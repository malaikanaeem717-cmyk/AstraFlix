# AstraFlix 🎬

**AI-powered movie discovery app with an agentic AI assistant** — built with Flutter, Firebase, and TMDB.

Astra, the built-in AI assistant, doesn't just talk about movies — it uses LLM function-calling to actually search TMDB, recommend titles, and manage your watchlist/favorites in real time.

---

## ✨ Highlights

- 🤖 **Agentic AI chat** — Groq (primary) + Gemini (auto-fallback), with 7 real tools: search, recommend, trending, and read/write the user's watchlist & favorites
- 🎬 **Live TMDB data** — posters, ratings, cast, trailers, watch providers
- 🎥 In-app trailer playback (no external redirects)
- 🔥 Firebase — Auth, real-time Firestore sync
- 💎 Dark/light themed UI with animated splash, glassmorphism, and smooth transitions
- 🗂️ Favorites + Watchlist, live-synced
- 📸 Profile photo upload (Cloudinary)

---

## 🛠️ Tech Stack

`Flutter` · `Dart` · `Riverpod` · `Firebase (Auth, Firestore)` · `TMDB API` · `Groq / Gemini LLM APIs` · `Function-Calling` · `Cloudinary`

---

## 🚀 Getting Started

```bash
git clone <this-repo>
cd astraflix
cp env.local.example.json env.local.json   # then fill in your API keys
flutter pub get
flutter run --dart-define-from-file=env.local.json
```

Full setup details (Firebase config, all API keys, deployment) are in [`SETUP.md`](./SETUP.md).

---



*Built with ❤️ using Flutter*