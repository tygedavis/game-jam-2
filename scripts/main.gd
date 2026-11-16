extends Node2D
## Boots straight into a run (see docs/prototype-plan.md).

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

## Enemy types that can spawn. Edit in main.tscn.
@export var enemy_defs: Array[EnemyDef] = []
@export var spawn_interval := 2.0
@export var max_enemies := 25
## Spawn distance from the player, in pixels (just off screen).
@export var spawn_distance := 700.0
## Don't spawn until the drill is this many rows underground.
@export var spawn_min_row := 3

@onready var terrain: Terrain = $Terrain
@onready var drill: Drill = $Drill
@onready var camera: Camera2D = $Camera2D

var _spawn_timer := 0.0
var _hud: Label


func _ready() -> void:
	drill.terrain = terrain
	# Start on the surface, centered, just above the dirt.
	drill.position = Vector2(Terrain.WIDTH * Terrain.TILE * 0.5, -Terrain.TILE)
	camera.position = drill.position
	drill.died.connect(_on_player_died)
	drill.xp_changed.connect(_update_hud)
	var layer := CanvasLayer.new()
	_hud = Label.new()
	_hud.position = Vector2(12, 8)
	layer.add_child(_hud)
	add_child(layer)
	_update_hud()


func _process(delta: float) -> void:
	camera.position = drill.position
	var size := get_viewport_rect().size
	terrain.set_view(Rect2(camera.position - size * 0.5, size))
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_try_spawn()
	_update_hud()


func _try_spawn() -> void:
	if enemy_defs.is_empty() or get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return
	if terrain.world_to_cell(drill.position).y < spawn_min_row:
		return
	var angle := randf() * TAU
	var pos := drill.position + Vector2.from_angle(angle) * spawn_distance
	# Keep spawns underground and inside the world.
	pos.x = clampf(pos.x, Terrain.TILE * 2.0, Terrain.WIDTH * Terrain.TILE - Terrain.TILE * 2.0)
	pos.y = maxf(pos.y, Terrain.TILE * 2.0)
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(enemy_defs.pick_random(), terrain, drill)
	enemy.position = pos
	enemy.killed.connect(_on_enemy_killed)
	add_child(enemy)


func _on_enemy_killed(def: EnemyDef, _at: Vector2) -> void:
	drill.gain_xp(def.xp)


func _on_player_died() -> void:
	# Placeholder until the results screen (milestone 5): restart the run.
	get_tree().reload_current_scene.call_deferred()


func _update_hud() -> void:
	var row := maxi(terrain.world_to_cell(drill.position).y, 0)
	_hud.text = "HP %d / %d    XP %d    Depth %d (%s)" % [
		maxf(drill.hp, 0.0), drill.max_hp, drill.xp, row, terrain.layer_name(row)]
