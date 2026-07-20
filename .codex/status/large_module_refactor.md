# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-source validation routing cleanup.

Status:
Selected; implementation not started.

Selected boundary:
Complete the existing `OrbitalDynamics.Schema.TimelineSourceValidation`
extraction by routing callback tables directly to that owner and removing
eight facade pass-through wrappers.
Preserve all `OrbitalDynamics.Schema` public facades and validation output.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,694 lines.
- Timeline-source validation logic already has a focused owner, but the facade
  retains eight one-hop wrappers referenced by campaign, Cadence import,
  source-review, and operator-review callback tables.
- The selected code has one responsibility: route optional timeline diff,
  dependency, precondition, integrity, preservation, lifecycle, and activity
  source validation to the existing owner.
- Callback-table composition, timeline transition/context validation, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact issue ordering, paths, messages, required-field behavior, callback
  wiring, public validation results, and schema exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema operational-readiness validation routing cleanup, selected in
`e662f676` and implemented in `5a7e2b98`.
`schema.ex` moved from 6,764 to 6,694 lines by completing routing to the
existing OperationalReadinessValidation owner.

Next candidate:
After this slice, continue with the separate timeline-transition or
timeline-context routing wrapper clusters.

Blocked:
No.
