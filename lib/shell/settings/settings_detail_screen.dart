import 'package:flutter/material.dart';

/// A single settings section shown on its own page (task: cards → detail pages).
///
/// The Settings screen is a menu of cards; tapping a card pushes this page,
/// which shows just that one section under an app bar with its title. The
/// section's own in-body header is hidden (the section is built with
/// `showHeader: false`) so the title is not shown twice.
class SettingsDetailScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const SettingsDetailScreen({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [child],
      ),
    );
  }
}
