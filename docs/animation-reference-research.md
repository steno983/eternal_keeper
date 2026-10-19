# Riferimenti per rifare la locomozione — 18 ottobre 2026

L'utente ha respinto anche la corsa articolata v4: ricorda un cavallo al trotto.
Non considerare la correttezza dei vincoli IK o il numero di test come prova di
qualità visiva. Nessuna ulteriore modifica alla corsa durante questa ricerca.

## Fonti primarie verificate

- Animation Mentor, Jason Martinsen, “Animating Dynamic Run Cycles”:
  https://www.animationmentor.com/blog/animating-dynamic-run-cycles/
  Procedere da riferimento reale a pose principali, passaggi, curve e rifinitura.
  Studiare carico del peso, spinta, bacino, torace e movimento secondario insieme.
- Rusty Animator, “Run Cycle Step by Step”:
  https://rustyanimator.com/run-cycle/
  Mostra pose laterali e analizza contatto, abbassamento, passaggio, salita,
  controrotazione del busto e rifinitura di piedi e ginocchia.
- Clembod, “Warrior-Free Animation set V1.3”:
  https://clembod.itch.io/warrior-free-animation-set
  Riferimento concreto per un personaggio armato a scorrimento: corsa di 8 frame,
  attacco combo di 12, scatto e altri stati. La pagina consente uso personale,
  commerciale e modifica, ma vieta redistribuzione/rivendita dell'asset.
- rvros, “Animated Pixel Adventurer”:
  https://rvros.itch.io/animated-pixel-hero
  Include cammino, diverse corse, combattimento e sorgente Aseprite. La pagina
  consente uso personale/commerciale e modifica; vieta redistribuzione/rivendita.
- SEGA, trailer ufficiale Guardian Heroes:
  https://www.youtube.com/watch?v=lM73RYay5pc
  Riferimento dello stile richiesto dall'utente, non materiale da importare.
- Esoteric Software, esempio Spineboy:
  https://us.esotericsoftware.com/spine-examples-spineboy
  Alternativa per studiare un rig completo con bacino indipendente dai bersagli
  IK e animazioni sovrapposte; nessun acquisto o installazione proposto come
  soluzione automatica alla cattiva qualità delle pose.

## Diagnosi del nostro prototipo

Le gambe sono state mosse con una traiettoria matematica senza costruire prima
una prestazione convincente dell'intero corpo. Busto e braccia quasi immobili,
ginocchia molto sollevate e ritorni del piede regolari possono spiegare la
sensazione meccanica. Questa è una diagnosi del codice e delle catture locali,
non una conclusione attribuita alle fonti.

## Direzione consigliata

Ripartire da un solo eroe, Layla, in sagoma semplice: definire un ciclo laterale
di corsa leggero usando riferimenti reali e pose disegnate. Verificare il movimento
prima di applicare armatura, capelli, mantello o interpolazione. Per Tholgrin
adattare peso e ampiezza del passo; per Lupinor conservare una corsa controllata
con armi. Non moltiplicare il lavoro su tre eroi prima di validare un ciclo.

La ricerca ha selezionato pagine, tutorial e pacchetti; non ha importato asset,
acquistato software o corretto nuovamente le animazioni del gioco.
