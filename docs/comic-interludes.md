# Intermezzi a fumetto e accampamento sul ponte

## Flusso

La conclusione delle stanze 1–3 passa a `interlude`, prepara le tre ricompense e applica una volta sola il riposo. Il combattimento è sospeso. Prima battuta visibile subito; tutte le successive richiedono un input. Nessun avanzamento automatico. Invio, Spazio, clic o Start rivelano la prossima battuta. Quando sono tutte visibili, un altro input apre `reward`. Esc/Back salta direttamente a `reward`, senza scegliere una carta o avanzare alla stanza seguente. Aprire F1 sospende anche il tempo di comparsa dei balloon.

Nel campo sono necessarie le stesse tre scelte della run: 1/2/3, clic oppure sinistra/destra + Start. Le immagini dei buff restano identiche a quelle nel HUD. La selezione applica il potenziamento, incrementa il livello e avvia il prossimo combattimento. Il boss finale porta direttamente alla vittoria.

## Illustrazioni

Tre pagine statiche, ognuna di tre vignette, e un’illustrazione completa dell’accampamento del ponte. Tutti e tre gli eroi sono presenti. Il falò è sulla pavimentazione del ponte; parapetti rotti, abbazia e montagne riprendono lo stage attuale. Le carte sono spostate nella metà inferiore per lasciare visibili personaggi e fiamme. Nessuna animazione dell’immagine, nessuna lettera o balloon incorporato nel raster.

Le immagini sono state generate con imagegen integrato usando `artifacts/run-title.png` soltanto come riferimento di personaggi, ambiente e stile. I prompt completi sono in `assets/interludes/provenance.json`; originali in `assets/interludes/sources/`. `tools/build_interlude_assets.py` conserva i sorgenti e divide le tavole lungo i separatori d’inchiostro effettivi, perché le vignette generate non hanno larghezze perfettamente uguali. Le immagini dei pannelli sono caricate una volta; testi e balloon sono disegnati da Godot.

## Scrittura

`scripts/interlude_story.gd` contiene titoli, parlanti, nove battute e posizioni delle code dei balloon. Tutti i testi sono provvisori: brevi pause sul ponte e preparazione allo scontro finale. Non incorporano eventi della campagna ancora non forniti.

## Verifiche

- `tests/interlude_flow.gd`: 44/44, compresi congelamento, aiuto, ordine fumetto → campo → scelta → incontro, niente selezione attraverso la pagina, riposo non duplicato e reset.
- `tests/run_rules.gd`: 74/74.
- `tests/run_playthrough.gd`: tre build arrivate alla vittoria; il bot avanza esplicitamente le battute e sceglie le ricompense.
- `tests/run_visual_tour.gd`: percorso con tastiera attraverso fumetto, accampamento e stanza successiva.
- `tests/capture_interludes.gd`: catture delle tre pagine complete e del campo per ogni stanza; verifica degli input nativi Esc e clic sulla carta.

Artefatti: `artifacts/comic-1-complete.png`, `comic-2-complete.png`, `comic-3-complete.png`, `camp-1-reward.png` e gli equivalenti delle altre stanze. Le catture di presentazione forzano solo la conclusione della stanza; la completabilità è verificata separatamente dal bot di combattimento.
