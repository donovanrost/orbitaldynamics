defmodule OrbitalDynamics.Schema.BranchComparisonReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "branch_comparison_report.v1")
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "deterministic_strategy_branch_score_comparison"
    )
    |> expect_equal(callbacks, path, report, "source", "campaign_strategy.branches")
    |> expect_non_negative_integer(callbacks, path, report, "branch_count")
    |> validate_stable_ids(callbacks, path, report, ["recommended_branch_id"])
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_model_limits(callbacks, path, report)
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_counts(callbacks, path, report)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
  end

  def validate_row(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
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
    |> validate_stable_ids(callbacks, path, row, ["id", "branch_id"])
    |> expect_number(callbacks, path, row, "rank")
    |> expect_number(callbacks, path, row, "score")
    |> expect_number(callbacks, path, row, "score_delta_from_recommended")
    |> expect_optional_number(callbacks, path, row, "raw_score")
    |> expect_optional_number(callbacks, path, row, "branch_probability")
    |> expect_probability_range(callbacks, path, row, "branch_probability")
    |> expect_optional_number(callbacks, path, row, "expected_score")
    |> expect_type(callbacks, path, row, "selected", :boolean)
    |> expect_one_of(callbacks, path, row, "approval_status", [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ])
    |> expect_number(callbacks, path, row, "risk_count")
    |> expect_number(callbacks, path, row, "approval_requirement_count")
    |> expect_optional_number(callbacks, path, row, "candidate_activity_count")
    |> expect_optional_number(callbacks, path, row, "repair_delta_count")
    |> expect_optional_number(callbacks, path, row, "repair_score")
    |> expect_optional_number(callbacks, path, row, "repair_score_term_count")
    |> expect_optional_type(callbacks, path, row, "repair_score_term_keys", :list)
    |> expect_optional_number(callbacks, path, row, "repair_activity_score")
    |> expect_optional_number(callbacks, path, row, "repair_schedule_churn_penalty")
    |> expect_optional_number(callbacks, path, row, "repair_schedule_move_penalty")
    |> expect_optional_number(callbacks, path, row, "repair_link_contact_count")
    |> expect_optional_number(callbacks, path, row, "repair_link_selected_contact_count")
    |> expect_optional_number(
      callbacks,
      path,
      row,
      "repair_link_selected_estimated_throughput_mb"
    )
    |> expect_optional_number(
      callbacks,
      path,
      row,
      "repair_link_selected_capacity_adjusted_throughput_mb"
    )
    |> expect_optional_number(callbacks, path, row, "repair_link_actual_throughput_mb")
    |> expect_optional_probability(
      callbacks,
      path,
      row,
      "repair_link_actual_downlink_completion_ratio"
    )
    |> expect_optional_number(callbacks, path, row, "repair_link_actual_downlink_shortfall_mb")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "repair_link_actual_downlink_requirement_status",
      :binary
    )
    |> expect_optional_number(callbacks, path, row, "fuel_margin")
    |> expect_optional_number(callbacks, path, row, "storage_margin")
    |> expect_optional_number(callbacks, path, row, "downlink_capacity_margin")
    |> expect_optional_number(callbacks, path, row, "spacecraft_availability")
    |> expect_optional_number(callbacks, path, row, "payload_availability")
    |> expect_optional_number(callbacks, path, row, "antenna_availability")
    |> expect_optional_number(callbacks, path, row, "resource_score_adjustment")
    |> expect_optional_number(callbacks, path, row, "resource_projection_spacecraft_count")
    |> expect_optional_integer(callbacks, path, row, "resource_projection_flow_count")
    |> expect_optional_number(callbacks, path, row, "projected_storage_margin")
    |> expect_optional_number(callbacks, path, row, "projected_storage_remaining_mb")
    |> expect_optional_number(callbacks, path, row, "projected_downlink_margin")
    |> expect_optional_number(callbacks, path, row, "projected_downlink_remaining_mb")
    |> expect_optional_number(callbacks, path, row, "projected_storage_overflow_mb")
    |> expect_optional_number(callbacks, path, row, "projected_downlink_shortfall_mb")
    |> expect_optional_number(callbacks, path, row, "resource_projection_warning_count")
    |> expect_optional_type(callbacks, path, row, "fuel_preservation_mode", :boolean)
    |> expect_optional_type(callbacks, path, row, "resource_risk_types", :list)
    |> validate_string_list_items(callbacks, path, row, "resource_risk_types")
    |> expect_optional_type(callbacks, path, row, "risk_types", :list)
    |> validate_string_list_items(callbacks, path, row, "risk_types")
    |> expect_optional_type(callbacks, path, row, "high_risk_types", :list)
    |> validate_string_list_items(callbacks, path, row, "high_risk_types")
    |> expect_optional_type(callbacks, path, row, "resource_pressure_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "resource_pressure_statuses")
    |> expect_optional_type(callbacks, path, row, "resource_pressure_types", :list)
    |> validate_string_list_items(callbacks, path, row, "resource_pressure_types")
    |> expect_optional_type(callbacks, path, row, "first_resource_pressure_kinds", :list)
    |> validate_string_list_items(callbacks, path, row, "first_resource_pressure_kinds")
    |> validate_optional_string_lists(
      callbacks,
      path,
      row,
      strategy_recommendation_pressure_handoff_string_list_fields(callbacks)
    )
    |> validate_stable_ids(callbacks, path, row, [
      "first_resource_pressure_activity_id",
      "first_resource_pressure_ground_station_id",
      "first_resource_pressure_station_calendar_entry_id",
      "first_resource_pressure_station_calendar_provider_id",
      "first_resource_pressure_station_calendar_provider_entry_id"
    ])
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "first_resource_pressure_activity_type",
      :binary
    )
    |> expect_optional_type(callbacks, path, row, "first_resource_pressure_kind", :binary)
    |> expect_optional_number(callbacks, path, row, "first_resource_pressure_starts_at_s")
    |> expect_optional_type(callbacks, path, row, "first_resource_pressure_direction", :binary)
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "first_resource_pressure_station_calendar_directions",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      row,
      "first_resource_pressure_station_calendar_directions"
    )
    |> expect_optional_number(callbacks, path, row, "storage_limited_downlinked_mb")
    |> expect_optional_number(callbacks, path, row, "unused_downlink_capacity_mb")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "downlink_completion_required_contacts"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "downlink_completion_planned_contacts"
    )
    |> expect_optional_number(callbacks, path, row, "downlink_completion_planned_downlink_mb")
    |> expect_optional_number(callbacks, path, row, "downlink_completion_ratio")
    |> expect_probability_range(callbacks, path, row, "downlink_completion_ratio")
    |> expect_optional_type(callbacks, path, row, "feedback_risk_types", :list)
    |> validate_string_list_items(callbacks, path, row, "feedback_risk_types")
    |> expect_optional_number(callbacks, path, row, "feedback_score_adjustment")
    |> expect_optional_number(callbacks, path, row, "observation_success_factor")
    |> expect_probability_range(callbacks, path, row, "observation_success_factor")
    |> expect_optional_integer(callbacks, path, row, "coverage_observed_target_count")
    |> expect_optional_integer(callbacks, path, row, "priority_commitment_required_target_count")
    |> expect_optional_integer(callbacks, path, row, "priority_commitment_satisfied_target_count")
    |> expect_optional_integer(callbacks, path, row, "priority_commitment_missed_target_count")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "priority_commitment_required_target_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "priority_commitment_required_target_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "priority_commitment_satisfied_target_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "priority_commitment_satisfied_target_ids"
    )
    |> expect_optional_type(callbacks, path, row, "priority_commitment_missed_target_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "priority_commitment_missed_target_ids"
    )
    |> expect_optional_integer(callbacks, path, row, "revisit_count")
    |> validate_branch_event_summary_fields(callbacks, path, row)
    |> expect_optional_type(callbacks, path, row, "capacity_pack_group_ids", :list)
    |> expect_optional_type(callbacks, path, row, "capacity_pack_statuses", :list)
    |> expect_optional_number(callbacks, path, row, "capacity_pack_min_capacity_fraction")
    |> expect_optional_number(callbacks, path, row, "capacity_pack_max_used_fraction")
    |> expect_optional_number(
      callbacks,
      path,
      row,
      "capacity_pack_max_required_capacity_fraction"
    )
    |> expect_optional_number(
      callbacks,
      path,
      row,
      "capacity_pack_total_required_capacity_fraction"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "capacity_pack_required_capacity_sources",
      :list
    )
    |> validate_string_list_items(callbacks, path, row, "capacity_pack_required_capacity_sources")
    |> expect_probability_range(callbacks, path, row, "capacity_pack_min_capacity_fraction")
    |> expect_probability_range(callbacks, path, row, "capacity_pack_max_used_fraction")
    |> expect_probability_range(
      callbacks,
      path,
      row,
      "capacity_pack_max_required_capacity_fraction"
    )
    |> expect_field_at_least(
      callbacks,
      path,
      row,
      "capacity_pack_total_required_capacity_fraction",
      0.0
    )
    |> validate_row_counts(path, row, callbacks)
    |> expect_type(callbacks, path, row, "score_terms", :map)
    |> validate_numeric_map(callbacks, path <> ".score_terms", Map.get(row, "score_terms"))
  end

  def validate_row_counts(issues, path, row, callbacks) when is_list(callbacks) do
    callbacks
    |> branch_comparison_row_count_fields()
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, callbacks, path, row, field)
    end)
    |> expect_list_count_equals(
      callbacks,
      path,
      row,
      "repair_score_term_count",
      "repair_score_term_keys"
    )
    |> expect_list_count_equals(
      callbacks,
      path,
      row,
      "priority_commitment_required_target_count",
      "priority_commitment_required_target_ids"
    )
    |> expect_list_count_equals(
      callbacks,
      path,
      row,
      "priority_commitment_satisfied_target_count",
      "priority_commitment_satisfied_target_ids"
    )
    |> expect_list_count_equals(
      callbacks,
      path,
      row,
      "priority_commitment_missed_target_count",
      "priority_commitment_missed_target_ids"
    )
  end

  defp validate_model_limits(issues, callbacks, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      limits when is_list(limits) ->
        if limits == branch_comparison_model_limits(callbacks) do
          issues
        else
          [
            error(callbacks, path <> ".model_limits", "must match branch comparison model limits")
            | issues
          ]
        end

      _limits ->
        issues
    end
  end

  defp validate_counts(issues, callbacks, path, report) do
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
    |> expect_field_equals(callbacks, path, report, "branch_count", length(rows))
    |> expect_recommended_branch_row(callbacks, path, recommended_branch_id, rows)
    |> expect_single_selected_branch(callbacks, path, selected_rows)
    |> validate_score_deltas(callbacks, path, rows, recommended_branch_id)
    |> expect_field_equals(
      callbacks,
      path,
      %{"selected_branch_ids" => selected_branch_ids},
      "selected_branch_ids",
      [recommended_branch_id],
      "must select exactly the recommended_branch_id"
    )
  end

  defp validate_score_deltas(issues, _callbacks, _path, _rows, nil), do: issues

  defp validate_score_deltas(issues, callbacks, path, rows, recommended_branch_id) do
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
              callbacks,
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

  defp expect_recommended_branch_row(issues, _callbacks, _path, nil, _rows), do: issues

  defp expect_recommended_branch_row(issues, callbacks, path, recommended_branch_id, rows) do
    if Enum.any?(rows, &(&1["branch_id"] == recommended_branch_id)) do
      issues
    else
      [
        error(callbacks, path <> ".recommended_branch_id", "must match a branch comparison row")
        | issues
      ]
    end
  end

  defp expect_single_selected_branch(issues, callbacks, path, selected_rows) do
    if length(selected_rows) == 1 do
      issues
    else
      [error(callbacks, path <> ".rows", "must contain exactly one selected branch row") | issues]
    end
  end

  defp branch_comparison_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :branch_comparison_model_limits), [])

  defp branch_comparison_row_count_fields(callbacks),
    do: apply(Keyword.fetch!(callbacks, :branch_comparison_row_count_fields), [])

  defp strategy_recommendation_pressure_handoff_string_list_fields(callbacks),
    do:
      apply(
        Keyword.fetch!(callbacks, :strategy_recommendation_pressure_handoff_string_list_fields),
        []
      )

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_integer), [issues, path, map, field])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_probability), [issues, path, map, field])

  defp expect_probability_range(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_probability_range), [issues, path, map, field])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_at_least(issues, callbacks, path, map, field, minimum),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_at_least), [
        issues,
        path,
        map,
        field,
        minimum
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp expect_list_count_equals(issues, callbacks, path, row, count_field, list_field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_list_count_equals), [
        issues,
        path,
        row,
        count_field,
        list_field
      ])

  defp validate_branch_event_summary_fields(issues, callbacks, path, row),
    do:
      apply(Keyword.fetch!(callbacks, :validate_branch_event_summary_fields), [
        issues,
        path,
        row
      ])

  defp validate_numeric_map(issues, callbacks, path, value),
    do: apply(Keyword.fetch!(callbacks, :validate_numeric_map), [issues, path, value])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_string_lists(issues, callbacks, path, map, fields),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_string_lists), [
        issues,
        path,
        map,
        fields
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
