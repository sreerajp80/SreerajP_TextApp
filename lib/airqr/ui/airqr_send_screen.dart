import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:text_data/airqr/airqr_constants.dart';
import 'package:text_data/airqr/airqr_payload.dart';
import 'package:text_data/airqr/airqr_provider.dart';
import 'package:text_data/l10n/app_localizations.dart';

/// Shows the animated QR stream for one payload.
///
/// The screen keeps running until the user leaves: the sender has no way to
/// know the other device is finished, because the optical link is one-way. That
/// is why the loop never stops on its own and the user is the one who decides
/// it is done.
class AirqrSendScreen extends StatefulWidget {
  final AirqrPayload payload;

  const AirqrSendScreen({super.key, required this.payload});

  @override
  State<AirqrSendScreen> createState() => _AirqrSendScreenState();
}

class _AirqrSendScreenState extends State<AirqrSendScreen> {
  late final AirqrSendController _controller = AirqrSendController(
    payload: widget.payload,
  );

  @override
  void initState() {
    super.initState();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.airqrSendTitle)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final error = _controller.errorMessage;
          if (error != null) return _SendError(message: error);
          return _SendBody(controller: _controller);
        },
      ),
    );
  }
}

class _SendBody extends StatelessWidget {
  final AirqrSendController controller;

  const _SendBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final frame = controller.currentFrame;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // The QR sits on a fixed white card. A dark-theme background behind a
        // QR wrecks the contrast scanners depend on, so this one panel stays
        // white in both themes on purpose.
        Center(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: frame == null
                  ? const SizedBox(width: 260, height: 260)
                  : QrImageView(
                      data: frame,
                      version: QrVersions.auto,
                      size: 260,
                      backgroundColor: Colors.white,
                      // Level M repairs a blurred or partly covered symbol.
                      // This is the error correction that genuinely helps; a
                      // frame the camera never sees at all is handled by
                      // looping instead (see AirqrSender).
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (controller.isEncrypted) _CodeCard(controller: controller),
        if (!controller.isEncrypted) const _UnsealedWarning(),

        const SizedBox(height: 16),
        Text(l10n.airqrHoldSteady, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.airqrFrameCount(controller.totalFrames),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              l10n.airqrPassCount(controller.passesCompleted),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.airqrOnePassTakes(controller.onePassDuration.inSeconds),
          style: theme.textTheme.bodySmall,
        ),

        const Divider(height: 32),
        _SpeedSlider(controller: controller),
        _DensitySlider(controller: controller),
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  final AirqrSendController controller;

  const _CodeCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(l10n.airqrCodeLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SelectableText(
              controller.formattedCode ?? '',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: 'JetBrains Mono',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.airqrCodeHint,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsealedWarning extends StatelessWidget {
  const _UnsealedWarning();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.airqrUnsealedWarning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedSlider extends StatelessWidget {
  final AirqrSendController controller;

  const _SpeedSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.airqrSpeedLabel(controller.fps)),
        Slider(
          value: controller.fps.toDouble(),
          min: AirqrConstants.minFps.toDouble(),
          max: AirqrConstants.maxFps.toDouble(),
          divisions: AirqrConstants.maxFps - AirqrConstants.minFps,
          label: '${controller.fps}',
          onChanged: (v) => controller.setFps(v.round()),
        ),
        Text(l10n.airqrSpeedHelp, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DensitySlider extends StatelessWidget {
  final AirqrSendController controller;

  const _DensitySlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(l10n.airqrDensityLabel(controller.chunkBytes)),
        Slider(
          value: controller.chunkBytes.toDouble(),
          min: AirqrConstants.minChunkBytes.toDouble(),
          max: AirqrConstants.maxChunkBytes.toDouble(),
          divisions:
              (AirqrConstants.maxChunkBytes - AirqrConstants.minChunkBytes) ~/
              100,
          label: '${controller.chunkBytes}',
          onChanged: (v) => controller.setChunkBytes(v.round()),
        ),
        Text(
          l10n.airqrDensityHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SendError extends StatelessWidget {
  final String message;

  const _SendError({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
