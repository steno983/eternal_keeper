# Struttura della corsa condivisa dai tre eroi

La struttura del ciclo approvato di Layla è ora usata anche da Tholgrin e Lupinor.
`hero_run_skin.gd` separa movimento, proporzioni ed elementi grafici. Il piccolo
wrapper `layla_run_skin.gd` resta per compatibilità con lo studio e i suoi test.

Il movimento di base resta in `layla_run_study.gd`, senza modifiche alle pose
approvate. I profili adattano le lunghezze degli arti, il busto e la guardia
delle braccia. Il clock segue la distanza percorsa e la velocità del personaggio.

| Eroe | Ciclo completo | Falcata in gioco | Aspetto e guardia |
|---|---:|---:|---|
| Tholgrin | 0,76 s | 182,4 | Corpo largo, arti corti, armatura completa, mazza e scudo sacro |
| Layla | 0,70 s | 231,0 | Ciclo approvato, pelle viola, coda bionda e lame psioniche |
| Lupinor | 0,82 s | 233,7 | Corpo slanciato, falcata più lunga, capelli argento, scimitarra e balestra da polso |

Ogni eroe ha dodici parti caricate dal proprio kit in `assets/*_skin`.
Le immagini sono state generate usando come riferimento le precedenti immagini
originali del progetto. Le sorgenti e i prompt sono conservati nelle cartelle
dei kit. `build_layla_skin.py` e `build_hero_skins.py` isolano e ridimensionano
le parti senza inventare pose o dipingere fotogrammi. I rapporti `qa.json`
registrano dimensioni e alpha. La sorgente di Tholgrin ha richiesto un secondo
passaggio di trasparenza; il runtime usa solo le parti isolate verificate.

Lo studio, aperto con F3 o `Avvia-studio-corsa.cmd`, permette di scegliere gli
eroi con i tre pulsanti oppure con 1/2/3. Mostra sagoma e aspetto sincronizzati,
con pausa, rallentatore, cursore e lettura per fotogramma. Esc torna al gioco.
Il parametro facoltativo `--hero=0`, dopo `--`, apre direttamente Tholgrin.

La modifica è integrata nella corsa della demo. Gli attacchi, le magie, le pose
ferme e i nemici conservano le animazioni precedenti. I raccordi fra i segmenti
sono ancora quelli di una demo con parti articolate, non animazione finale
disegnata individualmente per ogni fotogramma.

`tests/hero_skins.gd` verifica caricamento di tutti i kit, proporzioni, alternanza,
chiusura del ciclo, passo legato alla distanza, cambio direzione, attacchi e
selettore dello studio. Sono stati verificati anche sincronizzazione degli
attacchi e percorso di gioco con gli input della demo. Le catture native a 60 Hz
sono in `artifacts/hero-skin-frames` e `artifacts/hero-game-frames`.

L'anteprima GIF ha una dissolvenza al taglio: i tre periodi diversi non possono
chiudersi tutti nello stesso breve filmato. Nessuna velocità è stata alterata
per far combaciare l'anteprima.

## Correzione dei raccordi anatomici

Ogni kit ora definisce punti dipinti espliciti per collo, vita, spalle,
gomiti, ginocchia e caviglie. Le trasformazioni seguono questi punti anche
quando l’immagine sorgente è obliqua: i bordi del ritaglio non sono articolazioni.
La testa è agganciata al collo; i bracci seguono le spalle del busto.
Le sezioni già presenti nel busto e nel braccio superiore sono ritagliate per
non duplicare bacino e avambraccio. Le catene delle gambe condividono ginocchia
e caviglie, mantenendo le lunghezze durante tutto il ciclo.

`tests/rig_bindings.gd` controlla 168 condizioni su punti dipinti e raccordi.
L’anteprima `artifacts/tholgrin-bindings-fixed.gif` mostra un ciclo completo
nativo di Tholgrin, senza dissolvenza, con durata originale di 0,76 secondi.

## Passo e massa di Tholgrin

Tholgrin usa ora curve proprie per cosce, schinieri e piedi, con recupero
più basso e minore estensione delle punte. La lunghezza delle gambe è il 68%
del riferimento, con larghezza dei pezzi aumentata del 65% rispetto al kit
precedente e stivali da 40×24. Il corpo segue la suola di appoggio senza
allungare le ossa. Cadenza, velocità e raccordi restano invariati.
Layla e Lupinor mantengono il proprio ciclo. Anteprima nativa completa:
`artifacts/tholgrin-heavy-run.gif`.
