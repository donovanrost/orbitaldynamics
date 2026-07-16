defmodule OrbitalDynamics.CampaignPlanner.CadenceImportDirectPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CadenceImportSourceReports,
    CandidateDiffPressureEvents,
    CommandWindowOperationalFeedback,
    ConstraintPressureBranches,
    ConstraintReviewRows,
    ContactAllocationPressureFanout,
    ContactAllocationReviewRows,
    ContactContentionPressureBranches,
    ContactFilterPressureBranches,
    ContactIntentPressureBranches,
    ContactIntentReviewRows,
    LinkCapacityPressureBranches,
    LinkCapacityReviewRows,
    ManeuverReviewOperationalFeedback,
    ObjectiveReviewRows,
    ObjectiveSatisfactionPressureBranches,
    ObjectiveTradeoffPressureBranches,
    OperationalTimelinePressureEvents,
    RealizedFeedbackPressureEvents,
    RefreshBudgetPressureEvents,
    RefreshFreshnessPressureEvents,
    ResourceFilterPressureBranches,
    ResourceProjectionPressureBranches,
    ResourceProjectionReviewRows,
    ReviewRowSources,
    ScalarValues,
    ScoreTermPressureBranches,
    ScoreTermReviewRows,
    StationCalendarReviewRows,
    SuppressionReviewRows,
    TimelineDiffPressureEventCallbacks,
    TimelineDiffPressureEvents,
    TimelineDiffReviewRows,
    TimelineSourceReports,
    ValueEncoding
  }

  def branches(
        row,
        source_review_row,
        index,
        policy,
        source_prefix
      ) do
    cond do
      is_map(TimelineDiffReviewRows.application_source(row)) ->
        row
        |> TimelineDiffReviewRows.application_source()
        |> TimelineSourceReports.timeline_transition_application_pressure_row()
        |> TimelineDiffReviewRows.review_row(row)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> timeline_diff_pressure_branch(
          "#{source_prefix}.#{TimelineDiffReviewRows.application_source_suffix(row)}",
          index
        )

      is_map(TimelineDiffReviewRows.application_source(source_review_row)) ->
        source_review_row
        |> TimelineDiffReviewRows.application_source()
        |> TimelineSourceReports.timeline_transition_application_pressure_row()
        |> TimelineDiffReviewRows.review_row(source_review_row)
        |> Map.put_new(
          "approval_status",
          row["approval_status"] || source_review_row["approval_status"]
        )
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> timeline_diff_pressure_branch(
          "#{source_prefix}.source_review_row.#{TimelineDiffReviewRows.application_source_suffix(source_review_row)}",
          index
        )

      is_map(row["source_timeline_diff"]) ->
        row["source_timeline_diff"]
        |> ValueEncoding.stringify_keys()
        |> TimelineDiffReviewRows.review_row(row)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> timeline_diff_pressure_branch(
          "#{source_prefix}.source_timeline_diff",
          index
        )

      is_map(source_review_row["source_timeline_diff"]) ->
        source_review_row["source_timeline_diff"]
        |> ValueEncoding.stringify_keys()
        |> TimelineDiffReviewRows.review_row(source_review_row)
        |> Map.put_new(
          "approval_status",
          row["approval_status"] || source_review_row["approval_status"]
        )
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> timeline_diff_pressure_branch(
          "#{source_prefix}.source_review_row.source_timeline_diff",
          index
        )

      TimelineDiffReviewRows.review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> timeline_diff_pressure_branch(
          "#{source_prefix}.timeline_diff_review",
          index
        )

      is_map(row["source_operational_timeline"]) ->
        row
        |> ReviewRowSources.operational_timeline()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> OperationalTimelinePressureEvents.pressure_branch(
          "#{source_prefix}.source_operational_timeline",
          index
        )

      OperationalTimelinePressureEvents.review_row?(row) ->
        row
        |> ReviewRowSources.operational_timeline()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> OperationalTimelinePressureEvents.pressure_branch(
          "#{source_prefix}.operational_timeline_review",
          index
        )

      is_map(row["source_candidate_diff"]) ->
        row
        |> ReviewRowSources.candidate_diff()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> CandidateDiffPressureEvents.pressure_branch(
          "#{source_prefix}.source_candidate_diff",
          index
        )

      CandidateDiffPressureEvents.review_row?(row) ->
        row
        |> ReviewRowSources.candidate_diff()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> CandidateDiffPressureEvents.pressure_branch(
          "#{source_prefix}.candidate_diff_review",
          index
        )

      is_map(row["source_refresh_budget_report"]) ->
        row
        |> ReviewRowSources.refresh_budget()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> RefreshBudgetPressureEvents.pressure_branch(
          "#{source_prefix}.source_refresh_budget_report",
          index
        )

      RefreshBudgetPressureEvents.review_row?(row) ->
        row
        |> ReviewRowSources.refresh_budget()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> RefreshBudgetPressureEvents.pressure_branch(
          "#{source_prefix}.refresh_budget_review",
          index
        )

      is_map(row["source_freshness_report"]) ->
        row
        |> ReviewRowSources.freshness()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> RefreshFreshnessPressureEvents.pressure_branch(
          "#{source_prefix}.source_freshness_report",
          index
        )

      RefreshFreshnessPressureEvents.review_row?(row) ->
        row
        |> ReviewRowSources.freshness()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> RefreshFreshnessPressureEvents.pressure_branch(
          "#{source_prefix}.freshness_review",
          index
        )

      is_map(row["source_delta"]) ->
        row
        |> TimelineDiffReviewRows.plan_delta_source()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> timeline_diff_pressure_branch(
          "#{source_prefix}.source_delta",
          index
        )

      TimelineDiffReviewRows.plan_delta_row?(row) ->
        row
        |> TimelineDiffReviewRows.plan_delta_source()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> timeline_diff_pressure_branch(
          "#{source_prefix}.plan_delta_review",
          index
        )

      is_map(row["source_command_window"]) ->
        row
        |> ReviewRowSources.command_window()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> CommandWindowOperationalFeedback.pressure_branch(
          "#{source_prefix}.source_command_window",
          index
        )

      CommandWindowOperationalFeedback.review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> CommandWindowOperationalFeedback.pressure_branch(
          "#{source_prefix}.command_window_review",
          index
        )

      is_map(row["source_maneuver_review"]) ->
        row
        |> ReviewRowSources.maneuver_review()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ManeuverReviewOperationalFeedback.pressure_branch(
          "#{source_prefix}.source_maneuver_review",
          index
        )

      ManeuverReviewOperationalFeedback.review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ManeuverReviewOperationalFeedback.pressure_branch(
          "#{source_prefix}.maneuver_review",
          index
        )

      is_map(row["source_feedback"]) ->
        row
        |> ReviewRowSources.realized_feedback()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> RealizedFeedbackPressureEvents.pressure_branch(
          "#{source_prefix}.source_feedback",
          index
        )

      RealizedFeedbackPressureEvents.review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> RealizedFeedbackPressureEvents.pressure_branch(
          "#{source_prefix}.realized_feedback",
          index
        )

      is_map(row["source_resource_projection"]) ->
        row["source_resource_projection"]
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ResourceProjectionPressureBranches.build(
          "#{source_prefix}.source_resource_projection",
          policy
        )

      ResourceProjectionReviewRows.review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ResourceProjectionPressureBranches.build(
          "#{source_prefix}.resource_projection_review",
          policy
        )

      is_map(row["source_link_capacity"]) ->
        row["source_link_capacity"]
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> Map.put_new("source_report", "cadence_import_manifest")
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> LinkCapacityPressureBranches.build("#{source_prefix}.source_link_capacity")

      LinkCapacityReviewRows.review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> Map.put_new("source_report", "cadence_import_manifest")
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> LinkCapacityPressureBranches.build("#{source_prefix}.link_capacity_review")

      is_map(row["source_contact_allocation"]) ->
        row["source_contact_allocation"]
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> contact_allocation_pressure_branch("#{source_prefix}.source_contact_allocation")

      ContactAllocationReviewRows.review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> contact_allocation_pressure_branch("#{source_prefix}.contact_allocation_review")

      is_map(row["source_contact_allocation_capacity_pack"]) ->
        row
        |> ReviewRowSources.contact_allocation_capacity_pack()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> capacity_pack_branches("#{source_prefix}.source_contact_allocation_capacity_pack")

      ContactAllocationReviewRows.capacity_pack_review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> capacity_pack_branches("#{source_prefix}.contact_allocation_capacity_pack_review")

      is_map(row["source_contact_intent"]) ->
        row
        |> ReviewRowSources.contact_intent()
        |> elem(0)
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ContactIntentPressureBranches.build("#{source_prefix}.source_contact_intent")

      ContactIntentReviewRows.review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ContactIntentPressureBranches.build("#{source_prefix}.contact_intent_review")

      is_map(row["source_station_calendar_review"]) ->
        StationCalendarReviewRows.pressure_branches(
          row,
          CadenceImportSourceReports.Rows.trust_boundary(row),
          source_prefix
        )

      is_map(row["source_station_calendar_provider_contention"]) ->
        StationCalendarReviewRows.pressure_branches(
          row,
          CadenceImportSourceReports.Rows.trust_boundary(row),
          source_prefix
        )

      StationCalendarReviewRows.review_row?(row) ->
        StationCalendarReviewRows.pressure_branches(
          row,
          CadenceImportSourceReports.Rows.trust_boundary(row),
          source_prefix
        )

      is_map(row["source_recommendation"]) ->
        row["source_recommendation"]
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> Map.put_new("review_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> contact_contention_resolution_pressure_branches(
          "#{source_prefix}.source_recommendation"
        )

      contact_contention_recommendation_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> Map.put_new("review_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> contact_contention_resolution_pressure_branches(
          "#{source_prefix}.contact_contention_recommendation"
        )

      is_map(row["source_contact_suppression"]) ->
        row["source_contact_suppression"]
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ContactFilterPressureBranches.build("#{source_prefix}.source_contact_suppression")

      SuppressionReviewRows.contact_review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ContactFilterPressureBranches.build("#{source_prefix}.contact_suppression")

      is_map(row["source_resource_suppression"]) ->
        row["source_resource_suppression"]
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ResourceFilterPressureBranches.build("#{source_prefix}.source_resource_suppression")

      SuppressionReviewRows.resource_review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ResourceFilterPressureBranches.build("#{source_prefix}.resource_suppression")

      is_map(row["source_objective_satisfaction"]) ->
        row["source_objective_satisfaction"]
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ObjectiveSatisfactionPressureBranches.branch(
          "#{source_prefix}.source_objective_satisfaction",
          index
        )

      ObjectiveReviewRows.satisfaction_review_row?(row) ->
        row
        |> ReviewRowSources.flattened_objective_satisfaction()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ObjectiveSatisfactionPressureBranches.branch(
          "#{source_prefix}.objective_satisfaction_review",
          index
        )

      is_map(row["source_objective_tradeoff"]) ->
        row["source_objective_tradeoff"]
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ObjectiveTradeoffPressureBranches.branch(
          "#{source_prefix}.source_objective_tradeoff",
          index
        )

      ObjectiveReviewRows.tradeoff_review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ObjectiveTradeoffPressureBranches.branch(
          "#{source_prefix}.objective_tradeoff_review",
          index
        )

      is_map(row["source_score_term"]) ->
        row["source_score_term"]
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ScoreTermPressureBranches.branch(
          "#{source_prefix}.source_score_term",
          index
        )

      ScoreTermReviewRows.review_row?(row) ->
        row
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ScoreTermPressureBranches.branch(
          "#{source_prefix}.score_term_review",
          index
        )

      is_map(row["source_constraint_row"]) ->
        row["source_constraint_row"]
        |> ValueEncoding.stringify_keys()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ConstraintPressureBranches.branch(
          "#{source_prefix}.source_constraint_row",
          index
        )

      ConstraintReviewRows.review_row?(row) ->
        row
        |> ReviewRowSources.flattened_constraint()
        |> Map.put_new("approval_status", row["approval_status"])
        |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)
        |> ConstraintPressureBranches.branch(
          "#{source_prefix}.constraint_review",
          index
        )

      true ->
        []
    end
  end

  def capacity_pack_branches(row, source_path) do
    row
    |> contact_allocation_capacity_pack_recommendation()
    |> contact_contention_resolution_pressure_branches(source_path)
  end

  defp contact_allocation_capacity_pack_recommendation(row) do
    source_recommendation =
      row
      |> Map.get("source_contention_recommendation", %{})
      |> ValueEncoding.stringify_keys()

    source_recommendation
    |> ValueEncoding.put_default_if_present(
      "group_id",
      row["contention_group_id"] || row["group_id"]
    )
    |> ValueEncoding.put_default_if_present(
      "contention_group_id",
      row["contention_group_id"] || row["group_id"]
    )
    |> ValueEncoding.put_default_if_present("ground_station_id", row["ground_station_id"])
    |> ValueEncoding.put_default_if_present(
      "selected_contact_id",
      first_present_id(row["selected_contact_ids"])
    )
    |> ValueEncoding.put_default_if_present("deferred_contact_ids", row["deferred_contact_ids"])
    |> ValueEncoding.put_default_if_present(
      "capacity_pack_group_id",
      row["contention_group_id"] || row["group_id"]
    )
    |> ValueEncoding.put_default_if_present("capacity_pack_status", row["pack_status"])
    |> ValueEncoding.put_default_if_present(
      "capacity_pack_capacity_fraction",
      row["capacity_fraction"]
    )
    |> ValueEncoding.put_default_if_present(
      "capacity_pack_used_fraction",
      row["used_capacity_fraction"]
    )
    |> ValueEncoding.put_default_if_present(
      "capacity_pack_unused_fraction",
      row["unused_capacity_fraction"]
    )
    |> ValueEncoding.put_default_if_present(
      "capacity_pack_contact_ids_by_direction",
      row["capacity_pack_contact_ids_by_direction"] || row["contact_ids_by_direction"]
    )
    |> ValueEncoding.put_default_if_present(
      "capacity_pack_selected_contact_ids_by_direction",
      row["capacity_pack_selected_contact_ids_by_direction"] ||
        row["selected_contact_ids_by_direction"]
    )
    |> ValueEncoding.put_default_if_present(
      "capacity_pack_deferred_contact_ids_by_direction",
      row["capacity_pack_deferred_contact_ids_by_direction"] ||
        row["deferred_contact_ids_by_direction"]
    )
    |> ValueEncoding.put_default_if_present(
      "capacity_pack_required_capacity_fraction_by_direction",
      row["capacity_pack_required_capacity_fraction_by_direction"] ||
        row["required_capacity_fraction_by_direction"]
    )
    |> ValueEncoding.put_default_if_present(
      "capacity_pack_selected_required_capacity_fraction_by_direction",
      row["capacity_pack_selected_required_capacity_fraction_by_direction"] ||
        row["selected_required_capacity_fraction_by_direction"]
    )
    |> ValueEncoding.put_default_if_present(
      "capacity_pack_deferred_required_capacity_fraction_by_direction",
      row["capacity_pack_deferred_required_capacity_fraction_by_direction"] ||
        row["deferred_required_capacity_fraction_by_direction"]
    )
    |> ValueEncoding.put_default_if_present(
      "capacity_requirement_rows",
      row["capacity_requirement_rows"]
    )
    |> ValueEncoding.put_default_if_present("trust_boundary", row["trust_boundary"])
    |> ValueEncoding.put_default_if_present("provenance", row["provenance"])
    |> ValueEncoding.put_default_if_present(
      "_source_report_trust_boundary",
      row["_source_report_trust_boundary"]
    )
  end

  defp first_present_id(values) do
    values
    |> List.wrap()
    |> Enum.find(&ScalarValues.stable_id_string?/1)
  end

  defp timeline_diff_pressure_branch(row, source_path, index) do
    TimelineDiffPressureEvents.pressure_branch(
      row,
      source_path,
      index,
      %{},
      TimelineDiffPressureEventCallbacks.callbacks()
    )
  end

  defp contact_allocation_pressure_branch(row, source_path) do
    ContactAllocationPressureFanout.branches(row, source_path)
  end

  defp contact_contention_resolution_pressure_branches(recommendation, source_path) do
    ContactContentionPressureBranches.resolution(recommendation, source_path)
  end

  defp contact_contention_recommendation_row?(row) do
    (row["source_review_type"] == "contact_contention_recommendation" or
       row["review_type"] == "contact_contention_recommendation" or
       row["import_action"] == "review_contact_contention_resolution") and
      row["deferred_contact_ids"] not in [nil, []]
  end
end
