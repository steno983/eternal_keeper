# Articulated hero gait

The previous eight source poses repeated the same leg ordering. RIFE made that
incorrect half-stride smoother; it could not invent an anatomical full stride.
Two attempts to regenerate full gait sheets, including a skeletal pose guide,
were visually rejected for retaining the same problem. They are not used.

Hero running now uses `scripts/run_rig.gd`: native textured cutout polygons,
with independent near and far leg chains solved at runtime. Their phases differ
by exactly half a cycle. Each foot moves backward during stance, lifts during
recovery and returns forward. Two-bone inverse kinematics preserve thigh and
shin lengths, while source texture coordinates preserve the existing artwork.
Far limbs are shaded darker to keep depth and limb identity readable at crossings.
The gait follows distance travelled, and mirrors as a whole when facing changes.
Attacks and other actions retain their existing SpriteFrames animations.

This addresses leg alternation directly rather than adding more interpolated
full-body images. The upper-body/cape cutout is still largely static, and joins
at hips/knees are provisional. Enemies still use their previous animations.
The result is a technical cutout gait, not final hand-drawn arcade animation.

`tests/gait_motion.gd` checks opposite contacts, stance/swing separation, loop
continuity, constant limb lengths throughout the cycle, actual rig selection,
distance sampling, reverse facing and return to attack sprites.
`tests/capture_gait_movie.gd` captures old and new rendering at equal 60 Hz timing.
`tools/preview_corrected_run.py` creates the comparison GIF from those captures.

No new generated character art was accepted into the game in this revision.
The rig samples the existing v2 original art; its provenance remains unchanged.
