# V1 Campaign Plan

The `campaign_plan.v1` artifact and its surrounding artifact-only review/import
contracts are documented across focused sub-files in
[`v1_campaign_plan/`](v1_campaign_plan/):

- [overview.md](v1_campaign_plan/overview.md) — the `campaign_plan.v1` surface, planner entry points, and the inventory of reports embedded in a campaign artifact.
- [operational_timeline_and_normalization.md](v1_campaign_plan/operational_timeline_and_normalization.md) — `operational_timeline_report.v1`, operator-review/Cadence-import vocabularies, activity normalization, timeline transition decisions, and protection helpers.
- [contact_contention.md](v1_campaign_plan/contact_contention.md) — `contact_contention_report.v1` and `contact_contention_resolution_report.v1` for station- and spacecraft-scoped contention with advisory resolution policy.
- [link_capacity.md](v1_campaign_plan/link_capacity.md) — `link_capacity_report.v1` station throughput rollups, downlink demand reconciliation, and review/import handoff.
- [contact_allocation.md](v1_campaign_plan/contact_allocation.md) — `contact_allocation_report.v1` filtering, reduced-capacity packing, reservation/match status, and capacity-pack ledger semantics.
- [candidate_refresh.md](v1_campaign_plan/candidate_refresh.md) — candidate-refresh replay of prior filter/allocation/contention/calendar evidence, embedded subreports, and strategy branch derivation.
- [timeline_diff.md](v1_campaign_plan/timeline_diff.md) — `timeline_diff_report.v1` row semantics, transition decisions, integrity evidence, and review/import propagation.
- [timeline_feedback.md](v1_campaign_plan/timeline_feedback.md) — `timeline_feedback_report.v1` reconciliation, realized-feedback handoffs, operational-feedback derivation, and `realized_activity.v1`/`realized_state_snapshot.v1` contracts.
- [command_window.md](v1_campaign_plan/command_window.md) — `command_window_report.v1` rows for command/tracking/health-check/uplink contacts and the V3 command/maneuver feedback replay paths.
- [station_calendar.md](v1_campaign_plan/station_calendar.md) — `station_calendar_report.v1`, provider artifact normalization, provider-calendar contention groups, and direction-scoped overlay semantics.
- [maneuver_review.md](v1_campaign_plan/maneuver_review.md) — `maneuver_review_report.v1` and `maneuver_recommendation.v1` handoff into review/import rows.
- [schema_validation.md](v1_campaign_plan/schema_validation.md) — `schema_validation_report.v1`, batch lint, and the schema-validation review/import gates.
