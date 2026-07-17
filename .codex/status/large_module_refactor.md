# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline callback ownership cleanup.

Status:
Selected; implementation pending.

Selected slice:
Point timeline-diff, transition-application, operational-timeline, and cadence
publication/dependency/precondition/lifecycle/preservation callbacks directly
at `Schema.TimelineHandoffContracts`. Remove the eleven facade delegates across
seventeen callback positions. Leave the earlier publication-summary pipeline
helpers unchanged.

Why this slice:
The three general families each appear in three callback bags and have one
cadence callback; five additional cadence-only families appear once. All eleven
facade functions are pure one-hop delegates, while the owner already retains
specialized/fallback clauses and field traversal. Excluding the publication
summary helpers keeps direct pipeline retargeting separate.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All seventeen selected captures point directly to `TimelineHandoffContracts`,
the eleven facade delegates are gone, the publication-summary helpers remain
unchanged, and callback plus field traversal issue ordering remains exact,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

Behavior/schema changes:
None.

Last completed slice:
Schema source-review callback ownership cleanup published as `c0ec315b`: three
refresh-budget source captures and nine cadence callbacks now point directly to
their owner; 182 schema/export tests passed, full export bytes stayed exact,
and bounded review was clean.

Next candidate:
Audit `TimelineHandoffContracts` in two boundaries. First map the eleven
diff/transition/publication/dependency/precondition/lifecycle/preservation/
operational-timeline callback delegates and their capture counts. Keep the two
earlier publication-summary helper wrappers separate until their direct
pipeline consumers are proven safe to retarget.

Blocked:
No.
