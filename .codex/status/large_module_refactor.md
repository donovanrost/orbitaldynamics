# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema command-window capability-context extraction.

Status:
Completed and pushed.

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
Added `OrbitalDynamics.Schema.CommandWindowCapabilityContext`, which now owns
the capability-derived command-window report model-limit projection.
`OrbitalDynamics.Schema` imports that single focused API for property dispatch
and executable validation.
`schema.ex` moved from 6,181 to 6,178 lines; the dedicated owner is 9 lines.

Verification:
- Strict focused command-window/export/default-message baseline before
  extraction: 25 passed.
- The same strict focused suite after extraction: 25 passed.
- Strict full schema-export task plus adjacent Cadence-import,
  operator-review, timeline-activity, and timeline-summary coverage: 33 passed.
- `mix xref callers
  OrbitalDynamics.Schema.CommandWindowCapabilityContext` reports only
  `lib/orbital_dynamics/schema.ex (export)`.
- A direct domain `capability/capabilities` scan now returns no matches in
  `schema.ex`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `db23798a` pushed to `main`.

Behavior/schema changes:
None. Public facades, model-limit values and ordering, generated JSON Schema,
validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema command-window capability-context extraction, selected in `63633755`
and implemented in `db23798a`.
`schema.ex` moved from 6,181 to 6,178 lines; the dedicated
CommandWindowCapabilityContext owner is 9 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
