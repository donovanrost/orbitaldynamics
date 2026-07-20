# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema handoff leaf-property direct routing.

Status:
Completed and pushed.

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
Removed the two handoff leaf-property helpers and routed all six callbacks
directly to their existing owner modules. `schema.ex` moved from 6,039 to
6,031 lines.

Verification:
- Strict focused Cadence import/review/handoff baseline before routing:
  10 passed.
- The same strict focused suite after routing: 10 passed.
- Strict full JSON Schema export-contract, candidate-refresh schema, and
  operational schema coverage: 33 passed.
- The full schema-export task completed and produced no checked-in changes.
- `mix xref callers` for CommandAuthorityHandoffJsonSchema and
  ResourceAvailabilityVarianceJsonSchema reports only the expected facade
  consumer.
- Definition/capture-specific static search confirms both helpers and all six
  indirect captures are gone; provider-map key names remain unchanged.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `df84fb51` pushed to `main`.

Behavior/schema changes:
None. Public facades, provider-map keys, callback timing, composed schemas,
executable validation, and checked-in exports remain unchanged.

Last completed slice:
Schema handoff leaf-property direct routing, selected in `fcc99445` and
implemented in `df84fb51`.
`schema.ex` moved from 6,039 to 6,031 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
