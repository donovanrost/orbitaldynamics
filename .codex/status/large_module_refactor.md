# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline command-window context extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move the private command-window activity-type constant,
`activity_command_window_context/1`, relevance checks, explicit/nested/metadata
ID and type lookup, ID inference, and type inference into
`Timeline.CommandWindowContext.build/2`. `Timeline` retains every public
function and supplies shared activity-ID and compaction helpers as callbacks.

Why this slice:
The reduced 9,269-line Timeline facade still owns this compact, self-contained
projection. The approximately 52-line cluster has one responsibility, two
callers, a private-only constant, focused regression/diff coverage, and only
two shared dependencies. It is a clean small seam before remapping the larger
precondition and transition regions.

Planned proof:
- Focused Timeline tests covering inferred and explicit command-window
  provenance and command-window-sensitive diffs.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for the exact projection, private constant, and
  every moved clause after normalizing only callback boundaries.
- Format, diff, whitespace, ownership, caller, public-definition, and xref
  checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline execution-uncertainty context extraction, implementation published in
`b2b15284` and handoff published in `5e28e4c1`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing the larger
activity-precondition and transition-integrity regions.

Blocked:
No.
