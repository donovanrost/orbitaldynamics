# Verification and Validation

## External Simulator Adapter Boundary

The toolkit should not reimplement every specialized simulator.

Potential adapters:

- Orekit
- GMAT
- STK
- Tudat
- SPICE
- Basilisk
- vendor power simulators
- vendor thermal simulators
- mission-specific link tools
- internal flight-dynamics services

Adapters should provide:

- declared input contract
- declared output contract
- model/version metadata
- validation level
- known limits
- deterministic artifact normalization
- comparison reports

## Verification Harness and Model Test Kit

Mission-specific models need a standard test kit before they are trusted in
planning products.

Feature areas:

- subsystem model unit tests
- scenario conformance tests
- golden input/output cases
- stress cases
- edge-case generators
- regression thresholds
- model acceptance reports
- model compatibility checks
- deterministic replay
- fixture coverage reports

The harness should make it cheap to ask whether a new or changed spacecraft
model is safe to use for a given readiness level.

## Fault Injection

Resilience features should be tested by injecting operational failures.

Injection cases:

- missed contact
- failed contact
- bad telemetry
- stale OD
- station outage
- reduced station capacity
- payload failure
- low battery
- recorder saturation
- command failure
- maneuver underperformance
- model adapter timeout
- partial artifact generation

Fault-injection outputs should show degraded recommendation behavior,
confidence downgrades, blocked actions, and recovery branches.

## Interoperability Test Suite

Schema export is necessary but not sufficient. Other systems must be able to
consume the artifacts.

Feature areas:

- Cadence import compatibility
- provider calendar compatibility
- simulator adapter compatibility
- command dictionary compatibility
- telemetry dictionary compatibility
- JSON Schema examples
- backward compatibility fixtures
- import/export round trips
- version skew tests
- deprecation warnings

Interoperability tests should protect the artifact contracts that connect
OrbitalDynamics to real operations systems.

## Red-Team and Challenge Testing

A mature planner should be stress-tested against adversarial or pathological
inputs.

Challenge cases:

- invalid but schema-valid inputs
- conflicting authority rules
- stale but plausible telemetry
- pathological candidate explosion
- misleading high-score unsafe plans
- contradictory model outputs
- missing but decision-critical provenance
- cyclic dependencies
- impossible merge requests
- agent-generated artifact sanity checks

Challenge tests should prove the planner fails closed, downgrades confidence,
or requires review instead of producing unsafe importable artifacts.

## Validation and Trust

High-fidelity planning requires trust evidence.

Feature areas:

- ICD provenance
- model review records
- reference fixture library
- telemetry comparison reports
- simulator comparison reports
- tolerance policies
- validation levels
- model-limit declarations
- golden artifact fixtures
- compatibility tests
- regression scenarios

Current implementation note: validation-reference fixtures now include a
provider-counteroffer report case generated from declared station-calendar
counteroffer evidence. It verifies reviewability, timing-shift, cost-delta, and
deadline observations while preserving the no-provider-write/no-schedule-mutation
boundary.

Current implementation note: `Validation.model_acceptance_report/2` and
`OrbitalDynamics.validation_model_acceptance_report/2` now emit
`model_acceptance_report.v1`. The report classifies registered model evidence
for a declared intended use, exposes accepted/review/blocked rows, validates
row-derived scalar counts plus optional `status_counts`, exposes deterministic
model-ID maps by acceptance status, validation level, and intended use, blocks
unknown models, and keeps the claim explicitly evidence-based rather than
certification. The validation-reference fixture set also includes an
operational-import model-acceptance case, so compatibility tests cover
accepted, review-required, blocked, and unknown-model rows.

Current implementation note: `Validation.safety_case_summary/2` and
`OrbitalDynamics.validation_safety_case_summary/2` now emit
`validation_safety_case_summary.v1`, a lintable artifact-only rollup for
model-acceptance, operational-readiness, quality-gate, schema-validation, and
validation-fixture evidence. The summary preserves blocked and review-required
counts plus deterministic evidence references by status and input contract for
handoff routing, but explicitly does not grant certification, operator
authority, or Cadence import authority.
Wrapped handoff inputs can carry both `schema_validation_batch_report` and
`source_schema_validation_batch_report` evidence without caller-side unpacking.

Current implementation note: `Validation.schema_migration_report/1` and
`OrbitalDynamics.validation_schema_migration_report/1` now emit
`schema_migration_report.v1`, a lintable artifact-only compatibility inventory
over the executable schema registry. It preserves caller-declared deprecation
hints, caller-declared future-contract hints, row-derived status/action
rollups, and explicit no-rewrite/no-migration authority limits for
interoperability gates.

Suggested validation labels:

- `declared_assumption`
- `artifact_contract`
- `analysis`
- `mission_calibrated`
- `reference_compared`
- `ops_review_ready`

The repo should never imply more trust than the evidence supports.
