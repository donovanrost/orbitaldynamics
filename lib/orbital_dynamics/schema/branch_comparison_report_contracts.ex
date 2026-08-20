defmodule OrbitalDynamics.Schema.BranchComparisonReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [expect_list_count_equals: 5, validate_numeric_map: 3, validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_at_least: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      expect_probability_range: 4,
      expect_type: 5,
      require_fields: 4,
      validate_optional_string_lists: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  @pressure_handoff_string_list_fields [
    "operational_readiness_report_ids",
    "operational_readiness_source_artifact_types",
    "operational_readiness_source_artifact_ids",
    "operational_readiness_levels",
    "operational_readiness_import_classifications",
    "operational_readiness_statuses",
    "operational_readiness_gate_ids",
    "operational_readiness_gate_statuses",
    "operational_readiness_gate_classifications",
    "operational_readiness_required_operator_actions",
    "operational_readiness_feedback_sources",
    "operational_readiness_feedback_scopes",
    "operational_readiness_feedback_keys",
    "operational_readiness_trust_boundaries",
    "quality_gate_report_ids",
    "quality_gate_source_artifact_types",
    "quality_gate_source_artifact_ids",
    "quality_gate_source_readiness_report_ids",
    "quality_gate_readiness_levels",
    "quality_gate_import_classifications",
    "quality_gate_pressure_statuses",
    "quality_gate_ids",
    "quality_gate_statuses",
    "quality_gate_classifications",
    "quality_gate_required_operator_actions",
    "quality_gate_feedback_sources",
    "quality_gate_feedback_scopes",
    "quality_gate_feedback_keys",
    "quality_gate_trust_boundaries",
    "quality_gate_resource_availability_reason_ids",
    "quality_gate_unavailable_resource_reason_ids"
  ]

  @row_count_fields [
    "approval_requirement_count",
    "branch_event_count",
    "branch_requires_operator_review_count",
    "candidate_activity_count",
    "coverage_observed_target_count",
    "priority_commitment_missed_target_count",
    "priority_commitment_required_target_count",
    "priority_commitment_satisfied_target_count",
    "repair_delta_count",
    "repair_link_contact_count",
    "repair_link_selected_contact_count",
    "repair_score_term_count",
    "resource_projection_antenna_unavailable_count",
    "resource_projection_degraded_payload_unavailable_count",
    "resource_projection_flow_count",
    "resource_projection_payload_unavailable_count",
    "resource_projection_spacecraft_count",
    "resource_projection_unavailable_spacecraft_count",
    "resource_projection_warning_count",
    "revisit_count",
    "risk_count"
  ]

  def row_count_fields, do: @row_count_fields

  def validate(issues, path, report) do
    {issues, report} =
      OrbitalDynamics.Schema.CollectionValidation.sanitize_list_field(
        issues,
        path,
        report,
        "rows"
      )

    issues
    |> expect_equal(path, report, "schema_contract", "branch_comparison_report.v1")
    |> expect_equal(
      path,
      report,
      "model",
      "deterministic_strategy_branch_score_comparison"
    )
    |> expect_equal(path, report, "source", "campaign_strategy.branches")
    |> expect_non_negative_integer(path, report, "branch_count")
    |> validate_stable_ids(path, report, ["recommended_branch_id"])
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_model_limits(path, report)
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_counts(path, report)
    |> validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      &validate_row/3
    )
  end

  def validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "id",
      "rank",
      "branch_id",
      "score",
      "score_delta_from_recommended",
      "selected",
      "approval_status",
      "risk_count",
      "approval_requirement_count",
      "score_terms"
    ])
    |> validate_stable_ids(path, row, ["id", "branch_id"])
    |> expect_number(path, row, "rank")
    |> expect_number(path, row, "score")
    |> expect_number(path, row, "score_delta_from_recommended")
    |> expect_optional_number(path, row, "raw_score")
    |> expect_optional_number(path, row, "branch_probability")
    |> expect_probability_range(path, row, "branch_probability")
    |> expect_optional_number(path, row, "expected_score")
    |> expect_type(path, row, "selected", :boolean)
    |> expect_one_of(path, row, "approval_status", [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ])
    |> expect_number(path, row, "risk_count")
    |> expect_number(path, row, "approval_requirement_count")
    |> expect_optional_number(path, row, "candidate_activity_count")
    |> expect_optional_number(path, row, "repair_delta_count")
    |> expect_optional_number(path, row, "repair_score")
    |> expect_optional_number(path, row, "repair_score_term_count")
    |> expect_optional_type(path, row, "repair_score_term_keys", :list)
    |> expect_optional_number(path, row, "repair_activity_score")
    |> expect_optional_number(path, row, "repair_schedule_churn_penalty")
    |> expect_optional_number(path, row, "repair_schedule_move_penalty")
    |> expect_optional_number(path, row, "repair_link_contact_count")
    |> expect_optional_number(path, row, "repair_link_selected_contact_count")
    |> expect_optional_number(
      path,
      row,
      "repair_link_selected_estimated_throughput_mb"
    )
    |> expect_optional_number(
      path,
      row,
      "repair_link_selected_capacity_adjusted_throughput_mb"
    )
    |> expect_optional_number(path, row, "repair_link_actual_throughput_mb")
    |> expect_optional_probability(
      path,
      row,
      "repair_link_actual_downlink_completion_ratio"
    )
    |> expect_optional_number(path, row, "repair_link_actual_downlink_shortfall_mb")
    |> expect_optional_type(
      path,
      row,
      "repair_link_actual_downlink_requirement_status",
      :binary
    )
    |> expect_optional_number(path, row, "fuel_margin")
    |> expect_optional_number(path, row, "storage_margin")
    |> expect_optional_number(path, row, "downlink_capacity_margin")
    |> expect_optional_number(path, row, "spacecraft_availability")
    |> expect_optional_number(path, row, "payload_availability")
    |> expect_optional_number(path, row, "antenna_availability")
    |> expect_optional_number(path, row, "resource_score_adjustment")
    |> expect_optional_number(path, row, "resource_projection_spacecraft_count")
    |> expect_optional_integer(path, row, "resource_projection_flow_count")
    |> expect_optional_number(path, row, "projected_storage_margin")
    |> expect_optional_number(path, row, "projected_storage_remaining_mb")
    |> expect_optional_number(path, row, "projected_downlink_margin")
    |> expect_optional_number(path, row, "projected_downlink_remaining_mb")
    |> expect_optional_number(path, row, "projected_storage_overflow_mb")
    |> expect_optional_number(path, row, "projected_downlink_shortfall_mb")
    |> expect_optional_number(path, row, "resource_projection_warning_count")
    |> expect_optional_type(path, row, "fuel_preservation_mode", :boolean)
    |> expect_optional_type(path, row, "resource_risk_types", :list)
    |> validate_string_list_items(path, row, "resource_risk_types")
    |> expect_optional_type(path, row, "risk_types", :list)
    |> validate_string_list_items(path, row, "risk_types")
    |> expect_optional_type(path, row, "high_risk_types", :list)
    |> validate_string_list_items(path, row, "high_risk_types")
    |> expect_optional_type(path, row, "resource_pressure_statuses", :list)
    |> validate_string_list_items(path, row, "resource_pressure_statuses")
    |> expect_optional_type(path, row, "resource_pressure_types", :list)
    |> validate_string_list_items(path, row, "resource_pressure_types")
    |> expect_optional_type(path, row, "first_resource_pressure_kinds", :list)
    |> validate_string_list_items(path, row, "first_resource_pressure_kinds")
    |> validate_optional_string_lists(
      path,
      row,
      @pressure_handoff_string_list_fields
    )
    |> validate_stable_ids(path, row, [
      "first_resource_pressure_activity_id",
      "first_resource_pressure_ground_station_id",
      "first_resource_pressure_station_calendar_entry_id",
      "first_resource_pressure_station_calendar_provider_id",
      "first_resource_pressure_station_calendar_provider_entry_id"
    ])
    |> expect_optional_type(
      path,
      row,
      "first_resource_pressure_activity_type",
      :binary
    )
    |> expect_optional_type(path, row, "first_resource_pressure_kind", :binary)
    |> expect_optional_number(path, row, "first_resource_pressure_starts_at_s")
    |> expect_optional_type(path, row, "first_resource_pressure_direction", :binary)
    |> expect_optional_type(
      path,
      row,
      "first_resource_pressure_station_calendar_directions",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "first_resource_pressure_station_calendar_directions"
    )
    |> expect_optional_number(path, row, "storage_limited_downlinked_mb")
    |> expect_optional_number(path, row, "unused_downlink_capacity_mb")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "downlink_completion_required_contacts"
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "downlink_completion_planned_contacts"
    )
    |> expect_optional_number(path, row, "downlink_completion_planned_downlink_mb")
    |> expect_optional_number(path, row, "downlink_completion_ratio")
    |> expect_probability_range(path, row, "downlink_completion_ratio")
    |> expect_optional_type(path, row, "feedback_risk_types", :list)
    |> validate_string_list_items(path, row, "feedback_risk_types")
    |> expect_optional_number(path, row, "feedback_score_adjustment")
    |> expect_optional_number(path, row, "observation_success_factor")
    |> expect_probability_range(path, row, "observation_success_factor")
    |> expect_optional_integer(path, row, "coverage_observed_target_count")
    |> expect_optional_integer(path, row, "priority_commitment_required_target_count")
    |> expect_optional_integer(path, row, "priority_commitment_satisfied_target_count")
    |> expect_optional_integer(path, row, "priority_commitment_missed_target_count")
    |> expect_optional_type(
      path,
      row,
      "priority_commitment_required_target_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "priority_commitment_required_target_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "priority_commitment_satisfied_target_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "priority_commitment_satisfied_target_ids"
    )
    |> expect_optional_type(path, row, "priority_commitment_missed_target_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "priority_commitment_missed_target_ids"
    )
    |> expect_optional_integer(path, row, "revisit_count")
    |> validate_branch_event_summary_fields(path, row)
    |> expect_optional_type(path, row, "capacity_pack_group_ids", :list)
    |> expect_optional_type(path, row, "capacity_pack_statuses", :list)
    |> expect_optional_number(path, row, "capacity_pack_min_capacity_fraction")
    |> expect_optional_number(path, row, "capacity_pack_max_used_fraction")
    |> expect_optional_number(
      path,
      row,
      "capacity_pack_max_required_capacity_fraction"
    )
    |> expect_optional_number(
      path,
      row,
      "capacity_pack_total_required_capacity_fraction"
    )
    |> expect_optional_type(
      path,
      row,
      "capacity_pack_required_capacity_sources",
      :list
    )
    |> validate_string_list_items(path, row, "capacity_pack_required_capacity_sources")
    |> expect_probability_range(path, row, "capacity_pack_min_capacity_fraction")
    |> expect_probability_range(path, row, "capacity_pack_max_used_fraction")
    |> expect_probability_range(
      path,
      row,
      "capacity_pack_max_required_capacity_fraction"
    )
    |> expect_field_at_least(
      path,
      row,
      "capacity_pack_total_required_capacity_fraction",
      0.0
    )
    |> validate_row_counts(path, row)
    |> expect_type(path, row, "score_terms", :map)
    |> validate_numeric_map(path <> ".score_terms", Map.get(row, "score_terms"))
  end

  def validate_row_counts(issues, path, row) do
    row_count_fields()
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, path, row, field)
    end)
    |> expect_list_count_equals(
      path,
      row,
      "repair_score_term_count",
      "repair_score_term_keys"
    )
    |> expect_list_count_equals(
      path,
      row,
      "priority_commitment_required_target_count",
      "priority_commitment_required_target_ids"
    )
    |> expect_list_count_equals(
      path,
      row,
      "priority_commitment_satisfied_target_count",
      "priority_commitment_satisfied_target_ids"
    )
    |> expect_list_count_equals(
      path,
      row,
      "priority_commitment_missed_target_count",
      "priority_commitment_missed_target_ids"
    )
  end

  defp validate_model_limits(issues, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      limits when is_list(limits) ->
        if limits == OrbitalDynamics.CampaignPlanner.branch_comparison_model_limits() do
          issues
        else
          [
            error(path <> ".model_limits", "must match branch comparison model limits")
            | issues
          ]
        end

      _limits ->
        issues
    end
  end

  defp validate_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    recommended_branch_id = Map.get(report, "recommended_branch_id")

    selected_rows =
      Enum.filter(rows, &(&1["selected"] == true))

    selected_branch_ids =
      Enum.map(selected_rows, &Map.get(&1, "branch_id"))

    issues
    |> expect_field_equals(path, report, "branch_count", length(rows))
    |> expect_recommended_branch_row(path, recommended_branch_id, rows)
    |> expect_single_selected_branch(path, selected_rows)
    |> validate_score_deltas(path, rows, recommended_branch_id)
    |> expect_field_equals(
      path,
      %{"selected_branch_ids" => selected_branch_ids},
      "selected_branch_ids",
      [recommended_branch_id],
      "must select exactly the recommended_branch_id"
    )
  end

  defp validate_score_deltas(issues, _path, _rows, nil), do: issues

  defp validate_score_deltas(issues, path, rows, recommended_branch_id) do
    recommended_score =
      rows
      |> Enum.find(&(&1["branch_id"] == recommended_branch_id))
      |> case do
        %{} = row -> Map.get(row, "score")
        _row -> nil
      end

    if is_number(recommended_score) do
      rows
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {row, index}, acc ->
        score = Map.get(row, "score")
        delta = Map.get(row, "score_delta_from_recommended")

        if is_number(score) and is_number(delta) and
             abs(delta - (score - recommended_score)) > 1.0e-9 do
          [
            error(
              "#{path}.rows[#{index}].score_delta_from_recommended",
              "must equal row score minus recommended branch score"
            )
            | acc
          ]
        else
          acc
        end
      end)
    else
      issues
    end
  end

  defp expect_recommended_branch_row(issues, _path, nil, _rows), do: issues

  defp expect_recommended_branch_row(issues, path, recommended_branch_id, rows) do
    if Enum.any?(rows, &(&1["branch_id"] == recommended_branch_id)) do
      issues
    else
      [
        error(path <> ".recommended_branch_id", "must match a branch comparison row")
        | issues
      ]
    end
  end

  defp expect_single_selected_branch(issues, path, selected_rows) do
    if length(selected_rows) == 1 do
      issues
    else
      [error(path <> ".rows", "must contain exactly one selected branch row") | issues]
    end
  end

  defp validate_branch_event_summary_fields(issues, path, row),
    do: OrbitalDynamics.Schema.BranchEventContracts.validate_summary_fields(issues, path, row)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
