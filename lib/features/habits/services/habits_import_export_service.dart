import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/habit.dart';

class HabitsImportExportService {
  
  // ============ ESPORTAZIONE ============
  
  // Esporta in JSON e condividi
  static Future<void> exportAndShareJson(List<Habit> habits) async {
    final file = await exportToJson(habits);
    await Share.shareXFiles([XFile(file.path)]);
  }
  
  // Esporta in JSON
  static Future<File> exportToJson(List<Habit> habits) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/habits_$timestamp.json');
    
    final jsonData = habits.map((h) => h.toJson()).toList();
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
    
    await file.writeAsString(jsonString);
    return file;
  }
  
  // Esporta statistiche in CSV
  static Future<File> exportStatsToCsv(List<Habit> habits) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/habits_stats_$timestamp.csv');
    
    // Crea CSV con statistiche
    final csvRows = <List<String>>[];
    
    // Intestazione
    csvRows.add([
      'Nome',
      'Descrizione',
      'Icona',
      'Streak Attuale',
      'Completamenti Mese',
      'Obiettivo Mensile',
      'Percentuale',
      'Totale Completamenti',
    ]);
    
    // Dati
    final oggi = DateTime.now();
    for (final habit in habits) {
      final completamentiMese = habit.completamentiMese(oggi);
      final percentuale = habit.obiettivoMensile > 0 
          ? (completamentiMese / habit.obiettivoMensile * 100).toStringAsFixed(1)
          : '0';
      
      csvRows.add([
        habit.nome,
        habit.descrizione ?? '',
        habit.icona,
        habit.streakAttuale().toString(),
        completamentiMese.toString(),
        habit.obiettivoMensile.toString(),
        '$percentuale%',
        habit.completamenti.length.toString(),
      ]);
    }
    
    // Converte in CSV
    final csvString = csvRows.map((row) => row.join(',')).join('\n');
    
    await file.writeAsString(csvString);
    return file;
  }
  
  // Esporta statistiche complete (JSON con stats)
  static Future<File> exportStatsToJson(List<Habit> habits) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/habits_stats_$timestamp.json');
    
    final oggi = DateTime.now();
    final statsData = {
      'data_export': oggi.toIso8601String(),
      'totale_habits': habits.length,
      'habits': habits.map((h) {
        final completamentiMese = h.completamentiMese(oggi);
        final percentuale = h.obiettivoMensile > 0 
            ? (completamentiMese / h.obiettivoMensile * 100)
            : 0.0;
        
        return {
          'nome': h.nome,
          'descrizione': h.descrizione,
          'icona': h.icona,
          'colore': h.colore,
          'streak_attuale': h.streakAttuale(),
          'completamenti_mese': completamentiMese,
          'obiettivo_mensile': h.obiettivoMensile,
          'percentuale': double.parse(percentuale.toStringAsFixed(1)),
          'totale_completamenti': h.completamenti.length,
          'data_creazione': h.dataCreazione.toIso8601String(),
          'ultimo_completamento': h.completamenti.isNotEmpty 
              ? h.completamenti.last.toIso8601String() 
              : null,
        };
      }).toList(),
    };
    
    final jsonString = JsonEncoder.withIndent('  ').convert(statsData);
    await file.writeAsString(jsonString);
    return file;
  }
  
  // ============ IMPORTAZIONE ============
  
  // Importa da JSON
  static Future<List<Habit>> importFromJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    
    if (result == null || result.files.isEmpty) {
      return [];
    }
    
    String jsonString;
    if (result.files.single.bytes != null) {
      jsonString = utf8.decode(result.files.single.bytes!);
    } else {
      final file = File(result.files.single.path!);
      jsonString = await file.readAsString();
    }
    
    final List<dynamic> jsonList = json.decode(jsonString);
    
    return jsonList
        .map((json) => Habit.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}