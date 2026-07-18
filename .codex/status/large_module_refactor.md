# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity identity policy extraction.

Status:
Implementation published in `40a099b3`; focused and broad proof is green.

Selected boundary:
Move durable/derived timeline identity, subject selection, and source-window ID
and type selection into `Timeline.ActivityIdentityPolicy`. `Timeline` retains
four private entry points; derived identity becomes internal to the policy.
Activity start selection and artifact-value encoding cross the boundary
explicitly.

Why this slice:
The extraction moved five clauses into a 54-line internal module and reduced
Timeline from 6,599 to 6,568 lines. Four private entry points preserve row,
context, transition, lifecycle-summary, and publication callers while moving
explicit/derived timeline identity, subject precedence, and nested
source-window identity out of the facade.

Completed proof:
- Focused persistent/derived identity, provider station, nested source-window,
  and metadata source-window examples: 5 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,747 files.
- Canonical AST equivalence: all five moved clauses after normalizing only
  the four facade names and two callback boundaries.
- Format, whitespace, ownership, exactly-four-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity identity policy extraction, selected in `c05b969c` and
implemented in `40a099b3`.

Next candidate:
Remap the reduced 6,568-line Timeline facade, avoiding boundaries whose guard
vocabularies remain shared with Timeline.

Blocked:
No.
