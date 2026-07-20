# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema handoff leaf-property direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the two zero-context, one-hop property helpers for command-authority
handoffs and resource-availability variance. Route the six callbacks in the
three Cadence row-provider contexts directly to the existing
CommandAuthorityHandoffJsonSchema and
ResourceAvailabilityVarianceJsonSchema owner APIs. Keep provider-map
construction, all other handoff property builders, executable validation, and
all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,039 lines.
- Both helpers call zero-arity owner APIs and add no facade state, guards,
  defaults, transformation, or caching.
- All six consumers are lazy callbacks in three parallel Cadence row-provider
  contexts and can capture the owners directly.
- Exact property maps, callback timing, composed JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema validation leaf-schema direct routing, selected in `47e7ed05`, boundary
count corrected in `fb47f7a9`, and implemented in `6a23e82b`.
`schema.ex` moved from 6,061 to 6,039 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
