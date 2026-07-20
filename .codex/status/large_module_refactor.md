# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-intent capability-context extraction.

Status:
Completed and pushed.

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
Added `OrbitalDynamics.Schema.ContactIntentCapabilityContext`, which now owns
the sorted ContactIntent model-limit projection and summary-assumptions
assembly. `OrbitalDynamics.Schema` imports only those two focused APIs.
`schema.ex` moved from 6,201 to 6,189 lines; the dedicated owner is 21 lines.

Verification:
- Strict focused communications/feedback/export baseline before extraction:
  28 passed.
- The same strict focused suite after extraction: 28 passed.
- Strict full schema-export/lint tasks plus adjacent Cadence-row, campaign-plan,
  and campaign-repair contract coverage: 17 passed.
- `mix xref callers OrbitalDynamics.Schema.ContactIntentCapabilityContext`
  reports only `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,056 files.
- Implementation commit `c71107c0` pushed to `main`.

Behavior/schema changes:
None. Public facades, model-limit conversion and sorting, assumption ordering,
generated JSON Schema, validation behavior, and checked-in exports remain
unchanged.

Last completed slice:
Schema contact-intent capability-context extraction, selected in `4b180837`
and implemented in `c71107c0`.
`schema.ex` moved from 6,201 to 6,189 lines; the dedicated
ContactIntentCapabilityContext owner is 21 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
