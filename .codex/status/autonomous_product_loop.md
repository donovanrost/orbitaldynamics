# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Typed activity station-calendar direction/source-entry context.

Status:
Implemented, locally reviewed, committed, and parent-verified. Typed
`MissionPlan.Activity` ingress/egress now preserves
`station_calendar_directions` and nested `source_station_calendar_entry`
provider evidence. Operational timeline rows receive normalized
direction-scoped context from typed activities, including directions derived
from the source station-calendar entry and flattened source entry IDs.

Files changed:
- `docs/artifacts/field_families/mission_activities.md`
- `docs/feature_set/capability_map/08_mission_activities/typed-activity-model-and-lifecycle.md`
- `lib/orbital_dynamics/mission_plan/activity.ex`
- `test/orbital_dynamics/mission_plan/activity_test.exs`
- `test/orbital_dynamics/mission_plan_test.exs`
- `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix format lib/orbital_dynamics/mission_plan/activity.ex test/orbital_dynamics/mission_plan/activity_test.exs test/orbital_dynamics/mission_plan_test.exs`
- `mix test test/orbital_dynamics/mission_plan_test.exs:335 test/orbital_dynamics/mission_plan_test.exs:462 test/orbital_dynamics/mission_plan/activity_test.exs` (33 passed, 21 excluded)
- `mix test test/orbital_dynamics/mission_plan/activity_test.exs test/orbital_dynamics/mission_plan_test.exs test/orbital_dynamics/timeline_test.exs` (181 passed)
- `mix orbital_dynamics.schema.lint --all` (154 files, 154 artifacts, status pass)
- `git diff --check`
- `mix test` (3237 passed; known `:propagator_exit` test log observed and suite exited green)

Docs/artifacts changed:
- Updated typed-activity capability docs and mission-activity artifact docs to
  state that station-calendar directions and nested source-entry provenance are
  first-class typed activity handoff context.
- No generated artifacts or schema exports changed; existing schemas already
  exposed these context fields.

Local review:
- Live comparison showed `station_calendar_directions` and
  `source_station_calendar_entry` existed in downstream timeline activity
  context but not in `MissionPlan.Activity`.
- `station_calendar_directions` uses the existing scalar-list path.
  `source_station_calendar_entry` is preserved as a nested map so timeline
  normalization can derive direction context and flattened source entry IDs.
- No subagent reviewer was spawned because the discovered subagent tool requires
  an explicit current-turn user request for delegation.

Level 6 pillar advanced:
Fleet-level resource/contact/station-calendar allocation behavior and durable
Cadence-facing activity handoffs. Direction-scoped provider-calendar provenance
can now enter the reusable typed activity API and reach timeline review/import
context without mutating station calendars or granting reservation, import, or
execution authority.

Remaining maturity gaps:
Typed activity context still has selected downstream-only station-calendar
fields, especially overlap evidence and reservation/hold details. Resource and
contact allocation still need deeper planner-visible behavior for
provider-calendar capacity, reservation pressure, and approval/import authority
during candidate selection.

Last commit:
`9a521ee` Preserve activity station calendar sources.

Next candidate:
Reassess the guide after publishing. Likely candidates include a typed
station-calendar overlap/reservation subset or a shift back to planner-visible
resource/contact behavior if live evidence shows that is the larger local gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `9a521ee` preserved typed activity station-calendar directions/source-entry
  context.
- `fff843f` preserved typed activity station-calendar identity/status context.
- `873a195` preserved typed activity station-capacity fraction context.
- `4a178fc` preserved typed activity observation-objective context.
- `e44638e` preserved typed activity collection-latency objective context.
- `38500cc` exposed capacity-pack direction routing.

Blocked:
No.
