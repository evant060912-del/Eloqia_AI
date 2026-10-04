# Mia Experience 4.0: Build Audit

## Implemented

- The splash uses the complete `eloqia_logo_concept_v1.png` asset with `BoxFit.contain`; it no longer crops the wordmark into a circle.
- First launch routes through a standalone Mia welcome screen before onboarding. Existing users who still need onboarding continue directly to onboarding.
- Twenty-one authored lessons cover grammar, vocabulary, reading, and listening at selected CEFR levels A1-C1. Exercise types are choice, true/false, fill-in, ordering, and matching.
- Evaluation and feedback are deterministic and answer-specific. Correct answers award XP; sessions track retries and combos, save progress/memories, and unlock achievements from recorded results.
- Recommendations use declared/assessed level, completed sessions, interests, progress, and active learning memories. The reason is shown with the lesson.
- Home actions launch a real lesson, local guided writing, or Mia. Progress shows only measured skill values and derives achievement status from saved sessions. Profile notes quote declared preferences rather than claiming an AI diagnosis.
- Mia's static presence is reused across Home, Talk, lesson, feedback, completion, Progress, and Profile. State changes animate its halo and scale; the portrait itself does not animate or lip-sync.

## Provider Boundaries

| Contract | Current implementation | Honest status |
| --- | --- | --- |
| `VoiceProvider` | `DeviceVoiceOutputProvider` through `flutter_tts` | Prefers a voice marked Natural/Neural, then known US voices. Accent and quality vary by device. |
| `SpeechProvider` | LiveKit microphone control | Captures microphone audio for a configured LiveKit session; it is not a standalone local speech recognizer. |
| `ConversationProvider` | `VoiceSessionClient` | Requires an allowed secure backend URL and an OIDC access-token provider. Session availability is confirmed only on connect. |
| `AvatarProvider` | `StaticMiaAvatarProvider` | Uses the static Mia portrait; no facial animation or lip-sync is claimed. A remote LiveKit video track can replace it when configured. |

No provider API key is embedded in Flutter. The Talk screen requests microphone consent and disables live startup while required backend/sign-in configuration is absent. The live conversation was not runtime-tested because those credentials and services are not configured in this workspace.

On the Chrome runtime used for this build, the available US voices were Microsoft Mark, Zira, and David. No Natural/Neural voice or regional-accent metadata was exposed; Mia selects Zira from that list. The device engine cannot guarantee a California-specific accent, and no cloud voice has been auditioned or configured.

## Voice Technology Review

Official documentation was checked for this build. No audio quality, latency, accent, or interruption claims below are treated as independently tested.

| Provider | Documented fit | Eloqia decision |
| --- | --- | --- |
| OpenAI Realtime | Speech-to-speech, low-latency turn-taking, interruption handling, tools, and WebRTC/WebSocket transports. Browser/mobile clients use ephemeral credentials created by a server. | Keep as the existing backend baseline. The client must never receive a long-lived API key. |
| Cartesia Sonic 3.6 | Streaming TTS, context-sensitive pacing, and 44 documented languages. Managed Agents are a separate orchestration option. | Candidate for a server-side TTS/agent comparison. No integration or listening test performed. |
| Hume EVI | Real-time speech-to-speech, transcription, prosody signals, expressive output, and interruption behavior. EVI 3 is English-only; EVI 4-mini supports more languages but needs a supplemental LLM and lacks EVI 3 quick responses. | Candidate if emotion/prosody becomes a measured product requirement. Use server-issued tokens; no adapter or test performed. |
| ElevenLabs Agents | Managed ASR, LLM, TTS, and turn-taking with WebSocket integration and documented React, Swift, Kotlin, and React Native libraries. | Candidate for a managed-agent comparison. The reviewed official docs do not list a Flutter SDK; no integration or listening test performed. |

Recommendation: retain the current OpenAI/LiveKit backend design and device-TTS fallback until a controlled listening POC compares the same teaching script, correction styles, interruption cases, first-audio latency, transcription quality, and session cost. No provider has been selected by audition.

## Avatar Technology Review

- LiveAvatar LITE documents real-time video as an add-on to an existing stack and provides a LiveKit integration path. The reviewed documentation lists one credit per minute. No production Mia avatar or likeness configuration is available here.
- Tavus CVI documents a modular real-time WebRTC pipeline, with Daily as its transport and configurable STT, LLM, TTS, and avatar layers. The current Flutter/LiveKit app has not been adapted to it.
- Neither vendor has been tested with an approved Mia likeness. Likeness rights, consent, retention, and deletion terms must be reviewed before any custom-face trial.

## Content and Product Limits

- Listening lines are spoken by the device/browser TTS engine; they are not recorded native-speaker audio.
- The lesson catalog is authored and limited to its current A1-C1 lessons. It does not imply complete CEFR coverage or autonomous AI generation.
- Guided writing uses local structural checks. It does not assess grammar quality with an LLM.
- Live conversation, speech recognition by the remote agent, and live avatar video remain unavailable until secure backend, identity, and vendor setup are supplied and verified.
- There is no production accent guarantee, avatar lip-sync, daily quest system, or cloud synchronization.

## Official Sources

- [OpenAI Realtime API](https://developers.openai.com/api/docs/guides/realtime)
- [Cartesia Sonic 3.6](https://docs.cartesia.ai/build-with-cartesia/tts-models/latest)
- [Hume EVI overview](https://dev.hume.ai/docs/speech-to-speech-evi/overview)
- [ElevenLabs Agents](https://elevenlabs.io/docs/eleven-agents/overview)
- [LiveAvatar LITE](https://docs.liveavatar.com/docs/lite-mode/overview)
- [Tavus CVI](https://docs.tavus.io/sections/conversational-video-interface/cvi-overview)

## Verification Snapshot

- `flutter analyze`: clean.
- `flutter test`: 52 tests passed before the final browser build/runtime check.
- Provider/live avatar auditions and live conversation runtime checks were not possible without credentials.
