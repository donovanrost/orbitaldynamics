# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Approval-requirement JSON-property family routing.

Status:
Completed and pushed.

Selected boundary:
Move the approval-requirement property body from
`JsonSchemaPropertyRouter` into the existing
`ReferencePolicyPropertyRouter`. Keep the parent router's exact literal clause
head/order as a delegation.

Selection evidence:
- Only approval requirement and callback-bearing candidate refresh remain as
  domain property bodies in the 572-line parent router.
- The roughly 15-line approval body is part of the policy artifact family
  already owned by `ReferencePolicyPropertyRouter`.
- It reuses that owner's existing shared
  provider/context/fallback support.
- No recursive parent callback, embedded-schema callback, or cross-family
  property lookup is required.

Implementation:
Selected in `35933100` and implemented in `d6c490df`.
`JsonSchemaPropertyRouter` retains all 76 public route heads in their original
order and delegates approval requirement to
`ReferencePolicyPropertyRouter`. The existing owner now contains seven
reference/policy routes and preserves the copied lazy
provider/context/fallback body.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- AST-rendered comparison confirmed the moved body is exact and all 76 parent
  route heads remain exact and ordered.
- Xref reports seven runtime edges from the parent to the reference/policy
  owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,107 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The parent router shrank from 572 to 563 lines; the reference/policy owner
  grew from 68 to 81 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Approval-requirement JSON-property family routing, selected in `35933100` and
implemented in `d6c490df`. The parent router moved from 572 to 563 lines.

Next candidate:
Assess the callback-bearing candidate-refresh route against the public
`Schema` facade's provider-helper boundaries.

Blocked:
No.
