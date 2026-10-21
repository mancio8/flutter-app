import 'package:flutter/material.dart';
import '../../domain/x01_game.dart' show DartThrow;

// Come sul bersaglio: triplo rosso, doppio verde.
// Se hai già cambiato i colori (palette per daltonici), tieni i tuoi.
Color multColor(int m) => switch (m) {
      3 => const Color(0xFFE53935),
      2 => const Color(0xFF2E9E5B),
      _ => const Color(0xFF607D8B),
    };

class DartSlot extends StatelessWidget {
  const DartSlot({super.key, required this.dart, this.subText});
  final DartThrow? dart;
  final String? subText; // se null mostra i punti

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = dart;
    final c = d == null
        ? theme.colorScheme.outlineVariant
        : (d.value == 0 ? const Color(0xFF607D8B) : multColor(d.mult));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: d == null ? Colors.transparent : c.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c, width: d == null ? 1 : 2),
      ),
      child: Column(
        children: [
          Text(
            d?.label ?? '·',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: d == null ? theme.colorScheme.outline : c,
            ),
          ),
          Text(
            d == null ? ' ' : (subText ?? '${d.points}'),
            style: TextStyle(fontSize: 11, color: c),
          ),
        ],
      ),
    );
  }
}