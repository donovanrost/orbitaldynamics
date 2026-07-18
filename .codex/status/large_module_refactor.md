# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline invalid lifecycle-state input policy extraction.

Status:
Implementation published in `7099753c`; focused and broad proof is green.

Selected boundary:
Move optional lifecycle-state input conversion, invalid-row detection and
aggregation, invalid/valid state identity access, and planned-before-realized
display identity into `Timeline.InvalidLifecycleStateInputPolicy`. `Timeline`
retains nine private entry points. Activity conversion, activity/timeline ID,
and sorted-unique helpers cross the boundary as callbacks.

Why this slice:
The extraction moved 17 clauses into a 93-line internal module and reduced
Timeline from 6,767 to 6,759 lines. Nine private entry points preserve shared
status, approval, combined-state, and transition-helper callers while moving
the branching responsibility out of the facade.

Completed proof:
- Focused invalid lifecycle-state input examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,741 files.
- Canonical AST equivalence: all 17 moved clauses after normalizing only the
  nine facade names and callback boundaries.
- Format, whitespace, ownership, exactly-nine-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline invalid lifecycle-state input policy extraction, selected in
`070962e4` and implemented in `7099753c`.

Next candidate:
Remap the reduced 6,759-line Timeline facade, emphasizing remaining activity
normalization and lifecycle state assembly.

Blocked:
No.
