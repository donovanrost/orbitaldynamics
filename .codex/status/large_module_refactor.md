# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-timing policy extraction.

Status:
Implementation published in `da906de9`; focused and broad proof is green.

Selected boundary:
Move activity start, end, explicit duration, and derived duration selection into
`Timeline.ActivityTimingPolicy`. `Timeline` retains three private entry points.
The boundary has no callbacks, module attributes, or shared vocabulary
arguments.

Why this slice:
The extraction moved four clauses into a 20-line internal module and reduced
Timeline from 6,609 to 6,603 lines. Three private entry points preserve row,
context, throughput, uncertainty, and transition callers while moving
canonical/alternate endpoint precedence and explicit/derived duration selection
out of the facade.

Completed proof:
- Focused timing, throughput, transition, and diff examples: 5 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,745 files.
- Canonical AST equivalence: all four moved clauses after normalizing only
  the three facade names.
- Format, whitespace, ownership, exactly-three-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-timing policy extraction, selected in `b81cc29b` and
implemented in `da906de9`.

Next candidate:
Remap the reduced 6,603-line Timeline facade, avoiding boundaries whose guard
vocabularies remain shared with Timeline.

Blocked:
No.
