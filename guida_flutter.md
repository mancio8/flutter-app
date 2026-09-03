# Guida: come procedere per creare un'app Flutter

Questa guida riassume il flusso di lavoro corretto per costruire un'app Flutter da zero, basandosi sulla struttura che stai già usando nel tuo progetto (biblioteca, rifornimenti, ecc.).

---

## 1. Setup iniziale

### Installare Flutter
1. Scarica Flutter SDK da [flutter.dev](https://flutter.dev)
2. Aggiungilo al PATH del sistema
3. Verifica l'installazione:
   ```bash
   flutter doctor
   ```
   Risolvi tutti i problemi segnalati (Android SDK, licenze, editor, ecc.) prima di andare avanti.

### Creare un nuovo progetto
```bash
flutter create nome_app
cd nome_app
flutter run
```

### Editor consigliato
- **VS Code** con estensioni Flutter e Dart
- oppure **Android Studio** con plugin Flutter

---

## 2. Architettura del progetto

Il progetto che stai costruendo segue già una struttura pulita e scalabile. Consiglio di mantenerla per ogni nuova funzionalità:

```
lib/
├── core/
│   └── models/          # Classi dati (Libro, Rifornimento, Veicolo...)
├── features/
│   ├── biblioteca/
│   │   ├── data/
│   │   │   └── repository/    # Accesso ai dati (storage, API)
│   │   ├── providers/         # Stato con Riverpod
│   │   └── presentation/
│   │       ├── pages/         # Schermate
│   │       └── widgets/       # Componenti riutilizzabili
│   └── rifornimenti/
│       └── ... (stessa struttura)
└── main.dart
```

**Perché conviene:** ogni funzionalità (feature) è isolata. Se domani aggiungi "manutenzioni" o "spese", copi la stessa struttura senza toccare il resto dell'app.

---

## 3. Le librerie principali che stai usando

| Package | A cosa serve |
|---|---|
| `flutter_riverpod` | Gestione dello stato (dati che cambiano e aggiornano l'interfaccia) |
| `shared_preferences` | Salvataggio dati semplice sul dispositivo (chiave-valore) |
| `path_provider` | Trovare le cartelle di sistema (documenti, cache...) |
| `share_plus` | Condividere file con altre app |
| `file_picker` | Selezionare file dal dispositivo (per l'import) |

Aggiungi un package con:
```bash
flutter pub add nome_pacchetto
```

---

## 4. Flusso di lavoro per ogni nuova funzionalità

Segui sempre questo ordine, è quello che abbiamo usato per "biblioteca" e "rifornimenti":

### Passo 1 — Modello dati
Definisci la classe che rappresenta l'oggetto (es. `Libro`, `Rifornimento`):
- Campi (`final String id`, ecc.)
- `toJson()` / `fromJson()` per salvare e leggere
- `copyWith()` per creare copie modificate

### Passo 2 — Repository
Classe che si occupa di **salvare e recuperare i dati** (da `SharedPreferences`, database, o API):
- `getX()` — legge tutti gli elementi
- `addX()` — aggiunge un elemento
- `updateX()` — modifica un elemento
- `deleteX()` — elimina un elemento

### Passo 3 — Provider (stato)
Con Riverpod, crei un `Notifier` che espone i dati alla UI e permette di modificarli reagendo automaticamente:
```dart
final xProvider = AsyncNotifierProvider<XNotifier, List<X>>(() {
  return XNotifier();
});
```

### Passo 4 — Interfaccia (UI)
- **Pagina** (`XPage`): la schermata principale, con lista/griglia dei dati
- **Widget** (`XCard`): come viene mostrato il singolo elemento
- **Dialog**: form per aggiungere/modificare

### Passo 5 — Funzionalità aggiuntive
Solo dopo che le basi (CRUD: create, read, update, delete) funzionano, aggiungi:
- Export JSON
- Import JSON
- Statistiche, filtri, ordinamento

---

## 5. Buone pratiche da seguire

- **Un file, una responsabilità**: non mettere tutto in un unico file enorme.
- **Naming coerente**: se il modello si chiama `Rifornimento`, il repository sarà `RifornimentiRepository`, il provider `rifornimentiProvider`, ecc.
- **Gestisci sempre gli stati di caricamento/errore** nella UI (`.when(loading: ..., error: ..., data: ...)`), come già fai.
- **Controlla `context.mounted`** prima di usare `context` dopo un'operazione asincrona (es. dopo `await`), per evitare crash.
- **Evita dialog bloccanti attorno a operazioni che aprono altre finestre native** (es. condivisione file) — può causare schermate nere, come abbiamo visto con l'export dei rifornimenti.
- **Versiona il progetto con Git** fin da subito:
  ```bash
  git init
  git add .
  git commit -m "Setup iniziale progetto"
  ```

---

## 6. Test e debug

- `flutter run` — avvia l'app in modalità debug (hot reload con `r`, hot restart con `R`)
- `flutter analyze` — controlla errori statici nel codice
- `flutter test` — esegue eventuali test automatici
- Per vedere log dettagliati: `flutter logs`

---

## 7. Quando l'app è pronta per essere distribuita

```bash
flutter build apk --release       # Android
flutter build ios --release       # iOS (richiede Mac)
```

Prima della pubblicazione:
- Aggiorna `pubspec.yaml` con nome, versione, icona dell'app
- Testa su dispositivo fisico, non solo emulatore
- Verifica i permessi richiesti (storage, condivisione file, ecc.)

---

## 8. Risorse utili

- Documentazione ufficiale: https://docs.flutter.dev
- Pacchetti: https://pub.dev
- Riverpod: https://riverpod.dev

---

*Guida creata come riferimento per il progetto in corso (gestione biblioteca, rifornimenti, ecc.)*
