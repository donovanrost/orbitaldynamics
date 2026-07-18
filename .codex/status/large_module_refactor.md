# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-input normalization flow extraction.

Status:
Implementation published in `f07698e1`; focused and broad proof is green.

Selected boundary:
Move safe activity conversion, validation dispatch, invalid-row routing, and
valid activity normalization into `Timeline.ActivityInputNormalization`.
`Timeline` retains private `normalize_activity_input/2` and
`activity_input_to_map/2` entry points because the latter is shared across
candidate, lifecycle, diff, and summary paths. Activity conversion, issue
classification, invalid-row construction, and valid normalization are supplied
as callbacks.

Why this slice:
The extraction moved four clauses into a 69-line internal module and reduced
Timeline from 7,507 to 7,491 lines. The two private entry points preserve all
candidate, lifecycle, diff, summary, and list-normalization callers.

Completed proof:
- Focused activity-input normalization examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,726 files.
- Canonical AST equivalence: all four moved clauses after normalizing only the
  two facade names and callback boundaries.
- Format, whitespace, ownership, exactly-two-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-input normalization flow extraction, selected in `a6bca7f2`
and implemented in `f07698e1`.

Next candidate:
Remap the reduced 7,491-line Timeline facade, emphasizing transition integrity
gating and activity normalization.

Blocked:
No.
