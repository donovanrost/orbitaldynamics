# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Route resource projection activity-availability pressure into V3 resource
availability score terms.

Status:
Completed and committed in product commit `4127152`.

Slice-selection note:
- Selected slice: make resource projection activity-availability pressure types
  contribute to `resource_availability_pressure_penalty` instead of falling
  through to generic `risk_penalty`.
- Why this slice: the projection replay path already emits
  `spacecraft_degraded_payload_unavailable`,
  `activity_type_suppressed_by_resource_summary`, and
  `activity_type_incompatible_with_resource_summary` risk indicators and
  branch-comparison rows, but the score-term classifier only counts spacecraft,
  payload, antenna, and generic resource-unavailable types.
- Level 6 pillar: reproducible V3 branch scoring with planner-visible resource
  constraints and explainable score-term deltas.
- Current evidence gap: otherwise-equal resource-projection availability
  branches should isolate activity-type and degraded-payload availability
  pressure in `resource_availability_pressure_penalty`, leaving `risk_penalty`
  for unrelated risks.
- Docs read:
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`,
  `docs/feature_set/recommended_roadmap.md`.
- Likely files/tests: `lib/orbital_dynamics/campaign_planner.ex`,
  `test/orbital_dynamics/campaign_planner_test.exs`, and the V3 orchestration
  doc.
- Definition of done: all resource projection availability pressure types count
  in the dedicated availability score term; focused projection replay tests
  assert the split and score-term report rows; docs record the scope; product
  and handoff are committed and pushed without touching unrelated `.gitignore`.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `test/orbital_dynamics/campaign_planner_test.exs`
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:38940`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:61910`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:38940 test/orbital_dynamics/campaign_planner_test.exs:61910`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `git diff --cached --check`

Docs/artifacts changed:
V3 orchestration docs now state that resource-projection payload/antenna,
degraded-payload, and activity-type availability pressure contributes to
`resource_availability_pressure_penalty`, leaving `risk_penalty` for unrelated
risks.

Local review:
Sidecar review was not started because the available multi-agent tool requires
explicit user-requested delegation. Parent review checked projection-specific
risk preservation, score-term classification, generic-risk subtraction, focused
tests, docs, and staged scope; no must-fix issues remained. `.gitignore`
remains unrelated and unstaged.

Level 6 pillar advanced:
Resource projection availability constraints are now score-visible in V3 branch
trees through the dedicated resource-availability score term and report rows,
including degraded-payload and activity-type availability pressure.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`4127152` Route projection availability score terms.

Next candidate:
Reassess the next planner-visible communications or timeline/readiness scoring
gap from current Level 6 evidence.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `4127152` routed resource-projection degraded-payload and activity-type
  availability pressure into the dedicated V3 resource-availability score term
  while preserving generic risk scoring for unrelated risks.
- `a188da9` split explicit approval-boundary pressure into a dedicated V3 score
  term while preserving generic risk scoring for unrelated risks.
- `777a1dc` rejected stale publication source-review evidence in Cadence import
  handoffs.
- `0bdc8df` rejected stale dependency-impact source-review evidence in Cadence
  import handoffs.
- `f8e4afa` rejected stale activity-precondition source-review evidence in
  Cadence import handoffs.
- `379420e` rejected stale lifecycle-state and preservation source-review
  evidence in Cadence import handoffs.
- `7905319` split battery-depletion V3 pressure into a dedicated score term
  while preserving total branch score compatibility.
- `69761fb` split fuel, power, and thermal margin V3 pressure into a dedicated
  score term while preserving total branch score compatibility.
- `cce6dc7` split resource-availability V3 pressure into a dedicated score term
  while preserving total branch score compatibility.
- `fbffb6b` split contact-filter V3 pressure into a dedicated score term while
  preserving total branch score compatibility.
- `50d6f65` split contact-contention and contention-resolution V3 pressure into
  a dedicated score term while preserving total branch score compatibility.
- `1076212` split contact-intent-derived V3 review/import pressure into a
  dedicated score term while preserving total branch score compatibility.
- `9d07ee2` split link-capacity-derived V3 shortfall pressure into a dedicated
  score term while preserving total branch score compatibility.
- `24adf78` hardened compact relay data-path CandidateRefresh source/replay
  summaries against stale top-level aggregate maps.
- `72e824e` hardened compact link-capacity CandidateRefresh source/replay
  summaries against stale top-level aggregate maps.
- `7efd232` hardened compact contact-intent CandidateRefresh source/replay
  routing against stale top-level aggregate maps.
