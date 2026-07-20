# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema low-fanout common primitive direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove five zero-context, one-hop CommonJsonSchema helpers for
number-or-number-array, probability maps, string-value maps, string-list maps,
and nested-object maps. Route their eight low-fanout consumers directly to the
same owner APIs. Keep higher-fanout common primitives, context-bearing helpers,
schema composition, executable validation, and all public facades in
`OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,024 lines.
- All five helpers call same-arity zero-context CommonJsonSchema APIs and add no
  facade state, guards, defaults, transformation, or caching.
- The six eager consumers and two lazy callbacks can route directly with
  unchanged evaluation behavior.
- Exact primitive schemas, callback timing, composed JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema Cadence import status direct routing, selected in `56b6601b` and
implemented in `310f440a`.
`schema.ex` moved from 6,027 to 6,024 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
