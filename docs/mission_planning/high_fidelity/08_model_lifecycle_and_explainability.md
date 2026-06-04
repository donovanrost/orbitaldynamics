# Model Lifecycle and Explainability

## Cost and Opportunity Model

Operational plans have costs, not only scores.

Feature areas:

- provider contact cost
- station-minute cost
- operator workload cost
- maneuver fuel cost
- battery/resource wear cost
- data latency penalty
- missed-objective penalty
- re-observation cost
- schedule churn cost
- campaign priority value
- customer delivery value
- opportunity cost of using scarce ground or spacecraft resources

Cost should be separate from physical feasibility. A plan may be feasible but
too expensive or may be worth the cost because mission priority is high.

## Requirements Traceability

Every plan decision should be traceable to the requirement, objective, policy,
or model that drove it.

Traceability targets:

- mission requirement IDs
- campaign objective IDs
- customer/tasking request IDs
- observation request IDs
- contact request IDs
- ops constraint IDs
- ICD rule references
- procedure references
- policy rule references
- validation evidence references
- model version references

Traceability should flow into:

- candidate generation
- activity feasibility
- constraint violations
- score terms
- policy decisions
- approval requirements
- operator-review rows
- recommendation explanations

This is essential for explaining why a plan exists and defending changes during
operations review.

## Model Explainability and Sensitivity

High-fidelity models should expose which assumptions drove a decision.

Feature areas:

- limiting model parameter
- sensitivity to battery capacity
- sensitivity to solar generation
- sensitivity to downlink rate
- sensitivity to activity duration
- sensitivity to state uncertainty
- sensitivity to weather/contact success
- sensitivity to maneuver performance
- robustness score
- alternate result under pessimistic assumptions
- alternate result under optimistic assumptions

Sensitivity analysis helps operators understand whether a plan is robust or
fragile.

## Model Sandbox and Experiment Registry

Engineers need to try alternate models without confusing experiments with
approved operations models.

Feature areas:

- experiment IDs
- parameter set versions
- baseline comparison
- result summaries
- promoted models
- rejected models
- experiment provenance
- sandbox readiness marking
- replayable experiment inputs
- comparison reports

Experimental model artifacts should be visibly non-operational unless promoted
through model governance and review.

## Planning Model vs Truth Model

Simulation and validation should distinguish planning approximations from truth
or reference models.

Concepts:

- lightweight planning model
- high-fidelity truth simulator
- external reference model
- residual report
- model adequacy threshold
- reference-required condition
- approximation warning
- calibration handoff

A plan can be valid for strategic analysis with a Tier 1 approximation but
require Tier 3 or Tier 4 evidence before operational import. Artifacts should
make that distinction explicit.

## Data Product Pipeline

For payload missions, planning does not end at observation or downlink.

Feature areas:

- required data products
- product priority
- processing deadlines
- downlink-to-delivery latency
- partial data usability
- product completeness
- reprocessing requirements
- product quality feedback
- failed-processing re-observation triggers
- delivery commitments
- customer/campaign priority

The planner should be able to reason from mission objective to observation to
downlink to product delivery, even if processing itself is outside the toolkit.

