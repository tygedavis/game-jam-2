## What & why

<!-- What does this change, and why? -->

Closes #<!-- issue number; this also marks the issue "in progress" while the PR is open -->

## Checklist

- [ ] Branch is `feature/...` or `fix/...` and this PR targets `develop`
- [ ] Tests pass (`bash tests/run_all.sh`) and new behavior has a test
- [ ] `gdlint scripts tests` is clean
- [ ] `docs/game-design.md` / `docs/prototype-plan.md` updated if design or plan changed
- [ ] If `export_presets.cfg` changed: no secrets (`script_encryption_key`, keystore/signing passwords) and no absolute local paths
