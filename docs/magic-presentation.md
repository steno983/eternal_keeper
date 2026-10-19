# Magie illustrate e ricariche

## Kit del chierico della Luce

I nomi sono quelli di incantesimi presenti nel kit del chierico / Dominio della Luce 2024. La simulazione resta un adattamento action: mana, cooldown, geometrie, durata dei buff e trasformazioni non riproducono il regolamento a turni.

| Tasto | Nome nel gioco | Riferimento inglese | Lettura visiva |
|---|---|---|---|
| K | Dardo tracciante | Guiding Bolt, chierico | Cometa di luce e fuoco con scia, impatto illustrato |
| L | Muro di fuoco | Wall of Fire, Dominio della Luce dal livello 7 | Rune, pozza e colonne che salgono; verde nelle varianti curative |
| U | Scudo della fede | Shield of Faith, chierico | Aura dorata a pennellate, centro libero, nascita dai piedi |
| I | Colpo infuocato | Flame Strike, Dominio della Luce dal livello 9 | Colonne di fiamma e luce, esplosione nelle varianti nova |

Triplice scintilla mantiene l’identità di potenziamento ma il nome della magia nel HUD diventa Raggio rovente (Scorching Ray, anch’esso nel dominio 2024). Gli altri nomi di carte sono mutazioni della run e non vengono presentati come nomi ufficiali di nuovi incantesimi.

Fonti verificate il 19 ottobre 2026:
- [Dominio della Luce, Player’s Handbook 2024, compendio autorizzato Roll20](https://roll20.net/compendium/dnd5e/Subclasses%3ALight%20Domain?expansion=32231&iframe=true)
- [Dardo tracciante / Guiding Bolt, D&D Beyond](https://www.dndbeyond.com/spells/2619136-guiding-bolt)
- [Scudo della fede / Shield of Faith, D&D Beyond](https://www.dndbeyond.com/spells/2619020-shield-of-faith)
- [Descrizioni degli incantesimi, regole gratuite 2024](https://www.dndbeyond.com/sources/dnd/br-2024/spell-descriptions)
- [Terminologia italiana SRD 5.1, Wizards of the Coast](https://media.wizards.com/2023/downloads/dnd/SRD_CC_v5.1_IT.pdf) per i nomi italiani storici, non per determinare le regole 2024.

## Livelli e ricariche della demo

Partenza al livello 9, poi 10, 11, 12 dopo le tre stanze. Ricariche base 0,65 / 5 / 9 / 10 s. Il fattore livello è 1 - 0,06 × (livello - 9), minimo 0,55. Le mutazioni moltiplicano la ricarica: orb 1,35; pierce 1,20; fan 1,50; ash 1,15; sanctuary 1,25; eruption 1,35; mirror 1,10; renewal 1,15; aegis 1,25; judgment 1,35; inferno 1,25; nova 1,40. Scudo della fede attivo applica 0,88 alle altre magie al lancio, salvo Egida. Minimo assoluto 0,3 s.

Ogni lancio salva la durata effettiva della propria ricarica: il contatore e il riempimento usano la stessa durata e non saltano quando finisce il buff. Le carte di fine stanza mostrano il confronto attuale → nuovo includendo livello e mutazione, senza buff temporanei che scadranno prima della stanza successiva.

## Produzione delle immagini

Set generato con imagegen integrato: aura, aura_birth, flame, flame_birth, projectile, impact e quattro icone. Prompt completi, sorgenti originali e note di preparazione in `assets/magic/provenance.json` e `assets/magic/sources/`. Il preparatore taglia la griglia 4×2, preserva l’alfa, normalizza la scala per sequenza e allinea i piedi a y=480. Non ingrandisce ogni fotogramma alla stessa altezza: i primi frame restano pozze basse. Icone in griglia 2×2, normalizzate a 128×128 con copie grigie per la ricarica.

`magic_bank.gd` conserva gli AtlasTexture in SpriteFrames. Nascita: 8 disegni a 18 fps (0,44 s); ciclo: 8 disegni a 12 fps. Sotto movimento ridotto la nascita conserva le fasi, poi il ciclo si ferma. Tutti i tempi vengono dalla simulazione: pausa, aiuto e ricompense congelano anche le magie. Nessun nuovo scuotimento o lampo a pieno schermo.

## Verifiche

85 controlli in `tests/magic_feedback.gd`; 71 regole di combattimento in `tests/run_rules.gd`; tre completamenti automatici con build diverse in `tests/run_playthrough.gd`. `tests/ability_visual_tour.gd` cattura tutte le varianti e i passaggi pozza → salita → piena altezza su bersagli di prova. `tests/run_visual_tour.gd` verifica selezione, input, ricompensa, alleati, pausa e guida nel rendering nativo.
