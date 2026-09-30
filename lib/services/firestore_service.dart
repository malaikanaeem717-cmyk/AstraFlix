// lib/services/firestore_service.dart
// All Firestore database operations for AstraFlix

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie_model.dart';
import '../models/user_model.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collections ──────────────────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  DocumentReference _user(String uid) => _users.doc(uid);
  CollectionReference _userFavorites(String uid) =>
      _user(uid).collection('favorites');
  CollectionReference _userWatchlist(String uid) =>
      _user(uid).collection('watchlist');
  CollectionReference _userChats(String uid) =>
      _user(uid).collection('chats');
  CollectionReference _chatMessages(String uid, String chatId) =>
      _userChats(uid).doc(chatId).collection('messages');

  // ─── User Profile ─────────────────────────────────────────────────────────
  Stream<UserModel?> userStream(String uid) {
    return _user(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _user(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUserProfile(String uid, {
    String? displayName,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (updates.isNotEmpty) {
      await _user(uid).update(updates);
    }
  }

  // ─── Favorites ────────────────────────────────────────────────────────────
  Stream<List<Movie>> favoritesStream(String uid) {
    return _userFavorites(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Movie.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addToFavorites(String uid, Movie movie) async {
    await _userFavorites(uid).doc(movie.id.toString()).set({
      ...movie.toFirestore(),
      'addedAt': FieldValue.serverTimestamp(),
    });
    // Update stats
    await _user(uid).update({
      'favoriteIds': FieldValue.arrayUnion([movie.id]),
      'stats.moviesFavorited': FieldValue.increment(1),
    });
  }

  Future<void> removeFromFavorites(String uid, int movieId) async {
    await _userFavorites(uid).doc(movieId.toString()).delete();
    await _user(uid).update({
      'favoriteIds': FieldValue.arrayRemove([movieId]),
      'stats.moviesFavorited': FieldValue.increment(-1),
    });
  }

  Future<bool> isFavorite(String uid, int movieId) async {
    final doc = await _userFavorites(uid).doc(movieId.toString()).get();
    return doc.exists;
  }

  // ─── Watchlist ────────────────────────────────────────────────────────────
  Stream<List<Movie>> watchlistStream(String uid) {
    return _userWatchlist(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Movie.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addToWatchlist(String uid, Movie movie) async {
    await _userWatchlist(uid).doc(movie.id.toString()).set({
      ...movie.toFirestore(),
      'addedAt': FieldValue.serverTimestamp(),
    });
    await _user(uid).update({
      'watchlistIds': FieldValue.arrayUnion([movie.id]),
    });
  }

  Future<void> removeFromWatchlist(String uid, int movieId) async {
    await _userWatchlist(uid).doc(movieId.toString()).delete();
    await _user(uid).update({
      'watchlistIds': FieldValue.arrayRemove([movieId]),
    });
  }

  Future<bool> isInWatchlist(String uid, int movieId) async {
    final doc = await _userWatchlist(uid).doc(movieId.toString()).get();
    return doc.exists;
  }

  // ─── Search History ───────────────────────────────────────────────────────
  Future<void> addSearchHistory(String uid, String query) async {
    if (query.trim().isEmpty) return;
    await _user(uid).update({
      'searchHistory': FieldValue.arrayUnion([query.trim()]),
    });
  }

  Future<void> clearSearchHistory(String uid) async {
    await _user(uid).update({'searchHistory': []});
  }

  Future<void> removeSearchTerm(String uid, String query) async {
    await _user(uid).update({
      'searchHistory': FieldValue.arrayRemove([query]),
    });
  }

  // ─── Recently Viewed ──────────────────────────────────────────────────────
  Future<void> addToRecentlyViewed(String uid, int movieId) async {
    // Remove if already present, then add to front
    final doc = await _user(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      List<int> recent = List<int>.from(data['recentlyViewed'] ?? []);
      recent.remove(movieId);
      recent.insert(0, movieId);
      if (recent.length > 50) recent = recent.take(50).toList();

      await _user(uid).update({'recentlyViewed': recent});
    }
  }

  // ─── Ratings ─────────────────────────────────────────────────────────────
  Future<void> rateMovie(String uid, int movieId, double rating) async {
    await _user(uid).update({
      'ratings.$movieId': rating,
      'stats.moviesRated': FieldValue.increment(1),
    });
  }

  Future<double?> getUserRating(String uid, int movieId) async {
    final doc = await _user(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final ratings = data['ratings'] as Map<String, dynamic>?;
      return ratings?[movieId.toString()]?.toDouble();
    }
    return null;
  }

  // ─── Stats ────────────────────────────────────────────────────────────────
  Future<void> incrementMoviesWatched(String uid) async {
    await _user(uid).update({
      'stats.moviesWatched': FieldValue.increment(1),
    });
  }

  // ─── AI Chat Sessions (sidebar history, like ChatGPT/Claude) ─────────────
  Stream<List<ChatSession>> chatSessionsStream(String uid) {
    return _userChats(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSession.fromFirestore(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<ChatSession> createChatSession(String uid, {String title = 'New chat'}) async {
    final doc = _userChats(uid).doc();
    await doc.set({
      'title': title,
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ChatSession(id: doc.id, title: title);
  }

  Future<void> renameChatSession(String uid, String chatId, String title) async {
    if (title.trim().isEmpty) return;
    await _userChats(uid).doc(chatId).update({'title': title.trim()});
  }

  Future<void> touchChatSession(String uid, String chatId,
      {String? lastMessage, String? autoTitle}) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (lastMessage != null) updates['lastMessage'] = lastMessage;
    if (autoTitle != null) updates['title'] = autoTitle;
    await _userChats(uid).doc(chatId).update(updates);
  }

  Future<void> deleteChatSession(String uid, String chatId) async {
    // Firestore doesn't cascade-delete subcollections client-side.
    final messages = await _chatMessages(uid, chatId).get();
    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_userChats(uid).doc(chatId));
    await batch.commit();
  }

  Stream<List<ChatMessage>> chatMessagesStream(String uid, String chatId) {
    return _chatMessages(uid, chatId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addChatMessage(String uid, String chatId, ChatMessage message) async {
    await _chatMessages(uid, chatId).doc(message.id).set(message.toFirestore());
  }
}
