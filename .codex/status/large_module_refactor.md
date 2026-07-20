# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-intent capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the contact-intent model-limit projection and summary-assumptions
builder into `OrbitalDynamics.Schema.ContactIntentCapabilityContext`.
Import those two focused internal APIs into the Schema facade.
Keep contact-intent schema construction, property dispatch, validation
routing, and public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,201 lines.
- The two private helpers form the complete schema-facing capability boundary
  for ContactIntent: one sorted atom-to-string model-limit projection and one
  assumptions assembly from ContactIntentSummaryContracts.
- The selected code has one responsibility: expose schema-facing
  ContactIntent capability context for report and summary schema composition.
- Importing both APIs preserves the four existing unqualified call sites and
  evaluation order. ContactIntent schema construction, property dispatch,
  validators, and other communications families remain outside the boundary.
- Exact atom-to-string conversion and sorting, assumption values and ordering,
  generated JSON Schema, validation results, and checked-in exports must
  remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema contact-allocation capability-context extraction, selected in
`906526ce` and implemented in `4e12f391`.
`schema.ex` moved from 6,326 to 6,201 lines; the dedicated
ContactAllocationCapabilityContext owner is 138 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
