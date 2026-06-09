# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Split candidate-rejection pressure into an explicit V3 score term.

Status:
Completed and pushed in product commit `e679918`.

Slice-selection note:
- Selected slice: V3 strategy scoring should classify candidate-rejection
  pressure into a dedicated score term instead of leaving it inside generic
  `risk_penalty`.
- Why this slice: typed activity candidate-rejection reports and CandidateRefresh
  replay are already mature, and V3 derives branch-local
  `candidate_rejection_pressure` branches from mission-state reports. The
  scoring surface still hides those review-required rejected-candidate risks in
  generic risk.
- Level 6 pillar: reproducible V1/V2/V3 branch trees with explainable score
  terms and deltas.
- Current evidence gap: V3 derives `candidate_rejection_pressure` events with
  `feedback_scope: candidate_rejection`, but those events were not yet
  score-visible as risk indicators or split into a typed pressure score term.
- Docs to read:
  `docs/autonomous_work_guide.md`,
  `.codex/prompts/long_running_context_efficient_product_loop.md`,
  `.codex/status/autonomous_product_loop.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`,
  `docs/artifacts/field_families/mission_activities.md`,
  `test/orbital_dynamics/campaign_planner_test.exs`.
- Likely files: `lib/orbital_dynamics/campaign_planner.ex`,
  `test/orbital_dynamics/campaign_planner_test.exs`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`,
  `.codex/status/autonomous_product_loop.md`.
- Likely tests:
  `mix test test/orbital_dynamics/campaign_planner_test.exs:<candidate-rejection-selector>`,
  `mix compile --warnings-as-errors`, `git diff --check`.
- Definition of done: candidate-rejection branch events become risk indicators;
  V3 score terms include `candidate_rejection_pressure_penalty`; generic
  `risk_penalty` excludes those candidate-rejection risks; branch score-term
  reports expose the new key; docs mention the split; focused tests/compile
  pass.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `test/orbital_dynamics/campaign_planner_test.exs`
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:42621`
- `mix compile --warnings-as-errors`
- `git diff --check`

Docs/artifacts changed:
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md` documents
  candidate-rejection pressure risk scoring and score-term split.

Local review:
- Parent local review found the slice scoped to candidate-rejection event risk
  mapping, V3 score-term classification, score-report/tradeoff exposure,
  focused mission-state candidate-rejection assertions, and V3 strategy docs.
  No multi-agent reviewer was used because the available delegation tool
  requires an explicit user request for subagents in this turn.

Level 6 pillar advanced:
Typed activity branch refresh and V3 branch scoring: candidate-rejection
pressure is now score-visible and separated from generic risk.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`e679918` Score candidate rejection pressure explicitly.

Next candidate:
Continue with planner-visible resource/contact/readiness evidence that affects
V2/V3 branch scoring or candidate-refresh provenance, or move to the next
highest guide item after a fresh status check.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `e679918` made candidate-rejection pressure score-visible and split it into
  an explicit V3 score term.
- `25da839` split station-calendar pressure into an explicit V3 score term.
- `91b7f03` preserved compact station-calendar precedence reservation routing
  through CandidateRefresh source-report and replay summaries.
- `7b80988` preserved suppressed reservation ID/status/owner routing in
  station-calendar precedence summaries.
- `630bb44` split storage/downlink pressure into an explicit V3 score term.
- Earlier published slices covered actual-throughput storage/downlink replay,
  operational timeline duplicate rollups, V3 compatibility fixtures, timeline,
  readiness/quality, contact-allocation, reservation-conflict, and
  operational-readiness gate scoring/routing paths.

Blocked:
No.
