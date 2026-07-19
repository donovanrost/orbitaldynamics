# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity stable contact-identity extraction.

Status:
Completed and pushed in `eef2a62a`.

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
- Strict test-environment compile passed with warnings as errors across 3,916
  files.
- Focused LinkCapacity coverage passed: 44 tests.
- Adjacent operator-review and Cadence-import link-capacity coverage passed:
  10 tests.
- Exact public old/new comparison against selection commit `a4818a70` passed
  for capability metadata and report, summary, and relay-data-path outputs
  covering atom, string, integer, nested, missing, malformed, and invalid
  contact, station, spacecraft, and route identities.
- `mix xref callers` reports only the LinkCapacity facade as a runtime caller
  of the extracted contact-identity owner.
- Static ownership checks confirm the stable-ID pattern, field contract,
  resolution precedence, and invalid-identity classification live in the
  dedicated owner while throughput and artifact responsibilities remain in
  the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
LinkCapacity stable contact-identity extraction, selected in `a4818a70` and
implemented in `eef2a62a`.
`link_capacity.ex` moved from 3,724 to 3,656 lines; the dedicated
contact-identity owner is 89 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
