# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Harden stale contact-intent CandidateRefresh source/replay routing.

Status:
Completed and pushed in product commit `7efd232`.

Slice-selection note:
- Selected slice: make compact CandidateRefresh contact-intent summaries derive
  direction routing, capacity-pack fractions, and contact IDs from row-local
  contact-intent evidence when rows are present.
- Why this slice: contact-intent direction routing is now present in source and
  replay summaries, but stale top-level compact summary maps could still hide or
  misroute row-local contact/capacity pressure.
- Level 6 pillar: fleet-level contact and communications allocation behavior;
  branch-local refresh provenance with challenge fixtures for stale-but-plausible
  inputs; reproducible branch trees with explainable contact pressure.
- Current evidence gap: compact `contact_intent_summary` inputs with row
  evidence need a stale-aggregate challenge so source reports and replay
  summaries trust row-local contact-intent rows over stale aggregate maps.
- Docs read:
  `docs/feature_set/capability_map/07_ground_network_and_communications_planning.md`,
  `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`.
- Likely files/tests: `lib/orbital_dynamics/candidate_refresh.ex`,
  `test/orbital_dynamics/candidate_refresh_test.exs`, and the listed docs.
- Definition of done: stale top-level contact-intent aggregate maps no longer
  mask row-local direction, station, capacity-pack, or contact-ID routing in
  CandidateRefresh source-report summaries or replay summaries; docs record the
  row-derived compact-summary behavior; locally reviewed, committed, and pushed
  without touching unrelated `.gitignore`.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `docs/feature_set/capability_map/07_ground_network/05_contact_intent_refresh_and_allocation_policy.md`
- `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`
- `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:3588`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:3366 test/orbital_dynamics/candidate_refresh_test.exs:3588 test/orbital_dynamics/candidate_refresh_test.exs:3746`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `git diff --cached --check`
- `rg -n 'contact_intent_compact_summary_for_provenance|compact contact intent source summaries derive stale aggregate routing from rows|embedded rows derive|row-derived compact-summary|Compact `contact_intent_summary\.v1`' lib/orbital_dynamics/candidate_refresh.ex test/orbital_dynamics/candidate_refresh_test.exs docs/feature_set/capability_map/07_ground_network/05_contact_intent_refresh_and_allocation_policy.md docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md docs/feature_set/capability_map/14_v3_strategy_orchestration.md`

Docs/artifacts changed:
Ground-network contact-intent, refresh provenance, and V3 orchestration docs now
state that compact contact-intent summaries with embedded rows derive
station/direction capacity maps, contact-ID maps, and direction routing from
rows before stale aggregate fields are replayed.

Local review:
Sidecar review could not start because the agent thread limit was reached.
Parent fallback review checked the product diff for row-derived semantics,
rowless compact-summary compatibility, stale aggregate coverage, docs, and
scope; no must-fix issues remained. `.gitignore` remains unrelated and
unstaged.

Level 6 pillar advanced:
Stale-but-plausible compact contact-intent summaries now preserve row-local
direction, station, capacity-pack, and contact-ID routing through
CandidateRefresh source-report summaries and replay summaries.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`7efd232` Harden contact-intent summary replay.

Next candidate:
After this contact-intent source/replay hardening, reassess the next
planner-visible communications allocation or candidate-refresh gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
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
