# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline relationship-presence policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move dependency-presence, exclusivity-presence, and their private non-empty-list
predicate into `Timeline.RelationshipPresencePolicy`. `Timeline` retains two
private entry points; no callback, constant, report coordinator, or schema
boundary crosses the extraction.

Why this slice:
The 6,262-line Timeline facade still owns three exclusive relationship-presence
clauses used only by operational-report counts. Moving them together isolates
the list-only/non-empty semantics without pulling the surrounding wide report
assembly or integrity aggregation into the new module.

Planned proof:
- Focused list relationship, normalized scalar relationship, and malformed
  relationship operational-report examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  public/private heads and facade function names.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline diff-presentation policy extraction, selected in `3665226a` and
implemented in `f3f7120a`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
