# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema maneuver validation context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Add default-context entry points to DecisionSupportValidation for maneuver
recommendation and maneuver-review report validation. Derive limits from the
existing maneuver capability owner, route both eager Schema validations
directly, and remove both facade wrappers. Keep the customizable arity-four
owner APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,752 lines; the other
  targeted public facades are now 164 to 524 lines.
- Both wrappers supply only maneuver-owned model limits.
- Exact usage finds one required maneuver recommendation validation and one
  required maneuver-review report validation.
- `ManeuverReviewCapabilityContext` already owns both default limit lists; no
  recursive Schema lookup or facade context is required.
- Owner-default entry points preserve the customizable APIs for callers that
  supply alternate model limits.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema resource-projection validation context extraction, selected in
`d922c4fd` and implemented in `90f0fb94`.
`schema.ex` moved from 5,796 to 5,752 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
