defmodule OrbitalDynamics.Schema.RiskFeedbackHandoffContracts do
  @moduledoc false

  @risk_explanation_source_field_pairs [
    {"subject_id", "type"},
    {"risk_type", "type"},
    {"severity", "severity"},
    {"reason", "reason"},
    {"value", "value"},
    {"branch_id", "branch_id"},
    {"scenario_id", "scenario_id"},
    {"activity_id", "activity_id"},
    {"activity_type", "activity_type"},
    {"ground_station_id", "ground_station_id"},
    {"spacecraft_id", "spacecraft_id"},
    {"target_id", "target_id"},
    {"collection_id", "collection_id"},
    {"product_id", "product_id"},
    {"product_ids", "product_ids"},
    {"payload_id", "payload_id"},
    {"instrument_id", "instrument_id"},
    {"objective_id", "objective_id"},
    {"objective_type", "objective_type"},
    {"objective_status", "objective_status"},
    {"source_objective_status", "source_objective_status"},
    {"latency_objective", "latency_objective"},
    {"max_latency_s", "max_latency_s"},
    {"planned_latency_s", "planned_latency_s"},
    {"required_contacts", "required_contacts"},
    {"planned_contacts", "planned_contacts"},
    {"required_downlink_mb", "required_downlink_mb"},
    {"planned_downlink_mb", "planned_downlink_mb"},
    {"contact_result", "contact_result"},
    {"realized_status", "realized_status"},
    {"source_activity_id", "source_activity_id"},
    {"source_activity_ids", "source_activity_ids"},
    {"missed_downlink_activity_id", "missed_downlink_activity_id"},
    {"missed_downlink_activity_ids", "missed_downlink_activity_ids"},
    {"feedback_source", "feedback_source"},
    {"feedback_scope", "feedback_scope"},
    {"trust_boundary", "trust_boundary"},
    {"derivation_reasons", "derivation_reasons"},
    {"direction", "direction"},
    {"station_calendar_entry_id", "station_calendar_entry_id"},
    {"station_calendar_provider_id", "station_calendar_provider_id"},
    {"station_calendar_provider_entry_id", "station_calendar_provider_entry_id"},
    {"station_calendar_directions", "station_calendar_directions"},
    {"first_resource_pressure_activity_id", "first_resource_pressure_activity_id"},
    {"first_resource_pressure_activity_type", "first_resource_pressure_activity_type"},
    {"first_resource_pressure_kind", "first_resource_pressure_kind"},
    {"first_resource_pressure_starts_at_s", "first_resource_pressure_starts_at_s"},
    {"first_resource_pressure_direction", "first_resource_pressure_direction"},
    {"first_resource_pressure_ground_station_id", "first_resource_pressure_ground_station_id"},
    {"first_resource_pressure_station_calendar_entry_id",
     "first_resource_pressure_station_calendar_entry_id"},
    {"first_resource_pressure_station_calendar_provider_id",
     "first_resource_pressure_station_calendar_provider_id"},
    {"first_resource_pressure_station_calendar_provider_entry_id",
     "first_resource_pressure_station_calendar_provider_entry_id"},
    {"first_resource_pressure_station_calendar_directions",
     "first_resource_pressure_station_calendar_directions"},
    {"first_resource_pressure_capacity_fraction", "first_resource_pressure_capacity_fraction"},
    {"first_resource_pressure_source_window_id", "first_resource_pressure_source_window_id"},
    {"first_resource_pressure_source_window_type", "first_resource_pressure_source_window_type"},
    {"first_resource_pressure_source_window", "first_resource_pressure_source_window"},
    {"source_window_id", "source_window_id"},
    {"source_window_type", "source_window_type"},
    {"source_window", "source_window"}
  ]
  @risk_explanation_source_review_fields Enum.map(
                                           [
                                             "subject_id",
                                             "risk_type",
                                             "severity",
                                             "reason",
                                             "value",
                                             "branch_id",
                                             "scenario_id",
                                             "activity_id",
                                             "activity_type",
                                             "ground_station_id",
                                             "spacecraft_id",
                                             "target_id",
                                             "collection_id",
                                             "product_id",
                                             "product_ids",
                                             "payload_id",
                                             "instrument_id",
                                             "objective_id",
                                             "objective_type",
                                             "objective_status",
                                             "source_objective_status",
                                             "latency_objective",
                                             "max_latency_s",
                                             "planned_latency_s",
                                             "required_contacts",
                                             "planned_contacts",
                                             "required_downlink_mb",
                                             "planned_downlink_mb",
                                             "contact_result",
                                             "realized_status",
                                             "source_activity_id",
                                             "source_activity_ids",
                                             "missed_downlink_activity_id",
                                             "missed_downlink_activity_ids",
                                             "feedback_source",
                                             "feedback_scope",
                                             "trust_boundary",
                                             "derivation_reasons",
                                             "direction",
                                             "station_calendar_entry_id",
                                             "station_calendar_provider_id",
                                             "station_calendar_provider_entry_id",
                                             "station_calendar_directions",
                                             "first_resource_pressure_activity_id",
                                             "first_resource_pressure_activity_type",
                                             "first_resource_pressure_kind",
                                             "first_resource_pressure_starts_at_s",
                                             "first_resource_pressure_direction",
                                             "first_resource_pressure_ground_station_id",
                                             "first_resource_pressure_station_calendar_entry_id",
                                             "first_resource_pressure_station_calendar_provider_id",
                                             "first_resource_pressure_station_calendar_provider_entry_id",
                                             "first_resource_pressure_station_calendar_directions",
                                             "first_resource_pressure_capacity_fraction",
                                             "first_resource_pressure_source_window_id",
                                             "first_resource_pressure_source_window_type",
                                             "first_resource_pressure_source_window",
                                             "source_window_id",
                                             "source_window_type",
                                             "source_window",
                                             "source_risk"
                                           ],
                                           &{&1, &1}
                                         )
  @realized_feedback_source_field_pairs [
    {"subject_id", "activity_id"},
    {"activity_id", "activity_id"},
    {"feedback_status", "status"},
    {"operational_feedback_excluded", "operational_feedback_excluded"},
    {"operational_feedback_status", "operational_feedback_status"},
    {"operational_feedback_exclusion_reason", "operational_feedback_exclusion_reason"},
    {"match_strategy", "match_strategy"},
    {"ambiguous_planned_timeline_id", "ambiguous_planned_timeline_id"},
    {"ambiguous_planned_match_count", "ambiguous_planned_match_count"},
    {"ambiguous_planned_activity_ids", "ambiguous_planned_activity_ids"},
    {"feedback_kind", "feedback_kind"},
    {"realized_match_count", "realized_match_count"},
    {"realized_activity_ids", "realized_activity_ids"},
    {"realized_statuses", "realized_statuses"},
    {"realized_match_strategies", "realized_match_strategies"},
    {"planned_timeline_id", "planned_timeline_id"},
    {"realized_timeline_id", "realized_timeline_id"},
    {"realized_activity_id", "realized_activity_id"},
    {"realized_source_quality", "realized_source_quality"},
    {"realized_provider", "realized_provider"},
    {"realized_adapter", "realized_adapter"},
    {"realized_adapter_version", "realized_adapter_version"},
    {"realized_external_id", "realized_external_id"},
    {"realized_schema_contract", "realized_schema_contract"},
    {"realized_trust_boundary", "realized_trust_boundary"},
    {"realized_received_at", "realized_received_at"},
    {"realized_ingested_at", "realized_ingested_at"},
    {"invalid_realized_feedback_input", "invalid_realized_feedback_input"},
    {"invalid_realized_feedback_input_reason", "invalid_realized_feedback_input_reason"},
    {"invalid_realized_feedback_sections", "invalid_realized_feedback_sections"},
    {"unsupported_realized_status", "unsupported_realized_status"},
    {"invalid_cadence_import", "invalid_cadence_import"},
    {"invalid_cadence_import_reason", "invalid_cadence_import_reason"},
    {"planned_status", "planned_status"},
    {"realized_status", "realized_status"},
    {"status_transition", "status_transition"},
    {"realized_type", "realized_type"},
    {"direction", "direction"},
    {"planned_direction", "planned_direction"},
    {"realized_direction", "realized_direction"},
    {"direction_match_status", "direction_match_status"},
    {"ground_station_id", "ground_station_id"},
    {"planned_ground_station_id", "planned_ground_station_id"},
    {"realized_ground_station_id", "realized_ground_station_id"},
    {"ground_station_match_status", "ground_station_match_status"},
    {"spacecraft_id", "spacecraft_id"},
    {"target_id", "target_id"},
    {"planned_target_id", "planned_target_id"},
    {"realized_target_id", "realized_target_id"},
    {"target_match_status", "target_match_status"},
    {"cadence_import_status", "cadence_import_status"},
    {"cadence_import_type", "cadence_import_type"},
    {"cadence_import_id", "cadence_import_id"},
    {"cadence_import_contract", "cadence_import_contract"},
    {"has_cadence_import", "has_cadence_import"},
    {"command_authority_status", "command_authority_status"},
    {"planned_command_authority_status", "planned_command_authority_status"},
    {"realized_command_authority_status", "realized_command_authority_status"},
    {"command_authority_status_match_status", "command_authority_status_match_status"},
    {"required_authority", "required_authority"},
    {"planned_required_authority", "planned_required_authority"},
    {"realized_required_authority", "realized_required_authority"},
    {"required_authority_match_status", "required_authority_match_status"},
    {"command_safety_status", "command_safety_status"},
    {"planned_command_safety_status", "planned_command_safety_status"},
    {"realized_command_safety_status", "realized_command_safety_status"},
    {"command_safety_status_match_status", "command_safety_status_match_status"},
    {"command_authorized", "command_authorized"},
    {"planned_command_authorized", "planned_command_authorized"},
    {"realized_command_authorized", "realized_command_authorized"},
    {"command_authorized_match_status", "command_authorized_match_status"},
    {"command_safety_checked", "command_safety_checked"},
    {"planned_command_safety_checked", "planned_command_safety_checked"},
    {"realized_command_safety_checked", "realized_command_safety_checked"},
    {"command_safety_checked_match_status", "command_safety_checked_match_status"}
  ]
  @realized_feedback_source_review_fields Enum.map(
                                            [
                                              "subject_id",
                                              "activity_id",
                                              "feedback_status",
                                              "operational_feedback_excluded",
                                              "operational_feedback_status",
                                              "operational_feedback_exclusion_reason",
                                              "match_strategy",
                                              "ambiguous_planned_timeline_id",
                                              "ambiguous_planned_match_count",
                                              "ambiguous_planned_activity_ids",
                                              "feedback_kind",
                                              "realized_match_count",
                                              "realized_activity_ids",
                                              "realized_statuses",
                                              "realized_match_strategies",
                                              "planned_timeline_id",
                                              "realized_timeline_id",
                                              "realized_activity_id",
                                              "realized_source_quality",
                                              "realized_provider",
                                              "realized_adapter",
                                              "realized_adapter_version",
                                              "realized_external_id",
                                              "realized_schema_contract",
                                              "realized_trust_boundary",
                                              "realized_received_at",
                                              "realized_ingested_at",
                                              "invalid_realized_feedback_input",
                                              "invalid_realized_feedback_input_reason",
                                              "invalid_realized_feedback_sections",
                                              "unsupported_realized_status",
                                              "invalid_cadence_import",
                                              "invalid_cadence_import_reason",
                                              "planned_status",
                                              "realized_status",
                                              "status_transition",
                                              "realized_type",
                                              "direction",
                                              "planned_direction",
                                              "realized_direction",
                                              "direction_match_status",
                                              "ground_station_id",
                                              "planned_ground_station_id",
                                              "realized_ground_station_id",
                                              "ground_station_match_status",
                                              "spacecraft_id",
                                              "target_id",
                                              "planned_target_id",
                                              "realized_target_id",
                                              "target_match_status",
                                              "cadence_import_status",
                                              "cadence_import_type",
                                              "cadence_import_id",
                                              "cadence_import_contract",
                                              "has_cadence_import",
                                              "command_authority_status",
                                              "planned_command_authority_status",
                                              "realized_command_authority_status",
                                              "command_authority_status_match_status",
                                              "required_authority",
                                              "planned_required_authority",
                                              "realized_required_authority",
                                              "required_authority_match_status",
                                              "command_safety_status",
                                              "planned_command_safety_status",
                                              "realized_command_safety_status",
                                              "command_safety_status_match_status",
                                              "command_authorized",
                                              "planned_command_authorized",
                                              "realized_command_authorized",
                                              "command_authorized_match_status",
                                              "command_safety_checked",
                                              "planned_command_safety_checked",
                                              "realized_command_safety_checked",
                                              "command_safety_checked_match_status",
                                              "spacecraft_available",
                                              "planned_spacecraft_available",
                                              "realized_spacecraft_available",
                                              "spacecraft_available_match_status",
                                              "payload_available",
                                              "planned_payload_available",
                                              "realized_payload_available",
                                              "payload_available_match_status",
                                              "antenna_available",
                                              "planned_antenna_available",
                                              "realized_antenna_available",
                                              "antenna_available_match_status",
                                              "degraded",
                                              "planned_degraded",
                                              "realized_degraded",
                                              "degraded_match_status",
                                              "mode",
                                              "planned_mode",
                                              "realized_mode",
                                              "mode_match_status"
                                            ],
                                            &{&1, &1}
                                          )

  def validate_risk_explanation_matches_source(
        issues,
        path,
        %{"source_risk" => %{} = source_row} = row
      ) do
    if risk_explanation_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @risk_explanation_source_field_pairs,
        "source_risk"
      )
    else
      issues
    end
  end

  def validate_risk_explanation_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_risk_explanation_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if risk_explanation_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @risk_explanation_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_risk_explanation_matches(issues, _path, _row), do: issues

  def validate_realized_feedback_matches_source(
        issues,
        path,
        %{"source_feedback" => %{} = source_row} = row
      ) do
    if realized_feedback_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @realized_feedback_source_field_pairs,
        "source_feedback"
      )
    else
      issues
    end
  end

  def validate_realized_feedback_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_realized_feedback_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if realized_feedback_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @realized_feedback_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_realized_feedback_matches(issues, _path, _row), do: issues

  def risk_explanation_handoff_row?(row) do
    Map.get(row, "review_type") == "risk_explanation" or
      Map.get(row, "source_review_type") == "risk_explanation" or
      Map.get(row, "import_action") == "review_risk"
  end

  def realized_feedback_handoff_row?(row) do
    Map.get(row, "review_type") == "realized_feedback" or
      Map.get(row, "source_review_type") == "realized_feedback" or
      Map.get(row, "import_action") in ["record_realized_feedback", "review_realized_feedback"]
  end

  defp validate_source_pairs(issues, path, row, source_row, field_pairs, source_key) do
    Enum.reduce(field_pairs, issues, fn {row_field, source_field}, acc ->
      row_value = Map.get(row, row_field)
      source_value = Map.get(source_row, source_field)

      if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
        [error("#{path}.#{row_field}", "must match #{source_key}.#{source_field}") | acc]
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
