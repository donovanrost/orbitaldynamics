# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema maneuver validation context extraction.

Status:
Completed and pushed.

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
Added default-context maneuver recommendation and review-report entry points
to DecisionSupportValidation, kept both customizable arity-four APIs, derived
limits from ManeuverReviewCapabilityContext, routed both eager facade
validations directly, and removed both wrappers. `schema.ex` moved from 5,752
to 5,734 lines.

Verification:
- Strict maneuver/operator-review/campaign baseline before extraction:
  6 passed.
- The same strict focused suite after extraction: 6 passed.
- Strict checked-in export, JSON Schema export, review/import handoff, and
  contact-feedback coverage: 27 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms two direct eager validations, zero facade
  wrappers, and retained customizable owner APIs.
- `mix xref callers OrbitalDynamics.Schema.DecisionSupportValidation` reports
  only the expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,072 files with no warnings.
- Bounded local diff review found no must-fix findings.
- Implementation commit `749ae44e` pushed to `main`.

Behavior/schema changes:
None. Maneuver model limits, issue ordering and paths, customizable owner entry
points, public Schema APIs, validation results, and checked-in exports remain
unchanged.

Last completed slice:
Schema maneuver validation context extraction, selected in `9e4614ec` and
implemented in `749ae44e`.
`schema.ex` moved from 5,752 to 5,734 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
