class_name Reticle
extends RefCounted
## The target-reticle mouse cursor used during runs. The surface keeps the normal cursor.

const SIZE := 32
const RING_RADIUS := 11.0
const COLOR := Color(1.0, 1.0, 1.0, 0.95)


## A ring with a cross through it (gap at the center), on a transparent background.
static func make_image() -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var c := Vector2(SIZE, SIZE) * 0.5 - Vector2(0.5, 0.5)
	for y in SIZE:
		for x in SIZE:
			var offset := Vector2(x, y) - c
			var on_ring := absf(offset.length() - RING_RADIUS) < 1.0
			var on_cross := (absf(offset.x) < 1.0 or absf(offset.y) < 1.0) and offset.length() > 3.0 and offset.length() < RING_RADIUS + 4.0
			if on_ring or on_cross:
				img.set_pixel(x, y, COLOR)
	return img


static func apply() -> void:
	var tex := ImageTexture.create_from_image(make_image())
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2(SIZE / 2, SIZE / 2))


static func clear() -> void:
	Input.set_custom_mouse_cursor(null)
