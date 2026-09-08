// File: lib/core/widgets/refreshable_widgets.dart
import 'package:flutter/material.dart';

// ListView con pull-to-refresh
class RefreshableList extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry? padding;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollPhysics? physics;
  final bool alwaysScrollable;

  const RefreshableList({
    super.key,
    required this.onRefresh,
    this.padding,
    required this.itemCount,
    required this.itemBuilder,
    this.physics,
    this.alwaysScrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: alwaysScrollable
            ? const AlwaysScrollableScrollPhysics()
            : physics,
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

// GridView con pull-to-refresh
class RefreshableGrid extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry? padding;
  final SliverGridDelegate gridDelegate;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollPhysics? physics;
  final bool alwaysScrollable;

  const RefreshableGrid({
    super.key,
    required this.onRefresh,
    this.padding,
    required this.gridDelegate,
    required this.itemCount,
    required this.itemBuilder,
    this.physics,
    this.alwaysScrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        physics: alwaysScrollable
            ? const AlwaysScrollableScrollPhysics()
            : physics,
        padding: padding,
        gridDelegate: gridDelegate,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

// Stato vuoto con pull-to-refresh
class RefreshableEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final IconData icon;
  final String title;
  final String subtitle;
  final double? height;

  const RefreshableEmptyState({
    super.key,
    required this.onRefresh,
    required this.icon,
    required this.title,
    this.subtitle = 'Scorri verso il basso per aggiornare',
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: height ?? MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 80,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget di errore con retry
class RefreshableError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const RefreshableError({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova'),
          ),
        ],
      ),
    );
  }
}

// CustomScrollView con pull-to-refresh (per layout personalizzati)
class RefreshableCustomScrollView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final bool alwaysScrollable;

  const RefreshableCustomScrollView({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.alwaysScrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: alwaysScrollable
            ? const AlwaysScrollableScrollPhysics()
            : null,
        slivers: slivers,
      ),
    );
  }
}