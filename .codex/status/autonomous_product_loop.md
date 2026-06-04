# Autonomous Product Loop Status

Current slice:
Timeline-preservation replay reads and labels branch `candidate_source`
preservation rows.

Status:
Implementation, focused verification, read-only review, and review follow-up
are complete for this slice. Publish is pending.
`CandidateRefresh.timeline_preservation_replay_summary/1` now prefers non-empty
V3 branch `candidate_source` preservation report/status rows before falling
back to candidate-refresh review provenance. Branch rows preserve
preservation-status maps, required-action maps, protection decision/category/
reason maps, activity/timeline routing, action routing, source contract/model
counts, and pressure booleans while labeling their `source` and replay scope as
candidate-source request metadata. Branch row source paths are rewritten to the
`candidate_source.candidate_refresh_request.*` boundary. Empty, absent, or
unmarked branch preservation rows fall back to review-provenance labels;
partial non-empty marked branch rows remain authoritative. Direct marked
`candidate_source` maps use the same branch labels.

Files changed for this slice:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:15174 test/orbital_dynamics/candidate_refresh_test.exs:15401 test/orbital_dynamics/candidate_refresh_test.exs:15482 test/orbital_dynamics/candidate_refresh_test.exs:15519 test/orbital_dynamics/candidate_refresh_test.exs:15554 test/orbital_dynamics/candidate_refresh_test.exs:15597 test/orbital_dynamics/candidate_refresh_test.exs:15626 --trace --seed 0`
  passed existing preservation review/import handoff plus branch
  candidate-source replay, direct candidate-source labeling, empty-branch
  fallback, unmarked nested and direct candidate-source fallback, and
  partial-row precedence checks.

Review:
- Initial `slice_reviewer` found a publish blocker: unmarked nested
  `candidate_source` maps were treated as branch-authoritative. The helper now
  requires the `candidate_refresh_request_source_report_summary` marker for
  nested/direct branch preservation rows, with focused regression coverage.
- Final `slice_reviewer` found no publish blocker. Its recommended direct
  unmarked candidate-source regression was added and rerun.

Docs/artifacts changed:
- `docs/artifacts/field_families/candidate_refresh_artifact.md` now documents
  the branch candidate-source preservation row preference, source-path rewrite,
  branch replay-scope label, partial-row precedence, and review-provenance
  fallback. No schema exports or checked-in study artifacts changed in this
  slice.

Last product commit:
- Pending.

Next candidate:
After publish, re-read `docs/autonomous_work_guide.md`, this ledger, and the
live worktree before choosing another gap. Continue one narrow typed
timeline/activity replay helper or branch-local source preservation gap at a
time before moving to broader resource, readiness, or validation work.

Blocked:
No.

Notes:
This slice intentionally does not apply preservation decisions, mutate
timelines, select candidates, approve imports, execute commands, write to
Cadence, or regenerate candidates. Treat current files as authoritative and do
not revert unrelated changes. `.gitignore` has an unrelated pre-existing local
scratch-ignore change and is not part of this slice.
