import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// Warns that the crash-recovery draft could not be written.
///
/// Auto-save is a silent promise: it runs in the background and the user is
/// meant to forget about it. That makes a broken one dangerous — without this
/// banner they would keep typing, believing the work is protected, and lose it
/// all if the app were killed. Shown by every format's document view; the
/// auto-saver keeps retrying, so it disappears on its own once a write succeeds.
class AutoSaveFailingBanner extends StatelessWidget {
  const AutoSaveFailingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('auto-save-failing-banner'),
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.sync_problem_outlined,
            size: 18,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).editorAutoSaveFailing,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
