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

| Enemy | `data/enemies/burrower.tres` > **Sprite** | `burrower.png` (22x22) | Draw it **facing right**; the game flips it. Sheets: set Sprite Hframes / Vframes / Fps in the same file. |
| Trinkets | `data/trinkets/bone.tres`, `coin.tres`, `fossil.tres`, `gem.tres` > **Sprite** | `trinket_*.png` (16x16) | Drawn centred in a 32x32 dirt tile at the art's own size. Sheets work the same way. |

Enemies and trinkets live in data files, not scenes: double-click the `.tres` file, then drag the PNG onto
**Sprite** in the Inspector. There is no editor viewport preview for these; press **F5** and dig to see them
(enemies spawn once you are a few rows deep). To add a new enemy or trinket, right-click an existing `.tres`
> Duplicate, change the fields, and ask the developer to list it in the scene.

| Dirt tiles (all layers) | `data/terrain_profile.tres` > **Tile Texture** | `tile_dirt.png` (4 variants, 128x32) | Tiles are **32x32**. Draw it light/grey: the game tints it with each layer's colour, so every depth looks different. |
| Dirt tiles (one layer) | `data/layers/layer_1.tres` (etc.) > **Tile Texture** | none yet | Shown exactly as drawn (no tint). Use this for a layer that needs its own look. |

**Tile variety:** put several 32x32 tiles side by side in one image and set **Tile Variants** to how many
(e.g. a 128x32 image = 4). The game picks one at random per tile.

**Preview:** open `scenes/main.tscn` and look near the origin. Under the Terrain node you'll see a sample
patch of each of the first four layers, plus a row of the trinkets. It updates as you change textures.
(The real terrain is generated while playing, so the layout in the game differs.)

Still coloured shapes in code: the sky and grass strip.

## Good to know
- An enemy's hitbox is its **Size** in the `.tres` (pixels), whatever size the art is.
- The drill's hitbox is a fixed 24x24 square, whatever size the art is. Tell the developer if the art needs a different size.
- Pixel art: for crisp pixels, Project Settings > Rendering > Textures > Default Texture Filter = Nearest.
