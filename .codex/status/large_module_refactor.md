# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-boolean policy extraction.

Status:
Implementation published in `787e5732`; focused and broad proof is green.

Selected boundary:
Move boolean parsing, strict truthiness, first-present top-level/metadata lookup,
and locked/approved/overlap activity flags into
`Timeline.ActivityBooleanPolicy`. `Timeline` retains private entry points for
first boolean lookup, boolean parsing, and the three activity flags. Strict
truthiness stays internal to the new policy. Approval-status normalization and
protected approval constants cross the boundary explicitly.

Why this slice:
The extraction moved 13 clauses into an 88-line internal module and reduced
Timeline from 7,006 to 6,944 lines. Five private entry points preserve shared
report and protection callers while strict truthiness remains policy-private.

Completed proof:
- Focused activity-boolean examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,737 files.
- Canonical AST equivalence: all 13 moved clauses after normalizing only the
  five facade names, protected-status argument, and approval-status callback.
- Format, whitespace, ownership, exactly-five-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent review's initial low-severity truthiness visibility finding was
  corrected; re-review found no remaining findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-boolean policy extraction, selected in `25604047`, corrected
in `20e122b9`, and implemented in `787e5732`.

Next candidate:
Remap the reduced 6,944-line Timeline facade, emphasizing remaining activity
normalization and lifecycle application.

Blocked:
No.
