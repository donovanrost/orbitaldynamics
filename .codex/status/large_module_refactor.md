# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lock-or-approval protection policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move Timeline's remaining lock-or-approval combination clause into the existing
`Timeline.ApprovalProtectionPolicy`. `Timeline` retains one private entry point
and passes its existing locked and approved predicates explicitly; protection
decision coordination remains unchanged.

Why this slice:
The 6,253-line Timeline facade still owns one exclusive protection combination
leaf while fallback source sensitivity and approval membership already belong
to `ApprovalProtectionPolicy`. Moving it completes the reusable boolean
classification boundary without moving transition application decisions.

Planned proof:
- Focused auto-approvable, lock/approval/executed preservation, and JSON-string
  truthy protection examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for the moved definition after normalizing only the
  public/private head and explicit predicate callbacks.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline collection list-value policy extraction, selected in `77ebf7f8` and
implemented in `67d1a114`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
