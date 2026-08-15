import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:text_data/airqr/airqr_constants.dart';
import 'package:text_data/airqr/airqr_payload.dart';
import 'package:text_data/airqr/airqr_provider.dart';
import 'package:text_data/l10n/app_localizations.dart';

/// Receives an animated QR stream: scan, then unlock, then use the result.
class AirqrReceiveScreen extends ConsumerWidget {
  const AirqrReceiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.watch(airqrReceiveControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.airqrReceiveTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          switch (controller.phase) {
            case AirqrReceivePhase.scanning:
              return _ScanningBody(controller: controller);
            case AirqrReceivePhase.needCode:
              return _CodeEntryBody(controller: controller);
            case AirqrReceivePhase.assembling:
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.airqrAssembling),
                  ],
                ),
              );
            case AirqrReceivePhase.done:
              return _ResultBody(payload: controller.result!);
            case AirqrReceivePhase.error:
              return _ErrorBody(controller: controller);
          }
        },
      ),
    );
  }
}

class _ScanningBody extends StatelessWidget {
  final AirqrReceiveController controller;

  const _ScanningBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: Semantics(
            label: l10n.airqrScanSemantics,
            child: MobileScanner(
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final raw = barcode.rawValue;
                  if (raw != null) controller.onScan(raw);
                }
              },
            ),
          ),
        ),
        _ProgressPanel(controller: controller),
      ],
    );
  }
}

/// The live readout: how much has arrived, how fast, and how much longer.
class _ProgressPanel extends StatelessWidget {
  final AirqrReceiveController controller;

  const _ProgressPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final total = controller.totalFrames;
    final rejection = controller.lastRejection;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (total == null) ...[
              Text(
                l10n.airqrLookingForStream,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ] else ...[
              Text(
                l10n.airqrFramesProgress(controller.framesReceived, total),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: controller.progress),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.airqrFps(
                      controller.framesPerSecond.toStringAsFixed(1),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (controller.estimatedRemaining != null)
                    Text(
                      l10n.airqrRemaining(
                        controller.estimatedRemaining!.inSeconds,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              if (controller.missingCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.airqrStillMissing(controller.missingCount),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
            if (rejection != null) ...[
              const SizedBox(height: 8),
              Text(
                rejection,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CodeEntryBody extends StatefulWidget {
  final AirqrReceiveController controller;

  const _CodeEntryBody({required this.controller});

  @override
  State<_CodeEntryBody> createState() => _CodeEntryBodyState();
}

class _CodeEntryBodyState extends State<_CodeEntryBody> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final error = widget.controller.errorMessage;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          l10n.airqrAllFramesReceived,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.airqrEnterCodePrompt,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _code,
          autofocus: true,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 24,
            letterSpacing: 4,
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              // Allow room for the separators a user may copy along with it.
              AirqrConstants.longCodeLength * 2,
            ),
          ],
          decoration: InputDecoration(
            labelText: l10n.airqrCodeLabel,
            border: const OutlineInputBorder(),
            errorText: error,
          ),
          onSubmitted: widget.controller.submitCode,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => widget.controller.submitCode(_code.text),
          icon: const Icon(Icons.lock_open),
          label: Text(l10n.airqrUnlock),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.controller.restart,
          child: Text(l10n.airqrStartOver),
        ),
      ],
    );
  }
}

/// What arrived, and what the user can do with it.
///
/// A received document is **not** written anywhere automatically. The user
/// saves it through their own SAF picker, which is what keeps the sender from
/// having any say over where a file lands (CLAUDE.md §3 rule 3).
class _ResultBody extends StatelessWidget {
  final AirqrPayload payload;

  const _ResultBody({required this.payload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final charCount = payload.content.length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.airqrReceivedTitle,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(
              payload.isDocument ? Icons.description_outlined : Icons.notes,
            ),
            title: Text(payload.name),
            subtitle: Text(l10n.airqrCharacterCount(charCount)),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.airqrPreview, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: Text(
              payload.content,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: payload.content));
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.airqrCopied)));
          },
          icon: const Icon(Icons.copy),
          label: Text(l10n.airqrCopyText),
        ),
        const SizedBox(height: 8),
        // Handing the text back to the caller lets the opener decide what to do
        // with it — save it as a new document, or paste it into the open one.
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(payload),
          icon: const Icon(Icons.save_outlined),
          label: Text(l10n.airqrUseThis),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final AirqrReceiveController controller;

  const _ErrorBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage ?? l10n.airqrFailedGeneric,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: controller.restart,
              child: Text(l10n.airqrStartOver),
            ),
          ],
        ),
      ),
    );
  }
}
