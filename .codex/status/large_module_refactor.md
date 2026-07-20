# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign artifact JSON-property family extraction.

Status:
Implemented and verified.

Selected boundary:
Extract the adjacent campaign-plan and campaign-repair clauses from
`JsonSchemaPropertyRouter` into a campaign artifact family owner. Keep the
parent router's exact clause heads/order and pass its property callback
explicitly so campaign repair preserves recursive timeline-transition schema
routing without coupling the child back to the parent module.

Selection evidence:
- The parent router remains 1,241 lines across 76 contract-family clauses.
- The next two clauses are a contiguous 40-line campaign artifact boundary
  already delegated through one focused dispatcher.
- Campaign repair's only cross-family dependency is its recursive property
  callback for the timeline-transition contract.
- Passing that callback explicitly preserves the recursion and keeps the child
  dependency one-way while reusing `JsonSchemaPropertySupport`.

Implementation:
- Added a 57-line `CampaignArtifactPropertyRouter` with the campaign-plan and
  campaign-repair clause bodies.
- Passed a three-arity property callback from the parent so repair retains its
  recursive timeline-transition lookup without a child-to-parent dependency.
- Kept both original parent clause heads in place as ordered delegations.
- The parent router moved from 1,241 to 1,226 lines.

Verification:
- Strict pre-change baseline and post-change schema/validation suite: 359 tests
  passed in each run.
- AST comparison confirmed all 76 parent clause heads remain in their original
  order; focused tests and exports exercised the explicit recursive callback.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the two intended family edges.
- Formatting, `git diff --check`, and bounded source/schema diff review passed.
- Strict compile passed for 4,098 files with warnings as errors.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Campaign artifact JSON-property family extraction, selected in `a8372d62` and
implemented in `52d33f59`. The parent router moved from 1,241 to 1,226 lines.

Next candidate:
Re-rank the adjacent realized-state and timeline-report clauses, preferring a
family with no new cross-family callback surface.

Blocked:
No.
