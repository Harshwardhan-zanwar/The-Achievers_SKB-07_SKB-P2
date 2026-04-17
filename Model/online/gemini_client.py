import os
import logging
from google import genai
from dotenv import load_dotenv

load_dotenv()

key = os.getenv("GEMINI_API_KEY")
if not key:
    logger = logging.getLogger("GeminiClient")
    logger.warning("⚠️ GEMINI_API_KEY is missing. AI Fusion and Translation will run in MOCK mode.")

model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
client = None
if key:
    client = genai.Client(api_key=key)
else:
    logger = logging.getLogger("GeminiClient")
    logger.warning("⚠️ Skipping Gemini Client initialization (Key Missing).")


def get_response(messages):
    if not key or not client:
        return "System is in Demo Mode. (Gemini API Key missing)"

    prompt_text = "\n\n".join(
        f"{m.get('role', 'user').upper()}: {m.get('content', '').strip()}"
        for m in messages
        if m.get("content")
    )

    response = client.models.generate_content(
        model=model_name,
        contents=prompt_text,
    )

    text = (response.text or "").strip()
    if not text:
        raise RuntimeError("Gemini returned an empty response")
    return text
