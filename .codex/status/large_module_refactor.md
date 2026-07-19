# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity stable contact-identity extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the stable contact-identity field contract, stable-ID normalization,
contact/station/spacecraft identity resolution, and invalid-identity
classification into
`OrbitalDynamics.Communications.LinkCapacity.ContactIdentity`.
Preserve the existing LinkCapacity public API facade.

Selection evidence:
- Live re-ranking places `link_capacity.ex` at 3,724 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of ResourceProjection,
  TimelineFeedback, StationCalendar, Manifest, ContactAllocation, and
  RecommendationRiskContext.
- The selected family owns one validation-boundary responsibility reused by
  grouping, relay evidence, invalid-input review rows, and policy metadata:
  canonical stable identities and deterministic identity failure reasons.
- Throughput derivation, capacity adjustment, station availability,
  requirement resolution, policy decisions, and artifact assembly remain
  outside this boundary.
- Existing capability metadata, accepted identity types and pattern, fallback
  precedence, missing/invalid classifications, exceptions, and output ordering
  remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar provider-result canonicalization extraction, selected in
`bc3a559d` and implemented in `18189013`.
`station_calendar.ex` moved from 3,728 to 3,655 lines; the dedicated
provider-result owner is 77 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
