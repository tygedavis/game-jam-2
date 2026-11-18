class_name SurfaceGate
extends RefCounted
## Decides when the "return to the surface?" prompt may open. A run starts above ground, so
## the gate is disarmed until the drill has been underground, and again after a decline.

var _armed := false


## Call every frame with the drill's current row. True on the single frame the prompt should open.
func update(row: int) -> bool:
	if row >= 1:
		_armed = true
	elif row < 0 and _armed:
		_armed = false
		return true
	return false


## The caller closed the prompt without returning; stay quiet until the drill goes underground again.
func decline() -> void:
	_armed = false
