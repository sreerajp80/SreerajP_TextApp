import 'package:flutter/material.dart';

import 'package:text_data/formats/markdown/md_document_session.dart';
import 'package:text_data/formats/markdown/md_editor_surface.dart';
import 'package:text_data/formats/markdown/md_preview_view.dart';

/// The split-screen dual view: the Markdown source and the live rendered result
/// side by side (roadmap §4.4.1).
///
/// The layout follows the device **orientation**, which is what the reader
/// actually notices: landscape puts the panes side by side, portrait stacks
/// source above preview. A draggable divider between them sets how much room
/// each gets, and the session remembers that across documents.
///
/// The preview rebuilds as the source changes because it reads the session's
/// freshly parsed AST, and the session notifies on every edit. With the split
/// turned off, only the source pane is shown.
class MdLivePreview extends StatelessWidget {
  final MdDocumentSession session;

  /// True in raw mode, where the source is shown but must not be edited. The
  /// split works there too, so a read-only file can still be read both ways.
  final bool readOnly;

  const MdLivePreview({
    super.key,
    required this.session,
    this.readOnly = false,
  });

  /// How thick the drag handle between the two panes is.
  static const double _dividerThickness = 12;

  @override
  Widget build(BuildContext context) {
    final editor = MdEditorSurface(session: session, readOnly: readOnly);
    if (!session.livePreview) return editor;

    final preview = _PreviewPane(session: session);
    // Orientation, not width: a phone held sideways should split side by side
    // even though it is not a wide "tablet" screen.
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        final total = landscape ? constraints.maxWidth : constraints.maxHeight;
        // A pane cannot be dragged away completely, and on a very small screen
        // an even split is the only sensible answer.
        final usable = total - _dividerThickness;
        if (!usable.isFinite || usable <= 0) {
          return landscape
              ? Row(
                  children: [
                    Expanded(child: editor),
                    Expanded(child: preview),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: editor),
                    Expanded(child: preview),
                  ],
                );
        }
        final first = usable * session.splitRatio;

        void onDrag(Offset delta) {
          final moved = landscape ? delta.dx : delta.dy;
          session.setSplitRatio((first + moved) / usable);
        }

        final divider = _Divider(
          landscape: landscape,
          thickness: _dividerThickness,
          onDrag: onDrag,
        );

        if (landscape) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: first, child: editor),
              divider,
              Expanded(child: preview),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: first, child: editor),
            divider,
            Expanded(child: preview),
          ],
        );
      },
    );
  }
}

/// The grab handle between the two panes.
class _Divider extends StatelessWidget {
  final bool landscape;
  final double thickness;
  final void Function(Offset) onDrag;

  const _Divider({
    required this.landscape,
    required this.thickness,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handle = Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Container(
        width: landscape ? 3 : 36,
        height: landscape ? 36 : 3,
        decoration: BoxDecoration(
          color: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

    return MouseRegion(
      cursor: landscape
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        key: const Key('md-split-divider'),
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: landscape ? (d) => onDrag(d.delta) : null,
        onVerticalDragUpdate: landscape ? null : (d) => onDrag(d.delta),
        child: landscape
            ? SizedBox(width: thickness, child: handle)
            : SizedBox(height: thickness, child: handle),
      ),
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
