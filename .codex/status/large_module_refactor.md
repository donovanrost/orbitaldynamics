# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline invalid-activity row extraction.

Status:
Implementation published in `9ee57bb5`; focused and broad proof is green.

Selected boundary:
Move deterministic invalid-activity row construction and invalid activity-ID
fallback policy into `Timeline.InvalidActivityRow`. `Timeline` retains one
private `invalid_activity_input_row/3` facade used by normalization. Shared
stable-ID validation, integrity-issue construction, and map compaction are
supplied as callbacks.

Why this slice:
The extraction moved three clauses into a 60-line internal module and reduced
Timeline from 7,663 to 7,619 lines. The one private facade preserves both
normalization callers and the complete review/integrity artifact shape.

Completed proof:
- Focused invalid-activity examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,724 files.
- Canonical AST equivalence: all three moved clauses after normalizing only the
  facade name and three callback boundaries.
- Format, whitespace, ownership, exactly-one-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline invalid-activity row extraction, selected in `e586b0f5` and
implemented in `9ee57bb5`.

Next candidate:
Remap the reduced 7,619-line Timeline facade, emphasizing transition integrity
gating and invalid-activity validation.

Blocked:
No.
