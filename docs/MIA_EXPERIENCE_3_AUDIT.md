# Mia Experience 3.0: Audit and Technology Decision

Research date: 2026-10-02

## Current Architecture Audit

- Flutter Web is the primary client. The AppShell routes Home, Talk, Learn, Progress, and Profile.
- The optional A1-C2 placement check is adaptive, stores its estimate separately from `LearningProfile.currentLevel`, and now presents answer-specific teaching points before advancing.
- `MiaEmotionEngine` derives assessment reactions from correctness, item difficulty, per-skill repeated errors, observed correct streak, and the learner's `gentle`, `balanced`, `direct`, or `deep` correction preference. It is deterministic and local; it does not infer emotion from free text or voice.
- Placement errors are saved as aggregate, per-skill `LearningMemory` records through the existing memory service. The selected answer text is not saved.
- Guided writing uses three authored prompts and local word/sentence counts. The writing text is not persisted or submitted for AI review. Completing all three prompts awards 10 XP only after both the session and progress update succeed.
- Voice currently uses a FastAPI authentication/token boundary, LiveKit Agents, OpenAI Realtime, and LiveAvatar LITE. These integrations are **CONFIGURATION REQUIRED**: OIDC, LiveKit, OpenAI, and LiveAvatar credentials are absent. The current configuration has not been auditioned.
- The LiveKit client displays the remote video track for the participant named `Mia`; without that track it shows `assets/tutors/mia/mia.png`. The fallback PNG itself does not blink, emote, or lip-sync.
- Voice transport states are initializing, idle, listening, thinking, and speaking. They are agent transport states, not a rich emotional-state protocol. Assessment emotion does not currently drive live voice delivery or avatar expressions.
- Learning memories, sessions, progress, and profile already have local services. The voice job currently receives a bounded learning context, not learner identity, transcript history, or saved memories.

## Voice Options

| Option | Officially documented strengths | Tradeoffs for Eloqia |
| --- | --- | --- |
| OpenAI Realtime | Direct speech-to-speech, WebRTC/WebSocket, low-latency turn-taking, tool calls, and barge-in. Existing LiveKit Agent integration is already structured around it. | Most conservative baseline; no listening comparison has established the requested California-inspired voice or expressive range. Pricing is audio-token based, so test a representative session rather than compare a single token number. |
| Cartesia Sonic 3.6 + Ink 2 / Managed Agents | Streaming TTS and STT/turn detection; Sonic 3.6 documents context-sensitive pacing and 44 languages. Cartesia exposes per-request emotion guidance (currently documented as beta) and `[laughter]` nonverbalisms; Managed Agents combine STT, a chosen LLM, and TTS. | A more composable pipeline than the current Realtime model; voice quality and emotion tags must be auditioned with Mia's actual scripts. Public pricing lists Free and Pro ($5/month); exact credit-to-session cost depends on use. |
| Hume EVI 3 / EVI 4-mini | Speech-to-speech with transcription, prosody/expression signals, empathic speech, and interruption behavior. EVI 3 is English-only; EVI 4-mini is multilingual but requires a supplemental LLM and does not offer EVI 3 quick responses. | Strongest documented emotion/prosody fit, but it adds a second vendor and a different WebSocket pipeline. Official page lists Free with 5 EVI minutes, Starter $3/month with 40 minutes and $0.07/min additional EVI 3 usage; verify current plan details before purchase. |
| ElevenLabs Agents / TTS | Expressive voice catalogue, managed ASR/LLM/TTS/turn-taking, voice selection, mobile SDKs for iOS/Android/React Native, and a custom WebSocket API. Its TTS supports emotionally guided speech. | Agents are a full orchestration option rather than a drop-in Realtime voice. No first-party Flutter SDK is listed. Pricing page lists Free 15 call minutes and $0.08/min additional calls; LLM usage is separate. |

### Decision

Do not switch providers on documentation claims alone. Keep OpenAI Realtime as the existing baseline behind the backend while running a listening POC against Cartesia and Hume; include ElevenLabs Agents if its managed workflow is acceptable. Use the same learner profile, 10-turn teaching script, correction-style variants, and interruption tests. Record first-audio latency, turn latency, interruption recovery, transcription errors, voice consistency, naturalness, pronunciation of learner-level vocabulary, and cost per five-minute session. Human listening is required before selecting a voice. No credentials or usable voice samples are currently available in this workspace, so that POC has **not** been performed.

## Avatar Options

| Option | Officially documented strengths | Tradeoffs for Eloqia |
| --- | --- | --- |
| HeyGen LiveAvatar LITE | Designed to add real-time video to an existing LLM/TTS/STT pipeline; supports LiveKit, matching the current agent architecture. Documented at 1 credit/minute (FULL is 2 credits/minute). | Sandbox only supplies the Wayne avatar and sessions last about one minute. It cannot prove that Mia's existing likeness is preserved. Production avatar availability, source rights, and credits must be verified. |
| Tavus CVI | End-to-end WebRTC conversation pipeline; custom faces can be created from an image or roughly two minutes of training video; documents facial emotion, speaking/listening motion, configurable interruption, and Cartesia/ElevenLabs TTS. | Replaces or delegates more of the current stack. The official pricing page lists Starter at $22/month with 60 CVI minutes and one custom Face slot; verify current terms and the exact Flutter transport path. Any training source requires documented likeness rights and consent. |

### Decision

Keep LiveAvatar LITE as the least disruptive avatar architecture because it can retain the current LiveKit/agent stack. Do not treat the sandbox avatar as Mia: the documented sandbox only exposes Wayne. Compare a production LiveAvatar Mia configuration with a Tavus custom-face POC only after the owner confirms rights and consent for the existing Mia source material. No photorealistic avatar, custom face, or synchronized expression is currently verified.

## Security and Platform Notes

- Provider API keys stay in the backend; clients receive only short-lived, room-scoped credentials.
- Do not pass OIDC subject, raw transcripts, or free-text writing into agent metadata or persistent learning memory by default.
- A custom voice clone or avatar likeness requires documented rights, provider policy review, deletion/retention review, and a learner-facing disclosure.
- Hume's current official quickstarts emphasize TypeScript/Python/WebSocket. ElevenLabs lists native Swift/Kotlin and React Native SDKs, not Flutter. Cartesia documents WebSocket-capable browser/mobile/server clients. The current LiveKit client is the clearest Flutter-native media path among the options reviewed.

## Implemented in This Milestone

- Deterministic Mia emotion and feedback for the objective placement questions, including skill-specific rationales and correction preference.
- Animated presence card driven by the reaction state. It animates its halo/scale only; it does not simulate facial movement.
- Aggregate placement mistake memories stored via `MemoryService`; no selected answer or writing text is stored.
- Completion-only 10 XP for the three-prompt writing session, with session and progression persistence checked before showing the reward.
- Server-side Mia personality guidance for bounded humor, correction style, concise conversational turns, and evidence-based claims.

## Not Implemented / Not Verified

- No voice vendor has been chosen from an audio comparison, and no sample has been listened to.
- No user interruption test, speech-recognition test, latency benchmark, accent evaluation, or per-emotion TTS test has run.
- No production Mia avatar identity, live lip-sync, face expression, gaze, blink, or gesture has been tested.
- Contextual emotion currently drives the assessment UI only; it is not yet synchronized to the live audio/avatar protocol.
- Session combos, challenge questions, achievement unlocks, and measured skill mastery are not implemented. No unsupported mastery percentages are shown.
- The current reward is only a fixed completion bonus for the completed writing exercise; there are no per-correct-answer rewards or combo multipliers.

## Official Sources

- [OpenAI Realtime API](https://developers.openai.com/api/docs/guides/realtime)
- [OpenAI API pricing](https://developers.openai.com/api/docs/pricing)
- [Cartesia Sonic 3.6](https://docs.cartesia.ai/build-with-cartesia/tts-models/latest)
- [Cartesia emotion and laughter controls](https://docs.cartesia.ai/build-with-cartesia/sonic-3/volume-speed-emotion)
- [Cartesia Managed Agents](https://docs.cartesia.ai/agents/introduction)
- [Cartesia pricing](https://cartesia.ai/pricing)
- [Hume EVI overview](https://dev.hume.ai/docs/speech-to-speech-evi/overview)
- [Hume EVI configuration](https://dev.hume.ai/docs/speech-to-speech-evi/configuration/build-a-configuration)
- [Hume pricing](https://www.hume.ai/pricing)
- [ElevenLabs TTS docs](https://elevenlabs.io/docs/overview/capabilities/text-to-speech)
- [ElevenLabs Agents docs](https://elevenlabs.io/docs/eleven-agents/overview)
- [ElevenLabs Agents pricing](https://elevenlabs.io/pricing/agents)
- [LiveAvatar LITE overview](https://docs.liveavatar.com/docs/lite-mode/overview)
- [LiveAvatar LITE configuration](https://docs.liveavatar.com/docs/lite-mode/configuration)
- [LiveAvatar sandbox](https://docs.liveavatar.com/docs/sandbox-mode)
- [Tavus CVI overview](https://docs.tavus.io/sections/conversational-video-interface/cvi-overview)
- [Tavus face overview](https://docs.tavus.io/sections/faces/overview)
- [Tavus pricing](https://www.tavus.io/pricing)
