# Percorsi di Tholgrin

Ogni ricompensa offre una trasformazione per ciascun percorso disponibile. Il percorso è visibile sulla carta insieme al beneficio che sarà attivo dopo la scelta. Le abilità già trasformate non vengono sostituite. La prima scelta di un percorso attiva il beneficio; la seconda lo porta al rango massimo 2. Altre scelte dello stesso percorso trasformano ancora la magia, senza superare il rango 2. Sono possibili combinazioni fra percorsi.

| Percorso | Trasformazioni | Rango 1 | Rango 2 |
| --- | --- | --- | --- |
| Braci | Sfera esplosiva, Eruzione, Sentiero infernale | Le magie applicano Bruciatura: 3 danni/s per 2 s | Bruciatura per 4 s |
| Custode | Santuario ardente, Scudo del giudizio, Preghiera vitale, Egida di Oghma | Scudo della fede aggiunge 12 assorbimento | Aggiunge 24 assorbimento |
| Sigilli | Lancia di fuoco, Triplice scintilla, Terra di cenere, Giudizio di fuoco, Nova sacra | Le magie rallentano del 35% per 1,5 s | Rallentano del 50% per 2,5 s |

La bruciatura si rinnova senza accumulare copie e non provoca stordimento o combo aggiuntive. I rallentamenti si rinnovano senza moltiplicarsi e modificano movimento e ritirata, senza accelerare o ritardare le animazioni di attacco. L’ingresso fuori schermo conserva la propria corsa. I danni della mazza e degli alleati non applicano questi effetti.

L’assorbimento del Custode si consuma prima della riduzione del 35% della benedizione base; Egida conserva invece la sua regola di assorbimento senza riduzione percentuale. Rilanciare lo scudo ripristina il valore previsto, senza sommare barriere.

Percorsi, colori, descrizioni e valori per rango sono in `data/testi/abilita.json`, sotto `build_paths`; ogni trasformazione ha il campo `path`. I nomi base delle magie restano visibili. Le etichette generiche sono in `data/testi/interfaccia.json`. Il riepilogo del percorso compare anche nel riquadro del mana durante il combattimento.

I percorsi durano per l’intera run; bruciature e rallentamenti sono temporanei, si fermano durante pausa e intermezzi e spariscono con i nemici dello stage. Una nuova run cancella tutti i percorsi. Nel capitolo attuale la prima scelta viene giocata nel secondo livello; la seconda arriva al termine del capitolo. La verifica automatica copre anche le combinazioni di due scelte, in preparazione ai livelli successivi.

Verifica: `tests/tholgrin_builds.gd` copre offerte, ranghi, danni nel tempo, assorbimento, movimento rallentato, combinazioni, pausa e reset. `tests/second_level_skills.gd` verifica ogni trasformazione e il suo percorso durante il passaggio reale al secondo livello e fra stage.
