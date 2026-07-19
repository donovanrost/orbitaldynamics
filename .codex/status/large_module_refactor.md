# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback downlink-demand feedback extraction.

Status:
Selected; implementation not started.

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
Pending implementation.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness quality-gate operator-training summary extraction,
selected in `303a6a96` and implemented in `cca255af`.
`operational_readiness.ex` moved from 2,839 to 2,766 lines; the dedicated
operator-training summary owner is 156 lines.

Next candidate:
Implement and verify the selected TimelineFeedback downlink-demand feedback
extraction.

Blocked:
No.
