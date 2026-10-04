import 'package:flutter/material.dart';

import '../../services/voice/voice_output_provider.dart';
import '../../theme/app_colors.dart';
import '../tutors/mia/widgets/mia_presence.dart';
import 'onboarding_screen.dart';

class MiaWelcomeScreen extends StatefulWidget {
  const MiaWelcomeScreen({super.key});

  @override
  State<MiaWelcomeScreen> createState() => _MiaWelcomeScreenState();
}

class _MiaWelcomeScreenState extends State<MiaWelcomeScreen> {
  late final Future<bool> _voiceAvailability;

  @override
  void initState() {
    super.initState();
    _voiceAvailability = MiaVoice.provider.isAvailable();
  }

  Future<void> _speak() async {
    await MiaVoice.provider.speak(
      "Hi, I'm Mia. Welcome to Eloqia. We'll build an English learning path around your goals and the way you learn.",
      style: MiaSpeechStyle.warm,
    );
  }

  void _continue() {
    Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final Animation<double> curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return Opacity(opacity: 0.65 + 0.35 * curved.value, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.65, -0.5),
                radius: 1.4,
                colors: <Color>[
                  Color(0xFF132938),
                  AppColors.background,
                  Color(0xFF080A10),
                ],
                stops: <double>[0, 0.55, 1],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool wide = constraints.maxWidth >= 850;
                final double portraitSize = wide ? 292 : 204;
                final Widget portrait = Center(
                  child: MiaPresence(
                    size: portraitSize,
                    showLabel: true,
                    state: MiaPresenceState.encouraging,
                  ),
                );
                final Widget introduction = _introduction(wide: wide);
                final Widget content = wide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(width: 390, child: portrait),
                          const SizedBox(width: 44),
                          SizedBox(width: 470, child: introduction),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          portrait,
                          const SizedBox(height: 14),
                          introduction,
                        ],
                      );

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 42,
                        ),
                        child: Center(child: content),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _introduction({required bool wide}) {
    final double headingSize = wide ? 44 : 34;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          'ELOQIA AI  /  YOUR TUTOR',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            color: AppColors.electricBlue,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Hi, I'm Mia.",
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: headingSize,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "We'll shape your English learning path around your goals, your interests, and the way you learn best.",
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            FutureBuilder<bool>(
              future: _voiceAvailability,
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                final bool available = snapshot.data == true;
                return ValueListenableBuilder<bool>(
                  valueListenable: MiaVoice.provider.speaking,
                  builder:
                      (BuildContext context, bool isSpeaking, Widget? child) {
                        return OutlinedButton.icon(
                          onPressed: available
                              ? isSpeaking
                                    ? MiaVoice.provider.stop
                                    : _speak
                              : null,
                          icon: Icon(
                            isSpeaking
                                ? Icons.stop_rounded
                                : Icons.volume_up_rounded,
                          ),
                          label: Text(
                            snapshot.connectionState == ConnectionState.waiting
                                ? 'Checking voice'
                                : isSpeaking
                                ? 'Stop Mia'
                                : 'Hear Mia',
                          ),
                        );
                      },
                );
              },
            ),
            FilledButton.icon(
              onPressed: _continue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text("Let's begin"),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<bool>(
          future: _voiceAvailability,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            return Text(
              snapshot.data == true
                  ? '${MiaVoice.provider.description}. A California-specific accent cannot be guaranteed by device speech.'
                  : 'No US English device voice is available. A cloud voice needs secure provider configuration.',
              textAlign: wide ? TextAlign.left : TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            );
          },
        ),
      ],
    );
  }
}
