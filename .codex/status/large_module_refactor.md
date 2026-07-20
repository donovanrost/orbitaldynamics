# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Provider-counteroffer JSON-property family routing.

Status:
Completed and pushed.

Selected boundary:
Move the four-contract provider-counteroffer property body from
`JsonSchemaPropertyRouter` into the existing
`GroundNetworkPropertyRouter`. Keep the parent router's exact guarded clause
head/order as a delegation.

Selection evidence:
- Only three domain property bodies remain inline in the 581-line parent
  router, excluding its global lighting special case and fallback.
- The roughly 25-line counteroffer body covers report, review, import
  readiness, and plan-impact contracts tied to provider/ground-network
  operations.
- It fits the existing ground-network owner and its shared
  provider/context/fallback support.
- No recursive parent callback, embedded-schema callback, or cross-family
  property lookup is required.

Implementation:
Selected in `caa5f091` and implemented in `37c6d3a7`.
`JsonSchemaPropertyRouter` retains all 76 public route heads in their original
order and delegates the guarded four-contract clause to
`GroundNetworkPropertyRouter`. The existing owner now contains eleven related
ground-network/provider routes and preserves the copied lazy
provider/context/fallback body.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- AST-rendered comparison confirmed the moved body is exact and all 76 parent
  route heads remain exact and ordered.
- Xref reports eleven runtime edges from the parent to the ground-network
  owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,107 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The parent router shrank from 581 to 572 lines; the ground-network owner grew
  from 218 to 242 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Provider-counteroffer JSON-property family routing, selected in `caa5f091` and
implemented in `37c6d3a7`. The parent router moved from 581 to 572 lines.

Next candidate:
Re-rank the approval and callback-bearing candidate-refresh bodies against the
public `Schema` facade's provider-helper boundaries.

Blocked:
No.
