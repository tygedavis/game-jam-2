class_name Enemy
extends Node2D
## A burrowing enemy: heads straight for the player, digging through any dirt in the way.
## Call setup() before adding to the tree.

signal killed(def: EnemyDef, at: Vector2)

var def: EnemyDef
var terrain: Terrain
var target: Drill
var hp := 0.0
var _flash := 0.0

## The enemy art (an AutoSprite child). Its texture comes from the EnemyDef's sprite.
@onready var _sprite: AutoSprite = $Sprite


func setup(enemy_def: EnemyDef, ground: Terrain, player: Drill) -> void:
	def = enemy_def
	terrain = ground
	target = player
	hp = def.max_hp


func _ready() -> void:
	add_to_group("enemies")
	_sprite.visible = def.sprite != null
	_sprite.texture = def.sprite
	_sprite.hframes = def.sprite_hframes
	_sprite.vframes = def.sprite_vframes
	_sprite.fps = def.sprite_fps
	# Burrow out of the ground at the spawn point so we never start embedded.
	_clear_around(position)


func rect() -> Rect2:
	var half := Vector2(def.size, def.size) * 0.5
	return Rect2(position - half, half * 2.0)


func take_damage(amount: float) -> void:
	if is_dying():
		return # already killed this frame; don't emit killed twice
	hp -= amount
	_flash = 0.1
	if hp <= 0.0:
		killed.emit(def, position)
		queue_free()


## True once the enemy has been killed. It stays in the tree (and the "enemies" group) until the end of the frame.
func is_dying() -> bool:
	return hp <= 0.0 or is_queued_for_deletion()


func _physics_process(delta: float) -> void:
	var dir := (target.position - position).normalized()
	_move_axis(Vector2(dir.x, 0.0) * def.speed * delta, delta)
	_move_axis(Vector2(0.0, dir.y) * def.speed * delta, delta)
	if rect().grow(1.0).intersects(target.rect()): # touching counts
		target.take_damage(def.contact_damage)
	_flash = maxf(_flash - delta, 0.0)
	_sprite.flip_h = target.position.x < position.x # art faces right
	_sprite.modulate = Color(1, 0.3, 0.3) if _flash > 0.0 else Color.WHITE # hit flash (red tint)
	queue_redraw()


func _move_axis(offset: Vector2, delta: float) -> void:
	if offset == Vector2.ZERO:
		return
	var next := Rect2(rect().position + offset, rect().size)
	if next.intersects(target.rect()):
		return # solid: stop against the player instead of overlapping
	var a := terrain.world_to_cell(next.position)
	var b := terrain.world_to_cell(next.end - Vector2(0.01, 0.01))
	# A barrier stops enemies, but only the player can damage it.
	var blocked := terrain.barrier_layer_in_rect(next) >= 1
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			var cell := Vector2i(x, y)
			if terrain.is_solid(cell):
				blocked = true
				terrain.damage(cell, def.dig_dps * delta)
	if not blocked:
		position += offset


func _clear_around(center: Vector2) -> void:
	var half := Vector2(def.size, def.size) * 0.5
	var a := terrain.world_to_cell(center - half)
	var b := terrain.world_to_cell(center + half)
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			terrain.damage(Vector2i(x, y), 1.0e30)


func _draw() -> void:
	if def.sprite != null:
		return # the Sprite child draws the enemy
	var half := Vector2(def.size, def.size) * 0.5
	draw_rect(Rect2(-half, half * 2.0), Color.WHITE if _flash > 0.0 else def.color)
