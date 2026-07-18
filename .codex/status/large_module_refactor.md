# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline integrity issue-construction policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move Timeline's integrity issue-construction leaf into
`Timeline.IntegrityIssuePolicy`. `Timeline` retains one private entry point and
the existing `IntegrityAnnotation` callback bundle remains unchanged.

Why this slice:
The 6,258-line Timeline facade still owns one exclusive issue-map mutation used
only through integrity annotation. Moving it isolates exact string-key
insertion and overwrite behavior without moving the annotation coordinator or
its issue detection clauses.

Planned proof:
- Focused dependency/exclusivity integrity, timeline-ID integrity handoff, and
  normalized integrity annotation examples.
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
Timeline lock-or-approval protection policy extraction, selected in `95633792`
and implemented in `15e50e2a`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
