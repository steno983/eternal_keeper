# Interfaccia della demo

Tre schede con ritratti dedicati, salute numerica e barra ampia. L’eroe attivo
riporta IN CAMPO e un bordo nel proprio colore; gli altri indicano il tasto
per sceglierli. La geometria delle schede è condivisa tra disegno e clic.

Il riquadro obiettivo esplicita cosa fare, nemici rimasti e ondata. La barra
inferiore raggruppa movimento/corsia, attacco, abilità, secondaria e schivata.
Nomi e descrizioni seguono il personaggio attivo. L’abilità mostra PRONTA o
Ricarica con secondi e avanzamento. Il contatore combo appare soltanto quando
serve. Rimossi il piccolo tracciato di avanzamento e l’indicatore astratto di
corsia, sostituito dal testo W/S e dal numero della corsia.

La schermata iniziale usa GIOCA e istruzioni dirette. La pausa rende esplicito
che la partita è ferma. F1 apre la guida con colonne separate per comandi e
abilità, più riepilogo gamepad e indicazione degli attacchi nemici.

Verifica visiva a 1280×720: gioco, salute parziale e ricarica, combo, titolo,
pausa e aiuto. Il percorso nativo visual_tour verifica avvio, cambio eroe,
abilità, corsie, schivata, pausa, guida e riavvio senza errori.
Catture: artifacts/ui-gameplay.png, ui-recharge.png, ui-help.png, ui-title.png,
ui-pause.png. Tutto il testo rimane nativo Godot; nessun testo nelle immagini.
