import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings),
      ),
      body: _buildSettings(context, ref, themeState),
    );
  }

  Widget _buildSettings(BuildContext context, WidgetRef ref, ThemeState themeState) {
    return ListView(
      children: [
        // ============================================================
        // SEZIONE ASPETTO
        // ============================================================
        _SectionHeader(title: AppLocalizations.of(context).appearance),
        
        // Dark Mode
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: Text(AppLocalizations.of(context).darkMode),
          subtitle: Text(AppLocalizations.of(context).useDarkTheme),
          value: themeState.themeMode == ThemeMode.dark,
          onChanged: (value) {
            ref.read(themeNotifierProvider.notifier).setThemeMode(
              value ? ThemeMode.dark : ThemeMode.light,
            );
          },
        ),
        
        // Modalità Sistema (opzionale, se vuoi tre stati)
        SwitchListTile(
          secondary: const Icon(Icons.brightness_auto_outlined),
          title: Text(AppLocalizations.of(context).systemMode),
          subtitle: const Text('Usa le impostazioni di sistema'),
          value: themeState.themeMode == ThemeMode.system,
          onChanged: (value) {
            if (value) {
              ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.system);
            }
          },
        ),
        
        const Divider(),
        
        // ============================================================
        // SEZIONE COLORE TEMA
        // ============================================================
        _SectionHeader(title: AppLocalizations.of(context).themeColor),
        
        ...ColorSeed.values.map(
          (seed) => RadioListTile<ColorSeed>(
            title: Text(seed.label),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: seed.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
            ),
            value: seed,
            groupValue: themeState.colorSeed,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeNotifierProvider.notifier).setColorSeed(value);
              }
            },
          ),
        ),
        
        const Divider(),
        
        // ============================================================
        // SEZIONE INFORMAZIONI
        // ============================================================
        _SectionHeader(title: AppLocalizations.of(context).about),
        
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(AppLocalizations.of(context).flutterStarterApp),
          subtitle: Text(AppLocalizations.of(context).version),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: AppLocalizations.of(context).flutterStarter,
              applicationVersion: '1.0.0',
              applicationLegalese: AppLocalizations.of(context).material3StarterTemplate,
              children: [
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).starterFeatures,
                ),
              ],
            );
          },
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}