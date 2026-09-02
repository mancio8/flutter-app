import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/raccolta.dart';
import '../../providers/raccolta_provider.dart';
import '../widgets/day_pill.dart';
import '../widgets/waste_card.dart';

class RaccoltaPage extends ConsumerWidget {
  const RaccoltaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raccoltaAsync = ref.watch(raccoltaGiornoProvider);
    final tuttiGiorniAsync = ref.watch(tuttiGiorniProvider);
    final giornoSelezionato = ref.watch(giornoSelezionatoProvider);
    final oggi = DateTime.now().weekday % 7;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header con gradiente
          SliverAppBar(
            expandedHeight: 160,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B5E20), // Verde scuro
                      Color(0xFF2E7D32), // Verde medio
                      Color(0xFF43A047), // Verde chiaro
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Icona decorativa
                    Positioned(
                      right: 20,
                      top: 20,
                      child: Icon(
                        Icons.recycling,
                        size: 80,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    // Contenuto
                    Positioned(
                      left: 16,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '♻️',
                                style: TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Raccolta Differenziata',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getDataOggi(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  // Selettore giorni
                  Text(
                    'Seleziona giorno',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  tuttiGiorniAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Text('Errore: $e'),
                    data: (giorni) {
                      return SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: giorni.length,
                          itemBuilder: (context, index) {
                            final giorno = giorni[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: DayPill(
                                label: giorno.nome.substring(0, 3),
                                isActive: giorno.giorno == giornoSelezionato,
                                isToday: giorno.giorno == oggi,
                                onTap: () {
                                  ref
                                      .read(giornoSelezionatoProvider.notifier)
                                      .state = giorno.giorno;
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Orario conferimento
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE8F5E9),
                          const Color(0xFFF1F8E9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🕙', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Orario conferimento',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'La sera prima dalle 22:00 alle 05:00',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF2E7D32).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Titolo raccolta del giorno
                  raccoltaAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Text('Errore: $e'),
                    data: (raccolta) {
                      return Row(
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
                            'Raccolta di ${raccolta.nome}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Schede rifiuti
                  raccoltaAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Text('Errore: $e'),
                    data: (raccolta) {
                      if (raccolta.rifiuti.isEmpty) {
                        return _NoCollectionCard(theme: theme);
                      }
                      
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: raccolta.rifiuti.length,
                        itemBuilder: (context, index) {
                          return WasteCard(
                            rifiuto: raccolta.rifiuti[index],
                            index: index,
                          );
                        },
                      );
                    },
                  ),
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
    if (width > 600) return 3;
    return 2;
  }

  String _getDataOggi() {
    final now = DateTime.now();
    final giorni = [
      'Domenica', 'Lunedì', 'Martedì', 'Mercoledì',
      'Giovedì', 'Venerdì', 'Sabato'
    ];
    final mesi = [
      'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
      'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'
    ];
    
    final giorno = giorni[now.weekday % 7];
    final mese = mesi[now.month - 1];
    
    return 'Oggi è $giorno ${now.day} $mese ${now.year}';
  }
}

// Card per "nessuna raccolta"
class _NoCollectionCard extends StatelessWidget {
  final ThemeData theme;

  const _NoCollectionCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuna raccolta prevista',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Goditi la giornata di riposo!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}