# Autonomous Product Loop Status

Current slice:
CandidateRefresh candidate-rejection source-report identity contract.

Status:
Implemented with focused verification passing locally.
Candidate-rejection source-report identity already uses the shared
count/row-count gate. This slice tightens the replay contract and tests so
declared contract is independent from flattened count/row/path identity,
explicit zero identity counts and explicit empty path lists are preserved,
missing or nil paths remain omitted after valid counts, and non-identity
rejection-reason, required-action, candidate, and station routing maps still
drive branch-local replay pressure when the family identity is only partial.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `test/orbital_dynamics/candidate_refresh_test.exs`

Tests run:
- `mix format test/orbital_dynamics/candidate_refresh_test.exs`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:27192 test/orbital_dynamics/candidate_refresh_test.exs:27231 test/orbital_dynamics/candidate_refresh_test.exs:27259 test/orbital_dynamics/candidate_refresh_test.exs:27298 test/orbital_dynamics/candidate_refresh_test.exs:27323`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs`
- `git diff --check`

Docs/artifacts changed:
- `docs/artifacts/field_families/candidate_refresh_artifact.md`

Last commit:
Pending publish.

Next candidate:
After verification and publish, continue guide-backed CandidateRefresh depth
from queue item 4 with the next source-report family whose replay helper exists
but aggregate identity, routing, or capability advertisement is incomplete.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
