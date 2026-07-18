# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-transition assembly policy extraction.

Status:
Implementation published in `4717aadf`; focused and broad proof is green.

Selected boundary:
Move lifecycle transition object construction and field-specific semantic
assembly into `Timeline.LifecycleTransitionPolicy`. `Timeline` retains the
single private `lifecycle_transition/3` entry point. Status/approval category,
status/approval review, and compact-map helpers cross the boundary as callbacks.

Why this slice:
The extraction moved seven clauses into a 138-line callback-explicit module and
reduced Timeline from 6,791 to 6,767 lines. The single private entry point
preserves all status and approval transition callers. The initially mapped
lifecycle-vocabulary candidate remained rejected because its module-attribute
guards would require semantic reshaping.

Completed proof:
- Focused lifecycle-transition assembly examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,740 files.
- Canonical AST equivalence: all seven moved clauses after normalizing only the
  single facade name and callback boundaries.
- Format, whitespace, ownership, exactly-one-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-transition assembly policy extraction, initially selected as
vocabulary in `da906798`, corrected in `0e098fb0`, and implemented in
`4717aadf`.

Next candidate:
Remap the reduced 6,767-line Timeline facade, emphasizing remaining activity
normalization and lifecycle state assembly.

Blocked:
No.
