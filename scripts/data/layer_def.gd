@tool
class_name LayerDef
extends Resource
## Optional hand-authored override for one depth layer (name, colour, HP, later: enemies,
## trinkets, art). Layers without an override use the TerrainProfile formula.

## Which layer this overrides (0 = topmost).
@export var layer_index := 0
@export var display_name := "Layer"
## Overrides the formula's tile HP when > 0.
@export var tile_hp := 0.0
## Overrides the formula's colour when use_color is true.
@export var use_color := false
@export var color := Color(0.55, 0.36, 0.2)
## Art for this layer's dirt tiles, drawn as-is (no tint). Tiles are 32x32 px.
## If empty, the Terrain Profile's tile texture is used (tinted with this layer's colour).
@export var tile_texture: Texture2D
## Several tile pictures side by side in one image (for variety). Number of columns; 1 = a single tile.
@export var tile_variants := 1
