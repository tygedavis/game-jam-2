#!/usr/bin/env bash
# Run a command in the dev container with the project mounted at /workspace.
# No args: start the Godot MCP server (stdio). Example: container/run.sh godot --headless --path . --quit
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tty_flag=(); [ -t 0 ] && tty_flag=(-t)
exec podman run --rm -i "${tty_flag[@]}" --userns=keep-id \
  -v "$root:/workspace:Z" -e DEBUG="${DEBUG:-}" \
  localhost/game-jam-2-dev "$@"
