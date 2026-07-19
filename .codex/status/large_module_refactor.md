# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity station-reservation evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract station-reservation IDs, expiration timestamps, owners, statuses,
match statuses, nested/wrapped station-calendar source traversal, and the
corresponding row-derived summary aggregations into
`OrbitalDynamics.Communications.LinkCapacity.StationReservationEvidence`.
Preserve the public LinkCapacity facade and private delegates used by report
row construction, report-level aggregation, and compact summary projection.

Selection evidence:
- Live re-ranking places `link_capacity.ex` at 2,792 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity, and ahead of StationCalendar,
  OperationalReadiness, RecommendationRiskContext, and TimelineFeedback.
- The selected family spans row-derived reservation aggregation at lines
  1,353-1,410 and contact/source reservation extraction at lines 1,438-1,654.
  It owns explicit and nested reservation IDs, reserved-entry fallback IDs,
  recursively wrapped expiration values, owner/status/match-status
  normalization, and deterministic list/count aggregation.
- Report station rows, report-level reservation fields, summary reservation
  fields/counts, and summary routing maps remain facade consumers through
  narrow delegates.
- Link-capacity throughput, selection reconciliation, downlink requirements,
  approval policy, general station-calendar identity/direction evidence,
  availability/capacity semantics, public clauses, and artifact contracts
  remain outside this boundary.
- Existing explicit-ID precedence, reserved-source fallback, recursion depth,
  alias order, numeric/string/status normalization, nil/empty omission,
  uniqueness, sorting, frequency counts, and exact errors must remain
  unchanged.

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused LinkCapacity regression file and adjacent compact-summary,
  operator-review, validation, and schema fixture consumers selected from live
  references.
- Run exact old/new parity from this selection commit across direct and nested
  reservation evidence, wrapped expiration values, reserved-entry fallback,
  mixed atom/string/numeric values, stale row summaries, deterministic output,
  and invalid public input errors.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  helper family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention feedback-context extraction, selected in `1eb8bb50`,
implemented in `760a7ba0`, and handed off in `67213d3e`.
`contact_contention.ex` moved from 2,805 to 2,509 lines; the dedicated
feedback-context owner is 327 lines.

Next candidate:
Implement and verify the selected LinkCapacity station-reservation evidence
extraction.

Blocked:
No.
