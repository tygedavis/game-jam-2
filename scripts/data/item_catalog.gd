class_name ItemCatalog
extends Resource
## The list of every map upgrade item. Shared by the run (what can spawn) and the shop (what can be
## bought). Add a new item by creating its UpgradeItemDef .tres (with a unique item_id) and listing it here.

@export var items: Array[UpgradeItemDef] = []


## Problems that would corrupt the save: a missing item, or an item_id that is empty or shared.
## Empty when the catalog is fine.
func validate() -> Array[String]:
	var errors: Array[String] = []
	var seen := {}
	for i in items.size():
		var it := items[i]
		if it == null:
			errors.append("item %d is null" % i)
			continue
		if it.item_id.strip_edges() == "":
			errors.append("item %d (%s) has an empty item_id" % [i, it.resource_path])
		elif seen.has(it.item_id):
			errors.append("item_id \"%s\" is used by %s and %s" % [it.item_id, seen[it.item_id], it.resource_path])
		else:
			seen[it.item_id] = it.resource_path
	return errors
