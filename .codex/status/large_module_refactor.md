# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar approval-policy extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract affected-contact and provider-contention approval decisions,
requirement construction, activity context, command/health-check requirement
typing, provider-result normalization, and provider-counteroffer delta evidence
into `OrbitalDynamics.Communications.StationCalendar.ApprovalPolicy`. Preserve
the public StationCalendar facade and the two private policy-application
delegates used by affected rows and provider-contention groups.

Selection evidence:
- Live re-ranking places `station_calendar.ex` at 2,778 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity, and ahead of
  OperationalReadiness, RecommendationRiskContext, TimelineFeedback, and
  LinkCapacity.
- The selected family spans lines 2,237-2,424 plus the two counteroffer delta
  helpers at lines 2,502-2,505. It owns Policy decisions for affected contacts
  and provider-contention groups, requirement activity types/actions/reasons,
  approval context projection, command and health-check specialization,
  provider result artifact flattening, and derived counteroffer time deltas.
- Affected-row construction and provider-contention grouping remain facade
  consumers through two narrow delegates.
- Calendar overlay/matching, reservation and hold summaries, counteroffer
  artifacts, station action/reason selection, duplicate disambiguation,
  general feedback validation, public clauses, and artifact contracts remain
  outside this boundary.
- Existing nil-policy pass-through, Policy inputs, requirement maps, context
  omission, provider-result traversal, command/health-check precedence,
  counteroffer explicit-value precedence, numeric delta fallback, decision
  fields, and exact errors must remain unchanged.

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused StationCalendar regression file and adjacent policy,
  operator-review, and validation consumers selected from live references.
- Run exact old/new parity from this selection commit across no-policy
  pass-through, affected row types, provider contention, counteroffers,
  command/health-check specialization, nested provider results, explicit and
  derived delta evidence, deterministic output, and invalid public errors.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  helper family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
LinkCapacity station-reservation evidence extraction, selected in `6d4702ee`,
implemented in `130b2c33`, and handed off in `f04e6781`.
`link_capacity.ex` moved from 2,792 to 2,554 lines; the dedicated
station-reservation evidence owner is 334 lines.

Next candidate:
Implement and verify the selected StationCalendar approval-policy extraction.

Blocked:
No.
