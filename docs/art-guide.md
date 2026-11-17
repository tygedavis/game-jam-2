# Art guide (no coding needed)

All sprites live in `assets/sprites/`. The current PNGs there are placeholders; replace them freely.

## Swap a sprite
1. In Godot's FileSystem dock, double-click the scene (see the table below).
2. Click the node in the Scene dock (e.g. `Dog`). It shows in the 2D viewport.
3. In the Inspector, drag your PNG from the FileSystem dock onto the **Texture** slot.
4. Press **F5** (or F6 for the open scene) to test it in the game.

Easiest of all: save your PNG over the placeholder file with the same name; no Inspector step needed.

## Static image vs sprite sheet
These nodes use `AutoSprite`, so both work the same way:
- **Static image:** just set Texture. Leave Hframes = 1, Vframes = 1.
- **Animated sprite sheet:** set Texture to the whole sheet, then in the Inspector under **Animation** set
  **Hframes** (columns) and **Vframes** (rows). It plays automatically, in the editor too.
  Set **Fps** (under the AutoSprite section) to change speed.
- **Anchor Bottom** (on for the dog and owner) keeps the bottom of the image on the ground, whatever size you draw.

## What is where
| Thing | Scene > node | Placeholder file | Notes |
|---|---|---|---|
| Drill in a run | `scenes/main.tscn` > Drill > Sprite | `drill.png` (48x48) | Draw it **pointing down**; the game rotates it to face the way the drill moves. |
| Drill on the surface | `scenes/surface.tscn` > Drill | `drill.png` | Same art as in a run. |
| Owner | `scenes/surface.tscn` > Owner | `owner.png` | |
| Dog on foot | `scenes/surface.tscn` > Dog | `dog.png` | Draw it **facing right**; the game flips it when walking left. |

Not yet swappable (still coloured shapes in code): enemies, trinkets and the dirt tiles. These are next.

## Good to know
- The drill's hitbox is a fixed 24x24 square, whatever size the art is. Tell the developer if the art needs a different size.
- Pixel art: for crisp pixels, Project Settings > Rendering > Textures > Default Texture Filter = Nearest.
