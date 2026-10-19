# Ceneri & Echi — technical demo

Original provisional setting, unrelated to the campaign until the summaries arrive.

Godot 4.7.2, desktop keyboard and gamepad, 1440 × 810 logical canvas, resizable
16:9 window, three fighting planes at y=470, 560, 650. Hand-painted fantasy
characters, atmospheric teal environment, amber fire, violet psionic blades and
cyan echo. Smooth texture filtering; silhouettes and attack tells take priority.

Background: generated with the built-in Imagegen tool, 1536 × 1024, opaque,
slow camera scroll. Midground bridge, foreground masonry, mist and embers are
original code-native graphics with independent scroll rates.

Hero atlas: generated with the built-in Imagegen tool, 4 poses × 3 characters,
transparent; normalized into equal transparent frame canvases with aligned feet.
These are prototype poses, not final production animation. No claim of affiliation
with or reuse of Golden Axe / Guardian Heroes assets.

UI typefaces are local system Georgia and Segoe UI copies for this private demo;
replace with redistributable fonts before publishing. Audio is original procedural
synthesis. Generated art provenance and prompts are recorded in assets/manifest.json.

Technical acceptance: boots, coherent depth order, all three selectable heroes,
lane-restricted melee, per-hero health and special cooldowns, enemy warning and
recovery states, ranged attacks, echo on another plane, clear victory/defeat,
restart, pause, sound toggle, optional reduced shake and actual window capture.
