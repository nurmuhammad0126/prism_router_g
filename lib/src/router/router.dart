import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../annotations/prism_screen.dart';
import '../navigator/prism_page.dart';
import '../navigator/types.dart';
import 'back_button_dispatcher.dart';
import 'controller.dart';
import 'path_codec.dart';
import 'route_information_parser.dart';
import 'router_delegate.dart';

class PrismRouter {
  const PrismRouter._();

  static RouterConfig<Object> router({
    required List<PrismPage> initialStack,
    List<PrismRouteDefinition>? routes,
    List<PrismPage>? pages,
    PrismGuard guards = const [],
    List<NavigatorObserver> observers = const [],
    TransitionDelegate<Object> transitionDelegate =
        const DefaultTransitionDelegate<Object>(),
    String? restorationScopeId,
  }) {
    assert(initialStack.isNotEmpty, 'initialStack cannot be empty');
    final generatedRoutes =
        routes ?? (PrismScreenRegistry.hasEntries ? PrismScreenRegistry.routeDefinitions : null);
    final generatedPages =
        pages ??
        (PrismScreenRegistry.hasEntries ? PrismScreenRegistry.pages : null);

    final resolvedInitialStack = initialStack;

    final controller = PrismController(
      initialPages: resolvedInitialStack,
      guards: guards,
    );
    // Auto-generate routes from pages or initialStack if not provided
    final routeMap =
        generatedRoutes != null
            ? {for (final route in generatedRoutes) route.name: route}
            : {
              // Use pages list if provided, otherwise use initialStack
              for (final page in (generatedPages ?? initialStack))
                page.name: page.routeDefinition,
            };
    final delegate = PrismRouterDelegate(
      controller: controller,
      observers: observers,
      transitionDelegate: transitionDelegate,
      restorationScopeId: restorationScopeId,
    );
    final parser = PrismRouteInformationParser(
      routeBuilders: routeMap,
      initialPages: resolvedInitialStack,
    );
    // initialRouteInformation is used as fallback if browser URL is empty
    // Parser will parse actual browser URL if it exists
    final initialLocation = encodeLocation(initialStack);
    final initialRouteInformation =
        kIsWeb
            // On web, read the actual browser URL so refresh preserves stacks.
            ? RouteInformation(uri: Uri.base)
            : RouteInformation(uri: Uri.parse(initialLocation));
    final provider = PlatformRouteInformationProvider(
      initialRouteInformation: initialRouteInformation,
    );
    return RouterConfig<Object>(
      routerDelegate: delegate,
      routeInformationParser: parser,
      routeInformationProvider: provider,
      backButtonDispatcher: PrismBackButtonDispatcher(controller),
    );
  }
}
