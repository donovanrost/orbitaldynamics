# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence import status direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the zero-context, one-hop Cadence import status helper. Route the
Cadence manifest row schema-provider callback directly to
`CadenceImportOperationalReadinessJsonSchema.status/0`. Keep provider-map
construction, row composition, executable validation, and all public facades
in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,027 lines.
- The helper calls the same zero-arity Cadence import readiness owner API and
  adds no facade state, guards, defaults, transformation, or caching.
- Its only consumer can capture the owner directly with unchanged lazy
  evaluation.
- Exact status values, callback timing, manifest row JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema policy rule-match field-group direct routing, selected in `e2bd180e`
and implemented in `7c7a7079`.
`schema.ex` moved from 6,031 to 6,027 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
