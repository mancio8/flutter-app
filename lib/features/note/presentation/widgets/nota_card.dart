import 'package:flutter/material.dart';
import '../../../../core/models/nota.dart';

class NotaCard extends StatelessWidget {
  final Nota nota;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePin;

  const NotaCard({
    super.key,
    required this.nota,
    this.onTap,
    this.onDelete,
    this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final colore = ColoreNota.fromValue(nota.colore);
    final coloreTesto = ThemeData.estimateBrightnessForColor(colore) ==
            Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Material(
      color: colore,
      borderRadius: BorderRadius.circular(16),
      elevation: nota.fissata ? 4 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(nota.categoria.icon, size: 16, color: coloreTesto.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Text(
                    nota.categoria.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: coloreTesto.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onTogglePin,
                    child: Icon(
                      nota.fissata ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                      color: coloreTesto.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  nota.testo,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: coloreTesto, fontSize: 14, height: 1.3),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatData(nota.dataCreazione),
                    style: TextStyle(fontSize: 10, color: coloreTesto.withOpacity(0.6)),
                  ),
                  InkWell(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline, size: 16, color: coloreTesto.withOpacity(0.6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatData(DateTime data) {
    return '${data.day}/${data.month}/${data.year}';
  }
}