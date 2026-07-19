# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-counteroffer report projection extraction.

Status:
Completed and pushed in `e0e40d24`.

Selected boundary:
Extract canonical provider-counteroffer report construction, row projection,
generated report identity, reviewability, preserved source entry, and numeric
report aggregates into
`OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferReport`.
Preserve the existing StationCalendar public API facade.

Selection evidence:
- Live re-ranking places `station_calendar.ex` at 3,924 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of Manifest,
  ResourceProjection, ContactAllocation, and TimelineFeedback.
- The selected helper family owns one `provider_counteroffer_report.v1`
  projection responsibility and consumes the dedicated normalization owner
  selected in the previous slice.
- Review, import-readiness, and plan-impact summary assembly remain in the
  facade as separate downstream artifact responsibilities.
- Calendar ingestion, station availability, reservations, contention,
  precedence, approval policy, and contact matching remain outside this
  boundary.
- Existing public APIs, normalized rows, report shapes, omission behavior, and
  deterministic ordering remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,908
  files.
- Focused StationCalendar coverage passed: 42 tests.
- Adjacent operator-review, schema-contract, and wrapped Cadence-import
  counteroffer coverage passed: 5 tests.
- Exact public old/new comparison against selection commit `4aadbd79` passed
  for eight artifacts covering capabilities, provider normalization, contact
  overlay, canonical report projection, review, import readiness, and plan
  impact.
- `mix xref callers` reports only the StationCalendar facade as a runtime
  caller of the extracted report owner.
- Static ownership checks confirm report construction, row identity,
  reviewability, source preservation, and report-row projection live in the
  dedicated owner while downstream summaries remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar provider-counteroffer report projection extraction, selected
in `4aadbd79` and implemented in `e0e40d24`.
`station_calendar.ex` moved from 3,924 to 3,804 lines; the dedicated report
owner is 217 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
