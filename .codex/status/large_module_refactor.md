# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state decision policy extraction.

Status:
Implementation published in `8c570e68`; focused and broad proof is green.

Selected boundary:
Move the complete status/approval/lifecycle decision and operator-action policy
cluster into `Timeline.LifecycleStatePolicy`: transition decisions, review
flags, import actions, operator actions/reasons, and protection aggregation.
`Timeline` retains the 11 existing private entry points used by state artifact
construction. The shared deterministic `sorted_uniq/1` behavior is supplied as
one callback to the two aggregators.

Why this slice:
The extraction moved 27 clauses into a 127-line internal module and reduced
Timeline from 7,852 to 7,813 lines. The 11 facade entry points preserve all
current status, approval, and combined-lifecycle artifact callers.

Completed proof:
- Focused lifecycle-state examples: 4 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,720 files.
- Canonical AST equivalence: all 27 moved clauses after normalizing only facade
  names and the `sorted_uniq/1` callback boundary.
- Format, whitespace, ownership, exactly-11-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-state decision policy extraction, selected in `4fdafc43` and
implemented in `8c570e68`.

Next candidate:
Remap the reduced 7,813-line Timeline facade, emphasizing operational action
classification and transition-decision summarization.

Blocked:
No.
