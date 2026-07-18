# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline source-window normalization policy extraction.

Status:
Implementation published in `ca54e136`; focused and broad proof is green.

Selected boundary:
Move direct and metadata-nested source-window normalization plus exclusive
window ID/type lookup into `Timeline.SourceWindowNormalizationPolicy`.
`Timeline` retains the single normalization entry point used by
`activity_to_map/1` and supplies its shared `put_new_present/3` helper as a
callback.

Why this slice:
The extraction moved five clauses into a 49-line internal module and reduced
Timeline from 7,108 to 7,082 lines. The single private entry point preserves
`activity_to_map/1` pipeline order and supplies only the shared present-value
insertion callback.

Completed proof:
- Focused source-window normalization examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,734 files.
- Canonical AST equivalence: all five moved clauses after normalizing only the
  single facade name and callback boundary.
- Format, whitespace, ownership, exactly-one-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline source-window normalization policy extraction, selected in `9f7b012d`
and implemented in `ca54e136`.

Next candidate:
Remap the reduced 7,082-line Timeline facade, emphasizing activity normalization
and lifecycle application.

Blocked:
No.
