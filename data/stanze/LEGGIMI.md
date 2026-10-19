# Tipologie di stanza e ondate

`archivio.json` contiene le regole delle tre stanze, nell’ordine del capitolo. I testi rimangono in `data/testi/`.

- `scrolling`: percorso mobile con incontri legati alla posizione e varco finale; usato dall’archivio e dalle gallerie dell’Orologio.
- `resistance`: posizione orizzontale fissa, telecamera ferma, ondate dai due lati e conto alla rovescia.
- `escape`: terza stanza, movimento libero fino all’uscita.

Nella resistenza A/D orienta attacchi e scudo, W/S cambia corsia, Spazio schiva senza spostamento orizzontale. Anche la respinta rispetta la posizione fissa. Gli altri tipi di stanza mantengono il movimento normale.

## Seconda stanza

`duration` è 25 secondi; `anchor_x` fissa Tholgrin a 760; `spawn_distance` pone gli ingressi a 580 unità da lui. Pausa, aiuto e scene narrative fermano la simulazione. Sopravvivere fino a zero completa l’obiettivo anche con nemici vivi.

`waves` contiene le quattro ondate:

| Inizio del preavviso | Nome | Composizione |
|---|---|---|
| 0 s | Primo contatto | Guardia da sinistra sulla corsia centrale; guardia da destra dopo 0,8 s. |
| 6 s | Tiro incrociato | Balestriere da destra sulla corsia alta; guardia da sinistra sulla bassa dopo 1,2 s. |
| 12 s | Assalto sfalsato | Assaltatori da sinistra in alto e da destra in basso a distanza di 1 s; balestriere centrale da sinistra dopo 2,2 s. |
| 17 s | Ultima pressione | Bruto centrale da destra, assaltatore basso da sinistra dopo 0,9 s e balestriere alto da destra dopo 2,2 s. |

Sono dieci nemici, cinque per lato. Ogni voce `entries` specifica:

- `offset`: ritardo del **preavviso** rispetto all’inizio dell’ondata.
- `side`: -1 per sinistra, 1 per destra.
- `lane`: 0 alta, 1 centrale, 2 bassa.
- `archetype`: `guard`, `runner` oppure `archer`.

`warning_time` (1,2 secondi) si aggiunge a `at + offset` prima della comparsa effettiva. Un ingresso a `at: 6`, `offset: 0` mostra il segnale al secondo 6 e fa entrare il nemico al secondo 7,2. Il segnale indica lato, corsia, ruolo e tempo rimanente, e scompare quando entra quel nemico. La durata deve lasciare tempo all’ultimo ingresso di entrare e partecipare.

`entry_lane_hold` (2,4 secondi) mantiene inizialmente il nemico sulla corsia annunciata. Poi il nemico può reagire al cambio di corsia del protagonista con la normale IA.

## Profili

`archetypes` separa il ruolo dalle composizioni:

| Ruolo | Salute | Velocità | Preparazione attacco |
|---|---:|---:|---:|
| guard | 48 | 108 | 0,70 s |
| runner | 34 | 155 | 0,55 s |
| archer | 38 | 96 | 0,80 s |

Le guardie e gli assaltatori usano gli sprite da mischia; gli assaltatori hanno anche due piccoli chevron sopra la salute. I balestrieri usano lo sprite e il comportamento a distanza esistenti. Rimane il limite di due nemici che impegnano contemporaneamente un attacco.

I nomi delle ondate si modificano in `data/testi/capitolo_01.json`, sezione `rooms.wave_names`, mantenendo gli stessi id. I nomi dei ruoli e i testi dei segnali si modificano in `data/testi/interfaccia.json`.

Le regole vengono rilette avviando una nuova partita. Per aggiungere livelli futuri di resistenza, riutilizzare l’intero blocco `resistance`, adattando durata e piano degli ingressi; inserire l’ID del nuovo livello nel manifesto della missione e configurare le sue liste di intermezzi, anche vuote.


## Ingressi nella fuga

La terza stanza non usa i punti di nascita vicini alla posizione iniziale del protagonista. `spawn_margin` (80) e `spawn_spacing` (140) collocano le guardie verso il bordo più lontano; `spawn_min_distance` (440) garantisce un margine anche ai rinforzi. Il lato di ingresso viene scelto rispetto alla posizione attuale di Tholgrin. Se il punto sfalsato fosse troppo vicino, si usa il bordo più lontano. I punti restano dentro i limiti effettivi del movimento dei nemici, così il primo aggiornamento non li teletrasporta verso il personaggio.

Livello e stage sono distinti: “La fuga dall’archivio” è un livello di tre stage, con un solo appunto iniziale e una scelta di potenziamento finale. La sequenza degli stage e la ricompensa sono in `data/livelli/fuga_archivio.json`.

## Struttura attuale

Una sola delle sei prove è statica a tempo: il passaggio segreto. Gli altri stage hanno un’uscita lungo il percorso. Le composizioni dei percorsi mobili sono nei rispettivi `encounters`; ruoli condivisi in `data/nemici/archetipi.json`. Il nuovo bruto e l’arcanista si affiancano a guardie, assaltatori e balestrieri. La fine di ogni stage mostra prima il messaggio di completamento, poi il fumetto. Guida aggiornata: [brawler-stages.md](../../docs/brawler-stages.md).
