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
I comandi restano quelli della versione desktop; i controlli touch non sono ancora implementati.

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
La build iniziale contiene un PCK di circa 206 MiB e un WASM di circa 38 MiB:
superano entrambi il limite di 25 MiB per file di Cloudflare Pages.
