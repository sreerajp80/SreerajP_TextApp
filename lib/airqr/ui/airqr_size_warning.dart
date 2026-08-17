import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/airqr/airqr_constants.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// The size gate that stands in front of every send.
///
/// An optical link moves roughly 10-20 KB per second, so the honest thing is to
/// tell the user what a transfer will cost them in time *before* they start
/// holding two phones together, not after. Three bands:
///
///   * under the soft cap  — start immediately, say nothing;
///   * over the warn cap   — show the estimate and offer LAN sync instead;
///   * over the hard cap   — refuse, and point at LAN sync.
class AirqrSizeWarning {
  AirqrSizeWarning._();

  /// Returns true when the transfer should go ahead.
  ///
  /// [byteCount] is the size of the content being sent, before compression —
  /// gzip usually shrinks it a lot, but promising a speed-up we have not
  /// measured yet would be worse than a pessimistic estimate.
  static Future<bool> confirm({
    required BuildContext context,
    required int byteCount,
  }) async {
    final l10n = AppLocalizations.of(context);

    if (byteCount > AirqrConstants.hardCapBytes) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.block),
          title: Text(l10n.airqrTooLargeTitle),
          content: Text(
            l10n.airqrTooLargeBody(
              _formatSize(byteCount),
              _formatSize(AirqrConstants.hardCapBytes),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionOk),
            ),
          ],
        ),
      );
      return false;
    }

    if (byteCount <= AirqrConstants.warnCapBytes) return true;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.hourglass_top),
        title: Text(l10n.airqrSlowTitle),
        content: Text(
          l10n.airqrSlowBody(
            _formatSize(byteCount),
            _formatDuration(context, _estimate(byteCount)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.airqrSendAnyway),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  /// How long [byteCount] will take at the measured optical rate.
  static Duration _estimate(int byteCount) => Duration(
    seconds: (byteCount / AirqrConstants.estimatedBytesPerSecond).ceil(),
  );

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
    return '$bytes B';
  }

  static String _formatDuration(BuildContext context, Duration d) {
    final l10n = AppLocalizations.of(context);
    if (d.inMinutes >= 1) {
      return l10n.airqrAboutMinutes(d.inMinutes);
    }
    return l10n.airqrAboutSeconds(d.inSeconds);
  }
}
