# Recommended Roadmap

This roadmap is intentionally short. It is the prioritization layer for
autonomous implementation loops; detailed feature inventory lives in the
capability-map files.

For slice selection, also read
[../autonomous_work_guide.md](../autonomous_work_guide.md).

## Current Product Direction

OrbitalDynamics already has useful V1 campaign planning, V2 repair, V3 strategy
comparison, candidate refresh, schema exports, validation artifacts, typed
timeline lifecycle/integrity/publication surfaces, station-calendar overlays,
contact-allocation and link-capacity artifacts, resource summaries, readiness
and quality-gate summaries, policy decisions, and operator-review/import
artifacts.

The next work should make those artifact surfaces more planner-visible. Prefer
small vertical slices that convert existing review evidence into candidate
selection, branch scoring, compatibility checks, and challenge fixtures while
preserving OrbitalDynamics' no Cadence database/API/execution boundary.

## Next Implementation Queue

### 1. Typed Operational Activity And Timeline Semantics

Primary outcome:
Activities, timeline rows, deltas, locks, approvals, execution status,
dependencies, and exclusivity should move from map conventions toward reusable
APIs and validated artifacts.

Already implemented or heavily covered:

- status and approval transition helpers
- dependency and exclusivity validation and integrity summaries
- lock/approved/executed preservation helpers
- candidate rejection reports, timeline diffs, transition-application reports
  and summaries, publication summaries, and their review/import handoffs
- V2/V3 branch scoring and recommendation explanations for replayed
  timeline-integrity and timeline-publication pressure
- curated lifecycle/protection compatibility and challenge coverage, including
  timeline lifecycle-state fixtures, preservation fixtures, CandidateRefresh
  lifecycle replay, and stale derived lifecycle/protection schema guards

Good next slices:

- harden one remaining downstream review/import path only when live code shows
  the artifact is not already routed

Key docs:

- [capability_map/08_mission_activities_and_timelines.md](capability_map/08_mission_activities_and_timelines.md)
- [../mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md](../mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md)

### 2. Resource And Communications Allocation Semantics

Primary outcome:
Resource summaries, station calendars, contact filters, contention reports, and
provider reservations should become explicit enough for operator review and
quality gates.

Already implemented or heavily covered:

- reserved/unavailable/reduced-capacity evidence and precedence reports
- same-station contention, allocation, and reservation pressure summaries
- storage/downlink roll-forward and zero-effect audit rows for terminal or
  approval-rejected selected activities
- V2 repair scoring and score-term reports apply selected link-capacity
  shortfall as an explicit normalized risk-weight penalty
- provider counteroffer, reservation-hold, reservation-expiration, plan-impact,
  and review/import handoff artifacts
- contact-intent and capacity-pack direction routing in allocation and
  CandidateRefresh replay
- candidate-refresh challenge fixture coverage for contradictory
  provider-calendar, station-reservation, and contact-allocation evidence

Good next slices:

- use selected resource/contact pressure directly in candidate ranking or branch
  score explanations
- add one compatibility fixture for a resource/contact artifact family that does
  not already have a curated reference check

Key docs:

- [capability_map/07_ground_network_and_communications_planning.md](capability_map/07_ground_network_and_communications_planning.md)
- [capability_map/06_spacecraft_and_payload_modeling.md](capability_map/06_spacecraft_and_payload_modeling.md)
- [../mission_planning/high_fidelity/06_operational_concerns.md](../mission_planning/high_fidelity/06_operational_concerns.md)

### 3. Quality Gates And Operational Readiness

Primary outcome:
Cadence-facing outputs should clearly say whether they are importable,
review-only, analysis-only, or blocked, and why.

Already implemented or heavily covered:

- `quality_gate_report.v1`
- `operational_readiness_report.v1`
- not-for-execution, analysis-only, review-only, import-eligibility, and
  execution-boundary summaries
- quality-gate and readiness rows in operator-review and Cadence-import packages
- V3 branch score terms and recommendation evidence for replayed
  operational-readiness, quality-gate, and import-readiness pressure

Good next slices:

- make one existing readiness or quality-gate block affect candidate selection
  before review/import handoff
- add stale-but-plausible readiness/input challenge fixtures
- harden schema-validation or compatibility checks for one readiness/quality
  family that lacks exact reference evidence

Key docs:

- [capability_map/17_reproducibility_artifacts_and_audit.md](capability_map/17_reproducibility_artifacts_and_audit.md)
- [capability_map/20_cadence_boundary_and_integration_artifacts.md](capability_map/20_cadence_boundary_and_integration_artifacts.md)
- [../mission_planning/high_fidelity/12_operational_readiness.md](../mission_planning/high_fidelity/12_operational_readiness.md)

### 4. Branch-Local Candidate Refresh Depth

Primary outcome:
More mission-state, realized-feedback, source-report, and branch-assumption
changes should produce executable `candidate_refresh.v1` requests and preserve
their explanations through repair, strategy, and operator review.

Good next slices:

- add one new source-report replay path only after verifying it is missing in
  live code
- preserve one more candidate-diff reason through V2/V3 when the current
  operator-review/import path drops it
- convert one replayed resource/contact/readiness pressure signal that is still
  missing from score terms into planner-visible branch scoring
- consolidate repeated branch-refresh helper logic after a focused duplication
  map identifies a small safe extraction

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
