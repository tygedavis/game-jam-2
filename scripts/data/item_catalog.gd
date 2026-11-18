class_name ItemCatalog
extends Resource
## The list of every map upgrade item. Shared by the run (what can spawn) and the shop (what can be
## bought). Add a new item by creating its UpgradeItemDef .tres and listing it here.

@export var items: Array[UpgradeItemDef] = []
