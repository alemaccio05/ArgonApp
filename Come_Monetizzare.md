# Monetizzare un gioco di svago offline (Flutter, Google Play)

Guida pratica per un gioco **2D rilassante, giocabile offline**, con torri da scalare (livelli progressivi e torre giornaliera), classifiche contro **bot**, skin e icone profilo sbloccabili giocando. Il modello consigliato è leggero: **annunci premiati facoltativi**, **interstitial rari** e **pochi acquisti in-app chiari**.

> **Ultima verifica: ottobre 2026.**
> Tutte le cifre (eCPM, conversione, aumenti di ricavi) sono **ordini di grandezza indicativi**: variano per paese, genere, stagione e rete pubblicitaria. Non usarle come previsioni di guadagno, misurale sul tuo gioco. Commissioni, norme AdMob e condizioni di RevenueCat cambiano: controllale nelle pagine ufficiali (Guida Play Console sulle commissioni, norme AdMob, sito di RevenueCat) prima di decidere.

---

## 0. Il principio guida: un gioco rilassante deve restare rilassante

Il valore di un giocatore è:

**LTV = ARPDAU (ricavo medio giornaliero per utente) × giorni di permanenza**

In un gioco di svago, chi si sente interrotto se ne va e recensisce male. Gli annunci forzati frequenti sono il contrario di ciò che il tuo pubblico cerca. La strategia sensata è **pochi annunci, ben scelti**, e lasciare all'utente il controllo.

Un altro fatto concreto del tuo caso: il gioco è **offline**. Un giocatore senza connessione **non genera ricavi pubblicitari** e non può comprare nulla. Non puoi forzare nulla: gli annunci compaiono solo quando c'è rete e sono pronti.

---

## 1. Pubblicità: formati e come usarli nel tuo gioco

L'eCPM è il ricavo ogni 1.000 impressioni. Gli intervalli sono **indicativi per mercati ad alto valore** (USA, Europa occidentale) e molto più bassi altrove.

| Formato | eCPM indicativo | Effetto sulla retention | Uso nel tuo gioco |
| --- | --- | --- | --- |
| **Rewarded video** | circa 8-30 € | Positivo (lo sceglie l'utente) | "Riprendi dal punto in cui sei caduto", un tentativo extra nella torre giornaliera, una skin in prova. |
| **Interstitial** | circa 3-12 € | Negativo se frequente | Dopo una caduta o a fine tentativo, **raramente**. Mai durante la scalata. |
| **Banner** | circa 0,30-1,50 € | Neutro o basso | Sconsigliato durante il gioco (rovina l'estetica a inchiostro e causa click accidentali). Eventualmente solo nel menu. |

### 1.1 Rewarded: dove inserirli
* **Continua dopo la caduta** (una volta per tentativo): propone di riprendere dal punto raggiunto. Il giocatore deve capire prima cosa ottiene.
* **Tentativo extra nella torre giornaliera:** coerente col tuo schema, ma stabilisci un **limite chiaro** (es. un tentativo extra al giorno) e **dichiaralo**. Dato che il confronto è con bot, non crea ingiustizie verso altri giocatori, ma può svalutare il senso della sfida giornaliera se concesso senza limiti.
* **Skin in prova per qualche tentativo:** valido, purché la skin non sia tra quelle che si ottengono giocando (vedi sezione 2).

Mostra il pulsante **solo se l'annuncio è pronto**. Se l'utente è offline o l'annuncio non è caricato, **nascondi il pulsante**, senza errori o messaggi di fallimento.

### 1.2 Interstitial: pochi e prevedibili
Nel tuo gioco si ritenta in fretta, quindi un frequency cap troppo largo si fa sentire subito. Un punto di partenza prudente (da testare):

* **non** prima di diversi tentativi giocati, e mai nella prima sessione;
* **al massimo uno ogni 3-5 minuti** di gioco effettivo;
* solo in pause naturali (schermata di caduta, fine livello), mai a metà scalata;
* **mai** all'apertura dell'app o subito dopo un tap in un momento inatteso.

Misura la retention (giorno 1, 3, 7) prima e dopo ogni modifica, e riduci la frequenza se scende.

### 1.3 Banner
In un gioco d'azione con un tocco centrale rischiano di causare **click accidentali**, che possono portare AdMob a limitare l'account. Se li vuoi, solo nel menu principale o nelle schermate di negozio.

### 1.4 Regole che proteggono l'account AdMob
* **Mai** posizionare annunci vicino a pulsanti in modo da indurre click involontari.
* **Mai** cliccare sui tuoi annunci né chiedere ad altri di farlo.
* In fase di sviluppo e test usa **solo ID di test** (e dispositivi di test registrati). Cliccare annunci reali durante i test può far sospendere l'account.
* I rewarded devono essere **facoltativi** e con la ricompensa spiegata **prima** della visione.

### 1.5 Mediazione (bidding)
Usare una sola rete lascia soldi sul tavolo. Con la mediazione (Open Bidding in AdMob, oppure AppLovin MAX o Unity LevelPlay) più reti competono per ogni annuncio.

* L'aumento dei ricavi può essere significativo, ma dipende dal traffico: confronta i dati prima e dopo.
* Ogni rete aggiunta è **un nuovo SDK**: va dichiarata in **Privacy Policy** e **Sicurezza dei dati**. Se vuoi tenere semplice la documentazione, parti con AdMob più una o due reti.

---

## 2. Acquisti in-app (IAP) adatti a un gioco di svago

Solo una **minoranza** degli utenti paga, e in un gioco casual la percentuale può essere molto bassa. Offri valore reale, non fastidio.

### 2.1 Regole da conoscere
* Per beni digitali nel gioco devi usare **Google Play Billing** (anche RevenueCat lo usa internamente).
* **Commissione:** per i prodotti in-app Google applica in genere il 15% sui primi 1 milione di dollari annui per sviluppatore (programma a commissione ridotta, a cui di solito ci si iscrive) e il 30% oltre. Verifica le condizioni attuali.
* Evita **casse casuali** (gacha): non servono al tuo gioco, aggiungono obblighi di comunicazione delle probabilità e non si adattano a un'esperienza rilassante.

### 2.2 Cosa vendere
1. **Rimuovi interstitial** (acquisto una tantum): per un pubblico rilassato è probabilmente l'acquisto più naturale. Chiarisci cosa include: i rewarded restano disponibili come scelta, se l'utente li vuole.
2. **Skin e icone profilo cosmetiche esclusive**, con lo stile inchiostro su carta come marchio: tratti a penna, macchie, colori alternativi dell'inchiostro, scie.
3. **Pacchetto "Sostieni il gioco"** (opzionale): rimuovi interstitial + una skin esclusiva a un prezzo unico, più conveniente dei due acquisti separati.

### 2.3 Un punto delicato: skin ottenibili giocando
Le skin e le icone che si ottengono giocando sono una parte del valore del gioco. Se le stesse diventano **acquistabili**, chi le ha guadagnate può sentirsi svalutato. Soluzioni sane:
* **riserva agli IAP skin ed elementi esclusivi**, non ottenibili giocando;
* oppure, se vendi scorciatoie, **dichiaralo chiaramente** e non rendere gli elementi più prestigiosi acquistabili.

### 2.4 Quando mostrare le offerte
* Nei **momenti positivi**: dopo aver completato una torre difficile, battuto un record o sbloccato un traguardo.
* Con un **negozio sempre raggiungibile** dal menu, senza pop-up continui.
* Evita offerte di acquisto **subito dopo un annuncio forzato**: sfrutta il fastidio dell'utente, peggiora recensioni e retention, e può essere considerato manipolativo. Evita anche di sovrapporre un interstitial e un pop-up di acquisto.
* Se mostri un invito, deve poter essere chiuso subito. Limitalo a una volta per sessione, al massimo.

### 2.5 Prezzi per paese
Nei mercati con minore potere d'acquisto i prezzi unici in euro convertono poco e gli annunci rendono meno. Nella Play Console puoi impostare **prezzi diversi per paese**. Parti da un prezzo ridotto, poi **testa e misura**: non esiste un valore valido per tutti.

---

## 3. La curva di monetizzazione per il tuo gioco

Un esempio di progressione da adattare e testare:

1. **Prima sessione: nessun annuncio forzato.** Il giocatore deve capire il lancio della palla, scalare le prime torri e provare soddisfazione.
2. **Introduzione dei rewarded** quando cade vicino alla cima o a un record: un invito chiaro e facoltativo ("Riprendi da qui con un video").
3. **Torre giornaliera:** dopo qualche giorno di gioco, mostra l'opzione del tentativo extra premiato.
4. **Interstitial rari** dalla seconda sessione o dopo diversi tentativi, nelle pause naturali, con il cap descritto sopra.
5. **Offerte IAP** nei momenti positivi, mai dopo un annuncio forzato.

Misura retention a giorno 1, 3 e 7, ARPDAU e conversione degli acquisti, e correggi di conseguenza.

---

## 4. Particolarità del tuo gioco

### 4.1 Bot in classifica
* Chiarisci che sono **rivali simulati** (nomi, stile o etichetta riconoscibili). Questo vale anche per le descrizioni nello store e per le offerte di acquisto.
* **Non vendere vantaggi in classifica** in modo ambiguo: se un acquisto o un annuncio ti dà un tentativo in più nella sfida contro i bot, dillo chiaramente.
* Se in futuro userai giocatori reali, cambiano le regole: servono backend, nomi utente, moderazione e aggiornamento di Privacy Policy e Sicurezza dei dati.

### 4.2 Torre giornaliera e orologio
Con un gioco offline userai la data del dispositivo. Per ridurre abusi: usa sempre **UTC**, salva l'ultima data vista e ignora ritorni indietro nel tempo. In un gioco single-player il danno è solo per il giocatore stesso, quindi un controllo semplice basta. Ricorda questo se colleghi ricompense reali o acquisti ai tentativi giornalieri.

### 4.3 Pubblico
Se il gioco può attirare minori, rileggi la sezione 5 e le note sul pubblico di destinazione nel tutorial di pubblicazione.

---

## 5. Stack tecnico consigliato (Flutter)

### Pubblicità
* Pacchetto ufficiale **`google_mobile_ads`** più gli adapter di mediazione che sceglierai (controlla su pub.dev nomi e versioni compatibili).
* **Pre-carica** gli annunci in background (`RewardedAd.load(...)`, `InterstitialAd.load(...)`) e ricaricali dopo ogni visualizzazione. Se non sono pronti, **non bloccare il gioco** e nascondi il pulsante.
* Gestisci il caso **offline**: nessun errore visibile, nessun pulsante premio inutilizzabile.
* Durante lo sviluppo usa **ID di test**.

### Acquisti in-app
* Hai pochi prodotti (rimozione interstitial, skin, eventuale pacchetto). Puoi usare il pacchetto `in_app_purchase` (più lavoro per ripristino acquisti e verifica) oppure **RevenueCat** (`purchases_flutter`), che semplifica verifica e ripristino. RevenueCat ha un piano gratuito fino a una soglia di ricavi mensili: **verifica le condizioni attuali** sul loro sito. Se lo usi, dichiaralo in Privacy Policy e Sicurezza dei dati.
* Implementa sempre il **ripristino degli acquisti**: con il tuo gioco senza account, è l'unico modo per un giocatore di riavere ciò che ha comprato su un nuovo dispositivo.
* Attiva anche l'**Auto Backup** di Android per i progressi locali (vedi tutorial di pubblicazione).

### Consenso (GDPR / EEA)
* Per gli utenti europei serve un **consenso conforme** prima degli annunci personalizzati. Usa la **User Messaging Platform (UMP)** integrata in `google_mobile_ads` e configura il messaggio in AdMob. Il modulo di consenso richiede connessione: offline, gli annunci semplicemente non si caricano.
* Controlla le impostazioni sulla privacy nella console AdMob.

---

## 6. Se il gioco può essere usato da minori

* Se il gioco è rivolto, anche in parte, a **under 13**, valgono le regole del programma *Designed for Families*: reti pubblicitarie certificate, niente annunci personalizzati, raccolta dati molto limitata.
* Dichiarare "13+" **non ti protegge** se grafica, personaggi o tono attirano i bambini.
* In caso di dubbio, imposta in AdMob il trattamento come contenuto destinato ai minori (TFCD/TFUA) e usa solo annunci adatti.

---

## 7. Cosa scrivere sulla raccolta dati

Il tuo codice non raccoglie dati personali (niente account, niente server). Ma gli **SDK** di annunci e acquisti sì, e quelli determinano cosa dichiarare. Quindi:
* **non scrivere** "non raccogliamo alcun dato" nello store o nella Privacy Policy;
* scrivi che il gioco **non richiede account e non invia dati a server dello sviluppatore**, e che gli annunci possono trattare dati secondo le informative delle reti;
* aggiorna Privacy Policy e Sicurezza dei dati a ogni nuovo SDK.

---

## 8. Checklist prima del lancio

- [ ] Nessun annuncio forzato nella prima sessione
- [ ] Interstitial rari, solo in pause naturali, con frequency cap
- [ ] Rewarded sempre facoltativi, con ricompensa spiegata prima, nascosti se non pronti o offline
- [ ] Nessun annuncio vicino a pulsanti che possano causare click accidentali
- [ ] Test eseguiti con **ID di test** e senza click su annunci reali
- [ ] Mediazione attiva solo con reti dichiarate in Privacy Policy e Sicurezza dei dati
- [ ] UMP configurato per l'Europa
- [ ] IAP con Google Play Billing e **ripristino acquisti** funzionante
- [ ] Skin acquistabili distinte da quelle ottenibili giocando
- [ ] Nessuna cassa casuale
- [ ] Bot presentati come rivali simulati; nessun vantaggio in classifica venduto in modo ambiguo
- [ ] Torre giornaliera su UTC con controllo sull'orologio
- [ ] Privacy Policy, scheda dello store e Sicurezza dei dati coerenti con gli SDK
- [ ] Piano per misurare retention (G1, G3, G7), ARPDAU e conversione IAP
