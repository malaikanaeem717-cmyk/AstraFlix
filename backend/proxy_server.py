"""
AstraFlix AI Chat Proxy
========================
A thin FastAPI pass-through that sits between the Flutter app and Groq.

Why this exists:
-----------------
Flutter Web ships every --dart-define value readable in plain text inside
the compiled JS bundle / browser Network tab. That's fine for the TMDB key
(TMDB's own client is designed for that), but NOT fine for the Groq key —
anyone could open devtools, copy it, and burn your quota.

This server holds the real GROQ_API_KEY as a server-side environment
variable. The Flutter app calls THIS server instead of Groq directly, and
never sees the real key.

Run locally:
    pip install -r requirements.txt
    export GROQ_API_KEY=your_real_key
    uvicorn proxy_server:app --reload --port 8001

Deploy (free tier options): Render.com, Railway.app, or Google Cloud Run.
Set GROQ_API_KEY as a secret/environment variable on whichever you use,
then point the Flutter app at it:
    flutter run --dart-define=AI_PROXY_BASE_URL=https://your-proxy.onrender.com

Once AI_PROXY_BASE_URL is set, lib/services/ai_chat_service.dart
automatically routes chat through this proxy instead of Groq directly.
"""

import os
import json
from typing import List

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
GROQ_BASE_URL = "https://api.groq.com/openai/v1"
GROQ_MODEL = os.environ.get("GROQ_MODEL", "llama-3.3-70b-versatile")

SYSTEM_PROMPT = """You are Astra, the AI assistant built into the AstraFlix movie app.
You are warm, sharp, and genuinely enthusiastic about film and TV, but the
user can ask you about absolutely anything - general knowledge, advice,
writing help, explanations, casual conversation - and you should answer
helpfully just like any capable assistant, not deflect back to movies.

Style rules:
- Be conversational and concise. Prefer short paragraphs over long essays.
- Use markdown-style **bold** sparingly for emphasis and "- " bullet lists
  when giving multiple recommendations, options, or steps.
- When recommending movies or shows, give the title, year if known, and a
  one-line reason it fits what the user asked for.
- Avoid spoilers unless the user explicitly asks for them or says they've
  already seen it.
- Never claim to have watched anything yourself - you know about films from
  training data, not personal experience.
- If a question is unclear, make a reasonable assumption and answer it
  rather than only asking for clarification.
"""

app = FastAPI(title="AstraFlix AI Proxy")

# Lock this down to your real domains before going to production —
# "*" is fine for local development only.
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.environ.get("ALLOWED_ORIGINS", "*").split(","),
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]


@app.get("/health")
def health():
    return {"status": "ok", "configured": bool(GROQ_API_KEY)}


@app.post("/chat/stream")
async def chat_stream(payload: ChatRequest):
    if not GROQ_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Server is missing GROQ_API_KEY. Set it as an environment variable.",
        )
    if not payload.messages:
        raise HTTPException(status_code=400, detail="messages must not be empty")

    body = {
        "model": GROQ_MODEL,
        "messages": [{"role": "system", "content": SYSTEM_PROMPT}]
        + [m.dict() for m in payload.messages],
        "stream": True,
        "temperature": 0.7,
        "max_tokens": 1024,
    }

    async def event_generator():
        async with httpx.AsyncClient(timeout=45) as client:
            async with client.stream(
                "POST",
                f"{GROQ_BASE_URL}/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {GROQ_API_KEY}",
                },
                json=body,
            ) as response:
                if response.status_code != 200:
                    error_body = await response.aread()
                    yield f"data: {json.dumps({'error': error_body.decode(errors='ignore')})}\n\n"
                    return
                async for line in response.aiter_lines():
                    if line:
                        yield f"{line}\n\n" if not line.startswith("data:") else f"{line}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")
