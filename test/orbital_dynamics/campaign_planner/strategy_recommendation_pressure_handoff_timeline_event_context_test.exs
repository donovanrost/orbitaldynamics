Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffTimelineEventContextTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase

  @timeline_publication_context_contracts [
    {"identity", "timeline_publication_ids", "publication_id",
     ["timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1"],
     ["timeline_publication:stale"]},
    {"sequence", "timeline_publication_sequences", "publication_sequence", [9], [10]},
    {"status", "timeline_publication_statuses", "publication_status",
     ["published_with_downstream_invalidations"], ["stale_publication_status"]},
    {"downstream invalidation status", "timeline_publication_downstream_invalidation_statuses",
     "downstream_invalidation_status", ["invalidated"], ["stale_invalidation_status"]},
    {"dependency-impact status", "timeline_publication_dependency_impact_statuses",
     "dependency_impact_status", ["review_required"], ["stale_dependency_status"]},
    {"source-artifact identity", "timeline_publication_source_artifact_ids", "source_artifact_id",
     ["timeline:selected_plan:v2"], ["timeline:stale_plan"]},
    {"source-artifact type", "timeline_publication_source_artifact_types", "source_artifact_type",
     ["operational_timeline_report.v1"], ["stale_timeline_report.v1"]},
    {"authority", "timeline_publication_authorities", "publication_authority",
     ["mission_operations"], ["stale_authority"]},
    {"superseded artifact identities", "timeline_publication_supersedes_artifact_ids",
     ["supersedes_artifact_ids"], ["timeline:selected_plan:v1"], ["timeline:stale_plan"]},
    {"downstream product identities", "timeline_publication_downstream_product_ids",
     ["downstream_product_ids"], ["operator_review:selected:v1", "cadence_import:selected:v1"],
     ["stale_downstream_product"]},
    {"invalidated downstream product identities",
     "timeline_publication_invalidated_downstream_product_ids",
     ["invalidated_downstream_product_ids"],
     ["cadence_import:selected:v1", "operator_review:selected:v1"],
     ["stale_invalidated_product"]},
    {"downstream invalidation reason counts",
     "timeline_publication_downstream_invalidation_reason_count_maps",
     "downstream_invalidation_reason_counts", [%{"dependency_impact_review_required" => 2}],
     [%{"dependency_impact_review_required" => 3}]},
    {"downstream invalidation reasons", "timeline_publication_downstream_invalidation_reasons",
     ["downstream_invalidation_reasons"], ["dependency_impact_review_required"],
     ["stale_invalidation_reason"]},
    {"invalidated products by reason",
     "timeline_publication_invalidated_downstream_product_ids_by_reason",
     "invalidated_downstream_product_ids_by_reason",
     [
       %{
         "dependency_impact_review_required" => [
           "cadence_import:selected:v1",
           "operator_review:selected:v1"
         ]
       }
     ], [%{"dependency_impact_review_required" => ["stale_invalidated_product"]}]},
    {"dependency-impact row count", "timeline_publication_dependency_impact_row_count_values",
     "dependency_impact_row_count", [2], [3]},
    {"timeline-diff row count", "timeline_publication_timeline_diff_row_count_values",
     "timeline_diff_row_count", [3], [4]},
    {"timeline-diff changed count", "timeline_publication_timeline_diff_changed_count_values",
     "timeline_diff_changed_count", [2], [3]},
    {"timeline-diff review-required count",
     "timeline_publication_timeline_diff_review_required_count_values",
     "timeline_diff_review_required_count", [1], [2]},
    {"changed-field counts", "timeline_publication_changed_field_count_maps",
     "changed_field_counts", [%{"timeline_presence" => 2}], [%{"timeline_presence" => 3}]},
    {"changed fields", "timeline_publication_changed_fields", ["changed_fields"],
     ["timeline_presence"], ["stale_changed_field"]},
    {"changed timeline identities", "timeline_publication_changed_timeline_ids",
     ["changed_timeline_ids"], ["timeline:health_check:0.0"], ["timeline:stale_change"]},
    {"review timeline identities", "timeline_publication_review_timeline_ids",
     ["review_timeline_ids"], ["timeline:health_check:0.0", "timeline:health_check:5.0"],
     ["timeline:stale_review"]},
    {"timeline identities by changed field", "timeline_publication_timeline_ids_by_changed_field",
     "timeline_ids_by_changed_field",
     [
       %{
         "timeline_presence" => ["timeline:health_check:0.0", "timeline:health_check:5.0"]
       }
     ], [%{"timeline_presence" => ["timeline:stale_change"]}]},
    {"feedback source", "timeline_publication_feedback_sources", "feedback_source",
     ["mission_state.source_timeline_publication_summary"],
     ["mission_state.stale_timeline_publication_summary"]},
    {"feedback scope", "timeline_publication_feedback_scopes", "feedback_scope",
     ["timeline_publication"], ["stale_timeline_publication"]},
    {"feedback key", "timeline_publication_feedback_keys", "feedback_key",
     ["timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1"],
     ["timeline_publication:stale"]},
    {"trust boundary", "timeline_publication_trust_boundaries", "trust_boundary",
     ["mission_state_timeline_publication_summary"], ["stale_publication_boundary"]},
    {"derivation reasons", "timeline_publication_derivation_reasons", ["derivation_reasons"],
     ["timeline_publication_summary_pressure"], ["stale_publication_derivation"]},
    {"safety assumptions", "timeline_publication_assumption_maps", "assumptions",
     [
       %{
         "import_approval" => "not_granted_by_strategy_branch",
         "notification_delivery" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "publication_execution" => "not_performed_by_strategy_branch"
       }
     ],
     [
       %{
         "import_approval" => "not_granted_by_strategy_branch",
         "notification_delivery" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "publication_execution" => "stale_publication_execution"
       }
     ]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @timeline_publication_context_contracts do
    test "timeline-publication #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"feedback_scope", "timeline_publication"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @timeline_lifecycle_state_context_contracts [
    {"status", "timeline_lifecycle_state_statuses", "timeline_lifecycle_state_status",
     ["review_required"], ["stale_lifecycle_status"]},
    {"planned-activity count", "timeline_lifecycle_state_planned_activity_count_values",
     "planned_activity_count", [4], [5]},
    {"realized-activity count", "timeline_lifecycle_state_realized_activity_count_values",
     "realized_activity_count", [1], [2]},
    {"row count", "timeline_lifecycle_state_row_count_values", "row_count", [4], [5]},
    {"recordable count", "timeline_lifecycle_state_recordable_count_values", "recordable_count",
     [3], [4]},
    {"preserved count", "timeline_lifecycle_state_preserved_count_values", "preserved_count", [1],
     [2]},
    {"review-required count", "timeline_lifecycle_state_review_required_count_values",
     "review_required_count", [3], [4]},
    {"duplicate-identity count", "timeline_lifecycle_state_duplicate_identity_count_values",
     "duplicate_timeline_identity_count", [1], [2]},
    {"invalid-activity-input count",
     "timeline_lifecycle_state_invalid_activity_input_count_values",
     "invalid_activity_input_count", [1], [2]},
    {"transition-decision counts", "timeline_lifecycle_state_transition_decision_count_maps",
     "transition_decision_counts", [%{"record" => 3, "none" => 1}],
     [%{"record" => 4, "none" => 1}]},
    {"required-operator-action counts",
     "timeline_lifecycle_state_required_operator_action_count_maps",
     "required_operator_action_counts",
     [
       %{
         "review_activity_approval" => 1,
         "review_duplicate_timeline_identity" => 1,
         "review_invalid_activity_input" => 1
       }
     ],
     [
       %{
         "review_activity_approval" => 2,
         "review_duplicate_timeline_identity" => 1,
         "review_invalid_activity_input" => 1
       }
     ]},
    {"operator-action-reason counts",
     "timeline_lifecycle_state_operator_action_reason_count_maps",
     "operator_action_reason_counts",
     [
       %{
         "activity_approval_pending" => 1,
         "duplicate_timeline_identity" => 1,
         "missing_activity_type" => 1
       }
     ],
     [
       %{
         "activity_approval_pending" => 2,
         "duplicate_timeline_identity" => 1,
         "missing_activity_type" => 1
       }
     ]},
    {"import-action counts", "timeline_lifecycle_state_import_action_count_maps",
     "import_action_counts", [%{"review_timeline_diff" => 3}], [%{"review_timeline_diff" => 4}]},
    {"planned-status-category counts",
     "timeline_lifecycle_state_planned_status_category_count_maps",
     "planned_status_category_counts", [%{"planned" => 4}], [%{"planned" => 5}]},
    {"realized-status-category counts",
     "timeline_lifecycle_state_realized_status_category_count_maps",
     "realized_status_category_counts", [%{"executed" => 1}], [%{"executed" => 2}]},
    {"status-transition-category counts",
     "timeline_lifecycle_state_status_transition_category_count_maps",
     "status_transition_category_counts", [%{"changed" => 1}], [%{"changed" => 2}]},
    {"approval-transition-category counts",
     "timeline_lifecycle_state_approval_transition_category_count_maps",
     "approval_transition_category_counts", [%{"changed" => 1}], [%{"changed" => 2}]},
    {"recordable timeline identities", "timeline_lifecycle_state_recordable_timeline_ids",
     ["recordable_timeline_ids"],
     [
       "timeline:lifecycle:cmd_pending",
       "timeline:lifecycle:dup",
       "timeline:invalid_activity_input:lifecycle_bad_missing_type"
     ], ["timeline:stale_recordable"]},
    {"preserved timeline identities", "timeline_lifecycle_state_preserved_timeline_ids",
     ["preserved_timeline_ids"], ["timeline:lifecycle:obs_preserved"],
     ["timeline:stale_preserved"]},
    {"review timeline identities", "timeline_lifecycle_state_review_timeline_ids",
     ["review_timeline_ids"],
     [
       "timeline:lifecycle:cmd_pending",
       "timeline:lifecycle:dup",
       "timeline:invalid_activity_input:lifecycle_bad_missing_type"
     ], ["timeline:stale_review"]},
    {"review activity identities", "timeline_lifecycle_state_review_activity_ids",
     ["review_activity_ids"],
     [
       "lifecycle_cmd_pending",
       "lifecycle_dup_a",
       "lifecycle_dup_b",
       "timeline_row:4:lifecycle_bad_missing_type"
     ], ["stale_review_activity"]},
    {"invalid-activity-input identities", "timeline_lifecycle_state_invalid_activity_input_ids",
     ["invalid_activity_input_ids"], ["timeline_row:4:lifecycle_bad_missing_type"],
     ["stale_invalid_activity_input"]},
    {"review timelines by required operator action",
     "timeline_lifecycle_state_review_timeline_ids_by_required_operator_action",
     "review_timeline_ids_by_required_operator_action",
     [
       %{
         "review_activity_approval" => ["timeline:lifecycle:cmd_pending"],
         "review_duplicate_timeline_identity" => ["timeline:lifecycle:dup"],
         "review_invalid_activity_input" => [
           "timeline:invalid_activity_input:lifecycle_bad_missing_type"
         ]
       }
     ], [%{"review_activity_approval" => ["timeline:stale_review"]}]},
    {"review timelines by operator-action reason",
     "timeline_lifecycle_state_review_timeline_ids_by_operator_action_reason",
     "review_timeline_ids_by_operator_action_reason",
     [
       %{
         "activity_approval_pending" => ["timeline:lifecycle:cmd_pending"],
         "duplicate_timeline_identity" => ["timeline:lifecycle:dup"],
         "missing_activity_type" => [
           "timeline:invalid_activity_input:lifecycle_bad_missing_type"
         ]
       }
     ], [%{"activity_approval_pending" => ["timeline:stale_review"]}]},
    {"review timelines by status-transition category",
     "timeline_lifecycle_state_review_timeline_ids_by_status_transition_category",
     "review_timeline_ids_by_status_transition_category",
     [%{"changed" => ["timeline:lifecycle:cmd_pending"]}],
     [%{"changed" => ["timeline:stale_review"]}]},
    {"review timelines by approval-transition category",
     "timeline_lifecycle_state_review_timeline_ids_by_approval_transition_category",
     "review_timeline_ids_by_approval_transition_category",
     [%{"changed" => ["timeline:lifecycle:cmd_pending"]}],
     [%{"changed" => ["timeline:stale_review"]}]},
    {"required operator actions", "timeline_lifecycle_state_required_operator_actions",
     "required_operator_action", ["review_timeline_lifecycle_state"], ["stale_operator_action"]},
    {"operator-review requirement", "timeline_lifecycle_state_requires_operator_review_values",
     "requires_operator_review", [true], [false]},
    {"feedback source", "timeline_lifecycle_state_feedback_sources", "feedback_source",
     ["mission_state.source_timeline_lifecycle_state_summary"],
     ["mission_state.stale_timeline_lifecycle_state_summary"]},
    {"feedback scope", "timeline_lifecycle_state_feedback_scopes", "feedback_scope",
     ["timeline_lifecycle_state"], ["stale_timeline_lifecycle_state"]},
    {"feedback key", "timeline_lifecycle_state_feedback_keys", "feedback_key",
     ["mission.lifecycle.summary"], ["stale.lifecycle.summary"]},
    {"trust boundary", "timeline_lifecycle_state_trust_boundaries", "trust_boundary",
     ["mission_state_timeline_lifecycle_state_summary"], ["stale_lifecycle_boundary"]},
    {"derivation reasons", "timeline_lifecycle_state_derivation_reasons", ["derivation_reasons"],
     ["timeline_lifecycle_state_summary_pressure"], ["stale_lifecycle_derivation"]},
    {"safety assumptions", "timeline_lifecycle_state_assumption_maps", "assumptions",
     [
       %{
         "cadence_import" => "not_performed_by_strategy_branch",
         "command_execution" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "timeline_lifecycle_application" => "not_performed_by_strategy_branch",
         "timeline_mutation" => "not_performed_by_strategy_branch"
       }
     ],
     [
       %{
         "cadence_import" => "not_performed_by_strategy_branch",
         "command_execution" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "timeline_lifecycle_application" => "stale_lifecycle_application",
         "timeline_mutation" => "not_performed_by_strategy_branch"
       }
     ]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @timeline_lifecycle_state_context_contracts do
    test "timeline-lifecycle-state #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"feedback_scope", "timeline_lifecycle_state"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end
end
