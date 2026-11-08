import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'system_status.dart';

/// Explains in plain words why Mia may not speak or review.
class SystemStatusScreen extends StatefulWidget {
  const SystemStatusScreen({super.key, this.checker});

  /// Injected in tests.
  final Future<SystemStatus> Function()? checker;

  @override
  State<SystemStatusScreen> createState() => _SystemStatusScreenState();
}

class _SystemStatusScreenState extends State<SystemStatusScreen> {
  late Future<SystemStatus> _status = _run();

  Future<SystemStatus> _run() {
    final Future<SystemStatus> Function()? checker = widget.checker;
    if (checker != null) return checker();
    const String api = String.fromEnvironment('ELOQIA_API_URL');
    const String voice = String.fromEnvironment('ELOQIA_VOICE_API_URL');
    return SystemStatus.check(apiUrl: api.isNotEmpty ? api : voice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'System status',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Check again',
            onPressed: () => setState(() => _status = _run()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<SystemStatus>(
        future: _status,
        builder: (BuildContext context, AsyncSnapshot<SystemStatus> snap) {
          final SystemStatus? status = snap.data;
          if (status == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                status.allOk
                    ? 'Everything works: Mia can chat, review and speak.'
                    : 'Something needs attention:',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              for (final ServiceCheck check in status.checks)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: check.ok
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.warning.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        check.ok
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: check.ok ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              check.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              check.message,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
