# Missioni, livelli e stage in JSON

## Significato dei termini

- **Missione:** contiene una sequenza di livelli.
- **Livello:** gruppo di stage che porta alla scelta di un potenziamento. Ha un titolo e una sola apertura con l’appunto del master.
- **Stage:** singola prova giocabile: combattimento, difesa, resistenza o fuga. Può avere il proprio ambiente e intermezzi, ma non ripete l’apertura del livello.

La missione attuale contiene **due livelli**, ciascuno con **tre stage**. Il primo è “La fuga dall’archivio”: scale, passaggio segreto e via di fuga. Il secondo è “L’Orologio di Thultanthar”: discesa, sigillo e camera dei cicli. La scelta avviene alla locanda dopo il terzo stage. Il foglietto appare soltanto prima delle scale, dopo le vignette introduttive.

## Dove intervenire

| File/cartella | Contenuto |
| --- | --- |
| `data/campagna.json` | Missione attiva dal titolo |
| `data/missioni/` | Ordine dei livelli, testi, prologo, immagini e apertura standard |
| `data/livelli/` | Ordine degli stage di un livello, ricompensa finale, intermezzi di apertura/chiusura e variazioni dell’appunto |
| `data/stage/` | Obiettivo, ambiente, nemici, alleati, limiti e intermezzi della singola prova |
| `data/ambienti/` | Sfondi, shader e piani di parallasse riutilizzabili |
| `data/testi/` | Titoli dei livelli e degli stage, avvisi e dialoghi |

Le definizioni hanno `schema_version: 1`; il nome del file coincide con `id`. Gli ID usano lettere minuscole, numeri e underscore. La posizione deriva dalle liste: non occorre numerare i file o cambiare gli ID quando si spostano gli elementi.

## Missione

`data/missioni/archivio.json` usa:

```json
"levels": ["fuga_archivio", "orologio"]
```

`texts` identifica il file in `data/testi/`. `prologue` abilita l’introduzione a scorrimento; `interludes_before` identifica le pagine iniziali. `ending: "victory"` conclude l’ultima parte. `presentation` associa gli ID `art` dei fumetti a tre immagini per pagina e definisce gli sfondi delle ricompense e della conclusione.

Per aggiungere un livello alla missione si inserisce il suo ID in `levels`, nella posizione desiderata. Per attivare un’altra missione si cambia `data/campagna.json`; non serve modificare il codice. Il menu di scelta fra più missioni resta da realizzare.

## Livello

Esempio reale, `data/livelli/fuga_archivio.json`:

```json
{
  "schema_version": 1,
  "id": "fuga_archivio",
  "text_id": "fuga_archivio",
  "stages": ["archivio_scale", "archivio_passaggio", "archivio_fuga"],
  "interludes": {"before": [], "after": []},
  "reward": {"type": "skill_upgrade", "choices": 3, "heal": 20, "mana": 30}
}
```

Il titolo si trova in `capitolo_01.json`, sezione `levels.fuga_archivio.name`. Il motore mostra l’appunto prima del primo stage e lo ripropone solo quando inizia un altro livello.

`interludes.before` precede gli eventuali intermezzi del primo stage; `interludes.after` segue quelli dell’ultimo stage e precede la ricompensa. Le liste possono essere vuote. Tutti i fumetti avanzano manualmente.

La ricompensa appartiene al livello: salute/mana vengono recuperati una sola volta, a fine gruppo; poi si scelgono le trasformazioni. La scelta avvia il livello successivo o conclude la missione. `type: "none"` permette una conclusione senza ricompensa, se esplicitamente voluta. La UI attuale usa tre carte; il sistema di trasformazioni supporta al massimo quattro ricompense per run, una per magia di Tholgrin.

## Appunto del master

Lo standard è nella missione:

```json
"entrance": {"style": "pencil", "write": 0.65, "hold": 0.85, "erase": 0.5}
```

Un livello può sovrascrivere singoli parametri con il proprio `entrance`. Lo stage non definisce un’appunto separato. Il foglietto ha bordi strappati, inclinazione, fibre, pieghe e ombra; il titolo viene tracciato e cancellato da sinistra a destra. La dicitura “Appunti del master” è in `interfaccia.json`.

- `pencil`: matita, cancellazione e residui di grafite.
- `ink`: rivelazione e rimozione della scritta, senza matita/gomma.
- `none`: disabilita lo standard, riservando lo spazio a una futura sequenza dedicata, per esempio per un boss. Tale sequenza richiede ancora implementazione.

Durante l’appunto nemici, timer, azioni e cooldown restano fermi. Invio/clic può saltarlo dopo 0,25 secondi; Esc mette in pausa e riprende nello stesso punto; F1 lo ferma durante l’aiuto. F2 nasconde gli strumenti in movimento e riduce il movimento del foglio. Gli avvisi delle ondate iniziano solo dopo l’apertura.

## Stage

Duplicare un file di `data/stage/` per creare una singola prova. Campi comuni:

- `id`, `text_id`: identificativo del file e chiave in `rooms.stages` del JSON testi, con `name` e `notice`.
- `environment`: ID in `data/ambienti/`.
- `stage`: limiti orizzontali `left`/`right` e partenza `player_x`, in coordinate logiche.
- `interludes.before/after`: ID delle pagine, anche liste vuote.
- `initial_enemies`: quantità della composizione standard di guardie e balestrieri; la resistenza usa ondate proprie.
- `reinforcements`: numero `count`, intervallo `interval` e limite `max_alive`; `count: 0` disabilita i rinforzi.
- `allies`: visibilità di Layla/eco e sostegno periodico (`echo_enabled`, `echo_interval`, `echo_max_x`, `echo_damage`). La super di gruppo resta distinta da questo aiuto ambientale.

Gli stage non contengono `reward` o `entrance`: i due campi appartengono al livello.

| `type` | Obiettivo e campi specifici |
| --- | --- |
| `scrolling` | Incontri attivati da `encounters[].at_x`, ingressi fuori schermo e uscita `exit` dopo l’ultimo gruppo. `gate_x` è conservato per compatibilità e non blocca il movimento. |

| `resistance` | Sopravvivere per `duration`, con posizione e camera fisse. Usa `anchor_x`, `waves`, `archetypes`, `warning_time`, `spawn_distance`, `entry_lane_hold`. |
| `escape` | Raggiungere `exit.x` nella corsia `exit.lane`, con tolleranza verticale `exit.tolerance`. Ingressi regolati da `spawn_min_distance`, `spawn_margin`, `spawn_spacing`. |

Dettagli delle ondate: `data/stanze/LEGGIMI.md`. Corsie 0/1/2 = alta/centrale/bassa; lati -1/1 = sinistra/destra. I preavvisi iniziano a `wave.at + entry.offset`, poi trascorre `warning_time` prima dell’ingresso.

Il tipo `synchronization`, usato dalla camera dell’Orologio, è implementato: `synchronization.sigils` contiene posizioni e corsie; `charge_seconds` e `radius` regolano l’accordatura; `pulse_interval`, `pulse_warning` e `pulse_damage` regolano le pulsazioni. Il completamento dipende dai sigilli, non dalle uccisioni. I punti di ingresso facoltativi `spawn_points` e `spawn_safe_distance` permettono di distribuire avversari e rinforzi lontano dal protagonista. Nuove meccaniche, IA ed eroi giocabili richiedono codice; nuovi stage dei tipi già presenti richiedono soltanto dati e asset.

## Ambienti e parallasse

Ogni ambiente definisce `shader` e `layers` ordinati. Il materiale dell’archivio mantiene grafite su pergamena; attori, magie e UI restano fuori dal materiale.

Ogni piano ha `kind`, `texture`, `depth`; opzionali `alpha` e `foreground`. `depth` controlla il rapporto con il movimento della camera: nei fondali attuali 0.12 lontananza, 0.48 architettura, 1 terreno, 1.22 primo piano. Nella resistenza la camera è fissa.

| `kind` | Parametri |
| --- | --- |
| `texture` | Immagine intera in `rect: [x,y,larghezza,altezza]`. |
| `tiles` | Ripetizione orizzontale con `rect` e intervallo `tiles: [inizio,fine_esclusa]`. |
| `pillars` | Ritaglio `region`, destinazione `rect`, ripetuto alle ascisse `anchors`. |
| `arches` | Modulo predefinito delle arcate a inchiostro, con `anchors` e `region` dei pilastri. |

Tutti i percorsi di risorse iniziano con `res://`. I piani `texture` e `tiles` bastano per nuovi fondali senza arcate.

## Procedura pratica

1. Per una nuova prova, duplicare un file in `data/stage/`, cambiarne ID, obiettivo e ambiente, e collegare il suo `text_id` nei testi.
2. Inserire l’ID nella lista `stages` del livello: non introduce una ricompensa né un’altra apertura.
3. Per un nuovo livello, creare invece un file in `data/livelli/` con la sua lista di stage, titolo nei testi e ricompensa; aggiungerne l’ID a `mission.levels`.
4. Collegare le pagine narrative con gli ID. Le pagine attuali usano tre battute e tre pannelli illustrati.
5. Eseguire `python tools/check_missions.py` e `python tools/check_texts.py`, poi riavviare con R.

Il caricatore e il validatore verificano i riferimenti; i controlli Python completi verificano anche coordinate, parametri, immagini e ingressi oltre la fine della resistenza. `tests/level_groups.gd` verifica apertura unica, tre stage senza ripetizioni, ricompensa finale e nuova apertura solo dopo la scelta del livello successivo.

## Revisione dei percorsi

Solo `resistance` conclude una prova a tempo. Gli altri tipi del sistema di campagna richiedono `exit`. Gli stage `scrolling` usano `encounters`, `warning_time` e `spawn_distance`; la composizione di ogni incontro indica ruoli, corsie, lati e ritardi di ingresso. I profili sono in `data/nemici/archetipi.json`. Dopo ogni obiettivo si apre `stage_clear`, poi il fumetto manuale. Regole e campi: [brawler-stages.md](brawler-stages.md). Le vecchie modalità `combat`/`defense` restano soltanto nella logica sperimentale e nei test di migrazione, non sono tipi validi per nuovi file di campagna.
