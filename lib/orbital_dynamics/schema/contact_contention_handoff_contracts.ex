defmodule OrbitalDynamics.Schema.ContactContentionHandoffContracts do
  @moduledoc false

  @station_calendar_context_fields [
    "station_availability",
    "station_calendar_status",
    "capacity_fraction",
    "capacity_fraction_min",
    "capacity_fraction_max",
    "station_calendar_entry_ids",
    "station_calendar_provider_ids",
    "station_calendar_provider_entry_ids",
    "station_calendar_overlap_entry_ids",
    "station_calendar_directions",
    "station_calendar_reservation_ids",
    "station_calendar_reserved_by",
    "station_calendar_reservation_statuses",
    "station_calendar_reservation_expires_at_s",
    "station_calendar_trust_boundary_statuses",
    "station_reservation_ids",
    "station_reservation_expires_at_s",
    "station_reserved_bys",
    "station_reservation_statuses",
    "station_reservation_match_statuses"
  ]
  @provider_result_fields [
    "contact_result",
    "command_result"
  ]
  @group_source_field_pairs [
                              {"subject_id", "id"}
                              | Enum.map(
                                  [
                                    "resource_scope",
                                    "ground_station_id",
                                    "ground_station_ids",
                                    "spacecraft_id",
                                    "spacecraft_ids",
                                    "starts_at_s",
                                    "ends_at_s",
                                    "direction",
                                    "directions",
                                    "contact_count",
                                    "contention_window_s",
                                    "total_contact_duration_s",
                                    "overlap_duration_s",
                                    "max_concurrent_contacts",
                                    "overlap_contact_pair_count",
                                    "contact_ids",
                                    "duplicate_contact_ids",
                                    "duplicate_contact_id_count",
                                    "duplicate_contact_candidate_count",
                                    "source_window_ids",
                                    "scenario_ids",
                                    "operator_action_reason",
                                    "approval_status"
                                  ],
                                  &{&1, &1}
                                )
                            ] ++ Enum.map(@station_calendar_context_fields, &{&1, &1})
  @recommendation_source_field_pairs [
                                       {"subject_id", "group_id"},
                                       {"approval_status", "review_status"},
                                       {"required_operator_action", "action"},
                                       {"action", "action"}
                                       | Enum.map(
                                           [
                                             "resource_scope",
                                             "ground_station_id",
                                             "ground_station_ids",
                                             "spacecraft_id",
                                             "spacecraft_ids",
                                             "direction",
                                             "directions",
                                             "starts_at_s",
                                             "ends_at_s",
                                             "contention_window_s",
                                             "total_contact_duration_s",
                                             "overlap_duration_s",
                                             "max_concurrent_contacts",
                                             "overlap_contact_pair_count",
                                             "selected_contact_id",
                                             "selected_priority",
                                             "selected_priority_source",
                                             "deferred_contact_ids",
                                             "deferred_contact_priorities",
                                             "candidate_count",
                                             "selection_reason",
                                             "resolution_selection_rule",
                                             "resolution_priority_fields",
                                             "requested_priority_fields",
                                             "priority_field_evidence_counts",
                                             "priority_fields_without_numeric_evidence_count",
                                             "priority_fields_without_numeric_evidence",
                                             "resolution_priority_override_count",
                                             "resolution_priority_override_contact_ids",
                                             "ignored_priority_override_count",
                                             "ignored_priority_override_keys",
                                             "ignored_priority_override_contact_ids",
                                             "ignored_priority_override_input",
                                             "resolution_tie_breakers",
                                             "requested_selection_rule",
                                             "ignored_tie_breakers",
                                             "ignored_policy_input",
                                             "policy_warnings",
                                             "actual_throughput_mb",
                                             "actual_data_rate_throughput_derivations",
                                             "resolution_status",
                                             "resolution_issue",
                                             "duplicate_contact_ids",
                                             "duplicate_contact_id_count",
                                             "duplicate_contact_candidate_count",
                                             "duplicate_contact_candidates"
                                           ],
                                           &{&1, &1}
                                         )
                                     ] ++ Enum.map(@station_calendar_context_fields, &{&1, &1})
  @invalid_input_source_field_pairs [
    {"subject_id", "id"},
    {"action", "required_operator_action"}
    | Enum.map(
        [
          "contact_id",
          "contact_ids",
          "ground_station_id",
          "starts_at_s",
          "ends_at_s",
          "direction",
          "directions",
          "contact_count",
          "scenario_ids",
          "required_operator_action",
          "approval_status",
          "operator_action_reason",
          "invalid_contact_input",
          "invalid_contact_input_reason"
        ],
        &{&1, &1}
      )
  ]
  @source_review_match_fields [
                                "subject_id",
                                "approval_status",
                                "required_operator_action",
                                "resource_scope",
                                "ground_station_id",
                                "ground_station_ids",
                                "spacecraft_id",
                                "spacecraft_ids",
                                "starts_at_s",
                                "ends_at_s",
                                "direction",
                                "directions",
                                "contact_count",
                                "contention_window_s",
                                "total_contact_duration_s",
                                "overlap_duration_s",
                                "max_concurrent_contacts",
                                "overlap_contact_pair_count",
                                "contact_id",
                                "contact_ids",
                                "duplicate_contact_ids",
                                "duplicate_contact_id_count",
                                "duplicate_contact_candidate_count",
                                "source_contact_candidates",
                                "contact_success",
                                "contact_success_factor",
                                "contact_success_factor_source",
                                "command_success",
                                "command_success_factor",
                                "command_success_factor_source",
                                "actual_throughput_mb",
                                "actual_data_rate_throughput_derivations",
                                "contact_result",
                                "command_result",
                                "source_window_ids",
                                "scenario_ids",
                                "selected_contact_id",
                                "selected_priority",
                                "selected_priority_source",
                                "deferred_contact_ids",
                                "deferred_contact_priorities",
                                "candidate_count",
                                "selection_reason",
                                "resolution_selection_rule",
                                "resolution_priority_fields",
                                "requested_priority_fields",
                                "priority_field_evidence_counts",
                                "priority_fields_without_numeric_evidence_count",
                                "priority_fields_without_numeric_evidence",
                                "resolution_priority_override_count",
                                "resolution_priority_override_contact_ids",
                                "ignored_priority_override_count",
                                "ignored_priority_override_keys",
                                "ignored_priority_override_contact_ids",
                                "ignored_priority_override_input",
                                "resolution_tie_breakers",
                                "requested_selection_rule",
                                "ignored_tie_breakers",
                                "ignored_policy_input",
                                "policy_warnings",
                                "resolution_status",
                                "resolution_issue",
                                "reason",
                                "requirement_type",
                                "duplicate_contact_candidates",
                                "operator_action_reason",
                                "invalid_contact_input",
                                "invalid_contact_input_reason",
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
                                "source_contention_group",
                                "source_invalid_contact_input",
                                "source_recommendation"
                              ] ++ @provider_result_fields ++ @station_calendar_context_fields

  def validate_matches_source(issues, path, row) do
    issues
    |> validate_group_matches_source(path, row)
    |> validate_recommendation_matches_source(path, row)
    |> validate_invalid_input_matches_source(path, row)
  end

  def validate_group_matches_source(
        issues,
        path,
        %{"source_contention_group" => %{} = source_row} = row
      ) do
    if group_handoff_row?(row) do
      reduce_source_pairs(
        @group_source_field_pairs,
        issues,
        path,
        row,
        source_row,
        "source_contention_group"
      )
    else
      issues
    end
  end

  def validate_group_matches_source(issues, _path, _row), do: issues

  def validate_recommendation_matches_source(
        issues,
        path,
        %{"source_recommendation" => %{} = source_row} = row
      ) do
    if recommendation_handoff_row?(row) do
      reduce_source_pairs(
        @recommendation_source_field_pairs,
        issues,
        path,
        row,
        source_row,
        "source_recommendation"
      )
    else
      issues
    end
  end

  def validate_recommendation_matches_source(issues, _path, _row), do: issues

  def validate_invalid_input_matches_source(
        issues,
        path,
        %{"source_invalid_contact_input" => %{} = source_row} = row
      ) do
    if invalid_input_handoff_row?(row) do
      reduce_source_pairs(
        @invalid_input_source_field_pairs,
        issues,
        path,
        row,
        source_row,
        "source_invalid_contact_input"
      )
    else
      issues
    end
  end

  def validate_invalid_input_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if handoff_row?(row) do
      Enum.reduce(@source_review_match_fields, issues, fn field, acc ->
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

  def group_handoff_row?(row) do
    Map.get(row, "review_type") == "contact_contention_review" or
      Map.get(row, "source_review_type") == "contact_contention_review" or
      Map.get(row, "import_action") == "review_contact_contention"
  end

  def recommendation_handoff_row?(row) do
    Map.get(row, "review_type") == "contact_contention_recommendation" or
      Map.get(row, "source_review_type") == "contact_contention_recommendation" or
      Map.get(row, "import_action") == "review_contact_contention_resolution"
  end

  def invalid_input_handoff_row?(row) do
    Map.get(row, "invalid_contact_input") == true and group_handoff_row?(row)
  end

  def handoff_row?(row) do
    group_handoff_row?(row) or recommendation_handoff_row?(row)
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

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
