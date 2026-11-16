class_name Terrain
extends Node2D
## Destructible grid of dirt. Row 0 is the first underground row; rows < 0 are open sky.
## Visuals are drawn here as placeholder rects; swap _draw for a TileMapLayer when art arrives.

const TILE := 32
const WIDTH := 60
const DEPTH := 150

var _solid := PackedByteArray()
var _view := Rect2()


func _ready() -> void:
	_solid.resize(WIDTH * DEPTH)
	_solid.fill(1)


func is_solid(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= WIDTH or cell.y >= DEPTH:
		return true # world walls and floor
	if cell.y < 0:
		return false # sky
	return _solid[cell.y * WIDTH + cell.x] == 1


func is_dirt(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < WIDTH and cell.y >= 0 and cell.y < DEPTH \
		and _solid[cell.y * WIDTH + cell.x] == 1


func dig(cell: Vector2i) -> void:
	if is_dirt(cell):
		_solid[cell.y * WIDTH + cell.x] = 0
		queue_redraw()


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))


func set_view(rect: Rect2) -> void:
	_view = rect
	queue_redraw()


func _draw() -> void:
	var from := world_to_cell(_view.position)
	var to := world_to_cell(_view.end)
	for y in range(maxi(from.y, 0), mini(to.y, DEPTH - 1) + 1):
		for x in range(maxi(from.x, 0), mini(to.x, WIDTH - 1) + 1):
			if _solid[y * WIDTH + x] == 1:
				var shade := clampf(0.55 - y * 0.003, 0.2, 0.55)
				var checker := 0.03 if (x + y) % 2 == 0 else 0.0
				draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE),
					Color(shade + checker, shade * 0.65 + checker, shade * 0.35))
