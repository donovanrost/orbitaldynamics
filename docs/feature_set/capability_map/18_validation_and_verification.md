# 18. Validation and Verification

Status: **implemented** (core), with **partial**, **near-term**, **later**, and **out of scope** items below.

## Test suites and analytical checks

Implemented test coverage includes:

- Unit tests for core structs, propagators, events, search, artifacts, study manifests, campaign planner, runtime telemetry, and Mix tasks.
- Analytical / conserved-quantity style checks.
- Backend comparison tests.
- Benchmark artifacts.

## Validation registry and policies

`OrbitalDynamics.Validation` centralizes:

- Current model validation levels.
- Tolerance metadata.
- Evidence.
- Known limits.
- An explicit `validation_tolerance_policy.v1`.

**Backend acceptance.** `backend_acceptance_policy.v1` declares reference-default, experimental-accelerator, and future external-service backend acceptance tiers against that tolerance policy. It provides:

- Executable `known_limits` validation against `Validation.backend_acceptance_policy/0`.
- Exact known-limit JSON Schema export for non-Elixir import gates.

**Policy artifacts.** Both policies are schema-exported and have checked-in lintable artifacts.

## Validation records

Result artifacts archive the relevant validation records.

- Standalone `validation_record.v1` JSON Schema exports type implementation and covered-regime provenance as strings, matching executable validation.
- Registered validation record IDs now enforce exact registry-backed `model` and `known_limits` through executable validation and conditional JSON Schema constraints, while external records remain extensible.

## Validation-reference fixtures (overview)

Curated fixtures that can be verified into `validation_reference_fixture_report.v1` and schema-linted span:

- Internal two-body and J2 propagation.
- Standalone atmospheric-drag acceleration at a curated 400 km Earth/J2000
  state, including provider identity, co-rotation-relative velocity, density,
  and acceleration tolerances.
- Opt-in scalar two-body plus atmospheric-drag propagation over a curated
  400 km/600 s case, including final state, specific-energy decay, provider
  identity, and exact model-limit evidence through the public `Study` path.
- Opt-in scalar point-mass plus J2 plus atmospheric-drag propagation over the
  declared 24-hour Earth/J2000/TDB envelope. The fixture compares 10 s and 5 s
  fixed-step outputs against 0.001 km position and 0.000001 km/s velocity
  internal convergence tolerances. This is educational step-convergence
  evidence, not external truth, acceptance, or flight validation.
- Access-window, eclipse, target-visibility event, and ground-track crossing.
- Campaign V1, repair V2, strategy V3 artifact.
- Standalone operator-review package.
- Operational-readiness report.
- Operational quality-gate import-readiness summary.
- Operational quality-gate unavailable-resource summary.
- Operational quality-gate operator-training summary.
- Operational quality-gate schema-validation summary.
- Contact-allocation report.
- Contact-allocation provider-reservation request summary.
- Contact-contention and contention-resolution reports.
- Contact-filter report.
- Link-capacity report.
- Objective-satisfaction and objective-tradeoff reports.
- Score-term and ranking-comparison reports.
- Resource-projection report.
- Resource-projection flow summary.
- Resource-filter report.
- Execution report.
- Freshness report.
- Manifest field-reference artifact.
- Study-manifest lint report.
- Approval requirement.
- Policy decision.
- Policy bundle.
- Planned activity.
- Realized activity.
- Plan delta.
- Candidate activity.
- Contact intent.
- Refreshed window.
- Source-window lineage.
- Spacecraft state estimate.
- Realized state snapshot.
- Remaining horizon.
- Maneuver execution delta.
- Maneuver recommendation.
- Timeline activity precondition summary.
- Timeline activity state.
- Timeline dependency impact summary.
- Timeline diff summary.
- Timeline integrity report.
- Timeline transition-application summary.
- Station-calendar stale provider reservation hold.
- Station-reservation summaries.
- Checked-in station-calendar overlay reports.
- Provider-counteroffer report timing/cost impact evidence.
- Candidate-refresh provider-counteroffer replay summaries derive status and
  required-action maps from rows when stale top-level aggregates are present.
- Sampled ground-track crossing fixtures.

## External numerical truth: Orekit J2-drag LEO case

Status: **implemented for one exact finite model combination**.

`OrbitalDynamics.Validation.ExternalTruth` is a standalone external-truth
registry, deliberately separate from the curated internal fixture rollup and
its aggregate counts. It contains one registration:

- `external_truth.orekit_13_1_7.earth_j2_drag_rk4_10s_access_eclipse_6h`

The content-bound reference bundle is under
`priv/validation/external_truth/orekit_13_1_7_leo_j2_drag_access_eclipse/`.
It was produced by Apache Orekit 13.1.7 release commit `cc18cc1` with
Hipparchus 4.0.3 in the digest-pinned Linux/arm64 container
`maven@sha256:6fdc855a6ed81d288ca7ca37ac6ff5e9308b612485c0801d70b25a858c83d237`.
The generator uses Orekit's upstream `NumericalPropagator`,
`J2OnlyPerturbation`, `DragForce`, `SimpleExponentialAtmosphere`,
`IsotropicDrag`, `ElevationDetector`, and
`CylindricalShadowEclipseDetector`; it does not duplicate the Elixir force or
event equations.

The case is EME2000 at `2000-01-01T12:00:00 TDB`, with relative seconds from
0 through 21,600. It uses fixed 10 s classical RK4, Earth
mu = 398600.4418 km^3/s^2, radius = 6378.1363 km, J2 = 0.00108262668, and
initial state `[7000, 0, 0]` km / `[0, 4.68721425101214,
5.913792592089408]` km/s. The drag case pins 120 kg total mass, 4 m^2 area,
coefficient 2.2, density 3.89e-12 kg/m^3 at 400 km, 60 km scale height, and
constant co-rotation at 7.292115e-5 rad/s. The station is a spherical-Earth
equatorial site at -60 degrees longitude and 5 degrees minimum elevation.
The eclipse model is a spherical cylindrical shadow with a fixed positive
EME2000 X Sun direction.

The raw result contains all 2,161 Cartesian states on the inclusive 10 s grid
from 0 through 21,600 seconds, two complete access intervals, and four complete
eclipse intervals. The executable verifier compares every state row, runs
`OrbitalDynamics.Propagators.J2Drag` plus bracketed-bisection access and
linear-shadow-margin eclipse detection, verifies exact source/config/tool/data
identity and full horizon count/order/exact-epoch coverage, then applies these
tolerances:

- Position maximum component error: 0.01 m.
- Velocity maximum component error: 0.00001 m/s.
- AOS/LOS absolute boundary error: 0.001 s.
- Eclipse ingress/egress absolute boundary error: 0.05 s.

The checked all-sample comparison's maximum residuals are
3.501772880554199e-7 m, 3.5220182326156646e-10 m/s,
1.6475805750815198e-6 s, and
0.025860116904368624 s respectively. The eclipse threshold is intentionally
larger than the state and access thresholds because the current exact path
linearly interpolates the shadow margin between 10 s samples; the observed
approximately 25.9 ms residual is reported rather than hidden.

The top-level identities are:

- Manifest SHA-256:
  `f4dbcf59007ac1552bb447d13aa9166b7846d393e7fc23d1d60a04fa841e91cd`.
- Source-manifest SHA-256:
  `4b6e875b2cbee2c20e83b268c5b07cedeb8c6ff96ce36a2de7dbf9741a217c93`.
- Raw-result SHA-256:
  `88f0ab20bd24a78bda74cfa8091f9e0546e85eee0e2c4719bde988ad2c66649f`.

Docker reproduction is:

```sh
bundle=priv/validation/external_truth/orekit_13_1_7_leo_j2_drag_access_eclipse
"$bundle/generate.sh" /tmp/orekit-j2-drag-reference-output.json
cmp "$bundle/reference-output.json" /tmp/orekit-j2-drag-reference-output.json
(cd "$bundle" && shasum -a 256 -c SHA256SUMS)
```

The runtime Elixir library has no Java, Maven, Orekit, or Hipparchus
dependency. The bundle does not use Orekit data, EOP, SPICE, or a downloaded
ephemeris: those revisions are explicitly `none`, and the fixed-Sun and
constant-rotation limitations are part of the registered claim. The evidence
is independently source-bound and does not depend on the inherited Domain 4
campaign table, public dataset injection, campaign revision comparisons, or a
campaign-table SHA.

The bundle loader preflights exact byte counts within immutable checked-in
per-file and total limits before reading the manifest, result, source manifest,
generator/config sources, or dependency lock. It rejects symlinks at the
custom bundle root and at every traversed intermediate or final path component,
so a byte-identical sibling reached through a symlinked `src` directory is not
accepted.

This promotes only the exact combined `J2Drag`/access/eclipse case above. It
does not validate J2-only, two-body-drag, other atmosphere providers or
ballistic parameters, other initial states/horizons/stations, accelerated
backends, a time-varying Sun, EOP-aware frames, conical eclipses, operational
acceptance, or flight certification. In particular, it does not close the
broader Domain 3 Level 5 state-error claim across the published J2-drag
envelope; Domain 3 still needs independently sampled cases across that
envelope even though this exact supported path now has external state evidence.

The `timeline_activity_precondition_summary.v1` fixture observes blocked and
review-required precondition counts, precondition type routing, row-derived
status/type maps, timeline identity, and the artifact-only/no-authority
assumptions. Fixture verification rejects stale precondition aggregates before
they can be treated as executable scheduling, operator, or resource authority.
The `timeline_activity_state.v1` fixture observes review-required activity
state rows, planned/realized activity identity, status/match/protection count
maps, row-derived transition categories, review activity IDs, and the
artifact-only/no-schedule-mutation/no-command-execution assumptions. Fixture
verification rejects stale row counts and stale row-derived match-strategy maps
before compact activity-state handoffs can steer review/import adapters.
The `timeline_dependency_impact_summary.v1` fixture observes changed-source,
dependent-activity, impacted-ID, row-scope, required-action, and
operator-action-reason routing plus the no-schedule-mutation/no-authority
assumptions. Fixture verification rejects stale dependency-impact aggregates
and row-derived reason maps before they can steer review/import routing.
The `timeline_diff_summary.v1` fixture observes compact diff/review counts,
changed-field maps, transition-decision maps, required-action routing,
review-timeline ID maps, row-derived transition categories, and
no-schedule-mutation/no-authority assumptions. Fixture verification rejects
stale review counts and row-derived transition maps before compact diff
summaries can steer review/import routing.
The `timeline_integrity_report.v1` fixture observes dependency/exclusivity
review rows, issue-type counts, required-action and operator-reason maps,
review activity/timeline routing, flattened dependency/exclusivity evidence
IDs, and no-schedule-mutation assumptions. Fixture verification rejects stale
issue counts and stale row-derived issue-type maps before integrity summaries
can steer review/import routing.
The `timeline_transition_application_summary.v1` fixture observes selected and
review-gated application counts, status/decision/action maps, review timeline
IDs, row-derived review application maps, withheld-review routing, and
no-schedule-mutation/no-authority assumptions. Fixture verification rejects
stale review counts and row-derived required-action maps before compact
transition summaries can steer review/import routing.
The `timeline_publication_summary.v1` fixture observes publication identity,
publication status, supersession, downstream invalidation routing,
dependency-impact review routing, nested timeline-diff counts, changed-field
maps, review timeline IDs, and no-notification/no-schedule-mutation/no-authority
assumptions. Focused fixture coverage exact-regenerates the checked-in
publication summary through the public facade from deterministic
source/replacement activities before schema validation, so checked-in
publication handoff evidence cannot drift from the public adapter contract.
The `operational_timeline_report.v1` fixture observes row-derived operational
kind, activity status, approval status, Cadence import status, required action,
timeline-integrity issue, and row-ID routing maps. Focused fixture coverage
refreshes and exact-regenerates the checked-in report through the public facade
from deterministic mission-plan activities, pinning current precondition,
invalid-activity, command-window, integrity, import/action, and no-execution
boundary fields before schema validation.

## Contact-intent fixtures

Status: **implemented**.

The validation-reference fixture set includes checked-in `contact_intent.v1`
and `contact_intent_summary.v1` artifact-contract cases. The contact-intent
fixture observes:

- Contact identity, timing, direction, and station routing.
- Cadence import identity fields.
- Approval status and policy-decision classification.
- Artifact-only model limits for no provider reservation, no schedule mutation,
  and no command execution.

The contact-intent summary fixture observes:

- Row-derived contact counts.
- Direction and ground-station routing.
- Capacity-pack required contact and capacity-fraction totals.
- Required-capacity source routing.
- The artifact-only no-provider-reservation/no-schedule-mutation boundary.

Fixture verification rejects stale approval status, summary routing, count, and
execution-boundary observations before contact-intent handoffs can be treated as
import-ready provider or schedule authority.

## Station-calendar and reservation fixture integrity

Station-calendar and station-reservation fixtures now observe:

- Row-derived reservation match-status maps.
- Stale hold counts.
- Reservation status maps.
- Reservation IDs.
- Affected-contact counts.
- Affected duration.
- Match-status ID routing.

This makes stale reservation handoff summaries fail compatibility checks.

## Fixture-report and rollup validation

- Operational-readiness top-level gate status counts export and validate as non-negative integers alongside readiness evidence count maps.
- Exported fixture-report JSON Schema types nested fixture report and check rows, and constrains `fixture_count` as a non-negative integer that executable validation checks against the emitted report list.
- Executable validation also requires top-level fixture-rollup `status` and optional `status_counts` to match nested report statuses, so stale pass/fail summaries cannot mask failed fixture reports.
- Invalid observation inputs are summarized as schema-valid failed fixture rows.
- Standalone validation-reference reports also expose and validate optional check `status_counts`.

## Count-field schema bounds

- Schema-validation report and batch-report scalar counts schema-export as non-negative integers, matching executable row-derived report and batch count checks.
- Campaign and study-manifest lint reports export preflight count fields with the same non-negative integer bounds, and campaign request lint executable validation rejects float-shaped counts.

## Orbit-data adapter validation

Orbit-data adapter validation records declare current evidence, artifact-level tolerances, and known limits for:

- Simple JSON state batches.
- OPM KVN.
- OEM KVN.
- TLE metadata preflight.

This includes metadata-only OPM/OEM covariance preservation without propagation.

## Schema exports and regression tests

- Checked-in artifact and study-manifest JSON Schema exports are tested against their executable exporters.
- Generated campaign IDs and artifact ordering are directly regression-tested across V1 campaign event-result permutations, V2 repair row-order permutations, and V3 strategy branch/event permutations.
- `schema_migration_report.v1` summarizes the executable schema registry with
  caller-declared deprecation/future-contract hints, row-derived status/action
  counts, and explicit report-only/no-rewrite migration limits.

**V3 strategy safety-case rejection.** V3 strategy validation also rejects stale validation-safety-case branch event evidence count maps, required-action drift, and non-review status vocabulary. As a result, blocked/review-required safety evidence cannot carry negative counts, softer review routing, or accepted/missing evidence status through branch-local refresh pressure.

**Golden regression coverage.**

- Checked-in V1 campaign, V2 repair, and V3 strategy artifacts have golden public-surface regression tests for stable IDs, ordering, selections, approval outcomes, and rounded scores.
- Checked-in V1 campaign embedded report surfaces and the Monte Carlo reproducibility report have golden regression coverage.

## Facade surfaces

The following top-level facades expose the same model-evidence and reference-check surfaces for application callers:

- `OrbitalDynamics.validation_registry/0`
- `OrbitalDynamics.validation_record/1`
- `OrbitalDynamics.validation_records_for_result_set/1`
- `OrbitalDynamics.validation_tolerance_policy/0`
- `OrbitalDynamics.backend_acceptance_policy/0`
- `OrbitalDynamics.backend_acceptance_evidence/1`
- Validation-reference fixture facades.

## Backend-acceptance evidence wiring

- Backend-acceptance policy validation rejects implementation tiers that do not map to declared acceptance tiers, and rejects reference backend implementations not mapped to the reference tier.
- Study-run backend-selection metadata carries backend-acceptance evidence, including reference-match and benchmark-artifact requirements.
- `result_artifact.v1` JSON Schema exposes those nested backend-selection evidence fields under `assumptions`.
- Result and execution-report validation rejects artifacts whose top-level backend-selection flags disagree with nested acceptance evidence, or whose acceptance-tier booleans disagree with the evidence row.

## Schema lint wrapper inference

- Schema lint now distinguishes plain result wrappers from nested execution reports, so top-level result artifacts validate as `result_artifact.v1` unless an embedded campaign or candidate-refresh product artifact is selected by the existing wrapper inference.
- `study_benchmark.v1` now covers persisted benchmark histories, so performance-evidence files are linted in `--all` runs instead of skipped.

## Model-limit validation on embedded rows

- `EventTiming` records detector-wide sample-cadence timing policy on event artifacts.
- `result_artifact.v1` trajectory summary rows now validate row-level `model_limits` against `ResultSet.Artifact.trajectory_model_limits/1`, so persisted propagation summaries cannot drift from their declared summary-only/non-flight-certified boundary while still passing schema lint.
- Event rows validate `model_limits` against `ResultSet.Artifact.event_detector_model_limits/1` for access, eclipse, target-visibility, and ground-track products.
- Declared `scenario_rankings` now expose `ResultSet.Report` model, source, validation-level, assumptions, and model-limit metadata, and `result_artifact.v1` validation checks those limits against `ResultSet.Report.model_limits/0`.
- Embedded `constraint_results` now reuse the same typed constraint-row schema and executable validation as `constraint_report.v1` rows, with report-level constraint and row counts bounded as non-negative integers.
- Embedded `maneuver_recommendations` now export the same typed delta-v vector and recommendation model-limit shape as standalone `maneuver_recommendation.v1`.
- Execution-report scenario/event counts and Monte Carlo reproducibility requested/generated counts export and validate as non-negative integers.
- Embedded result-artifact `constraint_report.v1`, `maneuver_review_report.v1`, and `monte_carlo_reproducibility_report.v1` sections now export their nested row/vector/limit schemas and validate stale report-level model limits at the embedded report path.

## Model-acceptance report

`model_acceptance_report.v1` now summarizes registry model evidence for demonstration, analysis, artifact-contract, and operational-import intended uses, with:

- Deterministic accepted/review/blocked rows.
- Row-derived scalar and optional `status_counts` validation.
- Deterministic model-ID maps grouped by acceptance status, validation level, and intended use.
- Unknown-model blocking.
- Facade access via `OrbitalDynamics.validation_model_acceptance_report/2`.
- Checked-in JSON Schema export.

The validation-reference fixture set now includes an operational-import model-acceptance report case covering accepted, review-required, blocked, and unknown model rows, including fixture observations and stale-reference checks for model-ID routing maps. CandidateRefresh model-acceptance replay derives validation-level counts and model-ID routing maps from rows when rows are present, so stale top-level model-acceptance aggregates cannot steer branch-local review/blocking pressure. Compact no-row replay derives row/model counts, accepted/review/blocked counts, unknown-model counts, and validation-level counts from present model-ID routing maps before falling back to duplicated scalar counters.

## Safety-case summary

Status: **implemented**.

`Validation.safety_case_summary/2` and `OrbitalDynamics.validation_safety_case_summary/2` emit lintable `validation_safety_case_summary.v1` summaries: compact artifact-only safety-case rollups over model-acceptance, operational-readiness, quality-gate, single-artifact schema-validation, schema-validation batch, and validation-fixture reports. They preserve:

- Blocked/review-required evidence counts.
- Model-acceptance status and model-ID routing maps.
- Deterministic evidence references grouped by status and input contract.
- Aggregate schema issue counts.
- Nested schema-validation report counts.
- Nested schema-validation batch reports from wrapped handoff inputs.
- Validation fixture report evidence classified from nested fixture-report
  statuses before trusting stale top-level pass/fail rollups.
- Executable row-derived count/map validation.
- The no-certification/no-operator-authority boundary for unsafe-but-plausible evidence bundles.

**Capability metadata** now advertises those safety-case model, readiness, quality-gate, schema-validation, fixture, and evidence-ref rollup semantics for catalog consumers, including review/import handoff evidence discovery.

**Fixture coverage.** The validation-reference fixture set now includes the checked-in `validation_safety_case_summary.v1` example and verifies its:

- Evidence counts.
- Status counts.
- Evidence-reference routing maps.
- Model-acceptance evidence status, validation-level, and intended-use model-ID routing maps.
- Model-limit count.
- No-authority assumptions, including blocked schema-validation evidence preserved through operator-review and Cadence-import containers.

**Blocking and discovery behavior.**

- Safety-case model-acceptance evidence now derives status, status-count, and
  model-ID routing maps from model rows when they are present, even when stale
  top-level model-acceptance fields claim accepted use.
- Safety-case operational-readiness evidence now derives review/blocked status
  and counts from readiness gate rows when they are present, even when stale
  top-level readiness fields claim import eligibility.
- Safety-case quality-gate evidence now derives review/blocked status and
  counts from gate rows when they are present, even when stale top-level gate
  counts claim the report passed.
- Safety-case schema-validation report evidence now derives blocked/review
  status and counts from `errors`/`warnings` issue lists when they are present,
  even when stale top-level schema-validation status/count fields claim pass.
- Safety-case schema-validation batch evidence now treats failed/error nested reports as blocking, even when stale top-level batch status/count fields claim pass.
- Safety-case validation-fixture evidence now treats failed nested fixture
  reports as blocking, even when stale top-level fixture-rollup status/count
  fields claim pass.
- Safety-case inputs also discover schema-validation reports preserved in operator-review packages and Cadence-import manifests, lifting those review/import rows as evidence while keeping certification and operator authority out of the summary.
- CandidateRefresh now accepts direct or result-artifact-wrapped `validation_safety_case_summary.v1` inputs as passive source-report provenance, preserving evidence status/count and evidence-reference routing maps without changing candidate selection. When evidence rows are present, CandidateRefresh derives source-report evidence counts, pressure counts, input-contract maps, and evidence-reference maps from those rows instead of trusting stale top-level safety-case aggregates.
- Compact no-row CandidateRefresh safety-case replay derives evidence row counts
  and accepted/review/blocked evidence counts from present evidence-status and
  evidence-reference maps before falling back to duplicated scalar counters.

## Operational-readiness report fixture

Status: **implemented**.

The validation-reference fixture set includes a curated
`operational_readiness_report.v1` artifact-contract case, with observation
support for:

- Source artifact identity and top-level readiness/import/status
  classification.
- Row-derived gate counts, status/classification maps, and gate-ID routing.
- Import-readiness row counts, import-status maps, and Cadence-import status
  maps.
- Evidence maps for freshness, schema-validation, resource availability, and
  unavailable-resource reason routing.
- Source model, model-limit, adapter-context, and missing trust-boundary counts.

Fixture verification rejects stale row-derived gate maps, stale import-status
counts, stale top-level readiness/import classifications, stale gate/evidence
counts, stale model limits, and stale no-authority assumptions before
operational-readiness reports can steer review or import queues.

## Quality-gate report fixture

Status: **implemented**.

The validation-reference fixture set now includes a curated `quality_gate_report.v1` artifact-contract case, with observation support for:

- Source readiness identity.
- Row-derived gate counts.
- Status/classification count maps.
- Gate ID routing maps.
- Executable stale row-derived gate map checks.
- Model-limit count.
- No-authority execution boundary assumptions.

## Quality-gate import-readiness fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in
`operational_quality_gate_import_readiness_summary.v1` artifact-contract case,
with observation support for:

- Import-readiness row counts and ready-for-import counts.
- Freshness, import-status, and Cadence-import status maps.
- Review-required, stale/unknown freshness, import-preparation, blocked-import,
  analysis-only, and gate-ID routing keys.
- Row-derived freshness and Cadence-import status counts from the compact
  summary maps.
- No-Cadence-write, no-command-execution, and no-operator-authority
  assumptions.

Fixture verification rejects stale ready-for-import counts and stale
row-derived freshness evidence before import-readiness summaries can steer
adapter queues.

## Quality-gate unavailable-resource fixture

Status: **implemented**.

The validation-reference fixture set now includes a generated
`operational_quality_gate_unavailable_resource_summary.v1` artifact-contract
case, with observation support for:

- Resource-availability and unavailable-resource row/pressure counts.
- Unavailable-resource reason maps and sorted reason keys.
- Blocking-dimension counts and blocked-contact routing by dimension,
  spacecraft, and status.
- Quality-gate row/status routing maps and resource-availability gate keys.
- Row-derived resource-availability and review/blocked row counts from compact
  routing maps.
- No-Cadence-write, no-command-execution, and no-operator-authority
  assumptions.

Fixture verification rejects stale unavailable-resource reason maps, stale
blocked-contact routing, and stale row-status counts before unavailable-resource
summaries can steer adapter queues.

## Quality-gate schema-validation fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in
`operational_quality_gate_schema_validation_summary.v1` artifact-contract case,
with observation support for:

- Schema-validation row counts and pass/fail/error/warning/remediation counts.
- Schema-validation status maps and status keys.
- Blocked, review-required, failed-schema-validation, and gate-ID routing keys.
- Row-derived pass/fail counts from compact status maps and blocked/failed row
  counts from compact row-routing lists.
- No-Cadence-write, no-command-execution, and no-operator-authority
  assumptions.

Fixture verification rejects stale schema-fail counts, stale row-derived status
evidence, and stale blocked-row routing before schema-validation summaries can
steer adapter queues.

## Quality-gate operator-training fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in
`operational_quality_gate_operator_training_summary.v1` artifact-contract case,
with observation support for:

- Operator-training row counts and requirement counts.
- Role, training, certification, qualification, and requirement-type routing
  keys.
- Status and classification row-routing maps for review-required/review-only
  quality-gate rows.
- Row-derived requirement counts from compact count maps and row-derived review
  routing counts from compact row-routing lists.
- No-Cadence-write, no-command-execution, and no-operator-authority
  assumptions.

Fixture verification rejects stale requirement counts, stale row-derived
requirement evidence, and stale review-row routing before operator-training
summaries can steer adapter queues.

## Candidate-refresh fixture

Status: **implemented**.

The validation-reference fixture set now includes checked-in and generated
`candidate_refresh.v1` artifact-contract cases, with observation support for
candidate/contact/window counts, warning count, and source-report provenance
family/row counts. Curated candidate-scoped operational-readiness and
quality-gate challenges also pin the exact rejected/remaining candidate
identities, source-specific rejection labels, report paths and identities,
planned-activity scope, blocked status, trust boundary, and invalidation reason.
Stale identity or reason observations fail fixture verification, while a
schema-valid nonmatching source identity remains selection-neutral.

## Policy and record contract fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `backend_acceptance_policy.v1`, `validation_tolerance_policy.v1`, `validation_record.v1`, and `validation_check.v1` artifact-contract cases, with observation support for:

- Backend tier routing.
- Numeric tolerance policy vocabulary and limits.
- Validation record evidence/tolerance rows.
- Known-limit counts.
- Scalar validation-check equality/error evidence.

## Catalog, optimizer, and strategy fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `capability_catalog.v1`, `optimizer_contract.v1`, `strategy_branch.v1`, and `strategy_recommendation.v1` artifact-contract cases, with observation support for:

- Public capability catalog counts.
- Optimizer contract selection/order metadata.
- V3 branch event/risk/score routing.
- Recommendation ranking/operator-review routing.

## Environment capability fixtures

Status: **implemented**.

The validation-reference fixture set now includes runtime `environment_model_capability.v1` and `environment_provider_capability.v1` cases sourced from the public environment capability facades, with observation support for:

- Model/provider identity.
- Category.
- Source.
- Interpolation and coverage policy.
- Network-access boundaries.
- Output/body/parameter counts.
- Known-limit counts.

## Lint and benchmark fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `campaign_request_lint.v1`, `study_benchmark.v1`, and `validation_reference_report.v1` artifact-contract cases, with observation support for:

- Request-lint status/source-plan routing.
- Persisted benchmark result/baseline counts.
- Distributed benchmark rows.
- Chunk/concurrency/Monte Carlo option sweep shape.
- Backend coverage.
- Standalone validation-reference check routing.

## Result-artifact wrapper fixtures

Status: **implemented**.

The validation-reference fixture set now includes the checked-in `result_artifact.v1` LEO constellation campaign, LEO access, manifest-driven LEO access, ground-track crossing, raise-apogee maneuver-search, candidate-refresh, orbit-data candidate-refresh, LEO dispersion Monte Carlo, and mission-plan checkout wrappers, with observation support for:

- Top-level product counts.
- Embedded campaign and candidate-refresh counts.
- Event/product counts.
- Nested report presence.
- Execution status.
- Run metadata.
- Payload metrics section/body-size checks.

## Planning-state and candidate fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `accepted_planning_state.v1`, `proposed_contact.v1`, and `invalidated_candidate.v1` artifact-contract cases, with observation support for:

- Simple JSON and CCSDS OPM/OEM accepted-state provenance/quality/vector dimensions.
- Proposed contact timing/source-window/import boundaries.
- Invalidated-candidate replacement and semantic-change routing.

## Policy-bundle fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in mission-ops, ground-network, operator-review queue, command/contact, maneuver, resource-projection, timeline-protection, conservative-ops, contact-command-review, degraded-payload-guard, default, and organization adapter `policy_bundle.v1` artifact-contract cases, with observation support for:

- Classification and authority maps.
- Station availability/reduced-capacity rule counts.
- Contention and contact-allocation review triggers.
- Missing trust-boundary rules.
- Operator-review queue authority routing.
- Command/contact/Cadence-import authority routing.
- Domain authority rule IDs.
- Fallback and organization-adapter provenance boundaries.
- Artifact-only no-authority/no-command assumptions.

## Branch-comparison and candidate-diff fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `branch_comparison_report.v1` and `candidate_diff_report.v1` artifact-contract cases, with observation support for:

- Branch ranking and selected-branch counts.
- Row-derived approval-status and resource-risk routing maps.
- No-execution branch-score assumptions.
- Candidate diff counts.
- Semantic change reason maps.
- Replacement routing maps.
- Model-limit boundaries.

## Candidate-diff-row fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `candidate_diff_row.v1` artifact-contract case, with observation support for:

- Row identity.
- Diff reason.
- Changed-field order/counts.
- Semantic-change reason/detail counts.
- Matched prior candidate identity.
- Target metadata.
- Target-priority objective routing.

## Candidate-rejection fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `candidate_rejection_report.v1` artifact-contract case, with observation support for:

- Rejected/not-rejected/reviewable counts.
- Rejection-reason routing.
- Required operator-review action counts.
- Candidate-refresh replay summaries derive rejection-reason and required-action
  maps from rows when stale top-level aggregates are present.
- Invalid candidate input routing.
- Artifact-only no-selection/no-schedule-mutation model limits.

## Refresh-budget and Monte Carlo reproducibility fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `refresh_budget_report.v1` and `monte_carlo_reproducibility_report.v1` artifact-contract cases, with observation support for:

- Deterministic keep/drop budget counts.
- Kept/dropped candidate IDs.
- No-search budget assumptions.
- Seeded scenario generation counts.
- RNG/seed metadata.
- Dispersion sigma vectors.
- Covariance/model-limit boundaries.
- Known-limit counts.

## Timeline-diff and transition-application fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `timeline_diff_report.v1` and `timeline_transition_application_report.v1` artifact-contract cases, with observation support for:

- Timeline source/replacement counts.
- Diff status and changed-field maps.
- Operator-action row routing.
- Review-required counts.
- Row-derived timeline-diff status/transition/action/changed-field maps.
- Row-derived diff/action row routing.
- Row-derived transition application status/decision/action maps.
- Candidate-refresh transition-application replay summaries derive application
  counts, duplicate counts, and status/decision/action/scope maps from
  application rows when stale top-level aggregates are present.
- Selected/review/preserved/replacement/withheld replay counts are also derived
  from application rows under the same stale-aggregate boundary.
- Status/approval transition maps.
- Application ID routing.
- Selected/preserved/withheld counts.
- Review-gate assumptions.
- No-schedule-mutation boundaries.

## Operational-timeline report fixture (row-derived maps)

Status: **implemented**.

The checked-in `operational_timeline_report.v1` validation-reference fixture now observes row-derived operational-kind, activity-status, approval-status, Cadence-import-status, required-action, and timeline-integrity issue maps, plus row-ID routing maps. Candidate-refresh replay summaries derive those routing maps and integrity counts from rows when source operational-timeline reports carry stale top-level aggregate fields.

## Timeline-feedback fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `timeline_feedback_report.v1` artifact-contract case, with observation support for:

- Planned/realized reconciliation counts.
- Feedback kind and match strategy maps.
- Execution-uncertainty counts.
- Nested operator-review and Cadence import handoff counts.
- Operational-feedback key counts.
- Row-derived status/kind/match/import/transition maps.
- Candidate-refresh replay summaries derive status/kind/match maps from rows
  when source timeline-feedback reports carry stale top-level aggregates.
- Activity routing maps.
- No-schedule-mutation boundaries.

## Station-calendar provider fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `station_calendar_provider.v1` artifact-contract case, with observation support for:

- Provider identity.
- Entry order/counts.
- Station routing.
- Maintenance/reserved availability counts.
- Zero-capacity and reservation metadata.
- Provenance.
- Trust boundary.
- No-provider-reservation assumptions.

## Cadence-import manifest fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `cadence_import_manifest.v1` artifact-contract case, with observation support for:

- Import readiness/blocking counts.
- Reported and row-derived Cadence import status maps.
- Source review queue/type maps.
- Import action/side maps.
- Import-status row routing.
- Executable stale row-derived routing checks.
- No-Cadence-write boundaries.
- Authorization boundaries.
- Model-limit evidence.

## Command-window and constraint fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `command_window_report.v1` and `constraint_report.v1` artifact-contract cases, with observation support for:

- Command-window row-derived operator-action routing.
- Cadence-import and approval status maps.
- Window-type maps.
- Required-action row IDs.
- Artifact-only execution boundary evidence.
- Constraint row-derived status and metric maps.
- Threshold operator counts.
- Status-routed constraint IDs.
- Model-limit boundaries.

## Schema-validation report fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `schema_validation_report.v1` and `schema_validation_batch_report.v1` artifact-contract cases, with observation support for:

- Validation mode.
- Pass/fail status.
- Issue/remediation counts.
- Batch file/artifact/skipped counts.
- Nested report pass/fail counts.
- Schema-validation model-limit boundaries.

## Schema-migration report fixtures

Status: **implemented**.

The validation-reference fixture set now includes `schema_migration_report.v1`
artifact-contract cases for both deprecated-contract and future-contract
registry hints, with observation support for:

- Deprecation and future-contract counts.
- Status-count and migration-action count maps.
- Row-derived status and migration-action count maps.
- Deprecated and replacement contract routing.
- Report-only execution and migration-authority boundaries.

## Resource-summary fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `resource_summary.v1` artifact-contract case, with observation support for:

- Planning-grade resource identity.
- Derived battery/storage/power margins.
- Downlink capacity metadata.
- Availability/degraded flags.
- Activity suppression/incompatibility lists.
- Source quality.
- Trust boundary.
- Provenance assumptions.

## Resource-projection fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `resource_projection_report.v1` artifact-contract case, with observation support for:

- Projection counts.
- Flow-row counts.
- Pressure-row counts.
- Storage/downlink pressure totals.
- Source-quality/trust maps.
- Warnings.
- Model-limit boundaries.

## Resource-projection flow-summary fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in
`resource_projection_flow_summary.v1` artifact-contract case, with observation
support for:

- Compact flow row counts.
- Row-derived storage production, downlink relief, downlink shortfall, and
  unused capacity totals.
- Row-derived battery consumption, generation, net delta, and peak overuse.
- Projected remaining storage/downlink capacity totals and minima.
- Ignored activity and pressure routing counts.
- The artifact-only no-schedule-mutation execution boundary.

## Resource-projection battery handoff challenge fixture

Status: **implemented**.

A resource-projection battery handoff challenge fixture now spans `resource_projection_report.v1`, `operator_review_package.v1`, and `cadence_import_manifest.v1`, checking flow-derived consumed/generated/net battery energy plus peak overuse on the source artifact, review row, import row, and nested source-review evidence.

## Operator-review package fixture (row-derived maps)

Status: **implemented**.

The checked-in `operator_review_package.v1` validation-reference fixture now observes row-derived review counts, review-type maps, required-operator-action maps, queue maps, and review row IDs by type, with stale row-derived review-routing checks.

## Resource-filter fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `resource_filter_report.v1` artifact-contract case, with observation support for:

- Kept/suppressed candidate counts.
- Invalid and duplicate candidate counts.
- Source-quality/trust maps.
- Suppressed-reason and resource-blocking routing maps.
- Model-limit boundaries.

## Objective-satisfaction and objective-tradeoff fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `objective_satisfaction_report.v1` and `objective_tradeoff_report.v1` artifact-contract cases, with observation support for:

- Objective status maps.
- Selected/satisfied/required totals.
- Planned-not-executed assumptions.
- Ranking/tradeoff counts.
- Score-term key shape.
- Score totals.
- Selected-ranking assumptions.
- Model-limit boundaries.

## Score-term and ranking-comparison fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `score_term_report.v1` and `ranking_comparison_report.v1` artifact-contract cases, with observation support for:

- Score-term row counts.
- Selected-row counts.
- Score-term key counts.
- Score totals.
- Pairwise ranking status maps.
- Winner-change evidence.
- No-solver assumptions.
- Model-limit boundaries.

The checked-in V3 strategy golden artifact also pins split strategy score-term
keys and per-branch rows across contact, resource, station, readiness, quality,
validation, execution-feedback, approval-boundary, and timeline pressure
penalties. Focused planner tests cover non-zero split penalty behavior for
those pressure families, including branch-local replay pressure such as
resource-filter suppressions.

## Maneuver-review and Pareto-frontier fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `maneuver_review_report.v1` and `pareto_frontier_report.v1` artifact-contract cases, with observation support for:

- Maneuver review counts.
- Execution-uncertainty status maps.
- Operator-action routing.
- No-command review boundaries.
- Pareto frontier/dominated counts.
- Objective key-count maps.
- Frontier routing maps.
- No-search assumptions.
- Model-limit boundaries.

## Operational-timeline report fixture (counts)

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `operational_timeline_report.v1` artifact-contract case, with observation support for:

- Operational activity/contact/command counts.
- Timeline-integrity issue and review counts.
- Dependency/exclusivity counts.
- Status maps.
- Operator-action row routing.
- Planned-not-commanded assumptions.
- Model-limit boundaries.

The exported `operational_timeline_report.v1` schema also exposes the
top-level duplicate dependency/exclusivity activity and timeline ID rollups
emitted by the checked-in fixture, so schema-visibility checks cover both row
and report-level integrity evidence.

## Contact-allocation fixtures

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `contact_allocation_report.v1` artifact-contract case, with observation support for:

- Contact allocation counts.
- Review-row counts.
- Reported and row-derived allocation/effective status and allocation-reason maps.
- Row-derived scalar allocation/contact counters.
- Station reservation/trust routing maps.
- Row-derived reservation ID/owner/status evidence.
- Executable stale top-level reservation-list checks.
- Model-limit boundaries.

A second reduced-capacity pack fixture verifies capacity-pack group counts, capacity fraction totals, selected/packed/deferred contact routing, row-derived capacity-pack status/reason maps, and the reported schema-visible capacity-pack status/contact-ID maps.

## Contact-filter fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `contact_filter_report.v1` artifact-contract case, with observation support for:

- Kept/suppressed candidate counts.
- Row-derived suppressed-candidate counters.
- Duplicate suppressed-candidate counts.
- Reservation match maps.
- Suppressed-reason routing maps.
- Station availability maps.
- Model-limit boundaries.

## Contact-contention and resolution fixtures

Status: **implemented**.

The validation-reference fixture set now includes checked-in `contact_contention_report.v1` and `contact_contention_resolution_report.v1` artifact-contract cases, with observation support for:

- Conflict/recommendation counts.
- Row-derived scalar conflict-group/conflicted-contact/recommendation counters.
- Review-required counts.
- Operator-action maps.
- Resource-scope routing maps.
- Selected/deferred contact counts.
- Resolution boundary evidence.
- Model-limit boundaries.

It also includes a generated cross-station same-spacecraft contention challenge
fixture that verifies spacecraft-scoped contention groups and row-derived
resource-scope routing without provider reservation, schedule mutation, or
candidate suppression.

## Link-capacity fixture

Status: **implemented**.

The validation-reference fixture set now includes a checked-in `link_capacity_report.v1` artifact-contract case, with observation support for:

- Fixed-rate contact and selection counts.
- Row-derived scalar contact/selected/evidence counters.
- Throughput totals.
- Station-selection routing maps.
- Model-limit boundaries.

It also includes checked-in `link_capacity_summary.v1` and
`relay_data_path_summary.v1` cases. These summary fixtures verify:

- Effective, selected, and actual-throughput contact counts.
- Downlink requirement and actual shortfall status.
- Capacity-adjusted throughput totals.
- Ground-station routing maps.
- Relay data-path feasibility and relay-window routing.
- Artifact-only no-provider-reservation/no-schedule-mutation/no-link-budget
  assumptions.

Fixture verification rejects stale summary counts, stale station routing, stale
relay-path routing, and stale execution-boundary observations before compact
link-capacity handoffs can steer candidate refresh or Cadence import review.

## Global artifact fixture coverage guard

Status: **implemented**.

The validation test surface compares every public `Schema.contracts/0` key with
the curated `artifact.*` model IDs in `Validation.reference_fixtures/0`. It
fails with sorted exact identities when a registered artifact contract lacks a
fixture or when a curated fixture points at a removed or renamed contract.

The current registry has 121 contracts, of which 120 have curated artifact
fixtures. The sole explicit bootstrap exclusion is the self-describing
`validation_reference_fixture_report.v1`: making its rollup a required member
of itself would create recursive fixture generation. The guard separately
asserts that this exclusion remains singular, registered, and without a fixture.

## Resource/contact fixture coverage guard

Status: **implemented**.

The validation test surface derives resource/contact artifact families from the
public schema registry and compares them with curated `artifact.*` validation
reference model IDs. The scope includes contact, resource, station,
link-capacity, relay-data-path, and provider-counteroffer contract prefixes plus
the explicit `proposed_contact.v1` and
`operational_quality_gate_unavailable_resource_summary.v1` contracts.

The current registry contains 33 contracts in that scope and all 33 have at
least one curated reference fixture. A future matching schema contract fails the
coverage guard with its exact missing contract name until a fixture is added;
the guard checks fixture presence and does not replace each fixture's field,
tolerance, stale-observation, or executable-schema assertions.

## Readiness/quality fixture coverage guard

Status: **implemented**.

The validation test surface also derives readiness/quality artifact families
from the public schema registry and compares them with curated `artifact.*`
validation reference model IDs. The scope includes model acceptance,
operational execution-boundary and import-eligibility summaries, operational
quality-gate and readiness artifacts, quality-gate reports, schema-validation
artifacts, validation safety cases, and any specialized contract ending in
`_import_readiness_summary.v1`.

The current registry contains 16 contracts in that scope and all 16 have at
least one curated reference fixture. A future matching schema contract fails the
coverage guard with its exact missing contract name until a fixture is added;
other adjacent policy and resource contracts remain outside this guard and keep
their own focused coverage boundaries.

## Activity/timeline fixture coverage guard

Status: **implemented**.

The validation test surface derives typed activity/timeline artifact families
from the public schema registry and compares them with curated `artifact.*`
validation reference model IDs. The scope includes every `timeline_*` contract
plus explicit activity-template, approval-requirement, candidate-activity,
candidate-rejection, command-window, invalidated-candidate, operational-
timeline, plan-delta, planned/realized-activity, and source-window-lineage
contracts.

The current registry contains 27 contracts in that scope and all 27 have at
least one curated reference fixture. A future matching schema contract fails the
coverage guard with its exact missing contract name until a fixture is added;
campaign-plan and maneuver-report contracts remain outside this focused family.

## Partial

Status: **partial**.

- Validation levels are centralized for current models. One exact Orekit
  J2-drag/state/access/eclipse reference-tool comparison is executable and
  content-bound; broader reference-tool coverage remains absent.
- Internal fixtures now cover one two-body case, one J2 case, four event-detector cases, and checked-in product/result artifact contract cases. These include:
  - The candidate-refresh artifact surface.
  - The operator-review import surface.
  - Generated operational-readiness and quality-gate report surfaces.
  - A declared station-calendar provider-hold surface that preserves stale-but-plausible reservation evidence without provider calls.
- Executable operator-review and Cadence-import validation now rejects negative lifted station-calendar and reservation-match count maps.
- Executable contact-contention validation now derives conflicted, duplicate, invalid-contact, group, and recommendation counts from emitted rows.
- Product-level V1 campaign plus candidate-refresh tests now cover generated same-scenario cross-station contact contention through embedded contact allocation, and validation now includes an internal cross-station contact-contention fixture baseline. External campaign reference baselines remain missing.
- Most event timing tolerances remain artifact metadata rather than a refined
  root-finding accuracy guarantee. The one exact external case above separately
  verifies AOS/LOS and eclipse boundaries against Orekit.

## Roadmap

- **Near-term** — add deeper product-level scenario tests for V1/V2/V3, and keep extending golden artifact tests as new public report surfaces are promoted.
- **Later** — broader SPICE/Orekit/GMAT/Tudat comparison suites beyond the one
  exact Orekit case, continuous benchmark trend tracking, and backend
  acceptance criteria.
- **Out of scope** — flight certification.
