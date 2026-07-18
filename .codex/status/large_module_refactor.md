# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-boolean policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move boolean parsing, strict truthiness, first-present top-level/metadata lookup,
and locked/approved/overlap activity flags into
`Timeline.ActivityBooleanPolicy`. `Timeline` retains private entry points for
first boolean lookup, boolean parsing, and the three activity flags. Strict
truthiness stays internal to the new policy. Approval-status normalization and
protected approval constants cross the boundary explicitly.

Why this slice:
The reduced Timeline facade is 7,006 lines. These 13 clauses own the two
intentional boolean semantics: nullable parsing for report fields and strict
truthiness for protection flags. The boundary also keeps top-level-before-
metadata precedence and approval-derived protection together.

Planned proof:
- Focused Timeline examples for boolean report fields, allow-overlap aliases,
  string truthy protection flags, and approved/locked protection.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 13 moved clauses after normalizing only the
  five facade names, protected-status argument, and approval-status callback.
- Format, diff, whitespace, ownership, exactly-five-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-state normalization policy extraction, selected in
`0397b88d`, corrected in `30899948` and `41fd2988`, implemented in `01ceb18c`,
and handed off in `db585f59`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing remaining
activity normalization and lifecycle application.

Blocked:
No.
