import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/lesson_models.dart';

/// Key vocabulary and idioms of a real video, folded until opened.
class MediaVocabularyCard extends StatelessWidget {
  const MediaVocabularyCard({super.key, required this.media});

  final MediaInfo media;

  @override
  Widget build(BuildContext context) {
    if (media.vocabulary.isEmpty && media.idioms.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white08),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const Key('media-vocabulary'),
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            'Key vocabulary (${media.vocabulary.length}) · '
            'Expressions (${media.idioms.length})',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final VocabItem item in media.vocabulary) _item(item),
            if (media.idioms.isNotEmpty) ...<Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 6, bottom: 6),
                child: Text(
                  'Idioms and expressions',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final VocabItem item in media.idioms) _item(item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _item(VocabItem item) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(
          TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: item.term,
                style: const TextStyle(
                  color: AppColors.primaryBright,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(text: ' — ${item.meaning}'),
            ],
          ),
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        if (item.example != null)
          Text(
            '“${item.example}”',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
              fontSize: 12.5,
            ),
          ),
      ],
    ),
  );
}
