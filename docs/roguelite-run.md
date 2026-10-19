# Run di Tholgrin — prima prova

Aggiornamento magie: [sprite, nomi 2024, livelli e ricariche](magic-presentation.md). Le ricariche della tabella sono quelle base del livello 9, prima dei modificatori di mutazioni e Scudo della fede.

La simulazione vive in `scripts/pilgrim_run.gd`, collegata agli eventi e ai contatti di `arena.gd`. Il painter visualizza le risorse senza governare i danni. Pause, aiuto e ricompense sospendono i tempi del combattimento.

## Percorso

Titolo → selezione → stanza 1 (3 nemici) → scelta → stanza 2 (4) → scelta → stanza 3 (5) → scelta → boss con 2 scorte → vittoria. Alla morte si riparte senza build. Nessuna resurrezione o cambio eroe. Ogni ricompensa offre tre carte distinte; dà priorità a slot differenti ancora non trasformati. All’ultima scelta possono esserci due alternative per lo stesso slot. Ogni slot può essere trasformato una volta per run.

## Magie e trasformazioni

| Slot | Base | Alternative |
|---|---|---|
| K | Dardo tracciante: 24 danni, 8 mana, 0,65 s | Sfera: esplosione 18 danni / Lancia: perfora 3 nemici, 34 danni / Triplice: tre corsie, 20 danni, 12 mana |
| L | Muro di fuoco: 11 danni ogni 0,5 s, raggio 135, durata 3 s; 24 mana, 5 s | Cenere: raggio 185 e 5 s / Santuario: cura 8 al secondo dentro la zona / Eruzione: sostituisce la zona con 75 danni immediati, raggio 190 |
| U | Scudo della fede: 5 s, riduce i danni del 35%, mana 11/s; 18 mana, 9 s | Giudizio: restituisce 20 danni entro 180 / Vitale: cura 4/s / Egida: sostituisce gli effetti con 45 assorbimento per 8 s |
| I | Colpo infuocato: 50 danni sulla corsia entro 620; 36 mana, 10 s | Giudizio: tre corsie, 45 danni / Infernale: tre zone da 4 s / Nova: 70 danni in ogni direzione, tre corsie entro 320 |

Mana massimo 100, rigenerazione base 5/s. J recupera 10 per attacco che trova almeno un bersaglio (non per ogni bersaglio). Le magie consumano al lancio e risolvono al contatto; un’interruzione prima del contatto perde la magia. Le ricariche azzerate alla nuova stanza rendono subito disponibili le nuove trasformazioni.

## Alleati e Intesa

I tre ritratti e battute provvisorie appaiono negli intermezzi. La barra Intesa parte da zero: danno effettivo inflitto ×0,11 e danno subito ×0,25; massimo 100. Niente carica dall’overkill, dai nemici morti o dagli attacchi della stessa Intesa.

V a 60–99: Layla entra, 45 danni sulla corsia, Tholgrin conclude con 35. V a 100: Layla 45 + Lupinor 55 + Tholgrin 65 su tutte le corsie. Portata 850 nella direzione scelta, interventi a 0,18/0,40/0,62 s. Si consuma l’intera barra, un secondo di invulnerabilità consente di vedere l’intervento. Gli alleati sono figure intere della libreria a matita e compaiono vicino al protagonista.

## Convalida

`tests/run_rules.gd`: controlli diretti delle regole, comprese tutte le 12 trasformazioni. `tests/run_playthrough.gd`: bot su tre build, senza modifiche artificiali al combattimento. `tests/run_visual_tour.gd`: input reali e catture; forza solo il passaggio all’intermezzo e la carica per mostrare quelle schermate. I vecchi test del party swap sono storici.

Il bilanciamento è iniziale. Gli ambienti condividono ancora il bioma del ponte. Le run di Layla e Lupinor e la progressione permanente non fanno parte di questa iterazione.
