# Versione giocabile a matita

La direzione del concept pencil-style-concept.png è ora implementata nel gioco,
non come immagine di sfondo con personaggi già incorporati. Le parti del mondo,
i combattenti, gli effetti e l’interfaccia sono separati e interattivi.

## Grafica

Nuove illustrazioni generate in stile grafite su carta avorio. Tutti i sei tipi
di combattente hanno 24 disegni a figura intera: guardia, difesa, distanza,
ferita, otto pose di corsa e tre attacchi con quattro pose ciascuno. Corpi e
armi non vengono più ricomposti dai ritagli del precedente scheletro.
L’isolamento dei soggetti, la scala uniforme per personaggio e il margine per
le pose con arma estesa vengono controllati prima dell’importazione.

Paesaggio montano e abbazia, arco in rovina, balaustre, pavimentazione e braciere
sono nuovi elementi distinti. Scorrono a profondità diverse, con stormo e
fulmini disegnati. La vegetazione e le pietre appartengono alle illustrazioni,
non agli sprite dei personaggi. L’interfaccia usa riquadri, ritratti, testo
nativo e salute tratteggiata, mantenendo i comandi già verificati.

Il colore è limitato soprattutto ad arancio, viola e turchese per distinguere
gli eroi e gli effetti. Menu iniziale, pausa, guida e riepilogo seguono la
stessa palette. Nessuna tabella di statistiche aggiunge regole D&D alla demo.

## Animazione e limiti del campione

Questa prima versione usa otto pose di corsa e quattro per attacco, con tempi
di contatto conservati. Gli intermedi automatici provati sono stati scartati
perché deformavano arti e armi: il runtime carica soltanto i disegni interi.
Il risultato ha un movimento a pose, da illustrazione animata; la fluidità è
ancora da rifinire con ulteriori disegni coerenti. Non è animazione finale
realizzata fisicamente a mano. I vecchi sprite e scheletri restano nel progetto
come archivio, ma non sono usati nella presentazione giocabile.

F3 (o Avvia-studio-corsa.cmd) apre il taccuino: sei personaggi, corsa, tre
attacchi, distanza, pausa, rallentatore e avanzamento per fotogramma. ESC torna
al gioco.

## File e verifiche

- scripts/pencil_actor.gd: campionamento dei disegni con gli orologi della simulazione.
- scripts/pencil_painter.gd: scenario, effetti e interfaccia.
- scripts/pencil_bank.gd: risorse SpriteFrames native.
- assets/pencil: atlanti, risorse, ritratti, sorgenti e provenance.json.
- tools/build_pencil_assets.py: ricostruzione deterministica degli atlanti.

Verifiche superate: pencil_art 165/165, animation_timing 164/164,
combat_smoke 30/30, combat_depth 43/43, hero_skins 33/33,
enemy_skins 24/24; visual_tour nativa senza errori di input. Il percorso completo
raggiunge ancora la vittoria con salute e danni normali. Catture reali Godot:
artifacts/pencil-gameplay.png, artifacts/miniboss-combat.png, artifacts/title.png.

I prompt e le sorgenti sono conservati: lo stile simula un disegno a matita,
le immagini non sono scansioni di disegni eseguiti manualmente su carta.

## Ink accents
The pencil painter now draws deterministic brush silhouettes around HUD cards, command panels and primary buttons. Angled dark keycaps retain fixed text and unchanged interaction rectangles. Sparse ink flecks frame the outer corners; the bottom HUD has a broken brush edge. Heavy impact effects and hero swaps add short, event-bound ink splashes. Reduced motion uses fixed splash scale with fading only. No new textures or external dependencies were added.
Validation: combat_smoke 30/30 and visual_tour 14 input checks passed; title, combat, pause and help captures inspected for rendering and legibility.

Super banner revision: pooled organic ink, larger detached drops, four-degree tilt and a 0.32-second horizontal clipping reveal (ink and lettering together, no entry fade). Global splatter drops now vary in size with occasional tapered tails. The banner hides during help/pause; reduced motion reveals the complete shape immediately. Captured early/middle/full/exit stages in artifacts/ink-reveal-*.png; reveal width, reduced motion and pause checks passed. Visual input tour: 14 checks passed.

Typography: Black Chancery from DaFont now supplies display titles, hero names and mixed-case super names. Caveat (official Google Fonts source, OFL 1.1, weight 600) supplies selected short notes and ability descriptions. UI controls and health numbers retain the existing font. Sources and author/license files are retained in assets/fonts. Existing super animation timings are unchanged. Visual tour: 14 checks passed; title, combat and help captures inspected.

## Current gameplay: Tholgrin run
The active demo now uses scripts/pilgrim_run.gd for a single-protagonist run: three reward rooms followed by a boss. Four spells, mana, twelve mutually exclusive slot transformations, party dialogue intermissions and a charged duo/trio attack replace combat switching. The pencil atlas and whole-figure animation pipeline remain in use. See docs/roguelite-run.md and the current README for rules and controls. Validation: run_rules 71/71, pencil_art 165/165, three automated full runs reached victory with different builds, and run_visual_tour passed. Previous party-switch test counts above describe historical iterations.


Magic presentation now uses dedicated generated sprite sequences (aura/flame startup and loops, projectile and impact), shared illustrated icons and grey-to-color cooldown meters. See docs/magic-presentation.md for source rules, prompts, level scaling, timing and validation.


Bridge intermissions now use three static comic pages with sequential native speech balloons, followed by rewards over an illustrated three-hero bridge campfire. Art sources and prompts: assets/interludes/provenance.json. Flow, controls and validation: docs/comic-interludes.md.


## Vincolo permanente: sfondi monocromatici e parallasse

Gli ambienti di combattimento devono restare disegni in grafite/inchiostro bianco e nero su carta chiara. I colori di eroi, nemici, magie, indicatori e HUD servono alla leggibilità. Le nuove stanze non devono sostituire questo stile con fondali colorati né appiattire il parallasse in un’unica immagine mobile.

Il capitolo dell’archivio usa `archive_scenery.gd`, separato da personaggi ed effetti. Il materiale `assets/archive/graphite.gdshader` porta ogni texture del fondale alla stessa scala grafite/carta, senza desaturare i combattenti. Le sorgenti illustrate restano conservate.

Quattro piani reali seguono la telecamera con fattori distinti: fondale 0,12; architetture 0,48; pavimento 1,00; pietra in primo piano 1,22. Le colonne usano regioni delle texture a matita già esistenti. Non sono fasce ritagliate dallo stesso fondale che trascinano con sé porzioni di pavimento. Il primo piano viene disegnato dopo i combattenti e prima dell’HUD; rimane ai bordi del campo.

Verifica grafica: `tests/archive_scenery.gd` confronta immagini a due posizioni della camera, verifica la palette del fondale e il movimento del pavimento, e controlla che personaggi ed effetti siano fuori dal materiale monocromatico. Immagini: `artifacts/scenery-game-left.png` e `scenery-game-right.png`.
