import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The top-level areas the adaptive navigation switches between (task 2.2).
enum ShellDestination {
  home,
  editor,
  settings;

  String get label {
    switch (this) {
      case ShellDestination.home:
        return 'Home';
      case ShellDestination.editor:
        return 'Editor';
      case ShellDestination.settings:
        return 'Settings';
    }
  }
}

/// Which navigation area is currently showing.
class ShellDestinationController extends Notifier<ShellDestination> {
  @override
  ShellDestination build() => ShellDestination.home;

  void select(ShellDestination destination) => state = destination;
}

final shellDestinationProvider =
    NotifierProvider<ShellDestinationController, ShellDestination>(
  ShellDestinationController.new,
);
