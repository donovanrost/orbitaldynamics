# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline execution-uncertainty context extraction.

Status:
Implementation published in `b2b15284`; handoff publication pending.

Completed boundary:
`Timeline.ExecutionUncertaintyContext.build/2` now owns all six uncertainty
source paths, declared/missing relevance, scalar and triplet normalization,
the exact uncertainty projection, magnitude derivation, and source/model
selection. `Timeline` retains every public function and five shared helpers
behind callbacks. The facade dropped from 9,343 to 9,269 lines.

Selection:
Selected and published in `88add146`. Shared numeric, triplet, and vector
helpers remain in Timeline for station-calendar and other context ownership.

Verification:
- Pre-change and post-change focused Timeline cases: 3/3.
- Full Timeline suite: 127/127.
- Timeline schema-contract suites: 36/36.
- Strict warnings-as-errors compile: 3,713 files.
- Canonical AST equivalence: exact builder and all eight moved clauses after
  normalizing only callback boundaries.
- Public-definition hash unchanged; format, diff, whitespace, ownership,
  caller, and xref checks clean; xref reports only Timeline.
- Independent review: no code findings. Lookup precedence, malformed-value
  blocking, map selection, stringify timing, relevance, scalar/triplet
  normalization, magnitude derivation, source precedence, callbacks,
  consumers, API, schema shape, and determinism are exact.

Behavior/schema changes:
None. No schema-generation boundary changed, so export regeneration was not
required.

Last completed slice:
Timeline execution-uncertainty context extraction, published in `b2b15284`.

Next candidate:
Remap the reduced Timeline facade; command-window context is the leading
smaller candidate.

Blocked:
No.
