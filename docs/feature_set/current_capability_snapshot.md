# Current Capability Snapshot

Implemented or partially implemented modules and artifacts include:

- Core nouns: `CentralBody`, `Epoch`, `Frame`, `StateVector`, `Spacecraft`,
  `Scenario`, `Trajectory`, `GroundStation`, and `Target`.
- Contracts: `Propagator`, `BatchPropagator`, `EventDetector`, and `Constraint`.
- Propagators: `Propagators.TwoBody`, `Propagators.J2`,
  `Propagators.TwoBodyDrag`, `Propagators.J2Drag`,
  `Propagators.TwoBodyNx`, `Propagators.TwoBodyNxCompiled`,
  `Propagators.TwoBodyExlaCpu`, and `Propagators.J2ExlaCpu`.
- Execution: `ScenarioRunner`, `StudyRunner`, `Study`, `StudyRun`,
  distributed task-supervisor options, task chunking, and batch propagation.
- Events: `EventDetectors.AccessWindows`,
  `EventDetectors.TargetVisibility`, `EventDetectors.Eclipses`, and sampled
  `EventDetectors.GroundTrackCrossings`.
- Search and scoring: `Search.Grid`, `Search.MonteCarlo`, `Search.Local`,
  `Constraints.ArtifactMetric`, report ranking metrics, opt-in bounded
  explainable local search, and a standalone executable certificate for exact
  enumeration of one declared finite local neighborhood. The certificate makes
  no global-optimality claim and is not a V1/V2/V3 default.
- Mission planning: `MissionPlan`, `MissionPlan.Activity`, and
  `Maneuver.ImpulsiveBurn`.
- Artifacts and reports: `ResultSet`, `ResultSet.Artifact`,
  `ResultSet.Report`, benchmark artifacts, study benchmark artifacts, and Mix
  report tasks.
- Product planning: `CampaignPlanner.build/2` for V1, `CampaignPlanner.repair/1`
  for V2, and `CampaignPlanner.strategy/1` for V3, with top-level
  `OrbitalDynamics.campaign_plan/2`, `OrbitalDynamics.campaign_repair/1`, and
  `OrbitalDynamics.campaign_strategy/1` facades over the in-memory planner
  entry points.
- Artifact contracts: `OrbitalDynamics.Schema` executable contracts for V1
  campaign plans, V2 repair artifacts, V3 strategy artifacts,
  candidate-refresh artifacts, accepted planning-state snapshots, and reference
  fixture reports, plus `mix orbital_dynamics.schema.lint` for saved JSON
  artifact validation and `mix orbital_dynamics.schema.export` for top-level
  JSON Schema exports.
- Validation registry: `OrbitalDynamics.Validation` records validation levels,
  tolerance metadata, evidence, and known limits for current propagators and
  event detectors, and result artifacts archive the relevant records. The
  scalar `J2Drag` record includes a 24-hour 10 s versus 5 s internal
  step-convergence fixture; it is educational convergence evidence rather than
  external acceptance.
- Environment registry: `OrbitalDynamics.Environment` records simplified fixed
  Sun and constant Earth-rotation capability records in result artifacts and
  exposes provider capability boundaries for fixed Sun, constant Earth rotation,
  and a reference exponential atmosphere-density interface.
- Subsystem model registry: `OrbitalDynamics.SubsystemModel` now exposes a
  schema-validated `subsystem_model_capability.v1` record set for
  planning-grade battery energy storage and data-recorder storage buffering,
  giving resource-flow evidence an explicit model identity/provenance boundary
  before full spacecraft configuration exists.
- Operational activity and timeline artifacts: typed activity context,
  lifecycle state helpers, transition-application reports and summaries,
  dependency/exclusivity integrity reports, timeline diffs, publication
  summaries, operational timeline reports, timeline feedback reports, and
  Cadence-facing review/import handoffs preserve status, approval, lock,
  execution, source-window, station-calendar, resource, command, contact,
  observation, maneuver, and feedback evidence without granting schedule,
  approval, import, or execution authority.
- Resource and communications planning artifacts: contact allocation,
  link-capacity, station-calendar, provider-reservation, reservation-hold,
  provider-counteroffer, resource-summary, resource-projection, unavailable
  resource, contention, contact-suppression, and resource-suppression reports
  expose schema-validated operator-review evidence for directionality,
  reservation pressure, station availability, capacity effects, storage/downlink
  roll-forward, and ignored terminal or approval-rejected activity effects.
  Strategy recommendation review/import handoffs also require all 27 resource-
  filter availability, margin, operator-training, identity, timing, status,
  value, and provenance fields to stay source exact across direct and review-
  derived Cadence rows. The parallel resource-margin context preserves all 22
  field/value, threshold, timing, review, identity, and provenance fields with
  the same source-exact guarantees. Resource-projection handoffs preserve all
  37 availability, degradation, compatibility, margin, projected-overflow,
  projected-shortfall, battery, identity, demand, timing, routing, and
  provenance fields with equivalent source-exact validation. Approval-boundary
  handoffs likewise require all 14 policy, status, authority, operator-action,
  execution-boundary, and provenance fields to remain source exact without
  granting approval or execution authority. Relay-data-path handoffs preserve
  all 32 route, spacecraft, custody, latency, capacity, aggregate, safety-
  assumption, and provenance fields with the same source-exact guarantees.
  Maneuver-execution-uncertainty handoffs preserve all 25 identity, covariance,
  delta-v, threshold, timing, review, and provenance fields without granting
  maneuver execution authority. Execution-success-feedback handoffs preserve
  all 38 command/maneuver identity, realized-result, success-factor, transition,
  mismatch, review, and provenance fields for closed-loop planning evidence.
  Timeline-dependency-impact handoffs preserve all 19 dependency, exclusivity,
  impact, operator-action, identity, and provenance fields. Timeline-publication
  handoffs preserve all 29 publication, invalidation, diff, dependency-impact,
  safety-assumption, identity, and provenance fields without publishing or
  invalidating downstream products. Timeline-lifecycle-state handoffs preserve
  all 34 lifecycle status, count, transition, review, identity,
  safety-assumption, and provenance fields without applying lifecycle state or
  mutating timelines. Operational-feedback handoffs preserve all 77 contact,
  observation, station-throughput, realized-result, identity, transition,
  review, and provenance fields without executing activities or mutating
  station capacity. Activity-lifecycle-state handoffs preserve all 38 currently
  emitted activity identity, transition, status, approval, protection, review,
  safety-assumption, and provenance fields without applying lifecycle state;
  invalid-input reasons remain unclaimed while the live risk emits none.
  Timeline-preservation handoffs likewise preserve all 25 currently emitted
  identity, protection, affected-activity, review, safety-assumption, and
  provenance fields without applying preservation or mutating timelines.
  Activity-precondition handoffs preserve all 26 currently emitted dependency,
  exclusivity, duplicate-edge, overlap, review, safety-assumption, identity,
  and provenance fields without evaluating preconditions or executing commands.
  Timeline-integrity handoffs preserve all 17 currently emitted issue,
  dependency, exclusivity, review, identity, and provenance fields without
  remediating integrity issues or mutating timelines.
  Validation-refresh handoffs preserve all 81 currently emitted model
  acceptance, schema validation, safety-case, refresh-budget, freshness,
  review, identity, and provenance fields without accepting models, applying
  remediations, or executing refreshes.
  An executable recommendation-context coverage guard accounts for all 962
  declared fields across 30 families as 953 source-exact contracts and nine
  pinned, intentionally non-emitted selected-fixture fields.
- Operational readiness and quality artifacts: readiness, import-eligibility,
  execution-boundary, quality-gate, safety-case, model-acceptance,
  schema-validation, validation-fixture, operator-training, and unavailable
  resource summaries classify review-only, analysis-only, importable, and
  blocked handoffs with explicit no-Cadence-execution boundaries. Curated
  validation fixtures now include a combined provider-calendar,
  station-reservation, and contact-allocation contradiction replay for
  CandidateRefresh.
- Candidate refresh replays a broad set of mission-state, realized-feedback,
  source-report, timeline-diff, transition-application, timeline
  lifecycle-state, integrity, publication, readiness, quality,
  contact-allocation, link-capacity, station-calendar, resource, policy, and
  validation evidence as branch-local provenance for V2/V3 repair and strategy
  paths, with replay-derived pressure feeding explainable V3 score terms for
  branch-local contact, resource, station-calendar, timeline, readiness,
  quality-gate, import-readiness, validation, and storage/downlink tradeoffs.
  The current CandidateRefresh source candidate carries an explicit
  accepted-state covariance/source-identity authority summary so unsafe metadata
  is review-visible while remaining non-authoritative for candidate selection,
  branch ordering, recommendation, execution policy, covariance propagation,
  external truth, and Cadence authorization; generated artifact/schema
  convergence remains deferred.
  Explicit unavailable-resource contact IDs from canonical operational
  readiness evidence, the compact quality-gate summary, or row-derived
  canonical contact-allocation resource suppressions now also affect
  CandidateRefresh selection when the ID is scoped to the regenerated
  candidate's spacecraft. Aggregate allocation/readiness pressure remains
  provenance-only, and each decision emits a candidate-rejection review/import
  explanation.
- Example manifests and outputs in `studies/`, `study_results/`, and
  `benchmark_results/`.

The current implementation is strongest as a transparent LEO planning prototype.
Its strongest Cadence-facing surfaces are artifact-only review/import contracts
and branch-local refresh provenance with planner-visible branch scoring for many
replayed review-pressure families. Its weakest areas are high-fidelity dynamics,
frame/time transformations, resource simulation beyond declarative planning-grade
subsystem contracts, event precision guarantees, optimizer breadth, schema
versioning discipline, external validation evidence, external orbit-data
ingestion, provider-write/notification workflows, and deeper use of
resource/contact/readiness evidence during candidate selection and optimization.
