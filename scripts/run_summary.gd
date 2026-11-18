class_name RunSummary
extends RefCounted
## Pure helpers for ending a run: the death loss and the results text.


## How much of `earned` is lost to the death penalty, rounded down to a whole number.
static func lost_amount(earned: int, fraction: float) -> int:
	return floori(maxi(earned, 0) * clampf(fraction, 0.0, 1.0))


## `stats` keys: deepest (int), layer (String), kills (int), gems (display_name -> count),
## upgrades (id -> {"name", "stacks"}), barriers (int), barrier_money (int).
## `money_total` is the wallet after banking. The Lost line only appears on death.
static func build_text(title: String, stats: Dictionary, earned: int, lost: int,
		money_total: int, died: bool) -> String:
	var lines := PackedStringArray([title, "",
		"Deepest: %d  (%s)" % [stats["deepest"], stats["layer"]],
		"Enemies drilled: %d" % stats["kills"], "", "Gems found:"])
	var gems: Dictionary = stats["gems"]
	if gems.is_empty():
		lines.append("  (none)")
	for name in gems:
		lines.append("  %s x%d" % [name, gems[name]])
	lines.append("")
	lines.append("Upgrades found:")
	var upgrades: Dictionary = stats["upgrades"]
	if upgrades.is_empty():
		lines.append("  (none)")
	for id in upgrades:
		lines.append("  %s x%d" % [upgrades[id]["name"], upgrades[id]["stacks"]])
	lines.append("")
	lines.append("Barriers broken: %d  (+%d)" % [stats["barriers"], stats["barrier_money"]])
	lines.append("")
	var kept := earned - lost
	lines.append("Earned %d" % earned)
	if died:
		lines.append("Lost: %d" % lost)
	lines.append("You keep %d" % kept)
	lines.append("Banked %d  (money: %d)" % [kept, money_total])
	return "\n".join(lines)
