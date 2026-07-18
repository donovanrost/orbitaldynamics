# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-transition review policy extraction.

Status:
Implementation published in `b16a898a`; focused and broad proof is green.

Selected boundary:
Move status/approval transition review classification, shared review metadata
construction, and operator-review detection into
`Timeline.LifecycleTransitionReviewPolicy`. `Timeline` retains the private
status-review, approval-review, and review-detection entry points. Status lists
and existing unsupported/repairable predicates cross the boundary explicitly;
transition assembly and lifecycle categories remain Timeline-owned.

Why this slice:
The extraction moved nine clauses into a 194-line internal module and reduced
Timeline from 6,918 to 6,791 lines. Three private entry points preserve status
review, approval review, and operator-review detection callers while transition
assembly and lifecycle categories remain Timeline-owned.

Completed proof:
- Focused lifecycle-transition review examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,739 files.
- Canonical AST equivalence: all nine moved clauses after normalizing only the
  three facade names, constant arguments, and predicate callbacks.
- Format, whitespace, ownership, exactly-three-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-transition review policy extraction, selected in `f1b8de8b`
and implemented in `b16a898a`.

Next candidate:
Remap the reduced 6,791-line Timeline facade, emphasizing lifecycle transition
assembly and remaining activity normalization.

Blocked:
No.
