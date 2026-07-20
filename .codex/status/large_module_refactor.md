# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema maneuver-review capability-context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract the maneuver-recommendation and maneuver-review report model-limit
projections into
`OrbitalDynamics.Schema.ManeuverReviewCapabilityContext`.
Import those two focused internal APIs into the Schema facade.
Keep maneuver schema construction, property dispatch, report validation, and
all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,188 lines.
- The two adjacent private helpers form the complete schema-facing
  ManeuverReview capability boundary: recommendation limits from the domain
  API and atom-to-string report limits from the capabilities map.
- Importing those two focused APIs preserves existing callback captures and
  validation calls while leaving all consumers in their current owners.
- Exact model-limit values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Added `OrbitalDynamics.Schema.ManeuverReviewCapabilityContext`, which now owns
the maneuver-recommendation and maneuver-review report model-limit
projections. `OrbitalDynamics.Schema` imports only those two focused APIs.
`schema.ex` moved from 6,188 to 6,184 lines; the dedicated owner is 13 lines.

Verification:
- Strict focused maneuver/export baseline before extraction: 18 passed.
- After extraction, the strict schema portion passed 17 and the strict
  maneuver-review export task passed 1.
- Strict full schema-export task plus adjacent validation-policy and
  fixture-visibility coverage: 3 passed.
- `mix xref callers
  OrbitalDynamics.Schema.ManeuverReviewCapabilityContext` reports only
  `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,063 files.
- Implementation commit `d4761487` pushed to `main`.

Behavior/schema changes:
None. Public facades, model-limit values and ordering, generated JSON Schema,
validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema maneuver-review capability-context extraction, selected in `381c3a71`
and implemented in `d4761487`.
`schema.ex` moved from 6,188 to 6,184 lines; the dedicated
ManeuverReviewCapabilityContext owner is 13 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
