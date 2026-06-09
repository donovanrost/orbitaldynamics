# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Split relay data-path pressure into an explicit V3 score term.

Status:
Completed and pushed in product commit `c0110a9`.

Slice-selection note:
- Selected slice: make V3 relay data-path branch risks score-visible through a
  dedicated `relay_data_path_pressure_penalty` term instead of blending them
  into generic `risk_penalty`.
- Why this slice: relay data-path summaries already generate branch-local
  link-capacity pressure, typed risk indicators, CandidateRefresh replay
  metadata, and branch-comparison rows, but the existing focused test still
  asserts only generic `risk_penalty` for that pressure.
- Level 6 pillar: reproducible V1/V2/V3 branch trees with explainable score
  terms and deltas; fleet-level contact, relay, and downlink behavior.
- Current evidence gap: V3 can derive relay data-path pressure branches and
  replay their source reports, but score attribution is less explainable than
  recently split contact, station-calendar, validation/refresh, and provider
  pressure.
- Docs to read:
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`.
- Likely files:
  `lib/orbital_dynamics/campaign_planner.ex`,
  `test/orbital_dynamics/campaign_planner_test.exs`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`,
  `.codex/status/autonomous_product_loop.md`.
- Likely tests:
  focused campaign-planner relay data-path branch derivation test;
  `mix compile --warnings-as-errors`; `git diff --check`.
- Definition of done: relay data-path pressure risks are counted in
  `relay_data_path_pressure_penalty`, removed from generic `risk_penalty`,
  surfaced in strategy score-term reports and recommendation tradeoffs, covered
  by the existing focused relay data-path test, documented in the V3 score-term
  section, locally reviewed, committed, and pushed without touching unrelated
  `.gitignore`.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `test/orbital_dynamics/campaign_planner_test.exs`
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:27111`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `rg -n "relay_data_path_pressure_(penalty|risk)|Relay data-path pressure score terms|relay data-path pressure risks contribute" lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Docs/artifacts changed:
The V3 strategy-orchestration score-term sections now document
`relay_data_path_pressure_penalty`.

Local review:
Parent local review confirmed the diff is limited to planner score accounting,
the existing relay data-path branch test, the V3 score-term doc, and this
ledger. `.gitignore` remains unrelated and unstaged.

Level 6 pillar advanced:
V3 branch scoring now exposes relay data-path custody, latency, and route-risk
pressure as an explicit score term and recommendation tradeoff dimension while
preserving total score compatibility by removing those risks from generic
`risk_penalty`.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`c0110a9` Split relay data path pressure score term.

Next candidate:
After this score-term split, continue with the next planner-visible
resource/contact/readiness or candidate-refresh provenance gap from the guide.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `c0110a9` split relay data-path pressure into an explicit V3 score term and
  recommendation tradeoff dimension.
- `dba9b34` split validation/refresh governance pressure into an explicit V3
  score term and recommendation tradeoff dimension.
- `1c43e21` clarified prompt/guide fallback behavior when sidecar review or
  publish tools are unavailable.
- `c564585` split provider-counteroffer pressure into an explicit V3 score term.
- `e679918` made candidate-rejection pressure score-visible and split it into
  an explicit V3 score term.
- `25da839` split station-calendar pressure into an explicit V3 score term.
- `91b7f03` preserved compact station-calendar precedence reservation routing
  through CandidateRefresh source-report and replay summaries.
- `7b80988` preserved suppressed reservation ID/status/owner routing in
  station-calendar precedence summaries.
- `630bb44` split storage/downlink pressure into an explicit V3 score term.

Blocked:
No.
