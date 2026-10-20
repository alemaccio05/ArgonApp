# PROJECT MEMORY — INK TOWER: Climb & Stick (`ArgonApp`)

> **Ultimo aggiornamento:** 20 Ottobre 2026  
> **Nome Ufficiale In-Game:** **INK TOWER: Climb & Stick** (Package: `ink_sling_daily`)  
> **Motore:** Flutter 3.44.x + Flame (`>=1.14.0 <2.0.0`) • Dart 3.12.x  
> **Toolchain Android:** Android Gradle Plugin 9.0.1 (Built-in Kotlin nativo, Gradle Kotlin DSL `.kts`)  
> **Target:** Android (Google Play Store), iOS, Windows, Web  

---

## 1. Visione, Concept & Game Design Consolidato

### Concept Principale & Identità
* **Titolo in-game:** **INK TOWER: Climb & Stick**
* **Stile Visivo:** Stampa serigrafica Risograph / Carta Giapponese a colori morbidi e ad altissimo contrasto visivo (zero affaticamento visivo, zero neon, ombre portate nette a 120 FPS fissi anche su telefoni economici).
* **Core Loop "One-Handed" (Mira in Bullet-Time):**
  1. **Trascina ovunque sullo schermo (`DragCallbacks`):** Attiva il *Bullet-Time* (`timeScale` scende morbidamente a `0.15`) e proietta una traiettoria predittiva a 22 punti calcolata con precisione millimetrica includendo i rimbalzi fisici sulle pareti laterali della torre.
  2. **Rilascia per saltare:** Spara la sfera d'inchiostro nella direzione opposta al trascinamento con potenza regolabile (440–900 px/s).
  3. **Piattaforme Verdi Adesive ("Sticky Pads"):** Quando la sfera impatta una piattaforma verde (`BlockType.matchaPad`), **si incolla istantaneamente e si ferma** (`PlayerCore.stickToPlatform`). Il giocatore può riprendere fiato, studiare il percorso e mirare con calma il salto successivo.
  4. **Sistema a 3 Lanci Ricaricabili (`maxAirCharges = 3`):** Il giocatore ha a disposizione 3 lanci per ogni sequenza in volo. I lanci **si ricaricano al 100%** ogni volta che si incolla a una piattaforma verde o raccoglie un Sigillo di Boost dorato (`BlockType.hankoSeal`). Se si esauriscono i lanci a mezz'aria, toccare una parete laterale restituisce 1 lancio di emergenza per non restare mai bloccati.
* **Condizioni di Sconfitta:**
  1. Impatto contro una barriera vermiglio (`vermilionHazard`, `verticalPatrolHazard`, `pulsingLaserHazard`) senza avere lo Scudo d'Inchiostro attivo.
  2. Raggiungimento da parte dell'Onda d'Inchiostro (`InkFloodWave`) che sale dal basso. L'onda parte solo dopo aver superato gli 8 metri e rallenta automaticamente quando il giocatore è fermo su una piattaforma verde a mirare.

---

## 2. Le Due Modalità di Gioco (`GameMode`)

L'app adotta un'architettura a doppio canale che massimizza sia la ritenzione quotidiana stile Wordle sia la progressione a lungo termine:

### 1) Progressione Livelli Infiniti (`GameMode.levelProgression`)
* **Livelli 1, 2, 3... Infiniti:** Ogni livello ha una torre procedurale generata in modo **100% deterministico** tramite `DailySeedEngine.getLevelSeed(level)`, garantendo che il Livello N sia identico per ogni giocatore su qualsiasi dispositivo.
* **Altezza Traguardo Crescente (+10m ogni 10 livelli):**
  * Livelli 1–10: **50.0m**
  * Livelli 11–20: **60.0m**
  * Livelli 21–30: **70.0m**
  * Livelli 31–40: **80.0m** (fino a 300m)
* **Curva di Introduzione degli Ostacoli:**
  * *Liv. 1:* Barriere rosse fisse e piattaforme verdi ampie.
  * *Liv. 2:* Sblocco dei **Respingenti Pinball (`bumperPin`)** e barriere mobili orizzontali.
  * *Liv. 3:* Sblocco delle **Piattaforme verdi friabili a tempo (`crumblingPad`)**.
  * *Liv. 4:* Sblocco delle **Piattaforme verdi mobili orizzontali (`movingPad`)**.
  * *Liv. 5:* Sblocco delle **Lame vermiglio a pattuglia verticale (`verticalPatrolHazard`)**.
  * *Liv. 6:* Sblocco dei **Varchi Laser a impulsi periodici (`pulsingLaserHazard`)**.
  * *Liv. 7–10+:* Combinazioni dense e ritmiche di tutti gli ostacoli con velocità incrementali.

### 2) Torre di Oggi / Sfida Giornaliera (`GameMode.dailyTower`)
* **Seed Globale `YYYYMMDD` (in UTC):** Genera la stessa identica torre di **100.0m** per tutti i giocatori del mondo.
* **3 Vite Ufficiali Giornaliere + Allenamento Illimitato:** 3 tentativi ufficiali per scalare la classifica del giorno. Una volta esauriti, il giocatore può continuare ad allenarsi all'infinito o riscattare +1 vita extra tramite Rewarded Ad.
* **Riepilogo Stile Wordle + Mini-Mappa del Volo:**
  * Disegna su `Canvas` (`RisographFlightMapPainter`) il tracciato reale percorso dalla sfera `0–100m` con gli hotspot di caduta della community.
  * Genera lo scontrino testuale con emoji a 5 settori (`🟩🟩🟩🟩🟥 84.6m / 100m (Top 3%)`), condivisibile con 1 tap tramite `share_plus` (`SharePlus.instance.share`).

---

## 3. Tipi di Blocchi ed Elementi Interattivi

| Tipo Blocco | Enum / Classe | Comportamento Visivo e Fisico |
| :--- | :--- | :--- |
| **Piattaforma Verde** | `BlockType.matchaPad` | Piattaforma adesiva elastica; la palla si incolla e ricarica i lanci a 3. |
| **Piattaforma Friabile** | `BlockType.crumblingPad` | Piattaforma adesiva a tempo; trema e collassa 1 secondo dopo l'impatto. |
| **Piattaforma Mobile** | `BlockType.movingPad` | Piattaforma verde adesiva che oscilla orizzontalmente in modo sinusoidale. |
| **Respingente Pinball** | `BlockType.bumperPin` | Perno circolare elastico; respinge la sfera con forte spinta cinetica e feedback percussivo. |
| **Barriera Vermiglio** | `BlockType.vermilionHazard` | Barriera rossa letale con tratteggio serigrafico; statica o mobile orizzontale. |
| **Pattuglia Verticale** | `BlockType.verticalPatrolHazard` | Lama vermiglio che pattuglia verticalmente un corridoio della torre. |
| **Varco Laser** | `BlockType.pulsingLaserHazard` | Raggio laser pulsante che si accende e si spegne a intervalli ciclici di 1.6 secondi. |
| **Sigillo Hanko** | `BlockType.hankoSeal` | Sigillo dorato; conferisce spinta verso l'alto, ricarica i 3 lanci e aumenta la combo pentatonica. |
| **Marea d'Inchiostro** | `InkFloodWave` | Onda inferiore che sale dopo gli 8m; rallenta quando il giocatore mira dalla piattaforma. |

---

## 4. Audio Procedurale e Localizzazione

### Sintetizzatore Audio Nativo (`NativeSoundSynth` + `SoundPool` Android)
* Nessuna dipendenza da asset audio esterni o file pesanti: l'audio è **sintetizzato a runtime a 44.1kHz PCM/WAV** a latenza ultra-bassa tramite `sound_synth_io.dart` (con fallback su `sound_synth_stub.dart` su web).
* **Architettura Audio Multipiattaforma:**
  * **Android (`MainActivity.kt` + `sound_synth_io.dart`):** I buffer WAV generati in memoria vengono caricati nel `SoundPool` nativo Android (`AudioAttributes.USAGE_MEDIA` + `CONTENT_TYPE_MUSIC`, 12 stream polifonici simultanei e `volumeControlStream = AudioManager.STREAM_MUSIC`) tramite il `MethodChannel('com.example.ink_sling_daily/audio')` con I/O asincrono su background thread.
  * **Windows (`sound_synth_io.dart`):** Riproduzione diretta in memoria nativa tramite `winmm.dll` (`PlaySoundW`).
* Include sound design procedurale con armoniche ottimizzate anche per speaker di smartphone per:
  * Tick tattile di mira
  * Spinta di lancio elastica
  * Incollaggio su piattaforma (con pitch pentatonico crescente in base alla combo)
  * Rimbalzo su muro e piattaforme
  * Respingente Pinball (tono percussivo/marimba)
  * Raccolta Sigillo Hanko (cristallo armonico a frequenze pentatoniche)
  * Rottura dello Scudo
  * Crash e Fanfara di Vittoria
* Toggle rapido ON/OFF dell'audio nel menu principale con persistenza su `SharedPreferences`.

### Sistema Multilingua Integrato (`AppStrings`)
* **6 Lingue Supportate:** Italiano (`it`), Inglese (`en`), Spagnolo (`es`), Francese (`fr`), Tedesco (`de`), Portoghese (`pt`).
* **Rilevamento Automatico:** Al primo avvio legge la lingua di sistema del dispositivo (`PlatformDispatcher.instance.locale`).
* **Selettore Manuale:** Dialog con cambio lingua istantaneo e reattivo accessibile tramite l'icona globo nel menu principale.
* **Etichette Tab Pulite:** Le tab del menu principale mostrano nomi essenziali e puliti (`SCALATA LIVELLI` senza `(1, 2, 3...)` e `TORRE DI OGGI` senza il tag `#giorno`).

---

## 5. Mappa dei File del Progetto (`lib/`)

```text
lib/
├── main.dart                              # Entrypoint, blocco orientamento verticale, MaterialApp, GameWidget e Overlays
├── core/
│   ├── app_strings.dart                   # Sistema multilingua (6 lingue: IT, EN, ES, FR, DE, PT) e tutte le stringhe UI
│   ├── daily_seed.dart                    # Seed deterministico per Livelli (1..N) e Giornaliero (YYYYMMDD), classifiche dinamiche e scontrino share
│   └── palette_theme.dart                 # 3 Temi Risograph (Sabbia, Notte, Salvia) e RisographPalette.lerp fluido
├── services/
│   ├── storage_service.dart               # Persistenza SharedPreferences (livello corrente, partite giocate, record metri/rimbalzi, vite, nome, lingua, audio, palette)
│   ├── audio_haptics_service.dart         # Bridge per feedback aptici e gestione eventi sonori con controllo ON/OFF
│   ├── sound_synth_io.dart                # Sintetizzatore PCM/WAV 44.1kHz procedurale nativo (SoundPool Android + winmm Windows)
│   ├── sound_synth_stub.dart              # Stub del sintetizzatore audio per ambienti non-I/O (Web)
│   └── monetization_service.dart          # Gestione flussi Rewarded Ad (Revive Scudo / +1 Vita Giornaliera)
├── game/
│   ├── ink_sling_game.dart                # FlameGame principale: loop di gioco, Bullet-Time, Ink Stamps permanenti, demo menu cinematica
│   └── components/
│       ├── player_core.dart               # Sfera d'inchiostro: fisica, stickToPlatform, cariche aeree, scia, squash & stretch, scudo
│       ├── obstacle_block.dart            # Tutti i tipi di blocchi (matcha, crumbling, moving, bumper, hazard, vertical, laser, hanko)
│       ├── ink_flood_wave.dart            # Onda d'inchiostro inferiore con salita adattiva
│       └── floating_label.dart            # Etichette animate a scomparsa (+SLANCIO!, SCUDO!)
└── ui/
    ├── main_menu_overlay.dart             # Menu principale con demo animata in background, selettore modalità/livello, classifiche, lingua, audio
    ├── hud_overlay.dart                   # Barra superiore in-game: metri attuali/traguardo, cariche rimaste, combo, cambio palette
    └── game_over_overlay.dart             # Overlay fine partita: mini-mappa 0-100m Canvas, riepilogo scontrino, share_plus, revive e riprova
```

---

## 6. Stile Visivo, Classifiche e Regole UI/UX

1. **Direzione Artistica Risograph Serigrafica:**
   * Palette ad alto contrasto, morbide per gli occhi, con ombre portate nette (`Offset(3.5, 4.5)`). Zero `MaskFilter.blur` per garantire **120 FPS granitici**.
   * **3 Temi con Transizione Fluida (600ms `Curves.easeInOutCubic`):**
     * **Sabbia (`washi_ivory`):** Default caldo (`#F4EFE6`) con sfera Blu Klein (`#1D3557`), piattaforme verdi (`#2A9D8F`) e ostacoli rossi (`#D62828`).
     * **Notte (`sumi_charcoal`):** Antracite morbido (`#232426`) con elementi crema, salvia e corallo.
     * **Salvia (`kyoto_matcha`):** Carta botanica verde rilassante (`#E9F0E6`) con verde foresta e cremisi.
2. **Macchie d'Inchiostro Permanenti sulla Torre ("Ink Stamps"):**
   * Ogni rimbalzo contro le mura laterali, atterraggio/rimbalzo sulle piattaforme verdi o impatto coi respingenti Pinball imprime sulla carta della torre una macchia d'inchiostro permanente (`InkStamp`) con micro-gocce satelliti orientate in modo deterministico, donando un senso tangibile di conquista visiva della parete durante la scalata.
3. **Menu Demo Background Cinematica Senza Loop & "Zona Franca" Seconda Chance (`reviveWithShield`):**
   * Durante la permanenza nel menu principale, la sfera dimostrativa calcola una parabola balistica esatta verso il centro superiore della piattaforma successiva e le piattaforme agiscono come *one-way* dal basso, garantendo una scalata fluida, continua e priva di loop.
   * Quando il giocatore usa la Seconda Chance (`reviveWithShield`), il gioco bonifica automaticamente il corridoio attorno al punto di rinascita rimuovendo tutte le trappole e i bumper vicini (`[reviveY - 185, reviveY + 115]`) e le piattaforme troppo ravvicinate (`[reviveY - 110, reviveY + 90]`), evitando qualsiasi incastro di rimbalzi o impatto immediato contro ostacoli.
4. **Classifiche Competitive Realistiche (`DailySeedEngine`):**
   * **Rimbalzi Fisicamente Coerenti (`computeRealisticRivalBounces`):** Il numero di rimbalzi degli sfidanti è calcolato in proporzione diretta ai metri effettivamente scalati e alla difficoltà della torre (~0.56–0.76 rimbalzi per metro, es. 55–68 rimbalzi per 90m), rendendoli realistici e leggermente meno efficienti del giocatore.
   * **Classifica Torre di Oggi (Rotazione 24h & Difficoltà Progressiva):** I partecipanti ruotano ogni 24 ore (`getTodaySeed()`) con altezze battibili (`15m–79m`), mentre in partita la Torre di Oggi (100m) scala gradualmente la propria difficoltà dal Livello 1 nei primi metri fino al Livello 7 in vetta.
   * **Classifica Scalata Livelli (Progressione Naturale Bot & Possibilità Reale di 1° Posto #1):** Gli sfidanti ruotano ogni 7 giorni (`getWeeklySeed()`) e partono da livelli realistici (`Liv. 1..12`). I bot avanzano in base alle partite complessive giocate dal giocatore (`totalLevelsPlayed`, sia vinte che perse), con una cadenza naturale di 1 livello ogni 4..8 partite (circa 1-2 livelli, massimo 3, ogni 10 partite). È stato completamente eliminato qualsiasi rubber-banding forzato: quando il giocatore supera i bot della torre, **conquista stabilmente il 1° posto (`#1 🥇`)**!
   * **Conservazione Vite per Scalata Classifica:** Il completamento della torre (100m) con la 1ª o 2ª vita NON azzera le vite ufficiali rimaste, consentendo al giocatore di tentare nuove scalate per ottimizzare i rimbalzi e raggiungere il 1° posto (#1).
5. **Sistema Profilo Giocatore & Avatar (`ProfileDialog`, `ProfileIconsCatalog`):**
   * **Card Profilo & Dialog Risograph:** Accessibile con 1 tap dal menu principale. Include modifica inline del nickname, visualizzazione del titolo onorifico dinamico (`getPlayerHonorTitle`) e 3 tab tematiche:
     * *Tab 1 (Statistiche):* Rimbalzi totali, streak giorni, # volte 1° nei livelli, # volte 1° nella torre giornaliera, piazzamenti top 3, torri giornaliere completate, livello massimo e metri totali.
     * *Tab 2 (Icone Profilo):* Griglia di 12 avatar collezionabili con condizioni di sblocco (livello, piazzamenti giornalieri, traguardi rimbalzi).
     * *Tab 3 (Skin Sfera):* Selettore rapido con stato e collegamento allo Studio Animato.
6. **Sistema Skin Sfera & Personalizzazione (`BallSkinsCatalog`, `BallSkinsDialog`):**
   * **10 Skin Sbloccabili Tematiche:**
     1. *Inchiostro Classico* (Default)
     2. *Matcha Zen* (Livello 3)
     3. *Stella Shinobi* (Livello 8)
     4. *Origami di Carta* (Livello 15)
     5. *Braci del Drago* (Livello 25)
     6. *Vuoto Celeste* (Livello 35)
     7. *Bronzo Quotidiano* (Top 3 Giornaliera 1x)
     8. *Argento Quotidiano* (Top 3 Giornaliera 3x)
     9. *Oro Quotidiano* (1° Posto Giornaliero 1x)
     10. *Fulmine Risograph* (750 rimbalzi totali)
   * **Studio Animato (`BallSkinsDialog`):** Anteprima interattiva della sfera con fisica di squash & stretch, riflessi concentrici, rotazione e indicatore di avanzamento requisiti.
   * **Rendering di Gioco Dinamico (`PlayerCore`):** Il componente della sfera di gioco renderizza in tempo reale i colori del nucleo, del bordo, della scia fluida e gli stemmi procedurali propri della skin equipaggiata.
7. **Adattamento Geometrico Dinamico (`towerHalfWidth`) & Regole Anti-Overflow:**
   * La larghezza interna delle mura si adatta dinamicamente allo schermo (`min(worldWidth / 2, max(100.0, (size.x / 2) - 16.0))`).
   * Tutti i bottoni ed elementi orizzontali usano `Expanded`, `Flexible`, `FittedBox(fit: BoxFit.scaleDown)` e `TextOverflow.ellipsis`, con `.withAlpha((opacity * 255).round())` per la gestione dell'opacità.

---

## 7. Stato Build System, Dipendenze & Risoluzione Avvio APK Standalone

* **Risoluzione Blocco Avvio / Schermo Nero / Loop su Build APK:**
  * **Disabilitazione Impeller su Android (`EnableImpeller = false`):** Nel manifest Android è stato forzato il motore di rendering Skia OpenGL ES per scongiurare schermate nere e blocchi dello swapchain Vulkan tipici di Impeller su GPU Mali/Adreno in Flutter 3.44.
  * **Rimozione `android:taskAffinity=""` e Blocco Orientamento Manifest:** Rimossa l'anomalia `android:taskAffinity=""` sul launcher Android (causa di loop di riavvio activity dal launcher del telefono) e aggiunto `android:screenOrientation="portrait"` direttamente nell'activity.
  * **Avvio Resiliente & Non-Bloccante (`main.dart`):** `runApp` viene eseguito immediatamente; `storage.init()` è protetto con timeout/try-catch e `SystemChrome` viene applicato senza bloccare il primo frame di rendering del motore Flutter.
  * **Audio Nativo Android Sicuro (`SoundPool` Nativo):** Rimossa la dipendenza dall'isolate FFI AAudio (`libaaudio.so`), lasciando la gestione audio interamente al `SoundPool` nativo di `MainActivity.kt` con caricamento WAV asincrono su thread in background per non bloccare mai l'UI thread.
  * **Correzione Widget ParentData (`Flexible` nidificato):** Rimosso il `Flexible` superfluo all'interno di `OutlinedButton.icon` ed `ElevatedButton.icon` che causava asserzioni fatali sul frame iniziale dell'overlay.
  * **Configurazione Gradle Release Pulita:** Disabilitata minificazione aggressiva R8 non necessaria (`isMinifyEnabled = false`, `isShrinkResources = false`) in `build.gradle.kts`.
* **Compatibilità Android Gradle Plugin 9.0+ & Built-in Kotlin:**
  * Risolto l'avviso di obsolescenza KGP (Kotlin Gradle Plugin) di Flutter 3.44+.
  * Dipendenza `share_plus` aggiornata a `^13.3.1` (`SharePlus.instance.share(ShareParams(text: receiptText))`).
  * Verificata compilazione pulita con `flutter analyze` e `flutter test`: **0 errori e tutti i test superati**.

---

## 8. Icona App, UI Concept & Roadmap Pubblicazione Play Store

* **Icona Ufficiale Applicata (Concept A — "La Sfera & Il Sigillo"):** Ritagliata a pieno formato (*full-bleed*, senza margini vuoti esterni né cornice nera attorno) e applicata su Android (`mipmap-mdpi` .. `mipmap-xxxhdpi`), Windows (`windows/runner/resources/app_icon.ico`) e Web (`web/icons/`).
* **Direzione Futura Menu Principale (Menu Concept B — "Griglia Bento Risograph"):** Tenuto come riferimento progettuale per l'evoluzione dell'interfaccia del menu principale (layout modulare a tessere Bento con barra progresso livello, box Rank, Torre di Oggi e selettore rapido temi Sabbia/Notte/Salvia).
* **Esportazione Immagine Grafica (PNG/Story):** Avvolgere la card della mini-mappa in `GameOverOverlay` con un `RepaintBoundary` per consentire la condivisione dello screenshot grafico della card per Instagram e TikTok Stories oltre al testo.
* **Classifiche Cloud Google Play Games:** Collegare `games_services` per sincronizzare la classifica con Google Play Giochi / Game Center.
* **AdMob ID Produzione:** Inserire gli ID reali dei blocchi pubblicitari Rewarded in `monetization_service.dart` e nel manifest Android.
