import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/providers/theme_provider.dart';
import 'core/error/error_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handling
  GlobalErrorHandler.initialize();

  // Remove the hash from URLs on web
  usePathUrlStrategy();

  // --- Configurazione Supabase -------------------------------------
  // Priorità: --dart-define (produzione) > .env via dotenv (sviluppo).
  // In release .env non è incluso negli asset: usa --dart-define.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  var url = supabaseUrl;
  var anonKey = supabaseAnonKey;

  // Fallback in sviluppo: carica .env dalla root (ignorato da git)
  if (url.isEmpty || anonKey.isEmpty) {
    try {
      await dotenv.load(fileName: '.env');
      url = dotenv.env['SUPABASE_URL'] ?? '';
      anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    } catch (_) {
      // .env non trovato in build di release: si affidano ai --dart-define
    }
  }

  if (url.isEmpty || anonKey.isEmpty) {
    // Non avviare l'app senza credenziali: mostra un errore chiaro.
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Configurazione mancante.\n\n'
                'Fornisci SUPABASE_URL e SUPABASE_ANON_KEY tramite --dart-define '
                '(produzione) o un file .env (sviluppo).',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Initialize Supabase
  await Supabase.initialize(url: url, anonKey: anonKey);

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}

/// Global Supabase client
final supabase = Supabase.instance.client;