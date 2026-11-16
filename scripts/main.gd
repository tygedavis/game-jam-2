extends Node2D
## Boots straight into a run (see docs/prototype-plan.md).

@onready var terrain: Terrain = $Terrain
@onready var drill: Drill = $Drill
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	drill.terrain = terrain
	# Start on the surface, centered, just above the dirt.
	drill.position = Vector2(Terrain.WIDTH * Terrain.TILE * 0.5, -Terrain.TILE)
	camera.position = drill.position


func _process(_delta: float) -> void:
	camera.position = drill.position
	var size := get_viewport_rect().size
	terrain.set_view(Rect2(camera.position - size * 0.5, size))
