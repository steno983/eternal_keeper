# Nemici e presentazione della demo

Predone, balestriere e custode usano nove parti dipinte ciascuno, con metallo
scuro, dettagli luminosi e stoffa bordeaux. Sorgenti, prompt e riferimenti sono
in assets/*_skin. Le parti vengono isolate per componente con alpha verificato.
I vecchi SpriteFrames restano disponibili come fallback se manca un kit.

Il renderer enemy_skin.gd usa la stessa struttura articolata degli eroi, con
profili di massa e cadenza propri. Tutti gli stati mantengono la stessa identità:
fermo, corsa, preparazione, attacco, ferita e caduta. Polso e impugnatura hanno
punti dipinti distinti per arma. Il balestriere mira senza fare la carica di un
attacco corpo a corpo. Il danno continua a dipendere dagli eventi della
simulazione, non dal numero di fotogrammi.

La camera ingrandisce il mondo del 24%, preservando le tre corsie e la scala
dell’interfaccia. Personaggi, fondale ed effetti condividono la trasformazione.
Nuvole lontane e vicine scorrono a velocità distinte, insieme a un ulteriore
strato di guglie nella foschia. Uno stormo attraversa il cielo; un fulmine breve
compare ogni tredici secondi (escluso con movimento ridotto).

I colpi generano più scintille, raggi e anelli di impatto nel colore dell’eroe;
le scie dei fendenti hanno una fascia piena rastremata. Non è stata aumentata
la pausa dei colpi o la vibrazione della camera.

Verifica: enemy_skins 99/99, combat_smoke 30/30, animation_timing 116/116;
visual_tour completa senza errori negli input. Catture native in
artifacts/enemy-skin-frames e artifacts/enemies-and-presentation.png.
