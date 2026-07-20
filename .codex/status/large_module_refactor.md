# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle/report JSON-property family expansion.

Status:
Selected; implementation pending.

Selected boundary:
Move the six contiguous candidate-rejection, timeline report/diff, lifecycle,
preservation, lifecycle-summary, and transition-application clauses from
`JsonSchemaPropertyRouter` into the existing `TimelineReportPropertyRouter`.
Keep the parent router's exact guarded and literal clause heads/order as
delegations.

Selection evidence:
- The parent router remains 772 lines across 76 contract-family clauses.
- Six adjacent clauses form a roughly 110-line timeline lifecycle/report
  boundary covering thirteen related contracts.
- They fit the existing timeline report/state owner and reuse its current lazy
  provider/context/fallback and timeline-context support.
- No recursive parent callback or cross-family property lookup is required.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Operational readiness/handoff JSON-property extraction, selected in `37a271be`
and implemented in `e41ff75a`. The parent router moved from 814 to 772 lines.

Next candidate:
Implement and verify the selected timeline family expansion, then re-rank the
remaining mixed maneuver/strategy/activity tail.

Blocked:
No.
