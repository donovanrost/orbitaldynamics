# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Harden stale activity-precondition pressure row evidence.

Status:
Completed and pushed in product commit `afbcf90`.

Slice-selection note:
- Selected slice: add a stale aggregate challenge for timeline activity
  precondition summaries and make V3 branch pressure derive blocked/review
  counts and type maps from row-local precondition evidence when rows are
  present.
- Why this slice: lifecycle and preservation pressure now resist stale
  top-level aggregates, while activity-precondition pressure still has the same
  stale-but-plausible input risk.
- Level 6 pillar: durable timeline semantics; validation and challenge fixtures
  for stale-but-plausible inputs; reproducible V3 branch trees with explainable
  score terms and deltas.
- Current evidence gap closed: stale precondition summary aggregate status,
  count, and type fields no longer mask row-local blocked or review-required
  pressure before the planner derives branch pressure.
- Docs read:
  `docs/feature_set/capability_map/08_mission_activities_and_timelines.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`.
- Definition of done: stale top-level precondition aggregate counts no longer
  mask row-local blocked/review pressure in V3 branches; score terms and branch
  comparison rows still expose the pressure; docs record the challenge behavior;
  locally reviewed, committed, and pushed without touching unrelated `.gitignore`.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `test/orbital_dynamics/campaign_planner_test.exs`
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:30145 test/orbital_dynamics/campaign_planner_test.exs:30345`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `rg -n "timeline_activity_precondition_rows_pressure_count|bogus_blocked_row_type|row-local precondition evidence|stale aggregate challenge" lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Docs/artifacts changed:
The V3 strategy-orchestration docs now state that activity-precondition branch
pressure derives status, blocked/review counts, and type lists from row-local
precondition evidence when rows are present, so stale aggregate fields cannot
hide blocked or review-required pressure.

Local review:
Read-only review found the first helper version still trusted aggregate-shaped
fields embedded in rows. Fixed by deriving counts and types only from each
precondition row's `status` and `type`; the stale challenge fixture now poisons
row-local aggregate fields to prove they are ignored. Parent review confirmed
the final staged product diff was limited to CampaignPlanner, the focused test,
and the V3 doc note. `.gitignore` remains unrelated and unstaged.

Level 6 pillar advanced:
Stale-but-plausible activity-precondition inputs now preserve row-local
blocked/review pressure through V3 branch derivation, risk indicators, score
terms, and branch comparison rows.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`afbcf90` Harden stale precondition pressure evidence.

Next candidate:
After this stale precondition challenge, reassess the next planner-visible
candidate-refresh or timeline-semantics gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
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
- `f3f4dbe` hardened shared execution-feedback pressure helper coverage for
  split branch math and score-term report rows.
- `0c59255` hardened shared relay data-path pressure helper coverage for split
  branch math and score-term report rows.
