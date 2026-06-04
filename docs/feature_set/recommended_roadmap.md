# Recommended Roadmap

This roadmap is intentionally short. It is the prioritization layer for
autonomous implementation loops; detailed feature inventory lives in the
capability-map files.

For slice selection, also read
[../autonomous_work_guide.md](../autonomous_work_guide.md).

## Current Product Direction

OrbitalDynamics already has useful V1 campaign planning, V2 repair, V3 strategy
comparison, candidate refresh, schema exports, validation artifacts,
station-calendar overlays, policy decisions, resource summaries, and
operator-review artifacts.

The next work should convert thin artifact surfaces into reusable operational
behavior. Prefer small vertical slices that make future planner work safer:
typed timeline semantics, resource/contact allocation semantics, quality gates,
branch-local refresh depth, and validation/compatibility fixtures.

## Next Implementation Queue

### 1. Typed Operational Activity And Timeline Semantics

Primary outcome:
Activities, timeline rows, deltas, locks, approvals, execution status,
dependencies, and exclusivity should move from map conventions toward reusable
APIs and validated artifacts.

Good first slices:

- status and approval transition helpers
- dependency and exclusivity validation
- lock/executed preservation helpers
- candidate rejection or timeline transition reports (`candidate_rejection_report.v1`
  now covers artifact-only "why rejected" rows; continue hardening downstream
  review/import use if needed)

Key docs:

- [capability_map/08_mission_activities_and_timelines.md](capability_map/08_mission_activities_and_timelines.md)
- [../mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md](../mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md)

### 2. Resource And Communications Allocation Semantics

Primary outcome:
Resource summaries, station calendars, contact filters, contention reports, and
provider reservations should become explicit enough for operator review and
quality gates.

Good first slices:

- reserved/unavailable/reduced-capacity precedence
- same-station allocation or reservation conflict report
- storage/downlink roll-forward for selected activities
- provider counteroffer or reservation-hold artifact (station-calendar
  counteroffer evidence, standalone `provider_counteroffer_report.v1`, and
  reservation-hold expiration are artifact-only report/review/import surfaces
  today, including row-derived counteroffer negotiation-state, cost, and
  lock-deadline summaries, compact counteroffer review summaries with
  active/expired/missing deadline status, and artifact-only plan-impact
  summaries for timing-shift/cost-delta rows; provider writes and full negotiation
  workflows remain future work)

Key docs:

- [capability_map/07_ground_network_and_communications_planning.md](capability_map/07_ground_network_and_communications_planning.md)
- [capability_map/06_spacecraft_and_payload_modeling.md](capability_map/06_spacecraft_and_payload_modeling.md)
- [../mission_planning/high_fidelity/06_operational_concerns.md](../mission_planning/high_fidelity/06_operational_concerns.md)

### 3. Quality Gates And Operational Readiness

Primary outcome:
Cadence-facing outputs should clearly say whether they are importable,
review-only, analysis-only, or blocked, and why.

Good first slices:

- `quality_gate_report.v1`
- `operational_readiness_report.v1`
- not-for-execution markings for trade studies
- quality-gate rows in operator-review packages

Key docs:

- [capability_map/17_reproducibility_artifacts_and_audit.md](capability_map/17_reproducibility_artifacts_and_audit.md)
- [capability_map/20_cadence_boundary_and_integration_artifacts.md](capability_map/20_cadence_boundary_and_integration_artifacts.md)
- [../mission_planning/high_fidelity/12_operational_readiness.md](../mission_planning/high_fidelity/12_operational_readiness.md)

### 4. Branch-Local Candidate Refresh Depth

Primary outcome:
More mission-state, realized-feedback, source-report, and branch-assumption
changes should produce executable `candidate_refresh.v1` requests and preserve
their explanations through repair, strategy, and operator review.

Good first slices:

- add one new source-report replay path
- preserve one more candidate-diff reason through V2/V3
- add refresh provenance for one new resource/contact feedback source
- consolidate repeated branch-refresh helper logic

Key docs:

- [capability_map/11_planning_state_refresh_and_opportunity_generation.md](capability_map/11_planning_state_refresh_and_opportunity_generation.md)
- [capability_map/13_v2_rolling_repair.md](capability_map/13_v2_rolling_repair.md)
- [capability_map/14_v3_strategy_orchestration.md](capability_map/14_v3_strategy_orchestration.md)

### 5. Validation, Compatibility, And Challenge Fixtures

Primary outcome:
New public artifact behavior should be protected by schema exports, golden
fixtures, interoperability checks, and challenge tests for unsafe but plausible
inputs.

Good first slices:

- model acceptance report
- safety-case report summary
- interoperability fixture for one artifact family
- stale-but-plausible input challenge test
- contract migration/deprecation report

Key docs:

- [capability_map/18_validation_and_verification.md](capability_map/18_validation_and_verification.md)
- [../mission_planning/high_fidelity/11_verification_and_validation.md](../mission_planning/high_fidelity/11_verification_and_validation.md)
- [../artifacts/compatibility_checks.md](../artifacts/compatibility_checks.md)

## Long-Term Direction

After the queue above is solid:

- add high-fidelity subsystem model contracts
- add Tier 1 battery/storage/resource projection
- add calibrated mission-specific model support
- add external simulator/reference-tool adapters behind contracts
- add stronger optimizer/search methods only after constraints are concrete
- expand beyond LEO only after the LEO operational loop is useful

## What Not To Do Yet

- do not implement Cadence database, UI, approval workflow, or command execution
- do not claim higher validation maturity than current evidence supports
- do not add opaque optimizer behavior before constraints and resources are
  explainable
- do not read or edit every documentation file for a narrow implementation
  slice
