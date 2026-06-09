# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Harden stale relay data-path CandidateRefresh compact-summary replay.

Status:
Completed and pushed in product commit `24adf78`.

Slice-selection note:
- Selected slice: make compact CandidateRefresh relay data-path summaries derive
  relay/direct route counts, status maps, route IDs, spacecraft IDs, and ground
  downlink contact routing from embedded rows when rows are present.
- Why this slice: relay data-path summaries share the link-capacity provenance
  family and already carry rows, but stale top-level route/status maps can still
  mask row-local relay pressure in source-report and replay summaries.
- Level 6 pillar: fleet-level contact and communications allocation behavior;
  branch-local refresh provenance with challenge fixtures for stale-but-plausible
  inputs; reproducible branch trees with explainable relay/downlink pressure.
- Current evidence gap: compact `relay_data_path_summary.v1` inputs with embedded
  rows need row-derived source-report/replay route counts, status maps, route
  IDs, and ground downlink contact IDs so stale top-level aggregates cannot hide
  relay path pressure.
- Docs read:
  `docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`,
  `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`.
- Likely files/tests: `lib/orbital_dynamics/candidate_refresh.ex`,
  `test/orbital_dynamics/candidate_refresh_test.exs`, and the listed docs.
- Definition of done: stale top-level relay data-path compact-summary route and
  status aggregates no longer mask row-local summary rows in CandidateRefresh
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
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:12264`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:12140 test/orbital_dynamics/candidate_refresh_test.exs:12264 test/orbital_dynamics/candidate_refresh_test.exs:12345`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:10303 test/orbital_dynamics/candidate_refresh_test.exs:11867 test/orbital_dynamics/candidate_refresh_test.exs:11995`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `git diff --cached --check`
- `rg -n 'relay data path source summaries derive stale aggregate pressure from rows|relay_data_path_summary_source\?|relay_data_path_summary\(source|link_capacity_compact_summary_metadata|Compact `relay_data_path_summary\.v1`|embedded rows are present|Compact relay summaries with embedded rows' lib/orbital_dynamics/candidate_refresh.ex test/orbital_dynamics/candidate_refresh_test.exs docs/feature_set/capability_map/07_ground_network/02_link_capacity.md docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Docs/artifacts changed:
Link-capacity, refresh provenance, and V3 orchestration docs now state that
compact relay data-path summaries with embedded rows derive relay/direct route
counts, status maps, route IDs, spacecraft IDs, and ground downlink contact IDs
from rows before stale top-level summary aggregates are replayed.

Local review:
Sidecar review could not start because the agent thread limit was reached.
Parent fallback review checked row-derived compact-summary semantics, metadata
preservation for wrapped relay summaries, stale aggregate coverage, docs, and
scope; no must-fix issues remained. `.gitignore` remains unrelated and unstaged.

Level 6 pillar advanced:
Stale-but-plausible compact relay data-path summaries now preserve row-local
relay/direct route counts, status maps, route IDs, spacecraft IDs, and ground
downlink contact IDs through CandidateRefresh source-report and replay summaries.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`24adf78` Harden relay data-path summary replay.

Next candidate:
After this relay data-path compact-summary hardening, reassess the next
planner-visible communications allocation or candidate-refresh gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
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
- `f3f4dbe` hardened shared execution-feedback pressure helper coverage for
  split branch math and score-term report rows.
- `0c59255` hardened shared relay data-path pressure helper coverage for split
  branch math and score-term report rows.
