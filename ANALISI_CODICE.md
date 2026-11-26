# Analisi del codice — flutter-starter-app

## Sintesi

- **Perimetro analizzato:** intero progetto `flutter-starter-app` (~111 file Dart in `lib/`, ~31.600 LOC), configurazioni (`pubspec.yaml`, `analysis_options.yaml`, `l10n.yaml`), entry point (`main.dart`, `app.dart`), routing, providers, repository, template di piattaforma (`android`, `web`, `linux`), CI (`.github/workflows`), Docker.
- **Stack rilevato:** Flutter 3.41.9 / Dart SDK ^3.8.1, Riverpod 2.6, `go_router` 14.8, Supabase (`supabase_flutter` 2.9), Freezed + `json_serializable`, `fl_chart`, `flutter_animate`, `google_fonts`, `intl` (l10n IT/EN/ES/FR), `dio`, `http`, `file_picker`, `share_plus`, `shared_preferences`, `flutter_secure_storage`, `flutter_dotenv`.
- **Esito complessivo:** applicazione **funzionale e ben strutturata** (feature-first con layering `presentation`/`providers`/`repository`/`data`/`domain`). Rispetto alla revisione precedente sono stati **rimossi i mock** (`AuthRepository`, `MockApiService` + modulo `users` demo) e **risolti 4 rilievi** (`.env` negli asset, `print()` in release, `withOpacity` deprecati, cast `state.extra` insicuro). Restano **debito tecnico** (`dart:io` in codice shared, file UI > 1000 LOC) e **assenza di test**.
- **Rilievi:** **0 Critica**, **2 Alta**, **7 Media**, **4 Bassa**, **2 Informative** (15 totali, di cui 4 risolti).

**Nota metodologica:** `flutter analyze` eseguito in questa sessione (0 errori). L'analisi è basata su lettura statica del codice, verifiche `grep` e controllo della struttura.

---

## Problemi individuati

### [RISOLTA] `.env` incluso negli asset

- **Stato:** ✅ **Risolta** — `.env` rimosso dagli asset (`pubspec.yaml`), creato `.env.example`, `main.dart` usa `--dart-define` primario + fallback `dotenv` (dev) con messaggio d'errore chiaro al posto dei `!`. Lo script `build-apk.sh` legge `.env` e inietta le credenziali con `--dart-define`.
- **File:** `pubspec.yaml` (asset), `lib/main.dart`, `.env.example`
- **Nota:** `.env` **non era tracciato in git** (già correttamente ignorato dal `.gitignore`); il problema reale era l'inclusione negli asset, ora risolta.

### [RISOLTA] `print()` di dati sensibili in release

- **Stato:** ✅ **Risolta** — 30 `print()` sostituiti con `developer.log()` (no-op in release) in `error_handler.dart`, `biblioteca_repository.dart`, `biblioteca_provider.dart`, `onboarding_page.dart`.
- **File:** `lib/core/error/error_handler.dart`, `lib/features/biblioteca/repository/biblioteca_repository.dart`, `lib/features/biblioteca/providers/biblioteca_provider.dart`, `lib/features/onboarding/presentation/pages/onboarding_page.dart`
- **Verifica:** `grep print()` in `lib/` → 0 occorrenze; `flutter analyze` → 0 errori.

---

### [ALTA] `dart:io` in codice shared (rompe il build web)

- **File:** `lib/features/biblioteca/presentation/pages/biblioteca_page.dart:2`, `lib/features/habits/presentation/pages/habits_page.dart:2`, `lib/features/rifornimenti/presentation/pages/rifornimenti_page.dart:2`, `lib/features/habits/services/habits_import_export_service.dart:2`, `lib/features/rifornimenti/services/rifornimenti_export_service.dart:2`
- **Evidenza:** `import 'dart:io';` in 5 file, con uso di `File(...)`, `Directory`, `Platform`. Il progetto ha `web/` e importa `flutter_web_plugins/url_strategy.dart` in `main.dart`, quindi il web è un target dichiarato. Ma `dart:io` **non è disponibile su web**: `flutter build web` fallisce.
- **Scenario:** `flutter build web` → errore di compilazione. Se il web non è un target attivo, il problema è latente.
- **Impatto:** build web impossibile; codice non portabile.
- **Correzione consigliata:**
  1. Astrarre le operazioni file dietro un'interfaccia con implementazioni `kIsWeb`/native.
  2. Usare `dart:io` solo dietro guardia `if (!kIsWeb)`.
  3. Valutare se il web è un target reale: se no, rimuovere `web/` e `flutter_web_plugins`.
- **Test di verifica:** `flutter build web` → compila; `grep -rln "dart:io" lib/` → solo file con guardia `kIsWeb`.

### [RISOLTA] `state.extra` cast insicuro nel router

- **Stato:** ✅ **Risolta** — cast sicuro con `is` check: `state.extra is DartsGameConfig ? state.extra as DartsGameConfig : null`. Se arriva un tipo diverso (deep-link), mostra "Partita non valida" invece di crashare.
- **File:** `lib/core/router/app_router.dart:185`
- **Verifica:** `flutter analyze` → 0 errori.

---

### [RISOLTA] `withOpacity` deprecato

- **Stato:** ✅ **Risolta** — 103 occorrenze di `withOpacity(x)` sostituite con `withValues(alpha: x)` in 22 file.
- **Verifica:** `grep withOpacity()` in `lib/` → 0 occorrenze; `flutter analyze` → 0 errori.

---

### [MEDIA] File UI > 1000 LOC

- **File:** `lib/features/viaggi/presentation/pages/viaggi_page.dart` (1424), `lib/features/veicoli/presentation/pages/gestione_veicolo_page.dart` (1374), `lib/features/habits/presentation/pages/habits_page.dart` (1185), `lib/features/settings/presentation/pages/settings_page.dart` (1060)
- **Evidenza:** file UI con > 1000 righe che mescolano widget, logica, formattazione, export.
- **Scenario:** manutenibilità, merge conflict, testabilità.
- **Correzione consigliata:** estrarre widget in `widgets/`, logica in `providers/`, helper in `services/`.
- **Test di verifica:** nessun file > 600 LOC (esclusi file generati `l10n/`).

### [MEDIA] Nessun test (1 solo file)

- **File:** `test/widget_test.dart`
- **Evidenza:** `find test -name "*.dart"` → 1 file (smoke test di base).
- **Scenario:** ogni modifica a provider/repository/routing non ha rete di sicurezza.
- **Impatto:** regressioni silenti.
- **Correzione consigliata:** test su `authProvider` (login/logout), `routerProvider` (redirect), repository principali (CRUD), widget chiave.
- **Test di verifica:** `flutter test` → > 20 test verdi.

### [MEDIA] Localizzazione incompleta: stringhe hardcoded

- **File:** `lib/shared/widgets/responsive_scaffold.dart:260,361` (`label: const Text('Fuel')`, `label: 'Fuel'`), e altre voci non localizzate
- **Evidenza:** "Fuel" hardcoded mentre le altre voci usano `l10n.home`, `l10n.dashboard`, `l10n.settings`.
- **Scenario:** in ES/FR la voce "Fuel" resta in inglese.
- **Correzione consigliata:** aggiungere `fuel` ai 4 `.arb` e usare `l10n.fuel`.
- **Test di verifica:** `flutter gen-l10n` + build in ES/FR → "Fuel" tradotto.

### [MEDIA] `AuthState.copyWith` con `clearUser` + `user` ambiguo

- **File:** `lib/features/auth/presentation/providers/auth_provider.dart:15-27`
- **Evidenza:** se `clearUser=true` e `user` non null, il risultato è `null` (user ignorato). Comportamento corretto ma fragile.
- **Scenario:** chiamate future con entrambi i parametri → risultato non ovvio.
- **Correzione consigliata:** `assert(!(clearUser && user != null))` o documentare.
- **Test di verifica:** test unit di `copyWith`.

### [MEDIA] `web/manifest.json` e `web/index.html` con metadati di default

- **File:** `web/manifest.json:2-8`, `web/index.html:22`
- **Evidenza:** `"name": "flutter_starter"`, `"description": "A new Flutter project."`, `<meta name="description" content="A new Flutter project.">`.
- **Scenario:** se il web è pubblicato, appare come "flutter_starter" in PWA/SEO.
- **Correzione consigliata:** aggiornare `name`, `short_name`, `description`, `theme_color`, meta description.
- **Test di verifica:** build web → manifest con nome reale.

### [MEDIA] `analysis_options.yaml` non personalizzato

- **File:** `analysis_options.yaml`
- **Evidenza:** include solo `package:flutter_lints/flutter.yaml`; sezione `rules:` commentata.
- **Scenario:** lint di default, nessuna regola aggiuntiva.
- **Correzione consigliata:** aggiungere `prefer_single_quotes`, `avoid_print`, `require_trailing_commas`.
- **Test di verifica:** `flutter analyze` → più warning utili.

---

### [BASSA] `pubspec.yaml` senza versioni pin per le dipendenze dirette

- **File:** `pubspec.yaml:30-75`
- **Evidenza:** tutte le dipendenze usano `^` (caret).
- **Scenario:** `flutter pub upgrade` può introdurre breaking change non testati.
- **Correzione consigliata:** revisione con `flutter pub outdated`; pin mirato delle dipendenze critiche. `pubspec.lock` già committato.
- **Test di verifica:** `flutter pub outdated` → revisione.

### [BASSA] File di log e `.flutter-plugins-dependencies` nella root

- **File:** `flutter_01.log` … `flutter_06.log`, `.flutter-plugins-dependencies`
- **Evidenza:** file di log (6 file) e `.flutter-plugins-dependencies` presenti nella root, possibilmente tracciati.
- **Scenario:** rumore nel repository, informazioni di build obsolete.
- **Correzione consigliata:** aggiungere a `.gitignore`: `*.log`, `.flutter-plugins-dependencies`; rimuovere dal tracking con `git rm --cached`.
- **Test di verifica:** `git ls-files | grep -E "\.log$|flutter-plugins"` → vuoto.

### [BASSA] `db/` con SQL non versionato in migrazioni

- **File:** `db/allenamento.sql`, `db/manutenzione.sql`, `db/setting_partita.sql`, `db/viaggi.sql`
- **Evidenza:** 4 file SQL con schema Supabase, senza numerazione di migrazione.
- **Scenario:** modifiche allo schema non tracciate, divergenza tra ambienti.
- **Correzione consigliata:** usare Supabase migrations (`supabase migration new`) o numerare i file.
- **Test di verifica:** `supabase migration list` coerente con `db/`.

### [BASSA] `.env.example` mancante

- **File:** root
- **Evidenza:** `.env.example` non presente, ma `.gitignore` lo prevede (`!.env.example`) e `main.dart` usa `!` su chiavi lette da `.env`.
- **Scenario:** un nuovo sviluppatore clona il repo, non trova `.env.example`, avvia l'app → crash con `Null check operator` se `.env` manca.
- **Correzione consigliata:** creare `.env.example` con i soli nomi delle chiavi; sostituire i `!` in `main.dart` con controlli espliciti.
- **Test di verifica:** avvio senza `.env` → messaggio d'errore chiaro.

---

## Aspetti da approfondire

- **`flutter analyze` e `flutter test`**: non eseguiti in questa sessione. **Da eseguire in locale**:
  ```bash
  cd /home/vincenzo/Sviluppo/flutter-starter-app
  flutter pub get
  flutter analyze
  flutter test
  flutter build web     # per verificare il problema dart:io
  ```
- **Policy RLS Supabase**: non verificabili dal codice. Controllare su `db/*.sql` e nella dashboard Supabase che ogni tabella esposta abbia RLS attive.
- **Contenuto di `.env`**: non ispezionato per policy. Verificare manualmente che non contenga `SERVICE_ROLE_KEY` o chiavi con privilegi elevati, e che `SUPABASE_ANON_KEY` sia la sola chiave client.
- **Piattaforme target reali**: il progetto ha `android`, `ios`, `web`, `linux`, `macos`, `windows`. Il `dart:io` suggerisce che il web non è tra i target attivi; chiarire se il web va supportato o rimosso.

## Controlli eseguiti

| Controllo | Comando/strumento | Esito |
|---|---|---|
| Test | `flutter test` | **Non eseguito** — 1 solo file di test presente |
| Lint/Analisi | `flutter analyze` | **Eseguito: 0 errori** (209 info/warning preesistenti) |
| Build web | `flutter build web` | **Non eseguito** — `dart:io` rilevato come rischio |
| Build APK | `flutter build apk --release --dart-define=...` | **Eseguito: OK** (verifica credenziali) |
| Struttura | `find lib -name "*.dart"` | Eseguito: ~111 file |
| File > 1000 LOC | `wc -l` ordinato | Eseguito: 4 file UI (viaggi 1424, gestione_veicolo 1374, habits 1185, settings 1060) |
| `print()` debug | `grep -rn "print("` | **Risolto: 0 occorrenze** (30 sostituiti con `developer.log`) |
| `withOpacity` deprecato | `grep -rn "withOpacity"` | **Risolto: 0 occorrenze** (103 → `withValues(alpha:)`) |
| `dart:io` in shared | `grep -rn "import 'dart:io'"` | Eseguito: 5 file (3 pagine UI + 2 service) |
| Mock rimossi | `grep -rn "mockApiService\|AuthRepository"` | Eseguito: **0 occorrenze** ✓ |
| Asset `.env` | lettura `pubspec.yaml` | **Risolto: rimosso dagli asset** |
| `.env` tracciato | `git ls-files .env` | **Non tracciato** (già ignorato) ✓ |
| `.env.example` | `ls .env.example` | **Creato** ✓ |
| Router | lettura `app_router.dart` | **Risolto: cast `state.extra` con `is` check** |
| Auth | lettura `auth_provider.dart` | Eseguito: solo Supabase, `copyWith` ambiguo |
| Generated code | freezed/json | Eseguito: 4 file generati |

## Priorità operative

**Correzioni necessarie (subito):**
1. ~~Rimuovere `.env` dagli asset, passare a `--dart-define`.~~ ✅ **Risolta**
2. ~~Sostituire i 28 `print()` con `developer.log`.~~ ✅ **Risolta**
3. **Rimuovere `dart:io` dal codice shared** (guardia `kIsWeb` o astrazione). — Alta
4. ~~Fix cast `state.extra` con `is` check.~~ ✅ **Risolta**
5. ~~Sostituire `withOpacity` → `withValues(alpha:)`.~~ ✅ **Risolta**

**Miglioramenti (dopo stabilizzazione):**
6. ~~Creare `.env.example` e sostituire i `!` in `main.dart`.~~ ✅ **Risolta**
7. Aggiungere test su `authProvider`, `routerProvider`, repository principali.
8. Estrarre widget dai file > 1000 LOC.
9. Completare la localizzazione (`Fuel` hardcoded).
10. Aggiornare `web/manifest.json` e `index.html` con nome reale.
11. Ripulire `.gitignore` per `*.log` e `.flutter-plugins-dependencies` (file già tracciati).
12. Sostituire i file SQL in `db/` con Supabase migrations.
13. Valutare se il target web è reale: se no, rimuovere `web/` e `flutter_web_plugins`.

**Non modificare senza autorizzazione:** tutte le correzioni richiedono la tua approvazione.