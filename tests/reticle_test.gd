extends SceneTree
## Headless tests for the reticle cursor image (issue #53).
## Run: godot --headless --path . --script tests/reticle_test.gd

var _failed := false


func check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _initialize() -> void:
	var img := Reticle.make_image()
	check("reticle image is 32x32", img.get_width() == 32 and img.get_height() == 32)
	check("reticle image is RGBA8", img.get_format() == Image.FORMAT_RGBA8)
	check("corner pixel is transparent", is_zero_approx(img.get_pixel(0, 0).a))
	var opaque_on_midline := false
	for x in 32:
		if img.get_pixel(x, 16).a > 0.5:
			opaque_on_midline = true
	check("reticle has opaque pixels on the midline", opaque_on_midline)
	check("reticle center is clear", is_zero_approx(img.get_pixel(16, 16).a))
	Reticle.apply()
	Reticle.clear()
	check("apply and clear run without error", true)
	quit(1 if _failed else 0)
