import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import 'md_document_session.dart';
import 'md_link_warning.dart';
import 'md_renderer.dart';

/// The scrollable rendered Markdown surface (tasks 6.1–6.3).
///
/// Builds the heading anchor keys, renders the parsed AST with [MarkdownRenderer],
/// routes external links through the safety warning and internal `#` links to a
/// scroll, and remembers the scroll position by fingerprint.
class MdPreviewView extends ConsumerStatefulWidget {
  final MdDocumentSession session;

  const MdPreviewView({super.key, required this.session});

  @override
  ConsumerState<MdPreviewView> createState() => _MdPreviewViewState();
}

class _MdPreviewViewState extends ConsumerState<MdPreviewView> {
  @override
  void initState() {
    super.initState();
    // Restore the remembered reading position once the content is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = widget.session.initialPreviewOffset;
      final controller = widget.session.previewScroll;
      if (offset > 0 && controller.hasClients) {
        controller.jumpTo(
          offset.clamp(0, controller.position.maxScrollExtent),
        );
      }
    });
  }

  @override
  void dispose() {
    final controller = widget.session.previewScroll;
    if (controller.hasClients) {
      widget.session.persistPreviewOffset(controller.offset);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final appearance = ref.watch(themeControllerProvider);
    session.syncHeadingKeys();

    return SingleChildScrollView(
      controller: session.previewScroll,
      padding: const EdgeInsets.all(16),
      child: MarkdownRenderer(
        nodes: session.renderNodes,
        headingAnchors: session.headingAnchors,
        headingKeys: session.headingKeys,
        textScale: appearance.fontScale,
        onTapLink: (href) => showMarkdownLinkWarning(context, href),
        onTapAnchor: (anchor) => session.jumpToAnchor(anchor),
      ),
    );
  }
}
