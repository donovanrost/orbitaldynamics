# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-counteroffer handoff-summary extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract provider-counteroffer import-readiness and plan-impact summary
assembly, report-row routing, deadline classification orchestration,
counteroffer ID grouping, numeric cost aggregation, and timing/duration deltas
into
`OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferHandoffSummary`.
Preserve the public StationCalendar facade and retain private delegates for the
timing helpers also used by contact annotation.

Selection evidence:
- Live re-ranking places `communications/station_calendar.ex` at 2,981 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  OrbitalDynamics, RecommendationRiskContext, OperationalReadiness,
  TimelineFeedback, ContactContention, LinkCapacity, and ResourceProjection.
- The selected family spans the two summary builders and shared helpers from
  lines 2,503-2,697. It owns import-readiness classification, plan-impact
  timing/cost evidence, deadline-status orchestration, report-row selection,
  counteroffer routing IDs, and numeric delta/count/sum semantics.
- Contact annotation also uses counteroffer timing and duration deltas. Those
  calculations will be exposed by the owner and retained behind private facade
  delegates so there is one implementation.
- Calendar input normalization, contact matching and annotation, availability
  precedence, reservation summaries, provider contention, counteroffer report
  and review-summary construction, approval policy, public input-shape clauses,
  and schema contracts remain outside this boundary.
- Existing summary fields, row compaction, numeric coercion, deadline routing,
  stable ordering, idempotent summary clauses, and exact error behavior must
  remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None intended.

Last completed slice:
Study Manifest activity-input extraction, selected in `c864d294` and
implemented in `edd99630`.
`study/manifest.ex` moved from 3,000 to 2,229 lines; the dedicated
activity-input owner is 826 lines.

Next candidate:
Implement and verify the selected StationCalendar provider-counteroffer
handoff-summary extraction.

Blocked:
No.
