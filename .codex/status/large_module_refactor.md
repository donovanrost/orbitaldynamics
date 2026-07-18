# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff-row construction extraction.

Status:
Implementation in progress; initial compile exposed a compile-time constant
boundary that is being corrected before verification.

Selected boundary:
Move all `timeline_diff_row/4` clauses and their exclusive private helpers
through `duplicate_timeline_identity_scope/2` into
`Timeline.DiffRow.build/5`: duplicate/add/remove/change rows, review and action
selection, safe transition-application provenance, transition-decision
annotation, activity-context projection, and duplicate-scope classification.
`Timeline` retains all public functions and shared status/approval/diff-context
helpers, supplying them through callbacks. The four private activity/status
constants are mirrored exactly in the extracted module because Elixir guards
require compile-time lists; Timeline retains its copies for other consumers.

Why this slice:
The reduced Timeline facade is 8,564 lines. This approximately 533-line region
has one facade caller, and every private helper it defines is exclusive to the
diff-row constructor. The boundary requires a larger callback/data surface
than prior slices, but it removes a substantially larger mixed responsibility
and preserves public diff-report orchestration in Timeline.

Boundary corrections:
Initial compile confirmed that executed/protected status and command activity/
direction lists are used in guards. Runtime selection data is invalid in those
guards, so the extracted module mirrors the exact private constants instead.
The next compile exposed the existing `put_transition_decision/1` facade
caller through a function capture plus shared `activity_context/1` and
`approval_protected?/1` dependencies. Both facade entry points therefore use
one shared callback list.

Planned proof:
- Focused Timeline tests covering duplicate identities, added/removed/
  unchanged/changed rows, protected/executed routing, command/contact review,
  context-sensitive changes, blocked transitions, and safe helper provenance.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for every moved clause after normalizing only
  callback boundaries and verifying the mirrored constants exactly.
- Format, diff, whitespace, ownership, two-caller, public-definition, and
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
