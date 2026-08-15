import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/ephemeral/ephemeral_controller.dart';
import 'package:text_data/core/ephemeral/ephemeral_policy.dart';
import 'package:text_data/l10n/app_localizations.dart';

/// The countdown badge on an ephemeral tab chip (Feature 9).
///
/// Shows nothing at all for a normal tab, so it can sit unconditionally in the
/// tab strip. It redraws off the shared one-second tick in
/// [EphemeralController] rather than running a timer of its own, so twenty open
/// tabs still cost one timer.
class EphemeralBadge extends ConsumerWidget {
  final String tabId;

  const EphemeralBadge({super.key, required this.tabId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ephemeralControllerProvider);
    final mark = state[tabId];
    if (mark == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final left = EphemeralPolicy.remaining(mark, state.nowMillis);
    final urgent = EphemeralPolicy.isUrgent(left);
    final color = urgent ? theme.colorScheme.error : theme.colorScheme.primary;
    final label = EphemeralPolicy.formatRemaining(left);

    return Tooltip(
      message: mark.hasTimer
          ? l10n.ephemeralBadgeTimerTooltip(label)
          : l10n.ephemeralBadgeOutputTooltip,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              // A tab with no timer burns on its next export, so the hourglass
              // would be misleading — it shows the "one-shot" icon instead.
              mark.hasTimer
                  ? Icons.timer_outlined
                  : Icons.local_fire_department,
              size: 13,
              color: color,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
