# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff relationship-context policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move dependency/integrity diff-context shaping and schedule-overlap
diff-context shaping into `Timeline.DiffRelationshipContextPolicy`. `Timeline`
retains two private entry points and the existing diff-row callbacks remain
unchanged; no callback, constant, report coordinator, or schema boundary
crosses the extraction.

Why this slice:
The 6,258-line Timeline facade still owns two exclusive pure map shapers for
relationship review context. Moving them together isolates exact prefixed field
projection without pulling the adjacent callback-bearing protection context or
the wider diff-row coordinator across the boundary.

Planned proof:
- Focused dependency-cycle, dependency/exclusivity/overlap change, and unchanged
  public-facade diff examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for both moved definitions after normalizing only
  public/private heads and facade function names.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline diff invalid-input context policy extraction, selected in `a5faf610`
and implemented in `fcf2bd75`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
