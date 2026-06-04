# Policy in Operator Review

## Operator Review Package

`operator_review_package.v1` exports a nested row schema for artifact-only
review/import rows. Rows can identify timeline-protection decisions for locked,
approved, or executed activities that repair preserved or changed, including the
protection category and preserved/changed decision. Repair and strategy review
packages can also expose `policy_escalation` rows copied from
`policy_decision.v1` escalation summaries, including required authority, queue,
role, SLA, source policy decision, and flattened policy-bundle provenance fields
for provenance source, adapter, organization, and policy-source routing. Standalone
`policy_decision.v1` artifacts can be normalized into the same
`policy_escalation` review rows for authority-boundary import queues, preserving
the source policy decision's model-limit boundary inside the review row for
downstream import gates.
Plan-delta review rows from campaign repair can also be replayed by V3 strategy
derivation when the source work was canceled or suppressed. Those prior
`plan_delta_review` / `review_plan_delta` rows are normalized into the existing
timeline-diff removed-work pressure path, preserving source activity context,
timeline identity, required operator action, source path, and review/import
trust boundary while leaving preserved timeline items as review-only evidence.
Execution-report failure rows normalize into `execution_review` rows that
preserve the failed scenario ID, zero-based source `scenario_index`,
non-resumable/manual-rerun status, and retry recommendation. Cadence import
manifests carry those same fields on `review_execution` gates so operators can
route a failed long-running run back to the exact source scenario without
inferring order from a separate manifest.
Operator-review packages also include
row-derived `review_type_counts`, `review_queue_counts`,
`approval_status_counts`, `required_operator_action_counts`, and
`cadence_import_status_counts`, `source_cadence_import_status_counts`, and
`replacement_cadence_import_status_counts` maps. Each row also carries a
deterministic `review_queue` and `review_queue_key` derived from review type,
required action, and approval status, with executable validation checking both
those maps and scalar review totals against the package rows when present.
Executable validation also treats operator-review row ranks and count evidence
fields as integers, including resource, contact, objective, repair, refresh, and
schema-validation counts, while score, timing, volume, margin, fraction, and
delta fields remain numeric.
Generic and plan-delta Cadence import review rows preserve row-level `target_id`
alongside station, spacecraft, branch, scenario, and source-window identifiers
when the source review row carries it. Cadence import manifests preserve those
policy rows as typed `review_policy_escalation` gates with queue, role,
required-authority, SLA, source-escalation, and source-decision fields for
downstream routing, plus the same flattened policy-bundle provenance source,
adapter, organization, and policy-source fields. Standalone
`approval_requirement.v1` rows now export and validate policy/routing evidence
directly, including activity context, rule IDs, policy bundle IDs,
classification, required authority, approval-rule matches, and embedded
policy-decision evidence. They can also be normalized into single-row approval
review packages and typed
`review_approval_requirement` Cadence import gates that preserve
`source_requirement`, durable activity context, and lifted routing fields such
as `required_authority`, `policy_bundle_id`, `rule_id`, and matched
policy-escalation level, queue, role, authority, and SLA metadata for downstream
approval queues without executing approval workflow. Warning and risk-explanation review rows are also typed Cadence gates:
they preserve the top-level operator reason, severity, source path, branch or
scenario identity, lifted activity or station routing context, station-calendar
direction context, first resource-pressure context, and structured
`source_risk` evidence when present instead of requiring adapters to unpack the
generic source review row. Contact-contention reports can be
normalized into `contact_contention_review` rows carrying conflicted contact
IDs, scenario IDs, resource scope, station and spacecraft ID arrays, timing,
source-window IDs, direction, required action, approval status, and the source
contention group; V1 campaign embedded contention groups use the same review/import surface with
`campaign_plan.contact_contention_report.conflict_groups` provenance.
Contention resolution reports can be normalized directly into
`contact_contention_recommendation` rows carrying the selected/deferred contact
recommendation, resource scope, multi-station/spacecraft context, candidate
count, selection reason, direction evidence, and source recommendation. When contention
artifacts were built with an approval policy, those rows preserve approval
requirements, rule matches, the source `policy_decision.v1`, and matched
policy-escalation authority, rule, queue, role, level, and SLA metadata so
Cadence import gates can route contention reviews without unpacking nested
policy decisions.
Command-window reports can be normalized into `command_window_review` rows for
command, tracking, health, or uplink windows that require operator review/import
action, carrying timing, direction, cadence import status, timeline identity,
dependency/exclusivity stable-ID arrays, source activity context, invalid-input
evidence when present, and the source command window row.
Maneuver review reports can be normalized into
`maneuver_review`
rows carrying maneuver ID, scenario, epoch, frame, delta-v, execution boundary,
execution-uncertainty status and review metadata, source recommendation, and the
source maneuver-review row. Station-calendar
reports can be normalized into `station_calendar_review` rows carrying affected
contact, station, timing, calendar-entry lineage, availability, capacity, and
reservation metadata, plus source policy decisions when the report was built
with an approval policy, including matched escalation queue and required
authority metadata. V1 campaign artifacts lift embedded
`station_calendar_report.affected_contacts` through the same review/import
surface with campaign-source provenance. V2 repair artifacts lift embedded
`source_station_calendar_report.affected_contacts` through the same
`station_calendar_review` and Cadence `review_station_calendar` surfaces, using
repair-source provenance while preserving reservation metadata. Timeline diff
reports can be normalized into
`timeline_diff_review` rows for added, removed, or changed timeline identities
that require operator review, carrying changed fields, timing deltas,
source/replacement activity IDs, and the source diff row.
Diff review and import rows also lift source/replacement spacecraft,
ground-station, target, and source-window IDs so adapter queues can route
changed assignments without unpacking the activity-context maps, while nested
source/replacement protection decisions remain schema-visible for timeline
protection audit tooling.
Campaign, repair, and strategy review packages can expose `contact_suppression`
rows copied from contact-filter reports and `resource_suppression` rows copied
from resource-filter reports, including suppressed activity/contact IDs, timing,
station availability or reservation fields, source-window lineage, and the
source suppression row. Contact suppression rows preserve optional contact-filter
approval-policy evidence (`approval_requirements`, `approval_rule_matches`, and
`source_policy_decision`) when the source report classified unavailable,
reserved, or zero-capacity station suppressions, and retain contact/command
success flags, feedback confidence factors, and source labels on the suppressed
row, approval context, operator review row, and Cadence import row. Native
`downlink` rows and
direction-`downlink` `planned_contact` rows normalize to
`review_suppressed_contact` actions for both contact- and resource-suppression
review rows, keeping planned downlink handoffs on the contact schedule review
path. Standalone
`contact_filter_report.v1` and
`resource_filter_report.v1` artifacts can be normalized into the same review
row types without requiring a campaign wrapper. Cadence import manifests now
preserve those rows as typed `review_contact_suppression` and
`review_resource_suppression` adapter gates with the source suppression row,
policy requirement routing fields, matched policy-escalation level, queue, role,
authority, and SLA metadata, station reservation fields, and thin resource
availability fields on the import row.

## Strategy Review Packages

Strategy review packages also expose
`strategy_tradeoff` rows with dimension, baseline, recommended, and delta
values copied from the nested recommendation tradeoffs or standalone branch
comparison reports. Cadence import manifests preserve those tradeoff rows as
typed `review_strategy_tradeoff` gates with reason/source context, branch
comparison source rows, repair score terms, and repaired link-capacity
throughput evidence; branch objective-satisfaction fields, feedback
factors/risk types, branch resource margin/risk evidence, and
priority-commitment required/planned/missing observation counts plus ratio are
promoted onto those rows so downstream import queues can route objective-gap,
low-confidence command/contact/station-throughput, and resource-pressure review
without unpacking the source branch-comparison payload.
Direct strategy-branch import rows produced from a full `campaign_strategy.v3`
artifact expose the same promoted branch evidence before the full source branch
comparison row is attached. Strategy recommendation rows from standalone
operator-review packages are likewise typed `review_strategy_recommendation`
gates with the recommended branch, reason, source path, and source
recommendation preserved, plus row-level operational-feedback provenance when
the recommendation came from a feedback-influenced strategy. Warning and risk
rows keep their reason/severity and structured risk evidence through Cadence
import manifests;
V2 plan-delta review
rows expose source/replacement timeline identity and activity-context maps for
repaired timeline import.
