# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-application policy extraction.

Status:
Implementation published in `4c8c2d03`; focused and broad proof is green.

Selected boundary:
Move the complete transition-application selection and provenance construction
cluster into `Timeline.TransitionApplicationPolicy`: seven selection clauses,
selected-activity provenance carry-forward, provenance construction, and
no-change reason policy. `Timeline` retains two private facade entry points for
selection and provenance attachment. The shared `compact_map/1` behavior is
supplied as one callback.

Why this slice:
The extraction moved 13 clauses into a 96-line internal module and reduced
Timeline from 7,930 to 7,852 lines. The two facade entry points preserve all
current single, batch, lifecycle, and integrity-gating callers.

Completed proof:
- Focused transition-application examples: 4 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,719 files.
- Canonical AST equivalence: all 13 moved clauses after normalizing only facade
  names and the `compact_map/1` callback boundary.
- Format, whitespace, ownership, exactly-two-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline transition-application policy extraction, selected in `88e2b690` and
implemented in `4c8c2d03`.

Next candidate:
Remap the reduced 7,852-line Timeline facade, emphasizing operational action
classification and lifecycle-state decision policy.

Blocked:
No.
