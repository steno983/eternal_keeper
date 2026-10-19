# Stage più lunghi, avanzamento e varietà dei nemici

Questa revisione sostituisce le arene mobili concluse a tempo con percorsi a scorrimento. La scelta del potenziamento rimane alla fine del **livello**, dopo il suo gruppo di stage.

| Stage | Tipo | Lunghezza logica | Conclusione |
| --- | --- | ---: | --- |
| Le scale dell’archivio | scrolling | 4.200 | Tre scontri e varco a 4.000 |
| Il passaggio segreto | resistance | 1.500 | Unica resistenza statica, 25 secondi |
| La via di fuga | escape | 3.600 | Uscita a 3.350, senza obbligo di eliminare tutti |
| La discesa di Tantras | scrolling | 6.200 | Quattro scontri e varco a 6.000 |
| La galleria dei sigilli | scrolling | 5.000 | Tre scontri e varco a 4.800 |
| La camera dei cicli | synchronization | 3.600 | Tre sigilli accordati, poi uscita a 3.350 |

Le lunghezze sono coordinate di gioco, non pixel della finestra. La camera segue il protagonista attraverso più schermate. Le pulsazioni della camera dei cicli sono pericoli periodici: non sono un conto alla rovescia per la fine dello stage.

## Incontri lungo il percorso

`scrolling` usa `encounters`: ogni incontro ha `at_x`, `gate_x` e una composizione finita `entries`. Gli avversari vengono annunciati con lato, corsia e ruolo; non appaiono istantaneamente. L’incontro parte quando il protagonista raggiunge il punto del percorso, non perché è trascorso un certo numero di secondi.

Il protagonista resta libero lungo tutto il percorso, anche durante i preavvisi. I nemici partono completamente fuori dall’inquadratura sul lato annunciato ed entrano correndo. `gate_x` rimane nel formato dei dati per compatibilità, ma non impone più un muro invisibile.

Per completare lo stage occorre eliminare tutti i gruppi finiti e raggiungere il varco. Il gruppo non viene rigenerato. Nei percorsi a scorrimento e nella camera dei cicli vale qualsiasi corsia (`exit.lane: -1`); la fuga conserva la corsia centrale indicata. Non ci sono rinforzi infiniti o attese di un timer per far finire gli stage mobili.

## Cinque ruoli

I profili condivisi sono in `data/nemici/archetipi.json`.

- **Guardia:** mischia ordinaria, pressione frontale.
- **Assaltatore:** meno salute, maggiore velocità; costringe a reagire rapidamente e a controllare i lati.
- **Balestriere:** mantiene distanza e spara dardi fisici dall’arma.
- **Bruto:** silhouette della grande armatura, movimento lento, preparazione lunga e fendente ampio che minaccia anche la corsia adiacente. Non è un boss e non usa la barra da boss.
- **Arcanista:** nuovo sprite completo con maschera, veste viola e bastone. Prepara un sortilegio su una posizione del terreno, annunciata da un segno; il bersaglio non segue il giocatore dopo la preparazione. Spostarsi o cambiare corsia evita l’impatto.

Gli attacchi mantengono il limite dei due nemici impegnati contemporaneamente. Il ritiro dei tiratori termina quando raggiungono il bordo dell’arena, permettendo loro di tornare ad attaccare invece di rimanere bloccati nel tentativo di arretrare.

Il nuovo arcanista usa sedici disegni interi, normalizzati con scala e base comuni in `tools/build_caster_assets.py`. Non ci sono ricomposizioni di arti. Gli altri ruoli riutilizzano le animazioni approvate, con differenze di comportamento e silhouette. Prompt e sorgenti: `assets/pencil/enemy_3-provenance.json`.

## Fine stage e intermezzi

Il raggiungimento dell’obiettivo apre la fase `stage_clear`: pennellata d’inchiostro con “STAGE COMPLETATO” e nome dello stage. Per 1,65 secondi azioni, nemici, cooldown e obiettivi sono fermi. Poi si apre il fumetto manuale collegato; le ricompense vengono preparate una sola volta soltanto a fine livello.

Invio/clic può proseguire dopo 0,35 secondi; pausa e aiuto fermano anche questa transizione. Una nuova pagina a tre vignette segue ciascuno dei due stage mobili iniziali dell’Orologio. Le vignette illustrano sigillo e accesso alla camera, senza aggiungere spiegazioni della memoria perduta. Sorgente e prompt: `assets/orologio/route-comics-provenance.json`; preparazione riproducibile in `tools/build_route_comics.py`.

## Parallasse sul percorso lungo

I quattro piani mantengono i rapporti 0.12 / 0.48 / 1.0 / 1.22. Pavimento e architetture coprono l’intera lunghezza; le colonne intermedie e in primo piano si ripetono con un proprio passo. L’allungamento non si limita a ingrandire una singola immagine o a lasciare lo scenario vuoto dopo la prima arena. Rimane il bianco e nero della scenografia, con personaggi ed effetti a colori.

## Verifica

- `tests/brawler_flow.gd`: incontri legati all’avanzamento, ingressi sicuri, limiti provvisori, assenza di completamento a tempo, uscita fisica, messaggio prima del fumetto, pausa e nuovi attacchi nemici.
- `tests/second_level_skills.gd`: tutte le trasformazioni restano attive attraverso i percorsi e le due ricompense.
- `tests/archive_playthrough.gd`: attraversamento dei sei stage con salute e risorse normali; messaggi di fine stage, intermezzi e magia trasformata utilizzata nel secondo livello.
- `tests/orologio_scenery.gd`: profondità dei piani, terreno solidale alla camera e primo piano davanti alla scena.

Gli incontri sono adattamenti ludici dei rapporti. Non introducono nuovi fatti canonici sui Custodi o sui misteri della campagna.

## Ingressi e sincronizzazione
Il preavviso non impone limiti orizzontali al protagonista. Gli incontri mobili richiedono comunque di sconfiggere i gruppi per completare la stanza. Tutti i rinforzi vengono creati oltre il bordo effettivo della telecamera, con 230 unità di margine per lo sprite, ed entrano correndo senza attaccare finché non sono visibili. Durante l’ingresso non vengono riportati dentro i confini con uno spostamento istantaneo.
I sigilli mostrano una zona chiara larga quanto il raggio utile, numero, freccia e cartellino accanto alla zona con barra individuale; il pannello indica corsia, direzione e percentuale del sigillo più vicino ancora da completare.
