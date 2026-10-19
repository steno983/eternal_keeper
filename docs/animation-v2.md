# Animation revision

The first demo's two-frame gait and whole-body pose replacement were rejected.
This revision replaces that renderer with native AnimatedSprite2D views and
SpriteFrames resources that can be inspected and edited in Godot.

## Research and choice

- Godot sprite animation: https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html
- Native SpriteFrames timing: https://docs.godotengine.org/en/stable/classes/class_spriteframes.html
- Aseprite Wizard: https://github.com/viniciusgerevini/godot-aseprite-wizard
- PixelLab MCP: https://www.pixellab.ai/mcp and https://api.pixellab.ai/mcp/docs
- Native cutout/skeletal alternative: https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html

Aseprite Wizard imports existing Aseprite animation data; it cannot create the
missing drawings. We use native PNG atlases and SpriteFrames, without installing
an unused importer or requiring the user to purchase an authoring application.
PixelLab provides dedicated sprite animation generation through MCP; it requires
a personal API token. No PixelLab plugin was found in the available catalog and
the service is not connected in this environment. The revised demo uses the
built-in Imagegen tool for the source drawings and Godot for playback and timing.

## Actual changes

Six character animation libraries, not alternating static full-body illustrations.
Heroes have four idle drawings, eight gait phases, eight melee phases and four
secondary poses. Enemy gait and attack clips are distinct. Original sources and
exact generation prompts are retained under `assets/animation_v2/`.

The first generated sheets had weapons and capes crossing nominal grid cells.
The normalizer isolates connected subjects with a small alpha edge allowance,
then places them on 384×320 transparent canvases. The hip reference remains
fixed; the foot baseline is y=306. A whole character uses a single scale rather
than stretching each individual pose. Tholgrin's overlapping original attack
cells were rejected and replaced by a separately generated eight-frame swing.

The simulation is authoritative for both animation and hit events. Melee contact
uses the extended-weapon drawing: frame 4 for Tholgrin and Lupinor, frame 3 for
Layla's faster lunge. Ranged release and spell cast have their own timings.
Hit-stop and pause freeze the same clock. Swaps, dodges, lane escapes and hit
reactions invalidate pending events using an action serial, preventing phantom
hits from canceled animations. Facing stays locked during a committed swing.
Distance-based gait sampling keeps locomotion in step with movement speed.

## Verification

- Combat smoke suite, including a harmless anticipation phase.
- Animation timing suite: native view frame agrees with the hit event, one hit
  per contact, canceled swings, sprite bounds and all six resources.
- Keyboard-driven graphical tour through all three heroes and menus.
- Native render capture, contact sheets and looping previews. A still screenshot
  alone is not evidence that animation works.

These are generated and curated demo animation assets. Secondary anatomy and
cloth still need a character animator's cleanup for final production quality.
