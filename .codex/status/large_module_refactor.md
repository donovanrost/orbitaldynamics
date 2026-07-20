# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-contention capability-context extraction.

Status:
Completed and pushed.

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
Added `OrbitalDynamics.Schema.ContactContentionCapabilityContext`, which now
owns the ContactContention model-limit projection and report-assumptions
assembly. `OrbitalDynamics.Schema` imports only those two focused APIs.
`schema.ex` moved from 6,189 to 6,183 lines; the dedicated owner is 15 lines.

Verification:
- Strict focused communications/default-message/export/registry baseline
  before extraction: 37 passed.
- The same strict focused suite after extraction: 37 passed.
- Strict full schema-export task plus adjacent Cadence-import,
  candidate-refresh provenance, fixture-visibility, and operator-review
  coverage: 9 passed.
- `mix xref callers
  OrbitalDynamics.Schema.ContactContentionCapabilityContext` reports only
  `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,057 files.
- Implementation commit `b0025203` pushed to `main`.

Behavior/schema changes:
None. Public facades, model-limit conversion, capability and assumption
ordering, generated JSON Schema, validation behavior, and checked-in exports
remain unchanged.

Last completed slice:
Schema contact-contention capability-context extraction, selected in
`81ef520e` and implemented in `b0025203`.
`schema.ex` moved from 6,189 to 6,183 lines; the dedicated
ContactContentionCapabilityContext owner is 15 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
