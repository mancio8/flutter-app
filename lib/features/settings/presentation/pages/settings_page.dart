import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/models/campionato_config.dart';
import '../../../girone/providers/girone_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ============================================================
          // APP BAR
          // ============================================================
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Row(
                children: [
                  const Icon(Icons.settings, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).settings,
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
                    Icons.tune,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // SEZIONE ASPETTO
          // ============================================================
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: AppLocalizations.of(context).appearance,
              icon: Icons.palette_outlined,
              theme: theme,
            ),
          ),

          SliverToBoxAdapter(
            child: _SettingsGroup(
              theme: theme,
              children: [
                // Dark Mode
                SwitchListTile(
                  secondary: _LeadingIcon(
                    icon: Icons.dark_mode_outlined,
                    theme: theme,
                  ),
                  title: Text(
                    AppLocalizations.of(context).darkMode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context).useDarkTheme,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: themeState.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    ref
                        .read(themeNotifierProvider.notifier)
                        .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                  },
                ),

                // Modalità Sistema
                SwitchListTile(
                  secondary: _LeadingIcon(
                    icon: Icons.brightness_auto_outlined,
                    theme: theme,
                  ),
                  title: Text(
                    AppLocalizations.of(context).systemMode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Usa le impostazioni di sistema',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: themeState.themeMode == ThemeMode.system,
                  onChanged: (value) {
                    if (value) {
                      ref
                          .read(themeNotifierProvider.notifier)
                          .setThemeMode(ThemeMode.system);
                    }
                  },
                ),
              ],
            ),
          ),

          // ============================================================
          // SEZIONE COLORE TEMA
          // ============================================================
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: AppLocalizations.of(context).themeColor,
              icon: Icons.color_lens_outlined,
              theme: theme,
            ),
          ),

          SliverToBoxAdapter(
            child: _SettingsGroup(
              theme: theme,
              children: ColorSeed.values.map((seed) {
                final isSelected = seed == themeState.colorSeed;

                return ListTile(
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: seed.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: seed.color.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                  title: Text(
                    seed.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 22,
                        )
                      : null,
                  onTap: () {
                    ref.read(themeNotifierProvider.notifier).setColorSeed(seed);
                  },
                );
              }).toList(),
            ),
          ),

          // ============================================================
          // SEZIONE CAMPIONATO
          // ============================================================
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Campionato',
              icon: Icons.sports_soccer,
              theme: theme,
            ),
          ),

          SliverToBoxAdapter(
            child: _CampionatoSettingsGroup(theme: theme, ref: ref),
          ),

          // ============================================================
          // SEZIONE INFORMAZIONI
          // ============================================================
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: AppLocalizations.of(context).about,
              icon: Icons.info_outline,
              theme: theme,
            ),
          ),

          SliverToBoxAdapter(
            child: _SettingsGroup(
              theme: theme,
              children: [
                ListTile(
                  leading: _LeadingIcon(icon: Icons.info_outline, theme: theme),
                  title: Text(
                    AppLocalizations.of(context).flutterStarterApp,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context).version,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),

          // ============================================================
          // PADDING FINALE
          // ============================================================
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.about,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Nome app + versione
                Row(
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.flutterStarter,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Versione 1.0.0',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Legalese
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.material3StarterTemplate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Features
                Text(l10n.starterFeatures, style: theme.textTheme.bodyMedium),

                const SizedBox(height: 24),

                // Chiudi
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Chiudi'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ======================================================================
// SECTION HEADER
// ======================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeData theme;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// SETTINGS GROUP
// ======================================================================

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final ThemeData theme;

  const _SettingsGroup({required this.children, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// LEADING ICON
// ======================================================================

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final ThemeData theme;

  const _LeadingIcon({required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 22),
    );
  }
}

// ======================================================================
// CAMPIONATO SETTINGS GROUP
// ======================================================================

class _CampionatoSettingsGroup extends ConsumerWidget {
  final ThemeData theme;
  final WidgetRef ref;

  const _CampionatoSettingsGroup({required this.theme, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(campionatoConfigProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        clipBehavior: Clip.antiAlias,
        child: configAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Errore: $e'),
          ),
          data: (config) {
            return Column(
              children: [
                // URL JSON
                ListTile(
                  leading: _LeadingIcon(icon: Icons.link, theme: theme),
                  title: Text(
                    'URL JSON campionato',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    config.jsonUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => _showEditUrlDialog(context, ref, config.jsonUrl),
                ),

                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                ),

                // Squadra preferita
                ListTile(
                  leading: _LeadingIcon(
                    icon: Icons.sports_soccer,
                    theme: theme,
                  ),
                  title: Text(
                    'Squadra preferita',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    config.squadraPreferita ?? 'Nessuna squadra selezionata',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: config.squadraPreferita == null
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                      fontWeight: config.squadraPreferita != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => _showSquadraDialog(context, ref),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG: MODIFICA URL
  // ============================================================

  void _showEditUrlDialog(
    BuildContext context,
    WidgetRef ref,
    String currentUrl,
  ) {
    final controller = TextEditingController(text: currentUrl);
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.link,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'URL JSON',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'URL del file JSON',
                      hintText: 'https://esempio.com/campionato.json',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'URL obbligatorio';
                      }
                      if (!v.startsWith('http')) {
                        return 'URL non valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Punta al JSON che contiene "classifica" e "calendario".',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Annulla'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            try {
                              final repo = ref.read(
                                campionatoConfigRepositoryProvider,
                              );
                              final currentConfig = await repo.getConfig();

                              await repo.upsertConfig(
                                CampionatoConfig(
                                  id: currentConfig?.id ?? '',
                                  jsonUrl: controller.text.trim(),
                                  squadraPreferita:
                                      currentConfig?.squadraPreferita,
                                ),
                              );

                              ref.invalidate(campionatoConfigProvider);
                              ref.invalidate(campionatoDataProvider);

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('URL aggiornato'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Errore: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Salva'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DIALOG: SELEZIONA SQUADRA
  // ============================================================

  void _showSquadraDialog(BuildContext context, WidgetRef ref) {
    final classificaAsync = ref.read(classificaProvider);
    final configAsync = ref.read(campionatoConfigProvider);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? selected = configAsync.value?.squadraPreferita;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 600,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.sports_soccer,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Squadra preferita',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Lista squadre
                    Expanded(
                      child: classificaAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Errore: $e')),
                        data: (classifica) {
                          if (classifica.isEmpty) {
                            return const Center(
                              child: Text('Nessuna squadra disponibile'),
                            );
                          }

                          return ListView.builder(
                            itemCount: classifica.length,
                            itemBuilder: (context, index) {
                              final squadra = classifica[index];
                              final isSelected = squadra.nome == selected;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: squadra.logoUrl != null
                                      ? Image.network(
                                          squadra.logoUrl!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              squadra.nome.isNotEmpty
                                                  ? squadra.nome[0]
                                                  : '?',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            squadra.nome.isNotEmpty
                                                ? squadra.nome[0]
                                                : '?',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                ),
                                title: Text(
                                  squadra.nome,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  '${squadra.posizione}ª · ${squadra.punti} pt',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: theme.colorScheme.primary,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    selected = squadra.nome;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bottoni
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              // Rimuovi squadra preferita
                              try {
                                final repo = ref.read(
                                  campionatoConfigRepositoryProvider,
                                );
                                final currentConfig = await repo.getConfig();

                                await repo.upsertConfig(
                                  CampionatoConfig(
                                    id: currentConfig?.id ?? '',
                                    jsonUrl:
                                        currentConfig?.jsonUrl ??
                                        CampionatoConfig.defaultJsonUrl,
                                    squadraPreferita: null,
                                  ),
                                );

                                ref.invalidate(campionatoConfigProvider);
                                ref.invalidate(campionatoDataProvider);

                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              } catch (e) {
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Errore: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Rimuovi'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selected == null
                                ? null
                                : () async {
                                    try {
                                      final repo = ref.read(
                                        campionatoConfigRepositoryProvider,
                                      );
                                      final currentConfig = await repo
                                          .getConfig();

                                      await repo.upsertConfig(
                                        CampionatoConfig(
                                          id: currentConfig?.id ?? '',
                                          jsonUrl:
                                              currentConfig?.jsonUrl ??
                                              CampionatoConfig.defaultJsonUrl,
                                          squadraPreferita: selected,
                                        ),
                                      );

                                      ref.invalidate(campionatoConfigProvider);
                                      ref.invalidate(campionatoDataProvider);

                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Squadra preferita aggiornata',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (dialogContext.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Errore: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Conferma'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
