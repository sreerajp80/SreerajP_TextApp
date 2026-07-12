import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/editor/editor_providers.dart';
import '../../core/large_file/paged_text.dart';
import '../../core/storage/saf_exceptions.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import 'document_tab.dart';

/// The body shown for a file that is too big for the normal editor (Phase 10,
/// task 10.2). It opens the file **read-only**, one page at a time, with a clear
/// notice that editing is turned off — so a very large file never crashes the
/// app and keeps the on-screen work small (arch §11, CLAUDE.md §3.4).
///
/// This view holds no format session and no editor controller. It reads the
/// bytes once, decodes them with the shared codec, and renders one page of text
/// at a time. Because it keeps no heavy per-tab state, it is naturally cheap to
/// drop and rebuild when the user switches tabs (task 10.3).
class DegradedDocumentView extends ConsumerStatefulWidget {
  final DocumentTab tab;

  /// Lines shown per page. Small enough to keep the widget tree light.
  final int linesPerPage;

  const DegradedDocumentView({
    super.key,
    required this.tab,
    this.linesPerPage = 500,
  });

  @override
  ConsumerState<DegradedDocumentView> createState() =>
      _DegradedDocumentViewState();
}

enum _LoadState { loading, ready, failed }

class _DegradedDocumentViewState extends ConsumerState<DegradedDocumentView> {
  _LoadState _state = _LoadState.loading;
  String? _error;
  PagedText? _paged;
  int _pageIndex = 0;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _state = _LoadState.loading;
      _error = null;
    });
    final saf = ref.read(safServiceProvider);
    final codec = ref.read(textCodecServiceProvider);
    try {
      final bytes = await saf.readBytes(widget.tab.uri);
      final decoded = codec.detectAndDecode(bytes);
      if (!mounted) return;
      setState(() {
        _paged = PagedText(decoded.text, linesPerPage: widget.linesPerPage);
        _pageIndex = 0;
        _state = _LoadState.ready;
      });
    } on SafException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _state = _LoadState.failed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = null; // fall back to the localized message at render time.
        _state = _LoadState.failed;
      });
    }
  }

  void _goToPage(int index) {
    final paged = _paged;
    if (paged == null) return;
    final clamped = index.clamp(0, paged.pageCount - 1);
    if (clamped == _pageIndex) return;
    setState(() => _pageIndex = clamped);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _LoadState.failed:
        return _FailureView(
          message: _error ?? AppLocalizations.of(context).failCannotOpen,
          onRetry: _load,
        );
      case _LoadState.ready:
        return _ReadyView(
          paged: _paged!,
          pageIndex: _pageIndex,
          scroll: _scroll,
          onGoToPage: _goToPage,
        );
    }
  }
}

class _ReadyView extends StatelessWidget {
  final PagedText paged;
  final int pageIndex;
  final ScrollController scroll;
  final void Function(int index) onGoToPage;

  const _ReadyView({
    required this.paged,
    required this.pageIndex,
    required this.scroll,
    required this.onGoToPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _LargeFileBanner(),
        Expanded(
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              paged.page(pageIndex),
              key: const Key('degraded-page-text'),
              style: const TextStyle(fontFamily: 'monospace', height: 1.4),
            ),
          ),
        ),
        _PageBar(
          pageIndex: pageIndex,
          pageCount: paged.pageCount,
          onGoToPage: onGoToPage,
        ),
      ],
    );
  }
}

/// The top notice that tells the user this file is large and read-only.
class _LargeFileBanner extends StatelessWidget {
  const _LargeFileBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).degradedLargeBanner,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Previous / next page controls plus a "Page X of N" jump field.
class _PageBar extends StatefulWidget {
  final int pageIndex;
  final int pageCount;
  final void Function(int index) onGoToPage;

  const _PageBar({
    required this.pageIndex,
    required this.pageCount,
    required this.onGoToPage,
  });

  @override
  State<_PageBar> createState() => _PageBarState();
}

class _PageBarState extends State<_PageBar> {
  late final TextEditingController _jump =
      TextEditingController(text: '${widget.pageIndex + 1}');

  @override
  void didUpdateWidget(covariant _PageBar old) {
    super.didUpdateWidget(old);
    if (old.pageIndex != widget.pageIndex) {
      _jump.text = '${widget.pageIndex + 1}';
    }
  }

  @override
  void dispose() {
    _jump.dispose();
    super.dispose();
  }

  void _submitJump(String value) {
    final n = int.tryParse(value.trim());
    if (n == null) {
      _jump.text = '${widget.pageIndex + 1}';
      return;
    }
    widget.onGoToPage(n - 1); // 1-based in the UI
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final atFirst = widget.pageIndex <= 0;
    final atLast = widget.pageIndex >= widget.pageCount - 1;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const Key('degraded-prev-page'),
            tooltip: l10n.degradedPrevPage,
            onPressed: atFirst ? null : () => widget.onGoToPage(widget.pageIndex - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 4),
          Text(l10n.degradedPageLabel, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: TextField(
              key: const Key('degraded-page-field'),
              controller: _jump,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _submitJump,
            ),
          ),
          const SizedBox(width: 8),
          Text(l10n.degradedOfCount(widget.pageCount),
              style: theme.textTheme.bodyMedium),
          const SizedBox(width: 4),
          IconButton(
            key: const Key('degraded-next-page'),
            tooltip: l10n.degradedNextPage,
            onPressed: atLast ? null : () => widget.onGoToPage(widget.pageIndex + 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailureView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context).degradedTryAgain)),
          ],
        ),
      ),
    );
  }
}
