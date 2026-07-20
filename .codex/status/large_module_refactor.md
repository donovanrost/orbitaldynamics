# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Execution-artifact JSON-property extraction.

Status:
Completed and pushed.

Selected boundary:
Move the realized-state-snapshot, realized-activity, and
maneuver-recommendation property bodies from `JsonSchemaPropertyRouter` into a
new `ExecutionArtifactPropertyRouter`. Keep the parent router's exact literal
clause heads/order as delegations.

Selection evidence:
- Only eight domain property bodies remain inline in the 615-line parent
  router, excluding its global lighting special case and fallback.
- These three bodies form a roughly 55-line realized-execution/maneuver
  artifact boundary.
- A dedicated owner needs only the shared provider/context/fallback support.
- No recursive parent callback, embedded-schema callback, or cross-family
  property lookup is required.

Implementation:
Selected in `94e3e7b8` and implemented in `b3ee5b97`.
`JsonSchemaPropertyRouter` retains all 76 public route heads in their original
order and delegates the three selected bodies to the new
`ExecutionArtifactPropertyRouter`. The owner contains realized snapshot,
realized activity, and maneuver recommendation dispatch with shared lazy
provider/context/fallback support.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- AST-rendered comparison confirmed all three moved bodies are exact and all 76
  parent route heads remain exact and ordered.
- Xref reports three runtime edges from the parent to the execution-artifact
  owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,107 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The parent router shrank from 615 to 581 lines; the new owner is 53 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Execution-artifact JSON-property extraction, selected in `94e3e7b8` and
implemented in `b3ee5b97`. The parent router moved from 615 to 581 lines.

Next candidate:
Re-rank the remaining inline router routes against the public `Schema`
facade's provider-helper boundaries.

Blocked:
No.
