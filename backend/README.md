# AstraFlix AI Proxy

Thin FastAPI pass-through that keeps `GROQ_API_KEY` server-side so it never
ships inside the Flutter Web bundle. See the top-of-file docstring in
`proxy_server.py` for the full explanation.

## Local run
```bash
pip install -r requirements.txt
export GROQ_API_KEY=your_real_groq_key
uvicorn proxy_server:app --reload --port 8001
```

## Deploy (free options)
- **Render.com** — New Web Service → point at this folder → build command
  `pip install -r requirements.txt` → start command
  `uvicorn proxy_server:app --host 0.0.0.0 --port $PORT` → add `GROQ_API_KEY`
  as an environment variable/secret.
- **Railway.app** — same idea, auto-detects the `requirements.txt`.
- **Google Cloud Run** — containerize with a simple Dockerfile and deploy;
  set `GROQ_API_KEY` as a secret.

## Point the Flutter app at it
```bash
flutter run --dart-define-from-file=env.local.json
# with AI_PROXY_BASE_URL set inside env.local.json, e.g.:
# "AI_PROXY_BASE_URL": "https://your-proxy.onrender.com"
```
Once set, `lib/services/ai_chat_service.dart` automatically calls this proxy
instead of Groq directly, and the real key never reaches the browser.
