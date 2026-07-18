# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline station-calendar context extraction.

Status:
Implementation published in `8d9d6b74`; handoff publication pending.

Completed boundary:
`Timeline.StationCalendarContext.build/2` now owns the exact 22-field
projection, nested overlap expiration aggregation, numeric list
normalization, direction aliases, nested entry-ID flattening, and stable
calendar ID-list cleanup. `Timeline` retains every public function and five
shared helpers behind callbacks. The facade dropped from 9,556 to 9,343 lines.

Selection:
Selected and published in `a717e790`. Shared numeric parsing and vector math
remain in Timeline with execution-uncertainty ownership.

Verification:
- Pre-change and post-change focused Timeline cases: 5/5.
- Full Timeline suite: 127/127.
- Timeline schema-contract suites: 36/36.
- Strict warnings-as-errors compile: 3,712 files.
- Canonical AST equivalence: exact builder and all 18 moved clauses after
  normalizing only callback boundaries.
- Public-definition hash unchanged; format, diff, whitespace, ownership,
  caller, and xref checks clean; xref reports only Timeline.
- Independent review: no code findings. Projection order, expiration
  aggregation, number coercion/deduplication/sorting, direction aliases,
  entry-ID precedence, malformed/stable ID handling, callbacks, consumers,
  API, schema behavior, and determinism are exact.

Behavior/schema changes:
None. No schema-generation boundary changed, so export regeneration was not
required.

Last completed slice:
Timeline station-calendar context extraction, published in `8d9d6b74`.

Next candidate:
Remap the reduced Timeline facade; execution-uncertainty context is the leading
smaller candidate.

Blocked:
No.
