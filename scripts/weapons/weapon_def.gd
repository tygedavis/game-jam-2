class_name WeaponDef
extends Resource
## A weapon. Add one by creating a WeaponDef .tres (file name is its id) and listing it in
## data/weapons/ (WeaponCatalog finds it there). Its mechanic is a WeaponBehavior and its firing rule a WeaponLimiter;
## both are resources, so a variant is just new values and a new mechanic is one new script.

const SLOT_PRIMARY := 0
const SLOT_SECONDARY := 1

@export var display_name := "Weapon"
@export_multiline var description := ""
@export_enum("primary", "secondary") var slot := SLOT_PRIMARY
## Damage per shot (or per second, for continuous weapons). Ignored when
## scales_with_drill_stats is set.
@export var damage := 10.0
## The primary takes its damage and fire interval from the drill's (buffed) attack stats.
@export var scales_with_drill_stats := false
@export var behavior: WeaponBehavior
@export var limiter: WeaponLimiter
## Placeholder visuals, also the HUD meter color.
@export var color := Color(1.0, 0.9, 0.4)


## Stable key, taken from the file name.
func id() -> String:
	return resource_path.get_file().get_basename()
