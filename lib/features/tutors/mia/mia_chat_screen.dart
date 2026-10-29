import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../services/mia/mia_chat_client.dart';
import '../../../services/mia/mia_learning_notes.dart';
import '../../../services/voice/voice_output_provider.dart';
import '../../../services/voice/voice_session_client.dart'
    show OidcAccessTokenProvider;
import '../../../theme/app_colors.dart';
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

  bool get isInfo => !fromLearner && reply == null;
}

class _MiaChatScreenState extends State<MiaChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatEntry> _entries = <_ChatEntry>[];

  late final MiaChatClient? _client;
  late final MiaLearningNotes _notes;

  late MiaChatMode _mode;
  MiaScenario _scenario = MiaScenario.cafe;
  MiaWritingMode _writingMode = MiaWritingMode.learn;
  MiaImmersion _immersion = MiaImmersion.guided;

  bool _thinking = false;
  bool _autoSpeak = true;
  MiaPresenceState _miaState = MiaPresenceState.idle;

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
    _entries.add(_ChatEntry.info(_introFor(_mode)));
  }

  @override
  void dispose() {
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
      .where((_ChatEntry e) => !e.isInfo)
      .map(
        (_ChatEntry e) => MiaChatTurn(fromLearner: e.fromLearner, text: e.text),
      )
      .toList(growable: false);

  void _changeMode(MiaChatMode mode) {
    if (mode == _mode || _thinking) return;
    MiaVoice.provider.stop();
    setState(() {
      _mode = mode;
      _entries
        ..clear()
        ..add(_ChatEntry.info(_introFor(mode)));
      _miaState = MiaPresenceState.idle;
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
    final MiaChatClient? client = _client;
    final String text = _input.text.trim();
    if (text.isEmpty || _thinking) return;

    if (client == null) {
      setState(
        () => _entries.add(
          _ChatEntry.info(const MiaChatException('not_configured').message),
        ),
      );
      return;
    }

    final List<MiaChatTurn> history = _history;
    await MiaVoice.provider.stop();
    setState(() {
      _entries.add(_ChatEntry.learner(text));
      _input.clear();
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
        message: text,
        mode: _mode,
        profile: widget.profile,
        history: history,
        scenario: _scenario,
        writingMode: _writingMode,
        immersion: _immersion,
        knownDifficulties: difficulties,
      );
      if (!mounted) return;

      setState(() {
        _entries.add(_ChatEntry.mia(reply));
        _miaState = _stateFor(reply);
      });
      _scrollToEnd();
      await _notes.rememberFrom(reply);
      if (_autoSpeak) await _speak(reply);
    } on MiaChatException catch (error) {
      if (!mounted) return;
      setState(() {
        _entries.add(_ChatEntry.info(error.message));
        _miaState = MiaPresenceState.empathetic;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _entries.add(
          _ChatEntry.info(const MiaChatException('unknown').message),
        );
        _miaState = MiaPresenceState.empathetic;
      });
    } finally {
      if (mounted) setState(() => _thinking = false);
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
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _entries.length + (_thinking ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index == _entries.length) return const _ThinkingBubble();
              return _MessageBubble(
                entry: _entries[index],
                onListen: (MiaChatReply reply) => _speak(reply),
              );
            },
          ),
        ),
        _buildComposer(),
      ],
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
          IconButton.filled(
            key: const Key('mia-chat-send'),
            tooltip: 'Envoyer',
            onPressed: _thinking ? null : _send,
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
  const _MessageBubble({required this.entry, required this.onListen});

  final _ChatEntry entry;
  final ValueChanged<MiaChatReply> onListen;

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
