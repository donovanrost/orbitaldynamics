# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Harden stale link-capacity CandidateRefresh compact-summary replay.

Status:
Completed and pushed in product commit `72e824e`.

Slice-selection note:
- Selected slice: make compact CandidateRefresh link-capacity summaries derive
  station throughput, selected/actual contact, and shortfall pressure from
  embedded summary rows when rows are present.
- Why this slice: raw link-capacity reports already resist stale aggregate maps,
  but `link_capacity_summary.v1` inputs are treated as compact summaries and can
  still carry stale top-level station/throughput aggregates alongside row-local
  evidence.
- Level 6 pillar: fleet-level contact and communications allocation behavior;
  branch-local refresh provenance with challenge fixtures for stale-but-plausible
  inputs; reproducible branch trees with explainable downlink pressure.
- Current evidence gap: compact `link_capacity_summary.v1` inputs with embedded
  rows need row-derived source-report/replay station throughput and selected /
  actual contact maps so stale top-level aggregates cannot hide downlink pressure.
- Docs read:
  `docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`,
  `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`.
- Likely files/tests: `lib/orbital_dynamics/candidate_refresh.ex`,
  `test/orbital_dynamics/candidate_refresh_test.exs`, and the listed docs.
- Definition of done: stale top-level link-capacity compact-summary station and
  throughput aggregates no longer mask row-local summary rows in CandidateRefresh
  source-report summaries or replay summaries; docs record the row-derived
  compact-summary behavior; locally reviewed, committed, and pushed without
  touching unrelated `.gitignore`.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`
- `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:11995`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:10303 test/orbital_dynamics/candidate_refresh_test.exs:11867 test/orbital_dynamics/candidate_refresh_test.exs:11995`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `git diff --cached --check`
- `rg -n 'link_capacity_compact_summary_for_provenance|link capacity source summaries derive stale aggregate pressure from rows|compact summary carries embedded rows|Compact `link_capacity_summary\.v1`|Compact summaries with embedded rows derive' lib/orbital_dynamics/candidate_refresh.ex test/orbital_dynamics/candidate_refresh_test.exs docs/feature_set/capability_map/07_ground_network/02_link_capacity.md docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Docs/artifacts changed:
Link-capacity, refresh provenance, and V3 orchestration docs now state that
compact link-capacity summaries with embedded rows derive throughput,
selected/actual contact, source-window, station-calendar, and direction-routing
maps from rows before stale top-level summary aggregates are replayed.

Local review:
Sidecar review could not start because the agent thread limit was reached.
Parent fallback review checked row-derived compact-summary semantics, rowless
summary compatibility, stale aggregate coverage, docs, and scope; no must-fix
issues remained. `.gitignore` remains unrelated and unstaged.

Level 6 pillar advanced:
Stale-but-plausible compact link-capacity summaries now preserve row-local
station throughput, selected/actual contact routing, source-window routing, and
direction routing through CandidateRefresh source-report and replay summaries.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`72e824e` Harden link-capacity summary replay.

Next candidate:
After this link-capacity compact-summary hardening, reassess the next
planner-visible communications allocation or candidate-refresh gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
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
- `f3f4dbe` hardened shared execution-feedback pressure helper coverage for
  split branch math and score-term report rows.
- `0c59255` hardened shared relay data-path pressure helper coverage for split
  branch math and score-term report rows.
