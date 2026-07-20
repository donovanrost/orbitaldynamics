# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema link-capacity validation routing.

Status:
Selected; implementation pending.

Selected boundary:
Add a small LinkCapacityValidation owner for registry-required report
validation and optional report shape handling. Route the direct Schema report
consumer and both campaign callback consumers to that owner, and remove the
facade-local optional closure. Keep the 910-line LinkCapacityReportContracts
module focused on artifact-specific validation rather than adding orchestration
to that existing hotspot.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,202 lines; the other
  targeted public facades are now 164 to 524 lines.
- Exact usage finds one direct report validation and two campaign optional
  callbacks behind one facade-local closure.
- LinkCapacityRegistryContracts owns the required-field list and
  LinkCapacityReportContracts owns all artifact-specific validation.
- Optional shape handling requires only PrimitiveValidation.error/2.
- No callback needs recursive Schema lookup or another facade-local validator.
- A separate owner avoids adding context orchestration to the already
  910-line report contract module.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public Schema
APIs, validation results, and checked-in exports must remain unchanged.

Last completed slice:
Schema decision-support registered-contract validation routing, selected in
`8da19f67` and implemented in `0d29fbd9`.
`schema.ex` moved from 5,294 to 5,202 lines.

Next candidate:
Implement and verify the selected link-capacity validation routing, then
re-evaluate campaign plan/repair callback ownership.

Blocked:
No.
