# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Make canonical unavailable station-calendar evidence affect default V3
recommendation selection.

Status:
Implemented, parent-reviewed, and verified. Publish pending.

Why this slice:
Public `station_calendar_report.v1` replay preserved row-derived unavailable
affected-contact/status counts, and derived outage branches emitted explicit
`ground_station_outage` risks. Both were scored but neither was a default hard
recommendation boundary.

Files changed:
- `lib/orbital_dynamics/campaign_planner/types.ex`
- `lib/orbital_dynamics/policy/blocked_risk_matcher.ex`
- `test/orbital_dynamics/policy_test.exs`
- `test/orbital_dynamics/campaign_planner/strategy_station_calendar_recommendation_test.exs`
- `study_results/campaign_repair_readiness_source_handoff_v2.json`
- `docs/feature_set/capability_map/07_ground_network/04_station_calendar.md`
- `.codex/status/autonomous_product_loop.md`

Behavior changed:
Default V3 policy now includes `station_calendar_unavailable_blocked`. It
matches direct `ground_station_outage` risks and positive canonical unavailable
or maintenance counts on station-calendar replay pressure. Blocked branches
remain visible with `policy_decision.v1` provenance but are skipped. Reserved,
reduced-capacity, and unknown provider-status replay remains reviewable.

Public proof:
The V3 regression builds unavailable and reserved `station_calendar_report.v1`
inputs through public `OrbitalDynamics.station_calendar_report/3`, declares
their trust boundaries, and consumes them through branch-local refresh.

Docs read/changed:
- Read/changed `docs/feature_set/capability_map/07_ground_network/04_station_calendar.md`.
- Read `docs/feature_set/capability_map/07_ground_network/03_contact_allocation.md`.
- Read `docs/artifacts/field_families/v3_strategy_artifact/artifact-overview-and-branch-replay.md`.

Verification:
- Focused matcher and public-facade V3 regression: `95 passed`.
- Station-calendar communications/replay/schema set: `161 passed`.
- Campaign-planner plus policy surface: `833 passed`.
- Schema suite, including checked-in V2 handoff: `184 passed`.
- Full `mix test --timeout 180000`: `3451 passed`.
- Changed Elixir files are formatted; `git diff --check` passes.

Artifact regeneration:
`study_results/campaign_repair_readiness_source_handoff_v2.json` was regenerated
through public `OrbitalDynamics.campaign_repair/1`. Canonical comparison against
`HEAD` proves the only semantic change is the new alias in serialized default
`blocked_risk_types`; exact fixture/schema validation passes.

Level 6 pillar advanced:
Fleet-level station-calendar behavior and approval-aware automation boundaries.

Parent review:
No must-fix findings. Matching is limited to direct outage risk identity or
positive canonical unavailable/maintenance counts on exact station-calendar
replay scope; generic pressure, reservation, reduced capacity, and unknown
status cannot trigger the alias. Sidecar delegation is unavailable under the
active runtime policy, so the parent performed review and publish checks.

Previous published slice:
- `8210479b` Block unavailable contact replay (`3449 passed`).

Current publish:
- Commit pending.

Remaining maturity gaps:
- Continue contact/resource/readiness selection only where canonical artifacts
  expose unambiguous blocking evidence.
- Continue branch-local realized-feedback depth where public replay preserves a
  decision-safe signal.
- Continue deeper numerical/backend and resource-model maturity separately.

Blocked:
Not blocked.
