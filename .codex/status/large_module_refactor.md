# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-orientation context extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved pointing and attitude context-map construction into the 68-line
`Timeline.ActivityOrientationContext`. The 5,623-line Timeline retains two
private context facades and passes its stable-ID pattern as data. The shared
`first_stable_identifier/2` facade was removed after strict compile proved the
moved builders owned its only remaining callers.

Published commits:
Initially selected in `2179a76d`, corrected in `46dbabb9` after strict compile
identified the dead shared facade, and implemented in `65316388`.

Verification:
- Strict warnings-as-errors compile passed across 3,791 files after removing
  the dead facade.
- Three focused combined-orientation, first-class-attitude, and numeric-string
  examples passed before and after extraction.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for both builders after normalizing only
  public names, stable-pattern data parameters, and definition kind.
- Format, diff, exactly-two-facade, dead-helper-removal, three-consumer,
  unchanged public definitions, sole-consumer, and xref checks passed.
- Independent review found no production issues and confirmed exact fields,
  aliases, ordering, stable validation, adapters, consumers, and neighbor
  isolation.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-orientation context extraction, initially selected in
`2179a76d`, corrected in `46dbabb9`, and implemented in `65316388`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
