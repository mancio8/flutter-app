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
      appBar: AppBar(title: Text(l10n.home)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // HERO
              // ============================================================
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 20),
                    Text(
                      l10n.welcomeTitle,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 12),
                    Text(
                      l10n.welcomeSubtitle,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ============================================================
              // LE TUE APP
              // ============================================================
              Text(
                'Le tue app',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                ],
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 32),

              // ============================================================
              // DEMO / COMPONENTI
              // ============================================================
              Text(
                'Demo e componenti',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
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
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              const SizedBox(height: 16),
            ],
          ),
        ),
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
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}

// ============================================================================
// FEATURE ITEM
// ============================================================================

