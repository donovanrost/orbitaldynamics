# Near-Term Planning Candidates

These are candidate high-fidelity slices after the current V1/V2/V3 operational
loop is stable. They are grouped by implementation lane so autonomous agents can
choose one coherent vertical slice instead of scanning a flat list.

For the current implementation queue, start with
[../../autonomous_work_guide.md](../../autonomous_work_guide.md).

## Lane 1: Model Contracts And Configuration

First useful slice:
define `spacecraft_model.v1` and `subsystem_model_capability.v1` as small,
schema-validated configuration artifacts.

Candidate artifacts:

- `spacecraft_model.v1`
- `subsystem_model_capability.v1`
- `model_acceptance_report.v1`
- dataset metadata and suitability labels

Why this matters:
ICD-derived subsystem behavior needs explicit model identity, provenance,
fidelity tier, known limits, and applicability before resource projection can
be trusted.

## Lane 2: Tier 1 Resource Projection

First useful slice:
add a deterministic battery or storage projection for selected activities using
simple rates and explicit assumptions.

Candidate artifacts:

- `battery_state.v1`
- `storage_state.v1`
- `resource_projection.v2`
- eclipse-heavy battery fixture
- recorder saturation fixture

Why this matters:
The current resource model is mostly externally supplied margins. Tier 1
projection is the first step toward answering what a plan does to onboard
systems.

## Lane 3: Activity Templates And State Transitions

First useful slice:
add typed activity templates for observe, downlink, command, health check, slew,
payload warm-up/cooldown, and maneuver, then validate one transition path.

Candidate artifacts:

- `activity_template.v1`
- `plan_lifecycle.v1`
- timeline transition validation rows
- `candidate_rejection_report.v1`

Why this matters:
Resources, policy, quality gates, and optimizer behavior all depend on knowing
what an activity requires, consumes, produces, blocks, or changes.

## Lane 4: Review, Readiness, And Safety

First useful slice:
add `quality_gate_report.v1` or `operational_readiness_report.v1` and wire it
to one existing operator-review path.

Candidate artifacts:

- `quality_gate_report.v1`
- `operational_readiness_report.v1`
- `safety_case_report.v1`
- `runbook_reference.v1`
- `automation_guardrail_report.v1`

Why this matters:
Cadence-facing consumers need a compact answer to whether an artifact is
importable, review-only, not-for-execution, or blocked.

## Lane 5: Traceability And Explainability

First useful slice:
add `requirements_traceability_report.v1` for objectives, constraints, policy
rules, model versions, and operator-review rows.

Candidate artifacts:

- `requirements_traceability_report.v1`
- domain ontology document or `domain_ontology.v1`
- planning knowledge graph relationship rows
- model sensitivity summary
- "why rejected" explanation rows

Why this matters:
Operators and engineers need to know why a plan exists, why alternatives were
rejected, and which rule or model drove a decision.

## Lane 6: Provider, Contact, And Relay Operations

First useful slice:
add `provider_negotiation_report.v1` for requested, accepted, rejected, and
counteroffered ground-network contacts.

Candidate artifacts:

- `provider_negotiation_report.v1`
- reservation hold rows
- contact counteroffer rows
- relay/crosslink planning contract
- contact allocation conflict report

Why this matters:
Ground and relay resources are negotiated and shared. The planner should carry
that state without pretending to own provider scheduling systems.

## Lane 7: Validation And Challenge Testing

First useful slice:
add `fault_injection_report.v1` or a challenge fixture for stale-but-plausible
telemetry, conflicting policy, or candidate explosion.

Candidate artifacts:

- `fault_injection_report.v1`
- challenge-test fixture set
- interoperability fixtures
- `contract_migration_report.v1`
- schema deprecation report

Why this matters:
High-fidelity planning is dangerous if it only handles happy paths. Challenge
tests should prove the planner fails closed or requires review.

## Lane 8: Analytics And Long-Running Service Maturity

First useful slice:
add planner service-health or mission-performance summary artifacts for
post-execution analysis.

Candidate artifacts:

- `mission_performance_report.v1`
- service-health report
- planning SLA report
- archive/retention metadata
- plan publication impact report

Why this matters:
Long-running operations need to understand planner runtime cost, service health,
objective fulfillment, contact success, resource trends, and churn.

## Selection Guidance

If no stronger product need is obvious, choose in this order:

1. activity templates and state transitions
2. Tier 1 battery or storage projection
3. quality gates and operational readiness
4. traceability and candidate rejection explanations
5. provider negotiation or contact allocation
6. validation challenge fixtures

Keep each slice vertical: public API, artifact shape, schema validation, tests,
docs, and one checked-in example when useful.
