# Contributing

- Keep the split: QML never runs `dcli`; only `bin/` scripts do, and they must not put secrets in argv or on disk.
- `test/test.sh` must pass (`shellcheck` clean in CI). Add an assertion when you touch a security path.
- Preview with the fixture: `DASHLANE_JSON=$PWD/test/vault.json PATH=$PWD/test/fake:$PATH dashlane-app`.
- Small PRs; no new dependencies beyond what Omarchy ships.
