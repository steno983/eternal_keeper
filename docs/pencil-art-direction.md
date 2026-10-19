# Proposta: il gioco come una scheda d’avventura illustrata

Stato: campione giocabile implementato. Vedi pencil-implementation.md per
risultato, sorgenti e limiti delle animazioni.

Carta avorio chiara, grafite scura, tratteggio e contorni con piccole variazioni
di pressione. Niente effetto lucido, dettagli metallici fotorealistici o semplice
filtro applicato agli sprite precedenti. Sagome dei combattenti più scure e
nette; architettura e paesaggio con linee più sottili e leggere in profondità.

Accenti di matita colorata limitati alle capacità: arancio brace per Tholgrin,
viola per Layla, turchese spettrale per Lupinor. Volti, costumi e armi mantengono
l’identità del gruppo. Layla ha anatomia adulta naturale e calzature pratiche.

L’interfaccia riprende riquadri e piccoli ritratti di una scheda del personaggio,
con pochi dati funzionali: eroe attivo, salute, azioni e ricariche. Non introduce
statistiche D&D prive di funzione nel combattimento della demo.

Il parallasse mantiene carta e trama ferme rispetto allo schermo; si spostano
le illustrazioni su livelli separati, con grafite via via più chiara in distanza.
Le tre corsie devono rimanere comprensibili senza linee troppo decorative.

Per i personaggi serve un modello di figura intera coerente, verificato in
posa neutra e nelle pose chiave prima della produzione dei cicli. Non basta
sostituire le texture dei ritagli attuali: anatomia, vista, sovrapposizioni e
traiettorie devono essere progettate insieme. Il primo campione previsto è
Layla, con guardia e un attacco, prima di estendere il trattamento al gruppo.

L’immagine di riferimento è una simulazione dello stile a matita generata con
Imagegen, non un disegno realizzato fisicamente a mano né una cattura del gioco.
