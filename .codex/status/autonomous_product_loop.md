# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve actual-throughput ID routing in storage/downlink replay summaries.

Status:
Completed; handoff recorded for product commit `211d7fd`.

Slice-selection note:
- Selected slice: carry link-capacity actual-throughput contact, source-window,
  station-calendar entry, and provider-entry ID lists through
  `CandidateRefresh.storage_downlink_pressure_replay_summary/1`, and let
  list-only actual-throughput evidence set the branch-local actual-throughput
  pressure flag.
- Why this slice: the guide prioritizes resource/contact allocation semantics
  and branch-local candidate-refresh depth. The link-capacity source summary
  already derives actual-throughput ID lists, but the composed
  storage/downlink replay summary currently exposes only row counts and contact
  ID count maps.
- Level 6 pillar: refreshed candidates from current mission state and realized
  feedback; fleet-level resource/contact/downlink evidence; Cadence-facing
  artifact-only handoff surfaces.
- Current evidence gap: docs say actual-throughput row or contact evidence
  contributes to storage/downlink pressure, but list-only contact/source/station
  evidence is dropped from the composed replay summary and does not affect the
  actual-throughput pressure flag.
- Docs to read:
  `docs/autonomous_work_guide.md`,
  `.codex/prompts/long_running_context_efficient_product_loop.md`,
  `.codex/status/autonomous_product_loop.md`,
  `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`,
  `docs/feature_set/capability_map/14_v3_strategy_orchestration.md`,
  `docs/artifacts/field_families/candidate_refresh_artifact.md`.
- Likely files: `lib/orbital_dynamics/candidate_refresh.ex`,
  `test/orbital_dynamics/candidate_refresh_test.exs`,
  `docs/artifacts/field_families/candidate_refresh_artifact.md`,
  `.codex/status/autonomous_product_loop.md`.
- Likely tests:
  `mix test test/orbital_dynamics/candidate_refresh_test.exs:<storage_downlink_selectors>`,
  `mix compile --warnings-as-errors`,
  `git diff --check`.
- Definition of done: storage/downlink replay summaries expose actual-throughput
  contact/source-window/station/provider-entry ID lists from link-capacity
  provenance; list-only evidence drives `branch_local_actual_throughput_pressure`
  and composed downlink/storage-downlink pressure; focused candidate-refresh
  tests pass.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:11257 test/orbital_dynamics/candidate_refresh_test.exs:11513 test/orbital_dynamics/candidate_refresh_test.exs:14240 test/orbital_dynamics/candidate_refresh_test.exs:14272 test/orbital_dynamics/candidate_refresh_test.exs:14320`
- `mix compile --warnings-as-errors`
- `git diff --check`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs`

Docs/artifacts changed:
- `docs/artifacts/field_families/candidate_refresh_artifact.md` now says the
  composed storage/downlink replay summary preserves actual-throughput contact
  count maps plus contact/source-window/station-calendar entry/provider-entry
  ID lists, and that row/count/list evidence drives composed pressure without
  implying shortfall.

Local review:
- Read-only reviewer `Linnaeus` found no blockers. The reviewer confirmed the
  storage/downlink helper preserves the four actual-throughput ID-list fields,
  emits them in the replay output, and lets list-only evidence drive
  actual-throughput/downlink/storage-downlink pressure without setting storage,
  capacity-adjusted-throughput, or shortfall pressure. The initial per-field
  granularity gap was closed with a looped regression that tests each ID-list
  field as the sole evidence source.

Level 6 pillar advanced:
Candidate-refresh replay fidelity for realized downlink evidence: composed
storage/downlink summaries now preserve actual-throughput ID routing evidence
from link-capacity provenance and treat list-only evidence as branch-local
actual-throughput/downlink/storage-downlink pressure without mutating allocation
or projection state.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last product commit:
`211d7fd` Preserve actual-throughput ID replay pressure.

Next candidate:
After this storage/downlink replay slice, continue with planner-visible
resource/contact/readiness evidence that affects V2/V3 branch scoring or
candidate-refresh provenance.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `211d7fd` preserved actual-throughput ID replay pressure in composed
  storage/downlink summaries.
- `1054d07` exposed operational timeline duplicate rollups in schema.
- `aec452f` refreshed the V3 score-term compatibility fixture.
- `a74eae0` split timeline pressure into an explicit V3 score term.
- `c896321` split readiness/quality pressure into an explicit V3 score term.
- `7dd93f5` split contact-allocation pressure into an explicit V3 score term.
- `ae950a5` exposed reservation-conflict identities in branch comparison rows.
- `eae9483` derived operational-readiness gate pressure classification from
  row-local status.
- Earlier published slices covered schema-validation, operator-training,
  unavailable-resource, provider-counteroffer/reservation, lifecycle,
  publication/dependency/integrity, contact-allocation, and direction-routing
  pressure paths.

Blocked:
No.
