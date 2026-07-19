# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-counteroffer normalization extraction.

Status:
Completed and pushed in `46e8ddb5`.

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
- Strict test-environment compile passed with warnings as errors across 3,907
  files.
- Focused StationCalendar coverage passed: 42 tests.
- Adjacent operator-review, schema-contract, and wrapped Cadence-import
  counteroffer coverage passed: 5 tests.
- Exact public old/new comparison against selection commit `a0dbc00c` passed
  for eight artifacts covering capabilities, provider normalization, contact
  overlay, report projection, review, import readiness, and plan impact.
- `mix xref callers` reports only the StationCalendar facade as a runtime
  caller of the extracted owner.
- Static ownership checks confirm counteroffer detection, aliased fields,
  negotiation-state vocabulary, numeric conversion, and stable ID validation
  live in the dedicated owner.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar provider-counteroffer normalization extraction, selected in
`a0dbc00c` and implemented in `46e8ddb5`.
`station_calendar.ex` moved from 4,012 to 3,924 lines; the dedicated owner is
195 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
