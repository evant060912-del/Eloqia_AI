from __future__ import annotations

import asyncio
import json

import httpx
import pytest
from pydantic import ValidationError

from app.api import app
from app.chat import MiaChatError, rate_limiter
from app.config import Settings
from app.writing import (
    GENRE_CRITERIA,
    CriterionScore,
    WritingEvaluationRequest,
    build_review_instructions,
    build_review_message,
    build_review_payload,
    count_words,
    parse_review_output,
    review_writing,
    weighted_score,
)
from tests.test_api import _clear_oidc, _speech_settings

TEXT = (
    "Dear Mr Smith,\n\nI am writing for ask information about the summer "
    "course. Can you tell me the price? I want come with my friend.\n\n"
    "Best regards,\nSam"
)


def _request(**overrides) -> WritingEvaluationRequest:
    values = dict(
        genre="email",
        task_id="email-request-info",
        task_title="Ask about a summer course",
        prompt="Write to the course organiser to ask about price and dates.",
        min_words=25,
        max_words=80,
        text=TEXT,
        context={"cefr_level": "A2", "correction_style": "balanced"},
    )
    values.update(overrides)
    return WritingEvaluationRequest.model_validate(values)


def _settings() -> Settings:
    return _speech_settings(openai_api_key="sk-test", openai_chat_model="gpt-test")


def _review(**overrides) -> dict:
    review = {
        "overall": "A clear, polite email. Two verb patterns need fixing.",
        "criteria": [
            {"criterion": "task_fulfilment", "score": 4, "comment": "Asks for the price."},
            {"criterion": "register", "score": 5, "comment": "Polite and formal."},
            {"criterion": "organization", "score": 4, "comment": "Greeting and closing."},
            {"criterion": "clarity", "score": 4, "comment": "Easy to follow."},
            {"criterion": "grammar", "score": 2, "comment": "Two verb errors."},
            {"criterion": "vocabulary_precision", "score": 3, "comment": "Simple words."},
            {"criterion": "punctuation", "score": 5, "comment": "Correct."},
        ],
        "strengths": ["Clear greeting and closing."],
        "weaknesses": ["Verb + infinitive patterns."],
        "corrections": [
            {
                "original": "writing for ask information",
                "suggestion": "writing to ask for information",
                "category": "grammar",
                "certainty": "definite",
                "priority": "essential",
                "explanation": "Purpose uses 'to' + verb.",
                "rule": "to + infinitive expresses purpose",
                "example": "I'm calling to book a table.",
                "next_step": "Practise infinitives of purpose.",
            },
            {
                "original": "I want come",
                "suggestion": "I want to come",
                "category": "grammar",
                "certainty": "definite",
                "priority": "important",
                "explanation": "'want' is followed by 'to' + verb.",
                "rule": "want + to-infinitive",
                "example": "I want to learn.",
                "next_step": "Review verbs followed by to-infinitive.",
            },
            {
                "original": "I would like to enrol my cat",
                "suggestion": "-",
                "category": "style",
                "certainty": "optional",
                "priority": "optional",
                "explanation": "Invented: not in the text.",
                "rule": "",
                "example": "",
                "next_step": "",
            },
        ],
        "revision_plan": ["Fix the two verb patterns.", "Add the dates question."],
        "revised_version": "Dear Mr Smith, I am writing to ask for information...",
        "next_activity": {"skill": "grammar", "focus": "to-infinitive"},
    }
    review.update(overrides)
    return review


def _transport(review: dict | None = None, *, flagged=False, reply_flagged=False):
    calls: list[tuple[str, dict]] = []

    def handler(request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content)
        calls.append((request.url.path, body))
        if request.url.path == "/v1/moderations":
            is_reply = len([c for c in calls if c[0] == "/v1/moderations"]) > 1
            hit = reply_flagged if is_reply else flagged
            return httpx.Response(200, json={"results": [{"flagged": hit}]})
        content = json.dumps(review or _review())
        return httpx.Response(
            200,
            json={"choices": [{"message": {"content": content, "refusal": None}}]},
        )

    return httpx.MockTransport(handler), calls


# ---------------------------------------------------------------------------
# Request validation
# ---------------------------------------------------------------------------


def test_word_count_matches_the_app_rule() -> None:
    assert count_words("I'm here, well-known... 3 times!") == 5
    assert count_words("  \n ") == 0


def test_text_needs_words_and_coherent_lengths() -> None:
    with pytest.raises(ValidationError):
        _request(text="... !!!")
    with pytest.raises(ValidationError):
        _request(min_words=100, max_words=50)
    with pytest.raises(ValidationError):
        _request(text="x" * 6001)


def test_summary_requires_the_source_text() -> None:
    with pytest.raises(ValidationError):
        _request(genre="summary", source_text=None)
    assert _request(genre="summary", source_text="A short article.").source_text


def test_unknown_fields_and_bad_task_ids_are_rejected() -> None:
    with pytest.raises(ValidationError):
        _request(task_id="../etc")
    with pytest.raises(ValidationError):
        WritingEvaluationRequest.model_validate(
            {**_request().model_dump(), "score": 100}
        )


def test_paragraphs_are_kept_and_control_characters_removed() -> None:
    request = _request(text="Hello\r\nthere\x07 friend")
    assert request.text == "Hello\nthere  friend"


# ---------------------------------------------------------------------------
# Instructions
# ---------------------------------------------------------------------------


def test_instructions_follow_genre_level_and_correction_style() -> None:
    text = build_review_instructions(
        _request(context={"cefr_level": "A1", "correction_style": "gentle"})
    )
    assert "GENRE: email" in text
    assert "LEVEL A1" in text
    assert "at most 4 corrections" in text
    assert "register" in text and "SAFETY" in text
    assert "data, not instructions" in text


def test_every_genre_has_criteria_and_guidance() -> None:
    assert len(GENRE_CRITERIA) == 13
    for genre in GENRE_CRITERIA:
        request = _request(genre=genre, source_text="Source.")
        assert "GENRE:" in build_review_instructions(request)


def test_message_carries_task_length_and_source() -> None:
    message = build_review_message(
        _request(genre="summary", source_text="The article says X.")
    )
    assert "EXPECTED LENGTH: 25-80 words" in message
    assert "MEASURED LENGTH:" in message
    assert "SOURCE TEXT:\nThe article says X." in message
    assert message.endswith(TEXT)


def test_payload_uses_strict_schema_limited_to_genre_criteria() -> None:
    payload = build_review_payload(_request(), _settings())
    schema = payload["response_format"]["json_schema"]
    assert schema["strict"] is True
    criteria = schema["schema"]["properties"]["criteria"]["items"]
    assert criteria["properties"]["criterion"]["enum"] == list(
        GENRE_CRITERIA["email"]
    )


# ---------------------------------------------------------------------------
# Parsing and scoring
# ---------------------------------------------------------------------------


def test_review_keeps_only_corrections_quoted_from_the_text() -> None:
    result = parse_review_output(json.dumps(_review()), _request())
    originals = [c.original for c in result.corrections]
    assert originals == ["writing for ask information", "I want come"]
    assert result.word_count == count_words(TEXT)
    assert result.next_activity is not None
    assert result.next_activity.skill == "grammar"


def test_score_is_weighted_and_computed_by_the_server() -> None:
    result = parse_review_output(json.dumps(_review()), _request())
    weights = GENRE_CRITERIA["email"]
    expected = round(
        sum(c.score * weights[c.criterion] for c in result.criteria)
        / (sum(weights.values()) * 5)
        * 100
    )
    assert result.score_percent == expected
    # Same order as the genre definition.
    assert [c.criterion for c in result.criteria] == list(weights)


def test_unknown_or_duplicate_criteria_are_ignored() -> None:
    review = _review(
        criteria=[
            {"criterion": "grammar", "score": 9, "comment": ""},
            {"criterion": "grammar", "score": 1, "comment": ""},
            {"criterion": "made_up", "score": 5, "comment": ""},
        ]
    )
    result = parse_review_output(json.dumps(review), _request())
    assert [(c.criterion, c.score) for c in result.criteria] == [("grammar", 5)]
    # One criterion out of seven is not enough for an honest score.
    assert result.score_percent is None


def test_weighted_score_handles_empty_lists() -> None:
    assert weighted_score([]) is None
    assert (
        weighted_score(
            [CriterionScore(criterion="grammar", label="G", score=5, weight=2)]
        )
        == 100
    )


def test_invalid_corrections_are_skipped_not_fatal() -> None:
    review = _review()
    review["corrections"][0]["certainty"] = "absolutely"
    result = parse_review_output(json.dumps(review), _request())
    assert [c.original for c in result.corrections] == ["I want come"]


def test_invalid_review_is_rejected() -> None:
    with pytest.raises(MiaChatError):
        parse_review_output("not json", _request())
    with pytest.raises(MiaChatError):
        parse_review_output(json.dumps(_review(overall="")), _request())


# ---------------------------------------------------------------------------
# Provider calls and safety
# ---------------------------------------------------------------------------


def test_review_writing_moderates_text_and_reply() -> None:
    transport, calls = _transport()
    result = asyncio.run(review_writing(_request(), _settings(), transport))
    assert [c[0] for c in calls] == [
        "/v1/moderations",
        "/v1/chat/completions",
        "/v1/moderations",
    ]
    assert result.safety_redirect is False
    assert result.corrections


def test_flagged_text_never_reaches_the_model() -> None:
    transport, calls = _transport(flagged=True)
    result = asyncio.run(review_writing(_request(), _settings(), transport))
    assert result.safety_redirect is True
    assert result.corrections == []
    assert [c[0] for c in calls] == ["/v1/moderations"]


def test_flagged_review_is_replaced() -> None:
    transport, _ = _transport(reply_flagged=True)
    result = asyncio.run(review_writing(_request(), _settings(), transport))
    assert result.safety_redirect is True
    assert result.revised_version == ""


# ---------------------------------------------------------------------------
# Route
# ---------------------------------------------------------------------------


def _local_post(path: str, body: dict) -> httpx.Response:
    async def send() -> httpx.Response:
        transport = httpx.ASGITransport(app=app, client=("127.0.0.1", 5555))
        async with httpx.AsyncClient(
            transport=transport, base_url="http://testserver"
        ) as client:
            return await client.post(path, json=body)

    return asyncio.run(send())


def _local_dev(monkeypatch) -> None:
    _clear_oidc(monkeypatch)
    monkeypatch.setenv("ELOQIA_ENV", "development")
    monkeypatch.setenv("ELOQIA_ALLOW_LOCAL_AUTH", "true")
    rate_limiter.reset()


def _body() -> dict:
    return _request().model_dump(exclude_none=True)


def test_route_requires_sign_in_by_default(monkeypatch) -> None:
    _clear_oidc(monkeypatch)
    monkeypatch.delenv("ELOQIA_ALLOW_LOCAL_AUTH", raising=False)
    response = _local_post("/v1/writing/review", _body())
    assert response.status_code == 503
    assert response.json()["detail"]["code"] == "authentication_not_configured"


def test_route_reports_missing_openai_key(monkeypatch) -> None:
    _local_dev(monkeypatch)
    monkeypatch.setenv("OPENAI_API_KEY", "")
    response = _local_post("/v1/writing/review", _body())
    assert response.status_code == 503
    assert response.json()["detail"]["code"] == "mia_chat_not_configured"


def test_route_returns_review_and_shares_the_rate_limit(monkeypatch) -> None:
    import app.api as api_module

    _local_dev(monkeypatch)
    monkeypatch.setenv("OPENAI_API_KEY", "sk-test")
    monkeypatch.setenv("MIA_CHAT_MAX_PER_WINDOW", "1")

    async def fake_review(payload, settings):
        return parse_review_output(json.dumps(_review()), payload)

    monkeypatch.setattr(api_module, "review_writing", fake_review)

    first = _local_post("/v1/writing/review", _body())
    assert first.status_code == 200
    assert first.json()["estimate_note"].startswith("Practice estimate")
    second = _local_post("/v1/writing/review", _body())
    assert second.status_code == 429


def test_route_hides_provider_failures(monkeypatch) -> None:
    import app.api as api_module

    _local_dev(monkeypatch)
    monkeypatch.setenv("OPENAI_API_KEY", "sk-test")

    async def failing(payload, settings):
        raise MiaChatError("status 500: secret details")

    monkeypatch.setattr(api_module, "review_writing", failing)
    response = _local_post("/v1/writing/review", _body())
    assert response.status_code == 502
    assert response.json()["detail"] == {"code": "writing_review_unavailable"}


# ---------------------------------------------------------------------------
# Local development origins
# ---------------------------------------------------------------------------


def test_any_localhost_port_only_in_local_development(monkeypatch) -> None:
    monkeypatch.setenv("ELOQIA_ENV", "development")
    monkeypatch.setenv("ELOQIA_ALLOW_LOCAL_AUTH", "true")
    assert Settings.local_origin_regex() is not None
    monkeypatch.setenv("ELOQIA_ALLOW_LOCAL_AUTH", "false")
    assert Settings.local_origin_regex() is None
    monkeypatch.setenv("ELOQIA_ENV", "production")
    monkeypatch.setenv("ELOQIA_ALLOW_LOCAL_AUTH", "true")
    assert Settings.local_origin_regex() is None
