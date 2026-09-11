import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/breakpoints.dart';
import '../../l10n/app_localizations.dart';

class ResponsiveScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const ResponsiveScaffold({
    required this.child,
    super.key,
  });

  @override
  ConsumerState<ResponsiveScaffold> createState() =>
      _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends ConsumerState<ResponsiveScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _railAnimation;
  late final Animation<double> _barAnimation;

  bool showLargeSizeLayout = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      value: 0,
      vsync: this,
    );

    _railAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.35,
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    _barAnimation = ReverseAnimation(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.65,
          curve: Curves.easeInOutCubic,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final width = MediaQuery.sizeOf(context).width;

    if (width > mediumWidthBreakpoint) {
      showLargeSizeLayout = width > largeWidthBreakpoint;

      if (!_controller.isAnimating &&
          _controller.status != AnimationStatus.completed) {
        _controller.forward();
      }
    } else {
      showLargeSizeLayout = false;

      if (!_controller.isAnimating &&
          _controller.status != AnimationStatus.dismissed) {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isDesktopLayout = _controller.value > 0;

        return Scaffold(
          body: Row(
            children: [
              if (isDesktopLayout)
                _AnimatedNavigationRail(
                  animation: _railAnimation,
                  extended: showLargeSizeLayout,
                  currentRoute: currentRoute,
                ),

              if (isDesktopLayout)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                ),

              Expanded(
                child: widget.child,
              ),
            ],
          ),

          // Mobile / compact layout
          bottomNavigationBar: _AnimatedNavigationBar(
            animation: _barAnimation,
            currentRoute: currentRoute,
          ),
        );
      },
    );
  }
}


// ============================================================
// NAVIGATION RAIL - TABLET / DESKTOP
// ============================================================

class _AnimatedNavigationRail extends StatelessWidget {
  final Animation<double> animation;
  final bool extended;
  final String currentRoute;

  const _AnimatedNavigationRail({
    required this.animation,
    required this.extended,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          axisAlignment: -1,
          child: NavigationRail(
            extended: extended,

            // Material 3
            useIndicator: true,
            indicatorShape: const StadiumBorder(),

            // When collapsed, show labels only when selected.
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,

            selectedIndex: _getSelectedIndex(currentRoute),

            onDestinationSelected: (index) {
              _onItemTapped(context, index);
            },

            destinations: _buildDestinations(context),
          ),
        );
      },
    );
  }

  List<NavigationRailDestination> _buildDestinations(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context);

    return [
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: Text(l10n.home),
      ),

      NavigationRailDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: Text(l10n.dashboard),
      ),

      NavigationRailDestination(
        icon: const Icon(Icons.local_gas_station_outlined),
        selectedIcon: const Icon(Icons.local_gas_station),
        label: const Text('Fuel'),
      ),

      NavigationRailDestination(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book),
        label: const Text('Biblioteca'),
      ),

      NavigationRailDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: Text(l10n.settings),
      ),
    ];
  }

  int _getSelectedIndex(String route) {
    if (route.startsWith('/home') ||
        route.startsWith('/showcase') ||
        route.startsWith('/forms')) {
      return 0;
    }

    if (route.startsWith('/dashboard')) {
      return 1;
    }

    if (route.startsWith('/rifornimenti')) {
      return 2;
    }

    if (route.startsWith('/biblioteca')) {
      return 3;
    }

    if (route.startsWith('/settings')) {
      return 4;
    }

    return 0;
  }

  void _onItemTapped(
    BuildContext context,
    int index,
  ) {
    switch (index) {
      case 0:
        context.go('/home');
        break;

      case 1:
        context.go('/dashboard');
        break;

      case 2:
        context.go('/rifornimenti');
        break;

      case 3:
        context.go('/biblioteca');
        break;

      case 4:
        context.go('/settings');
        break;
    }
  }
}


// ============================================================
// NAVIGATION BAR - MOBILE
// ============================================================

class _AnimatedNavigationBar extends StatelessWidget {
  final Animation<double> animation;
  final String currentRoute;

  const _AnimatedNavigationBar({
    required this.animation,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: 1,
          child: NavigationBar(
            // Material 3
            selectedIndex: _getSelectedIndex(currentRoute),

            onDestinationSelected: (index) {
              _onItemTapped(context, index);
            },

            destinations: _buildDestinations(context),
          ),
        );
      },
    );
  }

  List<NavigationDestination> _buildDestinations(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context);

    return [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.home,
      ),

      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: l10n.dashboard,
      ),

      NavigationDestination(
        icon: const Icon(Icons.local_gas_station_outlined),
        selectedIcon: const Icon(Icons.local_gas_station),
        label: 'Fuel',
      ),

      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: l10n.settings,
      ),
    ];
  }

  int _getSelectedIndex(String route) {
    if (route.startsWith('/home') ||
        route.startsWith('/showcase') ||
        route.startsWith('/forms')) {
      return 0;
    }

    if (route.startsWith('/dashboard')) {
      return 1;
    }

    if (route.startsWith('/rifornimenti')) {
      return 2;
    }

    if (route.startsWith('/settings')) {
      return 3;
    }

    // Biblioteca non è presente nella NavigationBar mobile.
    // Evitiamo quindi un indice fuori range.
    return 0;
  }

  void _onItemTapped(
    BuildContext context,
    int index,
  ) {
    switch (index) {
      case 0:
        context.go('/home');
        break;

      case 1:
        context.go('/dashboard');
        break;

      case 2:
        context.go('/rifornimenti');
        break;

      case 3:
        context.go('/settings');
        break;
    }
  }
}

