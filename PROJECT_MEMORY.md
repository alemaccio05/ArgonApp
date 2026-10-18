# PROJECT MEMORY — DAILY SLING 100m (`ArgonApp`)

> **Ultimo aggiornamento:** 18 Ottobre 2026  
> **Motore:** Flutter + Flame (`^1.14.0 <2.0.0`)  
> **Target:** Android (Google Play Store), iOS, Windows, Web

---

## 1. Visione e Game Design Consolidato

### Concept Principale
* **Titolo in-game:** **DAILY SLING** (*1 Torre al giorno • Arriva a 100 metri*)
* **Core Loop "One-Handed":**
  1. **Trascina ovunque sullo schermo (`DragCallbacks`):** attiva il *Bullet-Time* (`timeScale` scende dolcemente a `0.15`) e disegna una traiettoria predittiva di 22 punti comprensiva dei rimbalzi sulle pareti laterali.
  2. **Rilascia per saltare:** spara la sfera nella direzione opposta al trascinamento.
  3. **Piattaforme Verdi Adesive ("Sticky Pads"):** quando la palla tocca una piattaforma verde (`BlockType.matchaPad`), **si incolla e si ferma sopra di essa** (`PlayerCore.stickToPlatform`). Il giocatore può respirare e mirare con calma il salto successivo.
  4. **Sistema a 3 Lanci Ricaricabili (`maxAirCharges = 3`):** il giocatore dispone di 3 lanci per ogni salto, che **si ricaricano sempre al 100%** ogni volta che si incolla a una piattaforma verde o raccoglie una Gemma di Boost dorata (`BlockType.hankoSeal`). Toccare un muro laterale quando si è a 0 lanci restituisce 1 lancio di emergenza per non restare mai bloccati.
* **Condizioni di Sconfitta:**
  1. Toccare una barriera rossa (`BlockType.vermilionHazard`) senza avere lo Scudo attivo.
  2. Essere raggiunti dall'onda che sale dal basso (`InkFloodWave`), la quale **inizia a salire solo dopo aver superato gli 8 metri** e rallenta automaticamente quando il giocatore è fermo su una piattaforma verde.

### Viral Hook & Ritenzione Giornaliera
* **Seed Giornaliero Globale (`YYYYMMDD` in UTC):** gestito da [`DailySeedEngine`](lib/core/daily_seed.dart). Ogni giorno genera la stessa identica torre di 100 metri per tutti i giocatori del mondo.
* **3 Vite Ufficiali Giornaliere + Allenamento Libero:** gestite da [`StorageService`](lib/services/storage_service.dart). Ogni giorno il giocatore ha 3 tentativi ufficiali per stabilire il record del giorno (più modalità allenamento illimitata o sblocco di vite extra via Rewarded Ad).
* **Mini-Mappa Tracciato ("Flight Box") + Riepilogo Stile Wordle:** a fine partita [`GameOverOverlay`](lib/ui/game_over_overlay.dart) disegna su `Canvas` (`RisographFlightMapPainter`) la mappa verticale `0–100m` con la linea esatta percorsa dal giocatore e genera un riepilogo testuale a 5 settori da 20m (`🟩🟩🟩🟩🟥 84.6m / 100m`) condivisibile con 1 tap tramite `share_plus` e `Clipboard`.

---

## 2. Stile Visivo e Regole UI/UX (Decisioni Importanti)

1. **Zero Neon / Zero Affaticamento Visivo:**
   * Abbandonato lo stile neon su nero puro (che affatica la vista a lungo termine).
   * Adottata una direzione artistica **morbida, tattile e ad alto contrasto** con ombre portate nette (`Offset(3.5, 4.5)`) e zero `MaskFilter.blur` (garantendo **120 FPS fissi** anche su dispositivi Android economici).
2. **3 Temi con Transizione Fluida (`600ms` `Curves.easeInOutCubic`):**
   * Definiti in [`RisographPalette`](lib/core/palette_theme.dart):
     * **Sabbia (`washi_ivory`):** Default diurno caldo (`#F4EFE6`) con sfera Blu Klein (`#1D3557`), piattaforme verdi (`#2A9D8F`) e ostacoli rossi (`#D62828`).
     * **Notte (`sumi_charcoal`):** Antracite morbido (`#232426`) con elementi crema, salvia e corallo.
     * **Salvia (`kyoto_matcha`):** Carta verde botanico (`#E9F0E6`) con verde foresta e cremisi.
   * Il cambio tema non è mai brusco: `InkSlingGame.update` interpola frame per frame tutti i colori tramite `RisographPalette.lerp` e aggiorna contemporaneamente il mondo Flame e gli overlay Flutter tramite `paletteNotifier`.
3. **Linguaggio Pulito e Prevenzione Overflow UI:**
   * **Nessun riferimento meta-testuale** (non scrivere *"gioco tipografico/stilografico"* nei menu) e **nessun ideogramma orientale** (`印`, `百米`, ecc.).
   * **Protezione anti-overflow (`RenderFlex`):** tutte le `Row` e i pulsanti negli overlay usano `Expanded`, `Flexible`, `FittedBox(fit: BoxFit.scaleDown)` e `TextOverflow.ellipsis`.
   * **Compatibilità universale Flutter Color API:** usato `.withAlpha((opacity * 255).round())` al posto di `.withValues(alpha: ...)` o `.withOpacity(...)` per evitare errori su versioni Flutter < 3.27 e deprecation warning su Flutter >= 3.27.
   * **Attenzione a `Offset` vs `Vector2`:** su `Offset` di `dart:ui` usare sempre `.dx` e `.dy`; su `Vector2` di Flame usare `.x` e `.y`.

---

## 3. Mappa dei File del Progetto (`lib/`)

* [lib/main.dart](lib/main.dart) — Entrypoint, blocco orientamento verticale, inizializzazione servizi e `GameWidget` con `overlays` (`MainMenu`, `Hud`, `GameOver`).
* [lib/core/palette_theme.dart](lib/core/palette_theme.dart) — Definizione dei 3 temi (**Sabbia**, **Notte**, **Salvia**) e metodo statico `RisographPalette.lerp`.
* [lib/core/daily_seed.dart](lib/core/daily_seed.dart) — Calcolo seed `YYYYMMDD`, numero sfida `#`, stima percentile mondiale e generatore testo condivisibile.
* [lib/services/storage_service.dart](lib/services/storage_service.dart) — Persistenza `SharedPreferences` (record del giorno, record assoluto, serie di giorni consecutivi, vite ufficiali rimaste, tema selezionato).
* [lib/services/audio_haptics_service.dart](lib/services/audio_haptics_service.dart) — Feedback aptici (`HapticFeedback`) per mira, lancio, atterraggio su piattaforma, raccolta gemma e fine partita.
* [lib/services/monetization_service.dart](lib/services/monetization_service.dart) — Flusso Rewarded Ad per *"Continua dal metro X con Piattaforma + Scudo"* e *"+1 Vita Ufficiale"*.
* [lib/game/ink_sling_game.dart](lib/game/ink_sling_game.dart) — Classe principale `FlameGame`: generazione procedurale bilanciata della torre di 100m, gestione *Bullet-Time*, traiettoria predittiva, *Hit-Stop*, *Camera Shake* e transizione tema.
* [lib/game/components/player_core.dart](lib/game/components/player_core.dart) — Fisica del giocatore, meccanica di incollaggio `stickToPlatform`, 3 lanci aerei, *Squash & Stretch*, scia e scudo.
* [lib/game/components/obstacle_block.dart](lib/game/components/obstacle_block.dart) — Piattaforme verdi adesive (`matchaPad`), barriere rosse anche mobili (`vermilionHazard`) e gemme di boost (`hankoSeal`).
* [lib/game/components/ink_flood_wave.dart](lib/game/components/ink_flood_wave.dart) — Onda inferiore che parte dopo gli 8 metri e rallenta quando il giocatore è fermo su una piattaforma.
* [lib/game/components/floating_label.dart](lib/game/components/floating_label.dart) — Testi flottanti (`+SLANCIO!`, `SCUDO!`).
* [lib/ui/main_menu_overlay.dart](lib/ui/main_menu_overlay.dart) — Menu principale con statistiche giornaliere, selettore tema e regole.
* [lib/ui/hud_overlay.dart](lib/ui/hud_overlay.dart) — Barra superiore con metri, avanzamento `0-100m`, contatore `LANCI` e cambio tema rapido.
* [lib/ui/game_over_overlay.dart](lib/ui/game_over_overlay.dart) — Fine partita con `RisographFlightMapPainter` (mini-mappa `0-100m`), pulsante Revive con Scudo, Condividi e Riprova.

---

## 4. Parametri Fisici Chiave (Bilanciamento Attuale)

| Parametro | Valore | File | Note |
| :--- | :--- | :--- | :--- |
| `metersToPixels` | `45.0` px/m | `daily_seed.dart` | `100m` = `4500px` di altezza verticale |
| `PlayerCore.gravity` | `920.0` px/s² | `player_core.dart` | Gravità morbida e leggibile |
| `PlayerCore.maxAirCharges` | `3` | `player_core.dart` | Ricaricate a ogni piattaforma verde o gemma |
| `targetTimeScale` (Mira) | `0.15` | `ink_sling_game.dart` | Rallentamento dell'85% mentre si mira |
| Velocità Lancio | `440.0 – 900.0` | `ink_sling_game.dart` | Proporzionale alla lunghezza del drag |
| Distanza Piattaforme Verdi | `3.8m – 5.0m` | `ink_sling_game.dart` | Sempre raggiungibili con 1 singolo salto |
| Avvio Onda dal Basso | `>= 8.0m` | `ink_flood_wave.dart` | Primi 8 metri senza pressione temporale |
| Velocità Onda | `32.0` (fermo) / `48.0` (in volo) | `ink_flood_wave.dart` | Rallenta mentre il giocatore mira dalla piattaforma |

---

## 5. Prossimi Passi Consigliati (Roadmap per il Play Store)

1. **Audio Reattivo (`flutter_soloud` o `flame_audio`):** collegare i metodi già predisposti in `AudioHapticsService` a 4 campioni sonori morbidi/tattili (marimba/legno per l'incollaggio sulla piattaforma, corda pizzicata per il lancio, cristallo con pitch crescente `audioHaptics.currentPitch` per le gemme).
2. **Esportazione Immagine PNG per Instagram/TikTok Stories:** avvolgere la card del tracciato in `GameOverOverlay` con un `RepaintBoundary` per condividere anche lo screenshot grafico della mini-mappa oltre al testo.
3. **Integrazione SDK Produzione:** inserire l'App ID reale di AdMob in `AndroidManifest.xml` e collegare `games_services` per la classifica giornaliera Google Play Games.
