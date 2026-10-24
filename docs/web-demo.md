# Demo web

La demo usa Godot 4.7.2, renderer Compatibility e un solo thread.
Il preset Web include esplicitamente i JSON caricati durante la partita.

## Build locale

Scaricare i template ufficiali Godot 4.7.2 ed estrarre
`templates/web_nothreads_debug.zip` e `templates/web_nothreads_release.zip`
in `tmp/web-export/`. Sono archivi temporanei, esclusi dal repository.

Eseguire Godot dalla cartella del progetto:

```text
godot --headless --path . --export-release Web build/web/index.html
python -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Aprire http://127.0.0.1:8765. Non aprire index.html direttamente dal disco.
Su telefono i controlli touch si attivano automaticamente; su desktop rimangono tastiera e gamepad. Per provare il touch con il mouse aggiungere `?mobile=1` all’indirizzo.

## Prova dal telefono

Dalla cartella del progetto avviare `python tools/serve_web.py`. Il programma mostra l’indirizzo locale del computer e quello da aprire sul telefono collegato alla stessa Wi-Fi. La versione esportata è in `build/web/`; il server espone soltanto questa cartella. Non usare localhost dal telefono: localhost indica il telefono stesso.

Toccare **Gioca**, tenere il telefono in orizzontale e usare **Schermo intero** quando supportato. Il primo download include circa 141 MiB di dati di gioco e 38 MiB del motore: preferire Wi-Fi. La demo non è stata ancora verificata su un telefono fisico.

- Joystick sinistro: movimento orizzontale e cambio corsia con inclinazione verticale.
- Pulsanti destri: mazza, parata tenuta premuta, schivata e Intesa.
- Quattro carte in basso: magie, costo e ricarica grigio/colore.
- Toccare per avanzare nei fumetti; toccare la carta desiderata nelle ricompense.
- Pausa in alto a sinistra. Cambiare app rilascia i comandi e mette in pausa; il ritorno richiede un tocco per riprendere.

Il contenitore web mostra un avviso in verticale. La schermata intera e il blocco orientamento dipendono dal browser: il gioco resta utilizzabile in orizzontale anche senza queste funzioni. La build usa Compatibility/WebGL 2 e un solo thread. Non è una pubblicazione Internet né un’app Android/iOS nativa.

Per la verifica nativa: `godot --path . -- --mobile-preview`. I test multitouch sono in `tests/mobile_input.gd`.

## GitHub

Il workflow Web demo ricompila la versione in main e rende disponibile
l'archivio `eternal-keeper-web` nella pagina Actions, per 14 giorni.
I file binari della build non vengono aggiunti alla cronologia Git.

Per un repository pubblico il workflow pubblica anche su GitHub Pages:
nelle impostazioni Pages scegliere GitHub Actions come sorgente.
Per un repository privato, Pages richiede un piano compatibile;
la pubblicazione si avvia manualmente selezionando `publish` nel workflow.
Un sito Pages può essere pubblico anche quando il repository è privato.

Caricare sempre tutti i file della build, mantenendo i nomi originali.
La build mobile contiene un PCK di circa 141 MiB e un WASM di circa 38 MiB:
superano entrambi il limite di 25 MiB per file di Cloudflare Pages.


## Sorgenti della versione mobile

`scripts/mobile_controls.gd` gestisce dita indipendenti, joystick, pressione/rilascio delle azioni e navigazione. `scripts/pencil_painter.gd` contiene l’HUD mobile. `web/mobile-shell.html` è il contenitore esportato, con caricamento, orientamento e schermo intero; non modificare direttamente `build/web/index.html`, perché viene rigenerato. I testi dei comandi sono nel JSON dell’interfaccia.

Materiali delle vecchie animazioni e delle skin di lavorazione sono esclusi dall’esportazione. Gli sprite attuali, tutte le quattro profondità di parallasse, le magie, i fumetti e i JSON della campagna restano inclusi. Il server non richiede account né installazioni sul telefono. Per un link raggiungibile fuori dalla rete di casa occorre una successiva pubblicazione su hosting.


## Verifica del 24 ottobre 2026

18 verifiche di input mobile passate, inclusi movimento+attacco, magie reali, dita indipendenti, dialoghi manuali, scelta ricompense, rilascio in pausa e perdita del focus. Rendering controllato anche a 844×390. L’esportazione corretta è stata caricata in Chrome fino alla schermata del titolo. Non è ancora una verifica su telefono fisico o una misura delle prestazioni su Android/iOS. Se Godot segnala problemi di scrittura dei file temporanei durante l’esportazione, non distribuire il pacchetto senza aver verificato il suo avvio: una precedente esportazione in ambiente limitato aveva prodotto `project.binary` non valido.
