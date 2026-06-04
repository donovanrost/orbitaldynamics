# Policy Bundles

Reference for `policy_bundle.v1` and the built-in classifiers, plus the
artifact-only review/import contracts that consume their decisions. The
cross-cutting capability framing — what "policy, safety, and authority
boundaries" mean across V1/V2/V3 — lives in
[capability_map/15](../../feature_set/capability_map/15_policy_safety_and_authority_boundaries.md);
this directory is the artifact-level reference. Split into focused sub-files:

- [policy_bundles/overview.md](policy_bundles/overview.md) — bundle system overview, lookup APIs, normalization, organization-bundle provenance, and the built-in bundle list.
- [policy_bundles/built_in_bundles.md](policy_bundles/built_in_bundles.md) — fixtures and routing for each built-in bundle (mission-ops escalation, timeline protection, degraded payload guard, ground-network allocation, resource-projection authority, operator-review queue authority, command/contact authority, contact/command review, maneuver authority) plus organization-specific inline bundles.
- [policy_bundles/selectors_and_matching.md](policy_bundles/selectors_and_matching.md) — cross-cutting rule-match selectors and `policy_bundle.v1` JSON Schema, rule-match scope rules, scoped identity selectors, and policy-decision classification semantics.
- [policy_bundles/policy_in_contact_artifacts.md](policy_bundles/policy_in_contact_artifacts.md) — `contact_intent.v1` schema and approval lift, the `ContactFilter` facade, and command-window/standalone planned/proposed activity contracts.
- [policy_bundles/policy_in_campaign_and_allocation.md](policy_bundles/policy_in_campaign_and_allocation.md) — `campaign_plan.v1`, `contact_allocation_report.v1`, `optimizer_contract.v1`, plus `link_capacity_report.v1` and `resource_projection_report.v1` review/import normalization.
- [policy_bundles/policy_in_resource_artifacts.md](policy_bundles/policy_in_resource_artifacts.md) — `ResourceFilter` facade, resource-suppression rules, thin availability/margin model, `resource_projection_report.v1` row schema and roll-forward semantics, and `resource_filter_report.v1` suppressed-candidate row schema.
- [policy_bundles/policy_in_operator_review.md](policy_bundles/policy_in_operator_review.md) — `operator_review_package.v1` row types, policy-escalation rows, plan-delta/execution review, contention/maneuver/station-calendar/timeline-diff handoffs, and strategy-tradeoff/recommendation review/import gates.
- [policy_bundles/policy_in_candidate_refresh.md](policy_bundles/policy_in_candidate_refresh.md) — `candidate_refresh.v1` core, operational-feedback provenance and replay, refreshed contact-intents/resource-summaries, and `candidate_diff_report.v1`/`freshness_report.v1`/`refresh_budget_report.v1` handoffs.
- [policy_bundles/policy_in_branch_and_objective_reports.md](policy_bundles/policy_in_branch_and_objective_reports.md) — `branch_comparison_report.v1`, `objective_satisfaction_report.v1`, `objective_tradeoff_report.v1` (V1 and V3 strategy), `ranking_comparison_report.v1`/`pareto_frontier_report.v1`, `score_term_report.v1`, and `constraint_report.v1` schemas and review/import rows.
- [policy_bundles/policy_validation_and_records.md](policy_bundles/policy_validation_and_records.md) — validation reference reports/backend acceptance, `accepted_planning_state.v1`, `spacecraft_state_estimate.v1`, `maneuver_execution_delta.v1`, OPM/OEM adapters, TLE/OMM preflight, `station_calendar_provider.v1`, standalone window/candidate/invalidated contracts, and environment model/provider capability records.
