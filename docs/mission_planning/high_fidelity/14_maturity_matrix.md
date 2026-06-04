# Maturity Matrix

## Maturity Matrix

The high-fidelity roadmap should track maturity by subsystem and fidelity tier.

Initial target matrix:

```text
Subsystem / Capability        Tier 0       Tier 1       Tier 2       Tier 3       Tier 4
Onboard autonomy boundary     none         planned      later        later        adapter
Automation guardrails         none         planned      later        later        n/a
Planning product types        partial      planned      later        later        n/a
Hierarchical planning         none         planned      later        later        n/a
Plan lifecycle                partial      planned      later        later        n/a
Plan publication/subscription none         planned      later        later        n/a
Plan merge/conflict           none         planned      later        later        n/a
Constraint library            partial      planned      later        later        n/a
Objective library             partial      planned      later        later        n/a
Rejection catalog             partial      planned      later        later        n/a
Plan diff/audit trail         partial      planned      later        later        n/a
Power and battery             planned      planned      later        later        adapter
Storage and recorder          partial      planned      later        later        adapter
Communications and link        partial      planned      later        later        adapter
Ground station calendar        partial      planned      later        later        adapter
Payload operations             none         planned      later        later        adapter
ADCS and pointing              none         later        later        later        adapter
Propulsion and maneuvers       partial      planned      later        later        adapter
Thermal                        none         later        later        later        adapter
Command and FDIR               partial      planned      later        later        adapter
Mission phase policy           none         planned      later        later        n/a
Deployment/phasing             none         planned      later        later        adapter
Procedure modeling             none         planned      later        later        adapter
Collaborative planning         none         planned      later        later        n/a
Operational risk               partial      planned      later        later        adapter
Human workload                 none         planned      later        later        n/a
Data product pipeline          none         planned      later        later        adapter
Payload mission families       none         planned      later        later        adapter
Weather/collection quality     none         planned      later        later        adapter
Ground processing capacity     none         planned      later        later        adapter
Space traffic safety           none         planned      later        later        adapter
Crosslink/relay operations     none         planned      later        later        adapter
Adversarial/interference       none         planned      later        later        adapter
Regulatory/licensing           none         planned      later        later        adapter
Cost/opportunity model         none         planned      later        later        n/a
Requirements traceability      partial      planned      later        later        n/a
Quality gates                  partial      planned      later        later        n/a
Simulation/rehearsal           none         planned      later        later        adapter
Model composition/plugins      none         planned      later        later        adapter
Planner observability          partial      planned      later        later        n/a
Planning API surface           partial      planned      later        later        n/a
Fleet health strategy          none         planned      later        later        n/a
Customer commitments           none         planned      later        later        adapter
Model sensitivity              none         planned      later        later        adapter
Planning SLAs                  none         planned      later        later        n/a
Multi-mission boundaries       none         planned      later        later        n/a
OD handoff                     partial      planned      later        later        adapter
Planning vs truth model        none         planned      later        later        adapter
Anomaly knowledge base         none         planned      later        later        adapter
Mission analytics              none         planned      later        later        n/a
Operational readiness levels   none         planned      later        later        n/a
Knowledge capture              none         planned      later        later        n/a
Domain ontology                partial      planned      later        later        n/a
Verification harness           partial      planned      later        later        n/a
Fault injection                none         planned      later        later        adapter
Interoperability tests         partial      planned      later        later        n/a
Certification/review package   none         planned      later        later        n/a
Safety case                    none         planned      later        later        n/a
Runbook integration            none         planned      later        later        adapter
Dataset management             none         planned      later        later        n/a
Model sandbox/experiments      none         planned      later        later        n/a
Planning knowledge graph       none         planned      later        later        n/a
Archive/retention              none         planned      later        later        n/a
Program/portfolio planning     none         planned      later        later        n/a
Provider negotiation           none         planned      later        later        adapter
Service reliability            none         planned      later        later        n/a
Deprecation/migration          partial      planned      later        later        n/a
Challenge testing              none         planned      later        later        n/a
Vendor dependency governance   none         planned      later        later        n/a
Responsible-use markings       none         planned      later        later        adapter
Operator training evidence     none         planned      later        later        n/a
```

Status labels:

- `none`: not represented except as generic metadata.
- `partial`: represented through current artifact summaries or policy rows.
- `planned`: good candidate for the next explicit model slice.
- `later`: useful after Tier 1 behavior is established.
- `adapter`: likely best served by an external simulator or mission system
  behind a contract.

