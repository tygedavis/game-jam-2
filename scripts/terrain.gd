class_name Terrain
extends Node2D
## Endless destructible ground. Rows < 0 are open sky; row 0 is the first dirt row and
## depth is unbounded. Only tiles that have been damaged or dug are stored; any other
## tile is untouched dirt whose HP comes from the depth formula (TerrainProfile) or a
## LayerDef override. Visuals are placeholder rects.

const TILE := 32
const WIDTH := 60

@export var profile: TerrainProfile
## Optional hand-authored layers (name, colour, HP overrides), keyed by layer_index.
@export var overrides: Array[LayerDef] = []

var _override_by_layer := {}
var _tiles := {} # Vector2i -> current HP (<= 0 means dug out)
var _view := Rect2()


func _ready() -> void:
	for o in overrides:
		_override_by_layer[o.layer_index] = o


func max_hp(row: int) -> float:
	var layer := profile.layer_of(row)
	var o: LayerDef = _override_by_layer.get(layer)
	if o and o.tile_hp > 0.0:
		return o.tile_hp
	return profile.hp_for_layer(layer)


func layer_color(row: int) -> Color:
	var layer := profile.layer_of(row)
	var o: LayerDef = _override_by_layer.get(layer)
	if o and o.use_color:
		return o.color
	return profile.color_for_layer(layer)


func layer_name(row: int) -> String:
	var layer := profile.layer_of(row)
	var o: LayerDef = _override_by_layer.get(layer)
	return o.display_name if o else "Layer %d" % (layer + 1)


func _hp_at(cell: Vector2i) -> float:
	return _tiles.get(cell, max_hp(cell.y))


func is_solid(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= WIDTH:
		return true # world walls
	if cell.y < 0:
		return false # sky
	return _hp_at(cell) > 0.0


func is_dirt(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < WIDTH and cell.y >= 0 and _hp_at(cell) > 0.0


## Damages a dirt tile. Returns true if it broke.
func damage(cell: Vector2i, amount: float) -> bool:
	if not is_dirt(cell):
		return false
	var hp := maxf(_hp_at(cell) - amount, 0.0)
	_tiles[cell] = hp
	queue_redraw()
	return hp <= 0.0


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))


func set_view(rect: Rect2) -> void:
	_view = rect
	queue_redraw()


func _draw() -> void:
	var from := world_to_cell(_view.position)
	var to := world_to_cell(_view.end)
	for y in range(maxi(from.y, 0), to.y + 1):
		var full := max_hp(y)
		var base := layer_color(y)
		for x in range(maxi(from.x, 0), mini(to.x, WIDTH - 1) + 1):
			var hp := _hp_at(Vector2i(x, y))
			if hp <= 0.0:
				continue
			var c := base.lightened(0.05) if (x + y) % 2 == 0 else base
			# Damaged tiles darken so progress is visible.
			if hp < full:
				c = c.darkened(1.0 - hp / full)
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), c)
