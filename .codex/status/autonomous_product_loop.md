# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Split battery-depletion pressure into planner-visible V3 score terms.

Status:
Completed and pushed in product commit `7905319`.

Slice-selection note:
- Selected slice: give resource-projection `battery_depletion` risks a
  dedicated V3 `battery_depletion_pressure_penalty` score term.
- Why this slice: resource-projection battery overuse already creates
  branch-local refresh and risk evidence, but `battery_depletion` still shares
  generic `risk_penalty`; storage/downlink projection risks already have their
  own `storage_downlink_pressure_penalty` term and should not be folded into
  this slice.
- Level 6 pillar: fleet resource readiness and candidate refresh behavior;
  reproducible V3 branch trees with explainable score terms and deltas.
- Current evidence gap: planner-visible score-term reports should distinguish
  battery-depletion pressure from unrelated generic risks
  while preserving total branch score compatibility.
- Docs read:
  `docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`,
  `docs/feature_set/capability_map/11_planning_state_refresh/pressure_replay_into_branch_refresh.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`.
- Likely files/tests: `lib/orbital_dynamics/campaign_planner.ex`,
  `test/orbital_dynamics/campaign_planner_test.exs`, and the listed docs.
- Definition of done: battery-depletion risks are counted in a
  dedicated score term and removed from generic risk count; score-term reports
  expose the new term; focused V3 tests and docs cover the split; locally
  reviewed, committed, and pushed without touching unrelated `.gitignore`.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `test/orbital_dynamics/campaign_planner_test.exs`
- `docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`
- `docs/feature_set/capability_map/11_planning_state_refresh/pressure_replay_into_branch_refresh.md`
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:19139`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:19139 test/orbital_dynamics/campaign_planner_test.exs:34709 test/orbital_dynamics/campaign_planner_test.exs:47606 test/orbital_dynamics/campaign_planner_test.exs:47245 test/orbital_dynamics/campaign_planner_test.exs:61759 test/orbital_dynamics/campaign_planner_test.exs:62917 test/orbital_dynamics/campaign_planner_test.exs:34675`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `git diff --cached --check`
- `rg -n 'battery_depletion_pressure_penalty|battery_depletion_pressure_risk|assert_battery_depletion_pressure_score_terms|Battery-depletion.*pressure|battery-depletion.*pressure|Projected battery-depletion|Resource-projection battery-depletion' lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs docs/feature_set/capability_map/07_ground_network/02_link_capacity.md docs/feature_set/capability_map/11_planning_state_refresh/pressure_replay_into_branch_refresh.md docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Docs/artifacts changed:
Ground-network, refresh pressure replay, and V3 orchestration docs now state
that resource-projection battery-depletion pressure contributes to
`battery_depletion_pressure_penalty` while storage/downlink projection pressure
stays in its existing dedicated term.

Local review:
Sidecar review could not start because the agent thread limit was reached.
Parent fallback review checked score arithmetic, generic-risk subtraction,
storage/downlink projection overlap, score-term report/tradeoff coverage,
focused tests, docs, and scope; no must-fix issues remained. `.gitignore`
remains unrelated and unstaged.

Level 6 pillar advanced:
V3 branch score terms now distinguish battery-depletion pressure from unrelated
generic risks while preserving total one-risk-weight branch score compatibility.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`7905319` Split battery depletion pressure score term.

Next candidate:
After this battery-depletion score-term split, reassess the next
planner-visible timeline/readiness or communications scoring gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
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
- `13d5acc` hardened stale lifecycle-state CandidateRefresh source-report
  summaries against stale top-level aggregates.
- `1af9828` hardened stale activity-precondition CandidateRefresh
  source-report summaries against stale top-level aggregates.
- `afbcf90` hardened stale activity-precondition V3 branch pressure against
  stale top-level aggregates by deriving pressure from row-local preconditions.
- `792e502` hardened stale lifecycle-state pressure against stale top-level
  aggregates by deriving branch pressure from row-local evidence.
- `120e936` hardened shared timeline preservation pressure helper coverage for
  split branch math and score-term report rows.
- `f7b4985` hardened shared timeline precondition pressure helper coverage for
  split branch math and score-term report rows.
