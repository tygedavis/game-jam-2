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

## Developer mode
A testing panel for trying things without grinding. It only exists in debug runs (the editor, `godot --path .`, or a `tools/build.sh --debug` export), never in
production or plain release builds.

**Using it**
1. Run the game from the editor (or `godot --path .`).
2. Press the backtick key (`` ` ``, left of `1`) on the surface or during a run. The game pauses and the panel opens.
3. Click what you want. Press backtick or Esc to close it and carry on. No function keys are needed.

| Control | What it does |
|---|---|
| Invincible | The drill takes no damage and can't die. |
| Noclip | The drill passes through dirt, gems and layer barriers without digging. Enemies still block it. |
| Infinite money | A huge wallet for trying shop purchases. It is a throwaway session: **nothing is saved**, and turning it off restores your real money, unlocks and upgrade levels. Banked run earnings are discarded too. |
| Pause enemy spawning | No new enemies appear. |
| Skip layer down / up | Jumps the drill to the next layer down (breaking its barrier, no payout) or back up one. Run only. |
| Kill all enemies | Removes every enemy on screen. Run only. |
| Give 1 stack | Pick an upgrade item from the list and add one stack of it for this run (up to its cap). Run only. |

While any toggle is on, a yellow `DEV: ...` line shows at the bottom left, so you know a cheat is active. The toggles stay on
between the surface and runs until you turn them off or quit.

Dev mode lives in `scripts/dev/` (the small `DevMode` autoload in `scripts/dev_mode.gd` holds the toggles). Nothing outside that
folder may reference it; `tests/dev_isolation_test.gd` checks this.

## Production builds
Always export release builds with the wrapper, so developer mode is left out entirely (not just hidden):

```sh
tools/build.sh --production "Linux"        # or "Windows Desktop"; CI does this for every published build
tools/build.sh --debug "Linux"             # a debug export: the only exported build where developer mode works (local testing)
bash tests/production_build_check.sh       # proves a production export has no developer code
```

`--production` exports from a temporary copy of `export_presets.cfg` (the committed file is never changed) that adds the
`production` feature tag and excludes `scripts/dev/`. Even if the files slipped in, developer mode refuses to run in release
exports or when the `production` tag is set.

## Tests
```sh
godot --headless --import     # once, so the class cache exists
bash tests/run_all.sh
```
