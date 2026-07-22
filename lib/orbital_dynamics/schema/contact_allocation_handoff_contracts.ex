defmodule OrbitalDynamics.Schema.ContactAllocationHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PriorityOverrideContracts

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_at_least: 5,
      expect_optional_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_non_negative_number: 4,
      expect_optional_number: 4,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_non_negative_number_map: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_stable_id_array_map: 3,
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3
    ]

  @allocation_match_fields [
    "duplicate_contact_candidate_count",
    "duplicate_contact_candidate_ids",
    "resolution_priority_override_count",
    "resolution_priority_override_contact_ids"
  ]
  @station_pressure_grouped_summary_fields [
    {"station_pressure_contact_counts_by_ground_station_id",
     "station_pressure_contact_ids_by_ground_station_id"},
    {"station_pressure_contact_counts_by_availability",
     "station_pressure_contact_ids_by_availability"},
    {"station_pressure_contact_counts_by_precedence_availability",
     "station_pressure_contact_ids_by_precedence_availability"},
    {"station_pressure_contact_counts_by_precedence_rank",
     "station_pressure_contact_ids_by_precedence_rank"},
    {"station_pressure_contact_counts_by_status", "station_pressure_contact_ids_by_status"}
  ]
  @provider_reservation_contact_identity_fields %{
    "no_request" => %{
      count_field: "provider_reservation_no_request_contact_count",
      identity_field: "provider_reservation_no_request_contact_ids",
      map_fields: [
        "provider_reservation_no_request_contact_ids_by_direction"
      ],
      nested_field:
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
    },
    "request" => %{
      count_field: "provider_reservation_request_contact_count",
      identity_field: "provider_reservation_request_contact_ids",
      map_fields: [
        "provider_reservation_request_contact_ids_by_ground_station_id",
        "provider_reservation_request_contact_ids_by_direction",
        "provider_reservation_request_contact_ids_by_match_status"
      ],
      nested_field: "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
    },
    "review" => %{
      count_field: "provider_reservation_review_contact_count",
      identity_field: "provider_reservation_review_contact_ids",
      map_fields: [
        "provider_reservation_review_contact_ids_by_ground_station_id",
        "provider_reservation_review_contact_ids_by_direction",
        "provider_reservation_review_contact_ids_by_match_status"
      ],
      nested_field: "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
    }
  }
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

  def validate_station_pressure_identity_summary(issues, path, artifact) do
    issues = validate_station_pressure_review_identity_summary(issues, path, artifact)

    case Map.get(artifact, "station_pressure_contact_ids") do
      contact_ids when is_list(contact_ids) ->
        canonical_contact_ids = contact_ids |> Enum.uniq() |> Enum.sort()

        issues =
          if contact_ids == canonical_contact_ids do
            issues
          else
            [
              error(
                path <> ".station_pressure_contact_ids",
                "must equal sorted unique station-pressure contact IDs"
              )
              | issues
            ]
          end

        issues =
          if Map.get(artifact, "station_pressure_contact_count") ==
               length(canonical_contact_ids) do
            issues
          else
            [
              error(
                path <> ".station_pressure_contact_count",
                "must equal canonical station_pressure_contact_ids count"
              )
              | issues
            ]
          end

        routed_contact_ids = station_pressure_routed_identity_lists(artifact) |> List.flatten()

        if MapSet.subset?(MapSet.new(routed_contact_ids), MapSet.new(canonical_contact_ids)) do
          issues
        else
          [
            error(
              path <> ".station_pressure_contact_ids",
              "must include all review and routed station-pressure contact IDs"
            )
            | issues
          ]
        end

      _contact_ids ->
        issues
    end
  end

  defp validate_station_pressure_review_identity_summary(issues, path, artifact) do
    case Map.get(artifact, "station_pressure_review_contact_ids") do
      contact_ids when is_list(contact_ids) ->
        canonical_contact_ids = contact_ids |> Enum.uniq() |> Enum.sort()

        issues =
          if contact_ids == canonical_contact_ids do
            issues
          else
            [
              error(
                path <> ".station_pressure_review_contact_ids",
                "must equal sorted unique station-pressure review contact IDs"
              )
              | issues
            ]
          end

        if Map.get(artifact, "station_pressure_review_contact_count") ==
             length(canonical_contact_ids) do
          issues
        else
          [
            error(
              path <> ".station_pressure_review_contact_count",
              "must equal canonical station_pressure_review_contact_ids count"
            )
            | issues
          ]
        end

      _contact_ids ->
        issues
    end
  end

  defp station_pressure_routed_identity_lists(artifact) do
    fields =
      ["station_pressure_review_contact_ids"] ++
        Enum.map(@station_pressure_grouped_summary_fields, &elem(&1, 1)) ++
        [
          "station_pressure_contact_ids_by_direction",
          "station_pressure_contact_ids_by_direction_and_ground_station_id"
        ]

    Enum.flat_map(fields, &collect_identity_lists(Map.get(artifact, &1)))
  end

  defp collect_identity_lists(values) when is_list(values), do: [values]

  defp collect_identity_lists(%{} = values) do
    values
    |> Map.values()
    |> Enum.flat_map(&collect_identity_lists/1)
  end

  defp collect_identity_lists(_values), do: []

  defp validate_provider_reservation_contact_identity_summary(issues, path, artifact, status) do
    fields = Map.fetch!(@provider_reservation_contact_identity_fields, status)

    issues =
      Enum.reduce(fields.map_fields, issues, fn field, acc ->
        validate_canonical_id_map(acc, path, Map.get(artifact, field), field)
      end)

    issues =
      validate_canonical_nested_id_map(
        issues,
        path,
        Map.get(artifact, fields.nested_field),
        fields.nested_field
      )

    case Map.get(artifact, fields.identity_field) do
      contact_ids when is_list(contact_ids) ->
        canonical_contact_ids = contact_ids |> Enum.uniq() |> Enum.sort()

        issues =
          if contact_ids == canonical_contact_ids do
            issues
          else
            [
              error(
                path <> ".#{fields.identity_field}",
                "must equal sorted unique provider-reservation #{status} contact IDs"
              )
              | issues
            ]
          end

        issues =
          if Map.get(artifact, fields.count_field) == length(canonical_contact_ids) do
            issues
          else
            [
              error(
                path <> ".#{fields.count_field}",
                "must equal canonical #{fields.identity_field} count"
              )
              | issues
            ]
          end

        routed_contact_ids =
          (fields.map_fields ++ [fields.nested_field])
          |> Enum.flat_map(&collect_identity_lists(Map.get(artifact, &1)))
          |> List.flatten()

        if MapSet.subset?(MapSet.new(routed_contact_ids), MapSet.new(canonical_contact_ids)) do
          issues
        else
          [
            error(
              path <> ".#{fields.identity_field}",
              "must include all routed provider-reservation #{status} contact IDs"
            )
            | issues
          ]
        end

      _contact_ids ->
        issues
    end
  end

  defp validate_station_pressure_grouped_identity_summaries(issues, path, artifact) do
    Enum.reduce(@station_pressure_grouped_summary_fields, issues, fn
      {count_field, id_field}, acc ->
        validate_correlated_id_count_map(acc, path, artifact, count_field, id_field)
    end)
  end

  defp validate_correlated_id_count_map(issues, path, artifact, count_field, id_field) do
    case Map.get(artifact, id_field) do
      %{} = contact_ids_by_key ->
        counts_by_key = Map.get(artifact, count_field)

        Enum.reduce(contact_ids_by_key, issues, fn {key, contact_ids}, acc ->
          case contact_ids do
            contact_ids when is_list(contact_ids) ->
              canonical_contact_ids = contact_ids |> Enum.uniq() |> Enum.sort()

              acc =
                if contact_ids == canonical_contact_ids do
                  acc
                else
                  [
                    error(
                      "#{path}.#{id_field}.#{key}",
                      "must equal sorted unique station-pressure contact IDs"
                    )
                    | acc
                  ]
                end

              if is_map(counts_by_key) and
                   Map.get(counts_by_key, key) == length(canonical_contact_ids) do
                acc
              else
                [
                  error(
                    "#{path}.#{count_field}.#{key}",
                    "must equal canonical #{id_field} count"
                  )
                  | acc
                ]
              end

            _contact_ids ->
              [error("#{path}.#{id_field}.#{key}", "must be a list of stable IDs") | acc]
          end
        end)

      _contact_ids_by_key ->
        issues
    end
  end

  defp validate_station_pressure_direction_routes(issues, path, artifact) do
    flat_field = "station_pressure_contact_ids_by_direction"
    nested_field = "station_pressure_contact_ids_by_direction_and_ground_station_id"
    ids_by_direction = Map.get(artifact, flat_field)
    ids_by_direction_and_station = Map.get(artifact, nested_field)

    issues = validate_canonical_id_map(issues, path, ids_by_direction, flat_field)

    issues =
      validate_canonical_nested_id_map(
        issues,
        path,
        ids_by_direction_and_station,
        nested_field
      )

    if is_map(ids_by_direction) and is_map(ids_by_direction_and_station) do
      Enum.reduce(ids_by_direction_and_station, issues, fn {direction, ids_by_station}, acc ->
        nested_ids =
          if is_map(ids_by_station) do
            ids_by_station
            |> Map.values()
            |> Enum.filter(&is_list/1)
            |> List.flatten()
            |> MapSet.new()
          else
            MapSet.new()
          end

        case Map.get(ids_by_direction, direction) do
          flat_ids when is_list(flat_ids) ->
            if MapSet.subset?(nested_ids, MapSet.new(flat_ids)) do
              acc
            else
              [
                error(
                  "#{path}.#{flat_field}.#{direction}",
                  "must include all nested direction/station contact IDs"
                )
                | acc
              ]
            end

          _flat_ids ->
            [
              error(
                "#{path}.#{flat_field}.#{direction}",
                "must include the nested direction route"
              )
              | acc
            ]
        end
      end)
    else
      issues
    end
  end

  defp validate_canonical_id_map(issues, path, id_map, field) when is_map(id_map) do
    Enum.reduce(id_map, issues, fn {key, contact_ids}, acc ->
      cond do
        not is_list(contact_ids) ->
          [error("#{path}.#{field}.#{key}", "must be a list of stable IDs") | acc]

        contact_ids != Enum.sort(Enum.uniq(contact_ids)) ->
          [error("#{path}.#{field}.#{key}", "must equal sorted unique contact IDs") | acc]

        true ->
          acc
      end
    end)
  end

  defp validate_canonical_id_map(issues, _path, _id_map, _field), do: issues

  defp validate_canonical_nested_id_map(issues, path, nested_id_map, field)
       when is_map(nested_id_map) do
    Enum.reduce(nested_id_map, issues, fn
      {outer_key, %{} = id_map}, acc ->
        validate_canonical_id_map(acc, "#{path}.#{field}", id_map, outer_key)

      {outer_key, _id_map}, acc ->
        [error("#{path}.#{field}.#{outer_key}", "must be a station-to-ID map") | acc]
    end)
  end

  defp validate_canonical_nested_id_map(issues, _path, _nested_id_map, _field), do: issues

  def validate_expiration_summary(issues, path, artifact) do
    issues
    |> expect_optional_type(
      path,
      artifact,
      "station_reservation_expiration_status_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_reservation_expiration_status_counts",
      Map.get(artifact, "station_reservation_expiration_status_counts")
    )
    |> expect_optional_type(path, artifact, "resource_blocking_dimension_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".resource_blocking_dimension_counts",
      Map.get(artifact, "resource_blocking_dimension_counts")
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "resource_blocked_contact_ids_by_blocking_dimension"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "resource_blocked_contact_ids_by_spacecraft_id"
    )
    |> expect_optional_non_negative_integer(
      path,
      artifact,
      "station_pressure_contact_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      artifact,
      "station_pressure_review_contact_count"
    )
    |> expect_optional_type(
      path,
      artifact,
      "station_pressure_review_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      artifact,
      "station_pressure_review_contact_ids"
    )
    |> expect_optional_type(
      path,
      artifact,
      "station_pressure_contact_counts_by_ground_station_id",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_pressure_contact_counts_by_ground_station_id",
      Map.get(artifact, "station_pressure_contact_counts_by_ground_station_id")
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_pressure_contact_ids_by_ground_station_id"
    )
    |> expect_optional_type(
      path,
      artifact,
      "station_pressure_contact_counts_by_availability",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_pressure_contact_counts_by_availability",
      Map.get(artifact, "station_pressure_contact_counts_by_availability")
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_pressure_contact_ids_by_availability"
    )
    |> expect_optional_type(
      path,
      artifact,
      "station_pressure_contact_counts_by_precedence_availability",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_pressure_contact_counts_by_precedence_availability",
      Map.get(artifact, "station_pressure_contact_counts_by_precedence_availability")
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_pressure_contact_ids_by_precedence_availability"
    )
    |> expect_optional_type(
      path,
      artifact,
      "station_pressure_contact_counts_by_precedence_rank",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_pressure_contact_counts_by_precedence_rank",
      Map.get(artifact, "station_pressure_contact_counts_by_precedence_rank")
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_pressure_contact_ids_by_precedence_rank"
    )
    |> expect_optional_type(
      path,
      artifact,
      "station_pressure_contact_counts_by_status",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".station_pressure_contact_counts_by_status",
      Map.get(artifact, "station_pressure_contact_counts_by_status")
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_pressure_contact_ids_by_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_pressure_contact_ids_by_direction"
    )
    |> validate_optional_nested_stable_id_array_map(
      path,
      artifact,
      "station_pressure_contact_ids_by_direction_and_ground_station_id"
    )
    |> validate_station_pressure_direction_routes(path, artifact)
    |> validate_station_pressure_grouped_identity_summaries(path, artifact)
    |> expect_optional_non_negative_number(
      path,
      artifact,
      "capacity_pack_required_capacity_fraction"
    )
    |> expect_optional_non_negative_number(
      path,
      artifact,
      "capacity_pack_selected_required_capacity_fraction"
    )
    |> expect_optional_non_negative_number(
      path,
      artifact,
      "capacity_pack_deferred_required_capacity_fraction"
    )
    |> expect_optional_type(
      path,
      artifact,
      "capacity_pack_required_capacity_fraction_by_status",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_required_capacity_fraction_by_status",
      Map.get(artifact, "capacity_pack_required_capacity_fraction_by_status")
    )
    |> expect_optional_type(
      path,
      artifact,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_required_capacity_fraction_by_ground_station_id",
      Map.get(artifact, "capacity_pack_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_optional_type(
      path,
      artifact,
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      Map.get(artifact, "capacity_pack_selected_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_optional_type(
      path,
      artifact,
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      Map.get(artifact, "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id")
    )
    |> expect_optional_type(
      path,
      artifact,
      "required_capacity_fraction_source_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".required_capacity_fraction_source_counts",
      Map.get(artifact, "required_capacity_fraction_source_counts")
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "required_capacity_fraction_contact_ids_by_source"
    )
    |> expect_optional_non_negative_integer(
      path,
      artifact,
      "provider_reservation_candidate_contact_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      artifact,
      "provider_reservation_request_contact_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      artifact,
      "provider_reservation_review_contact_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      artifact,
      "provider_reservation_no_request_contact_count"
    )
    |> expect_optional_type(
      path,
      artifact,
      "provider_reservation_request_status_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".provider_reservation_request_status_counts",
      Map.get(artifact, "provider_reservation_request_status_counts")
    )
    |> expect_optional_type(
      path,
      artifact,
      "provider_reservation_request_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      artifact,
      "provider_reservation_request_contact_ids"
    )
    |> expect_optional_type(
      path,
      artifact,
      "provider_reservation_review_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      artifact,
      "provider_reservation_review_contact_ids"
    )
    |> expect_optional_type(
      path,
      artifact,
      "provider_reservation_no_request_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      artifact,
      "provider_reservation_no_request_contact_ids"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_request_contact_ids_by_ground_station_id"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_review_contact_ids_by_ground_station_id"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_no_request_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_request_contact_ids_by_direction"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_review_contact_ids_by_direction"
    )
    |> validate_optional_nested_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> validate_optional_nested_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> validate_optional_nested_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_request_contact_ids_by_match_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_review_contact_ids_by_match_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_request_ids_by_match_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "provider_reservation_review_ids_by_match_status"
    )
    |> validate_provider_reservation_contact_identity_summary(path, artifact, "request")
    |> validate_provider_reservation_contact_identity_summary(path, artifact, "review")
    |> validate_provider_reservation_contact_identity_summary(path, artifact, "no_request")
    |> expect_optional_non_negative_integer(
      path,
      artifact,
      "reduced_capacity_pack_group_count"
    )
    |> expect_optional_type(
      path,
      artifact,
      "reduced_capacity_pack_status_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".reduced_capacity_pack_status_counts",
      Map.get(artifact, "reduced_capacity_pack_status_counts")
    )
    |> expect_optional_type(path, artifact, "capacity_pack_group_ids", :list)
    |> validate_optional_stable_id_list(path, artifact, "capacity_pack_group_ids")
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "capacity_pack_group_ids_by_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "capacity_pack_contact_ids_by_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "capacity_pack_contact_ids_by_ground_station_id"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "capacity_pack_selected_contact_ids_by_ground_station_id"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "capacity_pack_deferred_contact_ids_by_ground_station_id"
    )
    |> expect_optional_type(
      path,
      artifact,
      "reduced_capacity_packed_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      artifact,
      "reduced_capacity_packed_contact_ids"
    )
    |> expect_optional_type(
      path,
      artifact,
      "reduced_capacity_deferred_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      artifact,
      "reduced_capacity_deferred_contact_ids"
    )
    |> expect_optional_non_negative_integer(
      path,
      artifact,
      "station_reservation_declared_expiration_contact_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      artifact,
      "station_reservation_missing_expiration_contact_count"
    )
    |> expect_optional_number(
      path,
      artifact,
      "earliest_station_reservation_expires_at_s"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_reservation_contact_ids_by_expiration_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_reservation_ids_by_expiration_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_reservation_contact_ids_by_match_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_reservation_contact_ids_by_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_reservation_contact_ids_by_reserved_by"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_reservation_ids_by_match_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_reservation_ids_by_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "station_reservation_ids_by_reserved_by"
    )
  end

  def validate_allocation_fields(issues, path, row),
    do:
      validate_allocation_fields(
        issues,
        path,
        row,
        &OrbitalDynamics.Schema.ContactAllocationValidation.validate_duplicate_evidence/3
      )

  def validate_allocation_fields(issues, path, row, duplicate_evidence_validator)
      when is_function(duplicate_evidence_validator, 3) do
    if allocation_handoff_row?(row) do
      issues
      |> expect_optional_integer(path, row, "duplicate_contact_candidate_count")
      |> expect_field_at_least(path, row, "duplicate_contact_candidate_count", 0)
      |> expect_optional_type(path, row, "duplicate_contact_candidate_ids", :list)
      |> validate_optional_stable_id_list(
        path,
        row,
        "duplicate_contact_candidate_ids"
      )
      |> duplicate_evidence_validator.(path, row)
      |> expect_optional_integer(path, row, "resolution_priority_override_count")
      |> expect_field_at_least(path, row, "resolution_priority_override_count", 0)
      |> expect_optional_type(
        path,
        row,
        "resolution_priority_override_contact_ids",
        :list
      )
      |> validate_optional_stable_id_list(
        path,
        row,
        "resolution_priority_override_contact_ids"
      )
      |> PriorityOverrideContracts.validate_count_matches_ids(
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

  defp validate_optional_stable_id_array_map(issues, path, artifact, field) do
    issues
    |> expect_optional_type(path, artifact, field, :map)
    |> validate_stable_id_array_map(path <> ".#{field}", Map.get(artifact, field))
  end

  defp validate_optional_nested_stable_id_array_map(issues, path, artifact, field) do
    issues
    |> expect_optional_type(path, artifact, field, :map)
    |> validate_nested_stable_id_array_map(
      path <> ".#{field}",
      Map.get(artifact, field)
    )
  end

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
