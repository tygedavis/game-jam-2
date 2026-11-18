# game-jam-2
- Godot 4.7, GDScript, 2D, Compatibility renderer. Godot binary: `/home/tygedavis/.local/bin/godot`.
- Run headless check: `godot --headless --path . --quit`.
- Dev happens in a Podman container: `container/run.sh <cmd>` (image `game-jam-2-dev`, build per README). Never run npm on the host.
- Godot MCP runs in that container; project path inside it is `/workspace`.
- Game vision and design decisions: `docs/game-design.md` (read before designing features; keep it updated).
- Current work plan: `docs/prototype-plan.md`.
- Layout: `scenes/`, `scripts/`, `assets/`, `addons/`. Main scene: `res://scenes/surface.tscn` (hub); a run is `res://scenes/main.tscn`.

## Git workflow
- Two long-lived branches: `develop` (integration, where all work lands) and `main` (release).
- Name branches `feature/<short-description>` (or `fix/<short-description>`), describing the change. Never keep a generated name like `claude/hopeful-hamilton-xxxx`.
- Never commit directly to `develop` or `main`. Always create a feature branch **off `develop`** and open the PR **against `develop`**. Never branch off or open feature PRs against `main`.
- When `develop` looks good, the user merges `develop` into `main` (a PR from `develop` to `main`). Don't do that merge unprompted.
- PRs to `develop` and `main` run `.github/workflows/ci.yml` (project load check and Linux export smoke test). Merges to `main` trigger `.github/workflows/build.yml`, which exports Linux/Windows builds and updates the rolling `latest` release. Keep `export_presets.cfg` committed.
- Before committing changes to `export_presets.cfg`, check the diff for secrets (`script_encryption_key`, keystore/signing passwords) and absolute local paths (e.g. `/home/...`). Secrets belong in GitHub Actions secrets, never in the repo; keep paths relative.
