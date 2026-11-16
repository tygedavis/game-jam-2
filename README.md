# game-jam-2

Godot 4.7 (2D, Compatibility renderer, GDScript). Name is a placeholder.

## Layout
- `scenes/` – `.tscn` scenes (`main.tscn` is the entry point)
- `scripts/` – GDScript
- `assets/` – art, audio, fonts
- `addons/` – Godot plugins

## Dev container (Podman)
Node/npm never run on the host. The image (`container/Containerfile`) contains Godot 4.7.2 and
[Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) pinned to a commit.

```sh
podman build -t game-jam-2-dev -f container/Containerfile container
container/run.sh godot --headless --path . --quit   # run any command in the container
```

`.mcp.json` launches the MCP server via `container/run.sh` (project mounted at `/workspace`, so
pass `/workspace` as the project path to MCP tools). Restart Claude Code and approve the `godot` server.
The editor and game windows are not shown from the container; use the host `godot` for the GUI editor.
