# game-jam-2
- Godot 4.7, GDScript, 2D, Compatibility renderer. Godot binary: `/home/tygedavis/.local/bin/godot`.
- Run headless check: `godot --headless --path . --quit`.
- Dev happens in a Podman container: `container/run.sh <cmd>` (image `game-jam-2-dev`, build per README). Never run npm on the host.
- Godot MCP runs in that container; project path inside it is `/workspace`.
- Game vision and design decisions: `docs/game-design.md` (read before designing features; keep it updated).
- Current work plan: `docs/prototype-plan.md`.
- Layout: `scenes/`, `scripts/`, `assets/`, `addons/`. Main scene: `res://scenes/surface.tscn` (hub); a run is `res://scenes/main.tscn`.
