# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection pressure classification extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract projection/flow pressure-type derivation, availability pressure
classification, status selection, first-pressure event metadata, and per-row
pressure kinds into
`OrbitalDynamics.ResourceProjection.PressureClassification`.
Preserve the existing ResourceProjection public API facade.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 3,629 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of TimelineFeedback,
  ContactAllocation, RecommendationRiskContext, OrbitalDynamics, Manifest,
  LinkCapacity, and StationCalendar.
- The selected family owns one interpretation responsibility reused by report
  summaries, routing maps, warnings, policy risks, and row metadata:
  deterministic classification of numerical and availability pressure.
- Projection math, activity resource effects, risk-row construction, policy
  decisions, provenance, and artifact assembly remain outside this boundary.
- Existing pressure vocabulary, sorting/deduplication, status precedence,
  first-event field selection, omission behavior, and deterministic output
  remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
Manifest candidate-refresh accepted planning-state extraction, selected in
`a1394b10` and implemented in `24f39a5c`.
`manifest.ex` moved from 3,638 to 3,530 lines; the dedicated planning-state
owner is 109 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
