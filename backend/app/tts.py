"""Cartesia text-to-speech for Mia's short spoken lines ("Hear Mia").

The Cartesia key stays on the server: the app sends text, the backend returns
WAV audio. Live conversations use the LiveKit agent instead (see agent.py).
"""

from __future__ import annotations

from typing import Any

import httpx

from app.config import Settings

CARTESIA_TTS_URL = "https://api.cartesia.ai/tts/bytes"

# Mia's speaking styles (MiaSpeechStyle in Flutter) -> Cartesia emotions.
STYLE_EMOTIONS: dict[str, str] = {
    "warm": "content",
    "excited": "excited",
    "encouraging": "enthusiastic",
    "playful": "happy",
    "serious": "calm",
    "calm": "calm",
}


class CartesiaError(Exception):
    """Cartesia could not produce audio."""


def build_cartesia_payload(
    text: str,
    style: str,
    other_speaker: bool,
    speed_factor: float,
    settings: Settings,
) -> dict[str, Any]:
    voice_id = settings.cartesia_voice_id
    if other_speaker and settings.cartesia_secondary_voice_id:
        voice_id = settings.cartesia_secondary_voice_id

    # Cartesia accepts speed 0.6..1.5 and volume 0.5..2.0.
    speed = min(max(settings.cartesia_speed * speed_factor, 0.6), 1.5)
    volume = min(max(settings.cartesia_volume, 0.5), 2.0)

    return {
        "model_id": settings.cartesia_model,
        "transcript": text,
        "voice": {"id": voice_id},
        "language": settings.cartesia_language,
        "output_format": {
            "container": "wav",
            "encoding": "pcm_s16le",
            "sample_rate": 24000,
        },
        "generation_config": {
            "speed": round(speed, 2),
            "volume": round(volume, 2),
            "emotion": STYLE_EMOTIONS.get(style, "content"),
        },
    }


async def synthesize(
    text: str,
    style: str,
    other_speaker: bool,
    speed_factor: float,
    settings: Settings,
    transport: httpx.AsyncBaseTransport | None = None,
) -> bytes:
    payload = build_cartesia_payload(
        text, style, other_speaker, speed_factor, settings
    )
    headers = {
        "Authorization": f"Bearer {settings.cartesia_api_key}",
        "Cartesia-Version": settings.cartesia_api_version,
        "Content-Type": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=20.0, transport=transport) as client:
            response = await client.post(
                CARTESIA_TTS_URL,
                json=payload,
                headers=headers,
            )
    except httpx.HTTPError as error:
        raise CartesiaError(type(error).__name__) from error

    if response.status_code != 200 or not response.content:
        raise CartesiaError(
            f"status {response.status_code}: {response.text[:200]}"
        )

    return response.content
