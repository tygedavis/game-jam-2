@tool
class_name GemDef
extends Resource
## A buried gem: its tile's dirt must be dug away, then the gem itself dug out. Add one by creating a GemDef .tres and listing it on the Terrain node.

@export var display_name := "Gem"
## What it's worth (to the owner, later). Shown on the results screen.
@export var value := 1
## How much digging it takes to break the gem out once the dirt around it is gone.
@export var durability := 20.0
## Relative chance among the gems available at a depth.
@export var weight := 1.0
## Shallowest layer (0 = topsoil) where it can appear.
@export var min_layer := 0
## Art, drawn centred in the tile it is buried in (tiles are 32x32 px; art is drawn at its own
## size). Drag a PNG here: a static image or a sprite sheet. If empty, a coloured dot is drawn.
@export var sprite: Texture2D
## Sprite sheet layout: columns and rows (1 and 1 for a single static image).
@export var sprite_hframes := 1
@export var sprite_vframes := 1
## Sprite sheet animation speed, frames per second.
@export var sprite_fps := 8.0
## Placeholder dot colour, used only when no sprite is set.
@export var color := Color(0.9, 0.9, 0.9)


## Draws this gem centred on `center` (placeholder dot if there is no sprite).
func draw_at(canvas: CanvasItem, center: Vector2, tile_size: float, fraction := 1.0) -> void:
	var shade := Color.WHITE.darkened(1.0 - fraction)
	if sprite == null:
		canvas.draw_circle(center, tile_size * 0.22, color.darkened(1.0 - fraction))
		return
	var frames := maxi(sprite_hframes * sprite_vframes, 1)
	var frame := 0
	if frames > 1 and sprite_fps > 0.0:
		frame = int(Time.get_ticks_msec() / 1000.0 * sprite_fps) % frames
	var cell := Vector2(sprite.get_width() / float(sprite_hframes), sprite.get_height() / float(sprite_vframes))
	var src := Rect2(Vector2(frame % sprite_hframes, frame / sprite_hframes) * cell, cell)
	canvas.draw_texture_rect_region(sprite, Rect2(center - cell * 0.5, cell), src, shade)
