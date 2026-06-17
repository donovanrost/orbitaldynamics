defmodule OrbitalDynamics.Schema.ContactAllocationHandoffContracts do
  @moduledoc false

  @allocation_match_fields [
    "duplicate_contact_candidate_count",
    "duplicate_contact_candidate_ids",
    "resolution_priority_override_count",
    "resolution_priority_override_contact_ids"
  ]
  @allocation_source_field_pairs [
    {"activity_type", "type"}
    | Enum.map(
        [
          "contact_id",
          "scenario_id",
          "spacecraft_id",
          "ground_station_id",
          "direction",
          "starts_at_s",
          "ends_at_s",
          "source_window_id",
          "source_window_type",
          "source_window",
          "actual_throughput_mb",
          "actual_data_rate_throughput_derivation",
          "completed_fraction",
          "required_downlink_mb",
          "candidate_downlink_mb",
          "downlink_completion_ratio",
          "selected_downlink_shortfall_mb",
          "downlink_requirement_status",
          "downlink_completion_source",
          "downlink_completion_sources",
          "required_capacity_fraction",
          "required_capacity_fraction_source",
          "contact_success",
          "contact_success_factor",
          "contact_success_factor_source",
          "command_success",
          "command_success_factor",
          "command_success_factor_source",
          "allocation_status",
          "effective_allocation_status",
          "allocation_reason",
          "selected",
          "contention_group_id",
          "selected_contact_id",
          "deferred_contact_ids",
          "selected_priority",
          "selected_priority_source",
          "station_calendar_entry_id",
          "station_calendar_provider_id",
          "station_calendar_provider_entry_id",
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
          "station_calendar_trust_boundary_status",
          "trust_boundary",
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
          "station_availability",
          "capacity_fraction",
          "station_contention_status",
          "station_reservation_id",
          "station_reservation_expires_at_s",
          "station_reserved_by",
          "station_reservation_status",
          "station_reservation_match_status",
          "approval_status"
          | @allocation_match_fields
        ],
        &{&1, &1}
      )
  ]
  @allocation_source_review_field_pairs Enum.map(
                                          @allocation_source_field_pairs,
                                          fn {row_field, _source_field} ->
                                            {row_field, row_field}
                                          end
                                        ) ++
                                          Enum.map(
                                            [
                                              "subject_id",
                                              "activity_id",
                                              "branch_id",
                                              "contact_result",
                                              "command_result",
                                              "policy_classification",
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
  @capacity_pack_source_fields [
    "contention_group_id",
    "ground_station_id",
    "capacity_fraction",
    "used_capacity_fraction",
    "unused_capacity_fraction",
    "default_required_capacity_fraction",
    "input_contact_ids",
    "selected_contact_ids",
    "capacity_packed_contact_ids",
    "deferred_contact_ids",
    "capacity_pack_contact_ids_by_direction",
    "capacity_pack_selected_contact_ids_by_direction",
    "capacity_pack_deferred_contact_ids_by_direction",
    "capacity_pack_required_capacity_fraction_by_direction",
    "capacity_pack_selected_required_capacity_fraction_by_direction",
    "capacity_pack_deferred_required_capacity_fraction_by_direction",
    "capacity_requirement_rows",
    "pack_status"
  ]
  @capacity_pack_source_review_fields @capacity_pack_source_fields ++
                                        [
                                          "subject_id",
                                          "action",
                                          "required_operator_action",
                                          "approval_status",
                                          "reason"
                                        ]
  @provider_calendar_contention_source_field_pairs [
    {"provider_calendar_contention_group_id", "id"},
    {"ground_station_id", "ground_station_id"},
    {"starts_at_s", "starts_at_s"},
    {"ends_at_s", "ends_at_s"},
    {"overlap_duration_s", "overlap_duration_s"},
    {"provider_calendar_contention_status", "provider_calendar_contention_status"},
    {"provider_calendar_contention_entry_count", "entry_count"},
    {"provider_calendar_contention_entry_ids", "entry_ids"},
    {"provider_calendar_contention_provider_ids", "provider_ids"},
    {"provider_calendar_contention_provider_entry_ids", "provider_entry_ids"},
    {"provider_calendar_contention_availabilities", "availabilities"},
    {"provider_calendar_contention_directions", "directions"},
    {"provider_calendar_contention_reservation_ids", "reservation_ids"},
    {"provider_calendar_contention_reserved_by", "reserved_by"},
    {"provider_calendar_contention_reservation_statuses", "reservation_statuses"},
    {"provider_calendar_contention_reservation_expires_at_s", "reservation_expires_at_s"},
    {"provider_calendar_contention_trust_boundary_statuses", "trust_boundary_statuses"},
    {"provider_calendar_contention_overlap_pairs", "overlap_pairs"},
    {"required_operator_action", "required_operator_action"},
    {"approval_status", "approval_status"},
    {"operator_action_reason", "operator_action_reason"}
  ]
  @provider_calendar_contention_source_review_field_pairs Enum.map(
                                                            @provider_calendar_contention_source_field_pairs,
                                                            fn {row_field, _source_field} ->
                                                              {row_field, row_field}
                                                            end
                                                          )

  def validate_expiration_summary(issues, path, artifact, callbacks) when is_list(callbacks) do
    issues
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "station_reservation_expiration_status_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_reservation_expiration_status_counts",
      Map.get(artifact, "station_reservation_expiration_status_counts")
    )
    |> expect_optional_type(callbacks, path, artifact, "resource_blocking_dimension_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".resource_blocking_dimension_counts",
      Map.get(artifact, "resource_blocking_dimension_counts")
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "resource_blocked_contact_ids_by_blocking_dimension"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "resource_blocked_contact_ids_by_spacecraft_id"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      artifact,
      "station_pressure_review_contact_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "station_pressure_review_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      artifact,
      "station_pressure_review_contact_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_counts_by_ground_station_id",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_pressure_contact_counts_by_ground_station_id",
      Map.get(artifact, "station_pressure_contact_counts_by_ground_station_id")
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_ids_by_ground_station_id"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_counts_by_availability",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_pressure_contact_counts_by_availability",
      Map.get(artifact, "station_pressure_contact_counts_by_availability")
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_ids_by_availability"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_counts_by_precedence_availability",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_pressure_contact_counts_by_precedence_availability",
      Map.get(artifact, "station_pressure_contact_counts_by_precedence_availability")
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_ids_by_precedence_availability"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_counts_by_precedence_rank",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_pressure_contact_counts_by_precedence_rank",
      Map.get(artifact, "station_pressure_contact_counts_by_precedence_rank")
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_ids_by_precedence_rank"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_counts_by_status",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_pressure_contact_counts_by_status",
      Map.get(artifact, "station_pressure_contact_counts_by_status")
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_ids_by_status"
    )
    |> validate_optional_nested_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_pressure_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      artifact,
      "capacity_pack_required_capacity_fraction"
    )
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      artifact,
      "capacity_pack_selected_required_capacity_fraction"
    )
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      artifact,
      "capacity_pack_deferred_required_capacity_fraction"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "capacity_pack_required_capacity_fraction_by_status",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_status",
      Map.get(artifact, "capacity_pack_required_capacity_fraction_by_status")
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_ground_station_id",
      Map.get(artifact, "capacity_pack_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      Map.get(artifact, "capacity_pack_selected_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      Map.get(artifact, "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "required_capacity_fraction_source_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_capacity_fraction_source_counts",
      Map.get(artifact, "required_capacity_fraction_source_counts")
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "required_capacity_fraction_contact_ids_by_source"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      artifact,
      "provider_reservation_candidate_contact_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      artifact,
      "provider_reservation_request_contact_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      artifact,
      "provider_reservation_review_contact_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      artifact,
      "provider_reservation_no_request_contact_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "provider_reservation_request_status_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".provider_reservation_request_status_counts",
      Map.get(artifact, "provider_reservation_request_status_counts")
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "provider_reservation_request_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      artifact,
      "provider_reservation_request_contact_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "provider_reservation_review_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      artifact,
      "provider_reservation_review_contact_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "provider_reservation_no_request_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      artifact,
      "provider_reservation_no_request_contact_ids"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_request_contact_ids_by_ground_station_id"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_review_contact_ids_by_ground_station_id"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_no_request_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_request_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_review_contact_ids_by_direction"
    )
    |> validate_optional_nested_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> validate_optional_nested_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> validate_optional_nested_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_request_contact_ids_by_match_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_review_contact_ids_by_match_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_request_ids_by_match_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "provider_reservation_review_ids_by_match_status"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      artifact,
      "reduced_capacity_pack_group_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "reduced_capacity_pack_status_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".reduced_capacity_pack_status_counts",
      Map.get(artifact, "reduced_capacity_pack_status_counts")
    )
    |> expect_optional_type(callbacks, path, artifact, "capacity_pack_group_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, artifact, "capacity_pack_group_ids")
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "capacity_pack_group_ids_by_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "capacity_pack_contact_ids_by_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "capacity_pack_contact_ids_by_ground_station_id"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "capacity_pack_selected_contact_ids_by_ground_station_id"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "capacity_pack_deferred_contact_ids_by_ground_station_id"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "reduced_capacity_packed_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      artifact,
      "reduced_capacity_packed_contact_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      artifact,
      "reduced_capacity_deferred_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      artifact,
      "reduced_capacity_deferred_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      artifact,
      "station_reservation_declared_expiration_contact_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      artifact,
      "station_reservation_missing_expiration_contact_count"
    )
    |> expect_optional_number(
      callbacks,
      path,
      artifact,
      "earliest_station_reservation_expires_at_s"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_reservation_contact_ids_by_expiration_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_reservation_ids_by_expiration_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_reservation_contact_ids_by_match_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_reservation_contact_ids_by_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_reservation_contact_ids_by_reserved_by"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_reservation_ids_by_match_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_reservation_ids_by_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      artifact,
      "station_reservation_ids_by_reserved_by"
    )
  end

  def validate_allocation_fields(issues, path, row, callbacks) when is_list(callbacks) do
    if allocation_handoff_row?(row) do
      issues
      |> expect_optional_integer(callbacks, path, row, "duplicate_contact_candidate_count")
      |> expect_field_at_least(callbacks, path, row, "duplicate_contact_candidate_count", 0)
      |> expect_optional_type(callbacks, path, row, "duplicate_contact_candidate_ids", :list)
      |> validate_optional_stable_id_list(
        callbacks,
        path,
        row,
        "duplicate_contact_candidate_ids"
      )
      |> validate_contact_allocation_duplicate_evidence(callbacks, path, row)
      |> expect_optional_integer(callbacks, path, row, "resolution_priority_override_count")
      |> expect_field_at_least(callbacks, path, row, "resolution_priority_override_count", 0)
      |> expect_optional_type(
        callbacks,
        path,
        row,
        "resolution_priority_override_contact_ids",
        :list
      )
      |> validate_optional_stable_id_list(
        callbacks,
        path,
        row,
        "resolution_priority_override_contact_ids"
      )
      |> validate_override_count_matches_ids(
        callbacks,
        path,
        row,
        "resolution_priority_override_count",
        "resolution_priority_override_contact_ids"
      )
    else
      issues
    end
  end

  def allocation_handoff_row?(row) do
    Map.get(row, "review_type") == "contact_allocation_review" or
      Map.get(row, "source_review_type") == "contact_allocation_review" or
      Map.get(row, "import_action") == "review_contact_allocation"
  end

  def validate_allocation_matches_source(
        issues,
        path,
        %{"source_contact_allocation" => %{} = source_row} = row
      ) do
    if allocation_handoff_row?(row) do
      Enum.reduce(@allocation_source_field_pairs, issues, fn {row_field, source_field}, acc ->
        row_value = Map.get(row, row_field)
        source_value = Map.get(source_row, source_field)

        if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
          [
            error(
              "#{path}.#{row_field}",
              "must match source_contact_allocation.#{source_field}"
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

  def validate_allocation_matches_source(issues, _path, _row), do: issues

  def validate_capacity_pack_matches_source(
        issues,
        path,
        %{"source_contact_allocation_capacity_pack" => %{} = source_row} = row
      ) do
    if capacity_pack_handoff_row?(row) do
      Enum.reduce(@capacity_pack_source_fields, issues, fn field, acc ->
        row_value = Map.get(row, field)
        source_value = Map.get(source_row, field)

        if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
          [
            error(
              "#{path}.#{field}",
              "must match source_contact_allocation_capacity_pack.#{field}"
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

  def validate_capacity_pack_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_capacity_pack_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if capacity_pack_handoff_row?(row) do
      Enum.reduce(@capacity_pack_source_review_fields, issues, fn field, acc ->
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

  def validate_cadence_source_review_capacity_pack_matches(issues, _path, _row), do: issues

  def capacity_pack_handoff_row?(row) do
    Map.get(row, "review_type") == "contact_allocation_capacity_pack_review" or
      Map.get(row, "source_review_type") == "contact_allocation_capacity_pack_review" or
      Map.get(row, "import_action") == "review_contact_allocation_capacity_pack"
  end

  def validate_cadence_source_review_allocation_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if allocation_handoff_row?(row) do
      Enum.reduce(@allocation_source_review_field_pairs, issues, fn {source_field, row_field},
                                                                    acc ->
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

  def validate_cadence_source_review_allocation_matches(issues, _path, _row), do: issues

  def validate_provider_calendar_contention_matches_source(issues, path, row) do
    source_row =
      Map.get(row, "source_station_calendar_provider_contention") ||
        Map.get(row, "source_station_reservation")

    if provider_calendar_contention_handoff_row?(row) and is_map(source_row) do
      Enum.reduce(@provider_calendar_contention_source_field_pairs, issues, fn {row_field,
                                                                                source_field},
                                                                               acc ->
        row_value = Map.get(row, row_field)
        source_value = Map.get(source_row, source_field)

        if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
          [
            error(
              "#{path}.#{row_field}",
              "must match provider calendar contention source #{source_field}"
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

  def validate_cadence_source_review_provider_calendar_contention_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if provider_calendar_contention_handoff_row?(row) do
      Enum.reduce(
        @provider_calendar_contention_source_review_field_pairs,
        issues,
        fn {source_field, row_field}, acc ->
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
        end
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_provider_calendar_contention_matches(issues, _path, _row),
    do: issues

  def provider_calendar_contention_handoff_row?(row) do
    station_calendar_source_handoff_row?(row) and
      present_string?(Map.get(row, "provider_calendar_contention_group_id"))
  end

  defp validate_optional_stable_id_array_map(issues, callbacks, path, artifact, field) do
    issues
    |> expect_optional_type(callbacks, path, artifact, field, :map)
    |> validate_stable_id_array_map(callbacks, path <> ".#{field}", Map.get(artifact, field))
  end

  defp validate_optional_nested_stable_id_array_map(issues, callbacks, path, artifact, field) do
    issues
    |> expect_optional_type(callbacks, path, artifact, field, :map)
    |> validate_nested_stable_id_array_map(
      callbacks,
      path <> ".#{field}",
      Map.get(artifact, field)
    )
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_integer), [issues, path, map, field])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_non_negative_number(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_number), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_at_least(issues, callbacks, path, map, field, minimum),
    do:
      apply(require_callback(callbacks, :expect_field_at_least), [
        issues,
        path,
        map,
        field,
        minimum
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_contact_allocation_duplicate_evidence(issues, callbacks, path, row),
    do:
      apply(require_callback(callbacks, :validate_contact_allocation_duplicate_evidence), [
        issues,
        path,
        row
      ])

  defp validate_override_count_matches_ids(
         issues,
         callbacks,
         path,
         row,
         count_field,
         ids_field
       ),
       do:
         apply(require_callback(callbacks, :validate_override_count_matches_ids), [
           issues,
           path,
           row,
           count_field,
           ids_field
         ])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(require_callback(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_nested_stable_id_array_map(issues, callbacks, path, values),
    do:
      apply(require_callback(callbacks, :validate_nested_stable_id_array_map), [
        issues,
        path,
        values
      ])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, values),
    do:
      apply(require_callback(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        values
      ])

  defp validate_non_negative_number_map(issues, callbacks, path, values),
    do:
      apply(require_callback(callbacks, :validate_non_negative_number_map), [
        issues,
        path,
        values
      ])

  defp station_calendar_source_handoff_row?(row) do
    Map.get(row, "review_type") in ["station_calendar_review", "station_reservation_review"] or
      Map.get(row, "source_review_type") in [
        "station_calendar_review",
        "station_reservation_review"
      ] or
      Map.get(row, "import_action") in ["review_station_calendar", "review_station_reservation"]
  end

  defp present_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
