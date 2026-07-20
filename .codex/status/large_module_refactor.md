# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-reservation owner routing extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add a registry-backed `StationReservationValidation.validate_artifact/4` entry
point for the reservation report, review summary, hold summary, and hold
import-readiness summary. Derive requirements from
`StationReservationRegistryContracts` and
`StationReservationHoldRegistryContracts`, route all four direct `Schema`
clauses, and preserve every existing owner API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,803 lines; the other
  targeted public facades are now 164 to 524 lines.
- The four clauses repeat required-field setup and form the exact two registry
  families already operationally owned by `StationReservationValidation`.
- The owner already owns summary model limits; report models are available
  directly from `StationReservationReportJsonSchema`.
- No route needs recursive `Schema` lookup.
- Station-calendar provider, report, and precedence artifacts remain separate
  because they belong to distinct registry/context boundaries.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `StationReservationValidation` APIs, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema resource planning/filter owner routing extraction, selected in
`63dde824` and implemented in `98e0f95a`.
`schema.ex` moved from 4,817 to 4,803 lines.

Next candidate:
Implement and verify the selected station-reservation owner routing, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.
