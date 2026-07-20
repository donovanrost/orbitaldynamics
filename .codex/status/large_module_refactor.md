# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema filter suppression-capability routing.

Status:
Completed and pushed.

Selected boundary:
Route suppressed-candidate reason aggregation through the existing
`ContactFilterCapabilityContext.contact_filter_suppression_reasons/0` and
`ResourceFilterCapabilityContext.resource_filter_suppression_reasons/0`
owners instead of querying both domain capabilities directly.
Keep the cross-family merge, deduplication, sorting, suppressed-candidate
schema construction, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,187 lines.
- The facade's suppressed-candidate helper is the only remaining direct
  ContactFilter/ResourceFilter capability coupling, even though both dedicated
  owners already expose the exact suppression-reason values.
- Importing those two focused APIs completes capability ownership for these
  filter families without moving the cross-family composition responsibility.
- Exact concatenation, `Enum.uniq/1`, `Enum.sort/1`, generated JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Imported the existing ContactFilter and ResourceFilter suppression-reason APIs
into the Schema facade and routed suppressed-candidate aggregation through
them. The cross-family concatenation, deduplication, and sorting remain in the
facade.
`schema.ex` moved from 6,187 to 6,188 lines because the two explicit imports
replace two shorter direct capability expressions.

Verification:
- Strict focused filter/candidate-refresh/export/default-message baseline
  before routing: 35 passed.
- The same strict focused suite after routing: 35 passed.
- Strict full schema-export task plus adjacent candidate-refresh provenance,
  fixture-visibility, and communications coverage: 11 passed.
- `mix xref callers` for both existing capability-context owners reports only
  `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,062 files.
- Implementation commit `f659fc87` pushed to `main`.

Behavior/schema changes:
None. Public facades, concatenation/deduplication/sorting order, generated JSON
Schema, validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema filter suppression-capability routing, selected in `e2eb0cfb` and
implemented in `f659fc87`.
`schema.ex` moved from 6,187 to 6,188 lines and no longer directly queries
ContactFilter or ResourceFilter capabilities.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
