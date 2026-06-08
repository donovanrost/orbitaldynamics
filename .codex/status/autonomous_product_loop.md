# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Typed activity station-calendar overlap evidence.

Status:
Implemented, parent-verified, and committed. `MissionPlan.Activity`
ingress/egress now preserves station-calendar overlap and ambiguity evidence:
`source_station_calendar_overlaps`, `station_calendar_overlap_count`,
`station_calendar_overlap_entry_ids`,
`station_calendar_overlap_availabilities`,
`station_calendar_entry_ambiguous`,
`station_calendar_ambiguous_entry_count`,
`station_calendar_ambiguous_entry_ids`, and `station_contention_status`.
Operational timeline rows receive the same context from typed activities, with
normalized overlap availability/status values and derived reservation-expiration
evidence from nested overlap provenance.

Files changed:
- `docs/artifacts/field_families/mission_activities.md`
- `docs/feature_set/capability_map/08_mission_activities/typed-activity-model-and-lifecycle.md`
- `lib/orbital_dynamics/mission_plan/activity.ex`
- `test/orbital_dynamics/mission_plan/activity_test.exs`
- `test/orbital_dynamics/mission_plan_test.exs`
- `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix format lib/orbital_dynamics/mission_plan/activity.ex test/orbital_dynamics/mission_plan/activity_test.exs test/orbital_dynamics/mission_plan_test.exs`
- `mix test test/orbital_dynamics/mission_plan_test.exs:438 test/orbital_dynamics/mission_plan_test.exs:663 test/orbital_dynamics/mission_plan/activity_test.exs` (33 passed, 25 excluded)
- `mix test test/orbital_dynamics/mission_plan/activity_test.exs test/orbital_dynamics/mission_plan_test.exs test/orbital_dynamics/timeline_test.exs` (185 passed)
- `mix orbital_dynamics.schema.lint --all` (154 files, 154 artifacts, status pass)
- `git diff --check`
- `mix test` (3241 passed; known `:propagator_exit` test log observed and suite exited green)

Docs/artifacts changed:
- Updated typed-activity capability docs and mission-activity artifact docs to
  state that station-calendar overlap and ambiguity evidence is first-class
  typed activity handoff context.
- No generated artifacts or schema exports changed; existing timeline schemas
  already exposed these context fields.

Local review:
- Live comparison showed overlap/ambiguity fields existed in downstream
  timeline activity context but not in `MissionPlan.Activity`.
- Overlap counts use non-negative integer parsing, overlap/ambiguous entry IDs
  use stable-ID list parsing, overlap availability labels remain scalar list
  evidence, and nested overlaps must be a list of maps.
- The slice preserves provider evidence only; it does not allocate station
  capacity, create or extend reservations, resolve ambiguity, approve import, or
  execute commands.

Level 6 pillar advanced:
Fleet-level resource/contact/station-calendar allocation behavior and durable
Cadence-facing activity handoffs. Provider overlap and ambiguity evidence can
now enter the reusable typed activity API and reach timeline review/import
context without granting schedule or reservation authority.

Remaining maturity gaps:
Typed activity context still has aggregate reservation-list details that are
downstream-only. Resource and contact allocation still need deeper
planner-visible behavior for provider-calendar capacity, reservation pressure,
and approval/import authority during candidate selection.

Last commit:
`02c2f4b` Preserve activity station overlaps.

Next candidate:
Reassess the guide after publishing. Likely candidates include typed aggregate
station-calendar reservation-list context or a shift back to planner-visible
resource/contact behavior such as the existing CandidateRefresh
contact-intent direction-routing gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `02c2f4b` preserved typed activity station-calendar overlap evidence.
- `894c0a3` preserved typed activity direct station-reservation context.
- `9a521ee` preserved typed activity station-calendar directions/source-entry
  context.
- `fff843f` preserved typed activity station-calendar identity/status context.
- `873a195` preserved typed activity station-capacity fraction context.
- `4a178fc` preserved typed activity observation-objective context.
- `e44638e` preserved typed activity collection-latency objective context.

Blocked:
No.
