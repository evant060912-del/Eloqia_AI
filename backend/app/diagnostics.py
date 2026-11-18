"""Live checks of the services Mia depends on, in plain language.

Answers "why does Mia not speak / not review any more?": missing keys, an
invalid key, no credit left, a model that no longer exists, or a network
problem. Keys are never returned.
"""

from __future__ import annotations

import asyncio
from typing import Any

import httpx

from app.config import Settings

OPENAI_MODELS_URL = "https://api.openai.com/v1/models/{model}"
CARTESIA_VOICE_URL = "https://api.cartesia.ai/voices/{voice_id}"

# Last error seen when Mia actually spoke (credits can only be seen there).
_last_tts_error: dict[str, Any] = {}


def record_tts_error(status_code: int | None, detail: str) -> None:
    _last_tts_error.clear()
    _last_tts_error.update({"status_code": status_code, "detail": detail[:200]})


def clear_tts_error() -> None:
    _last_tts_error.clear()


def explain(service: str, status_code: int | None, body: str = "") -> dict[str, str]:
    """Turns an HTTP outcome into a state and a fix anyone can follow."""
    text = body.lower()
    if status_code == 200:
        return {"state": "ok", "message": f"{service} answers normally."}
    if status_code in (401, 403):
        return {
            "state": "invalid_key",
            "message": f"The {service} key is refused. Create a new key and "
            "put it in the backend .env file, then restart the backend.",
        }
    if status_code == 402 or "credit" in text or "insufficient_quota" in text:
        return {
            "state": "no_credit",
            "message": f"{service} has no credit left. Add credit on the "
            f"{service} website (billing page).",
        }
    if status_code == 429:
        return {
            "state": "rate_limited",
            "message": f"{service} is limiting requests (quota or too many "
            "calls). Check the billing and usage page.",
        }
    if status_code == 404:
        return {
            "state": "not_found",
            "message": f"The configured {service} model or voice no longer "
            "exists. Update it in the backend .env file.",
        }
    if status_code is None:
        return {
            "state": "unreachable",
            "message": f"{service} could not be reached from the backend "
            "(internet connection or firewall).",
        }
    return {
        "state": "error",
        "message": f"{service} answered with an unexpected error "
        f"({status_code}).",
    }


async def _get(
    url: str, headers: dict[str, str], transport: httpx.AsyncBaseTransport | None
) -> tuple[int | None, str]:
    try:
        async with httpx.AsyncClient(timeout=8.0, transport=transport) as client:
            response = await client.get(url, headers=headers)
        return response.status_code, response.text[:300]
    except httpx.HTTPError:
        return None, ""


async def check_openai(
    settings: Settings, transport: httpx.AsyncBaseTransport | None = None
) -> dict[str, str]:
    if not settings.openai_api_key:
        return {
            "state": "missing",
            "message": "OPENAI_API_KEY is empty: Mia's chat, reviews and "
            "feedback cannot work. Add it to the backend .env file.",
        }
    status_code, body = await _get(
        OPENAI_MODELS_URL.format(model=settings.openai_chat_model),
        {"Authorization": f"Bearer {settings.openai_api_key}"},
        transport,
    )
    result = explain("OpenAI", status_code, body)
    result["model"] = settings.openai_chat_model
    return result


async def check_cartesia(
    settings: Settings, transport: httpx.AsyncBaseTransport | None = None
) -> dict[str, str]:
    if not settings.cartesia_api_key:
        return {
            "state": "missing",
            "message": "CARTESIA_API_KEY is empty: Mia cannot speak. Add it "
            "to the backend .env file.",
        }
    status_code, body = await _get(
        CARTESIA_VOICE_URL.format(voice_id=settings.cartesia_voice_id),
        {
            "Authorization": f"Bearer {settings.cartesia_api_key}",
            "Cartesia-Version": settings.cartesia_api_version,
        },
        transport,
    )
    result = explain("Cartesia", status_code, body)
    # The key can be valid while credits are gone: only speaking shows it.
    if result["state"] == "ok" and _last_tts_error:
        last = explain(
            "Cartesia",
            _last_tts_error.get("status_code"),
            str(_last_tts_error.get("detail", "")),
        )
        if last["state"] != "ok":
            last["message"] += " (seen the last time Mia tried to speak)"
            return last
    return result


async def diagnostics(
    settings: Settings, transport: httpx.AsyncBaseTransport | None = None
) -> dict[str, Any]:
    openai, cartesia = await asyncio.gather(
        check_openai(settings, transport), check_cartesia(settings, transport)
    )
    healthy = openai["state"] == "ok" and cartesia["state"] == "ok"
    return {
        "status": "ok" if healthy else "attention",
        "openai": openai,
        "cartesia": cartesia,
    }
