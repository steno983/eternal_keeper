# Combattimento e incontro completo

I tre eroi usano le parti articolate anche da fermi, in attacco, durante
speciali e attacchi a distanza, in parata, schivata e ferita. Le pose usano gli
stessi punti dipinti della corsa approvata. Le impugnature seguono i polsi.
I vecchi SpriteFrames restano come fallback e sorgenti storiche; il normale
combattimento non cambia più modello del personaggio.

J esegue una sequenza di tre attacchi con preparazioni e traiettorie distinte.
Il terzo colpo infligge il 165% del danno e provoca uno stordimento pesante.
La sequenza dipende dagli attacchi, non dal numero di nemici colpiti insieme.
Scade dopo 1,05 secondi senza una nuova azione. La coda di input viene consumata
solo quando l’attacco parte; il successivo può iniziare all’82% del precedente.
I tempi di contatto originari restano 34% / 24% / 34% per i tre eroi.

Dopo un colpo riuscito, cambiare eroe durante il seguito dell’attacco apre un
ingresso speciale (ricarica 1,2 s): Tholgrin protegge e interrompe, Layla avanza
con un affondo, Lupinor manifesta un’eco per due secondi. Il cambio neutro resta
sempre disponibile rispettando la breve attesa di cambio e non rigenera salute.
L’interfaccia segnala la finestra utile. La simulazione annulla i colpi in corso
quando schivata, ferita o cambio sostituiscono l’azione.

I nemici impegnano al massimo due attacchi contemporanei; il balestriere cerca
spazio se viene raggiunto. Il custode alterna un fendente sulla propria corsia
e una spazzata che raggiunge le corsie adiacenti. Le zone sono mostrate a terra
prima del danno; barra del boss e testo descrivono come reagire. Sotto metà
salute il custode prepara gli attacchi più rapidamente. Tre colpi ravvicinati
o un finale pesante possono interromperlo; segue una protezione di 2,4 secondi
contro interruzioni ripetute, senza impedire di danneggiarlo.

Il percorso contiene due scontri (5 e 6 nemici), avanzamento e un incontro
finale con custode da 420 salute e due accompagnatori. Vittoria e sconfitta
chiudono la demo; il riepilogo mostra durata e avversari sconfitti. È una sezione
tecnica breve da bilanciare con prove umane, non un livello già tarato a cinque
minuti. Mancano ancora la storia della campagna e le animazioni finali disegnate
fotogramma per fotogramma.

Verifiche: combat_depth 43/43; combat_smoke 30/30; animation_timing 116/116;
hero_skins 33/33; enemy_skins 99/99; rig_bindings 168/168. Visual tour nativa:
avvio, attacchi, abilità, cambio corsia, cambio eroe, schivata, pausa e riavvio.
Il bot deterministico completa il percorso partendo da ognuno dei tre eroi,
senza invulnerabilità artificiale o modifiche a salute/danni; è una verifica di
completabilità, non una misura della durata o del divertimento per un giocatore.

Anteprime native: artifacts/hero-combos.gif e artifacts/miniboss-combat.png.

## Revisione dell’attacco di Layla

La combo di Layla ha una posa dedicata: affondo della lama anteriore,
risposta della seconda lama e taglio discendente conclusivo. La mano libera
resta in guardia anziché eseguire un secondo attacco indipendente. Il bacino
trasferisce peso in avanti; ginocchia e gomiti seguono catene a due segmenti
con lunghezze costanti. Le suole restano piantate e ogni attacco ritorna alla
stessa guardia. Presa e asse della lama sono calibrati sul guanto dipinto.
Tempi di danno, corsa e altri personaggi restano quelli già verificati.

`tests/layla_attack.gd` verifica lunghezze degli arti, appoggi e chiusura della
guardia sull’intero ciclo. Anteprima nativa a velocità reale:
`artifacts/layla-dual-blade-combo.gif`.
