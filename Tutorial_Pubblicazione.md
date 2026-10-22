# Pubblicare su Google Play un gioco Flutter offline con classifiche simulate

Guida pratica e prudente, scritta per un gioco **2D di svago, giocabile offline**, con livelli a torre (progressivi e giornaliero), classifiche contro **bot**, skin e icone profilo sbloccabili giocando, annunci e acquisti in-app. Account sviluppatore **personale**.

> **Ultima verifica dei requisiti: ottobre 2026.**
> Requisiti, nomi dei menu e moduli della Play Console cambiano spesso. Questa guida non sostituisce la documentazione ufficiale. Prima di ogni passaggio importante controlla queste pagine (cercale per nome):
> * Guida Play Console: "Requisiti di test per i nuovi account sviluppatore personali"
> * Guida Play Console: "Sicurezza dei dati" e "Pubblico di destinazione e contenuti"
> * Guida Play Console: requisito sul livello API di destinazione ("target API level")
> * Documentazione Flutter: "Build and release an Android app"
> * Documentazione Google Mobile Ads per Flutter e norme AdMob

---

## 0. Panoramica e tempi realistici

| Fase | Tempo indicativo |
| --- | --- |
| Registrazione account e verifica identità | da pochi giorni a oltre una settimana |
| Preparazione app, asset, privacy policy | 1-3 giorni |
| Compilazione Play Console | 1-2 ore |
| Revisione iniziale del test chiuso | da poche ore a qualche giorno |
| **Test chiuso obbligatorio** | **minimo 14 giorni continuativi** |
| Richiesta accesso alla produzione + revisione | alcuni giorni lavorativi |

**Conta circa 3-5 settimane dal primo caricamento alla pubblicazione**, se tutto va bene.

---

## 1. La regola del test chiuso: ti riguarda?

Google richiede un **test chiuso con almeno 12 tester iscritti ininterrottamente per 14 giorni** prima di concedere l'accesso alla produzione, ma **solo per gli account sviluppatore personali creati dopo il 13 novembre 2023**.

* Account personale creato **dopo** il 13/11/2023: **regola obbligatoria**.
* Account personale creato **prima**: non soggetto alla regola.
* Account **organizzazione**: non soggetto alla regola, ma richiede la verifica dell'organizzazione (documenti aziendali, numero D-U-N-S), che può richiedere più tempo del test stesso.

Il requisito era inizialmente di 20 tester ed è stato ridotto a 12 nel dicembre 2024. Si applica **per ogni nuova app** finché l'account non ha ottenuto l'accesso alla produzione.

---

## 2. Cosa preparare prima di aprire la Play Console

### 2.1 Account sviluppatore
* Registrazione una tantum (25 $) e **verifica dell'identità** con documento. Per gli account personali può essere richiesta anche la **verifica di un dispositivo Android reale** tramite l'app Play Console per mobile.
* Completa la verifica **prima** di preparare il resto: è il passaggio che più spesso si blocca.

### 2.2 Application ID definitivo
In `android/app/build.gradle` (o `build.gradle.kts`) controlla `applicationId`:

* deve essere unico, ad esempio `com.tuonome.nomegioco`;
* **non** deve contenere `com.example`.

> ⚠️ **Irreversibile.** Dopo il primo caricamento di un `.aab`, l'`applicationId` di quell'app non si può più cambiare. Se lo sbagli devi creare una nuova app e rifare anche il test chiuso da 14 giorni.

### 2.3 Chiave di upload e firma
Genera la keystore una sola volta:

```
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Crea `android/key.properties` (fuori dal controllo di versione) con `storePassword`, `keyPassword`, `keyAlias`, `storeFile`, e configura la firma release in `build.gradle`. Segui la guida ufficiale Flutter per la sintassi aggiornata.

> ⚠️ **Backup immediato.** Salva `upload-keystore.jks`, password e alias in almeno due posti sicuri e separati. Con **Play App Signing** attivo puoi chiedere a Google il reset della chiave di upload se la perdi, ma la procedura è lenta. Non pubblicare mai keystore e password su repository pubblici.

### 2.4 Pacchetto `.aab`
Google Play accetta solo **Android App Bundle**:

```
flutter build appbundle --release
```

Il file è in `build/app/outputs/bundle/release/app-release.aab`.

Prima di caricarlo controlla:
* che il `targetSdkVersion` soddisfi il **livello API minimo richiesto da Google** per le nuove app (cambia ogni anno);
* che `versionCode` (il numero dopo il `+` in `pubspec.yaml`, es. `1.0.0+1`) sia **maggiore** di quello di ogni `.aab` già caricato;
* di aver testato la build **release** (non solo debug) su un dispositivo reale, **sia con connessione sia in modalità aereo**.

### 2.5 Asset grafici
* **Icona:** 512 x 512 px, PNG a 32 bit, max 1 MB.
* **Immagine in primo piano (Feature Graphic):** 1024 x 500 px, PNG o JPEG.
* **Screenshot del telefono:** da 2 a 8, formato 16:9 o 9:16, lato minimo 320 px e massimo 3840 px.

Per il tuo gioco, lo stile **inchiostro su carta** è un punto di forza: usalo per screenshot coerenti e riconoscibili. Mostra schermate reali del gioco, non illustrazioni che promettono funzioni che non esistono.

### 2.6 Privacy Policy
Un **URL pubblico e funzionante** (puoi ospitarlo su GitHub Pages, Notion pubblico o Google Sites). È obbligatoria perché usi SDK pubblicitari e di acquisto.

Per il tuo gioco la Privacy Policy deve dire, in modo onesto e specifico:
* che il gioco funziona **offline**, non richiede **account** e salva i progressi **sul dispositivo**;
* che le **classifiche usano giocatori simulati (bot)** e non dati di altri utenti;
* che gli **SDK pubblicitari** (AdMob e le reti di mediazione che userai) possono trattare ID pubblicità, indirizzo IP, informazioni sul dispositivo e interazioni con gli annunci, secondo le loro informative, con link alle informative stesse;
* che, se usi **RevenueCat** o **Google Play Billing**, vengono trattati dati sugli acquisti;
* come gestire il **consenso** degli utenti europei;
* come contattarti.

> ⚠️ **Non scrivere "non raccogliamo alcun dato"** (né nella Privacy Policy né nella scheda dello store) se usi annunci: sarebbe falso a causa degli SDK. Scrivi invece che il gioco **non richiede un account e non invia dati a un server dello sviluppatore**, e che gli annunci possono trattare dati come descritto sopra. Evita modelli generici copiati da altri giochi: devono corrispondere a ciò che l'app fa davvero.

---

## 3. Creare l'app e compilare la scheda dello store

1. Nella Play Console clicca **Crea app**.
2. Imposta nome, lingua predefinita, tipo **Gioco** e **Gratuita**.
3. Spunta le dichiarazioni richieste e conferma.

> ℹ️ **Gratuita o a pagamento è una scelta definitiva.** Un'app gratuita può avere annunci e acquisti in-app, ma non potrà mai diventare a pagamento.

4. Nella **scheda principale dello store** inserisci:
   * titolo;
   * descrizione breve (max 80 caratteri);
   * descrizione completa (max 4000 caratteri);
   * icona, immagine in primo piano e screenshot.
5. Salva.

**Cosa scrivere nella descrizione (e cosa evitare):**
* Puoi dire che il gioco è **giocabile offline** e **senza account**.
* Descrivi le classifiche come **sfide contro rivali simulati**, non come "classifica mondiale" o "gioca contro altri giocatori": sarebbe ingannevole.
* Se menzioni gli acquisti, dillo in modo chiaro ("contiene annunci e acquisti in-app").
* Niente parole chiave ripetute, niente riferimenti ad altri giochi o marchi.

**Verifica:** nella dashboard le voci relative alla scheda dello store risultano completate.

---

## 4. Compilare "Contenuti dell'app"

Nel menu laterale cerca **Contenuti dell'app** (in genere sotto "Regole e programmi" o "Criteri e programmi") e completa **ogni voce** nella scheda *Da completare*. Per il tuo gioco:

* **Norme sulla privacy:** incolla l'URL della Privacy Policy.
* **Accesso all'app:** dichiara che tutto il gioco è accessibile **senza login**.
* **Annunci:** seleziona "Sì, la mia app contiene annunci".
* **Classificazione dei contenuti (IARC):** rispondi con onestà. Un gioco di svago senza violenza o contenuti sensibili ottiene di solito una classificazione bassa. Dichiara correttamente gli **acquisti in-app** e gli **annunci**.
* **Pubblico di destinazione:**
  * Se il gioco non è pensato per bambini, seleziona le fasce **13+** (o più alte).
  * Dichiarare 13+ **non basta** se il gioco attira di fatto i più piccoli (grafica, personaggi, tono). Lo stile a inchiostro su carta non è infantile di per sé, ma controlla personaggi, testi e skin: se risultano rivolti ai bambini, Google può farti rientrare nel programma *Designed for Families*, con restrizioni forti su annunci e SDK.
* **Sicurezza dei dati (Data Safety):** dichiara i dati raccolti **dagli SDK** (non solo dal tuo codice). Per gli SDK pubblicitari tipicamente: ID dispositivo o altri ID, informazioni sull'app e prestazioni, interazioni con l'app, posizione approssimativa (se l'SDK la tratta). Controlla la documentazione di AdMob, di ogni rete di mediazione e di RevenueCat, che pubblicano gli elenchi dei dati trattati. Se in dubbio, dichiara di più, non di meno: una dichiarazione incoerente con il comportamento reale dell'app può causare il rifiuto.
* **ID pubblicità (Advertising ID):** dichiara l'uso, e verifica che il manifest finale includa il permesso corrispondente (le librerie di annunci di solito lo aggiungono da sole).
* **Eliminazione dell'account:** non applicabile, perché non hai account. Se non esistono account in-app, la voce non ti riguarda.
* **Altre dichiarazioni** (app governative, funzioni finanziarie, salute, notizie): compilale solo se pertinenti.

**Verifica:** la scheda *Da completare* risulta vuota e tutte le voci sono in *Completate*.

---

## 5. Cose da controllare nel codice prima di caricare

* **Notifiche:** se pensi a un promemoria per la torre giornaliera, da Android 13 serve il permesso `POST_NOTIFICATIONS`. Chiedilo in un momento sensato (dopo che il giocatore ha provato il gioco), spiegando il motivo, non all'avvio.
* **Backup dei progressi:** l'**Auto Backup** di Android ripristina i dati locali dell'app su un nuovo dispositivo dello stesso account Google, senza backend. Verifica che sia attivo (`android:allowBackup` nel manifest) e che i dati di gioco siano in posizioni incluse nel backup (ad esempio `shared_preferences`). Per le chiavi e i file temporanei, definisci cosa escludere. Prova un ripristino reale se puoi.
* **Torre giornaliera offline:** usa sempre **UTC** per far cambiare la torre allo stesso momento per tutti. Salva l'ultima data vista e **ignora ritorni indietro nel tempo**, per limitare chi cambia l'orologio. In un gioco single-player il danno è solo per il giocatore stesso, quindi un controllo semplice basta.
* **Annunci in assenza di rete:** il gioco non deve bloccarsi né mostrare errori se un annuncio non si carica. I pulsanti legati ad annunci compaiono solo se l'annuncio è pronto.
* **Bot:** mostrali con nomi o stile che li facciano riconoscere come rivali simulati.

---

## 6. Configurare il test chiuso e caricare l'AAB

1. Vai in **Test e rilascio → Test → Test chiusi** e gestisci la traccia (di solito *Alpha*).
2. Scheda **Paesi/regioni:** aggiungi l'Italia o i paesi dove si trovano i tester.
3. Scheda **Tester:** crea una lista di indirizzi **Gmail** oppure collega un **Google Group** (comodo: un unico link, e puoi aggiungere persone senza toccare la traccia). Salva.
4. Scheda **Release → Crea nuova release:** lascia attivo **Play App Signing**, carica `app-release.aab`, inserisci le note di rilascio, salva e invia in revisione dal **Riepilogo delle pubblicazioni**.

**Verifica:** dopo l'approvazione (da poche ore a qualche giorno) lo stato diventa *Disponibile per i tester* e nella scheda Tester trovi il **link di partecipazione sul web**.

> Per iterare più velocemente puoi usare anche il **test interno** (fino a 100 tester, senza revisione). **Non conta** per il requisito dei 14 giorni.

---

## 7. Superare i 14 giorni di test

### 7.1 Come funziona
* Il conteggio parte solo quando la release è **live nella traccia chiusa** e almeno **12 tester** si sono iscritti **tramite il link di partecipazione**. Inviare l'invito non basta.
* I tester devono restare **iscritti in modo continuativo per 14 giorni**. Quando richiedi la produzione, **almeno 12 tester devono risultare ancora iscritti**.
* I tester devono usare **account Google distinti** e dispositivi Android reali.

### 7.2 Come reclutare ed evitare il reset
* Recluta **15-20 persone** per avere margine.
* Spiega a ognuno che **non deve uscire dal test né disinstallare** il gioco per tutta la durata.
* Mantieni un canale di contatto e ricorda di aprire il gioco in giorni diversi.
* Recluta tra amici, familiari, colleghi e community di sviluppatori.
* **Sconsigliato: comprare tester da servizi a pagamento.** Google controlla l'engagement per individuare test artificiali, la richiesta può essere respinta e non ottieni feedback utile.

### 7.3 Cosa far provare ai tester (utile per il tuo gioco)
Chiedi ai tester di segnalare:
* il comportamento **in modalità aereo** (avvio, partita, salvataggio progressi, cambio della torre giornaliera);
* il comportamento **con connessione** (annunci che si caricano e si chiudono, consenso GDPR, acquisti di prova);
* controlli, difficoltà e chiarezza delle classifiche contro i bot;
* crash, rallentamenti, problemi di leggibilità della grafica.

Per testare gli **acquisti** senza pagare, aggiungi i tester come **tester di licenza** nella Play Console; per gli **annunci**, usa **ID di test** finché non sei in produzione.

### 7.4 Buone pratiche (non obbligatorie)
* Rilascia **1 o 2 aggiornamenti** correggendo bug, incrementando la build in `pubspec.yaml` (es. da `1.0.0+1` a `1.0.1+2`). Non sono richiesti formalmente, ma ti aiutano a rispondere con concretezza al modulo finale.

### 7.5 Richiesta di accesso alla produzione
Terminati i 14 giorni, nella **Dashboard** clicca **Richiedi l'accesso alla produzione** e spiega come hai reclutato i tester, che feedback hai ricevuto e cosa hai migliorato.

**Verifica:** entro alcuni giorni lavorativi ricevi la notifica di approvazione e la sezione **Produzione** si sblocca. Se la richiesta viene respinta, leggi il motivo, correggi e riprova.

---

## 8. Rilasciare in produzione

1. Vai in **Test e rilascio → Produzione**.
2. Scheda **Paesi/regioni:** scegli i paesi di distribuzione.
3. Scheda **Release → Crea nuova release:** usa **Aggiungi dalla libreria** per scegliere l'ultimo `.aab` già collaudato, oppure carica una nuova build con `versionCode` incrementato.
4. Scrivi le note di rilascio, salva e invia dal **Riepilogo delle pubblicazioni**.

Valuta un **rilascio graduale** (es. 20% degli utenti all'inizio) per limitare i danni in caso di bug.

**Verifica:** al termine della revisione lo stato diventa **Disponibile su Google Play**.

---

## 9. Dopo la pubblicazione

* Controlla **Android vitals** (crash e ANR) e rispondi alle recensioni.
* Aggiorna il `targetSdkVersion` ogni anno, o Google può limitare la visibilità dell'app.
* Ogni volta che aggiungi o aggiorni un SDK, **aggiorna Privacy Policy e Sicurezza dei dati**.
* Se in futuro aggiungi account, classifiche online con giocatori reali, nomi utente o analytics, **rifai questa guida**: cambiano dichiarazioni, privacy, moderazione dei contenuti e, probabilmente, il pubblico di destinazione.
* Conserva il backup della keystore e delle password.

---

## Checklist finale

- [ ] Verifica identità (e dispositivo) completata
- [ ] `applicationId` definitivo, senza `com.example`
- [ ] Keystore e password in backup
- [ ] `.aab` release firmato, `targetSdkVersion` conforme, `versionCode` corretto
- [ ] Gioco testato in modalità aereo e con connessione, su dispositivo reale
- [ ] Privacy Policy pubblica, specifica e senza frasi come "nessun dato raccolto"
- [ ] Scheda dello store onesta sui bot ("rivali simulati") e sugli acquisti
- [ ] Contenuti dell'app e Sicurezza dei dati completati, coerenti con gli SDK
- [ ] Annunci con ID di test finché non sei in produzione
- [ ] Auto Backup verificato; torre giornaliera basata su UTC con controllo sull'orologio
- [ ] 15-20 tester reclutati e informati di non uscire dal test
- [ ] 14 giorni continuativi trascorsi con almeno 12 tester ancora iscritti
- [ ] Richiesta di produzione inviata con risposte concrete
