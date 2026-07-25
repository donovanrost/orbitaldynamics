defmodule OrbitalDynamics.Schema.CampaignRepairContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CampaignRepairCandidateValueContracts,
    CampaignRepairCandidateDiffRankingContracts,
    CampaignRepairCadenceImportContracts,
    CampaignRepairCommandWindowContracts,
    CampaignRepairConstraintContracts,
    CampaignRepairContactAllocationContracts,
    CampaignRepairContactContentionResolutionPressureContracts,
    CampaignRepairContactIntentPressureContracts,
    CampaignRepairLinkCapacityPressureContracts,
    CampaignRepairProducedSurfaceContracts,
    CampaignRepairReadinessSourceContracts,
    CampaignRepairReplacementRankingContracts,
    CampaignRepairResourcePressureContracts,
    CampaignRepairScheduleRankingContracts,
    CampaignRepairScoreContracts,
    CampaignRepairStationPressureContracts,
    CampaignRepairTimelineTransitionContracts
  }

  @timeline_protection_fields [
    "preserved_locked_or_approved_count",
    "preserved_executed_count",
    "changed_locked_or_approved_count",
    "changed_executed_count",
    "preserved_locked_or_approved_activity_ids",
    "preserved_executed_activity_ids",
    "changed_locked_or_approved_activity_ids",
    "changed_executed_activity_ids"
  ]

  def validate(issues, artifact, required_fields, callbacks) when is_list(callbacks) do
    issues
    |> call(callbacks, :require_fields, ["$", artifact, required_fields])
    |> call(callbacks, :validate_stable_ids, ["$", artifact, ["source_plan_id"]])
    |> call(callbacks, :expect_equal, ["$", artifact, "schema_version", 2])
    |> call(callbacks, :expect_equal, [
      "$",
      artifact,
      "planner",
      "OrbitalDynamics.CampaignPlanner.V2"
    ])
    |> call(callbacks, :expect_type, ["$", artifact, "remaining_horizon", :map])
    |> call(callbacks, :expect_type, ["$", artifact, "activities", :list])
    |> call(callbacks, :expect_type, ["$", artifact, "source_candidate_activities", :list])
    |> call(callbacks, :expect_type, ["$", artifact, "deltas", :list])
    |> call(callbacks, :expect_type, ["$", artifact, "approval_requirements", :list])
    |> call(callbacks, :expect_one_of, [
      "$",
      artifact,
      "approval_status",
      ["auto_approvable", "operator_review_required", "blocked_by_policy"]
    ])
    |> call(callbacks, :expect_type, ["$", artifact, "approval_policy", :map])
    |> call(callbacks, :expect_type, ["$", artifact, "policy_decision", :map])
    |> call(callbacks, :expect_type, ["$", artifact, "warnings", :list])
    |> call(callbacks, :expect_type, ["$", artifact, "repair_metadata", :map])
    |> call(callbacks, :expect_optional_type, ["$", artifact, "source_planner", :binary])
    |> call(callbacks, :expect_optional_type, ["$", artifact, "study_id", :binary])
    |> call(callbacks, :validate_optional_stable_ids, ["$", artifact, ["study_id"]])
    |> call(callbacks, :expect_optional_type, ["$", artifact, "change_summary", :map])
    |> call(callbacks, :validate_realized_state_snapshot, [
      "$.realized_state_snapshot",
      Map.get(artifact, "realized_state_snapshot", %{})
    ])
    |> call(callbacks, :validate_rows, [
      "$.activities",
      Map.get(artifact, "activities", []),
      callback(callbacks, :validate_activity)
    ])
    |> CampaignRepairReplacementRankingContracts.validate_activities(
      "$.activities",
      Map.get(artifact, "activities", [])
    )
    |> call(callbacks, :validate_optional_rows, [
      "$.preserved_activities",
      Map.get(artifact, "preserved_activities"),
      callback(callbacks, :validate_activity)
    ])
    |> call(callbacks, :validate_optional_rows, [
      "$.approval_rule_matches",
      Map.get(artifact, "approval_rule_matches"),
      callback(callbacks, :validate_policy_rule_match)
    ])
    |> CampaignRepairProducedSurfaceContracts.validate(artifact)
    |> call(callbacks, :validate_optional_rows, [
      "$.source_contact_intents",
      Map.get(artifact, "source_contact_intents"),
      callback(callbacks, :validate_contact_intent)
    ])
    |> call(callbacks, :validate_optional_rows, [
      "$.source_resource_summaries",
      Map.get(artifact, "source_resource_summaries"),
      callback(callbacks, :validate_resource_summary)
    ])
    |> call(callbacks, :validate_optional_contact_filter_report, [
      "$.source_contact_filter_report",
      Map.get(artifact, "source_contact_filter_report")
    ])
    |> call(callbacks, :validate_optional_resource_filter_report, [
      "$.source_resource_filter_report",
      Map.get(artifact, "source_resource_filter_report")
    ])
    |> call(callbacks, :validate_optional_resource_projection_report, [
      "$.source_resource_projection_report",
      Map.get(artifact, "source_resource_projection_report")
    ])
    |> call(callbacks, :validate_optional_timeline_feedback_report, [
      "$.source_timeline_feedback_report",
      Map.get(artifact, "source_timeline_feedback_report")
    ])
    |> call(callbacks, :validate_optional_timeline_diff_report, [
      "$.source_timeline_diff_report",
      Map.get(artifact, "source_timeline_diff_report")
    ])
    |> call(callbacks, :validate_optional_operational_timeline_report, [
      Map.get(artifact, "operational_timeline_report")
    ])
    |> call(callbacks, :validate_optional_timeline_transition_application_report, [
      "$.timeline_transition_application_report",
      Map.get(artifact, "timeline_transition_application_report")
    ])
    |> CampaignRepairTimelineTransitionContracts.validate(artifact)
    |> call(callbacks, :validate_optional_command_window_report, [
      Map.get(artifact, "command_window_report")
    ])
    |> CampaignRepairCommandWindowContracts.validate(artifact)
    |> call(callbacks, :validate_optional_operator_review_package, [
      Map.get(artifact, "operator_review_package")
    ])
    |> call(callbacks, :validate_optional_cadence_import_manifest, [
      Map.get(artifact, "cadence_import_manifest")
    ])
    |> CampaignRepairCadenceImportContracts.validate(artifact)
    |> call(callbacks, :validate_optional_operational_readiness_report, [
      "$.source_operational_readiness_report",
      Map.get(artifact, "source_operational_readiness_report")
    ])
    |> call(callbacks, :validate_optional_operational_import_eligibility_summary, [
      "$.source_operational_import_eligibility_summary",
      Map.get(artifact, "source_operational_import_eligibility_summary")
    ])
    |> call(callbacks, :validate_optional_operational_readiness_gate_summary, [
      "$.source_operational_readiness_gate_summary",
      Map.get(artifact, "source_operational_readiness_gate_summary")
    ])
    |> call(callbacks, :validate_optional_operational_execution_boundary_summary, [
      "$.source_operational_execution_boundary_summary",
      Map.get(artifact, "source_operational_execution_boundary_summary")
    ])
    |> call(callbacks, :validate_optional_operational_quality_gate_summary, [
      "$.source_operational_quality_gate_summary",
      Map.get(artifact, "source_operational_quality_gate_summary")
    ])
    |> call(callbacks, :validate_optional_operational_quality_gate_unavailable_resource_summary, [
      "$.source_operational_quality_gate_unavailable_resource_summary",
      Map.get(artifact, "source_operational_quality_gate_unavailable_resource_summary")
    ])
    |> call(callbacks, :validate_optional_operational_quality_gate_operator_training_summary, [
      "$.source_operational_quality_gate_operator_training_summary",
      Map.get(artifact, "source_operational_quality_gate_operator_training_summary")
    ])
    |> call(callbacks, :validate_optional_operational_quality_gate_schema_validation_summary, [
      "$.source_operational_quality_gate_schema_validation_summary",
      Map.get(artifact, "source_operational_quality_gate_schema_validation_summary")
    ])
    |> call(callbacks, :validate_optional_operational_quality_gate_import_readiness_summary, [
      "$.source_operational_quality_gate_import_readiness_summary",
      Map.get(artifact, "source_operational_quality_gate_import_readiness_summary")
    ])
    |> call(callbacks, :validate_optional_quality_gate_report, [
      "$.source_quality_gate_report",
      Map.get(artifact, "source_quality_gate_report")
    ])
    |> call(callbacks, :validate_optional_schema_validation_report, [
      "$.source_schema_validation_report",
      Map.get(artifact, "source_schema_validation_report")
    ])
    |> call(callbacks, :validate_optional_model_acceptance_report, [
      "$.source_model_acceptance_report",
      Map.get(artifact, "source_model_acceptance_report")
    ])
    |> call(callbacks, :validate_optional_safety_case_summary, [
      "$.source_validation_safety_case_summary",
      Map.get(artifact, "source_validation_safety_case_summary")
    ])
    |> call(callbacks, :validate_optional_provider_counteroffer_report, [
      "$.source_provider_counteroffer_report",
      Map.get(artifact, "source_provider_counteroffer_report")
    ])
    |> call(callbacks, :validate_optional_provider_counteroffer_plan_impact_summary, [
      "$.source_provider_counteroffer_plan_impact_summary",
      Map.get(artifact, "source_provider_counteroffer_plan_impact_summary")
    ])
    |> call(callbacks, :validate_optional_provider_counteroffer_import_readiness_summary, [
      "$.source_provider_counteroffer_import_readiness_summary",
      Map.get(artifact, "source_provider_counteroffer_import_readiness_summary")
    ])
    |> CampaignRepairReadinessSourceContracts.validate(artifact)
    |> call(callbacks, :validate_optional_objective_tradeoff_report, [
      Map.get(artifact, "objective_tradeoff_report")
    ])
    |> call(callbacks, :validate_optional_source_objective_tradeoff_report, [
      "$.source_objective_tradeoff_report",
      Map.get(artifact, "source_objective_tradeoff_report")
    ])
    |> call(callbacks, :validate_optional_constraint_report, [
      Map.get(artifact, "constraint_report")
    ])
    |> call(callbacks, :validate_optional_source_constraint_report, [
      "$.source_constraint_report",
      Map.get(artifact, "source_constraint_report")
    ])
    |> call(callbacks, :validate_optional_source_objective_satisfaction_report, [
      "$.source_objective_satisfaction_report",
      Map.get(artifact, "source_objective_satisfaction_report")
    ])
    |> CampaignRepairConstraintContracts.validate(artifact)
    |> call(callbacks, :validate_optional_contact_allocation_report, [
      Map.get(artifact, "contact_allocation_report")
    ])
    |> CampaignRepairContactAllocationContracts.validate(artifact)
    |> call(callbacks, :validate_optional_score_term_report, [
      Map.get(artifact, "score_term_report")
    ])
    |> call(callbacks, :validate_optional_source_score_term_report, [
      "$.source_score_term_report",
      Map.get(artifact, "source_score_term_report")
    ])
    |> CampaignRepairScoreContracts.validate(artifact)
    |> OrbitalDynamics.Schema.CampaignRepairObjectiveTradeoffContracts.validate(artifact)
    |> CampaignRepairCandidateDiffRankingContracts.validate(artifact)
    |> CampaignRepairCandidateValueContracts.validate(artifact)
    |> CampaignRepairContactContentionResolutionPressureContracts.validate(artifact)
    |> CampaignRepairContactIntentPressureContracts.validate(artifact)
    |> CampaignRepairLinkCapacityPressureContracts.validate(artifact)
    |> CampaignRepairResourcePressureContracts.validate(artifact)
    |> CampaignRepairScheduleRankingContracts.validate(artifact)
    |> CampaignRepairStationPressureContracts.validate(artifact)
    |> call(callbacks, :validate_optional_link_capacity_report, [
      Map.get(artifact, "link_capacity_report")
    ])
    |> call(callbacks, :validate_optional_source_link_capacity_report, [
      "$.source_link_capacity_report",
      Map.get(artifact, "source_link_capacity_report")
    ])
    |> call(callbacks, :validate_optional_candidate_diff_report, [
      "$.source_candidate_diff_report",
      Map.get(artifact, "source_candidate_diff_report")
    ])
    |> call(callbacks, :validate_optional_candidate_rejection_report, [
      "$.source_candidate_rejection_report",
      Map.get(artifact, "source_candidate_rejection_report")
    ])
    |> call(callbacks, :validate_optional_freshness_report, [
      "$.source_freshness_report",
      Map.get(artifact, "source_freshness_report")
    ])
    |> call(callbacks, :validate_optional_refresh_budget_report, [
      "$.source_refresh_budget_report",
      Map.get(artifact, "source_refresh_budget_report")
    ])
    |> call(callbacks, :validate_optional_source_contact_allocation_report, [
      "$.source_contact_allocation_report",
      Map.get(artifact, "source_contact_allocation_report")
    ])
    |> call(callbacks, :validate_optional_source_contact_contention_report, [
      "$.source_contact_contention_report",
      Map.get(artifact, "source_contact_contention_report")
    ])
    |> call(callbacks, :validate_optional_source_contact_contention_resolution_report, [
      "$.source_contact_contention_resolution_report",
      Map.get(artifact, "source_contact_contention_resolution_report")
    ])
    |> call(callbacks, :validate_optional_source_station_reservation_report, [
      "$.source_station_reservation_report",
      Map.get(artifact, "source_station_reservation_report")
    ])
    |> call(
      callbacks,
      :validate_optional_source_station_reservation_hold_import_readiness_summary,
      [
        "$.source_station_reservation_hold_import_readiness_summary",
        Map.get(artifact, "source_station_reservation_hold_import_readiness_summary")
      ]
    )
    |> call(callbacks, :validate_optional_source_station_reservation_hold_summary, [
      "$.source_station_reservation_hold_summary",
      Map.get(artifact, "source_station_reservation_hold_summary")
    ])
    |> call(callbacks, :validate_optional_station_calendar_report, [
      "$.source_station_calendar_report",
      Map.get(artifact, "source_station_calendar_report")
    ])
    |> call(callbacks, :validate_rows, [
      "$.deltas",
      Map.get(artifact, "deltas", []),
      callback(callbacks, :validate_plan_delta)
    ])
    |> call(callbacks, :validate_rows, [
      "$.approval_requirements",
      Map.get(artifact, "approval_requirements", []),
      callback(callbacks, :validate_approval_requirement)
    ])
    |> call(callbacks, :validate_policy_decision, [
      "$.policy_decision",
      Map.get(artifact, "policy_decision", %{})
    ])
    |> call(callbacks, :require_nested, [
      "$.repair_metadata",
      Map.get(artifact, "repair_metadata", %{}),
      ["repair_id", "source_plan_id", "delta_count", "approval_required_count"]
    ])
    |> call(callbacks, :validate_stable_ids, [
      "$.repair_metadata",
      Map.get(artifact, "repair_metadata", %{}),
      ["repair_id", "source_plan_id"]
    ])
    |> validate_timeline_protection_metadata(artifact, callbacks)
  end

  def validate_timeline_protection_metadata(issues, artifact, callbacks)
      when is_list(callbacks) do
    repair_metadata = Map.get(artifact, "repair_metadata")

    timeline_protection =
      if is_map(repair_metadata), do: Map.get(repair_metadata, "timeline_protection")

    if is_map(repair_metadata) and is_map(timeline_protection) do
      expected =
        timeline_protection_summary(
          Map.get(artifact, "activities", []),
          Map.get(artifact, "deltas", [])
        )

      issues
      |> call(callbacks, :validate_optional_timeline_protection_summary, [
        "$.repair_metadata",
        repair_metadata,
        "timeline_protection"
      ])
      |> validate_timeline_protection_fields(callbacks, timeline_protection, expected)
    else
      issues
    end
  end

  defp validate_timeline_protection_fields(issues, callbacks, protection, expected) do
    Enum.reduce(@timeline_protection_fields, issues, fn field, acc ->
      call(acc, callbacks, :expect_field_equals_with_message, [
        "$.repair_metadata.timeline_protection",
        protection,
        field,
        Map.get(expected, field),
        "must equal row-derived repair timeline protection #{field}"
      ])
    end)
  end

  defp timeline_protection_summary(activities, deltas) do
    activities = list_or_empty(activities)
    deltas = list_or_empty(deltas)

    preserved_locked_ids =
      activities
      |> Enum.filter(&(get_in(&1, ["repair", "reason"]) == "activity_locked_or_approved"))
      |> Enum.map(&Map.get(&1, "id"))
      |> stable_sorted_values()

    preserved_executed_ids =
      activities
      |> Enum.filter(&(get_in(&1, ["repair", "action"]) == "preserved_executed"))
      |> Enum.map(&Map.get(&1, "id"))
      |> stable_sorted_values()

    changed_locked_ids =
      deltas
      |> Enum.reject(&(&1["repair_action"] in ["preserved", "preserved_executed"]))
      |> Enum.filter(&timeline_protection_locked_or_approved?(&1["planned"] || %{}))
      |> Enum.map(&Map.get(&1, "activity_id"))
      |> stable_sorted_values()

    changed_executed_ids =
      deltas
      |> Enum.reject(&(&1["repair_action"] in ["preserved", "preserved_executed"]))
      |> Enum.filter(&(&1["status"] in ["completed", "executed", "partial"]))
      |> Enum.map(&Map.get(&1, "activity_id"))
      |> stable_sorted_values()

    %{
      "preserved_locked_or_approved_count" => length(preserved_locked_ids),
      "preserved_executed_count" => length(preserved_executed_ids),
      "changed_locked_or_approved_count" => length(changed_locked_ids),
      "changed_executed_count" => length(changed_executed_ids),
      "preserved_locked_or_approved_activity_ids" => preserved_locked_ids,
      "preserved_executed_activity_ids" => preserved_executed_ids,
      "changed_locked_or_approved_activity_ids" => changed_locked_ids,
      "changed_executed_activity_ids" => changed_executed_ids
    }
  end

  defp timeline_protection_locked_or_approved?(activity) when is_map(activity) do
    metadata = Map.get(activity, "metadata", %{})

    truthy?(Map.get(activity, "locked")) or
      truthy?(Map.get(activity, "approved")) or
      truthy?(Map.get(metadata, "locked")) or
      truthy?(Map.get(metadata, "approved")) or
      Map.get(activity, "approval_status") in ["approved", "locked"] or
      Map.get(metadata, "approval_status") in ["approved", "locked"]
  end

  defp timeline_protection_locked_or_approved?(_activity), do: false

  defp truthy?(value) when is_boolean(value), do: value

  defp truthy?(value) when is_number(value), do: value == 1

  defp truthy?(value) when is_binary(value) do
    String.downcase(String.trim(value)) in ["true", "1"]
  end

  defp truthy?(_value), do: false

  defp stable_sorted_values(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp call(issues, callbacks, name, args),
    do: apply(callback(callbacks, name), [issues | args])
end
