# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema filter suppression-capability routing.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema validation capability-context extraction, selected in `1b7b8b2e` and
implemented in `739e27fc`.
`schema.ex` moved from 6,189 to 6,187 lines; the dedicated
ValidationCapabilityContext owner is 20 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
