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
