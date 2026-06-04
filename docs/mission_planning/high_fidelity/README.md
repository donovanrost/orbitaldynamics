# High-Fidelity Mission Planning Feature Set

This is the high-fidelity mission-planning feature set: the long, forward-
looking outline of what a mature mission-planning substrate should cover.
It is broader and more aspirational than the LEO-focused [campaign planner
spec](../leo_campaign_planner/README.md) and the cross-cutting
[feature_set](../../feature_set/README.md) capability map.

For autonomous implementation loops, do not read every file in this directory.
Start with [../../autonomous_work_guide.md](../../autonomous_work_guide.md) and
[16_near_term_planning_candidates.md](16_near_term_planning_candidates.md),
then open only the thematic file for the selected slice.

The original monolith grouped 75+ thematic H2 sections in one file. They
have been clustered here into thematic files; every section's H2 heading
is preserved verbatim inside the file it now lives in.

## Files

- [00_purpose_thesis_and_fidelity_tiers.md](00_purpose_thesis_and_fidelity_tiers.md)
  — Purpose, Product Thesis, Fidelity Tiers 0–4.
- [01_digital_twin_and_subsystem_models.md](01_digital_twin_and_subsystem_models.md)
  — Spacecraft Digital Twin Boundary, Configuration Management,
  Model Lifecycle, Core Subsystem Models (Power, Data Recorder, Comms,
  Payload, ADCS, Propulsion, Thermal, FDIR).
- [02_state_activities_and_resources.md](02_state_activities_and_resources.md)
  — Mode and State Machines, Activity Templates, Resource Propagation,
  Environment and Dynamics Fidelity.
- [03_planning_optimization_and_autonomy.md](03_planning_optimization_and_autonomy.md)
  — Planning and Optimization, Onboard Autonomy Boundary,
  Automation Guardrails.
- [04_plan_structure_and_lifecycle.md](04_plan_structure_and_lifecycle.md)
  — Planning Product Types, Hierarchical Planning, Plan Lifecycle,
  Plan Merge and Conflict Resolution, Constraint Library, Objective Library,
  Explainable Rejection Catalog, Plan Diff and Audit Trail,
  Plan Publication and Subscription.
- [05_mission_scope_and_coordination.md](05_mission_scope_and_coordination.md)
  — Mission Phase Modeling, Constellation-Level Coordination,
  Program and Portfolio Planning, Deployment, Phasing, and Fleet Growth,
  Operations Procedure Modeling, Collaborative Planning.
- [06_operational_concerns.md](06_operational_concerns.md)
  — Operational Risk Model, Latency and Timeliness,
  State Estimation and OD Handoff, Human Workload and Approval Burden,
  Ground Segment Reality, External Provider Negotiation,
  Inter-Satellite Links and Relay Operations, Space Traffic and Safety,
  Fleet Health Strategy.
- [07_regulatory_data_and_operations.md](07_regulatory_data_and_operations.md)
  — Regulatory and Licensing Constraints, Ethics and Responsible-Use,
  Data Rights, Runbook Integration, Payload-Specific Mission Families,
  Weather and Collection Quality, Standards and Interchange,
  Planning Dataset Management, Ground Data Processing Capacity.
- [08_model_lifecycle_and_explainability.md](08_model_lifecycle_and_explainability.md)
  — Cost and Opportunity Model, Requirements Traceability,
  Model Explainability and Sensitivity, Model Sandbox and Experiment Registry,
  Planning Model vs Truth Model, Data Product Pipeline.
- [09_security_and_modes.md](09_security_and_modes.md)
  — Security and Command Safety, Adversarial and Interference Environment,
  What-If and Trade Study Mode, Planning SLAs, Simulation and Rehearsal Mode,
  Model Composition and Plugin System, Supply Chain,
  Data Lineage and Provenance Depth, Quality Gates, Resilience,
  Anomaly Knowledge Base, Multi-Tenant Boundaries.
- [10_knowledge_observability_and_failure.md](10_knowledge_observability_and_failure.md)
  — Domain Ontology, Planning Knowledge Graph, Planner Observability,
  Service-Level Reliability, Mission Performance Analytics,
  Uncertainty and Margins, Telemetry Calibration Loop,
  Failure and Degraded Operations, Authority and Safety Boundaries.
- [11_verification_and_validation.md](11_verification_and_validation.md)
  — External Simulator Adapter Boundary, Verification Harness and
  Model Test Kit, Fault Injection, Interoperability Test Suite,
  Red-Team and Challenge Testing, Validation and Trust.
- [12_operational_readiness.md](12_operational_readiness.md)
  — Certification and Review Package, Safety Case,
  Operational Readiness Levels, Operator Training and Certification Evidence,
  Scenario and Fixture Library, Operator Explainability,
  Planner Explainability UX Contract, Knowledge Capture,
  Archive and Retention Policy, Deprecation and Migration Policy.
- [13_boundaries_and_governance.md](13_boundaries_and_governance.md)
  — Cadence Integration Boundary, Planning API Surface,
  Internationalization and Presentation Boundaries, Model Governance.
- [14_maturity_matrix.md](14_maturity_matrix.md)
- [15_open_questions.md](15_open_questions.md)
- [16_near_term_planning_candidates.md](16_near_term_planning_candidates.md)
