import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';

import '../../feature/home/home_screen.dart';

mixin RouteStateMixin<T extends StatefulWidget> on State<T> {
  late PrismNavigationState initialPages;

  late PrismGuard guards;

  late List<PrismPage> appPages;

  @override
  void initState() {
    super.initState();
    initialPages = [PrismScreen.of<HomeScreen>()];

    guards = [
      (context, state) =>
          state.length > 1 ? state : [PrismScreen.of<HomeScreen>()],
    ];
    // Use generated pages list if available.
    appPages = PrismScreenRegistry.pages;
  }
}
