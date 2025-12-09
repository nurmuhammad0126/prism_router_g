import 'package:flutter/widgets.dart';

import '../navigator/prism_page.dart';
import '../navigator/types.dart';

/// Annotation that marks a widget as a Prism-managed screen.
///
/// The generator uses this metadata to create a strongly-typed [PrismPage]
/// subclass and register it for routing/URL restoration.
class PrismScreen {
  const PrismScreen({
    required this.name,
    this.tags,
    this.path,
    this.initial = false,
    this.arguments,
  });

  /// Unique route name.
  final String name;

  /// Optional tags used for filtering/stats.
  final Set<String>? tags;

  /// Optional URL path (reserved for future path-based matching).
  final String? path;

  /// Marks screen as an initial page candidate.
  final bool initial;

  /// Custom argument keys (not currently used by the generator but reserved).
  final List<String>? arguments;

  /// Returns a generated [PrismPage] for the annotated widget type.
  static PrismPage of<T extends Widget>({
    T? screen,
    Map<String, Object?> arguments = const {},
  }) =>
      PrismScreenRegistry.of<T>(screen: screen, arguments: arguments);

  /// Wraps an annotated widget instance into its generated [PrismPage].
  static PrismPage? wrap(Object target) => PrismScreenRegistry.wrap(target);
}

/// Describes a generated screen entry.
class PrismGeneratedScreen<T extends Widget> {
  const PrismGeneratedScreen({
    required this.name,
    required this.pageBuilder,
    required this.fromWidget,
    this.tags,
    this.path,
    this.initial = false,
    this.defaultPage,
  });

  final String name;
  final Set<String>? tags;
  final String? path;
  final bool initial;
  final PrismPage Function(Map<String, Object?> arguments) pageBuilder;
  final PrismPage Function(T widget) fromWidget;
  final PrismPage Function()? defaultPage;
}

/// Global registry populated by generated code.
class PrismScreenRegistry {
  PrismScreenRegistry._();

  static final Map<Type, PrismGeneratedScreen<dynamic>> _screens = {};

  static PrismGeneratedScreen<T> register<T extends Widget>(
    PrismGeneratedScreen<T> screen,
  ) {
    _screens[T] = screen;
    return screen;
  }

  static bool get hasEntries => _screens.isNotEmpty;

  static PrismPage? wrap(Object target) {
    final screen = _screens[target.runtimeType];
    if (screen == null) return null;
    return screen.fromWidget(target as dynamic);
  }

  static PrismPage of<T extends Widget>({
    T? screen,
    Map<String, Object?> arguments = const {},
  }) {
    final registration = _screens[T];
    if (registration == null) {
      throw ArgumentError(
        'No @PrismScreen registration found for $T. '
        'Add @PrismScreen and run `flutter pub run build_runner build`.',
      );
    }
    if (screen != null) {
      return registration.fromWidget(screen);
    }
    if (arguments.isNotEmpty) {
      return registration.pageBuilder(arguments);
    }
    final defaultPage = registration.defaultPage;
    if (defaultPage != null) {
      return defaultPage();
    }
    throw ArgumentError(
      'Type $T requires constructor arguments. Provide the widget instance '
      'or `arguments` so the page can be created.',
    );
  }

  static List<PrismRouteDefinition> get routeDefinitions =>
      _screens.values
          .map(
            (screen) => PrismRouteDefinition(
              name: screen.name,
              builder: screen.pageBuilder,
            ),
          )
          .toList();

  static List<PrismPage> get pages =>
      _screens.values
          .map((screen) => screen.defaultPage?.call())
          .whereType<PrismPage>()
          .toList();

  static List<PrismPage> get initialPages =>
      _screens.values
          .where((screen) => screen.initial)
          .map((screen) => screen.defaultPage?.call())
          .whereType<PrismPage>()
          .toList();
}


