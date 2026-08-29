# Security

Report vulnerabilities privately via GitHub's "Report a vulnerability" on this repo rather than a public issue.

Out of scope: recovering a secret from process memory of a live, unlocked session — QML/JS strings cannot be scrubbed, and `dcli` (Node) holds the decrypted vault in memory the same way; "cleared" in the README means the reference is dropped, not that memory is zeroed.

Scope: anything that lets a secret leave `dcli` other than through the intended per-field pipe to the clipboard or the sidebar
(e.g. secrets in argv, logs, disk, clipboard history, or the metadata JSON). Issues inside `dcli` itself belong to
https://github.com/Dashlane/dashlane-cli.
