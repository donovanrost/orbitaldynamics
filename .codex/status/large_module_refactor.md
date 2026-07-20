# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-context validation routing cleanup.

Status:
Selected; implementation not started.

Selected boundary:
Complete the existing `OrbitalDynamics.Schema.TimelineContextValidation`
extraction by routing callback tables directly to that owner and removing
nine facade pass-through clauses.
Preserve all `OrbitalDynamics.Schema` public facades and validation/error
behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,640 lines.
- Timeline-context validation logic already has a focused owner, but the facade
  retains one-hop wrappers referenced by operational timeline, transition,
  campaign, Cadence import, source-review, and operator-review callbacks.
- The selected code has one responsibility: route optional precondition,
  activity, protection, lifecycle, identity, link, and protection-summary
  context validation to the existing owner.
- Preserve the facade wrappers' map-only function-clause behavior by moving
  those guards to the owner before exposing it directly to callback tables.
- Callback-table composition, timeline transition/source validation, other
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
Schema timeline-source validation routing cleanup, selected in `812776d1` and
implemented in `a60fc5ee`.
`schema.ex` moved from 6,694 to 6,640 lines by completing routing to the
existing TimelineSourceValidation owner.

Next candidate:
After this slice, re-rank the remaining schema wrapper clusters. Keep the
timeline-transition adapters because they inject callback dependencies.

Blocked:
No.
