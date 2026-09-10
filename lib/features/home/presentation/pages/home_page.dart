import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar a gradiente, coerente con Biblioteca/Raccolta/Note
          SliverAppBar(
            expandedHeight: 160,
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Row(
                children: [
                  const Icon(Icons.rocket_launch, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    l10n.home,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.rocket_launch,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Contenuto
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sottotitolo di benvenuto
                  Text(
                    l10n.welcomeTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcomeSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 28),

                  // ============================================================
                  // LE TUE APP
                  // ============================================================
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Le tue app',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: _getCrossAxisCount(context),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _AppTile(
                        icon: Icons.dashboard_outlined,
                        label: 'Riepilogo',
                        color: theme.colorScheme.primary,
                        onTap: () => context.go('/dashboard'),
                      ),
                      _AppTile(
                        icon: Icons.menu_book,
                        label: 'Biblioteca',
                        color: theme.colorScheme.primary,
                        onTap: () => context.go('/biblioteca'),
                      ),
                      _AppTile(
                        icon: Icons.local_gas_station,
                        label: 'Rifornimenti',
                        color: Colors.orange,
                        onTap: () => context.go('/rifornimenti'),
                      ),
                      _AppTile(
                        icon: Icons.recycling,
                        label: 'Raccolta',
                        color: const Color(0xFF2E7D32),
                        onTap: () => context.go('/raccolta'),
                      ),
                      _AppTile(
                        icon: Icons.sticky_note_2_outlined,
                        label: 'Note',
                        color: Colors.amber[800]!,
                        onTap: () => context.go('/note'),
                      ),
                      _AppTile(
                        icon: Icons.checklist_rtl,
                        label: 'Abitudini',
                        color: Colors.teal,
                        onTap: () => context.go('/habits'),
                      ),
                      _AppTile(
                        icon: Icons.fitness_center,
                        label: 'Allenamenti',
                        color: Colors.deepPurple,
                        onTap: () => context.go('/allenamenti'),
                      ),
                      _AppTile(
                        icon: Icons.directions_car,
                        label: 'I Miei Veicoli',
                        color: const Color.fromARGB(255, 58, 183, 89),
                        onTap: () => context.go('/veicoli'),
                      ),
                      _AppTile(
                        icon: Icons.book_sharp,
                        label: 'Whishlist',
                        color: const Color.fromARGB(255, 228, 15, 210),
                        onTap: () => context.go('/wishlist'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 28),

                  // ============================================================
                  // DEMO / COMPONENTI
                  // ============================================================
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Demo e componenti',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _DemoChip(
                          label: l10n.uiComponents,
                          onTap: () => context.go('/showcase/ui'),
                        ),
                        _DemoChip(
                          label: l10n.loadingSkeletons,
                          onTap: () => context.go('/showcase/skeletons'),
                        ),
                        _DemoChip(
                          label: l10n.errorHandling,
                          onTap: () => context.go('/showcase/errors'),
                        ),
                        _DemoChip(
                          label: l10n.fileUpload,
                          onTap: () => context.go('/showcase/upload'),
                        ),
                        _DemoChip(
                          label: l10n.language,
                          onTap: () => context.go('/showcase/language'),
                        ),
                        _DemoChip(
                          label: l10n.forms,
                          onTap: () => context.go('/forms'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }
}

// ============================================================================
// APP TILE (card per le app principali)
// ============================================================================

class _AppTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AppTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DEMO CHIP
// ============================================================================

class _DemoChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DemoChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}