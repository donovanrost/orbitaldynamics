# Autonomous Product Loop Status

Current slice:
Contact-allocation replay capacity-pack direction routing.

Status:
Implemented and focused verification passed. `CandidateRefresh.source_report_summary/1`
and `CandidateRefresh.contact_allocation_replay_summary/1` now preserve
capacity-pack required/selected/deferred demand by direction plus
selected/deferred/all capacity-pack contact IDs by direction. Row-derived
direction values use the same normalized contact-allocation direction tokens as
existing `contact_ids_by_direction`, so provider aliases such as `Down Link`
route to `downlink` instead of a stale generic token.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/candidate_refresh.ex test/orbital_dynamics/candidate_refresh_test.exs`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:4536 --trace --seed 0`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:4536 test/orbital_dynamics/candidate_refresh_test.exs:5758 test/orbital_dynamics/candidate_refresh_test.exs:6180 test/orbital_dynamics/candidate_refresh_test.exs:6263 test/orbital_dynamics/candidate_refresh_test.exs:6357 --trace --seed 0`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:4536 test/orbital_dynamics/candidate_refresh_test.exs:5758 test/orbital_dynamics/candidate_refresh_test.exs:6180 test/orbital_dynamics/candidate_refresh_test.exs:6263 test/orbital_dynamics/candidate_refresh_test.exs:6357 --trace --seed 0` (post-format line shift covered 4 intended tests)
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:6435 --trace --seed 0`
- `git diff --check`

Docs/artifacts changed:
Updated the candidate-refresh artifact field-family prose to name preserved
selected/deferred capacity-pack contact-ID direction maps in contact-allocation
replay. No checked-in schema export was needed because this slice extends
source-report/replay summary maps rather than a JSON Schema contract.

Last commit:
Current slice commit preserves contact-allocation capacity-pack direction maps
and is pushed to `origin/main`. `git_slice_publisher` was unavailable because
the valid publisher spawn hit the agent thread limit, so publish was performed
manually with scoped staging.

Next candidate:
After this slice is reviewed and pushed, re-read the guide/ledger/live
worktree and continue with the highest-priority unimplemented typed activity,
resource/communications, quality/readiness, or validation slice. Treat broad
partial/future wording as suspect until checked against live code.

Blocked:
No.

Notes:
Treat current files as authoritative and do not revert unrelated changes.
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. The initially considered contact-intent direction
replay gap was already implemented and tested in the live checkout, so this
slice moved to the adjacent contact-allocation replay gap. `slice_reviewer` was
unavailable because the valid reviewer spawn hit the agent thread limit; local
review added compact-summary fallback assertions and found no publish blockers.
