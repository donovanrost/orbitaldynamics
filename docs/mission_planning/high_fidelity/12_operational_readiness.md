# Operational Readiness

## Certification and Review Package

OrbitalDynamics should not claim flight certification, but it should be able to
produce review packages for engineering and operations boards.

Package contents:

- model assumptions
- model versions
- validation evidence
- known limits
- residual reports
- waivers
- open risks
- quality-gate results
- readiness level
- reviewer signoff metadata
- approval authority references
- import readiness evidence

This package helps humans decide whether a model, plan, or planning mode is
ready for the intended operational use.

## Safety Case

A safety case is a structured argument that a plan is safe enough for its
intended use.

Safety-case fields:

- claim
- scope
- evidence
- assumptions
- constraints checked
- mitigations
- residual risks
- blocked hazards
- readiness level
- authority approval
- open questions

The first implementation can be an artifact summary over existing quality gates,
policy decisions, validation records, and risk reports.

## Operational Readiness Levels

Fidelity tiers describe model depth. Operational readiness levels describe how
the output may be used.

Suggested readiness levels:

- analysis only
- engineering review
- ops rehearsal
- operator review
- import eligible
- execution-adjacent
- flight-certified external process

Current implementation:

- `operational_readiness_report.v1` summarizes existing operator-review and
  Cadence-import evidence into importable, review-only, analysis-only, or blocked
  classifications.
- The operational-mode gate preserves structured analysis-mode evidence for
  `analysis_only`, `simulation`, `rehearsal`, `trade_study`, `training`, and
  `not_for_execution` markers from options, artifact metadata, or direct
  artifact assumptions; artifact not-for-execution booleans/strings are
  normalized for case, whitespace, and separator differences before import
  eligibility is classified. The gate keeps the marker source distinct for
  root artifact fields, metadata, and assumptions so review/import queues can
  route the exact provenance.
  `OperationalReadiness.capabilities/0` publishes that vocabulary and common
  analysis-mode aliases such as `sim`, `tradeoff`, `no execution`, and
  `not for ops` for adapters.
- `OperationalReadiness.capabilities/0` also publishes the public
  `OrbitalDynamics.operational_readiness_report/2` facade, the review/import
  handoff artifact contracts, and the readiness review/import action names.
  Generated readiness reports, runtime validation, and JSON Schema export pin
  the capability `known_limits` list as the report-level `model_limits`
  contract. Runtime validation also derives `report_id` from the declared source
  artifact type and ID, preventing stale readiness lineage from being relabeled
  as evidence for a current artifact.
- `OperationalReadiness.import_eligibility/2` and
  `OrbitalDynamics.operational_import_eligibility/2` publish the validated
  `operational_import_eligibility_summary.v1` artifact-only eligibility summary
  over the same readiness report, including row-derived gate counts,
  non-passed gate rows, and explicit
  no-Cadence-write/no-operator-authority assumptions. Generated summaries,
  runtime validation, and JSON Schema export pin the artifact-only model-limit
  list for that import-eligibility handoff.
- `OperationalReadiness.gate_summary/2` and
  `OrbitalDynamics.operational_readiness_gate_summary/2` publish the validated
  `operational_readiness_gate_summary.v1` routing summary over the same gates
  with row-derived gate counts and deterministic gate-ID maps grouped by status
  and classification, while keeping the
  no-Cadence-write/no-operator-authority boundary explicit. Generated summaries,
  runtime validation, and JSON Schema export pin the artifact-only model-limit
  list for that routing boundary.
- `OperationalReadiness.execution_boundary_summary/2` and
  `OrbitalDynamics.operational_execution_boundary_summary/2` publish the
  validated `operational_execution_boundary_summary.v1` artifact-only
  execution-boundary view over the same readiness report. It distinguishes
  import eligibility from execution authority, preserves
  `analysis_mode` evidence for simulation, trade-study, rehearsal, training,
  and `not_for_execution` inputs, and always reports no command execution, no
  Cadence write, and no operator authority granted by the summary. Generated
  summaries, runtime validation, and JSON Schema export pin the artifact-only
  model-limit list for that execution-boundary handoff.
- `OperationalReadiness.quality_gate_report/2` and
  `OrbitalDynamics.operational_quality_gate_report/2` expose those gates as a
  standalone `quality_gate_report.v1` artifact with deterministic gate rows,
  row-derived readiness classification/status, status/classification count
  maps, gate ID maps grouped by status and classification, executable
  row-derived checks for stale count and ID routing maps, source readiness
  report identity, and explicit handoff-only execution-boundary booleans that
  deny command execution, Cadence writes, and operator authority, plus a
  row-derived `execution_boundary` value for adapter handoff, review-required,
  analysis-only, or blocked routing. Analysis-only quality-gate handoff rows
  stay `not_required` and `not_applicable` so simulation, rehearsal,
  trade-study, and not-for-execution artifacts do not look import-ready.
  Generated quality-gate reports, runtime validation, and JSON Schema export pin
  the artifact-only report `model_limits`. Runtime validation derives both the
  quality-gate report ID and its source-readiness report ID from the declared
  source artifact identity, and derives each row ID from that identity plus its
  gate ID and rank, so stale lineage cannot pass as a current gate or queue row.
  Existing `quality_gate_report.v1` artifacts are accepted as idempotent handoff
  inputs when downstream queues already hold the compact gate artifact.
- `OperationalReadiness.quality_gate_summary/2` and
  `OrbitalDynamics.operational_quality_gate_summary/2` publish the validated
  `operational_quality_gate_summary.v1` row-derived triage summary over that
  standalone quality-gate artifact, preserving status/classification counts,
  status-grouped and classification-grouped gate IDs and quality-gate row IDs,
  non-passed gate IDs, non-passed quality-gate row IDs, and non-passed rows
  without Cadence writes, command execution, or operator authority. Runtime
  validation and JSON Schema export pin the summary's artifact-only model-limit
  list so handoff queues cannot accept stale quality-gate triage declarations.
- `OperationalReadiness.quality_gate_unavailable_resource_summary/2` and
  `OrbitalDynamics.operational_quality_gate_unavailable_resource_summary/2`
  publish the validated
  `operational_quality_gate_unavailable_resource_summary.v1` row-derived
  summary over `resource_availability` quality-gate rows, including
  unavailable-resource reason counts, station-availability reason counts,
  blocked contact IDs by blocking dimension, spacecraft, and gate status,
  quality-gate row IDs by status, and artifact-only no-authority assumptions
  for review/import routing. Runtime validation and JSON Schema export pin the
  summary's artifact-only model-limit list so adapter queues cannot accept stale
  unavailable-resource trust-boundary declarations.
- `OperationalReadiness.quality_gate_schema_validation_summary/2` and
  `OrbitalDynamics.operational_quality_gate_schema_validation_summary/2`
  publish the validated
  `operational_quality_gate_schema_validation_summary.v1` routing shape for
  `cadence_import` quality-gate rows carrying schema-validation evidence,
  including pass/fail and issue counts, blocked row IDs, failed
  schema-validation row IDs, status-grouped gate IDs, and no-authority
  assumptions. Runtime validation and JSON Schema export pin the summary's
  artifact-only model-limit list so adapter queues cannot accept stale
  schema-validation trust-boundary declarations.
- `OperationalReadiness.quality_gate_import_readiness_summary/2` and
  `OrbitalDynamics.operational_quality_gate_import_readiness_summary/2` publish
  the validated
  `operational_quality_gate_import_readiness_summary.v1` freshness/import-status
  half of the same `cadence_import` quality-gate row context, including
  stale/unknown freshness routing, freshness status IDs, import status IDs,
  import-preparation row IDs, blocked import row IDs, analysis-only row IDs,
  Cadence-import status IDs, and no-authority assumptions. Runtime validation
  and JSON Schema export pin the summary's artifact-only model-limit list so
  adapter queues cannot accept stale import-readiness trust-boundary
  declarations.
- `OperationalReadiness.quality_gate_operator_training_summary/2` and
  `OrbitalDynamics.operational_quality_gate_operator_training_summary/2`
  publish the validated
  `operational_quality_gate_operator_training_summary.v1` row-derived routing
  over `operator_training` quality-gate rows, including role, training,
  certification, qualification, status/classification row IDs, and
  no-authority assumptions. Runtime validation and JSON Schema export pin the
  summary's artifact-only model-limit list so adapter queues cannot accept stale
  operator-training trust-boundary declarations.
- The readiness gate set includes optional mission-policy evidence. When
  `policy_decision.v1` classifications or preserved source-policy decisions are
  present, `operator_review_required` policy evidence keeps otherwise ready
  imports review-only, and `blocked_by_policy` evidence blocks import
  eligibility.
- The readiness gate set also includes optional resource/station availability
  evidence. Resource-projection or resource-suppression handoffs that preserve
  unavailable spacecraft, payload, antenna, degraded-payload, or
  resource-summary activity-type suppression reasons, and contact-allocation
  handoffs that preserve ground-station reserved, unavailable, zero-capacity, or
  reduced-capacity block reasons, now emit an explicit `resource_availability`
  gate with row-derived reason counts before import eligibility is reported.
  Standalone quality-gate rows carry those reason IDs and counts directly for
  adapter routing.
- Readiness reports can flow into operator-review packages and Cadence import
  manifests while preserving the classification, status, gate counts, and
  evidence used for the decision. `resource_availability` gate rows also lift
  resource pressure counts, reason counts, reason IDs, and unavailable-resource
  reason IDs directly into those review/import rows for adapter routing.
- Non-passed readiness gates also flow into deterministic
  `operational_readiness_review` rows, so blocked, review-required, and
  analysis-only gates are independently queueable instead of only appearing as
  nested summary context.
- Direct source artifacts with boolean-gated review rows, including candidate
  rejection and standalone provider counteroffer reports, preserve those booleans
  while deriving review/import evidence so they classify as review-only instead
  of analysis-only when operator review is required.
- Readiness evidence preserves current, stale, and unknown freshness counts when
  a freshness report or derived freshness review/import row is present.
- Readiness evidence preserves pass/fail schema-validation status plus error,
  warning, and remediation counts when schema-validation reports or derived
  validation review/import rows are present.
- Ready import evidence fails closed when source freshness is stale/unknown or
  source schema-validation evidence fails: stale/unknown freshness requires
  review, and failed schema validation blocks import eligibility. The
  `cadence_import` readiness gate now carries the flattened import-status,
  freshness, and schema-validation count maps directly, and those fields flow
  into quality-gate rows, operator-review rows, and Cadence-import rows for gate
  routing without reopening the full readiness evidence object.
- The adapter-boundary gate keeps adapter-shaped import rows review-only when
  they declare provider/adapter context without a trust boundary, blocks rows
  that explicitly declare unknown or untrusted trust-boundary evidence, and
  carries the adapter-boundary status counts into quality-gate, operator-review,
  and Cadence-import handoff rows.
- Readiness evidence preserves source model, model-limit, mission-policy
  classification, review-type, import-action, source-review-type, and
  adapter-boundary status count maps from direct input artifacts and derived
  review/import rows, so resource/contact pressure and policy authority can be
  traced to the exact review/import routing family; executable validation
  rejects negative readiness evidence count-map values to match the exported
  JSON Schema contract.
- Readiness reports also preserve declared operator role, training,
  certification, and qualification requirements from source artifacts and
  handoff rows. Those requirements add an explicit `operator_training` gate,
  keep the artifact review-only until a role-qualified human review happens,
  and flow through quality-gate, operator-review, and Cadence-import rows.
- The report is artifact-only: it does not approve actions, write to Cadence,
  reserve provider resources, or execute commands.

Readiness should depend on schema validity, input freshness, model compatibility,
validation evidence, authority classification, quality gates, and mission policy.

## Operator Training and Certification Evidence

Operators may need training or qualification before using planner outputs in
specific workflows.

Current implementation starts with artifact-level routing evidence: declared
operator role, training, certification, and qualification requirements are
machine-readable readiness gates and import handoff fields.

Feature areas:

- training scenario catalog
- operator qualification requirements
- planner feature certification
- simulated approval drills
- competency evidence references
- role-specific training requirements
- recurrent training dates
- readiness-level restrictions by role

The planner should expose when an output requires a trained or certified role to
review or approve it.

## Scenario and Fixture Library

Canonical fixtures should represent real planning stress cases.

Candidate scenarios:

- eclipse-heavy orbit battery case
- recorder saturation case
- high-priority imaging campaign
- missed contact recovery
- low-storage downlink relief
- degraded spacecraft repair
- failed payload branch
- station contention and reservation conflict
- reduced-capacity ground station
- maneuver plus post-burn OD update
- safe-mode recovery
- combined outage plus urgent target plus low storage
- command-only health recovery pass
- payload warm-up/cooldown conflict

Each fixture should include expected artifacts and schema validation.

## Operator Explainability

Every high-fidelity recommendation should explain:

- why the activity is feasible
- which model was used
- which subsystem is limiting
- which constraint blocked or penalized it
- what margin is closest to violation
- what assumption matters most
- what changed from the prior plan
- what requires approval
- what should be reviewed before import

This is a product requirement, not just documentation polish.

## Planner Explainability UX Contract

OrbitalDynamics should not own the Cadence UI, but it should emit artifacts that
make operator-facing UI straightforward and safe.

Explanation artifacts should include:

- concise recommendation summary
- branch comparison summary
- limiting constraint list
- risk ranking
- margin table
- before/after timeline diff
- "why not" explanations for rejected alternatives
- operator checklist rows
- approval requirement summary
- stale-input summary
- model and assumption summary
- import readiness status

The same underlying explanation data should support CLI reports, JSON artifacts,
and Cadence UI import.

## Knowledge Capture

Planning artifacts should preserve why humans accepted, rejected, or changed a
plan.

Feature areas:

- waiver records
- accepted risks
- operator notes
- engineering rationale
- model override reasons
- policy exception reasons
- post-ops lessons learned
- review meeting references
- anomaly review references
- superseded decision rationale

Knowledge capture should be structured enough to support audit, future anomaly
response, and model improvement.

## Archive and Retention Policy

Operational planning artifacts need retention and archive rules.

Feature areas:

- retain operational artifacts
- retain analysis artifacts
- purge temporary simulations
- preserve audit trail
- preserve review packages
- export archive bundle
- archive integrity check
- content-addressed artifact option
- retention class labels
- legal or contractual hold labels

Cadence or another host may own long-term storage, but OrbitalDynamics artifacts
should carry enough metadata to support retention decisions.

## Deprecation and Migration Policy

Artifact contracts, model contracts, and readiness policies will evolve.

Feature areas:

- deprecated contract versions
- deprecated model versions
- migration reports
- breaking-change policy
- compatibility windows
- automatic migration eligibility
- manual migration requirements
- migration validation report
- superseded field mapping
- consumer warning period

Deprecation policy should make old artifacts understandable and new artifacts
safe to consume.
