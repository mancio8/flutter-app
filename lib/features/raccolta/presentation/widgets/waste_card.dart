import 'package:flutter/material.dart';
import '../../../../core/models/raccolta.dart';

class WasteCard extends StatelessWidget {
  final TipoRifiuto rifiuto;
  final int index;

  const WasteCard({
    super.key,
    required this.rifiuto,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Colori per ogni tipo di rifiuto
    final color = _getColorForType(rifiuto.titolo, theme);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icona in cerchio colorato
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rifiuto.icona,
                      style: const TextStyle(fontSize: 35),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Titolo
                Text(
                  rifiuto.titolo,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                
                // Nota (se presente)
                if (rifiuto.nota != null && rifiuto.nota!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rifiuto.nota!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForType(String tipo, ThemeData theme) {
    final tipoLower = tipo.toLowerCase();
    
    if (tipoLower.contains('umido')) {
      return const Color(0xFF6D4C41); // Marrone
    } else if (tipoLower.contains('carta') || tipoLower.contains('cartone')) {
      return const Color(0xFF1976D2); // Blu
    } else if (tipoLower.contains('plastica')) {
      return const Color(0xFFFFA000); // Arancione
    } else if (tipoLower.contains('vetro')) {
      return const Color(0xFF00897B); // Verde acqua
    } else if (tipoLower.contains('indifferenziato')) {
      return const Color(0xFF757575); // Grigio
    } else if (tipoLower.contains('pannol')) {
      return const Color(0xFFEC407A); // Rosa
    } else if (tipoLower.contains('oli')) {
      return const Color(0xFFFDD835); // Giallo
    } else if (tipoLower.contains('erba') || tipoLower.contains('sfalcio')) {
      return const Color(0xFF43A047); // Verde
    }
    
    return theme.colorScheme.primary;
  }
}