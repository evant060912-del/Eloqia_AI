import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../services/mia/mia_chat_client.dart';
import '../../../services/mia/mia_learning_notes.dart';
import '../../../services/mia/mia_session_recorder.dart';
import '../../../services/voice/voice_output_provider.dart';
import '../../../services/voice/voice_session_client.dart'
    show OidcAccessTokenProvider;
import '../../../theme/app_colors.dart';
import '../../speaking/widgets/mic_button.dart';
import 'mia_session_summary_screen.dart';
import 'widgets/mia_presence.dart';

/// Large discussion screen with Mia's AI brain (turn-by-turn).
///
/// Wide screens: Mia on the left, conversation on the right.
/// Phones: full-screen conversation with Mia in the header.
class MiaChatScreen extends StatefulWidget {
  const MiaChatScreen({
    super.key,
    required this.profile,
    this.accessTokenProvider,
    this.client,
    this.notes,
    this.initialMode = MiaChatMode.conversation,
  });

  final LearningProfile profile;
  final OidcAccessTokenProvider? accessTokenProvider;

  /// Injected in tests; built from `--dart-define` otherwise.
  final MiaChatClient? client;
  final MiaLearningNotes? notes;
  final MiaChatMode initialMode;

  @override
  State<MiaChatScreen> createState() => _MiaChatScreenState();
}

class _ChatEntry {
  _ChatEntry.learner(this.text) : fromLearner = true, reply = null;

  _ChatEntry.mia(MiaChatReply this.reply)
    : fromLearner = false,
      text = reply.reply;

  _ChatEntry.info(this.text) : fromLearner = false, reply = null;

  final bool fromLearner;
  final String text;
  final MiaChatReply? reply;

  /// A learner message whose answer failed: it can be sent again.
  bool failed = false;

  bool get isInfo => !fromLearner && reply == null;
}

class _MiaChatScreenState extends State<MiaChatScreen> {
  final TextEditingController _input = TextEditingController();

  /// Text typed before the current dictation (dictation is appended).
  String _beforeDictation = '';
  bool _dictating = false;
  final ScrollController _scroll = ScrollController();
  final List<_ChatEntry> _entries = <_ChatEntry>[];

  late final MiaChatClient? _client;
  late final MiaLearningNotes _notes;

  late MiaChatMode _mode;
  MiaScenario _scenario = MiaScenario.cafe;
  MiaWritingMode _writingMode = MiaWritingMode.learn;
  MiaImmersion _immersion = MiaImmersion.guided;

  bool _thinking = false;
  bool _endingSession = false;
  bool _autoSpeak = true;
  MiaPresenceState _miaState = MiaPresenceState.idle;

  /// Changes whenever a new session starts: late answers from an older
  /// session are ignored instead of appearing in the new one.
  int _generation = 0;
  late String _sessionId;
  late DateTime _sessionStart;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _client =
        widget.client ??
        MiaChatClient.fromEnvironment(
          accessTokenProvider: widget.accessTokenProvider,
        );
    _notes = widget.notes ?? MiaLearningNotes();
    _startSession();
  }

  /// Starts a fresh session with Mia's opening message.
  void _startSession({String? opening}) {
    _generation++;
    _sessionId =
        'mia-${_mode.apiValue}-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    _sessionStart = DateTime.now();
    _thinking = false;
    _miaState = MiaPresenceState.idle;
    _entries
      ..clear()
      ..add(
        _ChatEntry.mia(
          MiaChatReply(
            reply: opening ?? _introFor(_mode),
            tone: MiaSpeechStyle.warm,
          ),
        ),
      );
  }

  @override
  void dispose() {
    _generation++;
    MiaVoice.provider.stop();
    _input.dispose();
    _scroll.dispose();
    if (widget.client == null) _client?.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Logic
  // ---------------------------------------------------------------------------

  String _introFor(MiaChatMode mode) {
    final String name = widget.profile.name.trim();
    final String hello = name.isEmpty ? 'Hi!' : 'Hi $name!';
    return switch (mode) {
      MiaChatMode.conversation =>
        '$hello What would you like to talk about today?',
      MiaChatMode.ask =>
        '$hello Ask me anything about English: grammar, words, '
            'how people really say things...',
      MiaChatMode.roleplay =>
        '$hello Pick a situation, then say your first line. '
            "I'll play the other person.",
      MiaChatMode.writing =>
        '$hello Paste or write your text. I will explain how to '
            'improve it, without rewriting your style.',
    };
  }

  List<MiaChatTurn> get _history => _entries
      .where((_ChatEntry e) => !e.isInfo && !e.failed)
      .map(
        (_ChatEntry e) => MiaChatTurn(fromLearner: e.fromLearner, text: e.text),
      )
      .toList(growable: false);

  _ChatEntry? get _lastLearnerEntry {
    for (int i = _entries.length - 1; i >= 0; i--) {
      if (_entries[i].fromLearner) return _entries[i];
    }
    return null;
  }

  void _changeMode(MiaChatMode mode) {
    if (mode == _mode || _endingSession) return;
    MiaVoice.provider.stop();
    setState(() {
      _mode = mode;
      _startSession();
    });
  }

  void _changeScenario(MiaScenario scenario) {
    if (_thinking) return;
    setState(() {
      _scenario = scenario;
      _entries
        ..clear()
        ..add(
          _ChatEntry.info(
            '${scenario.emoji} ${scenario.label}: '
            'say your first line!',
          ),
        );
    });
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _thinking || _endingSession) return;

    if (_client == null) {
      setState(
        () => _entries.add(
          _ChatEntry.info(const MiaChatException('not_configured').message),
        ),
      );
      return;
    }

    final _ChatEntry entry = _ChatEntry.learner(text);
    setState(() {
      _entries.add(entry);
      _input.clear();
    });
    await _ask(entry);
  }

  /// Sends a failed message again without duplicating it.
  Future<void> _retry(_ChatEntry entry) async {
    if (_thinking ||
        _endingSession ||
        !entry.failed ||
        entry != _lastLearnerEntry) {
      return;
    }
    setState(() {
      _entries.removeWhere((_ChatEntry e) => e.isInfo && e != _entries.first);
      entry.failed = false;
    });
    await _ask(entry);
  }

  Future<void> _ask(_ChatEntry entry) async {
    final MiaChatClient client = _client!;
    final int generation = _generation;
    // Everything said before this message (the message itself is sent
    // separately; failed messages and notices are left out).
    final int index = _entries.indexOf(entry);
    final List<MiaChatTurn> history = _entries
        .take(index < 0 ? _entries.length : index)
        .where((_ChatEntry e) => !e.isInfo && !e.failed)
        .map(
          (_ChatEntry e) =>
              MiaChatTurn(fromLearner: e.fromLearner, text: e.text),
        )
        .toList(growable: false);

    await MiaVoice.provider.stop();
    if (!mounted || generation != _generation) return;
    setState(() {
      _thinking = true;
      _miaState = MiaPresenceState.thinking;
    });
    _scrollToEnd();

    try {
      final List<String> difficulties = <String>[
        ...await _notes.difficultiesForMia(),
        ...widget.profile.difficulties,
      ];
      final MiaChatReply reply = await client.send(
        message: entry.text,
        mode: _mode,
        profile: widget.profile,
        history: history,
        scenario: _scenario,
        writingMode: _writingMode,
        immersion: _immersion,
        knownDifficulties: difficulties,
      );
      if (!mounted || generation != _generation) return;

      setState(() {
        _entries.add(_ChatEntry.mia(reply));
        _miaState = _stateFor(reply);
        _thinking = false;
      });
      _scrollToEnd();
      await _notes.rememberFrom(reply, sessionId: _sessionId);
      if (_autoSpeak && mounted && generation == _generation) {
        await _speak(reply);
      }
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      final String message = error is MiaChatException
          ? error.message
          : const MiaChatException('unknown').message;
      setState(() {
        entry.failed = true;
        _entries.add(_ChatEntry.info(message));
        _miaState = MiaPresenceState.empathetic;
        _thinking = false;
      });
      _scrollToEnd();
    }
  }

  Future<void> _endSession() async {
    final MiaChatClient? client = _client;
    final List<MiaChatTurn> history = _history;
    final bool learnerSpoke = history.any((MiaChatTurn t) => t.fromLearner);
    if (_endingSession || _thinking) return;

    if (!learnerSpoke || client == null) {
      Navigator.of(context).maybePop();
      return;
    }

    await MiaVoice.provider.stop();
    final int generation = ++_generation; // Ignore any late answer.
    setState(() {
      _endingSession = true;
      _miaState = MiaPresenceState.thinking;
    });

    MiaSessionSummary? summary;
    String? summaryError;
    try {
      summary = await client.summarize(
        history: history,
        mode: _mode,
        profile: widget.profile,
        scenario: _mode == MiaChatMode.roleplay ? _scenario : null,
      );
    } on MiaChatException catch (error) {
      summaryError = error.message;
    } on Object {
      summaryError = const MiaChatException('mia_summary_unavailable').message;
    }

    final MiaSessionRecord record = await MiaSessionRecorder.record(
      sessionId: _sessionId,
      mode: _mode,
      history: history,
      profile: widget.profile,
      duration: DateTime.now().difference(_sessionStart),
      scenario: _mode == MiaChatMode.roleplay ? _scenario : null,
      summary: summary,
    );
    if (!mounted || generation != _generation) return;

    final bool? again = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MiaSessionSummaryScreen(
          summary: summary,
          errorMessage: summaryError,
          record: record,
          learnerTurns: history.where((MiaChatTurn t) => t.fromLearner).length,
        ),
      ),
    );
    if (!mounted) return;
    if (again == true) {
      setState(() {
        _endingSession = false;
        _startSession();
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _speak(MiaChatReply reply) async {
    final VoiceProvider voice = MiaVoice.provider;
    if (!await voice.isAvailable()) return;
    try {
      await voice.speak(reply.reply, style: reply.tone);
    } on Object {
      // Voice is a bonus: the text is already on screen.
    }
  }

  MiaPresenceState _stateFor(MiaChatReply reply) {
    if (reply.safetyRedirect) return MiaPresenceState.empathetic;
    if (reply.scenarioComplete) return MiaPresenceState.celebrating;
    if (reply.corrections.isNotEmpty) return MiaPresenceState.correcting;
    return switch (reply.tone) {
      MiaSpeechStyle.warm => MiaPresenceState.happy,
      MiaSpeechStyle.excited => MiaPresenceState.celebrating,
      MiaSpeechStyle.encouraging => MiaPresenceState.encouraging,
      MiaSpeechStyle.playful => MiaPresenceState.playful,
      MiaSpeechStyle.serious => MiaPresenceState.serious,
      MiaSpeechStyle.calm => MiaPresenceState.idle,
    };
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _confirmClearNotes() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Effacer les notes de Mia ?'),
        content: const Text(
          'Mia garde sur cet appareil de courtes notes sur tes difficultés '
          '(pas tes conversations) pendant 30 jours. Elles seront supprimées.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _notes.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notes de Mia effacées.')));
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Mia', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: MiaVoice.provider.speaking,
            builder: (BuildContext context, bool speaking, Widget? child) =>
                speaking
                ? IconButton(
                    key: const Key('mia-chat-stop-voice'),
                    tooltip: 'Arrêter la voix de Mia',
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () => MiaVoice.provider.stop(),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: _autoSpeak ? 'Voix de Mia activée' : 'Voix de Mia coupée',
            icon: Icon(
              _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            ),
            onPressed: () {
              setState(() => _autoSpeak = !_autoSpeak);
              if (!_autoSpeak) MiaVoice.provider.stop();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton.icon(
              key: const Key('mia-chat-end'),
              onPressed: _endingSession || _thinking ? null : _endSession,
              icon: _endingSession
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flag_rounded, size: 18),
              label: const Text('Terminer'),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (String value) {
              if (value == 'clear') _confirmClearNotes();
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'clear',
                child: Text('Effacer les notes de Mia'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 900;
            final Widget conversation = _buildConversation(compact: !wide);
            if (!wide) return conversation;
            return Row(
              children: <Widget>[
                SizedBox(width: 320, child: _buildSidePanel()),
                const VerticalDivider(width: 1, color: AppColors.glassBorder),
                Expanded(child: conversation),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(child: MiaPresence(size: 180, state: _miaState)),
          const SizedBox(height: 24),
          _buildModeSelector(vertical: true),
          const SizedBox(height: 16),
          ..._buildModeOptions(),
          const SizedBox(height: 16),
          _buildImmersionSelector(),
        ],
      ),
    );
  }

  Widget _buildConversation({required bool compact}) {
    return Column(
      children: <Widget>[
        if (compact) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: <Widget>[
                MiaPresence(size: 64, state: _miaState, showLabel: false),
                const SizedBox(width: 12),
                Expanded(child: _buildModeSelector(vertical: false)),
              ],
            ),
          ),
          ..._buildModeOptions().map(
            (Widget w) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: w,
            ),
          ),
        ],
        _buildObjective(),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _entries.length + (_thinking ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index == _entries.length) return const _ThinkingBubble();
              final _ChatEntry entry = _entries[index];
              return _MessageBubble(
                entry: entry,
                onListen: (MiaChatReply reply) => _speak(reply),
                // Only the latest message can be retried, to keep the order.
                onRetry: entry.failed && entry == _lastLearnerEntry
                    ? () => _retry(entry)
                    : null,
              );
            },
          ),
        ),
        _buildComposer(),
      ],
    );
  }

  Widget _buildObjective() {
    final String objective = _mode == MiaChatMode.roleplay
        ? '${_scenario.emoji} ${_scenario.label}'
        : _mode.description;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.track_changes_rounded,
            size: 14,
            color: AppColors.primaryBright,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              objective,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector({required bool vertical}) {
    final List<Widget> chips = MiaChatMode.values
        .map(
          (MiaChatMode mode) => Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: ChoiceChip(
              label: Text(mode.label),
              tooltip: mode.description,
              selected: _mode == mode,
              onSelected: (_) => _changeMode(mode),
            ),
          ),
        )
        .toList();
    if (vertical) return Wrap(children: chips);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  List<Widget> _buildModeOptions() {
    if (_mode == MiaChatMode.roleplay) {
      return <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: MiaScenario.values
                .map(
                  (MiaScenario s) => Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: ChoiceChip(
                      label: Text('${s.emoji} ${s.label}'),
                      selected: _scenario == s,
                      onSelected: (_) => _changeScenario(s),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ];
    }
    if (_mode == MiaChatMode.writing) {
      return <Widget>[
        SegmentedButton<MiaWritingMode>(
          segments: MiaWritingMode.values
              .map(
                (MiaWritingMode m) => ButtonSegment<MiaWritingMode>(
                  value: m,
                  label: Text(m.label),
                ),
              )
              .toList(),
          selected: <MiaWritingMode>{_writingMode},
          onSelectionChanged: (Set<MiaWritingMode> s) =>
              setState(() => _writingMode = s.first),
        ),
        const SizedBox(height: 8),
      ];
    }
    return const <Widget>[];
  }

  Widget _buildImmersionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'IMMERSION',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<MiaImmersion>(
          segments: MiaImmersion.values
              .map(
                (MiaImmersion m) =>
                    ButtonSegment<MiaImmersion>(value: m, label: Text(m.label)),
              )
              .toList(),
          selected: <MiaImmersion>{_immersion},
          onSelectionChanged: (Set<MiaImmersion> s) =>
              setState(() => _immersion = s.first),
        ),
      ],
    );
  }

  /// The microphone fills the input; the learner reads it, edits it if the
  /// recogniser misheard, then sends it.
  void _onDictation(String text, bool isFinal) {
    if (!_dictating) {
      _dictating = true;
      _beforeDictation = _input.text.trimRight();
    }
    final String joined = <String>[
      if (_beforeDictation.isNotEmpty) _beforeDictation,
      if (text.trim().isNotEmpty) text.trim(),
    ].join(' ');
    _input.value = TextEditingValue(
      text: joined,
      selection: TextSelection.collapsed(offset: joined.length),
    );
    if (isFinal) _dictating = false;
  }

  Widget _buildComposer() {
    final bool writing = _mode == MiaChatMode.writing;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              key: const Key('mia-chat-input'),
              controller: _input,
              minLines: 1,
              maxLines: writing ? 10 : 4,
              maxLength: writing
                  ? MiaChatClient.maxWritingChars
                  : MiaChatClient.maxTurnChars,
              textInputAction: writing
                  ? TextInputAction.newline
                  : TextInputAction.send,
              onSubmitted: writing ? null : (_) => _send(),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                hintText: writing
                    ? 'Write or paste your text…'
                    : 'Write to Mia…',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MicButton(
            onText: _onDictation,
            enabled: !_thinking && !_endingSession,
            maxDuration: Duration(minutes: writing ? 3 : 1),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            key: const Key('mia-chat-send'),
            tooltip: 'Envoyer',
            onPressed: _thinking || _endingSession ? null : _send,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bubbles
// =============================================================================

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.entry,
    required this.onListen,
    this.onRetry,
  });

  final _ChatEntry entry;
  final ValueChanged<MiaChatReply> onListen;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final MiaChatReply? reply = entry.reply;
    final bool learner = entry.fromLearner;

    final Color background = learner
        ? AppColors.primaryDeep
        : entry.isInfo
        ? AppColors.glass
        : AppColors.surfaceElevated;

    return Align(
      alignment: learner ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SelectableText(
                entry.text,
                style: TextStyle(
                  color: entry.isInfo
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              if (reply != null) ..._details(reply),
              if (onRetry != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Réessayer'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _details(MiaChatReply reply) {
    return <Widget>[
      if (reply.corrections.isNotEmpty) ...<Widget>[
        const SizedBox(height: 12),
        ...reply.corrections.map(_CorrectionCard.new),
      ],
      if (reply.writingScore != null) ...<Widget>[
        const SizedBox(height: 10),
        _ScoreCard(score: reply.writingScore!),
      ],
      if (reply.usefulExpressions.isNotEmpty) ...<Widget>[
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: reply.usefulExpressions
              .map(
                (String e) => Chip(
                  label: Text(e, style: const TextStyle(fontSize: 12)),
                  avatar: const Icon(Icons.bookmark_add_outlined, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        ),
      ],
      Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: 'Écouter Mia',
          icon: const Icon(
            Icons.play_circle_outline_rounded,
            color: AppColors.primaryBright,
          ),
          onPressed: () => onListen(reply),
        ),
      ),
    ];
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard(this.correction);

  final MiaCorrection correction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warmthGlow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            correction.category.toUpperCase(),
            style: const TextStyle(
              color: AppColors.warmth,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: correction.original,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const TextSpan(text: '  →  '),
                TextSpan(
                  text: correction.suggestion,
                  style: const TextStyle(
                    color: AppColors.primaryBright,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          if (correction.explanation.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              correction.explanation,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});

  final MiaWritingScore score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Practice score: ${score.total}/${score.maximum}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          ...score.criteria.entries.map(
            (MapEntry<String, int> e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 96,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: e.value / 5,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${e.value}/5',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Text(
            'Estimation d\'entraînement, pas une note officielle.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Mia is thinking…',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
