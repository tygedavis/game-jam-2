class_name TrinketDef
extends Resource
## A buried trinket. Add one by creating a TrinketDef .tres and listing it on the Terrain node.

@export var display_name := "Trinket"
## What it's worth (to the owner, later). Shown on the results screen.
@export var value := 1
## Relative chance among the trinkets available at a depth.
@export var weight := 1.0
## Shallowest layer (0 = topsoil) where it can appear.
@export var min_layer := 0
## Placeholder visuals.
@export var color := Color(0.9, 0.9, 0.9)
