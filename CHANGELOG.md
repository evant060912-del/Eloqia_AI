# 📋 Eloqia AI Changelog

All notable changes, improvements, and learning milestones of **Eloqia AI** will be documented in this file.

This changelog tracks the evolution of the project step by step, from its first foundation to future releases.

---

# [Unreleased] — Microphone and speaking practice

## Added

* Microphone with the free speech recognition of the device or browser
  (`speech_to_text`; Chrome, Android, iOS). Nothing is recorded or stored,
  only the recognised text. Hidden when no recogniser is available.
* Mia chat: dictate with the microphone, read and correct the text, then send.
* Speaking practice in the TOEFL and IELTS spaces:
  - TOEFL Listen and Repeat: 2 sets of 7 sentences (8 to 12 s windows),
    compared word by word on the device (recognised words, not
    pronunciation);
  - TOEFL Take an Interview: 3 topics of 4 questions, 45 s each;
  - IELTS Part 1 (3 topics), Part 2 cue cards with 1 minute of preparation
    and up to 2 minutes of speaking (4 cards), Part 3 discussions (3 topics).
* Prompts are read by the free device voices; a typing fallback keeps every
  task usable without a microphone.
* Local measures per answer (words, words per minute, hesitation words) and
  Mia's review of the transcript (`toefl_interview` 0–5, `ielts_speaking`
  0–9 on three criteria). Pronunciation is never scored.
* Speaking scores join the exam history, trends and weakest-criterion advice.

## Changed

* Server: speaking genres reviewed from transcripts (ignore punctuation and
  likely recognition errors, no pronunciation judgement).
* Exam spaces are titled "TOEFL practice" and "IELTS practice".
* `pubspec.yaml`: `speech_to_text: ^7.3.0` (run `flutter pub get`);
  microphone and speech recognition permissions for Android and iOS.

# [Unreleased] — Listening with free device voices and accents

## Added

* Listening dialogues are read by the voices installed on the device
  (`flutter_tts`: Chrome, Android, iOS, desktop), at no cost. Each speaker
  keeps one voice; speakers sharing an accent get different voices when
  several are installed. Mia keeps her own voice for conversation.
* American, British and Australian accents per line (`AudioLine.accent`);
  when the device has no voice for an accent, a standard English voice reads
  those lines and the player says so.
* 7 new dialogues (12 listening lessons): café (A1), directions in Sydney
  (A2), flatmates with three accents (B1), weather forecast (B1), podcast
  (B2), job interview (B2), lecture exchange (C1).
* New question types: "Who says it?" and dictation.
* Listening library filters by accent; lesson tiles show the accents.

## Changed

* The listening player shows each speaker's accent and where the audio comes
  from (the old text claimed device audio even when the cloud voice was used).

# [Unreleased] — Personal plan from the onboarding answers

## Added

* Personal plan built from the onboarding answers: up to three focus areas
  ranked from the difficulties, main and secondary goals (strengths lower an
  area), each with the learner's own reason; daily minutes from the chosen
  pace; lesson tags from goals and interests.
* "Your plan" card on Home: focus areas (each opens its activity), daily goal
  and, for school or academic goals, a link to the TOEFL/IELTS writing practice.
* The daily goal follows the onboarding pace once (relaxed 10, regular 20,
  intensive 30, adaptive 15 minutes); later changes are never overwritten.

## Changed

* Lesson recommendations favour the focus skills (up to two lessons'
  advantage) and say why ("You said grammar is hard for you."). Lesson choice
  also uses interests mapped to lesson tags (business → career, music →
  culture...). A recent weakness still comes first.

# [Unreleased] — More lessons, lesson library and spaced review

## Added

* 15 new lessons (36 in total): grammar (present simple, comparatives,
  should/must/have to, relative clauses, mixed conditionals), vocabulary
  (family, food and cooking, phrasal verbs, environment, academic register)
  and reading (five original texts). Grammar, vocabulary and reading now have
  at least two lessons at every level from A1 to C1.
* Spaced review (Leitner boxes): grammar and vocabulary exercises missed at
  the first try come back the next day, then after 3, 7, 14 and 30 days; a
  mistake brings them back the next day; after the last box they count as
  mastered. The deck stays on the device under `eloqia.lessons.review`.
* "Spaced review" card in Learn (due count, or what is scheduled) and a
  "Spaced review" line on the lesson results screen.
* Lesson library: Grammar, Vocabulary, Reading and Listening in Learn list
  every lesson by level, completed ones ticked, with the recommended lesson
  and its reason first.

## Changed

* Learn → Grammar/Vocabulary/Reading/Listening opens the library instead of
  starting one automatically chosen lesson (Home keeps the quick start).

# [Unreleased] — TOEFL and IELTS writing preparation

## Added

* TOEFL and IELTS spaces in the Writing Studio ("Exam preparation"): official
  formats, score history with trend, tasks not tried yet, advice on the weakest
  criterion with a link to the task that trains it, estimated IELTS Writing
  band (Task 2 counts double). Every score is labelled unofficial.
* TOEFL iBT (January 2026 format): Build a Sentence with 30 original items in
  3 timed sets (6 min 50 s, all-or-nothing, explained corrections), 6 Write an
  Email tasks (7 min) and 6 Academic Discussion tasks shown as a class forum
  (10 min).
* IELTS: 8 Academic Task 1 tasks with visuals drawn by the app from invented
  data (bar and line charts, pie charts, table, process, map), 5 General
  Training letters and 8 Task 2 essays.
* Official timers (7, 10, 20 and 40 minutes) in the editor, with untimed
  practice; the time used is sent to Mia.
* 30 new tasks in the 13 studio genres (73 in total), including two original
  texts to summarise.
* Server: exam genres scored on their own scale (IELTS 0–9 with half bands,
  TOEFL 0–5), `exam_estimate` in the response, optional
  `time_limit_seconds`/`time_used_seconds`.

## Changed

* The review rules sent to Mia use the task's own scale instead of always
  "0 to 5".
* Review history shows the IELTS band or TOEFL score of exam tasks.

# [Unreleased] — Writing Studio

## Added

* Writing Studio: 13 genres with their own objectives, approach and
  server-side weighted criteria; 43 authored tasks across A1–A2, B1–B2 and
  C1–C2, including three original source texts for summaries.
* Writing workspace: brief with progressive hints, autosaved drafts, live word
  count against the target, deterministic "Check basics", side-by-side layout
  on wide screens.
* Mia's writing review (`POST /v1/writing/review`): level- and
  correction-style-aware instructions, quotes checked against the learner's
  text, certainty and priority for every correction, rule, example, next step,
  revision plan, revised version and a next activity linked to a real lesson.
  OpenAI moderation on the text and on Mia's answer; shared rate limit.
* Review screen: the learner's text annotated with numbered marks, criteria,
  strengths, corrections filterable by priority, automatic checks, revision
  plan, revised version and practice score (labelled as an estimate).
* Review history (last 20) and drafts kept on the device under `eloqia.`.
* `.vscode/launch.json`: server + app with the right `--dart-define` values.

## Changed

* Home and Learn: "Writing" opens the Writing Studio, "Conversation" opens the
  chat with Mia directly. Mia's "Practice by writing" button became "Writing
  Studio".
* In local development (`ELOQIA_ENV=development` and
  `ELOQIA_ALLOW_LOCAL_AUTH=true`) the API accepts any `localhost` port, so
  launching from VS Code no longer breaks CORS. `.env.example` enables local
  auth for development.
* The "Writer" achievement now reads "Complete a writing task with Mia".

## Removed

* `ConversationSessionScreen` (local writing prompts without review) and its
  test: replaced by the Writing Studio.

---

# [Unreleased] — Mia Conversation 2.0

## Added

* Mia's AI brain (`POST /v1/mia/chat`): free conversation, Ask Mia, six
  real-life role-plays and a writing coach (learn / improve / exam), with
  OpenAI moderation on both sides, per-learner rate limits and validated JSON.
* End-of-session review (`POST /v1/mia/chat/summary`). Every correction must
  quote what the learner actually wrote; ungrounded items are discarded.
* Finished conversations are recorded through the existing session, progress,
  streak and achievement services (XP only after 3 real learner messages,
  awarded once per session). New achievements: First Conversation, Role Player,
  Writer.
* Session review screen, "Stop voice" and "End session" actions, retry of a
  failed message without losing the conversation.

## Changed

* Mia's chat notes now use the existing `MemoryService` (tag `mia-chat`, 30-day
  expiry) instead of a separate store; lesson weaknesses are shared with Mia.
* "Hear Mia" plays long answers in full (split under the 600-character server
  limit), reuses already generated audio and caches availability for a minute.

## Removed

* Anam avatar widget and external script from `web/index.html`.
* Empty files (`mia_session_service.dart`, `writing_screen.dart`,
  `app_radius.dart`) and the duplicated `mia - Copy.png` asset.

---

# [Unreleased] — Mia Experience 4.0

## Added

* Added a standalone first-launch welcome screen for Mia and removed the
  onboarding overlay. The splash displays the complete logo asset uncropped.
* Added a lesson catalog covering grammar, vocabulary, reading, and listening
  with deterministic exercise evaluation, feedback, XP, combos, and achievements.
* Added Mia's shared visual presence and device text-to-speech actions to Home,
  lessons, Progress, and Profile.
* Added `VoiceProvider`, `SpeechProvider`, `ConversationProvider`, and
  `AvatarProvider` boundaries while preserving existing provider APIs.
* Connected Home learning actions to lessons and guided writing; recommendations
  and progress summaries are derived from local learner data.
* Added measured skill display and session-derived achievement states.

## Changed

* Live conversation now reports its secure configuration requirements before
  startup and stays disabled until the backend URL and OIDC provider are wired.
* The device/browser speech engine is the available TTS fallback; voice quality
  and accent vary by device.

## Verification

* `flutter analyze`: no issues found.
* `flutter test`: 52 tests passed.

## Remaining Configuration

* LiveKit/OpenAI conversation and a Mia LiveAvatar require backend credentials,
  OIDC integration, and runtime verification. No cloud voice or avatar POC has
  been performed.

# [v0.1.0] — 28 July 2026

## 🚀 Project Foundation

The Eloqia AI project was officially started.

This first version establishes the initial identity, organization, and direction of the project.

---

## ✨ Added

### Project Structure

* Created the Flutter project foundation
* Set up the initial project organization
* Added the first main folders:

  * `assets/`
  * `backend/`
  * `docs/`

---

### Documentation

Created the first official project documents:

* `README.md`
* `CHANGELOG.md`

Defined:

* Project vision
* Main objectives
* Development direction
* Long-term goals

---

### Project Planning

Established the first foundations of Eloqia AI:

* AI-powered English learning platform concept
* Personalized AI teacher experience concept
* Flutter + Dart as frontend technologies
* Python + FastAPI as backend technologies
* Professional project organization approach

---

## 📚 What I Learned

During this first version, I learned:

* How to structure a professional software project
* Why documentation is important before development
* How to plan a complex application step by step
* How real-world projects evolve through versions
* The importance of creating a clear technical vision before coding

---

# [v0.2.0] — 29 July 2026

## 🎨 First Visual Experience

The first visual milestone of Eloqia AI was completed.

This version transforms the initial project foundation into a first interactive application experience with a real visual identity.

---

## ✨ Added

### Application Interface

Created the first Eloqia AI user experience:

* Added the first animated Splash Screen
* Created the first Home Screen interface
* Added the first application navigation flow
* Created the first visual dashboard foundation

---

### AI Teacher Foundation

Introduced the first AI Tutor prototype:

## 🌴 Mia — The Encouraging Companion

Added the first tutor presentation system:

* First AI teacher identity
* Californian English Tutor concept
* Friendly and supportive learning experience

---

### Progression System Foundation

Created the first foundations of future gamification features:

* 🔥 Streak system placeholder
* ⭐ XP system placeholder
* 🏆 Level system placeholder

These features will be developed further in future versions.

---

### Documentation & Presentation

Added the first version presentation system:

* Splash Screen screenshot
* Home Screen screenshot
* Application demonstration recording

---

## 🔧 Improved

Improved the overall project quality:

* Improved Flutter project organization
* Created the first design system direction
* Improved UI consistency
* Established the version documentation workflow

---

## 📚 What I Learned

During this version, I learned:

* How to transform a project concept into a real interface
* How Flutter UI components are organized
* The importance of design before advanced development
* How to document the evolution of a software project
* How professional applications are built progressively

---

# [v0.3.0] — 31 July 2026

## 🌌 Premium Visual Experience

The third milestone of Eloqia AI was completed.

This version focuses on transforming the first visual prototype into a more immersive, premium, and futuristic application experience.

---

## ✨ Added

### Premium Splash Screen Experience

Enhanced the Eloqia AI startup experience:

* Added a redesigned premium Splash Screen
* Added advanced logo animation system
* Added smooth fade and scale animations
* Added dynamic AI glow effects
* Added improved startup transition experience

---

### Branding & Visual Identity

Improved the Eloqia AI visual direction:

* Integrated the official Eloqia AI logo asset
* Improved logo positioning and presentation
* Created a stronger premium AI brand feeling
* Reinforced the futuristic dark visual identity

---

### Home Experience Improvements

Enhanced the first application experience:

* Improved the Home Screen foundation
* Improved AI Tutor presentation
* Continued development of the Mia AI tutor experience
* Prepared the interface for future AI interactions

---

## 🔧 Improved

Improved the overall application quality:

* Improved Flutter UI structure
* Improved Splash Screen responsiveness
* Improved visual consistency
* Improved animation quality
* Improved asset management
* Fixed logo asset integration issues

---

## 📚 What I Learned

During this version, I learned:

* How to create more advanced Flutter animations
* How to manage and integrate application assets correctly
* How important visual details are in professional applications
* How to improve an interface through iterative design
* How real software products evolve through continuous refinement

# [v0.4.0] — 20 August 2026

## 🧠 Personalized AI Onboarding

The fourth milestone of Eloqia AI was completed.

This version focuses on creating a personalized onboarding experience and preparing the foundation for future AI-powered learning.

---

## ✨ Added

### Personalized Onboarding

* Added complete 15-step onboarding experience

* Added personalized learner profile using `LearningProfile`

* Added goals, strengths and difficulties questions

* Added confidence and English level assessment

* Added learning preferences and pace selection

* Added interests and speaking situations

* Added motivation and tutor personality preferences

* Added personalized onboarding completion experience

---

### 🌌 Premium Liquid Glass Experience

* Added premium Liquid Glass cards

* Added animated selection states

* Added ambient AI background effects

* Added smooth page transitions

* Added animated progress indicators

* Added premium completion animation

---

## 🔧 Improved

* Improved onboarding responsiveness

* Improved Flutter UI structure

* Improved navigation and animations

* Improved visual consistency

* Improved selection feedback

* Improved futuristic dark theme

* Established `LearningProfile` as the single source of truth

* Prepared the foundation for future AI personalization

---

## 📚 What I Learned

During this version, I learned:

* How to build a complete multi-step onboarding experience

* How to manage complex user selections in Flutter

* How to create reusable and responsive UI components

* How to create more advanced Liquid Glass interfaces

* How to design the foundation of a personalized AI experience

[v0.5.0] — 26 August 2026
🧠 Personalized Learning Experience

The fifth milestone of Eloqia AI was completed.

This version focuses on connecting the personalized learner profile to the main application, introducing persistent progression and creating the foundation of the Eloqia Learning Hub.

✨ Added
Personalized Home Experience
Added personalized HomeScreen using LearningProfile
Added dynamic learner greeting
Added persistent XP, level and streak data
Added daily learning goals
Added dynamic learning statistics
Added English Evolution progression section
Added personalized Daily Intelligence section
📚 Learning Hub
Added Learning Hub foundation
Added Conversation learning experience
Added Vocabulary learning category
Added Grammar learning category
Added Listening learning category
Added Writing learning category
Added Academic learning category
Added reusable learning action components
🤖 Mia
Added personalized Mia experience foundation
Added Mia welcome experience
Added Mia status presentation
Added Mia progress experience
Added Mia personalization architecture
Prepared the foundation for future interactive AI conversations
💾 Persistent Progression
Added persistent learner progression
Added XP and level persistence
Added streak tracking
Added daily goal persistence
Added skill progression tracking
Added learning statistics
Added progression snapshot system
🔧 Improved
Improved HomeScreen visual experience
Improved Liquid Glass interface
Improved ambient lighting and gradients
Improved cards, shadows and depth
Improved animations and transitions
Improved responsive layouts
Improved connection between learner profile and progression
Prepared the application for future adaptive learning
📚 What I Learned

During this version, I learned:

How to build a persistent learner progression system
How to connect stored data to Flutter interfaces
How to structure a scalable Learning Hub
How to create personalized application experiences
How to separate profile, progression and UI architecture
How to prepare an application for future AI-powered learning experiences

# [Unreleased] — Mia Voice Foundation

## Added

* Added a single light sweep to the existing animated splash logo.
* Connected the splash logo to Mia's intro with a shared Hero transition.
* Added an OIDC-protected FastAPI endpoint for room-scoped LiveKit voice sessions.
* Added a LiveKit Agents worker using OpenAI Realtime and the LiveAvatar plugin.
* Added a Flutter LiveKit session view with live video rendering, microphone
  mute, disconnect handling, and a static Mia image fallback.
* Added an explicit microphone-consent step and fail-closed configuration states.

## Security and Availability

* Provider credentials remain server-side and are read from environment
  variables.
* Voice sessions are not available until an OIDC provider, LiveKit project,
  OpenAI API key, LiveAvatar API key, and avatar are configured.
* The Flutter app does not yet inject an authenticated OIDC token provider.
* No transcript, learner memory, assessment score, or XP is persisted by this
  voice foundation.

## Verification

* `flutter analyze` passes.
* Flutter widget and voice-client tests pass.
* Backend tests pass on Python 3.14.6.


# [0.7.5] — 02 October 2026

🧠 Intelligent Learning Experience

The seventh major milestone of Eloqia AI was completed.

This version represents a major evolution of Eloqia from a personalized learning foundation into a more complete, immersive and intelligent English learning application.

V0.7.5 focuses on strengthening the learner experience, expanding the application architecture, improving personalization, introducing a more immersive Mia experience, and preparing the foundation for the transition toward V1.0.

✨ Added

🎯 Personalized Onboarding

Added expanded 15-step personalized onboarding experience

Added personalized learning goals

Added secondary learning goals

Added learning difficulties and strengths

Added confidence level personalization

Added speaking situation personalization

Added learning preferences

Added preferred correction style

Added motivation personalization

Added learning pace personalization

Added learner interests

Added preferred tutor style

Added CEFR level selection from A1 to C2

Added personalized onboarding completion experience

🧠 Learner Profile & Persistence

Strengthened persistent learner profile architecture

Added persistent application state management

Added persistent onboarding state

Improved connection between learner profile and application state

Strengthened profile persistence reliability

📚 Learning Experience

Expanded the Learning Hub experience

Added learning category foundations

Added Conversation learning experience foundation

Added Vocabulary learning experience foundation

Added Grammar learning experience foundation

Added Listening learning experience foundation

Added Writing learning experience foundation

Added Reading learning experience foundation

Added Academic learning foundations

Added personalized learning session foundations

Added assessment experience foundations

📈 Progression

Strengthened persistent XP system

Strengthened level progression

Strengthened streak tracking

Added daily learning goals

Added learning statistics

Added skill progression foundations

Added progression snapshots

Improved connection between learning activity and learner progression

🧠 Learning Memory

Added Learning Memory foundations

Added dedicated learning memory architecture

Prepared the application to retain learner weaknesses, strengths and learning history

Prepared memory architecture for future adaptive learning

🤖 Mia

Added Mia onboarding introduction experience

Added Mia visual tutor presence

Added contextual Mia onboarding guidance

Added personalized Mia experience foundations

Added Mia personalization architecture

Added foundation for future contextual AI tutoring

🏠 Application Experience

Added AppShell navigation architecture

Improved Home experience

Connected Home experience to learner profile and progression data

Expanded application-wide navigation foundations

Improved connection between major application sections

✨ Premium Experience

Expanded Liquid Glass visual system

Added layered glass surfaces

Improved ambient lighting

Improved gradients and visual depth

Improved borders and shadows

Improved animations and transitions

Improved onboarding visual experience

Improved responsive layouts

Improved spacing and visual hierarchy

Improved application-wide visual consistency

🔧 Improved

Improved application architecture

Improved persistent application state management

Improved onboarding reliability

Improved learner profile integration

Improved progression architecture

Improved Learning Hub structure

Improved Mia architecture

Improved navigation foundations

Improved responsive behavior

Improved animation system

Improved premium UI consistency

Improved separation between profile, progression, memory and learning responsibilities

Prepared the application for a more advanced adaptive learning architecture

📚 What I Learned

During this version, I learned:

How to design a multi-screen Flutter learning application

How to build a more scalable application architecture

How to connect persistent learner data across multiple experiences

How to structure personalized onboarding at a larger scale

How to connect learner profiles with application navigation

How to structure persistent progression systems

How to separate learner profile, progression and memory responsibilities

How to design a modular Learning Hub

How to create a more personalized AI tutor foundation

How to build reusable premium Flutter interfaces

How to manage application state across multiple screens

How to prepare a Flutter application for future AI-powered learning

How to think about adaptive learning architecture before implementing the complete AI layer

🚀 V0.7.5 → V1.0

V0.7.5 establishes the foundation for Eloqia AI's transition toward its first complete product release.

Future development will focus on:

Real AI-powered learning

AI-generated lessons

Complete Grammar learning experience

Complete Vocabulary learning experience

Complete Reading learning experience

Complete Listening learning experience

Advanced Writing and Speaking experiences

Intelligent answer evaluation

Advanced AI-generated feedback

Adaptive difficulty

Personalized recommendations

Advanced Learning Memory

Real-time AI conversations

Natural voice interaction with Mia

Advanced Mia expressions and emotional responses

Gamified learning progression

Cloud synchronization

Premium subscription architecture

Multiple AI tutors

Complete adaptive AI language academy 🚀