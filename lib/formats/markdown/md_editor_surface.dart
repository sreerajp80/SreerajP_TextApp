import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../core/theme/app_fonts.dart';
import '../../core/theme/theme_controller.dart';
import 'md_document_session.dart';
import 'md_find_panel.dart';

/// The `re_editor` surface for the Markdown **raw source** — used both for the
/// read-only raw view and the source editor (tasks 6.1, 6.4). It renders the
/// line-number gutter, wraps long prose lines, hosts the find / replace bar, and
/// applies the app's font settings (arch §6, §8.1).
///
/// The same widget serves both modes; [readOnly] decides whether typing is
/// allowed. Its controllers live on the [MdDocumentSession], so editor state
/// survives switching tabs.
class MdEditorSurface extends ConsumerWidget {
  final MdDocumentSession session;
  final bool readOnly;

  const MdEditorSurface({
    super.key,
    required this.session,
    required this.readOnly,
  });

  static const double _baseFontSize = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = session.code;
    if (code == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final appearance = ref.watch(themeControllerProvider);

    return CodeEditor(
      key: const Key('md-code-editor'),
      controller: code,
      scrollController: session.scroll,
      findController: session.find,
      readOnly: readOnly,
      wordWrap: true,
      autofocus: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      style: CodeEditorStyle(
        fontSize: _baseFontSize * appearance.fontScale,
        fontHeight: appearance.lineSpacing,
        fontFamily: appearance.fontFamily,
        fontFamilyFallback: AppFonts.malayalamFallback(
          appearance.malayalamFontFamily,
        ),
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
          MdFindPanel(controller: controller, readOnly: readOnly),
    );
  }
}
