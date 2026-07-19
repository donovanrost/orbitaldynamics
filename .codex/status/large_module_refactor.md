# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity contact-feedback aggregation extraction.

Status:
Completed and pushed in `cc37865f`.

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
- Strict test-environment compile passed with warnings as errors across 3,919
  files.
- Focused LinkCapacity coverage passed: 44 tests.
- Adjacent operator-review and Cadence-import link-capacity coverage passed:
  10 tests.
- Exact public old/new comparison against selection commit `8fb99b99` passed
  for capability metadata plus report and summary outputs across direct and
  metadata-backed feedback, conflicting booleans, minimum factors, mixed
  sources/results, nested provider maps/lists, blanks, and invalid numeric
  values.
- `mix xref callers` reports only the LinkCapacity facade as a runtime caller
  of the extracted contact-feedback owner.
- Static ownership checks confirm feedback field resolution, aggregation, and
  provider-result canonicalization live in the dedicated owner while capacity
  and artifact responsibilities remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
LinkCapacity contact-feedback aggregation extraction, selected in `8fb99b99`
and implemented in `cc37865f`.
`link_capacity.ex` moved from 3,656 to 3,520 lines; the dedicated
contact-feedback owner is 166 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
