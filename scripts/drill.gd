class_name Drill
extends Node2D
## Player drill vehicle. Moves in four directions; blocked by dirt.
## Digging is automatic: whenever the drill is steering into dirt it touches, it damages that
## dirt continuously. The auto-attack (until the mouse attack replaces it) only hits enemies.
## Dig power is derived from the attack stats, so attack upgrades also speed up digging.

@export var speed := 180.0
## Seconds between attacks.
@export var attack_interval := 0.4
## Damage per attack.
@export var attack_damage := 10.0
## How far past the drill's edge the attack reaches, in pixels.
@export var attack_reach := 20.0
## Half-width of the attack, in pixels.
@export var attack_area := 15.0
## How close (px) the drill must be to dirt, in the steering direction, to dig it.
@export var dig_contact := 4.0

signal died
signal xp_changed
signal leveled_up

@export var max_hp := 100.0
## Seconds of invulnerability after taking a hit.
@export var hit_cooldown := 0.6

var terrain: Terrain
var hp := 0.0
## XP progress toward the next level (resets on level-up).
var xp := 0.0
var level := 1
var _invuln := 0.0
var facing := Vector2i.DOWN
var _half := Vector2(12, 12)
var _attack_timer := 0.0
var _flash := 0.0

## The drill art (an AutoSprite child named Sprite). Artists swap its texture in the editor.
## The art should point DOWN; it is rotated to match the facing direction.
@onready var _sprite: Node2D = $Sprite


func _ready() -> void:
	hp = max_hp


func rect() -> Rect2:
	return Rect2(position - _half, _half * 2.0)


func take_damage(amount: float) -> void:
	if _invuln > 0.0 or hp <= 0.0:
		return
	hp -= amount
	_invuln = hit_cooldown
	if hp <= 0.0:
		died.emit()


func xp_to_next() -> float:
	return 10.0 + 6.0 * (level - 1)


func gain_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		leveled_up.emit()
	xp_changed.emit()


func _physics_process(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)
	var input := _read_input()
	if input != Vector2i.ZERO:
		facing = input
	var step := Vector2(input) * speed * delta
	_move_axis(Vector2(step.x, 0))
	_move_axis(Vector2(0, step.y))

	if input != Vector2i.ZERO:
		_dig(delta)

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		_attack()
	_flash = maxf(_flash - delta, 0.0)
	_update_visuals()
	queue_redraw()


func _read_input() -> Vector2i:
	var x := int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) \
		- int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"))
	var y := int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) \
		- int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"))
	# One axis at a time (no diagonals); horizontal wins.
	if x != 0:
		return Vector2i(x, 0)
	return Vector2i(0, y)


func _move_axis(offset: Vector2) -> void:
	if offset == Vector2.ZERO:
		return
	var target := position + offset
	if not _blocked(target) and not _hits_enemy(target):
		position = target


## True if moving to `center` would newly overlap an enemy (enemies are solid).
func _hits_enemy(center: Vector2) -> bool:
	var next := Rect2(center - _half, _half * 2.0)
	var now := rect()
	for e in get_tree().get_nodes_in_group("enemies"):
		var er: Rect2 = e.rect()
		if next.intersects(er) and not now.intersects(er):
			return true
	return false


func _blocked(center: Vector2) -> bool:
	var a := terrain.world_to_cell(center - _half)
	var b := terrain.world_to_cell(center + _half - Vector2(0.01, 0.01))
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			if terrain.is_solid(Vector2i(x, y)):
				return true
	return false


## The attack area in local space: from the drill's center out past its edge by `attack_reach`.
func attack_rect() -> Rect2:
	var reach := _half.x + attack_reach
	if facing.x != 0:
		return Rect2(0.0 if facing.x > 0 else -reach, -attack_area, reach, attack_area * 2.0)
	return Rect2(-attack_area, 0.0 if facing.y > 0 else -reach, attack_area * 2.0, reach)


## Dirt damage per second while digging (same output as the old attack timer).
func dig_power() -> float:
	return attack_damage / attack_interval


## Damages the dirt touching the drill's leading edge. Breaking a tile collects any gem in it.
func _dig(delta: float) -> void:
	var r := Rect2(position - _half, _half * 2.0)
	if facing.x > 0:
		r = Rect2(r.end.x, r.position.y, dig_contact, r.size.y)
	elif facing.x < 0:
		r = Rect2(r.position.x - dig_contact, r.position.y, dig_contact, r.size.y)
	elif facing.y > 0:
		r = Rect2(r.position.x, r.end.y, r.size.x, dig_contact)
	else:
		r = Rect2(r.position.x, r.position.y - dig_contact, r.size.x, dig_contact)
	var a := terrain.world_to_cell(r.position)
	var b := terrain.world_to_cell(r.end - Vector2(0.01, 0.01))
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			terrain.damage(Vector2i(x, y), dig_power() * delta, true)


func _attack() -> void:
	_flash = 0.08
	var r := attack_rect()
	r.position += position
	var a := terrain.world_to_cell(r.position)
	var b := terrain.world_to_cell(r.end - Vector2(0.01, 0.01))
	# Enemies can only be hit up to the nearest solid dirt, so the attack can't reach through the ground.
	var enemy_r := _clip_to_open(r, a, b)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.rect().intersects(enemy_r):
			enemy.take_damage(attack_damage)


## Trims world-space attack rect `r` (covering cells `a`..`b`) so it stops at the
## nearest solid cell in the facing direction.
func _clip_to_open(r: Rect2, a: Vector2i, b: Vector2i) -> Rect2:
	var T := float(Terrain.TILE)
	var limit := INF
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			if not terrain.is_solid(Vector2i(x, y)):
				continue
			var d: float
			if facing.x > 0:
				d = x * T - r.position.x
			elif facing.x < 0:
				d = r.end.x - (x + 1) * T
			elif facing.y > 0:
				d = y * T - r.position.y
			else:
				d = r.end.y - (y + 1) * T
			limit = minf(limit, d)
	if limit == INF:
		return r
	limit = maxf(limit, 0.0)
	var out := r
	if facing.x > 0:
		out.size.x = limit
	elif facing.x < 0:
		out.position.x = r.end.x - limit
		out.size.x = limit
	elif facing.y > 0:
		out.size.y = limit
	else:
		out.position.y = r.end.y - limit
		out.size.y = limit
	return out


func _update_visuals() -> void:
	# Art points down; rotate it to the facing direction. Blink while invulnerable.
	_sprite.rotation = Vector2.DOWN.angle_to(Vector2(facing))
	var blink := _invuln > 0.0 and int(_invuln * 20.0) % 2 == 0
	_sprite.modulate.a = 0.5 if blink else 1.0


func _draw() -> void:
	# The drill's look is the Sprite child; only the attack flash is drawn here.
	if _flash > 0.0:
		draw_rect(attack_rect(), Color(1, 1, 1, 0.35))
