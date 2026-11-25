class_name WeaponCatalog
extends RefCounted
## Every weapon, found by scanning data/weapons/. Add a weapon by dropping its WeaponDef .tres in
## that folder; there is no list to update.

const WEAPON_DIR := "res://data/weapons/"


## All weapon defs, sorted by id. Uses ResourceLoader so it also works in exported builds, where
## resource files are remapped.
static func all() -> Array[WeaponDef]:
	var defs: Array[WeaponDef] = []
	for file in ResourceLoader.list_directory(WEAPON_DIR):
		if not file.ends_with(".tres"):
			continue
		var def := load(WEAPON_DIR + file) as WeaponDef
		if def != null:
			defs.append(def)
	defs.sort_custom(func(a: WeaponDef, b: WeaponDef) -> bool: return a.id() < b.id())
	return defs
