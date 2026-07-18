# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff protection-context policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move all three diff protection-context clauses into
`Timeline.DiffProtectionContextPolicy`. `Timeline` retains one private entry
point and passes the existing protection-decision function explicitly; the
protection coordinator and diff-row callback list remain unchanged.

Why this slice:
The 6,234-line Timeline facade still owns a complete three-clause context
family for nil, empty, and populated protection rows. Moving the family together
isolates exact callback timing and prefixed result projection without moving the
protection decision coordinator or widening the diff-row boundary.

Planned proof:
- Focused changed protected/executed, changed unprotected, and unchanged
  public-facade diff examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  public/private heads, facade names, and the explicit callback argument.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline diff relationship-context policy extraction, selected in `b3b9347f`
and implemented in `56cc0522`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
