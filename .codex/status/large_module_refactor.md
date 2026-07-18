# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline artifact-value encoding policy extraction.

Status:
Implementation published in `0a12b3ee`; focused and broad proof is green.

Selected boundary:
Move recursive map/list key stringification, scalar artifact-value encoding,
and nil-only map compaction into `Timeline.ArtifactValueEncodingPolicy`.
`Timeline` retains three private entry points. The boundary has no callbacks or
shared vocabulary arguments.

Why this slice:
The extraction moved eight clauses into a 21-line internal module and reduced
Timeline from 6,615 to 6,609 lines. Three private entry points preserve report,
context, transition, and summary callers while moving recursive key/value
normalization, boolean and nil preservation, atom encoding, scalar
pass-through, and nil-only map compaction out of the facade.

Completed proof:
- Focused operational-row, activity-context, transition, and state examples: 5
  passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,744 files.
- Canonical AST equivalence: all eight moved clauses after normalizing only the
  three facade names.
- Format, whitespace, ownership, exactly-three-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline artifact-value encoding policy extraction, finalized in selection
correction `82527298` and implemented in `0a12b3ee`.

Next candidate:
Remap the reduced 6,609-line Timeline facade; lifecycle-category and
operational-kind extraction both require explicit compile-time vocabulary
ownership decisions.

Blocked:
No.
