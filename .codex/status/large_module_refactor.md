# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Result artifact JSON-property family extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the adjacent execution-report, result-artifact, and resource-summary
clauses from `JsonSchemaPropertyRouter` into a result artifact family owner.
Keep the parent router's exact clause heads/order and pass embedded-contract
lookup explicitly for `result_artifact.v1`.

Selection evidence:
- The parent router remains 1,147 lines across 76 contract-family clauses.
- Three adjacent clauses form one result-artifact boundary through the existing
  focused dispatcher.
- Only `result_artifact.v1` needs the parent's embedded-contract recursion; an
  explicit one-arity callback preserves that behavior without child coupling.
- The remaining dependencies are shared fallback and stable-ID context only.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline report/state JSON-property family extraction, selected in `64b5888d`
and implemented in `fd18ecf4`. The parent router moved from 1,226 to 1,147
lines.

Next candidate:
Implement and verify the selected result artifact split, then re-rank the
adjacent contact-planning/policy families.

Blocked:
No.
