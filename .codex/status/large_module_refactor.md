# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-counteroffer normalization extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract provider-counteroffer detection, aliased field resolution, stable
counteroffer identity, negotiation-state normalization, and numeric offer
fields into
`OrbitalDynamics.Communications.StationCalendar.ProviderCounteroffer`.
Preserve the existing StationCalendar public APIs and report assembly facade.

Selection evidence:
- Live re-ranking places `station_calendar.ex` at 4,012 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of Manifest,
  ResourceProjection, ContactAllocation, and TimelineFeedback.
- The selected helper family owns one external provider-counteroffer
  normalization vocabulary used by both calendar ingestion and counteroffer
  artifact projection.
- Provider-counteroffer report, review, import-readiness, and plan-impact
  assembly remain in the facade for later responsibility-focused slices.
- Station availability, reservation, contention, precedence, approval-policy,
  and contact matching behavior remain outside this boundary.
- Existing public APIs, normalized row shapes, report artifacts, capability
  vocabularies, and deterministic ordering remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation lifecycle-evidence extraction, selected in
`f517ed33` and implemented in `ea3a4941`.
`timeline_feedback.ex` moved from 3,842 to 3,776 lines; the dedicated owner is
83 lines.

Next candidate:
Implement and verify the selected StationCalendar provider-counteroffer
normalization extraction.

Blocked:
No.
