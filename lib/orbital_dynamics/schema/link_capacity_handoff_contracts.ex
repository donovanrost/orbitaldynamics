defmodule OrbitalDynamics.Schema.LinkCapacityHandoffContracts do
  @moduledoc false

  @count_list_pairs [
    {"contact_count", "contact_ids"},
    {"selected_contact_count", "selected_contact_ids"},
    {"ignored_contact_count", "ignored_contact_ids"},
    {"ignored_selected_contact_count", "ignored_selected_contact_ids"},
    {"ambiguous_selected_contact_id_count", "ambiguous_selected_contact_ids"},
    {"required_downlink_contact_count", "required_downlink_contact_ids"},
    {"actual_throughput_contact_count", "actual_throughput_contact_ids"},
    {"actual_completion_contact_count", "actual_completion_contact_ids"},
    {"unmatched_actual_throughput_contact_count", "unmatched_actual_throughput_contact_ids"},
    {"ambiguous_actual_throughput_contact_count", "ambiguous_actual_throughput_contact_ids"},
    {"unmatched_actual_completion_contact_count", "unmatched_actual_completion_contact_ids"},
    {"ambiguous_actual_completion_contact_count", "ambiguous_actual_completion_contact_ids"},
    {"unmatched_selected_contact_count", "unmatched_selected_contact_ids"},
    {"invalid_policy_required_downlink_station_count",
     "invalid_policy_required_downlink_station_ids"}
  ]
  @match_fields Enum.flat_map(@count_list_pairs, &Tuple.to_list/1)
  @source_fields [
    "ground_station_id",
    "estimated_throughput_mb",
    "selected_estimated_throughput_mb",
    "capacity_adjusted_throughput_mb",
    "selected_capacity_adjusted_throughput_mb",
    "unused_capacity_adjusted_throughput_mb",
    "selected_capacity_utilization_fraction",
    "selection_utilization_status",
    "required_downlink_mb",
    "downlink_completion_source",
    "downlink_completion_sources",
    "selected_downlink_shortfall_mb",
    "downlink_requirement_status",
    "actual_throughput_mb",
    "actual_completion_fraction",
    "actual_downlink_completion_ratio",
    "actual_downlink_shortfall_mb",
    "actual_downlink_requirement_status",
    "contact_success",
    "contact_success_factor",
    "contact_success_factor_source",
    "command_success",
    "command_success_factor",
    "command_success_factor_source",
    "station_calendar_entry_ids",
    "station_calendar_provider_ids",
    "station_calendar_provider_entry_ids",
    "station_calendar_directions",
    "station_reservation_ids",
    "station_reserved_bys",
    "station_reservation_statuses",
    "station_reservation_match_statuses",
    "capacity_fraction_min",
    "capacity_fraction_max",
    "approval_status"
    | @match_fields
  ]
  @context_source_review_fields [
    "source",
    "subject_id",
    "branch_id",
    "contact_id",
    "input_role",
    "required_operator_action",
    "reason",
    "ignored_contact_reason_counts",
    "ignored_selected_contact_reason_counts",
    "invalid_contact_input",
    "invalid_contact_input_reason",
    "requirement_type",
    "required_authority",
    "policy_bundle_id",
    "rule_id",
    "escalation_level",
    "escalation_queue",
    "escalation_role",
    "sla_s"
  ]
  @source_review_fields @source_fields ++ @context_source_review_fields

  def validate_count_lists(issues, path, row, callbacks) when is_list(callbacks) do
    if handoff_row?(row) do
      Enum.reduce(@count_list_pairs, issues, fn {count_field, list_field}, acc ->
        expect_field_matches_list_count(
          acc,
          callbacks,
          path,
          row,
          count_field,
          list_field,
          "must equal length of #{list_field}"
        )
      end)
    else
      issues
    end
  end

  def validate_matches_source(
        issues,
        path,
        %{"source_link_capacity" => %{} = source_row} = row
      ) do
    if handoff_row?(row) do
      Enum.reduce(@source_fields, issues, fn field, acc ->
        row_value = Map.get(row, field)
        source_value = Map.get(source_row, field)

        if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
          [error("#{path}.#{field}", "must match source_link_capacity.#{field}") | acc]
        else
          acc
        end
      end)
    else
      issues
    end
  end

  def validate_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if handoff_row?(row) do
      Enum.reduce(@source_review_fields, issues, fn field, acc ->
        row_value = Map.get(row, field)
        source_value = Map.get(source_review_row, field)

        if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
          [
            error(
              "#{path}.source_review_row.#{field}",
              "must match #{field} on Cadence import row"
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

  def validate_cadence_source_review_matches(issues, _path, _row), do: issues

  def handoff_row?(row) do
    Map.get(row, "review_type") == "link_capacity_review" or
      Map.get(row, "source_review_type") == "link_capacity_review" or
      Map.get(row, "import_action") == "review_link_capacity"
  end

  defp expect_field_matches_list_count(
         issues,
         callbacks,
         path,
         row,
         count_field,
         list_field,
         message
       ) do
    apply(require_callback(callbacks, :expect_field_matches_list_count), [
      issues,
      path,
      row,
      count_field,
      list_field,
      message
    ])
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
