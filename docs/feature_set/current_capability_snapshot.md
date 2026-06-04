# Current Capability Snapshot

Implemented or partially implemented modules and artifacts include:

- Core nouns: `CentralBody`, `Epoch`, `Frame`, `StateVector`, `Spacecraft`,
  `Scenario`, `Trajectory`, `GroundStation`, and `Target`.
- Contracts: `Propagator`, `BatchPropagator`, `EventDetector`, and `Constraint`.
- Propagators: `Propagators.TwoBody`, `Propagators.J2`,
  `Propagators.TwoBodyNx`, `Propagators.TwoBodyNxCompiled`,
  `Propagators.TwoBodyExlaCpu`, and `Propagators.J2ExlaCpu`.
- Execution: `ScenarioRunner`, `StudyRunner`, `Study`, `StudyRun`,
  distributed task-supervisor options, task chunking, and batch propagation.
- Events: `EventDetectors.AccessWindows`,
  `EventDetectors.TargetVisibility`, `EventDetectors.Eclipses`, and sampled
  `EventDetectors.GroundTrackCrossings`.
- Search and scoring: `Search.Grid`, `Search.MonteCarlo`,
  `Constraints.ArtifactMetric`, and report ranking metrics.
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
  event detectors, and result artifacts archive the relevant records.
- Environment registry: `OrbitalDynamics.Environment` records simplified fixed
  Sun and constant Earth-rotation capability records in result artifacts and
  exposes provider capability boundaries for fixed Sun, constant Earth rotation,
  and a reference exponential atmosphere-density interface.
- Example manifests and outputs in `studies/`, `study_results/`, and
  `benchmark_results/`.

The current implementation is strongest as a transparent LEO planning prototype.
Its weakest areas are high-fidelity dynamics, frame/time transformations,
resource simulation, event precision guarantees, optimizer breadth, schema
versioning discipline, external validation evidence, external orbit-data
ingestion, and deeper candidate-refresh integration across V2/V3 repair.

