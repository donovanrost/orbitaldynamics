# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline schedule-conflict lookup policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move activity schedule-conflict lookup into
`Timeline.ScheduleConflictPolicy`. `Timeline` retains one private entry point;
operational row assembly and operator-action policy callback wiring remain
unchanged.

Why this slice:
The 6,252-line Timeline facade still owns one exclusive fallback lookup used by
both operational row evidence and action classification. Moving it isolates
top-level-over-metadata precedence without moving either coordinator or
normalizing the provider value.

Planned proof:
- Focused operational activity context, conflict operator-action, and general
  operational report examples.
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
Timeline activity-ID encoding policy extraction, selected in `70ce1d8e` and
implemented in `24d6193c`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
