# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common numeric-map primitive direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the two zero-context, one-hop CommonJsonSchema helpers for unconstrained
and non-negative numeric maps. Route their twelve consumers directly to the
same owner APIs. Keep count maps, higher-fanout array/scalar primitives,
context-bearing helpers, schema composition, executable validation, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,006 lines.
- Both helpers call same-arity zero-context CommonJsonSchema APIs and add no
  facade state, guards, defaults, transformation, or caching.
- Their eager consumers and lazy callbacks can route directly with
  unchanged evaluation behavior.
- Exact numeric-map schemas, callback timing, composed JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Removed the two CommonJsonSchema numeric-map helpers and routed all twelve
consumers directly to the owner module. `schema.ex` moved from 6,006 to 6,001
lines after direct captures were formatted.

Verification:
- Strict focused policy/resource/strategy/Cadence/review baseline before
  routing: 15 passed.
- The same strict focused suite after routing: 15 passed.
- Strict full JSON Schema export-contract, contact-feedback, handoff, and
  checked-in export coverage: 27 passed.
- The full schema-export task completed and produced no checked-in changes.
- `mix xref callers OrbitalDynamics.Schema.CommonJsonSchema` reports the
  expected facade and internal schema-owner consumers.
- Definition/reference-specific static search confirms both helpers and all
  indirect references are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `6fa1f6a9` pushed to `main`.

Behavior/schema changes:
None. Public facades, numeric-map schemas, eager and lazy evaluation behavior,
composed schemas, executable validation, and checked-in exports remain
unchanged.

Last completed slice:
Schema common numeric-map primitive direct routing, selected in `32ff8955` and
implemented in `6fa1f6a9`.
`schema.ex` moved from 6,006 to 6,001 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
