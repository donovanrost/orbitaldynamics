defmodule OrbitalDynamics.Schema.ContactReviewHandoffContracts do
  @moduledoc false

  @provider_counteroffer_source_field_pairs [
    {"provider_counteroffer_id", "provider_counteroffer_id"},
    {"provider_counteroffer_status", "provider_counteroffer_status"},
    {"provider_counteroffer_negotiation_state", "provider_counteroffer_negotiation_state"},
    {"provider_counteroffer_reason_code", "provider_counteroffer_reason_code"},
    {"provider_counteroffer_cost_delta", "provider_counteroffer_cost_delta"},
    {"provider_counteroffer_lock_deadline_s", "provider_counteroffer_lock_deadline_s"},
    {"provider_counteroffer_starts_at_s", "provider_counteroffer_starts_at_s"},
    {"provider_counteroffer_ends_at_s", "provider_counteroffer_ends_at_s"},
    {"provider_counteroffer_start_delta_s", "provider_counteroffer_start_delta_s"},
    {"provider_counteroffer_end_delta_s", "provider_counteroffer_end_delta_s"},
    {"provider_counteroffer_duration_delta_s", "provider_counteroffer_duration_delta_s"},
    {"ground_station_id", "ground_station_id"},
    {"starts_at_s", "starts_at_s"},
    {"ends_at_s", "ends_at_s"},
    {"station_calendar_entry_id", "station_calendar_entry_id"},
    {"station_calendar_provider_id", "station_calendar_provider_id"},
    {"station_calendar_provider_entry_id", "station_calendar_provider_entry_id"},
    {"station_availability", "station_availability"},
    {"required_operator_action", "required_operator_action"}
  ]
  @provider_counteroffer_context_source_review_field_pairs Enum.map(
                                                             [
                                                               "subject_id",
                                                               "approval_status",
                                                               "cadence_import_status"
                                                             ],
                                                             &{&1, &1}
                                                           )
  @provider_counteroffer_source_review_field_pairs @provider_counteroffer_source_field_pairs ++
                                                     @provider_counteroffer_context_source_review_field_pairs

  @contact_intent_source_field_pairs [
    {"activity_id", "activity_id"},
    {"timeline_id", "timeline_id"},
    {"scenario_id", "scenario_id"},
    {"spacecraft_id", "spacecraft_id"},
    {"activity_type", "activity_type"},
    {"direction", "direction"},
    {"ground_station_id", "ground_station_id"},
    {"starts_at_s", "starts_at_s"},
    {"ends_at_s", "ends_at_s"},
    {"estimated_throughput_mb", "estimated_throughput_mb"},
    {"station_availability", "station_availability"},
    {"capacity_fraction", "capacity_fraction"},
    {"capacity_fraction_min", "capacity_fraction_min"},
    {"capacity_fraction_max", "capacity_fraction_max"},
    {"required_capacity_fraction", "required_capacity_fraction"},
    {"required_capacity_fraction_source", "required_capacity_fraction_source"},
    {"station_contention_status", "station_contention_status"},
    {"station_calendar_entry_id", "station_calendar_entry_id"},
    {"station_calendar_directions", "station_calendar_directions"},
    {"station_calendar_status", "station_calendar_status"},
    {"station_calendar_overlap_count", "station_calendar_overlap_count"},
    {"station_calendar_overlap_entry_ids", "station_calendar_overlap_entry_ids"},
    {"station_calendar_overlap_availabilities", "station_calendar_overlap_availabilities"},
    {"station_calendar_entry_ambiguous", "station_calendar_entry_ambiguous"},
    {"station_calendar_ambiguous_entry_count", "station_calendar_ambiguous_entry_count"},
    {"station_calendar_ambiguous_entry_ids", "station_calendar_ambiguous_entry_ids"},
    {"station_calendar_reservation_overlap_count", "station_calendar_reservation_overlap_count"},
    {"station_calendar_reservation_ids", "station_calendar_reservation_ids"},
    {"station_calendar_reserved_by", "station_calendar_reserved_by"},
    {"station_calendar_reservation_statuses", "station_calendar_reservation_statuses"},
    {"station_calendar_reservation_expires_at_s", "station_calendar_reservation_expires_at_s"},
    {"station_calendar_trust_boundary_status", "station_calendar_trust_boundary_status"},
    {"trust_boundary", "trust_boundary"},
    {"station_reservation_id", "station_reservation_id"},
    {"station_reservation_expires_at_s", "station_reservation_expires_at_s"},
    {"station_reserved_by", "station_reserved_by"},
    {"station_reservation_status", "station_reservation_status"},
    {"station_reservation_match_status", "station_reservation_match_status"},
    {"schedule_conflict_status", "schedule_conflict_status"},
    {"dependency_activity_ids", "dependency_activity_ids"},
    {"dependency_timeline_ids", "dependency_timeline_ids"},
    {"exclusive_with_activity_ids", "exclusive_with_activity_ids"},
    {"exclusive_with_timeline_ids", "exclusive_with_timeline_ids"},
    {"source_window_id", "source_window_id"},
    {"invalid_activity_input", "invalid_activity_input"},
    {"invalid_activity_input_reason", "invalid_activity_input_reason"},
    {"approval_status", "approval_status"},
    {"timeline_identity", "timeline_identity"}
  ]
  @contact_intent_context_source_review_field_pairs Enum.map(
                                                      [
                                                        "subject_id",
                                                        "branch_id",
                                                        "contact_id",
                                                        "contact_success",
                                                        "contact_success_factor",
                                                        "contact_success_factor_source",
                                                        "command_success",
                                                        "command_success_factor",
                                                        "command_success_factor_source",
                                                        "cadence_import_status",
                                                        "cadence_import_type",
                                                        "cadence_import_id",
                                                        "cadence_import_contract",
                                                        "has_cadence_import",
                                                        "required_operator_action",
                                                        "requirement_type",
                                                        "required_authority",
                                                        "policy_bundle_id",
                                                        "rule_id",
                                                        "escalation_level",
                                                        "escalation_queue",
                                                        "escalation_role",
                                                        "sla_s",
                                                        "reason"
                                                      ],
                                                      &{&1, &1}
                                                    )
  @contact_intent_source_review_field_pairs @contact_intent_source_field_pairs ++
                                              @contact_intent_context_source_review_field_pairs

  def validate_provider_counteroffer_matches_source(
        issues,
        path,
        %{"source_provider_counteroffer" => %{} = source_row} = row
      ) do
    if provider_counteroffer_handoff_row?(row) do
      reduce_source_pairs(
        @provider_counteroffer_source_field_pairs,
        issues,
        path,
        row,
        source_row,
        "source_provider_counteroffer"
      )
    else
      issues
    end
  end

  def validate_provider_counteroffer_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_provider_counteroffer_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if provider_counteroffer_handoff_row?(row) do
      reduce_source_review_pairs(
        @provider_counteroffer_source_review_field_pairs,
        issues,
        path,
        row,
        source_review_row
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_provider_counteroffer_matches(issues, _path, _row),
    do: issues

  def validate_contact_intent_matches_source(
        issues,
        path,
        %{"source_contact_intent" => %{} = source_row} = row
      ) do
    if contact_intent_handoff_row?(row) do
      reduce_source_pairs(
        @contact_intent_source_field_pairs,
        issues,
        path,
        row,
        source_row,
        "source_contact_intent"
      )
    else
      issues
    end
  end

  def validate_contact_intent_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_contact_intent_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if contact_intent_handoff_row?(row) do
      reduce_source_review_pairs(
        @contact_intent_source_review_field_pairs,
        issues,
        path,
        row,
        source_review_row
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_contact_intent_matches(issues, _path, _row), do: issues

  def provider_counteroffer_handoff_row?(row) do
    Map.get(row, "review_type") == "provider_counteroffer_review" or
      Map.get(row, "source_review_type") == "provider_counteroffer_review" or
      Map.get(row, "import_action") == "review_provider_counteroffer"
  end

  def contact_intent_handoff_row?(row) do
    Map.get(row, "review_type") == "contact_intent_review" or
      Map.get(row, "source_review_type") == "contact_intent_review" or
      Map.get(row, "import_action") == "review_contact_intent"
  end

  defp reduce_source_pairs(pairs, issues, path, row, source_row, source_key) do
    Enum.reduce(pairs, issues, fn {row_field, source_field}, acc ->
      row_value = Map.get(row, row_field)
      source_value = Map.get(source_row, source_field)

      if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
        [error("#{path}.#{row_field}", "must match #{source_key}.#{source_field}") | acc]
      else
        acc
      end
    end)
  end

  defp reduce_source_review_pairs(pairs, issues, path, row, source_review_row) do
    Enum.reduce(pairs, issues, fn {source_field, row_field}, acc ->
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
