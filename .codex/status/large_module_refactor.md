# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline command-window context extraction.

Status:
Implementation published in `4658c14f`; handoff publication pending.

Completed boundary:
`Timeline.CommandWindowContext.build/2` now owns the private activity-type
constant, exact two-key projection, relevance predicates, explicit/nested/
metadata ID and type precedence, ID inference, and ordered type inference.
`Timeline` retains every public function and two shared helpers behind
callbacks. The facade dropped from 9,269 to 9,223 lines.

Selection:
Selected and published in `d9f4a2e0` as a compact clean seam before the larger
precondition and transition regions.

Verification:
- Pre-change and post-change focused Timeline cases: 3/3.
- Full Timeline suite: 127/127.
- Timeline schema-contract suites: 36/36.
- Strict warnings-as-errors compile: 3,714 files.
- Private activity-type constant exact; canonical AST equivalence across all
  12 moved clauses after normalizing only callback boundaries.
- Public-definition hash unchanged; format, diff, whitespace, ownership,
  caller, and xref checks clean; xref reports only Timeline.
- Independent review: no code findings. Relevance ordering, ID precedence and
  empty-ID behavior, type precedence and inference, callbacks, consumers, API,
  schema shape, ownership, and determinism are exact.

Behavior/schema changes:
None. No schema-generation boundary changed, so export regeneration was not
required.

Last completed slice:
Timeline command-window context extraction, published in `4658c14f`.

Next candidate:
Remap the reduced Timeline facade, emphasizing the larger
activity-precondition and transition-integrity regions.

Blocked:
No.
