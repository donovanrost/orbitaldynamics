# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation owner routing extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add registry-backed owner-default entry points to `ContactAllocationValidation`
for the allocation report, base summary, reservation-conflict summary,
station-pressure summary, capacity-pack summary, and provider-reservation
request summary. Derive requirements from their six registry modules, route all
six direct `Schema` clauses, and preserve every existing owner API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,795 lines; the other
  targeted public facades are now 164 to 524 lines.
- The six adjacent clauses repeat required-field setup and already delegate
  artifact-specific validation to `ContactAllocationValidation`.
- Their six registry modules own every required field.
- The owner already owns allocation model limits and every nested report,
  row, capacity-pack, calendar, filter, and contention callback.
- No route needs recursive `Schema` lookup.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `ContactAllocationValidation` APIs, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema station-reservation owner routing extraction, selected in `c1049e27`
and implemented in `5f3c7f1b`.
`schema.ex` moved from 4,803 to 4,795 lines.

Next candidate:
Implement and verify the selected contact-allocation owner routing, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.
