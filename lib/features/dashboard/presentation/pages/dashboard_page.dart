import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final biblioteca = ref.watch(bibliotecaSummaryProvider);
    final rifornimenti = ref.watch(rifornimentiSummaryProvider);
    final raccolta = ref.watch(raccoltaSummaryProvider);
    final note = ref.watch(noteSummaryProvider);
    final habits = ref.watch(habitsSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riepilogo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            icon: Icons.menu_book,
            color: theme.colorScheme.primary,
            title: 'Biblioteca',
            lines: [
              '${biblioteca.totaleLibri} libri letti',
              if (biblioteca.ultimoLibroTitolo != null)
                'Ultimo: ${biblioteca.ultimoLibroTitolo}',
            ],
            onTap: () => context.go('/biblioteca'),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.local_gas_station,
            color: Colors.orange,
            title: 'Rifornimenti',
            lines: [
              'Totale speso: €${rifornimenti.totaleSpeso.toStringAsFixed(2)}',
              'Prezzo medio: €${rifornimenti.prezzoMedio.toStringAsFixed(3)}/L',
            ],
            onTap: () => context.go('/rifornimenti'),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.recycling,
            color: const Color(0xFF2E7D32),
            title: 'Raccolta Differenziata',
            lines: [
              // Oggi
              if (raccolta.raccoltaOggi)
                'Oggi: ${raccolta.tipoOggi ?? "raccolta prevista"}'
              else if (raccolta.prossimoGiornoNome != null)
                'Prossima: ${raccolta.prossimoGiornoNome} (tra ${raccolta.giorniAllaProssima} giorni)'
              else
                'Nessuna raccolta programmata',
              
              // Domani (NUOVO)
              if (raccolta.raccoltaDomani && raccolta.tipoDomani != null)
                'Domani: ${raccolta.tipoDomani}',
            ],
            onTap: () => context.go('/raccolta'),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.sticky_note_2_outlined,
            color: Colors.amber[800]!,
            title: 'Note',
            lines: [
              if (note.totaleNote == 0)
                'Nessuna nota'
              else ...[
                '${note.totaleNote} note totali',
                if (note.noteUrgenti > 0) '${note.noteUrgenti} urgenti',
                if (note.noteFissate > 0) '${note.noteFissate} fissate',
              ],
            ],
            onTap: () => context.go('/note'),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.check_circle,
            color: Colors.green,
            title: 'Habit Tracker',
            lines: [
              '${habits.completatiOggi}/${habits.totale} completati oggi',
              if (habits.migliorStreak > 0)
                'Miglior streak: ${habits.migliorStreak} giorni',
            ],
            onTap: () => context.go('/habits'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
    this.onTap,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...lines.map((l) => Text(
                          l,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}