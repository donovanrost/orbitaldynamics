# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh callback-aware JSON-property routing.

Status:
Completed and pushed.

Selected boundary:
Move the candidate-refresh property body from `JsonSchemaPropertyRouter` into
the existing `CandidateRefreshPropertyRouter`. Keep the parent router's exact
literal clause head/order and pass its embedded-contract builder as an
explicit callback.

Selection evidence:
- Candidate refresh is the only domain property body left inline in the
  563-line parent router.
- Its roughly 20-line body belongs with the existing candidate-refresh owner
  and reuses that owner's provider/context/fallback support.
- Its embedded-contract schema callback must continue to re-enter the parent
  facade so nested contracts retain the complete ordered route table.
- Existing campaign and result artifact routers establish the explicit
  callback pattern for this boundary.

Implementation:
Selected in `c61978d5` and implemented in `e7dc418b`.
`JsonSchemaPropertyRouter` retains all 76 public route heads in their original
order and delegates candidate refresh to a new callback-aware
`CandidateRefreshPropertyRouter.property/5` clause. The parent supplies the
embedded-contract closure, so nested property resolution still re-enters the
complete facade route table. The facade's now-unused `context_value/2` import
was removed.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- AST-rendered comparison confirmed all 76 parent route heads remain exact and
  ordered, and the moved body is exact after substituting only the original
  embedded closure with the explicit callback argument.
- Xref reports three existing `/4` edges and the new `/5` edge from the parent
  to the candidate-refresh owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,107 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The parent router shrank from 563 to 552 lines; the candidate-refresh owner
  grew from 53 to 80 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Candidate-refresh callback-aware JSON-property routing, selected in `c61978d5`
and implemented in `e7dc418b`. The parent router moved from 563 to 552 lines
and now contains only ordered facade routes, the global lighting special case,
fallback, and embedded-contract bridge.

Next candidate:
Return to the 1,959-line public `Schema` facade and select a cohesive
provider-helper boundary.

Blocked:
No.
