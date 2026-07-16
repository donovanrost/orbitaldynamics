defmodule OrbitalDynamics.Schema.CommandWindowManeuverHandoffContracts do
  @moduledoc false

  @command_window_source_field_pairs [
    {"activity_id", "activity_id"},
    {"timeline_id", "timeline_id"},
    {"scenario_id", "scenario_id"},
    {"activity_type", "activity_type"},
    {"window_type", "window_type"},
    {"direction", "direction"},
    {"ground_station_id", "ground_station_id"},
    {"starts_at_s", "starts_at_s"},
    {"ends_at_s", "ends_at_s"},
    {"status", "status"},
    {"source_approval_status", "approval_status"},
    {"locked", "locked"},
    {"contact_success", "contact_success"},
    {"command_success", "command_success"},
    {"command_success_factor", "command_success_factor"},
    {"command_success_factor_source", "command_success_factor_source"},
    {"station_availability", "station_availability"},
    {"capacity_fraction", "capacity_fraction"},
    {"station_contention_status", "station_contention_status"},
    {"station_calendar_entry_id", "station_calendar_entry_id"},
    {"station_calendar_provider_id", "station_calendar_provider_id"},
    {"station_calendar_provider_entry_id", "station_calendar_provider_entry_id"},
    {"station_calendar_directions", "station_calendar_directions"},
    {"station_calendar_status", "station_calendar_status"},
    {"station_calendar_trust_boundary_status", "station_calendar_trust_boundary_status"},
    {"trust_boundary", "trust_boundary"},
    {"station_calendar_reservation_overlap_count", "station_calendar_reservation_overlap_count"},
    {"station_calendar_reservation_ids", "station_calendar_reservation_ids"},
    {"station_calendar_reserved_by", "station_calendar_reserved_by"},
    {"station_calendar_reservation_statuses", "station_calendar_reservation_statuses"},
    {"station_calendar_reservation_expires_at_s", "station_calendar_reservation_expires_at_s"},
    {"station_reservation_id", "station_reservation_id"},
    {"station_reservation_expires_at_s", "station_reservation_expires_at_s"},
    {"station_reserved_by", "station_reserved_by"},
    {"station_reservation_status", "station_reservation_status"},
    {"station_reservation_match_status", "station_reservation_match_status"},
    {"required_operator_action", "required_operator_action"},
    {"operator_action_reason", "operator_action_reason"},
    {"execution_boundary", "execution_boundary"},
    {"cadence_import_status", "cadence_import_status"},
    {"cadence_import_type", "cadence_import_type"},
    {"dependency_activity_ids", "dependency_activity_ids"},
    {"dependency_timeline_ids", "dependency_timeline_ids"},
    {"exclusive_with_activity_ids", "exclusive_with_activity_ids"},
    {"exclusive_with_timeline_ids", "exclusive_with_timeline_ids"},
    {"source_window_id", "source_window_id"},
    {"source_window_type", "source_window_type"},
    {"has_source_window", "has_source_window"},
    {"has_cadence_import", "has_cadence_import"},
    {"timeline_identity", "timeline_identity"}
  ]
  @command_window_match_field_pairs Enum.map(
                                      @command_window_source_field_pairs,
                                      fn
                                        {"source_approval_status", "approval_status"} ->
                                          {"approval_status", "approval_status"}

                                        pair ->
                                          pair
                                      end
                                    )
  @command_window_context_source_review_field_pairs Enum.map(
                                                      [
                                                        "contact_result",
                                                        "command_result",
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
                                                        "source_activity_context"
                                                      ],
                                                      &{&1, &1}
                                                    )
  @command_window_source_review_field_pairs @command_window_match_field_pairs ++
                                              @command_window_context_source_review_field_pairs
  @maneuver_review_source_field_pairs [
    {"subject_id", "maneuver_id"},
    {"maneuver_id", "maneuver_id"},
    {"scenario_id", "scenario_id"},
    {"maneuver_type", "maneuver_type"},
    {"epoch_s", "epoch_s"},
    {"epoch_scale", "epoch_scale"},
    {"frame", "frame"},
    {"delta_v_km_s", "delta_v_km_s"},
    {"delta_v_magnitude_km_s", "delta_v_magnitude_km_s"},
    {"maneuver_model", "maneuver_model"},
    {"maneuver_success_factor", "maneuver_success_factor"},
    {"maneuver_success_factor_source", "maneuver_success_factor_source"},
    {"approval_status", "approval_status"},
    {"required_operator_action", "required_operator_action"},
    {"reason", "reason"},
    {"execution_boundary", "execution_boundary"},
    {"approval_requirements", "approval_requirements"},
    {"approval_rule_matches", "approval_rule_matches"},
    {"source_recommendation", "source_recommendation"}
  ]
  @maneuver_review_source_review_fields Enum.map(
                                          [
                                            "subject_id",
                                            "maneuver_id",
                                            "scenario_id",
                                            "maneuver_type",
                                            "epoch_s",
                                            "epoch_scale",
                                            "frame",
                                            "delta_v_km_s",
                                            "delta_v_magnitude_km_s",
                                            "maneuver_model",
                                            "maneuver_success_factor",
                                            "maneuver_success_factor_source",
                                            "approval_status",
                                            "required_operator_action",
                                            "reason",
                                            "execution_boundary",
                                            "approval_requirements",
                                            "approval_rule_matches",
                                            "source_policy_decision",
                                            "source_policy_escalation",
                                            "source_recommendation",
                                            "source_maneuver_review"
                                          ],
                                          &{&1, &1}
                                        )

  def validate_command_window_matches_source(
        issues,
        path,
        %{"source_command_window" => %{} = source_row} = row
      ) do
    if command_window_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @command_window_source_field_pairs,
        "source_command_window"
      )
    else
      issues
    end
  end

  def validate_command_window_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_command_window_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if command_window_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @command_window_source_review_field_pairs
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_command_window_matches(issues, _path, _row),
    do: issues

  def validate_maneuver_review_matches_source(
        issues,
        path,
        %{"source_maneuver_review" => %{} = source_row} = row
      ) do
    if maneuver_review_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @maneuver_review_source_field_pairs,
        "source_maneuver_review"
      )
    else
      issues
    end
  end

  def validate_maneuver_review_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_maneuver_review_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if maneuver_review_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @maneuver_review_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_maneuver_review_matches(issues, _path, _row),
    do: issues

  def command_window_handoff_row?(row) do
    Map.get(row, "review_type") == "command_window_review" or
      Map.get(row, "source_review_type") == "command_window_review" or
      Map.get(row, "import_action") == "review_command_window"
  end

  def maneuver_review_handoff_row?(row) do
    Map.get(row, "review_type") == "maneuver_review" or
      Map.get(row, "source_review_type") == "maneuver_review" or
      Map.get(row, "import_action") == "review_maneuver"
  end

  defp validate_source_pairs(issues, path, row, source_row, field_pairs, source_key) do
    Enum.reduce(field_pairs, issues, fn {row_field, source_field}, acc ->
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
  end

  defp validate_cadence_source_review_pairs(
         issues,
         path,
         row,
         source_review_row,
         field_pairs
       ) do
    Enum.reduce(field_pairs, issues, fn {source_field, row_field}, acc ->
      source_value = Map.get(source_review_row, source_field)
      row_value = Map.get(row, row_field)

      if not is_nil(source_value) and not is_nil(row_value) and source_value != row_value do
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
  end

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
