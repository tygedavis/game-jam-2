extends Node2D
## Boots straight into a run (see docs/prototype-plan.md).

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

## Enemy types that can spawn. Edit in main.tscn.
@export var enemy_defs: Array[EnemyDef] = []
## Upgrades offered on level-up (three are picked at random). Edit in main.tscn.
@export var upgrade_defs: Array[UpgradeDef] = []
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
var _xp_bar: ProgressBar
var _menu: LevelUpMenu
var _pending_levels := 0
var _results: ResultsScreen
var _max_row := 0
var _kills := 0
var _trinkets := {} # display_name -> count
var _trinket_value := 0


func _ready() -> void:
	drill.terrain = terrain
	# Start parked on the ground line, matching the hub drill.
	drill.position = Vector2(0.0, -12.0)
	camera.position = drill.position
	# Draw the first frame correctly so the scene change doesn't flash.
	terrain.set_view(Rect2(camera.position - get_viewport_rect().size * 0.5, get_viewport_rect().size))
	drill.died.connect(_on_player_died)
	drill.xp_changed.connect(_update_hud)
	drill.leveled_up.connect(_on_leveled_up)
	var layer := CanvasLayer.new()
	_hud = Label.new()
	_hud.position = Vector2(12, 8)
	layer.add_child(_hud)
	_xp_bar = ProgressBar.new()
	_xp_bar.position = Vector2(12, 36)
	_xp_bar.custom_minimum_size = Vector2(300, 14)
	_xp_bar.show_percentage = false
	layer.add_child(_xp_bar)
	add_child(layer)
	terrain.trinket_collected.connect(_on_trinket_collected)
	_results = ResultsScreen.new()
	_results.retry.connect(_on_retry)
	add_child(_results)
	_menu = LevelUpMenu.new()
	_menu.chosen.connect(_on_upgrade_chosen)
	add_child(_menu)
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
	# Keep spawns underground.
	pos.y = maxf(pos.y, Terrain.TILE * 2.0)
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(enemy_defs.pick_random(), terrain, drill)
	enemy.position = pos
	enemy.killed.connect(_on_enemy_killed)
	add_child(enemy)


func _on_trinket_collected(def: TrinketDef) -> void:
	_trinkets[def.display_name] = _trinkets.get(def.display_name, 0) + 1
	_trinket_value += def.value


func _on_enemy_killed(def: EnemyDef, _at: Vector2) -> void:
	_kills += 1
	drill.gain_xp(def.xp)


func _on_leveled_up() -> void:
	_pending_levels += 1
	if _pending_levels == 1:
		_offer_upgrades()


func _offer_upgrades() -> void:
	var pool := upgrade_defs.duplicate()
	pool.shuffle()
	var picks: Array[UpgradeDef] = []
	for def in pool.slice(0, 3):
		picks.append(def)
	if picks.is_empty():
		_pending_levels = 0
		return
	_menu.offer(picks)


func _on_upgrade_chosen(def: UpgradeDef) -> void:
	def.apply(drill)
	_pending_levels -= 1
	if _pending_levels > 0:
		_offer_upgrades()


func _on_player_died() -> void:
	if _menu.visible:
		_menu.visible = false
	var lines := PackedStringArray(["YOU WERE OVERRUN", "",
		"Deepest: %d  (%s)" % [_max_row, terrain.layer_name(_max_row)],
		"Level: %d    Enemies drilled: %d" % [drill.level, _kills], "", "Trinkets found:"])
	if _trinkets.is_empty():
		lines.append("  (none)")
	for name in _trinkets:
		lines.append("  %s x%d" % [name, _trinkets[name]])
	lines.append("")
	lines.append("Total value: %d" % _trinket_value)
	_results.show_results("\n".join(lines))


func _on_retry() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/surface.tscn")


func _update_hud() -> void:
	var row := maxi(terrain.world_to_cell(drill.position).y, 0)
	_max_row = maxi(_max_row, row)
	_hud.text = "HP %d / %d    Lv %d    Depth %d (%s)    Trinkets %d (value %d)" % [
		maxf(drill.hp, 0.0), drill.max_hp, drill.level, row, terrain.layer_name(row),
		_trinkets.values().reduce(func(a: int, b: int) -> int: return a + b, 0), _trinket_value]
	_xp_bar.max_value = drill.xp_to_next()
	_xp_bar.value = drill.xp
