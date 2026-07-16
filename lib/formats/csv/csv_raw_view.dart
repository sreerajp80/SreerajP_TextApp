import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../core/editor/editor_selection_toolbar.dart';
import '../../core/theme/theme_controller.dart';
import 'csv_document_session.dart';
import 'csv_find_panel.dart';

/// The `re_editor` surface for the CSV **raw delimited text** (task 7.3, 7.5).
///
/// It renders the line-number gutter, hosts find / replace, and applies the
/// app's font settings. [readOnly] decides whether typing is allowed (a
/// read-only tab or a view-only mode). Its controllers live on the
/// [CsvDocumentSession] so editor state survives switching tabs; leaving raw
/// mode re-parses this text back into the grid.
class CsvRawView extends ConsumerStatefulWidget {
  final CsvDocumentSession session;
  final bool readOnly;

  const CsvRawView({
    super.key,
    required this.session,
    required this.readOnly,
  });

  @override
  ConsumerState<CsvRawView> createState() => _CsvRawViewState();
}

class _CsvRawViewState extends ConsumerState<CsvRawView> {
  static const double _baseFontSize = 14;

  late final SelectionToolbarController _toolbar =
      createEditorSelectionToolbar(() => widget.readOnly);

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final code = session.code;
    if (code == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final appearance = ref.watch(themeControllerProvider);

    return CodeEditor(
      key: const Key('csv-code-editor'),
      controller: code,
      scrollController: session.scroll,
      findController: session.find,
      toolbarController: _toolbar,
      readOnly: widget.readOnly,
      wordWrap: false,
      autofocus: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      style: CodeEditorStyle(
        fontSize: _baseFontSize * appearance.fontScale,
        fontHeight: appearance.lineSpacing,
        fontFamily: appearance.fontFamily,
        textColor: theme.colorScheme.onSurface,
        backgroundColor: theme.colorScheme.surface,
        cursorColor: theme.colorScheme.primary,
        selectionColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        highlightColor: theme.colorScheme.tertiary.withValues(alpha: 0.4),
      ),
      indicatorBuilder:
          (context, editingController, chunkController, notifier) {
        return Row(
          children: [
            DefaultCodeLineNumber(
              controller: editingController,
              notifier: notifier,
            ),
          ],
        );
      },
      findBuilder: (context, controller, readOnly) =>
          CsvFindPanel(controller: controller, readOnly: readOnly),
    );
  }
}
