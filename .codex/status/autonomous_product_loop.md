# Autonomous Product Loop Status

Current slice:
Resource-projection replay reads and labels branch
`candidate_source.candidate_refresh_request_source_report_summary` metadata.

Status:
Implementation, focused verification, and read-only review are complete.
Publish is pending.
`CandidateRefresh.resource_projection_replay_summary/1` now prefers a
non-empty branch `resource_projection_report` source-report family before
falling back to provenance. Branch summaries preserve source-report counts,
row counts, paths, projected-resource and invalid-input counts, source artifact
and flow-summary model counts, invalid input IDs, pressure status/type/activity
maps, station/spacecraft/direction routing, source-window/station-calendar/
provider-entry routing, trust-boundary metadata, and branch-local projection,
projected-resource, invalid-input, and activity pressure booleans while
labeling their `source` and replay scope as candidate-source summary metadata.
Empty or absent branch families fall back to provenance labels; partial
non-empty branch families remain authoritative. Direct `candidate_source` maps
use the same branch labels.

Files changed for this slice:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:8273 test/orbital_dynamics/candidate_refresh_test.exs:8739 test/orbital_dynamics/candidate_refresh_test.exs:8793 test/orbital_dynamics/candidate_refresh_test.exs:8847 test/orbital_dynamics/candidate_refresh_test.exs:8899 test/orbital_dynamics/candidate_refresh_test.exs:8989 test/orbital_dynamics/candidate_refresh_test.exs:9004 test/orbital_dynamics/candidate_refresh_test.exs:9196 test/orbital_dynamics/candidate_refresh_test.exs:9240 test/orbital_dynamics/candidate_refresh_test.exs:9284 --trace --seed 0`
  passed existing aggregate/activity/invalid/routing/absent checks and new
  branch candidate-source replay, direct candidate-source labeling,
  empty-branch fallback, and partial-family precedence checks.
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:9344 test/orbital_dynamics/candidate_refresh_test.exs:9645 test/orbital_dynamics/candidate_refresh_test.exs:9682 test/orbital_dynamics/candidate_refresh_test.exs:9714 test/orbital_dynamics/candidate_refresh_test.exs:9745 test/orbital_dynamics/candidate_refresh_test.exs:9785 --trace --seed 0`
  passed adjacent storage/downlink replay composition and pressure checks that
  consume resource-projection provenance.

Review:
- `slice_reviewer` found no must-fix or should-fix findings. It confirmed the
  branch preference, empty-branch fallback, candidate-source source/replay-scope
  labels, partial-family precedence tests, docs, and ledger alignment.

Docs/artifacts changed:
- `docs/artifacts/field_families/candidate_refresh_artifact.md` now documents
  the branch candidate-source resource-projection summary preference, source and
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
This slice intentionally does not replay refresh generation, mutate resource
projection, select candidates, approve imports, write to Cadence, or regenerate
candidates. Treat current files as authoritative and do not revert unrelated
changes. `.gitignore` has an unrelated pre-existing local scratch-ignore change
and is not part of this slice.
