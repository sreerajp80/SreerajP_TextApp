import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../core/theme/app_fonts.dart';
import '../../core/theme/theme_controller.dart';
import 'txt_document_session.dart';
import 'txt_find_panel.dart';

/// The `re_editor` surface used for both viewing (read-only) and editing a TXT
/// document (tasks 4.1, 4.2). It renders the line-number gutter, honors the
/// word-wrap toggle, hosts the find / replace bar, and applies the app's font
/// size / family / line-spacing preferences (arch §6, §8.1).
///
/// The same widget serves both modes; [readOnly] decides whether typing is
/// allowed. Its controllers live on the [TxtDocumentSession], so editor state
/// (content, undo history, scroll) survives switching tabs.
class TxtEditorSurface extends ConsumerWidget {
  final TxtDocumentSession session;
  final bool readOnly;

  const TxtEditorSurface({
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
      key: const Key('txt-code-editor'),
      controller: code,
      scrollController: session.scroll,
      findController: session.find,
      readOnly: readOnly,
      wordWrap: session.wordWrap,
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
          TxtFindPanel(controller: controller, readOnly: readOnly),
    );
  }
}
