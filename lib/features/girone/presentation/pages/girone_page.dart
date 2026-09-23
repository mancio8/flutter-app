// File: lib/features/girone/presentation/pages/girone_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/squadra_calcio.dart';
import '../../../../core/models/partita_calcio.dart';
import '../../providers/girone_provider.dart';

class GironePage extends ConsumerStatefulWidget {
  const GironePage({super.key});

  @override
  ConsumerState<GironePage> createState() => _GironePageState();
}

class _GironePageState extends ConsumerState<GironePage> {
  // 0 = Classifica, 1 = Calendario
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(classificaProvider);
          ref.invalidate(calendarioProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ============================================================
            // SLIVER APP BAR — identica alle altre pagine
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
                    const Icon(Icons.sports_soccer, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Girone C',
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
                      Icons.emoji_events_outlined,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            // ============================================================
            // SELETTORE CLASSIFICA / CALENDARIO
            // ============================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(6),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Classifica',
                          icon: Icons.leaderboard_outlined,
                          isActive: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _TabButton(
                          label: 'Calendario',
                          icon: Icons.calendar_month_outlined,
                          isActive: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ============================================================
            // CONTENUTO
            // ============================================================
            if (_selectedTab == 0)
              const _ClassificaSliver()
            else
              const _CalendarioSliver(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB BUTTON — stile coerente con le altre pagine
// ============================================================

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeData theme;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CLASSIFICA — sliver
// ============================================================

class _ClassificaSliver extends ConsumerWidget {
  const _ClassificaSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classificaAsync = ref.watch(classificaProvider);
    final theme = Theme.of(context);

    return classificaAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => SliverFillRemaining(
        child: _DatiNonDisponibili(theme: theme),
      ),
      data: (classifica) {
        if (classifica.isEmpty) {
          return SliverFillRemaining(
            child: _DatiNonDisponibili(theme: theme),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Container(
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
              child: Column(
                children: [
                  // Header tabella
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                    child: Row(
                      children: [
                        const SizedBox(width: 28),
                        const SizedBox(width: 4),
                        const SizedBox(width: 32), // logo
                        const SizedBox(width: 8),
                        const Expanded(
                          flex: 4,
                          child: Text(
                            'Squadra',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Pt',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'G',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'DR',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...classifica.map(
                    (s) => _ClassificaRow(squadra: s),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClassificaRow extends StatelessWidget {
  final SquadraCalcio squadra;

  const _ClassificaRow({required this.squadra});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Colore posizione
    Color posColor;
    Color posBg;
    if (squadra.posizione <= 2) {
      posColor = Colors.green[800]!;
      posBg = Colors.green.withOpacity(0.12);
    } else if (squadra.posizione <= 4) {
      posColor = Colors.blue[800]!;
      posBg = Colors.blue.withOpacity(0.12);
    } else if (squadra.posizione >= 9) {
      posColor = theme.colorScheme.error;
      posBg = theme.colorScheme.error.withOpacity(0.1);
    } else {
      posColor = theme.colorScheme.onSurfaceVariant;
      posBg = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Posizione colorata
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: posBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${squadra.posizione}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: posColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Logo squadra
          _LogoBox(
            logoUrl: squadra.logoUrl,
            fallbackText: squadra.nome.isNotEmpty ? squadra.nome[0] : '?',
            size: 32,
            theme: theme,
          ),
          const SizedBox(width: 10),

          // Nome
          Expanded(
            flex: 4,
            child: Text(
              squadra.nome,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Punti
          Expanded(
            child: Text(
              '${squadra.punti}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          // Partite giocate
          Expanded(
            child: Text(
              '${squadra.partiteGiocate}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),

          // Differenza reti
          Expanded(
            child: Text(
              squadra.differenzaReti > 0
                  ? '+${squadra.differenzaReti}'
                  : '${squadra.differenzaReti}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: squadra.differenzaReti > 0
                    ? Colors.green[700]
                    : squadra.differenzaReti < 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CALENDARIO — sliver
// ============================================================

class _CalendarioSliver extends ConsumerWidget {
  const _CalendarioSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarioAsync = ref.watch(calendarioFiltratoProvider);
    final faseSelezionata = ref.watch(faseSelezionataProvider);
    final giornataEffettiva = ref.watch(giornataEffettivaProvider);
    final giornataCorrente = ref.watch(giornataCorrenteProvider);
    final giornateDisponibili = ref.watch(giornateDisponibiliProvider);
    final theme = Theme.of(context);

    // Calcola indice corrente
    final currentIndex = giornateDisponibili.indexOf(giornataEffettiva ?? 0);
    final canGoPrev = currentIndex > 0;
    final canGoNext =
        currentIndex >= 0 && currentIndex < giornateDisponibili.length - 1;

    return SliverList(
      delegate: SliverChildListDelegate([
        // Selettore Andata/Ritorno
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(6),
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
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Andata',
                    icon: Icons.arrow_forward,
                    isActive: faseSelezionata == FasePartita.andata,
                    onTap: () {
                      ref.read(faseSelezionataProvider.notifier).state =
                          FasePartita.andata;
                      ref
                          .read(giornataSelezionataProvider.notifier)
                          .state = null;
                    },
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TabButton(
                    label: 'Ritorno',
                    icon: Icons.arrow_back,
                    isActive: faseSelezionata == FasePartita.ritorno,
                    onTap: () {
                      ref.read(faseSelezionataProvider.notifier).state =
                          FasePartita.ritorno;
                      ref
                          .read(giornataSelezionataProvider.notifier)
                          .state = null;
                    },
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Navigatore giornata ‹ 5ª Giornata ›
        if (giornateDisponibili.isNotEmpty && giornataEffettiva != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              child: Row(
                children: [
                  // Freccia indietro
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Giornata precedente',
                    color: canGoPrev
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    onPressed: canGoPrev
                        ? () {
                            ref
                                .read(giornataSelezionataProvider.notifier)
                                .state =
                                giornateDisponibili[currentIndex - 1];
                          }
                        : null,
                  ),

                  // Giornata centrale
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$giornataEffettivaª Giornata',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (giornataEffettiva == giornataCorrente) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PROSSIMA',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Freccia avanti
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Giornata successiva',
                    color: canGoNext
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    onPressed: canGoNext
                        ? () {
                            ref
                                .read(giornataSelezionataProvider.notifier)
                                .state =
                                giornateDisponibili[currentIndex + 1];
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),

        // Lista partite
        calendarioAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _DatiNonDisponibili(theme: theme, errore: '$e'),
          data: (partite) {
            if (partite.isEmpty) {
              return _DatiNonDisponibili(theme: theme);
            }

            // Poiché filtriamo per giornata, `partite` contiene solo
            // le partite della giornata selezionata
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: partite
                    .map((p) => _PartitaCard(partita: p))
                    .toList(),
              ),
            );
          },
        ),
      ]),
    );
  }
}

class _PartitaCard extends StatelessWidget {
  final PartitaCalcio partita;

  const _PartitaCard({required this.partita});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: partita.isLive
            ? Border.all(color: Colors.red, width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          // Data + ora + badge live
          if (partita.data != null || partita.isLive)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (partita.isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (partita.data != null)
                    Text(
                      '${_formatData(partita.data!)}'
                      '${partita.ora != null ? " · ${partita.ora!.substring(0, 5)}" : ""}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

          // Squadre
          Row(
            children: [
              // Casa
              Expanded(
                child: Column(
                  children: [
                    _LogoBox(
                      logoUrl: partita.logoCasa,
                      fallbackText: partita.squadraCasa.isNotEmpty
                          ? partita.squadraCasa[0]
                          : '?',
                      size: 44,
                      theme: theme,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      partita.squadraCasa,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Risultato
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: partita.giocata
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${partita.golCasa} - ${partita.golTrasferta}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : Text(
                        'vs',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),

              // Trasferta
              Expanded(
                child: Column(
                  children: [
                    _LogoBox(
                      logoUrl: partita.logoTrasferta,
                      fallbackText: partita.squadraTrasferta.isNotEmpty
                          ? partita.squadraTrasferta[0]
                          : '?',
                      size: 44,
                      theme: theme,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      partita.squadraTrasferta,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Campo
          if (partita.campo != null && partita.campo!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    partita.campo!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatData(DateTime data) {
    final giorni = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    final giorno = giorni[data.weekday - 1];
    return '$giorno ${data.day}/${data.month}/${data.year}';
  }
}

// ============================================================
// LOGO BOX — con fallback
// ============================================================

class _LogoBox extends StatelessWidget {
  final String? logoUrl;
  final String fallbackText;
  final double size;
  final ThemeData theme;

  const _LogoBox({
    required this.logoUrl,
    required this.fallbackText,
    required this.size,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(4),
        child: Image.network(
          logoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _fallback();
          },
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        fallbackText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ============================================================
// STATO "DATI NON DISPONIBILI"
// ============================================================

class _DatiNonDisponibili extends StatelessWidget {
  final ThemeData theme;
  final String? errore;

  const _DatiNonDisponibili({
    required this.theme,
    this.errore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errore != null
                    ? Icons.error_outline
                    : Icons.sports_soccer_outlined,
                size: 64,
                color: errore != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              errore != null
                  ? 'Errore nel caricamento'
                  : 'Dati non ancora disponibili',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errore != null
                  ? errore!
                  : 'Appena il campionato viene pubblicato, comparirà qui automaticamente.\nScorri verso il basso per aggiornare.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}