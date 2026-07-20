# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common number-or-string primitive direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the zero-context, one-hop CommonJsonSchema number-or-string helper.
Route its ten eager and lazy consumers directly to
`CommonJsonSchema.number_or_string/0`. Keep array, probability, count-map, and
context-bearing helpers, schema composition, executable validation, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,001 lines.
- The helper calls the same-arity zero-context CommonJsonSchema API and adds no
  facade state, guards, defaults, transformation, or caching.
- Its eager consumers and lazy callbacks can route directly with
  unchanged evaluation behavior.
- Exact number-or-string schemas, callback timing, composed JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Removed the CommonJsonSchema number-or-string helper and routed all ten
consumers directly to the owner module. `schema.ex` moved from 6,001 to 5,997
lines after direct calls and captures were formatted.

Verification:
- Strict focused feedback/strategy/Cadence/review baseline before routing:
  13 passed.
- The same strict focused suite after routing: 13 passed.
- Strict full JSON Schema export-contract, timeline-report, operational
  timeline, and checked-in export coverage: 28 passed.
- The full schema-export task completed and produced no checked-in changes.
- `mix xref callers OrbitalDynamics.Schema.CommonJsonSchema` reports the
  expected facade and internal schema-owner consumers.
- Definition/reference-specific static search confirms the helper and all
  indirect references are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `80b48d2c` pushed to `main`.

Behavior/schema changes:
None. Public facades, number-or-string schemas, eager and lazy evaluation
behavior, composed schemas, executable validation, and checked-in exports
remain unchanged.

Last completed slice:
Schema common number-or-string primitive direct routing, selected in
`dcde91be` and implemented in `80b48d2c`.
`schema.ex` moved from 6,001 to 5,997 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
