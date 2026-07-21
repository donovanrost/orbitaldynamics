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
- an executable registry-derived coverage guard confirms all 27 current typed
  activity, command-window, rejection, lineage, lifecycle, transition, and
  timeline contracts have curated artifact reference fixtures and automatically
  scopes future matching contracts

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
  shortfall and selected station-calendar pressure as explicit normalized
  risk-weight penalties without penalizing unselected affected contacts
- V2 replacement ranking projects link capacity across already repaired and
  remaining planned activities, applying the same calibrated selected-shortfall
  unit within semantic candidate-diff priority tiers and retaining the exact
  positive shortfall on pressured alternatives
- V2 replacement ranking internalizes the same calibrated repair-time
  station-calendar pressure within semantic candidate-diff priority tiers,
  aligning selection with the final repair objective without hard suppression
- V2 replacement ranking and final scoring also apply that calibrated unit to
  exact viable reduced-capacity rows from candidate-refresh contact-allocation
  evidence, while keeping nonmatching/unselected rows neutral and deduplicating
  matching live station-calendar pressure; ranking rows expose stable ordered
  allocation/calendar source paths without adding empty provenance to nominal
  candidates
- V2's generic selected resource-projection penalty covers every emitted
  storage, downlink, battery, thermal-margin, availability, and activity-
  compatibility projection risk
- V2 replacement ranking projects alternatives against canonical candidate-
  refresh resource summaries and internalizes the same calibrated per-risk
  units within semantic candidate-diff priority tiers while retaining the exact
  risk indicators on pressured alternatives
- runtime and exported `campaign_repair.v2` schemas validate replacement-
  ranking envelopes, rows, optional pressure evidence, row/rank uniqueness, and
  selected-candidate consistency without closing unrelated repair metadata
- runtime ranking validation also pins score arithmetic, semantic-diff priority,
  nonzero-penalty evidence presence, and priority/score ordering so internally
  contradictory explanations cannot pass as valid V2 repair handoffs
- runtime and exported V2 contracts require numeric aggregate score terms;
  runtime validation pins their sum and optional score-term report source,
  values, rank/selection, and timeline score to the enclosing repair artifact
- V2 candidate-refresh source freshness contributes one explicit normalized
  risk-weight penalty for a stale or unknown report, aligned with its
  review/import gate and V3 refresh-freshness pressure semantics
- V2 candidate-refresh diff evidence contributes one aggregate normalized
  risk-weight penalty when the shared V3 replay classifier finds diff pressure,
  without multiplying the score effect by report row count
- provider counteroffer, reservation-hold, reservation-expiration, plan-impact,
  and review/import handoff artifacts
- contact-intent and capacity-pack direction routing in allocation and
  CandidateRefresh replay
- candidate-refresh challenge fixture coverage for contradictory
  provider-calendar, station-reservation, and contact-allocation evidence
- an executable registry-derived coverage guard confirms all 33 current
  resource/contact/station/link/provider contracts have curated artifact
  reference fixtures and automatically scopes future matching contracts

Good next slices:

- assess remaining candidate-specific contact/resource pressure for safe use in
  ranking or branch score explanations

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
- CandidateRefresh exact-identity filtering for schema-valid blocked
  `planned_activity.v1` quality-gate and operational-readiness reports, with
  deterministic source-specific candidate-rejection review/import evidence and
  compact, malformed, nonmatching, wrong-type, and nonblocked inputs kept
  provenance-only
- an executable registry-derived coverage guard confirms all 16 current
  readiness, quality, import-readiness, model-acceptance, schema-validation, and
  safety-case contracts have curated artifact reference fixtures and
  automatically scopes future matching contracts

Good next slices:

- add stale-but-plausible readiness/input challenge fixtures
- harden schema-validation or compatibility checks for one readiness/quality
  family that lacks exact reference evidence
- assess another readiness or quality-gate selection effect only when live
  evidence carries an equally explicit candidate or resource identity

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

Already implemented or heavily covered:

- a global registry-derived guard requires curated fixtures for all 120
  non-bootstrap artifact contracts, rejects fixture model IDs without a live
  contract, and keeps the self-describing fixture-report contract as the sole
  explicit bootstrap exclusion
- runtime V1 validation checks numeric ranked-timeline score explanations and
  pins optional score-term report rows to their enclosing rank, scenario, term,
  value, timeline score, and selection; exported score-term values are numeric
- optional V1 objective-tradeoff rows are reconciled with their enclosing
  ranked timelines, including selected-score deltas, term maps, selected counts,
  and activity identities
- V1 score-term and objective-tradeoff reports are declared as optional direct
  nested contracts in the exported campaign-plan schema
- optional V1 optimizer metadata is reconciled with enclosing candidate,
  selected-activity, ranked-timeline, constraint, scoring-policy, and objective
  evidence; the required ranking explanation is nested and typed
- embedded V1 constraint reports are declared as direct nested contracts and
  receive standalone row/count/status/model-limit validation plus exact campaign
  model/source context checks
- embedded V1 contact-allocation reports are declared directly and receive the
  standalone allocation/nested-report validation plus exact campaign candidate
  source checking
- embedded V1 Cadence import manifests are declared directly and receive the
  standalone manifest/row/count/no-write validation plus exact containing-plan
  source identity checks
- embedded V1 command-window reports are declared directly and receive the
  standalone row/count/model-limit validation plus exact selected-activity
  source and no-command-execution boundary checks

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
