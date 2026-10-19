# Layla — studio del corpo intero

L'utente ha autorizzato di ripartire da un solo ciclo in sagoma prima di vestire
il personaggio. La scena `scenes/animation_studio.tscn` contiene questo studio e
il confronto fra sagoma e parti grafiche. Si apre con F3 dalla demo o con
`Avvia-studio-corsa.cmd`. Dopo l'approvazione del movimento, la struttura è stata
vestita e applicata alla corsa dei tre eroi. Dettagli in `hero-run-skins.md`.

## Fonti usate

- https://rustyanimator.com/run-cycle/ — consultate visivamente le quattro
  pose laterali contact/down/passing/up del tutorial dell'autore.
- https://www.animationmentor.com/blog/animating-dynamic-run-cycles/ — workflow
  da riferimento a pose, passaggi e rifinitura dell'intero corpo.

Il movimento dello studio è disegnato con geometria nativa Godot. Nessuna
immagine o animazione del tutorial è copiata nel progetto.

## Modifica rispetto al prototipo respinto

Otto pose del corpo intero specificano inclinazioni di coscia, tibia, piede,
busto, braccio e avambraccio. Le ginocchia e il tallone seguono i passaggi
anatomici delle pose; non sono risolti a partire da un piede che percorre una
semicirconferenza. Le gambe scambiano il ruolo a metà ciclo; le braccia si muovono
in opposizione. La coda di capelli ha un ritardo lieve.

Il ciclo dura 0,70 secondi (circa 2,86 passi al secondo), contro circa 0,48
secondi del precedente rig alla velocità di gioco di Layla. Il busto scende
durante l'assorbimento e risale per la spinta. Una piccola correzione verticale
del corpo conserva il contatto della suola senza allungare le ossa.

## Controlli

- Spazio o pulsante: pausa/riprendi.
- Frecce o pulsanti: un fotogramma avanti/indietro a 24 fps.
- Cursore: esplorazione continua del ciclo.
- Pulsanti: velocità reale, metà e un quarto.
- B: mostra articolazioni; S: sagoma monocromatica.
- Esc o pulsante: ritorno alla demo.

`tests/layla_study.gd` verifica pose ai tempi corretti, assorbimento e spinta,
scambio delle gambe, lunghezze costanti, suolo, continuità e controlli di lettura.
`tests/capture_layla_study.gd` cattura due cicli a 60 Hz dal renderer Godot.
La qualità del movimento resta una valutazione visiva; i test non la certificano.
