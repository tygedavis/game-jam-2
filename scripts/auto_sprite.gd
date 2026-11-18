@tool
class_name AutoSprite
extends Sprite2D
## A Sprite2D made for artists: drop a PNG on Texture and it just works, static or animated.
## Static image: leave Hframes = 1 and Vframes = 1.
## Sprite sheet: set Hframes (columns) and Vframes (rows); it plays all frames automatically.
## Plays in the editor viewport too, so you can see the animation without running the game.

## Animation speed in frames per second. Ignored for a single-frame image.
@export var fps := 8.0
## Keeps the bottom-centre of the image on this node's position, so a taller or shorter
## image still "stands" on the same spot (used for characters standing on the ground).
@export var anchor_bottom := false:
	set(value):
		anchor_bottom = value
		_update_anchor()

var _time := 0.0


func _ready() -> void:
	_update_anchor()


func _process(delta: float) -> void:
	_update_anchor()
	var count := hframes * vframes
	if count <= 1 or fps <= 0.0 or texture == null:
		return
	_time += delta
	frame = int(_time * fps) % count


func _update_anchor() -> void:
	if not anchor_bottom or texture == null:
		return
	centered = true
	offset = Vector2(0.0, -texture.get_height() / float(vframes) / 2.0)
