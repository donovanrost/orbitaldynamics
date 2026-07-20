# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common probability primitive direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the zero-context, one-hop CommonJsonSchema probability helper. Route
its twelve eager and lazy consumers directly to
`CommonJsonSchema.probability/0`. Keep string-array, count-map, and
context-bearing helpers, schema composition, executable validation, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 5,993 lines.
- The helper calls the same-arity zero-context CommonJsonSchema API and adds no
  facade state, guards, defaults, transformation, or caching.
- Its eager consumers and lazy callbacks can route directly with
  unchanged evaluation behavior.
- Consumer counting confirms twelve routes; three provider-map lines contain
  the identifier twice as both stable key and callback value.
- Exact probability schemas, callback timing, composed JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Removed the CommonJsonSchema probability helper and routed all twelve
consumers directly to the owner module. `schema.ex` moved from 5,993 to 5,989
lines after direct calls and captures were formatted.

Verification:
- Strict focused communications/candidate/feedback/strategy/Cadence/review
  baseline before routing: 31 passed.
- The same strict focused suite after routing: 31 passed.
- Strict full JSON Schema export-contract, communications fixtures, handoff,
  and checked-in export coverage: 26 passed.
- The full schema-export task completed and produced no checked-in changes.
- `mix xref callers OrbitalDynamics.Schema.CommonJsonSchema` reports the
  expected facade and internal schema-owner consumers.
- Definition/reference-specific static search confirms the helper and all
  indirect references are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `8237cb9a` pushed to `main`.

Behavior/schema changes:
None. Public facades, probability schemas, eager and lazy evaluation behavior,
composed schemas, executable validation, and checked-in exports remain
unchanged.

Last completed slice:
Schema common probability primitive direct routing, selected in `19648e06`,
boundary count corrected in `7513b2bc`, and implemented in `8237cb9a`.
`schema.ex` moved from 5,993 to 5,989 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
