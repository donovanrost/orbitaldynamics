# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity contact-feedback aggregation extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract contact/command feedback field resolution, boolean/factor/source
aggregation, recursive provider-result canonicalization, and the provider
result key contract into
`OrbitalDynamics.Communications.LinkCapacity.ContactFeedback`.
Preserve the existing LinkCapacity public API facade.

Selection evidence:
- Live re-ranking places `link_capacity.ex` at 3,656 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and one line ahead of
  StationCalendar, followed by Manifest, ResourceProjection, TimelineFeedback,
  ContactAllocation, and RecommendationRiskContext.
- The selected family owns one station-row evidence responsibility:
  deterministic aggregation of contact and command outcomes, confidence
  factors, and factor sources across grouped contacts.
- Contact selection, throughput derivation, station-calendar evidence,
  availability, requirements, policy decisions, and artifact assembly remain
  outside this boundary.
- Existing metadata fallback, boolean precedence, minimum-factor selection,
  mixed-source/result markers, provider-result key order, scalar conversion,
  omission behavior, and deterministic output remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback operational-feedback grouping extraction, selected in
`25f2362c` and implemented in `06f6111d`.
`timeline_feedback.ex` moved from 3,675 to 3,606 lines; the dedicated
feedback-aggregation owner is 86 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
