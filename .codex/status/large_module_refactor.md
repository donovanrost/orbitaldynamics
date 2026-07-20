# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common number-array primitive direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the zero-context, one-hop CommonJsonSchema number-array helper. Route
its nine eager and lazy consumers directly to
`CommonJsonSchema.number_array/0`. Keep string-array, probability, count-map,
and context-bearing helpers, schema composition, executable validation, and
all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 5,997 lines.
- The helper calls the same-arity zero-context CommonJsonSchema API and adds no
  facade state, guards, defaults, transformation, or caching.
- Its eager consumers and lazy callbacks can route directly with
  unchanged evaluation behavior.
- Exact-name counting confirms nine consumers; two earlier substring matches
  were the distinct number-or-number-array provider key.
- Exact number-array schemas, callback timing, composed JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Removed the CommonJsonSchema number-array helper and routed all nine consumers
directly to the owner module. `schema.ex` moved from 5,997 to 5,993 lines after
direct calls and captures were formatted.

Verification:
- Strict focused communications/feedback/strategy/Cadence/review baseline
  before routing: 21 passed.
- The same strict focused suite after routing: 21 passed.
- Strict full JSON Schema export-contract, communications fixtures, handoff,
  and checked-in export coverage: 26 passed.
- The full schema-export task completed and produced no checked-in changes.
- `mix xref callers OrbitalDynamics.Schema.CommonJsonSchema` reports the
  expected facade and internal schema-owner consumers.
- Definition/reference-specific static search confirms the helper and all
  indirect references are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `3f6643ad` pushed to `main`.

Behavior/schema changes:
None. Public facades, number-array schemas, eager and lazy evaluation behavior,
composed schemas, executable validation, and checked-in exports remain
unchanged.

Last completed slice:
Schema common number-array primitive direct routing, selected in `dc5a34f8`,
boundary count corrected in `46c496f2`, and implemented in `3f6643ad`.
`schema.ex` moved from 5,997 to 5,993 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
