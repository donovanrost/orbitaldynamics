# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Harden stale lifecycle-state CandidateRefresh source summaries.

Status:
Completed and pushed in product commit `13d5acc`.

Slice-selection note:
- Selected slice: make CandidateRefresh lifecycle-state source-report summaries
  derive review, duplicate-identity, invalid-input, action, and routing pressure
  from row-local lifecycle evidence when rows are present.
- Why this slice: V3 lifecycle branch pressure already resists stale top-level
  lifecycle aggregates, but CandidateRefresh source-report summaries can still
  replay stale aggregate-shaped lifecycle fields into branch-local pressure
  summaries.
- Level 6 pillar: durable timeline semantics; validation and challenge fixtures
  for stale-but-plausible inputs; reproducible V3 branch trees with explainable
  score terms and deltas.
- Current evidence gap: stale top-level lifecycle summary counts/maps can hide
  row-local review, duplicate-identity, and invalid-input pressure in
  CandidateRefresh source-report provenance and replay summaries.
- Docs read:
  `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`.
- Definition of done: stale top-level lifecycle aggregates no longer mask
  row-local lifecycle review/invalid/duplicate pressure in CandidateRefresh
  source-report summaries or replay flags; docs record the row-derived
  source-summary behavior; locally reviewed, committed, and pushed without
  touching unrelated `.gitignore`.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:20538 test/orbital_dynamics/candidate_refresh_test.exs:20916`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `rg -n "put_row_derived_timeline_lifecycle_state_summary_pressure|timeline_lifecycle_state_review_timeline_ids_by|timeline lifecycle state source summaries derive stale aggregate pressure|Timeline lifecycle-state source summaries|row-local lifecycle|review_required_count" lib/orbital_dynamics/candidate_refresh.ex test/orbital_dynamics/candidate_refresh_test.exs docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Docs/artifacts changed:
Refresh provenance and V3 orchestration docs now state that lifecycle-state
source summaries derive review, duplicate-identity, invalid-input, action,
transition-category, and routing pressure from lifecycle rows when row evidence
is present.

Local review:
Sidecar review could not start because the agent thread limit was reached.
Parent fallback review checked the staged product diff for row-derived
semantics, stale aggregate coverage, docs, and scope; no must-fix issues
remained. `.gitignore` remains unrelated and unstaged.

Level 6 pillar advanced:
Stale-but-plausible lifecycle-state inputs now preserve row-local review,
duplicate-identity, and invalid-input pressure through CandidateRefresh
source-report summaries, replay summaries, branch-local pressure flags, and
review routing.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`13d5acc` Harden lifecycle source-report summaries.

Next candidate:
After this lifecycle source-summary hardening, reassess the next
planner-visible candidate-refresh or timeline-semantics gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
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
- `f3f4dbe` hardened shared execution-feedback pressure helper coverage for
  split branch math and score-term report rows.
- `0c59255` hardened shared relay data-path pressure helper coverage for split
  branch math and score-term report rows.
