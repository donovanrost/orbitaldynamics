# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity numeric-value policy extraction.

Status:
Implementation published in `344471d0`; focused and broad proof is green.

Selected boundary:
Move numeric triplet conversion, scalar numeric parsing, and three-dimensional
vector norm into `Timeline.ActivityNumericValuePolicy`. `Timeline` retains
three private entry points. The boundary has no callbacks, module attributes,
or shared vocabulary arguments.

Why this slice:
The extraction moved seven clauses into a 28-line internal module and reduced
Timeline from 6,396 to 6,383 lines. Three private entry points preserve numeric
normalization, activity field selection, execution uncertainty, station
calendar, and context callback callers while moving number parsing, triplet
validation, and vector norm behavior out of the facade.

Completed proof:
- Focused valid/string uncertainty, numeric context, link-quality, and thermal
  examples: 5 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,751 files.
- Canonical AST equivalence: all seven moved clauses after normalizing only
  the three facade names.
- Format, whitespace, ownership, exactly-three-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity numeric-value policy extraction, selected in `52240076` and
implemented in `344471d0`.

Next candidate:
Remap the reduced 6,383-line Timeline facade, avoiding the wide activity-to-map
coordinator callback surface.

Blocked:
No.
