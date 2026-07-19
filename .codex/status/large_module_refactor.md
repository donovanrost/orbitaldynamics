# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-counteroffer handoff-summary extraction.

Status:
Completed and pushed in `bb5307a5`.

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
- Strict warning-clean compile passed across 3,949 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused StationCalendar regression passed: 42 tests.
- Full adjacent station-calendar campaign-planner, candidate-refresh, and
  operator-review regression bundle passed: 57 tests.
- Exact old/new parity passed 10 comparisons from selection commit `4dcb6468`
  with `/tmp/station_counteroffer_handoff_compare.exs`, covering expired,
  active, and declared deadlines; import-readiness and plan-impact summaries;
  atom-key and raw-provider inputs; idempotent handoffs; contact-overlay timing
  delegates; and duplicate-counteroffer stable routing.
- `mix xref callers
  OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferHandoffSummary`
  reports only the StationCalendar facade.
- The owner has no compile-connected expansion beyond itself.
- Focused formatting, `git diff --check`, removed-helper static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public StationCalendar facade, counteroffer handoff contracts,
deadline and timing semantics, stable routing, row compaction, and exact error
behavior are unchanged.

Last completed slice:
StationCalendar provider-counteroffer handoff-summary extraction, selected in
`4dcb6468` and implemented in `bb5307a5`.
`communications/station_calendar.ex` moved from 2,981 to 2,778 lines; the
dedicated handoff-summary owner is 265 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.
