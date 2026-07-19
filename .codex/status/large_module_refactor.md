# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext contact-allocation extraction.

Status:
Completed and pushed in `567b1b93`.

Selected boundary:
Extract the contact-allocation risk-context key contract, allocation-risk
filtering, atom-key normalization, multi-key/list flattening, stable
deduplication, and sparse context construction into
`OrbitalDynamics.RecommendationRiskContext.ContactAllocation`. Preserve
`contact_allocation_context_keys/0`, `contact_allocation_context/1`, and all
other RecommendationRiskContext public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 2,142 lines,
  the largest ordinary eligible facade behind Schema, Timeline, and
  MissionPlan.Activity.
- RecommendationRiskContext already has eleven extracted context-family
  owners; the contact-allocation family remains in the facade with its key
  contract at lines 353-390 and builder at lines 1,417-1,502.
- The selected boundary mirrors existing ContactIntent and ResourceProjection
  owners: one public key contract, one context builder, one scope predicate,
  and private value/key normalization.
- Approval, contention, filter, station, timeline, objective, resource,
  maneuver, execution, feedback, and all other risk-context families remain
  outside the boundary.
- Exact key ordering, contact-allocation scope filtering, atom/string input
  parity, list flattening, first-seen value ordering, deduplication, empty-field
  omission, and non-list fallback must remain unchanged.

Implementation:
- Added `OrbitalDynamics.RecommendationRiskContext.ContactAllocation` as the
  owner of the ordered contact-allocation key contract, risk filtering,
  atom-key normalization, multi-key/list flattening, stable deduplication,
  sparse context construction, and non-list fallback.
- Preserved the RecommendationRiskContext public API as two thin delegates.
- Removed the contact-allocation attribute, builder, and private scope
  predicate from the facade while leaving shared helpers used by other context
  families unchanged.
- `recommendation_risk_context.ex` moved from 2,142 to 2,016 lines; the new
  dedicated owner is 160 lines.

Verification:
- Strict focused baseline: 7 contact-allocation pressure tests passed.
- A combined baseline with the recommendation pressure-event tests passed all
  eight behavior tests but retained the pre-existing signed-zero pattern
  warnings documented by earlier slices.
- Exact old/new public parity passed for all six captured cases: ordered keys,
  string-key risks, atom-key risks, mixed/duplicate risks, empty input, and
  non-list fallback.
- Focused and adjacent verification passed 12 tests across contact-allocation
  pressure, source-report, repair allocation-filter, and station-reservation
  allocation-challenge coverage.
- Static checks confirm the attribute and predicate left the facade and only
  its public delegates remain; xref reports only the facade as a runtime caller
  of the new owner.
- Strict warning-clean forced compile passed for 3,986 files.
- Formatting, `git diff --check`, and a clean post-push worktree passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext contact-allocation extraction, selected in
`8496a10e` and implemented in `567b1b93`.
`recommendation_risk_context.ex` moved from 2,142 to 2,016 lines; the dedicated
contact-allocation context owner is 160 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/contact_intent.ex` is currently the largest
ordinary eligible facade at 2,112 lines; its summary construction and routing
aggregation region is a promising responsibility boundary to assess.

Blocked:
No.
