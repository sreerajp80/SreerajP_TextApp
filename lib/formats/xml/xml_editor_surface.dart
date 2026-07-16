import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

import '../../core/editor/editor_selection_toolbar.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/theme_controller.dart';
import 'xml_document_session.dart';
import 'xml_find_panel.dart';

/// The `re_editor` surface for the XML **raw source** — used for both the
/// read-only raw view and the source editor (tasks 9.1, 9.5). It renders the
/// line-number gutter, hosts the find / replace bar (with bracket matching), and
/// applies the app's font settings.
///
/// The same widget serves both modes; [readOnly] decides whether typing is
/// allowed. Its controllers live on the [XmlDocumentSession], so editor state
/// survives switching tabs.
class XmlEditorSurface extends ConsumerStatefulWidget {
  final XmlDocumentSession session;
  final bool readOnly;

  const XmlEditorSurface({
    super.key,
    required this.session,
    required this.readOnly,
  });

  @override
  ConsumerState<XmlEditorSurface> createState() => _XmlEditorSurfaceState();
}

class _XmlEditorSurfaceState extends ConsumerState<XmlEditorSurface>
    with WidgetsBindingObserver {
  static const double _baseFontSize = 14;

  late final SelectionToolbarController _toolbar =
      createEditorSelectionToolbar(() => widget.readOnly);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Restore the saved reading position only after the editor has laid out, so
    // its render object exists and the scroll actually takes effect.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.session.restorePositionIntoView();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save the position when the app leaves the foreground, so a later kill by
    // the OS does not lose it (dispose alone would not run in that case).
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      widget.session.persistPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final code = session.code;
    if (code == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final appearance = ref.watch(themeControllerProvider);

    return CodeEditor(
      key: const Key('xml-code-editor'),
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
          XmlFindPanel(controller: controller, readOnly: readOnly),
    );
  }
}
