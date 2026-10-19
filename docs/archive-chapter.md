# Capitolo 1 — La fuga dall’archivio

Prima trasposizione giocabile delle sessioni 1 e 2. Il titolo avvia il capitolo; **B**, dal titolo, conserva l’arena sperimentale del ponte.

## Percorso

0. Introduzione su pergamena a scorrimento: tre protagonisti, invito a Neverwinter, incontro con i Custodi e attacco. Si può fermare, rileggere o saltare. Invio/clic/Esc porta alla prima vignetta con Corvin; alla fine dello scorrimento il gioco attende un comando.

1. Fumetto: Corvin aiuta il gruppo, lo specchio rivela l’accesso all’archivio. Daleal consegna chiave e rapporti; la data rivela quattro anni mancanti.
2. **Le scale dell’archivio:** percorrere l’archivio e liberare tre gruppi di guardie mentre Layla cerca il passaggio, proteggendo la ritirata con i rapporti già ricevuti. Non è necessario uccidere tutti. L’eco di Lupinor colpisce periodicamente gli inseguitori presso le scale.
3. Fumetto: Layla individua il meccanismo del passaggio.
4. **Il passaggio segreto — RESISTENZA:** sopravvivere 25 secondi mentre Layla apre la porta. Tholgrin rimane fermo orizzontalmente al centro della scena. Quattro ondate iniziano ai secondi 0/6/12/17 e alternano guardie, assaltatori veloci e balestrieri. Gli ingressi sono sfalsati e anticipati di 1,2 secondi da segnali di lato, corsia e ruolo; i dieci nemici arrivano in totale cinque per lato. A/D cambia il verso, W/S cambia corsia, Spazio schiva sul posto. La telecamera resta ferma. La barra mostra l’avanzamento e il timer diventa rosso negli ultimi cinque secondi. Non occorre eliminare tutti gli inseguitori.
5. Fumetto: l’uscita si apre, l’eco copre la ritirata.
6. **La via di fuga:** raggiungere il varco a destra sulla corsia centrale. Gli inseguitori possono rimanere vivi.
7. Fumetto: attraversamento del fiume e stanza privata allo **Scudo Infrangibile**, nel Chasm. I rapporti NO-1 suggeriscono missioni dimenticate.
8. Scelta di una trasformazione della magia al tavolo della locanda, con tutti e tre gli eroi. Riposo una sola volta: +20 salute, +30 mana. La scelta porta il personaggio al livello 10 e avvia la ricostruzione del rapporto 217-A nel secondo livello, conservando la magia trasformata.

**Dialoghi sempre manuali:** Invio, Spazio o clic rivela la battuta successiva; dopo la terza battuta continua. Esc salta soltanto la pagina corrente. Nessun timer passa al dialogo successivo. Pausa e aiuto fermano combattimento e obiettivi.

## Fedeltà e adattamento

Fonti: `docs/sessioni/D&D i Custodi dell'Eterno - Sessione 1.pdf` e `Sessione 2.pdf`.

Sono fatti delle sessioni: Corvin alleato, specchio e arredi, archivio sotterraneo, sacca, Daleal anziano e robusto, chiave, data 4 Alturiak 1495, rapporti personali, Layla all’uscita, eco sulle scale, fuga sul retro, fiume, locanda, gruppo NO-1 e rapporti dimenticati. Le battute sono adattamenti, non citazioni.

Durata degli obiettivi, numero delle guardie, divisione in tre arene, regole della resistenza e danni periodici dell’eco sono adattamenti ludici. I combattenti riutilizzano gli sprite di guardie del prototipo. Daleal è rappresentato nelle vignette; la ricerca del passaggio in combattimento è indicata dall’obiettivo. Nessun boss è aggiunto a questa fuga.

Il luogo sicuro sostituisce l’accampamento al ponte per la scelta della benedizione. La ricompensa finale anticipa il sistema di crescita: la scelta ora avvia il secondo livello sull’Orologio, descritto in [orologio-level.md](orologio-level.md).

L’Orologio di Thultanthar rimane una pista per le successive ricostruzioni roguelite: sincronizza cicli magici, non è una macchina del tempo. Non vengono inventate spiegazioni della memoria perduta, risolte incongruenze di data o rivelate parti censurate dei rapporti. Il segreto di Layla rimane nascosto. L’incontro successivo con i Custodi alla locanda e la Casa della Conoscenza rimangono per un prossimo segmento.

## Verifica

`tests/archive_chapter.gd`: avanzamento manuale, congelamento dei timer, obiettivi che non dipendono dalle uccisioni, blocco orizzontale, ondate bilaterali, timer di resistenza, riposo singolo, scelta e riavvio.

`tests/archive_playthrough.gd`: percorso completo con salute, danni e mana normali; schermate del gioco, dialoghi con Invio e selezione con clic.

`assets/archive/provenance.json`: sorgenti e prompt delle illustrazioni. Originali conservati in `assets/archive/sources`.

## Testi modificabili

Tutti i testi del capitolo sono in `data/testi/capitolo_01.json`; interfaccia, abilità e ponte hanno JSON dedicati. Guida: `data/testi/LEGGIMI.md`. I file vengono riletti quando inizia una nuova partita e non vengono rigenerati dai PDF. `tools/check_texts.py` controlla sintassi, riferimenti e segnaposto senza modificare i contenuti.

Gli ambienti giocabili mantengono il vincolo grafite bianco e nero su pergamena e quattro livelli di parallasse; dettagli e verifica in `docs/pencil-implementation.md`.

La configurazione delle tipologie di stanza è nei file `data/stage/archivio_*.json`, ordinati da `data/missioni/archivio.json`. Il secondo ambiente usa `resistance`; gli altri restano difesa mobile e fuga. Questo permette di riutilizzare la resistenza nei livelli futuri senza bloccare globalmente i movimenti.

Le composizioni delle ondate e i profili dei nemici sono in `data/stage/archivio_passaggio.json`; nomi delle ondate e testi dei segnali restano nei JSON di `data/testi`. `tests/resistance_waves.gd` verifica il preavviso, gli ingressi sfalsati, le corsie annunciate, la pausa e l’assenza di duplicati.

Gli ingressi di guardie e rinforzi nella fuga rispettano un margine minimo dal personaggio. I dardi dei balestrieri nascono alla punta dell’arma nel fotogramma di rilascio, hanno punta metallica, impennaggio e una breve scia d’inchiostro; danni e velocità restano invariati. Verifica: `tests/escape_and_bolts.gd`; immagini di rilascio e volo nelle due direzioni in `artifacts/crossbow-*.png`.

## Sistema comune dei livelli

Missione, stanze, ambienti e collegamenti narrativi sono ora separati in JSON. Il secondo livello sull’Orologio è ora collegato dopo la prima ricompensa. Guida: [livelli JSON](livelli-json.md). Il vecchio file `data/stanze/archivio.json` non contiene più regole duplicate.

Livello e stage sono distinti: “La fuga dall’archivio” è un livello di tre stage, con un solo appunto iniziale e una scelta di potenziamento finale. La sequenza degli stage e la ricompensa sono in `data/livelli/fuga_archivio.json`.

Verifica aggiornata: la partita completa attraversa due livelli e sei stage; la prima scelta rimane attiva nel secondo livello e il riepilogo mostra due benedizioni.

## Revisione dell’avanzamento

Le scale dell’archivio sono ora un percorso di 4.200 unità con tre incontri, la fuga arriva al varco a 3.350 lungo un corridoio di 3.600 unità. Soltanto il passaggio segreto resta statico a tempo. Ogni obiettivo mostra prima un messaggio di completamento, poi il fumetto. Vedere [brawler-stages.md](brawler-stages.md) per le regole aggiornate, che prevalgono sui vecchi valori di durata sopra riportati.
