# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence import status direct routing.

Status:
Completed and pushed.

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
Removed the Cadence import status helper and routed its provider callback
directly to CadenceImportOperationalReadinessJsonSchema. `schema.ex` moved
from 6,027 to 6,024 lines.

Verification:
- Strict focused Cadence import/handoff/export baseline before routing:
  23 passed.
- The same strict focused suite after routing: 23 passed.
- Strict checked-in export, operator-review schema, and operational schema
  coverage: 13 passed.
- The full schema-export task completed and produced no checked-in changes.
- `mix xref callers` for
  CadenceImportOperationalReadinessJsonSchema reports the expected `schema.ex`
  and OperationalReadinessContextJsonSchema consumers.
- Definition/capture-specific static search confirms the helper and indirect
  callback are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `310f440a` pushed to `main`.

Behavior/schema changes:
None. Public facades, provider-map keys, callback timing, status values,
composed schemas, executable validation, and checked-in exports remain
unchanged.

Last completed slice:
Schema Cadence import status direct routing, selected in `56b6601b` and
implemented in `310f440a`.
`schema.ex` moved from 6,027 to 6,024 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
