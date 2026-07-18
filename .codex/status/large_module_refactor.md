# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state normalization policy extraction.

Status:
Implementation published in `01ceb18c`; focused and broad proof is green.

Selected boundary:
Move lifecycle event alias resolution, activity/approval status
canonicalization, and preserved terminal-status handling into
`Timeline.LifecycleStateNormalizationPolicy`. `Timeline` retains private entry
points for lifecycle events, lifecycle values, activity status, approval
status, the two capability alias maps, and preserved-status application.
Constant lists and the non-string encoder cross the boundary explicitly.

Why this slice:
The extraction moved 12 clauses into an 88-line internal module and reduced
Timeline from 7,037 to 7,006 lines. Seven private entry points preserve shared
report, transition, lifecycle-application, and capability-map callers.

Completed proof:
- Focused lifecycle-state normalization example: 1 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,736 files.
- Canonical AST equivalence: all 12 moved clauses after normalizing only the
  seven facade names, constant arguments, and encoder callback.
- Format, whitespace, ownership, exactly-seven-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-state normalization policy extraction, selected in
`0397b88d`, corrected in `30899948` and `41fd2988`, and implemented in
`01ceb18c`.

Next candidate:
Remap the reduced 7,006-line Timeline facade, emphasizing remaining activity
normalization and lifecycle application.

Blocked:
No.
