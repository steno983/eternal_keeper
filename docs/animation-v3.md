# Animation density and control recovery

The user rejected v2's distant poses and rigid motion. V3 fills the intervals
offline with RIFE 4.9 optical flow, including alpha warped with the same flow
and occlusion mask as RGB. The game needs no inference runtime or model.

Heroes have 32 run and 32 attack samples instead of eight; idle and ranged have
16 instead of four. Enemies also receive intermediate samples. Existing key
poses, total action duration and contact-event times are preserved exactly.
Frames and duration reports are in `assets/animation_v3/qa.json`.

Normal hits no longer pause the entire world. Heavy hits pause 25 ms rather
than 65 ms. Horizontal control resumes with smooth easing after 42% of an
action; it previously stayed completely locked for its entire duration.

## Limits observed, not solved

This improves sampling density; it does not repair incorrect source anatomy.
Large weapon displacements can still cause translucent/disappearing weapon
details in inferred frames, especially Tholgrin's mace. These are provisional
assets, not approved final animation. A controlled arm/weapon rig or individually
authored intermediate drawings is required to eliminate those defects.
Abrupt transitions between unrelated states also remain a separate issue.

The before/after preview uses equal action durations, sampled at 60 Hz.
The native-engine capture also samples 60 Hz; the previous GIF dropped frames
to 12 Hz and was unsuitable for assessing the new timing.

## Reproduction and provenance

`tools/interpolate_sprites.py` runs with the bundled Python 3.12 runtime,
onnxruntime-directml and ONNX installed locally in `.tools/interpolation`.
Model: https://huggingface.co/edgetools/rife/blob/main/README.md
Upstream: https://github.com/hzwer/Practical-RIFE (MIT).
Model and license are in `.tools/models`; the runtime game uses only baked PNGs.
Source art remains the existing generated v2 sheets; no third-party characters.

Combat smoke checks and animation timing checks verify contact timing,
cancellation, pause behavior and recovery movement. They cannot validate
perceived animation quality; visual inspection remains necessary.
