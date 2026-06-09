# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Split timeline lifecycle pressure out of generic V3 risk scoring.

Status:
Published locally in product commit `a74eae0`; handoff commit pending.

Slice-selection note:
- Selected slice: split timeline integrity, lifecycle, precondition,
  preservation, dependency-impact, and publication pressure risks out of
  generic V3 `risk_penalty` into an explicit timeline-pressure score term while
  preserving total score for fixed inputs.
- Why this slice: the guide prioritizes typed operational activity and timeline
  semantics, and the roadmap asks for timeline integrity/publication pressure
  to be planner-visible in branch scoring. Live code already derives the
  pressure branches, but their score effect is hidden in generic risk count.
- Level 6 pillar: typed operational activity semantics and reproducible V3
  branch trees with explainable score terms and deltas.
- Current evidence gap: timeline integrity, lifecycle, precondition, and
  preservation pressure rows expose routing context and branch-comparison
  fields, but score-term reports/tradeoffs do not isolate timeline pressure
  from unrelated risk pressure.
- Docs read:
  `docs/autonomous_work_guide.md`,
  `.codex/prompts/long_running_context_efficient_product_loop.md`,
  `.codex/status/autonomous_product_loop.md`,
  `docs/feature_set/capability_map/08_mission_activities_and_timelines.md`,
  `docs/feature_set/capability_map/08_mission_activities/integrity-rejection-and-preservation-reports.md`,
  `docs/feature_set/capability_map/08_mission_activities/lifecycle-helpers-diffs-and-transitions.md`,
  `docs/mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md`,
  `docs/artifacts/field_families/mission_activities.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`.
- Likely files: `lib/orbital_dynamics/campaign_planner.ex`,
  `test/orbital_dynamics/campaign_planner_test.exs`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`,
  `.codex/status/autonomous_product_loop.md`.
- Definition of done: timeline pressure contributes an explicit V3
  score term and score-term report key; generic risk penalty excludes those
  same risks so total score remains compatible; focused planner tests, compile,
  and whitespace checks pass.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `test/orbital_dynamics/campaign_planner_test.exs`
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:29393 test/orbital_dynamics/campaign_planner_test.exs:29612 test/orbital_dynamics/campaign_planner_test.exs:29805 test/orbital_dynamics/campaign_planner_test.exs:29967 test/orbital_dynamics/campaign_planner_test.exs:30181`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:29393 test/orbital_dynamics/campaign_planner_test.exs:29612 test/orbital_dynamics/campaign_planner_test.exs:29805 test/orbital_dynamics/campaign_planner_test.exs:29967 test/orbital_dynamics/campaign_planner_test.exs:30181` with exact current line selectors
- `mix test test/orbital_dynamics/campaign_planner_test.exs`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:28458 test/orbital_dynamics/campaign_planner_test.exs:28632 test/orbital_dynamics/campaign_planner_test.exs:29393 test/orbital_dynamics/campaign_planner_test.exs:29612 test/orbital_dynamics/campaign_planner_test.exs:29805 test/orbital_dynamics/campaign_planner_test.exs:29967 test/orbital_dynamics/campaign_planner_test.exs:30181` after reviewer coverage fix
- `mix compile --warnings-as-errors`
- `git diff --check`

Docs/artifacts changed:
- Documented `timeline_pressure_penalty` in the V3 strategy orchestration
  capability notes.

Local review:
- V3 strategy score terms now split timeline integrity, dependency-impact,
  publication, lifecycle-state, activity-lifecycle, activity-precondition, and
  preservation pressure into `timeline_pressure_penalty`, while generic
  `risk_penalty` retains unrelated risks. Raw score still applies one
  `risk_weight` penalty per risk indicator, preserving total branch-score
  compatibility for fixed inputs. Focused tests assert exact timeline risk
  counts, exact split penalties, score-term report rows/keys, and the new
  recommendation tradeoff dimension. Read-only reviewer `Halley` found that
  dependency-impact and publication risks were not covered by exact split
  assertions; tests were tightened accordingly.

Level 6 pillar advanced:
Planner-visible timeline lifecycle and integrity score explanations without
ranking drift.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last commit:
`a74eae0` Split timeline pressure score term.

Next candidate:
After this slice, inspect whether a compatibility fixture or lifecycle
challenge test is higher-value.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `c896321` split readiness/quality pressure into an explicit V3 score term.
- `7dd93f5` split contact-allocation pressure into an explicit V3 score term.
- `ae950a5` exposed reservation-conflict identities in branch comparison rows.
- `eae9483` derived operational-readiness gate pressure classification from
  row-local status.
- `110ba8e` hardened timeline-preservation pressure status against stale
  aggregate report status.
- `df963da` exposed contact-allocation pressure status in branch comparison rows.
- `d3cd30f` derived prior-plan readiness and quality-gate pressure branches.
- `4904a47` derived station-reservation review summary pressure branches.
- `3920603` derived relay data-path summary pressure branches.
- Earlier published slices covered schema-validation, operator-training,
  unavailable-resource, provider-counteroffer/reservation, lifecycle,
  publication/dependency/integrity, contact-allocation, and direction-routing
  pressure paths.

Blocked:
No.
