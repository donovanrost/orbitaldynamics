# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-input validation policy extraction.

Status:
Implementation published in `ea3e2c42`; focused and broad proof is green.

Selected boundary:
Move activity input issue precedence plus ID/type/status/approval, nested-shape,
unit-interval, and stable-identity-path validation into
`Timeline.ActivityInputPolicy`. `Timeline` retains one private
`activity_input_issue/1` facade. Status/approval lists and field/path metadata
are supplied as selection data; activity status/approval normalization,
numeric normalization, and stable-ID validation are supplied as callbacks.

Why this slice:
The extraction moved 19 clauses into a 149-line internal module and reduced
Timeline from 7,619 to 7,507 lines. The one private facade preserves the
short-circuit order that determines which invalid reason wins.

Completed proof:
- Focused activity-input validation examples: 6 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,725 files.
- Canonical AST equivalence: all 19 moved clauses after normalizing only the
  facade name and selection-data/callback boundaries.
- Format, whitespace, ownership, exactly-one-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-input validation policy extraction, selected in `677f8278`
and implemented in `ea3e2c42`.

Next candidate:
Remap the reduced 7,507-line Timeline facade, emphasizing transition integrity
gating and invalid-input normalization flow.

Blocked:
No.
