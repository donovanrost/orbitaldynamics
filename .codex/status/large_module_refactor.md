# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline optional activity-input policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move both optional activity-to-map clauses into
`Timeline.OptionalActivityInputPolicy`. `Timeline` retains one private entry
point and passes its existing activity conversion function explicitly; public
status/approval transition coordinators remain unchanged.

Why this slice:
The 6,246-line Timeline facade still owns a complete two-clause optional-input
family reused by activity, status, and approval transition entry points. Moving
it isolates nil callback bypass and present-input conversion without moving
those public coordinators or the larger activity normalization pipeline.

Planned proof:
- Focused reusable transition, selected-integrity transition, and blocked
  lifecycle transition examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for both moved clauses after normalizing only
  public/private heads, facade name, and the explicit conversion callback.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-status membership policy extraction, selected in `873251c3`
and implemented in `804f0f70`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
