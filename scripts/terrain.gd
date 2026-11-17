@tool
class_name Terrain
extends Node2D
## Endless destructible ground. Rows < 0 are open sky; row 0 is the first dirt row, and
## depth and width are unbounded (the surface is the only edge). Only tiles that have been damaged or dug are stored; any other
## tile is untouched dirt whose HP comes from the depth formula (TerrainProfile) or a
## LayerDef override. Dirt is drawn from tile textures (TerrainProfile / LayerDef), or flat colours if none.
## @tool so the editor shows a preview of each layer's tiles (see _draw_preview).

signal gem_collected(def: GemDef)

const TILE := 32
const SKY_COLOR := Color(0.55, 0.75, 0.9)
const GRASS_COLOR := Color(0.3, 0.6, 0.3)
const GRASS_HEIGHT := 10.0
## Editor preview size: how many layers to sample, and how many tile rows of each.
const PREVIEW_LAYERS := 4
const PREVIEW_ROWS := 3

@export var profile: TerrainProfile
## Optional hand-authored layers (name, colour, HP overrides), keyed by layer_index.
@export var overrides: Array[LayerDef] = []

## Gems that can be buried. Edit on the Terrain node in main.tscn.
@export var gem_defs: Array[GemDef] = []
## Fraction of dirt tiles that hide a gem.
@export var gem_chance := 0.008

var _seed := 0
var _override_by_layer := {}
var _tiles := {} # Vector2i -> current HP (<= 0 means dug out)
var _gem_hp := {} # Vector2i -> remaining gem durability (only gems that have been hit)
var _gems_done := {} # Vector2i -> true once a gem has been collected
var _view := Rect2()


func _ready() -> void:
	_seed = randi()
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
	if cell.y < 0:
		return false # sky
	return _hp_at(cell) > 0.0


func is_dirt(cell: Vector2i) -> bool:
	return cell.y >= 0 and _hp_at(cell) > 0.0


## True if something still blocks the drill here: dirt, or a gem that has not been collected.
func is_blocked(cell: Vector2i) -> bool:
	return is_solid(cell) or _gem_alive(cell)


## A gem is in this tile and has not been collected (it may still be buried or already exposed).
func _gem_alive(cell: Vector2i) -> bool:
	return cell.y >= 0 and not _gems_done.has(cell) and gem_at(cell) != null


## True if a gem is in this tile and its surrounding dirt is gone, so it can be dug.
func gem_exposed(cell: Vector2i) -> bool:
	return cell.y >= 0 and _hp_at(cell) <= 0.0 and _gem_alive(cell)


## Remaining durability of the gem in this tile as a fraction (1 = untouched).
func gem_fraction(cell: Vector2i) -> float:
	var def := gem_at(cell)
	if def == null:
		return 0.0
	return _gem_hp.get(cell, def.durability) / def.durability


## Damages a tile. Dirt is damaged first. Once the dirt is gone, a gem in the tile is exposed and
## takes the damage instead, but only from the player's attacks (collect = true); collecting it
## when its durability runs out. Enemies only ever dig dirt. Returns true if something broke.
func damage(cell: Vector2i, amount: float, collect := false) -> bool:
	if is_dirt(cell):
		var hp := maxf(_hp_at(cell) - amount, 0.0)
		_tiles[cell] = hp
		queue_redraw()
		return hp <= 0.0
	if not collect or not gem_exposed(cell):
		return false
	var def := gem_at(cell)
	var left := maxf(_gem_hp.get(cell, def.durability) - amount, 0.0)
	_gem_hp[cell] = left
	queue_redraw()
	if left > 0.0:
		return false
	_gems_done[cell] = true
	gem_collected.emit(def)
	return true


## The gem buried in this tile, or null. Deterministic per run from the cell.
func gem_at(cell: Vector2i) -> GemDef:
	if cell.y < 0 or gem_defs.is_empty():
		return null
	var h := _mix(cell.x * 73856093 ^ cell.y * 19349663 ^ _seed)
	if (h % 100000) / 100000.0 >= gem_chance:
		return null
	var layer := profile.layer_of(cell.y)
	var total := 0.0
	for t in gem_defs:
		if t.min_layer <= layer:
			total += t.weight
	if total <= 0.0:
		return null
	var roll := ((_mix(h) % 100000) / 100000.0) * total
	for t in gem_defs:
		if t.min_layer > layer:
			continue
		roll -= t.weight
		if roll <= 0.0:
			return t
	return null


func _mix(x: int) -> int:
	x = ((x >> 16) ^ x) * 0x45d9f3b & 0x7fffffff
	x = ((x >> 16) ^ x) * 0x45d9f3b & 0x7fffffff
	return (x >> 16) ^ x


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))


func set_view(rect: Rect2) -> void:
	_view = rect
	queue_redraw()


## Draws one dirt tile at cell (x, y). `fraction` is remaining HP (1 = untouched); damage darkens it.
func _draw_dirt(x: int, y: int, fraction: float) -> void:
	var layer := profile.layer_of(y)
	var o: LayerDef = _override_by_layer.get(layer)
	var tex: Texture2D = null
	var variants := 1
	var tint := true # the profile's texture is tinted with the layer colour; a layer's own is not
	if o and o.tile_texture:
		tex = o.tile_texture
		variants = o.tile_variants
		tint = false
	elif profile.tile_texture:
		tex = profile.tile_texture
		variants = profile.tile_variants
	var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
	var shade := 1.0 - fraction
	if tex == null:
		var c := layer_color(y)
		c = c.lightened(0.05) if (x + y) % 2 == 0 else c
		draw_rect(rect, c.darkened(shade) if fraction < 1.0 else c)
		return
	variants = maxi(variants, 1)
	var cell := Vector2(tex.get_width() / float(variants), tex.get_height())
	var pick := (_mix(x * 73856093 ^ y * 19349663) % variants) if variants > 1 else 0
	var modulate_color := layer_color(y) if tint else Color.WHITE
	if fraction < 1.0:
		modulate_color = modulate_color.darkened(shade)
	draw_texture_rect_region(tex, rect, Rect2(Vector2(pick * cell.x, 0.0), cell), modulate_color)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw() # keep the editor preview live while art or settings change


func _draw() -> void:
	if Engine.is_editor_hint():
		_draw_preview()
		return
	# Sky above the surface, matching the surface scene, with a grass strip on row 0.
	if _view.position.y < 0.0:
		var top := _view.position.y - TILE
		draw_rect(Rect2(_view.position.x - TILE, top, _view.size.x + TILE * 2, -top), SKY_COLOR)
	draw_rect(Rect2(_view.position.x - TILE, -GRASS_HEIGHT, _view.size.x + TILE * 2, GRASS_HEIGHT), GRASS_COLOR)
	var from := world_to_cell(_view.position)
	var to := world_to_cell(_view.end)
	for y in range(maxi(from.y, 0), to.y + 1):
		var full := max_hp(y)
		for x in range(from.x, to.x + 1):
			var cell := Vector2i(x, y)
			var hp := _hp_at(cell)
			if hp > 0.0:
				_draw_dirt(x, y, hp / full) # damaged tiles darken so progress is visible
			var gem := gem_at(cell)
			if gem == null or _gems_done.has(cell):
				continue
			# A gem is drawn in its tile; once exposed it darkens as its durability drops.
			var frac := gem_fraction(cell)
			var center := Vector2(x + 0.5, y + 0.5) * TILE
			gem.draw_at(self, center, TILE, frac)
			if hp <= 0.0 and frac < 1.0:
				draw_rect(Rect2(center + Vector2(-12, 12), Vector2(24.0 * frac, 3)), Color(0.4, 1.0, 0.5))


## Editor-only preview: the real terrain is generated while playing, so show a sample of each of the
## first layers (a patch of tiles, with the layer name above) and a row of the gems.
func _draw_preview() -> void:
	if profile == null:
		return
	_override_by_layer.clear()
	for o in overrides:
		if o:
			_override_by_layer[o.layer_index] = o
	var cols := 14
	var left := -cols / 2
	draw_rect(Rect2(left * TILE, -GRASS_HEIGHT, cols * TILE, GRASS_HEIGHT), GRASS_COLOR)
	var row := 0
	for layer in PREVIEW_LAYERS:
		var first := layer * profile.layer_height
		draw_string(ThemeDB.fallback_font, Vector2(left * TILE, row * TILE - 4.0),
			"Layer %d: %s (preview)" % [layer + 1, layer_name(first)], HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		# Reuse the real tile drawing, shifted from the layer's real rows into the preview grid.
		draw_set_transform(Vector2(0.0, (row - first) * TILE))
		for y in PREVIEW_ROWS:
			for x in range(left, left + cols):
				_draw_dirt(x, first + y, 1.0)
		draw_set_transform(Vector2.ZERO)
		row += PREVIEW_ROWS + 1
	draw_string(ThemeDB.fallback_font, Vector2(left * TILE, row * TILE - 4.0), "Gems (preview)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	for i in gem_defs.size():
		if gem_defs[i]:
			gem_defs[i].draw_at(self, Vector2(left + i + 0.5, row + 0.5) * TILE, TILE)
