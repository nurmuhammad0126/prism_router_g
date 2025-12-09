import 'package:flutter/material.dart';

import '../annotations/prism_screen.dart';
import '../navigator/prism_page.dart';
import '../router/controller.dart';
import '../router/scope.dart';

extension PrismContextExtension on BuildContext {
  /// Gets the Prism controller for navigation.
  PrismController get prism => PrismScope.of(this, listen: false);

  /// Checks if a page can be popped from the navigation stack.
  /// Returns false if at initial state to prevent back navigation.
  bool get canPop {
    if (!Navigator.canPop(this)) return false;
    // Also check if we're at initial state
    return !prism.isAtInitialState;
  }

  /// Pops the current page from the navigation stack.
  void pop() => prism.pop();

  /// Pushes a new page or annotated screen onto the navigation stack.
  ///
  /// Accepts either a [PrismPage] or a widget annotated with `@PrismScreen`.
  /// The generated registry wraps annotated widgets into pages automatically.
  void push(Object pageOrScreen) =>
      prism.push(_ensurePage(pageOrScreen));

  /// Replaces the top page with a new page or annotated screen.
  void pushReplacement(Object pageOrScreen) =>
      prism.pushReplacement(_ensurePage(pageOrScreen));

  /// Pushes a new page and removes all previous pages until the predicate is true.
  void pushAndRemoveUntil(
    Object pageOrScreen,
    bool Function(PrismPage) predicate,
  ) =>
      prism.pushAndRemoveUntil(_ensurePage(pageOrScreen), predicate);

  /// Pushes a new page and removes all previous pages.
  void pushAndRemoveAll(Object pageOrScreen) =>
      prism.pushAndRemoveAll(_ensurePage(pageOrScreen));

  /// Sets the navigation stack to the given pages.
  ///
  /// This replaces the entire navigation stack with the provided pages.
  void setStack(List<Object> pages) =>
      prism.setStack(pages.map(_ensurePage).toList());

  /// Applies a custom transformation to the navigation stack.
  ///
  /// Use this for advanced navigation scenarios where you need fine-grained control.
  void transformStack(
    List<PrismPage> Function(List<PrismPage> current) transform,
  ) => prism.transformStack(transform);

  PrismPage _ensurePage(Object target) {
    if (target is PrismPage) return target;
    final wrapped = PrismScreenRegistry.wrap(target);
    if (wrapped != null) return wrapped;
    throw ArgumentError(
      'Expected a PrismPage or a widget annotated with @PrismScreen, '
      'but got ${target.runtimeType}.',
    );
  }
}
