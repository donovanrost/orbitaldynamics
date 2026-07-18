# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline throughput-context extraction.

Status:
Implementation published in `545b4848`; handoff publication pending.

Completed boundary:
`Timeline.ThroughputContext.build/2` now owns the exact five-key throughput
projection, planned and actual aliases, declared-versus-derived selection,
MB/s and Mbps derivations, and duration aliases. `Timeline` retains every
public function and six shared helpers behind callbacks. The facade dropped
from 9,657 to 9,556 lines.

Selection:
Selected and published in `2da59a60` after the live hotspot refresh showed
Timeline was the largest cohesive implementation hotspot outside the
callback-heavy Schema facade.

Verification:
- Pre-change focused baseline: 4/4.
- Post-change focused tests: 4/4; full Timeline suite: 127/127.
- Timeline schema-contract suites: 36/36.
- Strict warnings-as-errors compile: 3,711 files.
- Canonical AST equivalence: exact five-key builder and all 11 moved clauses
  after normalizing only callback boundaries.
- Public-definition hash unchanged; format, diff, whitespace, ownership,
  caller, and xref checks clean; xref reports only Timeline.
- Independent review: no code findings. Alias precedence, declared and
  explicit actual selection, conversions, nil/zero semantics, callbacks,
  consumers, API, schema shape, compaction, and determinism are exact.

Behavior/schema changes:
None. No schema-generation boundary changed, so export regeneration was not
required.

Last completed slice:
Timeline throughput-context extraction, published in `545b4848`.

Next candidate:
Remap the reduced Timeline facade; link-context is adjacent and cohesive, while
station-calendar context remains a larger alternative.

Blocked:
No.
