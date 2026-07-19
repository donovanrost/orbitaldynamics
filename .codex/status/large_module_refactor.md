# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback downlink-demand feedback extraction.

Status:
Completed and pushed in `9b8c2d55`.

Selected boundary:
Extract weighted observation/contact downlink-demand derivation, residual
contact demand, station/default key routing, demand-source provenance,
trust-boundary eligibility values, and deterministic demand/source aggregation
into `OrbitalDynamics.TimelineFeedback.DownlinkDemandFeedback`. Preserve the
public TimelineFeedback facade and private delegates used by operational
feedback and provenance.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 2,809 lines, fifth behind
  Schema, Timeline, MissionPlan.Activity, and the intentionally public
  `OrbitalDynamics` facade, and ahead of ContactContention, LinkCapacity,
  StationCalendar, OperationalReadiness, RecommendationRiskContext, and
  ResourceProjection.
- The selected family spans lines 1,952-2,167. It owns demand derivation from
  observation actual/planned volume and completion, incomplete contact
  required-downlink residuals, feedback weighting, station/default keying,
  realized/source row provenance labels, exclusion-aware trust values, and
  sorted demand/source maps.
- Five facade consumers remain: operational feedback demand and source maps,
  plus the trust-key, trust-value, and source-trust-value functions used by
  provenance routing. Private delegates keep those callers stable.
- Reconciliation, realized/planned normalization, other operational feedback
  metrics, resource/priority/maneuver feedback, outcome aggregation, and public
  input/error clauses remain outside this boundary.
- Existing exclusion policy, numeric and unit-interval coercion, throughput
  aliases, feedback weights, positive-demand filtering, station/default keys,
  source labels, stable scalar identity, deterministic sorting, and exact
  fallback behavior must remain unchanged.

Verification:
- Strict warning-clean compile passed across 3,952 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused downlink-demand operational-feedback assertion passed: 1 test.
- Complete timeline-feedback regression bundle passed: 99 tests.
- Exact old/new parity passed 7 comparisons from selection commit `d8414e9e`
  with `/tmp/timeline_downlink_demand_compare.exs`, covering rich observation
  and contact demand, report wrapping, atom-key rows, empty feedback,
  deterministic station maps and duplicate accumulation, invalid-input errors,
  and full reconciliation provenance/trust routing.
- `mix xref callers
  OrbitalDynamics.TimelineFeedback.DownlinkDemandFeedback` reports only the
  TimelineFeedback facade.
- The owner has no compile-connected expansion beyond itself.
- Focused formatting, `git diff --check`, removed-family static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public TimelineFeedback facade, demand/source maps, exclusion and
weight semantics, residual demand, trust routing, deterministic ordering, and
exact errors are unchanged.

Last completed slice:
TimelineFeedback downlink-demand feedback extraction, selected in `d8414e9e`
and implemented in `9b8c2d55`.
`timeline_feedback.ex` moved from 2,809 to 2,608 lines; the dedicated
downlink-demand feedback owner is 239 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.
