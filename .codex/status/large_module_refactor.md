# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar approval-policy extraction.

Status:
Completed and pushed in `7cf1481b`.

Selected boundary:
Extract affected-contact and provider-contention approval decisions,
requirement construction, activity context, command/health-check requirement
typing, provider-result normalization, and provider-counteroffer delta evidence
into `OrbitalDynamics.Communications.StationCalendar.ApprovalPolicy`. Preserve
the public StationCalendar facade and the two private policy-application
delegates used by affected rows and provider-contention groups.

Selection evidence:
- Live re-ranking placed `station_calendar.ex` at 2,778 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity, and ahead of
  OperationalReadiness, RecommendationRiskContext, TimelineFeedback, and
  LinkCapacity.
- The extracted family owns Policy decisions for affected contacts and
  provider-contention groups, requirement activity types/actions/reasons,
  approval context projection, command and health-check specialization,
  provider result artifact flattening, and derived counteroffer time deltas.
- Affected-row construction and provider-contention grouping remain facade
  consumers through two narrow delegates.
- Calendar overlay/matching, reservation and hold summaries, counteroffer
  artifacts, station action/reason selection, duplicate disambiguation,
  general feedback validation, public clauses, and artifact contracts remain
  outside this boundary.

Verification:
- Strict warning-clean compile passed across 3,955 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused StationCalendar regression passed 42 tests; adjacent
  operator-review and validation consumers passed 16 tests; the complete
  policy regression file passed 89 tests. The final consolidated run passed
  all 147 tests.
- Exact old/new parity passed 9 comparisons from selection commit `7ca6a115`
  with `/tmp/station_calendar_approval_policy_compare.exs`, covering nil-policy
  pass-through, ground-network and command-authority policies,
  command/health-check specialization, provider contention, nested provider
  results, explicit and derived counteroffer deltas, deterministic reports,
  reservation wrapping, and public errors.
- `mix xref callers
  OrbitalDynamics.Communications.StationCalendar.ApprovalPolicy` reports only
  the StationCalendar facade.
- Compile-connected xref scope for the new owner does not expand beyond the
  owner itself.
- Focused formatting, `git diff --check`, removed-family static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public StationCalendar facade, nil-policy behavior, Policy inputs
and decisions, requirement maps, context omission, provider-result traversal,
command/health-check precedence, counteroffer delta precedence, deterministic
artifacts, and exact errors are unchanged.

Last completed slice:
StationCalendar approval-policy extraction, selected in `7ca6a115` and
implemented in `7cf1481b`.
`station_calendar.ex` moved from 2,778 to 2,595 lines; the dedicated approval
policy owner is 213 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.
