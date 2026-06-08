# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Typed activity station-capacity fraction context.

Status:
Implemented, locally reviewed, committed, and parent-verified. Typed
`MissionPlan.Activity` ingress/egress now preserves top-level
`capacity_fraction`, `station_capacity_fraction`, and
`capacity_pack_capacity_fraction` as bounded station-capacity evidence.
Operational timeline rows receive the same context from typed activities, so
provider-authored reduced-capacity evidence can reach review/import handoffs
without being hidden in metadata or raw timeline maps.

Files changed:
- `docs/artifacts/field_families/mission_activities.md`
- `docs/feature_set/capability_map/08_mission_activities/typed-activity-model-and-lifecycle.md`
- `lib/orbital_dynamics/mission_plan/activity.ex`
- `test/orbital_dynamics/mission_plan/activity_test.exs`
- `test/orbital_dynamics/mission_plan_test.exs`
- `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix format lib/orbital_dynamics/mission_plan/activity.ex test/orbital_dynamics/mission_plan/activity_test.exs test/orbital_dynamics/mission_plan_test.exs`
- `mix test test/orbital_dynamics/mission_plan_test.exs:241 test/orbital_dynamics/mission_plan_test.exs:319 test/orbital_dynamics/mission_plan/activity_test.exs` (33 passed, 17 excluded)
- `mix test test/orbital_dynamics/mission_plan/activity_test.exs test/orbital_dynamics/mission_plan_test.exs test/orbital_dynamics/timeline_test.exs` (177 passed)
- `mix orbital_dynamics.schema.lint --all` (154 files, 154 artifacts, status pass)
- `git diff --check`
- `mix test` (3233 passed; known `:propagator_exit` test log observed and suite exited green)

Docs/artifacts changed:
- Updated typed-activity capability docs and mission-activity artifact docs to
  state that station-capacity fraction evidence is first-class at typed
  activity ingress and operational timeline context handoff.
- No generated artifacts or schema exports changed; existing schemas already
  exposed these context fields.

Local review:
- Live comparison showed `capacity_fraction`, `station_capacity_fraction`, and
  `capacity_pack_capacity_fraction` existed in downstream timeline activity
  context but not in `MissionPlan.Activity`.
- The fields intentionally reuse optional unit-interval validation without
  joining `@unit_interval_fields`, because that list drives depleted-margin
  precondition semantics while these fields are capacity evidence.
- No subagent reviewer was spawned because the discovered subagent tool requires
  an explicit current-turn user request for delegation.

Level 6 pillar advanced:
Fleet-level resource/contact/station-calendar allocation behavior and durable
Cadence-facing activity handoffs. Provider-authored reduced-capacity evidence
can now enter the reusable typed activity API and reach timeline review/import
context without granting station reservation, import, or execution authority.

Remaining maturity gaps:
Typed activity context still has selected downstream-only station-calendar
identity/status fields, especially provider entry IDs, trust-boundary status,
directions, availability, reservation, and overlap evidence. Resource/contact
allocation still needs deeper planner-visible behavior for provider-calendar
capacity, reservation pressure, and approval/import authority during candidate
selection.

Last commit:
`873a195` Preserve activity capacity fractions.

Next candidate:
Reassess the guide after publishing. Likely next typed-context subset is
station-calendar provider identity/status context, unless live evidence shows a
planner-visible resource/contact behavior slice is the larger local gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `873a195` preserved typed activity station-capacity fraction context.
- `4a178fc` preserved typed activity observation-objective context.
- `e44638e` preserved typed activity collection-latency objective context.
- `38500cc` exposed capacity-pack direction routing.
- `7b02d2b` routed publication invalidation reasons.

Blocked:
No.
