import asyncio
import dataclasses

import httpx

from app.config import Settings
from app.diagnostics import (
    clear_tts_error,
    diagnostics,
    explain,
    record_tts_error,
)


def _settings(**overrides):
    return dataclasses.replace(Settings.from_env(), **overrides)


def _transport(openai_status: int, cartesia_status: int) -> httpx.MockTransport:
    def handler(request: httpx.Request) -> httpx.Response:
        if "openai" in request.url.host:
            return httpx.Response(openai_status, text="{}")
        return httpx.Response(cartesia_status, text="{}")

    return httpx.MockTransport(handler)


def test_explain_maps_common_failures():
    assert explain("OpenAI", 200)["state"] == "ok"
    assert explain("OpenAI", 401)["state"] == "invalid_key"
    assert explain("Cartesia", 402)["state"] == "no_credit"
    assert explain("OpenAI", 429, "insufficient_quota")["state"] == "no_credit"
    assert explain("OpenAI", 404)["state"] == "not_found"
    assert explain("Cartesia", None)["state"] == "unreachable"


def test_missing_keys_are_reported_without_calls():
    result = asyncio.run(
        diagnostics(_settings(openai_api_key="", cartesia_api_key=""))
    )
    assert result["status"] == "attention"
    assert result["openai"]["state"] == "missing"
    assert result["cartesia"]["state"] == "missing"


def test_live_checks_and_last_speech_error():
    settings = _settings(openai_api_key="sk-test", cartesia_api_key="ck-test")
    ok = asyncio.run(diagnostics(settings, _transport(200, 200)))
    assert ok["status"] == "ok"
    assert "sk-test" not in str(ok) and "ck-test" not in str(ok)

    bad = asyncio.run(diagnostics(settings, _transport(401, 200)))
    assert bad["openai"]["state"] == "invalid_key"

    record_tts_error(402, "status 402: out of credits")
    credit = asyncio.run(diagnostics(settings, _transport(200, 200)))
    assert credit["cartesia"]["state"] == "no_credit"
    clear_tts_error()
