# Security and Operating Modes

## Security and Command Safety

Command-related planning needs explicit safety boundaries.

Feature areas:

- command authorization boundary
- hazardous command classification
- command inhibit states
- dual-control requirements
- command load expiration
- command dictionary compatibility
- command conflict checks
- cryptographic/signing boundary
- command sequence provenance
- no-earlier-than and no-later-than execution times
- revocation or cancellation rules
- recovery command restrictions

OrbitalDynamics should classify command-planning risk and authority needs. It
should not sign, uplink, or execute commands.

## Adversarial and Interference Environment

Some missions need to plan around interference, degraded navigation, contested
regions, or cyber posture constraints.

Feature areas:

- RF interference risk
- jamming risk
- spoofing risk
- degraded GNSS assumptions
- contested-region rules
- security-driven contact restrictions
- cyber posture constraints
- trusted ground-station requirements
- fallback communication paths
- risk markings for operator review

This should remain an explicit risk and policy model unless mission-specific
evidence supports stronger predictive claims.

## What-If and Trade Study Mode

Operational planning and analysis planning should be visibly different.

Trade-study features:

- sandbox strategy mode
- non-operational assumptions
- parameter sweeps
- sensitivity analysis
- alternate model versions
- alternate policy bundles
- alternate objective weights
- comparison against operational baseline
- "not for execution" artifact marking
- explicit assumption deltas

This lets engineers explore options without producing artifacts that look ready
for operator import.

## Planning SLAs

Operational planning often has deadlines.

Feature areas:

- generate daily plan within a configured time budget
- repair plan within a configured anomaly-response budget
- produce contact proposal before provider lock deadline
- refresh candidates when accepted state exceeds age threshold
- produce command-window review before upload deadline
- return partial recommendation before timeout
- degrade gracefully under deadline pressure
- record missed planning SLA

Planning artifacts should carry enough observability to show whether the
planner met its own operational deadline.

## Simulation and Rehearsal Mode

Mission planners need a way to rehearse operations without producing importable
execution artifacts.

Feature areas:

- simulated telemetry feed
- simulated contact outcomes
- simulated missed contacts
- simulated spacecraft failures
- simulated degraded modes
- simulated maneuver execution errors
- anomaly rehearsal scenarios
- operator training scenarios
- what-if replay
- plan-vs-simulation comparison artifacts
- expected recovery procedure paths

Simulation artifacts should be clearly marked as non-operational unless
explicitly promoted through an ops-review gate.

## Model Composition and Plugin System

Mission-specific models should be pluggable and discoverable.

Feature areas:

- model registry
- capability discovery
- required input contracts
- emitted output contracts
- fidelity tier declaration
- validation-level declaration
- model compatibility checks
- model selection policy
- fallback model policy
- adapter lifecycle
- external service adapter boundary
- deterministic serialization of model decisions

The planner should be able to ask: "which compatible models can evaluate this
activity for this spacecraft/configuration/mission phase?"

## Supply Chain and Vendor Model Dependencies

Some mission models, reference tools, or adapters may come from vendors or
external teams.

Feature areas:

- vendor model version
- license or usage constraints
- validation responsibility
- update cadence
- dependency risk
- tool availability
- support boundary
- fallback if vendor tool is unavailable
- reproducibility impact
- export-control or distribution restrictions

Vendor dependency metadata should be visible when it affects feasibility,
validation, readiness, or reproducibility.

## Data Lineage and Provenance Depth

High-fidelity planning needs deeper provenance than a single source label.

Lineage fields may include:

- telemetry packet IDs
- telemetry product IDs
- accepted OD solution IDs
- state-estimate source IDs
- ground-calendar provider IDs
- station reservation IDs
- command dictionary IDs
- telemetry dictionary IDs
- model version IDs
- ICD/spec/procedure references
- operator input IDs
- derived field lineage
- transformation steps
- generating software version

Artifacts should make it possible to determine who or what supplied each
decision-relevant input and how it was transformed.

## Quality Gates

Before a plan is importable or reviewable, it should pass explicit gates.

Candidate gates:

- schema valid
- required fields present
- input freshness valid
- model compatibility valid
- spacecraft configuration compatible
- mission phase compatible
- authority requirements classified
- no blocked activities
- required margins above threshold
- station reservations checked
- command safety checked
- policy decisions present
- validation level acceptable
- warnings acknowledged
- artifact marked importable, review-only, or not-for-execution

Quality-gate outputs should be machine-readable so Cadence can decide whether a
planner artifact is eligible for import, review, or rejection.

## Resilience and Partial Planning

Operational planning often happens with incomplete or stale inputs.

Feature areas:

- missing telemetry handling
- stale state fallback
- partial ground-calendar fallback
- degraded model fallback
- unavailable external adapter fallback
- partial branch results
- timeout-safe recommendations
- confidence downgrade when inputs are incomplete
- explicit unknown/assumed fields
- no-result and partial-result artifacts
- retry and resume metadata

The planner should prefer honest degraded recommendations over silent failure or
false precision.

## Anomaly Knowledge Base

Recovery planning should benefit from known anomaly patterns without pretending
to automate flight-director judgment.

Feature areas:

- known anomaly types
- anomaly severity
- affected subsystems
- recommended recovery procedures
- historical outcomes
- spacecraft-specific recurrence
- fault-tree references
- similar past case links
- known bad actions
- required escalation authority

The planner can use anomaly knowledge to suggest recovery branches, attach
procedure references, and explain why certain actions are blocked or risky.

## Multi-Tenant and Multi-Mission Boundaries

If OrbitalDynamics supports Cadence broadly, mission boundaries must be explicit
even if the repo itself does not own authorization.

Feature areas:

- mission namespace
- customer/program boundary
- spacecraft fleet boundary
- model package boundary
- policy bundle boundary
- artifact access labels
- data-rights labels
- export-control labels
- cross-mission isolation
- shared ground-network provider references

Artifacts should carry enough metadata for Cadence or another host system to
enforce tenant, mission, and program boundaries.

