# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common count-map primitive direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the zero-context, one-hop CommonJsonSchema non-negative integer
count-map helper. Route its eleven eager and lazy consumers directly to
`CommonJsonSchema.non_negative_integer_count_map/0`. Keep enum count maps,
string arrays, stable-ID helpers, context-bearing helpers, schema composition,
executable validation, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 5,989 lines.
- The helper calls the same-arity zero-context CommonJsonSchema API and adds no
  facade state, guards, defaults, transformation, or caching.
- Its eager consumers and lazy callbacks can route directly with
  unchanged evaluation behavior.
- Direct call/capture counting confirms eleven consumers.
- Exact count-map schemas, callback timing, composed JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Removed the CommonJsonSchema non-negative integer count-map helper and routed
all eleven consumers directly to the owner module. `schema.ex` moved from
5,989 to 5,986 lines after direct calls and captures were formatted.

Verification:
- Strict focused timeline/communications/feedback/strategy/operational
  baseline before routing: 40 passed.
- The same strict focused suite after routing: 40 passed.
- Strict full JSON Schema export-contract, communications fixtures,
  candidate-refresh schema, and checked-in export coverage: 32 passed.
- The full schema-export task completed and produced no checked-in changes.
- `mix xref callers OrbitalDynamics.Schema.CommonJsonSchema` reports the
  expected facade and internal schema-owner consumers.
- Definition/reference-specific static search confirms the helper and all
  indirect references are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `132941cb` pushed to `main`.

Behavior/schema changes:
None. Public facades, count-map schemas, eager and lazy evaluation behavior,
composed schemas, executable validation, and checked-in exports remain
unchanged.

Last completed slice:
Schema common count-map primitive direct routing, selected in `96fd7f7d` and
implemented in `132941cb`.
`schema.ex` moved from 5,989 to 5,986 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
