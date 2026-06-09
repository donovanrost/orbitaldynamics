# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Split contact-filter pressure into planner-visible V3 score terms.

Status:
Completed and pushed in product commit `fbffb6b`.

Slice-selection note:
- Selected slice: give contact-filter `downlink_completion_gap` risks a
  dedicated V3 `contact_filter_pressure_penalty` score term.
- Why this slice: contact-filter pressure already derives branch-local refresh
  branches from prior-plan, mission-state, result-artifact, and
  candidate-refresh-preserved suppression rows, but it still shares generic
  `risk_penalty` while adjacent communications pressure families have dedicated
  terms.
- Level 6 pillar: fleet-level communications allocation behavior; reproducible
  V3 branch trees with explainable score terms and deltas.
- Current evidence gap: planner-visible score-term reports should distinguish
  contact-filter downlink suppression pressure from unrelated generic risks
  while preserving total branch score compatibility.
- Docs read:
  `docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`,
  `docs/feature_set/capability_map/11_planning_state_refresh/pressure_replay_into_branch_refresh.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`.
- Likely files/tests: `lib/orbital_dynamics/campaign_planner.ex`,
  `test/orbital_dynamics/campaign_planner_test.exs`, and the listed docs.
- Definition of done: contact-filter pressure risks are counted in a
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
- `mix test test/orbital_dynamics/campaign_planner_test.exs:47706 test/orbital_dynamics/campaign_planner_test.exs:47833`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:47706 test/orbital_dynamics/campaign_planner_test.exs:47833 test/orbital_dynamics/campaign_planner_test.exs:46028 test/orbital_dynamics/campaign_planner_test.exs:46635 test/orbital_dynamics/campaign_planner_test.exs:48182 test/orbital_dynamics/campaign_planner_test.exs:41362 test/orbital_dynamics/campaign_planner_test.exs:20867`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `git diff --cached --check`
- `rg -n 'contact_filter_pressure_penalty|contact_filter_pressure_risk|assert_contact_filter_pressure_score_terms|Contact-filter.*pressure|contact-filter.*pressure|filtered contact-window pressure' lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs docs/feature_set/capability_map/07_ground_network/02_link_capacity.md docs/feature_set/capability_map/11_planning_state_refresh/pressure_replay_into_branch_refresh.md docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Docs/artifacts changed:
Ground-network, refresh pressure replay, and V3 orchestration docs now state
that contact-filter downlink suppression pressure contributes to
`contact_filter_pressure_penalty` while generic `risk_penalty` remains for
unrelated risks.

Local review:
Sidecar review could not start because the agent thread limit was reached.
Parent fallback review checked score arithmetic, generic-risk subtraction,
score-term report/tradeoff coverage, focused tests, docs, and scope; no
must-fix issues remained. `.gitignore` remains unrelated and unstaged.

Level 6 pillar advanced:
V3 branch score terms now distinguish contact-filter downlink suppression
pressure from unrelated generic risks while preserving total one-risk-weight
branch score compatibility.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`fbffb6b` Split contact-filter pressure score term.

Next candidate:
After this contact-filter score-term split, reassess resource-filter pressure
scoring or the next planner-visible timeline/readiness gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
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
- `9dca476` hardened shared timeline lifecycle-state pressure helper coverage
  for split branch math and score-term report rows.
- `f7c09e1` hardened shared timeline-publication pressure helper coverage for
  split branch math and score-term report rows.
- `f94585e` hardened shared timeline dependency-impact pressure helper coverage
  for split branch math and score-term report rows.
