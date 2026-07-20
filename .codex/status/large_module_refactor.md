# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-activity-precondition extraction.

Status:
Completed and pushed in `9201d18b`.

Selected boundary:
Extract timeline-activity-precondition context keys, risk selection, context
value projection, deduplication, and omission behavior into
`OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition`.
Preserve all RecommendationRiskContext public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,893 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext already delegates thirteen focused contexts,
  including timeline activity lifecycle state, while timeline activity
  preconditions remain inline at lines 144-172 and 954-1,047.
- The selected block has one responsibility: collect timeline activity
  precondition review evidence into its public risk-context map.
- Other recommendation risk domains, common facade helpers, and all public
  contracts remain outside the boundary.
- Exact atom-key normalization, risk selection, scalar/list collection,
  encounter-order deduplication, empty-field omission, public output, and
  non-list fallback behavior must remain unchanged.

Implementation:
- Added
  `OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition` as
  the owner of context keys, risk selection, scalar/list value projection,
  deduplication, atom-key normalization, and empty-field omission.
- Preserved both RecommendationRiskContext public APIs as delegates, matching
  the existing timeline activity lifecycle-state owner pattern.
- Removed the timeline-activity-precondition key list and builder from the
  facade while leaving all other recommendation risk domains unchanged.
- `recommendation_risk_context.ex` moved from 1,893 to 1,772 lines; the new
  owner is 158 lines.

Verification:
- The focused strategy-recommendation baseline passed its single test; its two
  pre-existing signed-zero pattern warnings prevent a warnings-as-errors test
  invocation from exiting successfully.
- Exact old/new public parity passed for five deterministic results: context
  keys, mixed atom/string risks with scalar/list evidence, list-valued scalar
  fields, non-list fallback, and empty input.
- Post-extraction focused and adjacent verification passed all 8 tests; the 7
  adjacent tests passed with warnings-as-errors.
- Static checks confirm the precondition key/builder implementation left the
  facade; xref reports only RecommendationRiskContext as a runtime caller.
- Strict warning-clean forced compile passed for 4,004 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-activity-precondition extraction, selected
in `d27a1946` and implemented in `9201d18b`.
`recommendation_risk_context.ex` moved from 1,893 to 1,772 lines; the dedicated
TimelineActivityPrecondition owner is 158 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `orbit_data.ex` is now the largest ordinary eligible facade at
1,856 lines, followed by StationCalendar and ContactAllocation.

Blocked:
No.
