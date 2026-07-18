# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-helper integrity policy extraction.

Status:
Implementation published in `ae937888`; focused and broad proof is green.

Selected boundary:
Move opt-in transition-helper selected-activity validation, structured
integrity error construction, and status/approval/lifecycle raising policy into
`Timeline.TransitionHelperIntegrityPolicy`. `Timeline` retains private entry
points for validation and the three helper-specific raisers. Integrity
annotation/detection, selected projection/reason, list normalization, and map
compaction are supplied as callbacks.

Why this slice:
The extraction moved eight clauses into a 91-line internal module and reduced
Timeline from 7,429 to 7,392 lines. The four private entry points preserve all
status, approval, and lifecycle helper callers.

Completed proof:
- Focused transition-helper integrity examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,728 files.
- Canonical AST equivalence: all eight moved clauses after normalizing only the
  four facade names and callback boundaries.
- Format, whitespace, ownership, exactly-four-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline transition-helper integrity policy extraction, selected in `73d5f985`
and implemented in `ae937888`.

Next candidate:
Remap the reduced 7,392-line Timeline facade, emphasizing transition integrity
orchestration and activity normalization.

Blocked:
No.
