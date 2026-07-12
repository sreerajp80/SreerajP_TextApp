import 'package:flutter/material.dart';

import 'md_document_session.dart';
import 'md_editor_surface.dart';
import 'md_preview_view.dart';

/// The edit-mode layout (task 6.4): the raw-source editor with an optional live
/// rendered preview.
///
/// On a wide screen the editor and preview sit side by side; on a narrow screen
/// the preview stacks under the editor. When live preview is off, only the
/// editor is shown. The preview rebuilds as the source changes because it reads
/// the session's freshly parsed AST (the session notifies on every edit).
class MdLivePreview extends StatelessWidget {
  final MdDocumentSession session;

  const MdLivePreview({super.key, required this.session});

  /// Below this width the editor and preview stack instead of splitting.
  static const double _splitBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    final editor = MdEditorSurface(session: session, readOnly: false);

    if (!session.livePreview) {
      return editor;
    }

    final preview = _PreviewPane(session: session);
    final wide = MediaQuery.sizeOf(context).width >= _splitBreakpoint;

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: editor),
          const VerticalDivider(width: 1),
          Expanded(child: preview),
        ],
      );
    }
    return Column(
      children: [
        Expanded(child: editor),
        const Divider(height: 1),
        Expanded(child: preview),
      ],
    );
  }
}

class _PreviewPane extends StatelessWidget {
  final MdDocumentSession session;

  const _PreviewPane({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: MdPreviewView(session: session),
    );
  }
}
