// lib/services/ai_chat_service.dart
// Talks to Groq's free, OpenAI-compatible chat-completions API and streams
// the reply back token-by-token. If GEMINI_API_KEY is configured, Groq is
// tried first and — on ANY failure (deprecated/renamed model, rate limit,
// timeout, outage) — this automatically retries with Gemini instead of
// showing the user an error. If AI_PROXY_BASE_URL is set, everything routes
// through your own backend instead (see /backend/proxy_server.py), which
// should do its own provider fallback server-side.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_constants.dart';
import '../models/chat_message.dart';
import 'ai_tools_service.dart';

/// A function that runs a named tool with decoded arguments and returns a
/// JSON-able result. Supplied by the caller (ChatController) so this service
/// never needs to know about Firestore/uid directly.
typedef ToolExecutor = Future<Map<String, dynamic>> Function(
    String toolName, Map<String, dynamic> args);

class AiChatException implements Exception {
  final String message;
  AiChatException(this.message);
  @override
  String toString() => message;
}

class _ModelUnavailableException extends AiChatException {
  _ModelUnavailableException(super.message);
}

class AiChatService {
  static final AiChatService _instance = AiChatService._internal();
  factory AiChatService() => _instance;
  AiChatService._internal();

  final http.Client _client = http.Client();

  static const int maxMessageChars = 4000;

  static const String _systemPrompt = '''
You are Astra, the AI assistant built into the AstraFlix movie app.
You are warm, sharp, and genuinely enthusiastic about film and TV, but the
user can ask you about absolutely anything — general knowledge, advice,
writing help, explanations, casual conversation — and you should answer
helpfully just like any capable assistant, not deflect back to movies.

Style rules:
- Be conversational and concise. Prefer short paragraphs over long essays.
- Use markdown-style **bold** sparingly for emphasis and "- " bullet lists
  when giving multiple recommendations, options, or steps.
- When recommending movies or shows, give the title, year if known, and a
  one-line reason it fits what the user asked for.
- Avoid spoilers unless the user explicitly asks for them or says they've
  already seen it.
- Never claim to have watched anything yourself — you know about films from
  training data, not personal experience.
- If a question is unclear, make a reasonable assumption and answer it
  rather than only asking for clarification.

If tools are available to you, use them whenever they'd give a real,
current, accurate answer instead of guessing — search_movies for finding
specific titles, get_similar_movies/get_trending_movies for recommendations,
and get_watchlist/get_favorites/add_to_watchlist/add_to_favorites for the
user's own list (only add something when the user clearly asked you to).
Never invent a TMDB movie ID — only use IDs a tool actually returned.
''';

  bool get _usingProxy => ApiConstants.usesAiProxy;
  bool get _canFallbackToGemini => !_usingProxy && ApiConstants.hasGeminiKey;

  Stream<String> streamReply(
      List<ChatMessage> history, {
        ToolExecutor? toolExecutor,
      }) async* {
    if (history.isEmpty) {
      throw AiChatException('Say something and I\'ll jump in!');
    }

    if (_usingProxy) {
      yield* _streamOpenAiCompatible(
        history,
        endpoint: Uri.parse('${ApiConstants.aiProxyBaseUrl}/chat/stream'),
        headers: const {'Content-Type': 'application/json'},
        bodyBuilder: (messages) => {'messages': messages},
        includeSystemPrompt: false,
        timeoutSeconds: ApiConstants.chatRequestTimeoutSeconds,
      );
      return;
    }

    if (!ApiConstants.hasGroqKey && !ApiConstants.hasGeminiKey) {
      throw AiChatException(
        'AI chat isn\'t configured yet. Run the app with:\n'
            '--dart-define-from-file=env.local.json\n'
            'after filling GROQ_API_KEY (or GEMINI_API_KEY) in that file.\n'
            '(Free Groq key: console.groq.com/keys · Free Gemini key: aistudio.google.com/apikey)',
      );
    }

    if (ApiConstants.groqApiKey.isNotEmpty) {
      final trimmedHistory = history.length > ApiConstants.chatHistoryContextLimit
          ? history.sublist(history.length - ApiConstants.chatHistoryContextLimit)
          : history;
      final baseMessages = [
        {'role': 'system', 'content': _systemPrompt},
        ...trimmedHistory.map((m) => m.toApiJson()),
      ];

      for (final model in ApiConstants.groqModelCandidates) {
        var yieldedAny = false;
        try {
          final chunkStream = toolExecutor != null
              ? _streamGroqWithTools(
            baseMessages,
            model: model,
            timeoutSeconds: _canFallbackToGemini
                ? ApiConstants.groqFallbackTimeoutSeconds
                : ApiConstants.chatRequestTimeoutSeconds,
            toolExecutor: toolExecutor,
          )
              : _streamOpenAiCompatible(
            history,
            endpoint: Uri.parse('${ApiConstants.groqBaseUrl}${ApiConstants.groqChatEndpoint}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${ApiConstants.groqApiKey}',
            },
            bodyBuilder: (messages) => {
              'model': model,
              'messages': messages,
              'stream': true,
              'temperature': 0.7,
              'max_tokens': 1024,
            },
            includeSystemPrompt: true,
            timeoutSeconds: _canFallbackToGemini
                ? ApiConstants.groqFallbackTimeoutSeconds
                : ApiConstants.chatRequestTimeoutSeconds,
          );

          await for (final chunk in chunkStream) {
            yieldedAny = true;
            yield chunk;
          }
          return;
        } on _ModelUnavailableException {
          continue;
        } catch (_) {
          if (yieldedAny || !_canFallbackToGemini) rethrow;
          break;
        }
      }
    }

    if (ApiConstants.hasGeminiKey) {
      for (final model in ApiConstants.geminiModelCandidates) {
        try {
          await for (final chunk in _streamGemini(history, model)) {
            yield chunk;
          }
          return;
        } on _ModelUnavailableException {
          continue;
        } catch (_) {
          rethrow;
        }
      }
    }

    throw AiChatException(
        'The AI service is unavailable right now. Please try again shortly.');
  }

  Stream<String> _streamOpenAiCompatible(
      List<ChatMessage> history, {
        required Uri endpoint,
        required Map<String, String> headers,
        required Map<String, dynamic> Function(List<Map<String, String>> messages) bodyBuilder,
        required bool includeSystemPrompt,
        required int timeoutSeconds,
      }) async* {
    final trimmedHistory = history.length > ApiConstants.chatHistoryContextLimit
        ? history.sublist(history.length - ApiConstants.chatHistoryContextLimit)
        : history;

    final messages = [
      if (includeSystemPrompt) {'role': 'system', 'content': _systemPrompt},
      ...trimmedHistory.map((m) => m.toApiJson()),
    ];

    final request = http.Request('POST', endpoint)
      ..headers.addAll(headers)
      ..body = json.encode(bodyBuilder(messages));

    http.StreamedResponse response;
    try {
      response = await _sendWithRetry(request, timeoutSeconds);
    } on TimeoutException {
      throw AiChatException('The AI is taking too long to respond. Please try again.');
    } on http.ClientException {
      throw AiChatException('No internet connection. Check your network and try again.');
    } catch (_) {
      throw AiChatException('Couldn\'t reach the AI service. Check your internet connection.');
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      if (response.statusCode == 404) {
        throw _ModelUnavailableException(_friendlyError(response.statusCode, body));
      }
      throw AiChatException(_friendlyError(response.statusCode, body));
    }

    final lines = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    String buffer = '';
    var sawAnyPayload = false;
    await for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final payload = line.startsWith('data:') ? line.substring(5).trim() : line;
      if (payload.isEmpty) continue;
      if (payload == '[DONE]') break;

      sawAnyPayload = true;
      try {
        final decoded = json.decode(payload);
        final choices = decoded is Map ? decoded['choices'] as List<dynamic>? : null;
        if (choices != null && choices.isNotEmpty) {
          final delta = choices.first['delta'] as Map<String, dynamic>?;
          final piece = delta?['content'] as String?;
          if (piece != null && piece.isNotEmpty) {
            buffer += piece;
            yield piece;
          }
          continue;
        }
        final text = decoded is Map ? decoded['text'] as String? : null;
        if (text != null && text.isNotEmpty) {
          buffer += text;
          yield text;
        }
      } catch (_) {
        if (!line.startsWith('data:')) {
          buffer += payload;
          yield payload;
        }
      }
    }

    if (buffer.isEmpty) {
      throw AiChatException(sawAnyPayload
          ? 'The AI didn\'t return a response. Please try again.'
          : 'No response from the AI service. Please try again in a moment.');
    }
  }

  /// Groq streaming WITH function-calling support — this is what makes
  /// Astra "agentic": the model can call search/recommend/watchlist tools
  /// mid-conversation instead of only answering from training data.
  Stream<String> _streamGroqWithTools(
      List<Map<String, dynamic>> messages, {
        required String model,
        required int timeoutSeconds,
        required ToolExecutor toolExecutor,
        int depth = 0,
        bool retriedOn429 = false,
      }) async* {
    if (depth > 3) {
      throw AiChatException('I got stuck using tools — please try rephrasing your question.');
    }

    final endpoint = Uri.parse('${ApiConstants.groqBaseUrl}${ApiConstants.groqChatEndpoint}');
    final request = http.Request('POST', endpoint)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.groqApiKey}',
      })
      ..body = json.encode({
        'model': model,
        'messages': messages,
        'stream': true,
        'temperature': 0.7,
        'max_tokens': 1024,
        'tools': AiToolsService.toolSchemas,
        'tool_choice': 'auto',
      });

    http.StreamedResponse response;
    try {
      response = await _sendWithRetry(request, timeoutSeconds);
    } on TimeoutException {
      throw AiChatException('The AI is taking too long to respond. Please try again.');
    } on http.ClientException {
      throw AiChatException('No internet connection. Check your network and try again.');
    } catch (_) {
      throw AiChatException('Couldn\'t reach the AI service. Check your internet connection.');
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      if (response.statusCode == 404) {
        throw _ModelUnavailableException(_friendlyError(response.statusCode, body));
      }
      // Rate limits often clear within a couple of seconds — one short,
      // silent retry before giving up (and, if configured, falling back
      // to Gemini) avoids surfacing a transient blip as a hard error.
      if (response.statusCode == 429 && !retriedOn429) {
        await Future.delayed(const Duration(milliseconds: 2500));
        yield* _streamGroqWithTools(
          messages,
          model: model,
          timeoutSeconds: timeoutSeconds,
          toolExecutor: toolExecutor,
          depth: depth,
          retriedOn429: true,
        );
        return;
      }
      throw AiChatException(_friendlyError(response.statusCode, body));
    }

    final lines = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    String contentBuffer = '';
    var sawAnyPayload = false;
    String? finishReason;
    final toolCallAcc = <int, _ToolCallAccumulator>{};

    await for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || !line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;
      if (payload == '[DONE]') break;

      sawAnyPayload = true;
      try {
        final decoded = json.decode(payload) as Map<String, dynamic>;
        final choices = decoded['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) continue;
        final choice = choices.first as Map<String, dynamic>;
        final delta = choice['delta'] as Map<String, dynamic>?;
        finishReason = (choice['finish_reason'] as String?) ?? finishReason;

        final piece = delta?['content'] as String?;
        if (piece != null && piece.isNotEmpty) {
          contentBuffer += piece;
          yield piece;
        }

        final toolCalls = delta?['tool_calls'] as List<dynamic>?;
        if (toolCalls != null) {
          for (final raw in toolCalls) {
            final tc = raw as Map<String, dynamic>;
            final idx = (tc['index'] as num?)?.toInt() ?? 0;
            final acc = toolCallAcc.putIfAbsent(idx, () => _ToolCallAccumulator());
            if (tc['id'] != null) acc.id = tc['id'] as String;
            final fn = tc['function'] as Map<String, dynamic>?;
            if (fn?['name'] != null) acc.name = '${acc.name ?? ''}${fn!['name']}';
            if (fn?['arguments'] != null) acc.argsBuffer += fn!['arguments'] as String;
          }
        }
      } catch (_) {
        continue;
      }
    }

    if (finishReason == 'tool_calls' && toolCallAcc.isNotEmpty) {
      final calls = toolCallAcc.values.toList();

      final statusLine = calls.map((c) => AiToolsService.statusLabel(c.name ?? '')).join('  ·  ');
      yield '\n\n$statusLine\n\n';

      final assistantToolCallMessage = {
        'role': 'assistant',
        'content': contentBuffer.isEmpty ? null : contentBuffer,
        'tool_calls': [
          for (var i = 0; i < calls.length; i++)
            {
              'id': calls[i].id ?? 'call_$i',
              'type': 'function',
              'function': {
                'name': calls[i].name ?? '',
                'arguments': calls[i].argsBuffer.isEmpty ? '{}' : calls[i].argsBuffer,
              },
            },
        ],
      };

      final toolResultMessages = <Map<String, dynamic>>[];
      for (var i = 0; i < calls.length; i++) {
        final call = calls[i];
        Map<String, dynamic> args = {};
        try {
          final decoded = json.decode(call.argsBuffer.isEmpty ? '{}' : call.argsBuffer);
          if (decoded is Map<String, dynamic>) args = decoded;
        } catch (_) {}
        final result = await toolExecutor(call.name ?? '', args);
        toolResultMessages.add({
          'role': 'tool',
          'tool_call_id': call.id ?? 'call_$i',
          'content': json.encode(result),
        });
      }

      final nextMessages = [...messages, assistantToolCallMessage, ...toolResultMessages];
      yield* _streamGroqWithTools(
        nextMessages,
        model: model,
        timeoutSeconds: timeoutSeconds,
        toolExecutor: toolExecutor,
        depth: depth + 1,
      );
      return;
    }

    if (contentBuffer.isEmpty) {
      throw AiChatException(sawAnyPayload
          ? 'The AI didn\'t return a response. Please try again.'
          : 'No response from the AI service. Please try again in a moment.');
    }
  }

  Stream<String> _streamGemini(List<ChatMessage> history, String model) async* {
    final trimmedHistory = history.length > ApiConstants.chatHistoryContextLimit
        ? history.sublist(history.length - ApiConstants.chatHistoryContextLimit)
        : history;

    final endpoint = Uri.parse(
      '${ApiConstants.geminiBaseUrl}/$model:streamGenerateContent'
          '?alt=sse',
    );

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt}
        ]
      },
      'contents': trimmedHistory
          .map((m) => {
        'role': m.role == ChatRole.user ? 'user' : 'model',
        'parts': [
          {'text': m.content}
        ],
      })
          .toList(),
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024},
    };

    final request = http.Request('POST', endpoint)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'x-goog-api-key': ApiConstants.geminiApiKey,
      })
      ..body = json.encode(body);

    http.StreamedResponse response;
    try {
      final timeoutSeconds = ApiConstants.hasGroqKey
          ? ApiConstants.geminiFallbackTimeoutSeconds
          : ApiConstants.chatRequestTimeoutSeconds;
      response = await _client.send(request).timeout(Duration(seconds: timeoutSeconds));
    } on TimeoutException {
      throw AiChatException('The AI is taking too long to respond. Please try again.');
    } on http.ClientException {
      throw AiChatException('No internet connection. Check your network and try again.');
    } catch (_) {
      throw AiChatException('Couldn\'t reach the AI service. Check your internet connection.');
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      if (response.statusCode == 404) {
        throw _ModelUnavailableException(_friendlyError(response.statusCode, body));
      }
      throw AiChatException(_friendlyError(response.statusCode, body));
    }

    final lines = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    String buffer = '';
    await for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || !line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;

      try {
        final decoded = json.decode(payload);
        final candidates = decoded is Map ? decoded['candidates'] as List<dynamic>? : null;
        if (candidates == null || candidates.isEmpty) continue;
        final parts = candidates.first['content']?['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) continue;
        final piece = parts.first['text'] as String?;
        if (piece != null && piece.isNotEmpty) {
          buffer += piece;
          yield piece;
        }
      } catch (_) {
        continue;
      }
    }

    if (buffer.isEmpty) {
      throw AiChatException('The AI didn\'t return a response. Please try again.');
    }
  }

  Future<http.StreamedResponse> _sendWithRetry(http.Request request, int timeoutSeconds) async {
    try {
      return await _client.send(request).timeout(Duration(seconds: timeoutSeconds));
    } on http.ClientException {
      await Future.delayed(const Duration(milliseconds: 600));
      return await _client.send(request).timeout(Duration(seconds: timeoutSeconds));
    }
  }

  Future<String> sendMessage(List<ChatMessage> history) async {
    final buffer = StringBuffer();
    await for (final chunk in streamReply(history)) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  String _friendlyError(int statusCode, String body) {
    switch (statusCode) {
      case 401:
        return 'Invalid AI API key. Double-check your API key in env.local.json.';
      case 404:
        return 'That AI model isn\'t available anymore. Please update GROQ_MODEL / GEMINI_MODEL.';
      case 429:
        return 'AI service is rate-limited right now. Please wait a moment and try again.';
      case 400:
        return 'The AI service rejected the request. Please try rephrasing.';
      case 500:
      case 502:
      case 503:
        return 'The AI service is temporarily unavailable. Please try again shortly.';
      default:
        return 'AI service error ($statusCode). Please try again shortly.';
    }
  }

  String? sanitizeInput(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length > maxMessageChars
        ? trimmed.substring(0, maxMessageChars)
        : trimmed;
  }

  String suggestTitle(String firstMessage) {
    final cleaned = firstMessage.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return 'New chat';
    return cleaned.length > 42 ? '${cleaned.substring(0, 42)}…' : cleaned;
  }

  void dispose() => _client.close();
}

/// Accumulates a single tool call's id/name/arguments across the several
/// small streamed deltas Groq sends for it before it's complete.
class _ToolCallAccumulator {
  String? id;
  String? name;
  String argsBuffer = '';
}