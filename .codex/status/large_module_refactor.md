# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity station-reservation evidence extraction.

Status:
Completed and pushed in `130b2c33`.

Selected boundary:
Extract station-reservation IDs, expiration timestamps, owners, statuses,
match statuses, nested/wrapped station-calendar source traversal, and the
corresponding row-derived summary aggregations into
`OrbitalDynamics.Communications.LinkCapacity.StationReservationEvidence`.
Preserve the public LinkCapacity facade and private delegates used by report
row construction, report-level aggregation, and compact summary projection.

Selection evidence:
- Live re-ranking placed `link_capacity.ex` at 2,792 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity, and ahead of StationCalendar,
  OperationalReadiness, RecommendationRiskContext, and TimelineFeedback.
- The extracted family owns explicit and nested reservation IDs,
  reserved-entry fallback IDs, recursively wrapped expiration values,
  owner/status/match-status normalization, and deterministic list/count
  aggregation for both report and summary rows.
- Report station rows, report-level reservation fields, summary reservation
  fields/counts, and summary routing maps remain facade consumers through
  narrow delegates.
- Link-capacity throughput, selection reconciliation, downlink requirements,
  approval policy, general station-calendar identity/direction evidence,
  availability/capacity semantics, public clauses, and artifact contracts
  remain outside this boundary.

Verification:
- Strict warning-clean compile passed across 3,954 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused LinkCapacity regression passed 44 tests; adjacent compact-summary
  replay, operator-review, wrapped Cadence import, and communications schema
  fixture consumers passed 16 tests. The final consolidated run passed all 60
  tests.
- Exact old/new parity passed 10 comparisons from selection commit `6d4702ee`
  with `/tmp/link_capacity_station_reservation_compare.exs`, covering direct
  and nested reservation evidence, explicit-ID precedence, reserved-entry
  fallback, recursively wrapped expirations, mixed atom/string/numeric values,
  stale row-derived summaries, empty and deterministic reports, and public
  errors.
- `mix xref callers
  OrbitalDynamics.Communications.LinkCapacity.StationReservationEvidence`
  reports only the LinkCapacity facade.
- Compile-connected xref scope for the new owner does not expand beyond the
  owner itself.
- Focused formatting, `git diff --check`, removed-family static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public LinkCapacity facade, reservation evidence precedence and
traversal, recursion depth, coercion, deterministic aggregation, report and
summary artifacts, routing maps, and exact errors are unchanged.

Last completed slice:
LinkCapacity station-reservation evidence extraction, selected in `6d4702ee`
and implemented in `130b2c33`.
`link_capacity.ex` moved from 2,792 to 2,554 lines; the dedicated
station-reservation evidence owner is 334 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.
