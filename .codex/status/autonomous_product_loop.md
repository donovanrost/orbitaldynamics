# Autonomous Product Loop Status

Current slice:
Candidate-diff replay reads and labels branch
`candidate_source.candidate_refresh_request_source_report_summary` metadata.

Status:
Implementation, focused verification, and read-only review are complete for
this slice. Publish is pending. `CandidateRefresh.candidate_diff_replay_summary/1`
now checks a non-empty branch `candidate_diff_report` source-report family
before falling back to provenance. Branch-sourced summaries preserve
source-report counts, row counts, paths, retained/new/invalidated counts, diff
reason maps, invalidated reason maps, semantic-change reason maps,
changed-field maps, candidate/station routing maps, trust-boundary metadata,
and branch-local pressure booleans while labeling their `source` and replay
scope as candidate-source summary metadata. Empty or absent branch families fall
back to provenance and keep existing provenance-only labels; partial non-empty
branch families remain authoritative. Direct `candidate_source` maps use the
same branch labels.

Files changed for this slice:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:1495 test/orbital_dynamics/candidate_refresh_test.exs:1697 test/orbital_dynamics/candidate_refresh_test.exs:1712 test/orbital_dynamics/candidate_refresh_test.exs:1766 test/orbital_dynamics/candidate_refresh_test.exs:1872 test/orbital_dynamics/candidate_refresh_test.exs:1908 test/orbital_dynamics/candidate_refresh_test.exs:1947 --trace --seed 0`
  passed provenance aggregation, absent-provenance, preserved-map pressure,
  branch candidate-source replay, direct candidate-source labeling,
  empty-branch fallback, and partial-family precedence checks.
- `git diff --check` passed.

Review:
- `slice_reviewer` found no publish blocker. It confirmed branch labels,
  provenance fallback, empty-branch handling, and partial-family precedence.

Docs/artifacts changed:
- `docs/artifacts/field_families/candidate_refresh_artifact.md` now documents
  the branch candidate-source candidate-diff summary preference, source and
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
select candidates, write to Cadence, mutate schedules, or regenerate
candidates. Treat current files as authoritative and do not revert unrelated
changes. `.gitignore` has an unrelated pre-existing local scratch-ignore change
and is not part of this slice.
