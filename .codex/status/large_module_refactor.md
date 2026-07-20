# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh callback-aware JSON-property routing.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Approval-requirement JSON-property family routing, selected in `35933100` and
implemented in `d6c490df`. The parent router moved from 572 to 563 lines.

Next candidate:
Implement and verify the selected callback-aware route, then return to the
public `Schema` facade's provider-helper boundaries.

Blocked:
No.
