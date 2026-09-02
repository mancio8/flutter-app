import 'package:flutter/material.dart';
import '../../../../core/models/rifornimento.dart';

class RifornimentoCard extends StatelessWidget {
  final Rifornimento rifornimento;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;  // NUOVO: callback per modifica
  final VoidCallback? onTap;

  const RifornimentoCard({
    super.key,
    required this.rifornimento,
    this.onDelete,
    this.onEdit,  // NUOVO
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            Icons.local_gas_station,
            size: 20,
          ),
        ),
        title: Text(
          '${rifornimento.litri.toStringAsFixed(1)} L - ${rifornimento.tipoCarburante}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '€${rifornimento.costo.toStringAsFixed(2)} (€${rifornimento.prezzoPerLitro.toStringAsFixed(3)}/L)',
            ),
            // Mostra chilometraggio o "Nessun km" se mancante
            if (rifornimento.chilometraggio != null)
              Text('${rifornimento.chilometraggio!.toStringAsFixed(0)} km')
            else
              Text(
                'Km non inseriti',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            if (rifornimento.note != null)
              Text(
                rifornimento.note!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsante modifica
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                tooltip: 'Modifica',
              ),
            // Pulsante elimina
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                tooltip: 'Elimina',
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}