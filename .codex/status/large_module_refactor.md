# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline deterministic count-summary policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move duplicate-group/activity totals, generic field counts, changed-field
counts, transition type/category counts, and deterministic count-map sorting
into `Timeline.CountSummaryPolicy`. `Timeline` retains seven private entry
points; changed-field list extraction crosses the boundary explicitly.

Why this slice:
The 6,291-line Timeline facade still owns seven pure summary clauses shared by
operational, diff, lifecycle, transition-application, protection, and integrity
reports. Moving them together isolates nil filtering, frequency calculation,
duplicate cardinality, transition path selection, and stable map ordering
without extracting any report coordinator.

Planned proof:
- Focused operational count, duplicate identity, transition application
  summary, and timeline-diff changed/transition count examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all seven moved clauses after normalizing only
  public/private heads and the changed-field list callback.
- Format, diff, whitespace, ownership, exactly-seven-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline publication scalar-input policy extraction, selected in `93af9e7a`,
implemented in `e5df6b2a`, and handed off in `3f39dd86`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
