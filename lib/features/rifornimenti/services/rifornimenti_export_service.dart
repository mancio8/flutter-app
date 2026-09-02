import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/rifornimento.dart';

class RifornimentiExportService {
  
  // Esporta in formato JSON
  static Future<File> exportToJson(List<Rifornimento> rifornimenti) async {
    // Ottieni la directory dei documenti dell'app
    final directory = await getApplicationDocumentsDirectory();
    
    // Crea un nome file univoco con timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/rifornimenti_$timestamp.json');
    
    // Converte i rifornimenti in JSON
    final jsonData = rifornimenti.map((r) => r.toJson()).toList();
    
    // Crea una stringa JSON formattata (leggibile)
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
    
    // Scrivi il file
    await file.writeAsString(jsonString);
    
    return file;
  }
  
  // Condividi un file
  static Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }
  
  // Esporta e condividi direttamente
  static Future<void> exportAndShareJson(List<Rifornimento> rifornimenti) async {
    final file = await exportToJson(rifornimenti);
    await shareFile(file);
  }
}