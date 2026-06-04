# Autonomous Product Loop Status

Current slice:
Candidate-rejection replay reads and labels branch
`candidate_source.candidate_refresh_request_source_report_summary` metadata.

Status:
Implementation, focused verification, and read-only review are complete for
this slice. Publish is pending. `CandidateRefresh.candidate_rejection_replay_summary/1`
now checks a non-empty branch `candidate_rejection_report` source-report family
before falling back to provenance. Branch-sourced summaries preserve
source-report counts, row counts, paths, rejected/reviewable/invalid-input
counts, rejection reason maps, required-action maps, candidate/station routing
maps, trust-boundary metadata, and branch-local pressure booleans while
labeling their `source` and replay scope as candidate-source summary metadata.
Empty or absent branch families fall back to provenance and keep existing
provenance-only labels; partial non-empty branch families remain authoritative.
Direct `candidate_source` maps use the same branch labels.

Files changed for this slice:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:19975 test/orbital_dynamics/candidate_refresh_test.exs:19990 test/orbital_dynamics/candidate_refresh_test.exs:20028 test/orbital_dynamics/candidate_refresh_test.exs:20117 test/orbital_dynamics/candidate_refresh_test.exs:20152 test/orbital_dynamics/candidate_refresh_test.exs:20191 --trace --seed 0`
  passed absent-provenance, preserved-map pressure, branch candidate-source
  replay, direct candidate-source labeling, empty-branch fallback, and
  partial-family precedence checks.
- `git diff --check` passed.

Review:
- `slice_reviewer` found no publish blocker. It noted an optional follow-up for
  an explicit absent-branch-with-provenance fallback test, but the current slice
  covers absent provenance, empty-branch fallback, direct branch labels, and
  partial-family precedence.

Docs/artifacts changed:
- `docs/artifacts/field_families/candidate_refresh_artifact.md` now documents
  the branch candidate-source candidate-rejection summary preference, source and
  replay-scope labels, partial-family precedence, and provenance fallback. No
  schema exports or checked-in study artifacts changed in this slice.

Last product commit:
- Pending.

Next candidate:
After publish, re-read `docs/autonomous_work_guide.md`, this ledger, and the
live worktree before choosing another gap. Continue auditing one narrow typed
timeline/activity replay helper at a time for branch `candidate_source` summary
metadata before moving to broader resource, readiness, or validation work.

Blocked:
No.

Notes:
This slice intentionally does not replay refresh generation, mutate candidates,
select candidates, import rejected candidates, approve imports, write to
Cadence, mutate schedules, or regenerate candidates. Treat current files as
authoritative and do not revert unrelated changes. `.gitignore` has an
unrelated pre-existing local scratch-ignore change and is not part of this
slice.
