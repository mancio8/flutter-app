# Flutter Starter App

App Flutter (Material 3) con architettura pulita, state management Riverpod,
routing GoRouter e backend **Supabase**.

Supporta **Android, iOS, Web, Linux, macOS e Windows**.

> **Nota**: questo progetto usa **Supabase** come backend (auth + database).
> Il vecchio mock API service e il modulo demo "users" sono stati rimossi;
> ogni feature ora comunica con Supabase.

---

## Indice

- [Requisiti](#requisiti)
- [Avvio rapido](#avvio-rapido)
- [Struttura del progetto](#struttura-del-progetto)
- [Configurazione](#configurazione)
- [Build di produzione](#build-di-produzione)
  - [APK Android](#apk-android)
  - [Linux su NixOS](#linux-su-nixos)
  - [Web e altre piattaforme](#web-e-altre-piattaforme)
- [Test](#test)
- [Personalizzazione](#personalizzazione)
- [Risoluzione problemi](#risoluzione-problemi)

---

## Requisiti

- **Flutter SDK** 3.0+ (consigliato 3.41+)
- **Docker** (per le build isolate, consigliato)
- **Nix** con `nix profile` (solo per la build/installazione Linux)
- Browser Chrome (per il target web)

> **NixOS**: il PATH di sistema può puntare a Java 8, che non basta per
> Gradle 8.7.3 (richiede Java 11+). Per questo le build di produzione usano
> Docker, così da non dover modificare `configuration.nix`.

---

## Avvio rapido

```bash
# 1. Installa le dipendenze
flutter pub get

# 2. Configura Chrome (solo per target web)
export CHROME_EXECUTABLE=/run/current-system/sw/bin/google-chrome-stable

# 3. Avvia l'app
flutter run -d linux      # app desktop Linux
flutter run -d chrome     # app web in Chrome
```

---

## Struttura del progetto

```text
lib/
├── core/
│   ├── error/              # Gestione errori globale
│   ├── models/             # Modelli dati (freezed)
│   ├── providers/          # Provider globali (es. supabaseProvider)
│   ├── router/             # Configurazione GoRouter
│   ├── services/           # Servizi core
│   └── theme/              # Tema Material 3
├── features/               # Moduli funzionali (ogni feature è autonoma)
│   ├── auth/               # Login / registrazione (Supabase Auth)
│   ├── allenamenti/
│   ├── biblioteca/
│   ├── darts/
│   ├── girone/
│   ├── note/
│   ├── rifornimenti/
│   ├── veicoli/
│   ├── viaggi/
│   └── ...                 # altre feature
├── l10n/                   # Localizzazione (IT, EN, ES, FR)
├── shared/                 # Widget e componenti riutilizzabili
└── main.dart               # Entry point
```

Ogni feature segue la struttura `data/` (repository), `presentation/`
(pages, widgets, providers).

---

## Configurazione

### Variabili ambiente

Creare un file `.env` nella root con le credenziali Supabase:

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```

> Il file `.env` viene caricato all'avvio da `flutter_dotenv`. L'app legge
> queste variabili in `main()` per inizializzare Supabase.

### Localizzazione

```bash
flutter gen-l10n
```

### Dipendenze principali

| Categoria        | Pacchetti                                            |
|------------------|------------------------------------------------------|
| State management | `flutter_riverpod`, `riverpod_annotation`            |
| Navigazione      | `go_router`                                          |
| Backend          | `supabase_flutter`                                   |
| UI/UX            | `flutter_animate`, `flex_color_scheme`               |
| Utility          | `intl`, `shared_preferences`, `cached_network_image` |
| Sviluppo         | `freezed`, `json_serializable`, `build_runner`       |

---

## Build di produzione

Sono disponibili due script che automatizzano le build isolate in Docker
(necessari su NixOS per evitare problemi di permessi e di versione Java).

### APK Android

```bash
./build-apk.sh
```

- Usa un container Docker con **JDK 17** (richiesto da Gradle 8.7.3).
- Non richiede modifiche a `configuration.nix` né `sudo` per Java.
- Output: `build/app/outputs/flutter-apk/app-release.apk`

### Linux su NixOS

```bash
./build-linux.sh
```

- Compila nel container Docker (volume isolato per `build/`).
- Copia la build nel filesystem NixOS e la installa nel profilo Nix
  (`nix profile add path:.`).
- Output: `build/linux/x64/release/bundle/flutter_starter`
  + comando `flutter-starter` nel PATH.

> **Prerequisiti Linux**: Docker avviato. Per eseguire l'app dal container
> (non per compilarla) può servire abilitare l'accesso al display X11:
>
> ```bash
> xhost +local:
> ```

### Web e altre piattaforme

```bash
# Web
flutter build web --release

# Altre piattaforme (richiedono SDK/t toolchain dedicati)
flutter build ios --release
flutter build macos --release
flutter build windows --release
```

---

## Test

```bash
# Tutti i test
flutter test

# Con copertura
flutter test --coverage
```

> Se `build/` è di proprietà di `root` (dopo una build Docker), correggere
> i permessi prima di lanciare i test:
> `sudo chown -R vincenzo:vincenzo build/`

---

## Personalizzazione

### Tema

Modificare `lib/core/theme/app_theme.dart` per:

- Color scheme (Material 3)
- Tipografia
- Tema componenti
- Modalità chiara/scura

### Nuova feature

1. Creare una cartella in `lib/features/<nome>/`
2. Aggiungere `data/` (repository), `presentation/` (pages, widgets, providers)
3. Registrare le route in `lib/core/router/app_router.dart`

### Risoluzione problemi

**Build fallisce per permessi `build/`**

```bash
sudo chown -R vincenzo:vincenzo build/
```

**Gradle / Java non trovato (APK)**
Su NixOS il PATH può puntare a Java 8, che non basta per Gradle 8.7.3
(richiede Java 11+). Lo script `./build-apk.sh` rileva automaticamente una
JDK 17+ nel Nix store e la usa per la build, senza `sudo` e senza modificare
`configuration.nix`.

**App web non si avvia**
Verificare `CHROME_EXECUTABLE` e che `.env` contenga URL e anon key validi.

---

## Licenza

MIT — vedi [LICENSE](LICENSE).