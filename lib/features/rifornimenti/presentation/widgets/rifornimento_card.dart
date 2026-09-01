import 'package:flutter/material.dart';
// Import dal core models
import '../../../../core/models/rifornimento.dart';

// Card che mostra un singolo rifornimento
class RifornimentoCard extends StatelessWidget {
  final Rifornimento rifornimento;
  final VoidCallback? onDelete;

  const RifornimentoCard({
    super.key,
    required this.rifornimento,
    this.onDelete,
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
            if (rifornimento.chilometraggio != null)
              Text('${rifornimento.chilometraggio!.toStringAsFixed(0)} km'),
            if (rifornimento.note != null)
              Text(
                rifornimento.note!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              )
            : null,
        isThreeLine: rifornimento.note != null,
      ),
    );
  }
}