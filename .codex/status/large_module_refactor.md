# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-contention capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the contact-contention model-limit projection and report-assumptions
builder into `OrbitalDynamics.Schema.ContactContentionCapabilityContext`.
Import those two focused internal APIs into the Schema facade.
Keep contact-contention schema construction, property dispatch, validation
routing, and public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,189 lines.
- The two private helpers form the complete schema-facing capability boundary
  for ContactContention: one atom-to-string model-limit projection and one
  report-assumptions assembly from the same capabilities map.
- The selected code has one responsibility: expose schema-facing
  ContactContention capability context for report schema composition.
- Importing both APIs preserves the existing unqualified call sites and
  evaluation order. ContactContention schema construction, property dispatch,
  validators, and other communications families remain outside the boundary.
- Exact atom-to-string conversion, capability values and ordering, generated
  JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema contact-intent capability-context extraction, selected in `4b180837`
and implemented in `c71107c0`.
`schema.ex` moved from 6,201 to 6,189 lines; the dedicated
ContactIntentCapabilityContext owner is 21 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
