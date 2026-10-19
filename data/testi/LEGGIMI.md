# Modificare i testi del gioco

Questi file sono la sorgente dei testi visibili. Il gioco **non legge i PDF durante la partita** e non ricrea le battute dai riassunti. Puoi correggere liberamente le frasi: non vengono riscritte all’avvio.

| File | Cosa contiene |
|---|---|
| `capitolo_01.json` | Introduzione a scorrimento, titoli delle scene, battute con Corvin e Daleal, obiettivi delle tre stanze. |
| `ponte.json` | Dialoghi della precedente arena del ponte. |
| `abilita.json` | Nomi e descrizioni di eroi, magie e potenziamenti. |
| `interfaccia.json` | Menu, suggerimenti, messaggi, HUD, schermate della locanda e di fine capitolo. |

## Come fare

1. Apri il file con un editor di testo e cerca la frase da correggere.
2. Cambia il testo **a destra dei due punti**, tra le virgolette. Salva in UTF-8.
3. Avvia una nuova partita: i JSON vengono riletti. Puoi usare **R** durante il gioco, oppure tornare al titolo e ripartire. Non serve chiudere Godot.

Per esempio, in `capitolo_01.json` puoi cambiare `"text": "La frase di Corvin..."` senza modificare il resto del blocco.

## Introduzione

Dentro `intro`, modifica `title`, `kicker` e le frasi nell’elenco `paragraphs`. Ogni elemento è un paragrafo: puoi aggiungerne o rimuoverne, rispettando le virgole tra le stringhe. Testo e durata dello scorrimento si adattano alla lunghezza.

L’introduzione parte dopo la scelta di Tholgrin. Scorre automaticamente e rimane ferma alla fine. **Spazio** ferma/riprende, **freccia giù** accelera, **freccia su o rotella** permette di rileggere. **Invio, clic o Esc** passa alla scena di Corvin anche prima della fine. I fumetti successivi rimangono interamente manuali.

## Cosa mantenere

- Conserva i nomi delle chiavi, gli `id`, i valori `hero`, `slot` e `art`: collegano le frasi a personaggi, immagini e abilità.
- Le scene a fumetti hanno tre vignette e tre battute. Puoi cambiare `title`, `subtitle`, `text` e il `name` del parlante quando presente; non cambiare il numero delle vignette.
- Le sigle **`%d`, `%s`, `%.1f`, `%.2f`, `%02d`, `%%`** sono sostituite dal gioco con numeri, nomi o percentuali. Mantienile nello stesso ordine.
- Usa `\"` per virgolette all’interno di una frase, oppure le virgolette tipografiche “così”. Non eliminare virgole o parentesi del JSON.
- Per i balloon, preferisci battute brevi, circa tre righe. Introduzione e descrizioni possono essere più lunghe, ma le dimensioni dell’interfaccia restano quelle della demo.
- Cambiare una descrizione numerica non cambia danni, costi o cooldown: quei valori restano nella logica del gioco. Durata e ondate della resistenza sono invece configurate separatamente in `data/stage/archivio_passaggio.json`.

I titoli delle chiavi di `interfaccia.json` ricordano la versione iniziale della frase: non occorre rinominarli quando correggi il valore.

Per controllare sintassi e collegamenti dei testi: `python tools/check_texts.py`.

Gli eventuali prossimi adattamenti dai PDF vanno trattati come bozze da rivedere; queste sono le versioni modificabili usate dal gioco.

## Collegamento ai livelli

`capitolo_01.json` usa `rooms.stages`, una mappa da ID a `{ "name": "Titolo", "notice": "Obiettivo" }`. I file `data/stage/` indicano questa chiave con `text_id`; spostare una stanza nella sequenza non richiede spostarne i testi. Le pagine sono collegate tramite `id`, nelle liste `interludes.before/after` del livello o `interludes_before` della missione. Le illustrazioni sono associate a `art` dal manifesto della missione. Guida: [livelli JSON](../../docs/livelli-json.md).

Livello e stage sono distinti: “La fuga dall’archivio” è un livello di tre stage, con un solo appunto iniziale e una scelta di potenziamento finale. La sequenza degli stage e la ricompensa sono in `data/livelli/fuga_archivio.json`.
