# Secondo livello — L’Orologio di Thultanthar

Fonte: Sessione 2, pagina 6, rapporto 217-A del 19 Ches 1491 DR. Le catacombe sotto la Vecchia Tantras e il meccanismo netherese arcano-psionico provengono dal rapporto. Il dispositivo scandisce cicli magici, stabilizza flussi e interagisce con rune netheresi: non controlla il tempo. Fu rubato dopo la spedizione ai Custodi; una pista lo colloca presso un ricco commerciante del mercato nero di Neverwinter.

Il livello è una ricostruzione del rapporto letto alla locanda. Non afferma che gli eroi abbiano recuperato i ricordi né che l’Orologio sia in loro possesso nel presente. Le due nuove tavole distinguono la spedizione ricostruita dal ritorno ai documenti alla locanda. I dialoghi sono adattamenti, non citazioni.

## Percorso e progressione

La prima scelta alla locanda ora conduce alla vignetta del rapporto, poi all’appunto del master con il titolo del livello. Nessun reset della build: trasformazione, livello del personaggio, salute, mana residuo e Intesa passano al secondo livello. Come negli stage già esistenti, le ricariche tornano pronte all’ingresso e gli effetti temporanei cessano; non vengono rimossi i modificatori permanenti della run.

1. **La discesa di Tantras:** percorso di 6.200 unità con quattro gruppi diversi, compresi bruto e arcanista. Ogni gruppo apre il passaggio successivo; completati gli scontri occorre raggiungere il varco.
2. **La galleria dei sigilli:** 5.000 unità, tre incontri e uscita fisica. Il protagonista resta mobile; questo stage non è più una seconda resistenza statica.
3. **La camera dei cicli:** tre sigilli distribuiti lungo 3.600 unità. Restare entro 90 unità nella corsia corretta per 1,6 secondi li accorda. Il progresso resta acquisito. Le pulsazioni ogni 6,5 secondi sono anticipate di 1,3 secondi e infliggono 12 danni sulla corsia indicata. Accordatili tutti, occorre ancora raggiungere il varco a 3.350.

Ogni stage mostra il messaggio di completamento prima dell’intermezzo. Due nuove pagine collegano discesa, galleria e camera. La resistenza statica è riservata al primo livello, una sola volta nell’intera sequenza attuale. Per composizioni e nuovi ruoli vedere [brawler-stages.md](brawler-stages.md).

Segue la vignetta del recupero storico e della pista sul furto, poi una seconda scelta di potenziamento alla locanda. Le offerte non ripropongono lo slot già trasformato. Il riepilogo mostra entrambe le benedizioni.

La suddivisione in tre prove, i combattimenti, la resistenza, i sigilli e i valori numerici sono adattamenti ludici. Il nuovo arcanista ha una propria famiglia di disegni; gli altri ruoli riutilizzano le figure animate esistenti: il rapporto non descrive un roster di avversari o un boss. Non vengono aggiunti nuovi fatti sulla memoria, sul segreto di Layla o sui rapporti censurati.

## Nuova grafica e profondità

Tre nuovi fondali, un nuovo pavimento prospettico, una nuova colonna con alpha e due nuove tavole a fumetto sono in `assets/orologio/`. Prompt e sorgenti sono registrati in `provenance.json`; originali conservati in `sources/`, compreso l’atlas iniziale superato dalla verifica grafica. `tools/build_orologio_assets.py` prepara i pannelli e ritaglia il margine trasparente della colonna senza ridipingere i personaggi.

Ogni ambiente usa quattro piani reali: fondale a 0.12, colonne intermedie a 0.48, pavimento a 1.0 e colonne davanti agli attori a 1.22. Le colonne hanno trasparenza reale. Il materiale di grafite rimane confinato allo scenario: nessuna perdita di colore su eroi o magie. Nei due stage mobili la camera rende visibile il movimento relativo; nella resistenza rimane volutamente ferma.

## Dati e verifica

- `data/livelli/orologio.json`: gruppo di tre stage e ricompensa finale.
- `data/stage/orologio_*.json`: incontri, ingressi sicuri e parametri di sincronizzazione.
- `data/ambienti/orologio_*.json`: nuove immagini e rapporti di parallasse.
- `data/testi/capitolo_01.json`: titoli, avvisi e due nuove pagine manuali.
- `tests/second_level_skills.gd`: selezione tramite la ricompensa reale e verifica dell’effetto di tutte le dodici trasformazioni nel secondo livello; persistenza fra stage, costi/cooldown, sigilli e seconda scelta.
- `tests/orologio_scenery.gd`: verifica visiva e numerica della parallasse del nuovo scenario e del bianco e nero.
- `tests/archive_playthrough.gd`: partita completa di entrambi i livelli con danni e risorse normali, uso della magia scelta e schermate nel gioco.

Questo livello sostituisce la prevista prova con vecchi ambienti. Non implementa ancora le tre nuove direzioni di build descritte nella proposta estesa: mette alla prova le dodici trasformazioni già disponibili. La ricompensa arriva a fine livello, in accordo con la distinzione fra livello e stage chiarita dall’utente.
