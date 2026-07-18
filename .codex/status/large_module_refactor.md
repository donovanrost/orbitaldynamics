# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline invalid activity-input row filtering extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move Timeline's invalid-activity-input row filter into the existing
`Timeline.ActivityInputPolicy`. `Timeline` retains one private entry point;
source/replacement diff report assembly and invalid row construction remain
unchanged.

Why this slice:
The 6,262-line Timeline facade still owns one exclusive input-classification
leaf while activity issue detection already belongs to `ActivityInputPolicy`.
Moving the row filter completes that simple classification boundary without
moving report counts, ordering, or preservation logic.

Planned proof:
- Focused invalid operational input, invalid source/replacement diff, and valid
  unchanged public diff examples.
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
Timeline stable-identifier policy extraction, selected in `19bfd2ad` and
implemented in `7eaf4c9c`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
