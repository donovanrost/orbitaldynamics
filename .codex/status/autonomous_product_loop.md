# Autonomous Product Loop Status

Current slice:
Contact-allocation station-pressure and reservation-conflict direction/station
routing.

Status:
Implemented and focused verification is passing locally. ContactAllocation now emits optional
direction-and-ground-station contact-ID maps for station-pressure and
reservation-conflict evidence, and CandidateRefresh source-report/replay
summaries preserve those maps from row-derived reports and compact summaries.
Replay remains artifact-only: no allocation mutation, provider reservation,
candidate selection, import approval, Cadence write, or schedule mutation.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `docs/feature_set/capability_map/07_ground_network/03_contact_allocation.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/communications/contact_allocation.ex`
- `lib/orbital_dynamics/schema.ex`
- `schemas/contact_allocation_capacity_pack_summary.v1.schema.json`
- `schemas/contact_allocation_provider_reservation_request_summary.v1.schema.json`
- `schemas/contact_allocation_report.v1.schema.json`
- `schemas/contact_allocation_reservation_conflict_summary.v1.schema.json`
- `schemas/contact_allocation_station_pressure_summary.v1.schema.json`
- `schemas/contact_allocation_summary.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `test/orbital_dynamics/communications/contact_allocation_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/candidate_refresh.ex lib/orbital_dynamics/communications/contact_allocation.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/candidate_refresh_test.exs test/orbital_dynamics/communications/contact_allocation_test.exs`
- `mix test test/orbital_dynamics/communications/contact_allocation_test.exs`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:4861`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Definition of done:
Station-pressure and reservation-conflict contact IDs are replay-visible by
combined direction and ground station; generated and compact summary paths are
covered; stale nested station-pressure maps are rejected by executable
validation; docs and schema exports are current; reviewer has no must-fix
findings; the slice is committed and pushed without staging `.gitignore`.

Last completed/pushed commit before this slice:
`dfcec00` (`Replay contact intent direction station routing`).

Next candidate:
Continue guide-backed resource/communications allocation work after this slice,
likely the next uncovered station-calendar/contact-allocation precedence replay
gap.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
