# Capitolo 1: La fuga dall’archivio

Testi modificabili in [data/testi](data/testi/LEGGIMI.md), riletti a ogni nuova partita. Introduzione a scorrimento prima della scena con Corvin: Spazio pausa, frecce/rotella per leggere, Invio/clic/Esc prosegue.

Il titolo avvia la sequenza tratta dalle prime due sessioni: fumetti manuali, archivio a scorrimento con tre scontri, un’unica resistenza di 25 secondi, fuga lunga fino al varco e ricompensa alla locanda. Invio / Spazio / clic per avanzare i dialoghi; Esc salta la pagina corrente. **B dal titolo** avvia la precedente arena del ponte.

Nello stage **RESISTENZA**, A/D orienta Tholgrin, W/S cambia corsia e Spazio schiva sul posto. Barra e timer indicano quando Layla avrà aperto il passaggio.

Dettagli, differenze dalle sessioni e limiti del primo capitolo: [docs/archive-chapter.md](docs/archive-chapter.md). Il secondo livello, [L’Orologio di Thultanthar](docs/orologio-level.md), prosegue dopo la prima scelta: tre nuovi stage, nuovi fondali e vignette, sincronizzazione dei sigilli e seconda ricompensa. La trasformazione scelta viene mantenuta e usata nel nuovo livello.

---

# Ceneri & Echi

Prototipo Godot 4.7.2 di un action roguelite a tre corsie, illustrato su carta e inchiostro.

## La run attuale

Scegli Tholgrin nella schermata iniziale. Supera tre stanze, scegli una benedizione dopo ciascuna e affronta il custode finale. Una sola vita; nessun cambio del protagonista durante il combattimento. Le altre due avventure saranno sviluppate dopo questa prova: Layla e Lupinor compaiono già negli intermezzi e negli attacchi combinati.

Le quattro magie hanno mana e ricariche separate. Tholgrin parte dal livello 9 per avere già il kit completo del Dominio della Luce 2024; ogni scelta di fine stanza aumenta il livello di uno. Ogni livello riduce le ricariche base del 6%; le trasformazioni più forti aumentano la ricarica, mentre Scudo della fede attivo riduce del 12% quella delle altre magie al momento del lancio (tranne la variante Egida). Si tratta di adattamenti action, non delle regole da tavolo sui cooldown. La mazza recupera 10 mana quando colpisce; il mana rigenera anche nel tempo. Dodici benedizioni trasformano le magie (esplosione, perforazione, tre corsie, santuario, egida, nova e altre). Ogni run ne riceve tre. Nessuna progressione permanente o salvataggio per ora.

Tra le stanze si apre un intermezzo statico a fumetto: tre vignette illustrate, balloon che avanzano esclusivamente con Invio/Spazio/clic. Dopo l’ultima battuta, un altro input apre le ricompense. Esc salta il dialogo e va comunque alla scelta. Lo sfondo delle carte mostra tutti e tre gli eroi seduti attorno al falò sul ponte, con il gruppo visibile sopra le carte. Riposo: +20 salute e +30 mana fino al massimo, applicato una sola volta; ricariche azzerate all’ingresso successivo. La build e l’Intesa si conservano. Le battute sono segnaposto in attesa dei PDF della campagna.

## Avvio e comandi

Apri `project.godot` e premi F5 oppure usa `Avvia-demo.cmd`. Invio apre la selezione; Invio conferma Tholgrin.

| Comando | Azione |
|---|---|
| A/D oppure frecce | Muovi |
| W/S oppure frecce | Cambia corsia |
| J (anche tenuto) | Mazza e combo, recupera mana al contatto |
| K | Dardo tracciante |
| L | Muro di fuoco |
| U | Scudo della fede |
| I | Colpo infuocato |
| Q (tenuto) | Scudo frontale |
| Spazio/Shift | Schivata |
| V | Spendi Intesa: da 60 Layla, a 100 Layla e Lupinor |
| Invio/Spazio/clic | Avanza nel fumetto; dopo l’ultima battuta apre l’accampamento |
| Esc durante il fumetto | Salta alla scelta del potenziamento |
| 1/2/3 oppure clic | Scegli ricompensa all’accampamento |
| Esc/P | Pausa |
| F1 | Grimorio con comandi e descrizioni aggiornate delle magie |
| F2 | Movimento ridotto |
| M | Audio |
| R | Nuova run da zero |
| F3 | Studio delle animazioni |

Gamepad: stick/croce muove e cambia corsia; X mazza, Y/B/LB/RB magie, A schiva, R3 Intesa, Start conferma e Back pausa. Negli intermezzi sinistra/destra seleziona e Start conferma. Il controller fisico resta da verificare. Lo scudo opzionale Q al momento è disponibile da tastiera.

## Intesa

Si carica infliggendo danni effettivi e subendoli. Da 60 a 99, V richiama Layla per **Lame e braci**, un attacco combinato sulla corsia. A 100, V attiva **Patto delle tre voci**: entrano entrambi gli alleati, le eco di Lupinor colpiscono le corsie e Tholgrin conclude con le fiamme. Si consuma tutta la carica; l’attacco non si ricarica da solo.

## Magie illustrate

Aura, fiamme, proiettili ed esplosioni usano sprite originali generati, con otto fotogrammi per sequenza. Aura e fiamma hanno anche otto fotogrammi dedicati alla nascita, da una pozza a terra al volume completo. Le quattro icone sono condivise da HUD, grimorio e ricompense. In ricarica diventano grigie e recuperano colore dal basso, insieme al riempimento della carta e ai secondi rimanenti.

Asset e prompt: `assets/magic/provenance.json`. Preparazione: `tools/build_magic_assets.py`. Dettagli e fonti dei nomi: [magie e ricariche](docs/magic-presentation.md).

## Verifica della versione attuale

Esegui Godot con `--headless --path . --script tests/run_rules.gd`: 74 controlli su magie, tutte le trasformazioni, mana, danni, ricompense, alleati, vittoria, sconfitta e reset.

`tests/run_playthrough.gd`: tre run automatiche senza alterare salute/danni o eliminare nemici, con scelte e build differenti. È una verifica di completabilità, non una misura della durata o difficoltà per il giocatore.

`tests/run_visual_tour.gd` (con rendering): percorso tramite input per selezione, magie, ricompensa, nuova stanza, trio, pausa e aiuto; schermate `artifacts/run-*.png`. Solo per mostrare l’intermezzo questa cattura forza la conclusione della prima stanza e carica l’Intesa; la prova di completabilità è separata.

`tests/magic_feedback.gd`: 85 controlli su frame, nascita degli effetti, icone, nomi, livelli e ricariche. `tests/ability_visual_tour.gd`: catture delle 16 varianti, degli impatti e della nascita degli effetti, con bersagli fermi e salute aumentata per studiare la resa visiva.

`tests/interlude_flow.gd`: 44 controlli su sequenza, tempi dei balloon, pausa del mondo, scelta obbligatoria, riposo applicato una volta e reset. `tests/capture_interludes.gd` cattura le tre pagine complete e i tre accampamenti e verifica Esc e clic tramite input nativi.

`tests/pencil_art.gd`: verifica le risorse delle animazioni. I vecchi test basati sul cambio eroe e sulle tre ondate sono conservati come storico e non descrivono più le regole attuali.

## Limiti della prova

Le stanze sono arene dello stesso ambiente del ponte, con composizioni di nemici differenti. Arte, animazioni e audio restano da rifinire. I dialoghi sono segnaposto in attesa dei riassunti dell’avventura. Layla e Lupinor non hanno ancora le proprie run. Nessun multiplayer, salvataggio, meta-progressione o bilanciamento definitivo.

[Direzione grafica](docs/pencil-implementation.md) · [Regole della run](docs/roguelite-run.md) · [Font e licenze](assets/fonts/README.md)

Intermezzi: [note di implementazione](docs/comic-interludes.md) · [illustrazioni e prompt](assets/interludes/provenance.json).

Livello e stage sono distinti: “La fuga dall’archivio” è un livello di tre stage, con un solo appunto iniziale e una scelta di potenziamento finale. La sequenza degli stage e la ricompensa sono in `data/livelli/fuga_archivio.json`.

## Percorsi a scorrimento

Gli stage mobili ora terminano raggiungendo un’uscita fisica: incontri distribuiti, passaggi che si aprono dopo il combattimento e scenari lunghi fino a 6.200 unità. Una sola delle sei prove è statica a tempo. Ogni stage mostra un messaggio di completamento prima del fumetto. Cinque ruoli nemici includono un bruto e un nuovo arcanista. Dettagli: [stage e nemici](docs/brawler-stages.md).
