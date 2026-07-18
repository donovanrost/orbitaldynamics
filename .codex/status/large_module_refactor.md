# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff-row construction extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move all `timeline_diff_row/4` clauses and their exclusive private helpers
through `duplicate_timeline_identity_scope/2` into
`Timeline.DiffRow.build/5`: duplicate/add/remove/change rows, review and action
selection, safe transition-application provenance, transition-decision
annotation, activity-context projection, and duplicate-scope classification.
`Timeline` retains all public functions, shared status/approval/diff-context
helpers, and the four shared activity/status constants, supplying them through
callbacks and selection data.

Why this slice:
The reduced Timeline facade is 8,564 lines. This approximately 533-line region
has one facade caller, and every private helper it defines is exclusive to the
diff-row constructor. The boundary requires a larger callback/data surface
than prior slices, but it removes a substantially larger mixed responsibility
and preserves public diff-report orchestration in Timeline.

Planned proof:
- Focused Timeline tests covering duplicate identities, added/removed/
  unchanged/changed rows, protected/executed routing, command/contact review,
  context-sensitive changes, blocked transitions, and safe helper provenance.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for every moved clause after normalizing only
  callback and constant-data boundaries.
- Format, diff, whitespace, ownership, single-caller, public-definition, and
  xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline integrity annotation extraction, implementation published in
`c32fa811` and handoff published in `220056d8`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing transition
application and operational-row classification.

Blocked:
No.
