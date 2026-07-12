import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../core/theme/app_fonts.dart';
import '../../core/theme/theme_controller.dart';
import 'json_document_session.dart';
import 'json_find_panel.dart';

/// The `re_editor` surface for the JSON **raw source** — used for both the
/// read-only raw view and the source editor (tasks 8.1, 8.5). It renders the
/// line-number gutter, hosts the find / replace bar (with bracket matching), and
/// applies the app's font settings.
///
/// The same widget serves both modes; [readOnly] decides whether typing is
/// allowed. Its controllers live on the [JsonDocumentSession], so editor state
/// survives switching tabs.
class JsonEditorSurface extends ConsumerWidget {
  final JsonDocumentSession session;
  final bool readOnly;

  const JsonEditorSurface({
    super.key,
    required this.session,
    required this.readOnly,
  });

  static const double _baseFontSize = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = session.code;
    if (code == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final appearance = ref.watch(themeControllerProvider);

    return CodeEditor(
      key: const Key('json-code-editor'),
      controller: code,
      scrollController: session.scroll,
      findController: session.find,
      readOnly: readOnly,
      wordWrap: false,
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
          JsonFindPanel(controller: controller, readOnly: readOnly),
    );
  }
}
