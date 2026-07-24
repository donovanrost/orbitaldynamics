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
  contradictory explanations cannot pass as valid V2 repair handoffs; current
  contact-intent rows are additionally reconciled to exact embedded source
  identities and risk weight while all-prechange rankings remain compatible,
  and station-pressure rows are reconciled to exact allocation/calendar
  candidate identities, ordered source paths, and risk weight; link-capacity
  penalties are pinned to one risk-weight unit exactly when positive projected
  shortfall evidence is present; resource-projection penalties are recomputed
  from each row's embedded risk-indicator count and the enclosing risk weight;
  schedule churn is replayed from source/candidate start times and both schedule
  penalties are pinned to policy weights; semantic-diff matches are replayed
  from exact source ID/window and replacement-candidate links; candidate IDs and
  values are pinned to exactly one embedded source candidate row; and the
  selected row is reconciled to the enclosing repaired activity and optional
  source/replacement timeline handoff identities
- runtime and exported V2 contracts require numeric aggregate score terms;
  runtime validation pins their sum and optional score-term report repair model,
  embedded policy/source assumption, sorted rows, source-plan row identities,
  values, rank/selection, and timeline score to the enclosing repair artifact,
  and reconciles any contact-intent penalty to unique pressured downlink IDs in
  the repaired activities; a present aggregate activity score is recomputed
  from those repaired activities with producer-equivalent numeric/default-zero
  handling, while present churn and movement terms are reconciled to repair
  actions, activity churn seconds, and their embedded policy weights; present
  link-capacity and resource-projection penalties are reconciled to the final
  selected-shortfall status, shared source-report risk count, and `risk_weight`;
  CandidateRefresh diff, freshness, and budget penalties are reconciled through
  shared producer/runtime counts against their embedded source reports;
  operational-readiness and quality-gate penalties are reconciled through shared
  source-row expansion and reviewability classifiers; contact/resource-filter
  and candidate-rejection penalties are reconciled to shared suppression or
  rejection counts and embedded report fallbacks; contact-allocation pressure is
  reconciled through shared normalized unusable-row and status-summary counts
- an optional V2 repair objective-tradeoff report is pinned to its enclosing
  single repaired timeline: repair model, score-term keys, policy, source plan,
  score, zero delta, score terms, and repaired activity identity/count
- optional V2 constraint reports are declared as direct nested contracts and
  receive standalone row/count/status/model-limit validation plus exact repair
  model, constraint-model assumption, and constraint-source identity checks
- optional V2 contact-allocation reports are declared as direct nested
  contracts and receive the complete standalone allocation/nested-contention
  validation plus exact `campaign_repair.activities` source identity
- optional V2 timeline-transition reports receive complete nested validation;
  runtime reconciliation pins repair source, repaired-activity count, and
  selected/review-required summaries to enclosing repair metadata
- optional V2 command-window reports are declared as direct nested contracts
  and receive standalone row/count/approval/dependency/identity validation plus
  exact repaired-activity source and source-assumption checks
- V2 candidate-refresh source freshness contributes one explicit normalized
  risk-weight penalty for a stale or unknown report, aligned with its
  review/import gate and V3 refresh-freshness pressure semantics
- V2 candidate-refresh diff evidence contributes one aggregate normalized
  risk-weight penalty when the shared V3 replay classifier finds diff pressure,
  without multiplying the score effect by report row count
- V2 candidate-refresh contact-intent evidence contributes one normalized
  risk-weight penalty per unique pressured downlink contact selected in the
  repaired activities, using the shared V3 exact-identity classifier while
  keeping unrelated, duplicate, non-downlink, and review-only rows neutral;
  replacement ranking applies the same calibrated unit to each exact pressured
  alternative and exposes sorted unique pressure statuses without multiplying
  duplicate or multi-status evidence
- provider counteroffer, reservation-hold, reservation-expiration, plan-impact,
  and review/import handoff artifacts
- contact-intent and capacity-pack direction routing in allocation and
  CandidateRefresh replay
- candidate-refresh challenge fixture coverage for contradictory
  provider-calendar, station-reservation, and contact-allocation evidence
- V3 recommendation review/import handoffs recover normalized resource-filter
  availability booleans, including `false`, and require the 15-field
  availability identity, timing, status, value, and provenance context to stay
  source exact across direct and review-derived Cadence rows
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
- ranked V1 timelines require exported numeric activity-score and activity-
  count-penalty aggregates; runtime reconciles timeline score to those terms plus
  the producer's optional objective/pressure adjustments without double-counting
  component or count explanations
- V1 activity-score and activity-count-penalty aggregates are reconciled to
  nested activity scores, selected count, and the declared scoring-policy penalty
- exported V1 ranked score terms require nonnegative integer observation/contact
  counts reconciled to nested activities with the producer's exact classifiers
- exported V1 ranked target/contact/eclipse component terms are required and
  reconciled to nested activity-term sums without entering the aggregate twice
- runtime V1 validation also preserves the producer's descending timeline score
  order and deterministic ascending scenario tie-break; this adjacent-row rule
  remains executable because JSON Schema does not express the comparison
- ranked V1 scenario rows are unique and own all nested activity scenario IDs,
  preserving the producer's scenario-group boundary while allowing empty rows;
  these cross-row/cross-field comparisons remain executable contracts
- optional V1 objective-tradeoff rows are reconciled with their enclosing
  ranked timelines, including selected-score deltas, term maps, selected counts,
  and activity identities
- V1 score-term and objective-tradeoff reports are declared as optional direct
  nested contracts in the exported campaign-plan schema
- V1 target commitments are exported as typed inline rows and reconciled with
  candidate, selected-activity, and objective-satisfaction evidence
- V1 generation time is typed as a date-time and exact plan identity is derived
  from the enclosing study ID and generation timestamp
- required V1 assumptions pin the current builder/selector/filter/Cadence
  boundary identifiers and type the constraint/scoring-policy maps
- required V1 provenance keys preserve nullable direct-plan evidence while
  typing non-null run/manifest/revision/propagator values and manifest SHA-256
- V1 runtime/export contracts reject non-string, blank, and duplicate warning
  evidence without freezing the warning vocabulary
- required V1 planning-horizon objects type optional positive duration/cadence,
  require duration for cadence, and bound core schedule rows when duration is
  declared
- selected, candidate, and ranked V1 activities require numeric non-negative
  duration evidence, with runtime reconciliation against each start/end interval
- selected, candidate, and ranked V1 activities require numeric score/term
  evidence, with each activity score reconciled to its numeric term sum
- ranked V1 activity snapshots exactly match their candidate rows, and top-level
  selected snapshots exactly match the first ranked timeline
- stable V1 candidate activity IDs are unique across the candidate collection,
  and selected IDs are unique within each ranked timeline; runtime owns the
  property-key rule that structural JSON Schema cannot express
- V1 candidate rows preserve ascending scenario/start/ID order and ranked
  activity rows preserve ascending start/ID order through executable adjacent-
  row checks
- selected, candidate, and ranked V1 activities require matching stable outer
  and nested source-window IDs for producer-window lineage
- current V1 activity kinds conditionally reconcile nested source-window family
  to target visibility or ground-station access while future kinds remain open
- V1 proposed contacts are reconciled to candidate-derived normalized snapshots
  for count, order, and producer fields while compatible enrichment remains open
- V1 contact intents are reconciled to policy-independent candidate-derived base
  snapshots while optional validated approval-policy annotations remain open
- selected, candidate, and ranked V1 activity types are nonblank strings while
  retaining an extensible vocabulary
- selected, candidate, and ranked V1 activities require typed Cadence-import
  identity with external IDs reconciled to activity IDs
- current V1 activity kinds conditionally reconcile their Cadence import type to
  observation, command, or contact dispatch while future kinds remain open
- downlink, command, tracking, and health-check V1 activities conditionally
  require stable ground-station identity and exact activity-type direction
- those current contact-family activities also conditionally pin their nested
  Cadence adapter schema to `proposed_contact.v1`
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
- embedded V1 contact-filter and station-calendar reports are declared as
  optional direct nested contracts while retaining their existing executable
  campaign validation

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
