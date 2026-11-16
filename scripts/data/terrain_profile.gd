class_name TerrainProfile
extends Resource
## Formula for the endless ground. Any layer without a LayerDef override uses this,
## so deeper layers need no data files.

## Rows per depth layer.
@export var layer_height := 40
## Tile HP in layer 0.
@export var base_hp := 10.0
## HP multiplier for each deeper layer (tile_hp = base_hp * hp_growth ^ layer).
@export var hp_growth := 1.8
## Colour of layer 0; deeper layers shift hue and darken.
@export var base_color := Color(0.55, 0.36, 0.2)
@export var hue_step := 0.07
@export var darken_per_layer := 0.04


func layer_of(row: int) -> int:
	return maxi(row, 0) / layer_height


func hp_for_layer(layer: int) -> float:
	return base_hp * pow(hp_growth, layer)


func color_for_layer(layer: int) -> Color:
	var h := fposmod(base_color.h + layer * hue_step, 1.0)
	var c := Color.from_hsv(h, base_color.s, base_color.v)
	return c.darkened(clampf(layer * darken_per_layer, 0.0, 0.6))
