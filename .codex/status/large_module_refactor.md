# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline selected-integrity policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move selected-activity application gating, the complete selected-integrity
projection, review action/status upgrades, and deterministic reason formatting
into `Timeline.SelectedIntegrityPolicy`. `Timeline` retains private entry points
for application gating, context projection, and reason formatting. Integrity
review detection, list normalization, and map compaction are supplied as
callbacks.

Why this slice:
The reduced Timeline facade is 7,491 lines. These eight exclusive clauses form
an approximately 85-line selected-integrity policy shared by direct decisions,
single applications, batch applications, and transition helper errors. Keeping
the projection and upgrade rules together avoids splitting their field contract.

Planned proof:
- Focused Timeline tests for direct lifecycle integrity gating, reusable
  decisions, single applications, and batch applications.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all eight moved clauses after normalizing only
  the three facade names and callback boundaries.
- Format, diff, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-input normalization flow extraction, selected in `a6bca7f2`,
implemented in `f07698e1`, and handed off in `ae71c9f9`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing transition
integrity orchestration and activity normalization.

Blocked:
No.
