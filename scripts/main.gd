extends Node2D
## Boots straight into a run (see docs/prototype-plan.md).

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

## Enemy types that can spawn. Edit in main.tscn.
@export var enemy_defs: Array[EnemyDef] = []
## Every upgrade item; those unlocked at the shop can spawn in the ground.
@export var catalog: ItemCatalog
@export var spawn_interval := 2.0
@export var max_enemies := 25
## Spawn distance from the player, in pixels (just off screen).
@export var spawn_distance := 700.0
## Don't spawn until the drill is this many rows underground.
@export var spawn_min_row := 3
## Share of the run's total value lost when the player dies (0.25 = a quarter). A voluntary
## return to the surface keeps everything.
@export_range(0.0, 1.0, 0.01) var death_loss_fraction := 0.25

@onready var terrain: Terrain = $Terrain
@onready var drill: Drill = $Drill
@onready var camera: Camera2D = $Camera2D

var _spawn_timer := 0.0
var _hud: Label
var _results: ResultsScreen
var _return_prompt: ReturnPrompt
var _gate := SurfaceGate.new()
var _ended := false
var _max_row := 0
var _kills := 0
var _gems := {} # display_name -> count
var _gem_value := 0
var _upgrades := {} # upgrade item id -> {"name": display_name, "stacks": held this run}
var _barriers_broken := 0
var _barrier_money := 0


func _ready() -> void:
	DevMode.run = self
	drill.terrain = terrain
	# Only unlocked upgrade items can be found in the ground.
	var pool: Array[UpgradeItemDef] = []
	for def in catalog.items:
		if Save.is_unlocked(def):
			pool.append(def)
	terrain.upgrade_defs = pool
	drill.capture_baseline()
	drill.hp = drill.max_hp
	# Start parked on the ground line, matching the hub drill.
	drill.position = Vector2(0.0, -12.0)
	camera.position = drill.position
	# Draw the first frame correctly so the scene change doesn't flash.
	terrain.set_view(Rect2(camera.position - get_viewport_rect().size * 0.5, get_viewport_rect().size))
	drill.died.connect(_on_player_died)
	var layer := CanvasLayer.new()
	_hud = Label.new()
	_hud.position = Vector2(12, 8)
	layer.add_child(_hud)
	add_child(layer)
	terrain.gem_collected.connect(_on_gem_collected)
	terrain.upgrade_collected.connect(_on_upgrade_collected)
	terrain.barrier_broken.connect(_on_barrier_broken)
	var effects := BarrierEffects.new()
	add_child(effects)
	effects.setup(camera, terrain)
	terrain.barrier_hit.connect(func(_layer: int, fraction: float, at: Vector2) -> void: effects.on_hit(fraction, at))
	terrain.barrier_broken.connect(func(_layer: int, payout: int, at: Vector2) -> void: effects.on_break(payout, at))
	_results = ResultsScreen.new()
	_results.retry.connect(_on_retry)
	add_child(_results)
	_return_prompt = ReturnPrompt.new()
	_return_prompt.confirmed.connect(_on_return_confirmed)
	_return_prompt.declined.connect(_on_return_declined)
	add_child(_return_prompt)
	_update_hud()


func _exit_tree() -> void:
	if DevMode.run == self:
		DevMode.run = null


func _process(delta: float) -> void:
	camera.position = drill.position
	var size := get_viewport_rect().size
	terrain.set_view(Rect2(camera.position - size * 0.5, size))
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_try_spawn()
	_update_hud()
	if not _ended and _gate.update(terrain.world_to_cell(drill.position).y):
		_return_prompt.open()
	
	


func _try_spawn() -> void:
	if DevMode.spawning_paused or enemy_defs.is_empty() or get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return
	if terrain.world_to_cell(drill.position).y < spawn_min_row:
		return
	# Underground, and never on the far side of an unbroken barrier.
	var pos := terrain.spawn_position(drill.position, randf() * TAU, spawn_distance)
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(enemy_defs.pick_random(), terrain, drill)
	enemy.position = pos
	enemy.killed.connect(_on_enemy_killed)
	add_child(enemy)


func _on_gem_collected(def: GemDef) -> void:
	_gems[def.display_name] = _gems.get(def.display_name, 0) + 1
	_gem_value += def.value


func _on_barrier_broken(_layer: int, payout: int, _at: Vector2) -> void:
	_barriers_broken += 1
	_barrier_money += payout
	_gem_value += payout


func _on_upgrade_collected(def: UpgradeItemDef) -> void:
	if not drill.add_upgrade(def, Save.item_level_of(def)):
		return
	_upgrades[def.id()] = {"name": def.display_name, "stacks": drill.stacks_of(def)}
	if drill.stacks_of(def) >= def.max_stacks:
		terrain.capped_upgrade_ids[def.id()] = true


func _on_enemy_killed(_def: EnemyDef, _at: Vector2) -> void:
	_kills += 1


func _on_player_died() -> void:
	_end_run("YOU WERE OVERRUN", true)


func _on_return_confirmed() -> void:
	_end_run("BACK ON THE SURFACE", false)


func _on_return_declined() -> void:
	get_tree().paused = false
	_gate.decline()


## Both endings go through here, once. Dying loses `death_loss_fraction` of the run's value;
## returning voluntarily keeps all of it.
func _end_run(title: String, died: bool) -> void:
	if _ended:
		return
	_ended = true
	var lost := RunSummary.lost_amount(_gem_value, death_loss_fraction) if died else 0
	Save.bank(_gem_value - lost)
	var stats := {"deepest": _max_row, "layer": terrain.layer_name(_max_row), "kills": _kills,
		"gems": _gems, "upgrades": _upgrades, "barriers": _barriers_broken, "barrier_money": _barrier_money}
	_results.show_results(RunSummary.build_text(title, stats, _gem_value, lost, Save.money, died))


func _on_retry() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/surface.tscn")


func _update_hud() -> void:
	var row := maxi(terrain.world_to_cell(drill.position).y, 0)
	_max_row = maxi(_max_row, row)
	var stacks := "    ".join(_upgrades.values().map(func(u: Dictionary) -> String: return "%s x%d" % [u["name"], u["stacks"]]))
	_hud.text = "HP %d / %d    Depth %d (%s)    Gems %d (value %d)    %s" % [
		maxf(drill.hp, 0.0), drill.max_hp, row, terrain.layer_name(row),
		_gems.values().reduce(func(a: int, b: int) -> int: return a + b, 0), _gem_value, stacks]
