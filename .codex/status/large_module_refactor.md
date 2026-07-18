# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline collection list-value policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move Timeline's shared list-value fallback into
`Timeline.CollectionValuePolicy`. `Timeline` retains one private entry point;
impact, integrity, diff, and lifecycle summary call sites and callbacks remain
unchanged.

Why this slice:
The 6,251-line Timeline facade still owns one exclusive collection lookup used
across four responsibility modules. Moving it isolates exact truthy-value versus
empty-list fallback semantics without moving any consumer coordinator or adding
list validation.

Planned proof:
- Focused dependency-impact, integrity-review, diff relationship, and lifecycle
  summary examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for the moved definition after normalizing only the
  public/private head and facade name.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline schedule-conflict lookup policy extraction, selected in `9d18d04a` and
implemented in `cecc1013`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
