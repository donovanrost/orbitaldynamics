# Autonomous Product Loop Status

Current slice:
Station-calendar provider-contention provider ID direction replay.

Status:
Implemented with focused verification passing locally. CandidateRefresh
station-calendar source summaries and replay now carry direction-scoped provider
IDs for provider-calendar contention alongside the existing direction-scoped
group IDs, source-entry IDs, provider-entry IDs, and capacity fractions.
Direction routing now exposes `provider_contention_provider_ids`, and preserved
provider-ID direction maps count as provider-contention pressure.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/candidate_refresh.ex test/orbital_dynamics/candidate_refresh_test.exs`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:13288 test/orbital_dynamics/candidate_refresh_test.exs:14180 test/orbital_dynamics/candidate_refresh_test.exs:14257`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs`
- `git diff --check`
- `git diff --cached --check`

Definition of done:
Raw station-calendar reports and artifact provenance preserve
`provider_calendar_contention_provider_ids_by_direction`; station-calendar
direction routing includes provider IDs; provider-ID-only preserved maps set the
expected pressure booleans; docs and focused tests are updated; reviewer has no
must-fix findings; the slice is committed and pushed without staging
`.gitignore`.

Last completed/pushed commit before this slice:
`7d9edf3` (`Replay resource projection provider IDs`).

Next candidate:
After this slice, continue guide-backed resource/communications allocation work
from queue item 2.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
