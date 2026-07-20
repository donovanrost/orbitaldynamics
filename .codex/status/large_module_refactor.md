# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema command-window capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the capability-derived command-window report model-limit projection
into `OrbitalDynamics.Schema.CommandWindowCapabilityContext`.
Import that focused internal API into the Schema facade.
Keep command-window schema construction, property dispatch, report validation,
and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,181 lines.
- The private projection converts CommandWindow capability atoms to strings
  and feeds both report property dispatch and executable validation.
- This is the last direct domain `capabilities/0` read remaining in the Schema
  facade.
- Importing the focused API preserves existing callback captures and
  validation calls while leaving both consumers in their current owners.
- Exact model-limit values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema policy capability-context extraction, selected in `4573312c` and
implemented in `acf2057b`.
`schema.ex` moved from 6,184 to 6,181 lines; the dedicated
PolicyCapabilityContext owner is 9 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
