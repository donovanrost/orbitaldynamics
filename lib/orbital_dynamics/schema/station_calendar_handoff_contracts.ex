defmodule OrbitalDynamics.Schema.StationCalendarHandoffContracts do
  @moduledoc false

  @source_field_pairs [
    {"contact_id", "contact_id"},
    {"scenario_id", "scenario_id"},
    {"activity_type", "contact_type"},
    {"direction", "direction"},
    {"ground_station_id", "ground_station_id"},
    {"starts_at_s", "starts_at_s"},
    {"ends_at_s", "ends_at_s"},
    {"station_calendar_entry_id", "station_calendar_entry_id"},
    {"station_calendar_provider_id", "station_calendar_provider_id"},
    {"station_calendar_provider_entry_id", "station_calendar_provider_entry_id"},
    {"station_calendar_directions", "station_calendar_directions"},
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
    {"status", "status"},
    {"station_availability", "station_availability"},
    {"capacity_fraction", "capacity_fraction"},
    {"station_contention_status", "station_contention_status"},
    {"station_reservation_id", "station_reservation_id"},
    {"station_reservation_expires_at_s", "station_reservation_expires_at_s"},
    {"station_reserved_by", "station_reserved_by"},
    {"station_reservation_status", "station_reservation_status"},
    {"station_reservation_match_status", "station_reservation_match_status"},
    {"base_station_calendar_row_id", "base_station_calendar_row_id"},
    {"duplicate_station_calendar_row_id_collision",
     "duplicate_station_calendar_row_id_collision"},
    {"duplicate_station_calendar_row_index", "duplicate_station_calendar_row_index"},
    {"duplicate_station_calendar_row_count", "duplicate_station_calendar_row_count"},
    {"invalid_feedback_confidence", "invalid_feedback_confidence"},
    {"invalid_feedback_confidence_reason", "invalid_feedback_confidence_reason"},
    {"approval_status", "approval_status"},
    {"operator_action_reason", "operator_action_reason"}
  ]
  @match_field_pairs Enum.map(@source_field_pairs, fn {row_field, _source_field} ->
                       {row_field, row_field}
                     end)
  @context_source_review_field_pairs Enum.map(
                                       [
                                         "branch_id",
                                         "subject_id",
                                         "contact_success",
                                         "contact_success_factor",
                                         "contact_success_factor_source",
                                         "command_success",
                                         "contact_result",
                                         "command_result",
                                         "command_success_factor",
                                         "command_success_factor_source",
                                         "provider_counteroffer_id",
                                         "provider_counteroffer_status",
                                         "provider_counteroffer_negotiation_state",
                                         "provider_counteroffer_reason_code",
                                         "provider_counteroffer_cost_delta",
                                         "provider_counteroffer_lock_deadline_s",
                                         "provider_counteroffer_starts_at_s",
                                         "provider_counteroffer_ends_at_s",
                                         "provider_counteroffer_start_delta_s",
                                         "provider_counteroffer_end_delta_s",
                                         "provider_counteroffer_duration_delta_s",
                                         "import_status",
                                         "source_review_action",
                                         "required_operator_action",
                                         "escalation_level",
                                         "escalation_queue",
                                         "escalation_role",
                                         "required_authority",
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
  @source_review_field_pairs @match_field_pairs ++ @context_source_review_field_pairs

  def validate_matches_source(issues, path, row) do
    source_row =
      Map.get(row, "source_station_calendar_review") ||
        Map.get(row, "source_station_reservation")

    if source_handoff_row?(row) and is_map(source_row) do
      Enum.reduce(@source_field_pairs, issues, fn {row_field, source_field}, acc ->
        row_value = Map.get(row, row_field)
        source_value = Map.get(source_row, source_field)

        if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
          [
            error("#{path}.#{row_field}", "must match station calendar source #{source_field}")
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

  def validate_cadence_source_review_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if source_handoff_row?(row) do
      Enum.reduce(@source_review_field_pairs, issues, fn {source_field, row_field}, acc ->
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
    else
      issues
    end
  end

  def validate_cadence_source_review_matches(issues, _path, _row), do: issues

  def validate_count_lists(issues, path, row, callbacks) when is_list(callbacks) do
    if source_handoff_row?(row) do
      issues
      |> expect_field_matches_list_count(
        callbacks,
        path,
        row,
        "station_calendar_overlap_count",
        "station_calendar_overlap_entry_ids",
        "must equal length of station_calendar_overlap_entry_ids"
      )
      |> expect_field_matches_list_count(
        callbacks,
        path,
        row,
        "station_calendar_ambiguous_entry_count",
        "station_calendar_ambiguous_entry_ids",
        "must equal length of station_calendar_ambiguous_entry_ids"
      )
      |> expect_field_matches_list_count(
        callbacks,
        path,
        row,
        "station_calendar_reservation_overlap_count",
        "station_calendar_reservation_ids",
        "must equal length of station_calendar_reservation_ids"
      )
      |> expect_field_matches_list_count(
        callbacks,
        path,
        row,
        "provider_calendar_contention_entry_count",
        "provider_calendar_contention_entry_ids",
        "must equal length of provider_calendar_contention_entry_ids"
      )
    else
      issues
    end
  end

  def source_handoff_row?(row) do
    Map.get(row, "review_type") in ["station_calendar_review", "station_reservation_review"] or
      Map.get(row, "source_review_type") in [
        "station_calendar_review",
        "station_reservation_review"
      ] or
      Map.get(row, "import_action") in ["review_station_calendar", "review_station_reservation"]
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
