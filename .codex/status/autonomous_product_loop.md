# Autonomous Product Loop Status

Current slice:
Link-capacity replay reads and labels branch
`candidate_source.candidate_refresh_request_source_report_summary` metadata.

Status:
Implementation, focused verification, and read-only review are complete.
Publish is pending.
`CandidateRefresh.link_capacity_replay_summary/1` now prefers a non-empty
branch `link_capacity_report` source-report family before falling back to
provenance. Branch summaries preserve source-report counts, row counts, paths,
selected/actual shortfall rows, actual-throughput rows, capacity-adjusted
throughput totals and station/direction maps, direction/spacecraft/station/
requirement routing maps, selected/actual contact/source-window/station-entry/
provider-entry IDs, trust-boundary metadata, and branch-local link-capacity,
capacity-adjusted-throughput, downlink-shortfall, and actual-throughput pressure
booleans while labeling their `source` and replay scope as candidate-source
summary metadata. Empty or absent branch families fall back to provenance
labels; partial non-empty branch families remain authoritative. Direct
`candidate_source` maps use the same branch labels.

Files changed for this slice:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:6647 test/orbital_dynamics/candidate_refresh_test.exs:7501 test/orbital_dynamics/candidate_refresh_test.exs:7516 test/orbital_dynamics/candidate_refresh_test.exs:7759 test/orbital_dynamics/candidate_refresh_test.exs:7790 test/orbital_dynamics/candidate_refresh_test.exs:7832 test/orbital_dynamics/candidate_refresh_test.exs:7892 test/orbital_dynamics/candidate_refresh_test.exs:8034 test/orbital_dynamics/candidate_refresh_test.exs:8178 --trace --seed 0`
  passed existing aggregate/absent/compact-summary/routing/pressure checks and
  new branch candidate-source replay, direct candidate-source labeling,
  empty-branch fallback, and partial-family precedence checks.
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:9004 test/orbital_dynamics/candidate_refresh_test.exs:9305 test/orbital_dynamics/candidate_refresh_test.exs:9342 test/orbital_dynamics/candidate_refresh_test.exs:9374 test/orbital_dynamics/candidate_refresh_test.exs:9405 test/orbital_dynamics/candidate_refresh_test.exs:9445 --trace --seed 0`
  passed adjacent storage/downlink replay composition and pressure checks that
  consume link-capacity provenance.

Review:
- `slice_reviewer` found no code, doc, or test correctness blocker. It flagged
  the second ledger verification command as missing from the original review
  input; the parent had run that adjacent storage/downlink command after
  spawning review and substantiated it here from the local command result.

Docs/artifacts changed:
- `docs/artifacts/field_families/candidate_refresh_artifact.md` now documents
  the branch candidate-source link-capacity summary preference, source and
  replay-scope labels, partial-family precedence, and provenance fallback. No
  schema exports or checked-in study artifacts changed in this slice.

Last product commit:
- Pending.

Next candidate:
After publish, re-read `docs/autonomous_work_guide.md`, this ledger, and the
live worktree before choosing another gap. Continue one narrow resource/
communications replay helper or branch-local source preservation gap at a time
before moving to broader readiness, validation, or compatibility work.

Blocked:
No.

Notes:
This slice intentionally does not replay refresh generation, mutate contact
allocation, select candidates, approve imports, write to Cadence, or regenerate
candidates. Treat current files as authoritative and do not revert unrelated
changes. `.gitignore` has an unrelated pre-existing local scratch-ignore change
and is not part of this slice.
