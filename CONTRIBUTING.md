# Contributing

- Keep the split: QML never runs `dcli`; only `bin/` scripts do, and they must not put secrets in argv or on disk.
- `test/test.sh` must pass (`shellcheck` clean in CI). Add an assertion when you touch a security path.
- Preview with the fixture: `DASHLANE_JSON=$PWD/test/vault.json PATH=$PWD/test/fake:$PATH dashlane-app`.
- Small PRs; no new dependencies beyond what Omarchy ships.

## Commits
[Conventional Commits](https://www.conventionalcommits.org): `type(scope): summary`, e.g. `fix(copy): clear clipboard after 30s`.
Types: feat fix perf refactor docs test style chore ci build · scopes: app bar cli copy install plugin menu security test.
Run once after cloning so the hook and template are active:
```sh
git config core.hooksPath .githooks && git config commit.template .gitmessage
```
