// File: lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../../girone/providers/girone_provider.dart';

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
    final prossimaPartita = ref.watch(prossimaPartitaProvider);
    final squadraPreferita = ref.watch(squadraPreferitaProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bibliotecaSummaryProvider);
          ref.invalidate(rifornimentiSummaryProvider);
          ref.invalidate(raccoltaSummaryProvider);
          ref.invalidate(noteSummaryProvider);
          ref.invalidate(habitsSummaryProvider);
          ref.invalidate(campionatoDataProvider);
          ref.invalidate(campionatoConfigProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ============================================================
            // SLIVER APP BAR
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
                    const Icon(Icons.dashboard, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Riepilogo',
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
                      Icons.insights,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            // ============================================================
            // SALUTO / DATA
            // ============================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSaluto(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDataOggi(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============================================================
            // HEADER "PANORAMICA"
            // ============================================================
            SliverToBoxAdapter(
              child: Padding(
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
                    Text(
                      'Panoramica',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============================================================
            // PROSSIMA PARTITA
            // ============================================================
            prossimaPartita.when(
              loading: () => const SliverToBoxAdapter(
                child: SizedBox.shrink(),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: SizedBox.shrink(),
              ),
              data: (partita) {
                if (partita == null) {
                  return const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
                  );
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _SummaryCard(
                      icon: Icons.sports_soccer,
                      color: Colors.green[700]!,
                      title: 'Prossima partita',
                      lines: [
                        '${partita.squadraCasa} vs ${partita.squadraTrasferta}',
                        if (partita.data != null)
                          '${_formatData(partita.data!)}'
                              '${partita.ora != null ? ' · ${partita.ora!.substring(0, 5)}' : ''}',
                        if (partita.campo != null) partita.campo!,
                      ],
                      onTap: () => context.go('/girone-c'),
                    ),
                  ),
                );
              },
            ),

            // ============================================================
            // SQUADRA PREFERITA
            // ============================================================
            squadraPreferita.when(
              loading: () => const SliverToBoxAdapter(
                child: SizedBox.shrink(),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: SizedBox.shrink(),
              ),
              data: (squadra) {
                if (squadra == null) {
                  return const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
                  );
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _SummaryCard(
                      icon: Icons.emoji_events,
                      color: theme.colorScheme.primary,
                      title: squadra.nome,
                      lines: [
                        '${squadra.posizione}ª posizione · ${squadra.punti} punti',
                        '${squadra.vinte}V ${squadra.pareggiate}N ${squadra.perse}P',
                        'DR: ${squadra.differenzaReti > 0 ? '+' : ''}${squadra.differenzaReti}',
                      ],
                      onTap: () => context.go('/girone-c'),
                    ),
                  ),
                );
              },
            ),

            // ============================================================
            // CARD PRINCIPALI
            // ============================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
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
                      if (raccolta.raccoltaOggi)
                        'Oggi: ${raccolta.tipoOggi ?? "raccolta prevista"}'
                      else if (raccolta.prossimoGiornoNome != null)
                        'Prossima: ${raccolta.prossimoGiornoNome} (tra ${raccolta.giorniAllaProssima} giorni)'
                      else
                        'Nessuna raccolta programmata',
                      if (raccolta.raccoltaDomani &&
                          raccolta.tipoDomani != null)
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
                        if (note.noteUrgenti > 0)
                          '${note.noteUrgenti} urgenti',
                        if (note.noteFissate > 0)
                          '${note.noteFissate} fissate',
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
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPER
  // ============================================================

  String _formatData(DateTime data) {
    final giorni = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    final giorno = giorni[data.weekday - 1];
    return '$giorno ${data.day}/${data.month}/${data.year}';
  }

  String _getSaluto() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buongiorno 👋';
    if (hour < 18) return 'Buon pomeriggio 👋';
    return 'Buonasera 👋';
  }

  String _getDataOggi() {
    final now = DateTime.now();
    final giorni = [
      'Domenica',
      'Lunedì',
      'Martedì',
      'Mercoledì',
      'Giovedì',
      'Venerdì',
      'Sabato',
    ];
    final mesi = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];

    final giorno = giorni[now.weekday % 7];
    final mese = mesi[now.month - 1];

    return '$giorno ${now.day} $mese ${now.year}';
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

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

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
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
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...lines.map(
                        (l) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            l,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}