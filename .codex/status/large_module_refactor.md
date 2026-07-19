# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation station-calendar-evidence extraction.

Status:
Completed and pushed in `9cebb4bf`.

Selected boundary:
Extract reconciled station availability and capacity, calendar provenance,
overlap and ambiguity evidence, and reservation state into
`OrbitalDynamics.TimelineFeedback.ReconciliationStationCalendarEvidence`.
Preserve the existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,180 lines, behind Timeline
  and MissionPlan.Activity but ahead of the remaining Manifest facade.
- The selected reconciliation-row fields form one planned-versus-realized
  station-calendar execution-evidence responsibility and depend only on the
  planned and realized row maps.
- Station-calendar input normalization remains in the facade. Identity,
  observation, communications and resource evidence, throughput, timing,
  success outcomes, execution uncertainty, operational-feedback exclusion,
  and report aggregation remain with their current owners.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,897
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `03b80371` passed
  for five reports covering matched, mismatched, planned-only, realized-only,
  and mixed rows with divergent valid station-calendar evidence.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the extracted owner.
- Static ownership checks confirm reconciliation fallback assembly lives in
  the dedicated owner while station-calendar normalization and operational
  consumers remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation station-calendar-evidence extraction, selected
in `03b80371` and implemented in `9cebb4bf`.
`timeline_feedback.ex` moved from 4,180 to 4,122 lines; the dedicated owner is
51 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
