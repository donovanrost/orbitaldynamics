# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Harden stale activity-precondition CandidateRefresh source summaries.

Status:
Completed and pushed in product commit `1af9828`.

Slice-selection note:
- Selected slice: make CandidateRefresh activity-precondition source-report
  summaries derive status, blocked/review counts, and type maps from row-local
  precondition evidence when rows are present.
- Why this slice: V3 branch pressure now resists stale top-level
  activity-precondition aggregates, but CandidateRefresh source-report
  summaries can still replay stale aggregate-shaped fields into branch-local
  pressure summaries.
- Level 6 pillar: durable timeline semantics; validation and challenge fixtures
  for stale-but-plausible inputs; reproducible V3 branch trees with explainable
  score terms and deltas.
- Current evidence gap: stale top-level precondition summary status/count/type
  fields can hide row-local blocked or review-required preconditions in
  CandidateRefresh source-report provenance and replay summaries.
- Docs read:
  `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`.
- Definition of done: stale top-level activity-precondition aggregates no longer
  mask row-local blocked/review pressure in CandidateRefresh source-report
  summaries or replay flags; docs record the row-derived source-summary
  behavior; locally reviewed, committed, and pushed without touching unrelated
  `.gitignore`.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:25209 test/orbital_dynamics/candidate_refresh_test.exs:25548`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `rg -n "timeline_activity_precondition_summary_precondition_count|timeline_activity_precondition_precondition_rows_status|timeline_activity_precondition_precondition_row_status|timeline activity precondition source summaries derive stale aggregate pressure|Timeline activity-precondition source summaries derive|branch-local replay pressure|CandidateRefresh replay pressure|bogus_blocked_row_type|precondition_status" lib/orbital_dynamics/candidate_refresh.ex test/orbital_dynamics/candidate_refresh_test.exs docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Docs/artifacts changed:
Refresh provenance and V3 orchestration docs now state that activity-precondition
source summaries derive status, blocked/review counts, and type maps from
precondition rows when row evidence is present, preventing stale aggregate
fields from hiding branch-local replay pressure.

Local review:
Read-only review found two must-fix issues: the first helper version treated
row-local `precondition_status` as a precondition-row status alias, and the
ledger named the umbrella planning-state doc instead of the nested provenance
doc. Fixed the helper to read only precondition-row `status`, poisoned
row-local `precondition_status` in the stale fixture, and corrected the ledger
path. Parent review confirmed the final staged product diff was limited to
CandidateRefresh, the focused test, and the two doc notes. `.gitignore` remains
unrelated and unstaged.

Level 6 pillar advanced:
Stale-but-plausible activity-precondition inputs now preserve row-local
blocked/review pressure through CandidateRefresh source-report summaries,
replay summaries, branch-local pressure flags, and row-only review/import
handoffs.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`1af9828` Harden precondition source-report summaries.

Next candidate:
After this CandidateRefresh source-summary hardening, reassess the next
planner-visible candidate-refresh or timeline-semantics gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
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
- `f3f4dbe` hardened shared execution-feedback pressure helper coverage for
  split branch math and score-term report rows.
- `0c59255` hardened shared relay data-path pressure helper coverage for split
  branch math and score-term report rows.
