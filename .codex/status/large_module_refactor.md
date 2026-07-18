# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline single-transition decision policy extraction.

Status:
Implementation published in `11b72e46`; focused and broad proof is green.

Selected boundary:
Move the complete single-transition decision builder, diff-report adapter, and
zero/one/multiple-row summarization policy into `Timeline.TransitionDecisionPolicy`.
`Timeline` retains one private `base_transition_decision/3` facade used by the
public decision and application helpers. Shared `diff_report/3` and
`compact_map/1` behavior is supplied as callbacks.

Why this slice:
The extraction moved six clauses into a 76-line internal module and reduced
Timeline from 7,813 to 7,752 lines. The one private facade preserves public
decision/application callers and leaves integrity gating Timeline-owned.

Completed proof:
- Focused transition decision/application examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,721 files.
- Canonical AST equivalence: all six moved clauses after normalizing only the
  facade name and two callback boundaries.
- Format, whitespace, ownership, exactly-one-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline single-transition decision policy extraction, selected in `e398ffc1`
and implemented in `11b72e46`.

Next candidate:
Remap the reduced 7,752-line Timeline facade, emphasizing operational action
classification and transition integrity gating.

Blocked:
No.
