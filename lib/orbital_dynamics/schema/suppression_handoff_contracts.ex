defmodule OrbitalDynamics.Schema.SuppressionHandoffContracts do
  @moduledoc false

  @source_field_pairs [
    {"activity_type", "type"}
    | Enum.map(
        [
          "base_candidate_id",
          "scenario_id",
          "spacecraft_id",
          "target_id",
          "ground_station_id",
          "direction",
          "starts_at_s",
          "ends_at_s",
          "source_window_id",
          "contact_success",
          "contact_success_factor",
          "contact_success_factor_source",
          "command_success",
          "command_success_factor",
          "command_success_factor_source",
          "station_availability",
          "station_calendar_entry_id",
          "station_calendar_directions",
          "station_calendar_status",
          "station_calendar_overlap_count",
          "station_calendar_overlap_entry_ids",
          "station_calendar_overlap_availabilities",
          "station_calendar_entry_ambiguous",
          "station_calendar_ambiguous_entry_count",
          "station_calendar_ambiguous_entry_ids",
          "station_calendar_reservation_overlap_count",
          "station_calendar_reservation_ids",
          "station_calendar_reserved_by",
          "station_calendar_reservation_statuses",
          "station_calendar_reservation_expires_at_s",
          "station_contention_status",
          "station_reservation_id",
          "station_reservation_expires_at_s",
          "station_reserved_by",
          "station_reservation_status",
          "station_reservation_match_status",
          "resource_source_quality",
          "resource_trust_boundary",
          "resource_trust_boundary_status",
          "resource_provenance",
          "resource_blocking_dimension",
          "fuel_margin",
          "thermal_margin_c",
          "power_margin",
          "storage_margin",
          "downlink_margin",
          "battery_capacity_wh",
          "battery_energy_used_wh",
          "battery_energy_generated_wh",
          "battery_state_of_charge",
          "spacecraft_available",
          "payload_available",
          "antenna_available",
          "degraded",
          "mode",
          "incompatible_activity_types",
          "suppressed_activity_types",
          "duplicate_suppressed_candidate_id_collision",
          "duplicate_suppressed_candidate_index",
          "duplicate_suppressed_candidate_count",
          "invalid_contact_input",
          "invalid_contact_input_reason",
          "invalid_candidate_input",
          "invalid_candidate_input_reason",
          "invalid_resource_summary_input",
          "invalid_resource_summary_input_reason",
          "approval_status",
          "review_status",
          "suppressed_reason"
        ],
        &{&1, &1}
      )
  ]
  @source_review_field_pairs Enum.map(@source_field_pairs, fn {row_field, _source_field} ->
                               {row_field, row_field}
                             end) ++
                               Enum.map(
                                 [
                                   "subject_id",
                                   "activity_id",
                                   "branch_id",
                                   "contact_result",
                                   "command_result",
                                   "required_operator_action",
                                   "reason",
                                   "requirement_type",
                                   "required_authority",
                                   "policy_bundle_id",
                                   "rule_id",
                                   "escalation_level",
                                   "escalation_queue",
                                   "escalation_role",
                                   "sla_s",
                                   "approval_requirements",
                                   "approval_rule_matches",
                                   "source_policy_decision",
                                   "source_policy_escalation",
                                   "cadence_import_status",
                                   "has_cadence_import"
                                 ],
                                 &{&1, &1}
                               )

  def validate_cadence_source_review_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if handoff_row?(row) do
      Enum.reduce(@source_review_field_pairs, issues, fn {source_field, row_field}, acc ->
        row_value = Map.get(row, row_field)
        source_value = Map.get(source_review_row, source_field)

        if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
          [
            error(
              "#{path}.source_review_row.#{source_field}",
              "must match #{row_field} on Cadence import row"
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

  def validate_matches_source(issues, path, row) do
    case source(row) do
      {source_key, source_row} ->
        Enum.reduce(@source_field_pairs, issues, fn {row_field, source_field}, acc ->
          row_value = Map.get(row, row_field)
          source_value = Map.get(source_row, source_field)

          if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
            [
              error(
                "#{path}.#{row_field}",
                "must match #{source_key}.#{source_field}"
              )
              | acc
            ]
          else
            acc
          end
        end)

      nil ->
        issues
    end
  end

  def source(row) do
    if handoff_row?(row) do
      cond do
        is_map(Map.get(row, "source_contact_suppression")) ->
          {"source_contact_suppression", Map.get(row, "source_contact_suppression")}

        is_map(Map.get(row, "source_resource_suppression")) ->
          {"source_resource_suppression", Map.get(row, "source_resource_suppression")}

        true ->
          nil
      end
    end
  end

  def handoff_row?(row) do
    Map.get(row, "review_type") in ["contact_suppression", "resource_suppression"] or
      Map.get(row, "source_review_type") in ["contact_suppression", "resource_suppression"] or
      Map.get(row, "import_action") in [
        "review_contact_suppression",
        "review_resource_suppression"
      ]
  end

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
