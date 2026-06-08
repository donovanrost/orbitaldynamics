# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Station-calendar precedence summaries preserve applied status routing.

Status:
Implementation and focused verification are complete. Station-calendar
precedence summaries now expose optional applied-status count/ID maps and
reserved-under-higher-precedence ID maps by applied status, so review/import
adapters can distinguish maintenance-over-reserved from generic unavailable
outage routing while preserving the existing normalized availability fields.

Files changed:
- `lib/orbital_dynamics/communications/station_calendar.ex`
- `lib/orbital_dynamics/schema.ex`
- `schemas/station_calendar_precedence_summary.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `study_results/station_calendar_precedence_summary_v1.json`
- `test/orbital_dynamics/communications/station_calendar_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `docs/feature_set/capability_map/07_ground_network/04_station_calendar.md`
- `docs/mission_planning/high_fidelity/06_operational_concerns.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix test test/orbital_dynamics/communications/station_calendar_test.exs:1978 test/orbital_dynamics/communications/station_calendar_test.exs:2649 test/orbital_dynamics/schema_test.exs:2596` (3 passed)
- `mix orbital_dynamics.schema.lint --all` (pass; 152 artifacts)
- `mix compile --warnings-as-errors`
- `git diff --check`

Docs/artifacts changed:
- Updated station-calendar and high-fidelity ground-segment docs for
  applied-status precedence routing.
- Updated CandidateRefresh routing inventory for precedence-summary status
  maps.
- Refreshed `station_calendar_precedence_summary.v1` schema exports and the
  exact checked-in summary fixture.

Level 6 pillar advanced:
Fleet-level contact, station-calendar, and allocation behavior: provider
calendar precedence handoffs now keep status-level triage evidence for
maintenance/outage distinctions without reserving provider time or mutating
schedules.

Remaining maturity gaps:
Continue reassessing the guide queue from live evidence. The next slice should
favor a concrete current-code gap in typed activity/timeline semantics,
resource/comms allocation semantics, quality-gate readiness, branch-local
refresh depth, or validation/compatibility fixtures.

Last commit:
Product commit `7adbb2b8d16939a4d00b251fc164fdb645175be9`.

Next candidate:
Re-read the guide queue and current checkout before selecting another slice.
Resource/comms remains a useful lane; next candidates include station
reservation conflict/readiness replay, provider counteroffer impact/import
readiness, or capacity-pack allocation evidence if a focused current-code gap
is found.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.
