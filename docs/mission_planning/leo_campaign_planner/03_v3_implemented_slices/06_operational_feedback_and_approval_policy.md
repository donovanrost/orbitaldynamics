# Operational Feedback, Approval Policy, Examples, and Limits

Operational feedback uses deterministic success-rate and throughput factors:
contact success affects downlink/contact confidence, observation success affects
observation confidence, maneuver success can raise maneuver risk for maneuver
or impulsive-burn activities and maneuver timing events, and station throughput
adjusts downlink confidence. Resource availability feedback is a deterministic
payload/antenna availability overlay, not a subsystem simulator or learned
model.

Action-specific approval rules can classify moved contacts, strategic urgent
target additions, maneuver timing events, typed approval requirements, grouped
resource risks, grouped branch events, feasibility statuses, and resource
projection pressure promoted into branch risks. Built-in maneuver-authority
policy covers maneuver timing changes and impulsive-burn approval boundaries
with artifact-only escalation metadata; Cadence still owns any approval
workflow or schedule mutation. Cadence import manifests preserve maneuver
reviews as typed `review_maneuver` gates with source maneuver-review rows,
source recommendations, delta-v vectors, and policy evidence.
`policy_decision.v1` records are stored beside branch approvals so Cadence can
explain which policy fired, which fallback limits applied, and whether the
branch is auto-approvable, operator-review-required, or blocked by policy.
The same schema registry can validate and export standalone
`planned_activity.v1`, `proposed_contact.v1`, `contact_intent.v1`, and
`resource_summary.v1` rows for narrower Cadence import checks without requiring
the full campaign, repair, or strategy artifact envelope; proposed-contact rows
also replay directly into V3 contact-success and station-throughput feedback
when they carry realized provider factors, and standalone realized-activity rows
replay directly into V3 operational feedback when they carry provider execution
factors; realized-state snapshots replay their embedded activities through the
same path. V2 repair snapshots
also carry `realized_state_snapshot.v1` and `realized_activity.v1` contracts so
planned-vs-realized feedback can preserve source planned and realized activity
context through review and import gates without mutating the source schedule.
Cadence-sourced execution feedback can be validated independently before repair.
Timeline-feedback review and import rows preserve the feedback match strategy,
planned and realized timeline IDs, realized activity ID/type, source-window
type, source planned/realized activity rows, and planned operator-action
context, including dependency-cycle and other timeline-integrity evidence from
the planned row so completed provider feedback remains review-gated when the
source plan is cyclic. Their realized activity-context maps also carry provider-declared
planned IDs, reconciled planned IDs, match strategy, and ambiguous planned-ID
evidence, so Cadence adapters can correlate record/review rows without
unpacking the source feedback report. Realized-only uplink contact feedback is
classified as command feedback, matching the command-window authority boundary.
If Cadence or a provider emits multiple realized
rows for the same planned activity, the feedback report keeps all matched
realized IDs and normalized rows, increments duplicate-feedback counts, and
routes the activity to operator review before import.
If a realized feedback row identifies a timeline ID that matches multiple
planned activities, the row is kept as ambiguous realized-only feedback with
all possible planned activity IDs and source rows preserved for review instead
of being attached to an arbitrary planned item.
Strategy branch derivation follows the same trust boundary for sparse realized
activity rows: realized observation and downlink feedback only borrows target,
station, type, and throughput context from the prior plan when the planned
activity ID resolves to a single planned row, so duplicate planned IDs cannot
trigger target-revisit or downlink-completion branches through an arbitrary
lookup. When realized observation rows declare actual data volume, timeline
feedback summarizes that volume as default downlink-demand feedback for later
candidate-refresh or strategy handoff; it remains artifact evidence and does
not reserve provider contact time. If a V2 repair artifact is used as the V3
source plan and branch derivation is enabled, that source-derived demand can
create a branch-local candidate refresh with required-downlink evidence before
candidate-budget selection.
Timeline-diff artifacts now apply the same trust boundary to duplicate
timeline identities in source or replacement activity lists: colliding
activities are preserved in review-required diff rows with duplicate activity
IDs and normalized activity evidence instead of allowing one activity to
overwrite another during identity matching.
Operational timeline reports also count and mark duplicate timeline identities
as `review_duplicate_timeline_identity` rows, preserving the colliding activity
IDs and normalized source rows for downstream review/import gates.
Newly generated operator-review packages, Cadence import manifests, and
scoring/comparison reports also include top-level `model_limits` arrays that
declare the artifact-only limits behind those review/import rows.
Repair deltas, approval requirements, policy decisions, and strategy
recommendations are also standalone contracts, and result-set artifacts expose
`maneuver_recommendation.v1` rows extracted from trajectory maneuver
assumptions. Those maneuver rows are recommendation-only review products and do
not execute commands. Cadence can validate the operator-review rows it needs
without importing the whole strategy artifact. The exported schema bundle also
declares a compatibility policy for the top-level required fields, exported
types, and schema contract/version identifiers, plus a stable public-ID policy
that rejects blank or whitespace-containing artifact identifiers during linting.

Example V3 inputs and outputs are checked into:

- `studies/leo_constellation_campaign_strategy_v3.json`
- `study_results/leo_constellation_campaign_strategy_v3.json`

Remaining V3 limits are intentional:

- no Cadence database, UI, API, or autonomous command execution,
- no persistent digital-twin store,
- no high-fidelity resource simulator or link-budget model,
- no ML-based policy or feedback learning,
- no flight-certification or precision claims beyond the recorded model
  assumptions.
