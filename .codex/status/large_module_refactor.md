# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness capability-metadata extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract operational-readiness capability/contract metadata assembly into
`OrbitalDynamics.OperationalReadiness.Capability`.
Preserve `OperationalReadiness.capabilities/0` and all downstream public
facades.

Selection evidence:
- Live re-ranking places `operational_readiness.ex` at 484 lines, the
  largest remaining facade in this refactor lane.
- Report, gate, evidence, and summary construction already delegate to focused
  owners; the remaining large inline block is static capability metadata and
  its dependent capability lookups.
- The selected code has one responsibility: advertise stable readiness
  contracts, classifications, semantics, helpers, handoff artifacts, and known
  limits.
- Report routing, schema-contract pattern matching, source acquisition, and
  report construction remain outside the boundary.
- Exact capability keys and values, list ordering, dependent capability
  lookups, atom/string types, and public output must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-preservation extraction, selected in
`456df820` and implemented in `7054c53b`.
`recommendation_risk_context.ex` moved from 573 to 473 lines; the dedicated
TimelinePreservation owner is 133 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest remaining facade at 473 lines.

Blocked:
No.
