// File: lib/features/biblioteca/data/repository/biblioteca_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/libro.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BibliotecaRepository {
  final SupabaseClient _supabase;

  BibliotecaRepository(this._supabase);

  // Ottiene tutti i libri letti
  Future<List<Libro>> getLibriLetti() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('biblioteca_libri')
        .select()
        .eq('user_id', userId)
        .not('read_date', 'is', null) // Questo è corretto
        .order('read_date', ascending: false);

    return response.map<Libro>((json) => Libro.fromJson(json)).toList();
  }

  // Ottiene la wishlist
  // Ottiene la wishlist
  Future<List<Libro>> getWishlist() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('biblioteca_libri')
        .select()
        .eq('user_id', userId)
        .eq('in_wishlist', true)
        .filter(
          'read_date',
          'is',
          null,
        ) // FIX: "is" è riservato, si usa filter()
        .order('wishlist_date', ascending: false);

    return response.map<Libro>((json) => Libro.fromJson(json)).toList();
  }

  // Aggiunge un libro alla wishlist
  Future<void> addToWishlist(Libro libro) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final existing = await _supabase
        .from('biblioteca_libri')
        .select('id')
        .eq('user_id', userId)
        .eq('title', libro.titolo)
        .eq('author', libro.autore)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('biblioteca_libri')
          .update({
            'in_wishlist': true,
            'wishlist_date': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
    } else {
      final data = {
        'title': libro.titolo,
        'author': libro.autore,
        'cover_url': libro.copertinaUrl ?? '',
        'genre': libro.genere,
        'description': libro.descrizione,
        'in_wishlist': true,
        'wishlist_date': DateTime.now().toIso8601String(),
        'user_id': userId,
      };

      await _supabase.from('biblioteca_libri').insert(data);
    }
  }

  // Sposta un libro dalla wishlist ai libri letti
  Future<void> moveToRead(Libro libro, DateTime dataLettura) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase
        .from('biblioteca_libri')
        .update({
          'read_date': dataLettura.toIso8601String().split('T')[0],
          'in_wishlist': false,
          'wishlist_date': null,
        })
        .eq('id', libro.id)
        .eq('user_id', userId);
  }

  // Rimuove un libro dalla wishlist
  Future<void> removeFromWishlist(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final existing = await _supabase
        .from('biblioteca_libri')
        .select('read_date')
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null && existing['read_date'] == null) {
      await _supabase
          .from('biblioteca_libri')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } else {
      await _supabase
          .from('biblioteca_libri')
          .update({'in_wishlist': false, 'wishlist_date': null})
          .eq('id', id)
          .eq('user_id', userId);
    }
  }

  // Cerca libri su Google Books API
  Future<List<Libro>> searchBooksOnline(String query) async {
    final googleBooksApiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'];

    try {
      final url = Uri.https('www.googleapis.com', '/books/v1/volumes', {
        'q': query,
        'maxResults': '20',
        'key': googleBooksApiKey,
      });

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        print('Errore Google Books: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body);
      final items = data['items'];

      if (items == null || items is! List) {
        print('Nessun items nella risposta');
        return [];
      }

      return items.map<Libro>((item) {
        final info = Map<String, dynamic>.from(item['volumeInfo'] ?? {});

        final categories = info['categories'];

        // Google Books a volte restituisce http://
        String? copertinaUrl = info['imageLinks']?['thumbnail']?.toString();

        if (copertinaUrl != null) {
          copertinaUrl = copertinaUrl.replaceFirst('http://', 'https://');
        }

        return Libro(
          id:
              item['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),

          titolo: info['title']?.toString() ?? 'Titolo sconosciuto',

          autore: info['authors'] is List
              ? (info['authors'] as List).join(', ')
              : 'Autore sconosciuto',

          copertinaUrl: copertinaUrl,

          genere: categories is List && categories.isNotEmpty
              ? categories.first.toString()
              : null,

          descrizione: info['description']?.toString(),
        );
      }).toList();
    } catch (e, stackTrace) {
      print('ERRORE searchBooksOnline: $e');
      print(stackTrace);
      return [];
    }
  }

  // Aggiunge un libro letto
  Future<void> addLibro(Libro libro) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final data = {
      'title': libro.titolo,
      'author': libro.autore,
      'read_date': libro.dataLettura?.toIso8601String().split('T')[0],
      'cover_url': libro.copertinaUrl ?? '',
      'genre': libro.genere,
      'description': libro.descrizione,
      'user_id': userId,
    };

    await _supabase.from('biblioteca_libri').insert(data);
  }

  // Aggiorna un libro
  Future<void> updateLibro(Libro libro) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    final data = {
      'title': libro.titolo,
      'author': libro.autore,
      'read_date': libro.dataLettura?.toIso8601String().split('T')[0],
      'cover_url': libro.copertinaUrl ?? '',
      'genre': libro.genere,
      'description': libro.descrizione,
      'rating': libro.valutazione,
      'review': libro.recensione,
      'user_id': userId,
    };

    await _supabase
        .from('biblioteca_libri')
        .update(data)
        .eq('id', libro.id)
        .eq('user_id', userId);
  }

  // Elimina un libro
  Future<void> deleteLibro(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    await _supabase
        .from('biblioteca_libri')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  // Esporta in JSON
  Future<String> exportToJson() async {
    final libri = await getLibriLetti();

    final jsonList = libri
        .map(
          (l) => {
            'title': l.titolo,
            'author': l.autore,
            'read_date': l.dataLettura?.toIso8601String().split('T')[0],
            'cover_url': l.copertinaUrl ?? '',
          },
        )
        .toList();

    return JsonEncoder.withIndent('  ').convert(jsonList);
  }

  // Importa da JSON con gestione migliorata
  Future<int> importFromJson(String jsonString, {bool merge = true}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utente non autenticato');

    try {
      final List<dynamic> jsonList = json.decode(jsonString);

      if (jsonList.isEmpty) return 0;

      print('Inizio importazione: ${jsonList.length} libri, merge: $merge');

      final List<Map<String, dynamic>> libriDaImportare = [];
      final Set<String> chiaviEsistenti = {};

      if (merge) {
        final existingLibri = await getLibriLetti();
        chiaviEsistenti.addAll(
          existingLibri.map(
            (l) =>
                '${l.titolo.toLowerCase().trim()}|${l.autore.toLowerCase().trim()}',
          ),
        );
      }

      for (var i = 0; i < jsonList.length; i++) {
        try {
          final map = jsonList[i] as Map<String, dynamic>;

          final titolo = (map['title'] ?? map['titolo'] ?? '')
              .toString()
              .trim();
          final autore = (map['author'] ?? map['autore'] ?? '')
              .toString()
              .trim();
          final dataLettura = map['read_date'] != null
              ? DateTime.parse(map['read_date'])
              : null;
          final coverUrl =
              map['cover_url'] ?? map['cover'] ?? map['copertinaUrl'] ?? '';

          if (titolo.isEmpty || autore.isEmpty) continue;

          final chiave = '$titolo|$autore'.toLowerCase();

          if (merge && chiaviEsistenti.contains(chiave)) {
            print('Duplicato saltato: $titolo');
            continue;
          }

          final data = {
            'title': titolo,
            'author': autore,
            'read_date': dataLettura?.toIso8601String().split('T')[0],
            'cover_url': coverUrl.toString(),
            'user_id': userId,
          };

          libriDaImportare.add(data);

          if (merge) {
            chiaviEsistenti.add(chiave);
          }
        } catch (e) {
          print('Errore nel parsing del libro $i: $e');
        }
      }

      print('Libri da importare: ${libriDaImportare.length}');

      if (!merge) {
        print('Eliminazione libri esistenti...');
        await _supabase.from('biblioteca_libri').delete().eq('user_id', userId);
      }

      int importati = 0;
      const batchSize = 500;

      for (var i = 0; i < libriDaImportare.length; i += batchSize) {
        final batch = libriDaImportare.sublist(
          i,
          i + batchSize > libriDaImportare.length
              ? libriDaImportare.length
              : i + batchSize,
        );

        if (batch.isNotEmpty) {
          await _supabase.from('biblioteca_libri').insert(batch);
          importati += batch.length;
        }
      }

      print('Importazione completata: $importati libri');
      return importati;
    } catch (e) {
      print('Errore durante l\'importazione: $e');
      throw Exception('Errore durante l\'importazione: $e');
    }
  }
}
