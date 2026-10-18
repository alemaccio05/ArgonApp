# INK SLING: Daily 100m (Risograph Edition)

Gioco arcade 2D one-handed basato sulla fisica in **Bullet-Time** e su un **Seed Globale Giornaliero (`YYYYMMDD`)**, progettato in **Flutter + Flame** con direzione artistica **Stampa Tipografica / Risograph Giapponese**.

## Caratteristiche Implementate

1. **Stile Risograph / Carta Stampata Giapponese (Zero fatica visiva, 120 FPS):**
   - **3 Carte selezionabili in tempo reale:**
     - *Carta Washi (Avorio & Blu Klein)* — Default diurno ad altissima leggibilità anche sotto il sole.
     - *Carta Carbone (Sumi Antracite & Crema)* — Modalità notturna morbida senza nero assoluto né neon.
     - *Kyoto Matcha (Carta Tè Verde & Cremisi)* — Variante botanica rilassante.
   - Ombre serigrafiche nette (`Offset(3.5, 4.5)`), blocchi Matcha che si comprimono come tasti fisici al rimbalzo, barriere Vermiglio con tratteggio diagonale tipografico e sigilli tradizionali giapponesi (*Hanko* `印`).
2. **Core Loop One-Handed ("Hold, Aim in Bullet-Time, Release"):**
   - Trascina in qualsiasi punto dello schermo per rallentare il tempo (`timeScale = 0.15`) e visualizzare la traiettoria predittiva a gocce d'inchiostro (inclusi i rimbalzi sulle marginature laterali).
   - **Regola dei 2 Lanci Aerei:** Ricarica i lanci rimbalzando sulle marginature del foglio, sulle piattaforme Matcha o attraversando i sigilli Hanko dorati.
3. **Viral Hook & Daily Challenge:**
   - **Seed Giornaliero Globale (`YYYYMMDD`):** Genera una torre verticale di `100.0m` identica per tutti i giocatori del mondo ogni giorno.
   - **Sistema dei 3 Timbri Ufficiali Giornalieri** + Allenamento Libero infinito + Sblocco timbro extra o **Revive con Scudo d'Inchiostro** tramite Rewarded Ad.
   - **Biglietto di Volo & Scontrino Wordle:** A fine partita disegna la mini-mappa verticale `0–100m` con il tracciato esatto della tua scalata e genera lo scontrino emoji condivisibile con un tap (`share_plus` + Appunti).

## Struttura del Progetto (`lib/`)

```text
lib/
├── main.dart                              # Entrypoint, SystemChrome portrait, GameWidget + Overlays
├── core/
│   ├── palette_theme.dart                 # 3 Palette Risograph (Carta Washi, Carta Carbone, Kyoto Matcha)
│   └── daily_seed.dart                    # Seed YYYYMMDD, percentile e generatore scontrino Wordle
├── services/
│   ├── storage_service.dart               # Persistenza locale (Streak, Record Oggi, Timbri, Tema)
│   ├── audio_haptics_service.dart         # HapticFeedback stratificato e calcolo pitch combo
│   └── monetization_service.dart          # Gestione Rewarded Ad (Revive Scudo / +1 Timbro)
├── game/
│   ├── ink_sling_game.dart                # FlameGame: generatore torre, Bullet-Time, grana carta, shake
│   └── components/
│       ├── player_core.dart               # Goccia d'inchiostro, Squash & Stretch, scia Fude, scudo
│       ├── obstacle_block.dart            # Blocchi Matcha elastici, lame Vermiglio, sigilli Hanko
│       ├── ink_flood_wave.dart            # Marea d'inchiostro Sumi con onde Ukiyo-e dinamiche
│       └── floating_label.dart            # Timbri flottanti ("印 RICARICA!", "SCUDO!")
└── ui/
    ├── main_menu_overlay.dart             # Copertina editoriale Risograph, selettore carta e Streak
    ├── hud_overlay.dart                   # Contatore metri, barra 0-100m, cariche e cambio carta rapido
    └── game_over_overlay.dart             # Biglietto tipografico con Mini-Mappa tracciato e Share
```

## Come Avviare il Progetto

Se la cartella non contiene ancora le sottocartelle native di piattaforma (`android/`, `ios/`, `windows/`, `web/`), genera i file di piattaforma con:

```bash
flutter create .
flutter pub get
flutter run
```
