defmodule Mix.Tasks.OrbitalDynamics.Schema.ExportTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.{Schema, Validation}

  test "exports schema bundles" do
    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics.schema_bundle.v1.json")

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.schema.export", ["--all", "--output", output_path])
    end)

    assert %{
             "schema_contract" => "orbital_dynamics.schema_bundle.v1",
             "schema_count" => count,
             "schemas" => schemas
           } = output_path |> File.read!() |> :json.decode()

    assert count == map_size(schemas)

    classification_values = [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ]

    strategy_approval_status_values = classification_values ++ ["not_applicable"]

    assert Map.has_key?(schemas, "candidate_refresh.v1")
    assert Map.has_key?(schemas, "station_calendar_provider.v1")
    assert Map.has_key?(schemas, "station_reservation_report.v1")
    assert Map.has_key?(schemas, "policy_bundle.v1")
    assert Map.has_key?(schemas, "environment_model_capability.v1")
    assert Map.has_key?(schemas, "environment_provider_capability.v1")
    assert Map.has_key?(schemas, "constraint_report.v1")
    assert Map.has_key?(schemas, "score_term_report.v1")
    assert Map.has_key?(schemas, "optimizer_contract.v1")
    assert Map.has_key?(schemas, "branch_comparison_report.v1")
    assert Map.has_key?(schemas, "resource_projection_flow_summary.v1")
    assert Map.has_key?(schemas, "resource_filter_summary.v1")
    assert Map.has_key?(schemas, "link_capacity_report.v1")
    assert Map.has_key?(schemas, "link_capacity_summary.v1")
    assert Map.has_key?(schemas, "relay_data_path_summary.v1")
    assert Map.has_key?(schemas, "contact_contention_resolution_summary.v1")
    assert Map.has_key?(schemas, "contact_intent_summary.v1")

    link_capacity_capabilities = OrbitalDynamics.Communications.LinkCapacity.capabilities()

    link_capacity_model_limits =
      Enum.map(link_capacity_capabilities.known_limits, &Atom.to_string/1)

    link_capacity_budget_model_limits =
      OrbitalDynamics.Communications.LinkCapacity.report_model_limits([:present])

    link_capacity_report_model_limits =
      get_in(schemas, ["link_capacity_report.v1", "properties", "model_limits"])

    assert link_capacity_report_model_limits["oneOf"] == [
             %{"const" => link_capacity_model_limits},
             %{"const" => link_capacity_budget_model_limits}
           ]

    assert get_in(link_capacity_report_model_limits, ["items", "enum"]) ==
             Enum.uniq(link_capacity_model_limits ++ link_capacity_budget_model_limits)

    assert get_in(schemas, [
             "link_capacity_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == link_capacity_model_limits

    assert get_in(schemas, [
             "relay_data_path_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == link_capacity_capabilities.relay_data_path_model_limits

    assert get_in(schemas, ["resource_filter_summary.v1", "properties", "model", "const"]) ==
             "artifact_only_resource_filter_summary"

    assert get_in(schemas, [
             "resource_filter_summary.v1",
             "properties",
             "source_artifact_type",
             "const"
           ]) == "resource_filter_report.v1"

    resource_filter_model_limits =
      OrbitalDynamics.ResourceFilter.capabilities().known_limits
      |> Enum.map(&Atom.to_string/1)

    assert get_in(schemas, [
             "resource_filter_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == resource_filter_model_limits

    assert get_in(schemas, [
             "resource_filter_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == resource_filter_model_limits

    assert get_in(schemas, ["contact_intent_summary.v1", "properties", "model", "const"]) ==
             "artifact_only_contact_intent_summary"

    assert get_in(schemas, [
             "contact_intent_summary.v1",
             "properties",
             "source_artifact_type",
             "const"
           ]) == "contact_intent.v1"

    assert get_in(schemas, [
             "contact_intent_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) ==
             OrbitalDynamics.Communications.ContactIntent.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)
             |> Enum.sort()

    assert get_in(schemas, [
             "contact_intent_summary.v1",
             "properties",
             "contact_ids_by_direction",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    candidate_refresh_contact_intent_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "contact_intent",
        "properties"
      ])

    assert get_in(candidate_refresh_contact_intent_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "contact_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(candidate_refresh_contact_intent_source_report, [
             "capacity_pack_required_capacity_fraction_by_direction",
             "additionalProperties",
             "minimum"
           ]) == 0.0

    assert get_in(candidate_refresh_contact_intent_source_report, [
             "station_feedback_count",
             "minimum"
           ]) == 0

    Enum.each(
      [
        "station_calendar_status_counts",
        "cadence_import_status_counts",
        "policy_classification_counts",
        "direction_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_contact_intent_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    assert get_in(candidate_refresh_contact_intent_source_report, [
             "capacity_pack_required_contact_count",
             "minimum"
           ]) == 0

    assert get_in(candidate_refresh_contact_intent_source_report, [
             "capacity_pack_required_capacity_fraction",
             "type"
           ]) == ["number", "null"]

    assert get_in(candidate_refresh_contact_intent_source_report, [
             "capacity_pack_required_capacity_fraction_by_direction_and_ground_station",
             "additionalProperties",
             "additionalProperties",
             "minimum"
           ]) == 0.0

    Enum.each(
      [
        "required_capacity_fraction_contact_ids_by_source",
        "capacity_pack_contact_ids_by_ground_station",
        "contact_ids_by_ground_station",
        "capacity_pack_contact_ids_by_direction"
      ],
      fn field ->
        assert get_in(candidate_refresh_contact_intent_source_report, [
                 field,
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_contact_intent_source_report, [
             "contact_ids_by_direction_and_ground_station",
             "additionalProperties",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    candidate_refresh_station_calendar_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "station_calendar_report",
        "properties"
      ])

    assert get_in(candidate_refresh_station_calendar_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "provider_contention_provider_entry_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(candidate_refresh_station_calendar_source_report, [
             "provider_calendar_contention_capacity_fractions_by_direction",
             "additionalProperties",
             "items",
             "type"
           ]) == "number"

    candidate_refresh_station_reservation_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "station_reservation_report",
        "properties"
      ])

    Enum.each(
      [
        "contact_ids",
        "reservation_hold_ids",
        "reservation_hold_contact_ids"
      ],
      fn field ->
        assert get_in(candidate_refresh_station_reservation_source_report, [
                 "direction_routing",
                 "additionalProperties",
                 "properties",
                 field,
                 "type"
               ]) == "array"

        assert get_in(candidate_refresh_station_reservation_source_report, [
                 "direction_routing",
                 "additionalProperties",
                 "properties",
                 field,
                 "items",
                 "pattern"
               ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_station_reservation_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "contact_count",
             "type"
           ]) == "integer"

    assert get_in(candidate_refresh_station_reservation_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "contact_count",
             "minimum"
           ]) == 0

    candidate_refresh_contact_allocation_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "contact_allocation_report",
        "properties"
      ])

    Enum.each(
      [
        "contact_count",
        "station_pressure_contact_count",
        "reservation_conflict_contact_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_contact_allocation_source_report, [
                 "direction_routing",
                 "additionalProperties",
                 "properties",
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_contact_allocation_source_report, [
                 "direction_routing",
                 "additionalProperties",
                 "properties",
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "contact_ids",
        "station_pressure_contact_ids",
        "reservation_conflict_contact_ids",
        "provider_reservation_no_request_contact_ids",
        "provider_reservation_request_contact_ids",
        "provider_reservation_review_contact_ids"
      ],
      fn field ->
        assert get_in(candidate_refresh_contact_allocation_source_report, [
                 "direction_routing",
                 "additionalProperties",
                 "properties",
                 field,
                 "type"
               ]) == "array"

        assert get_in(candidate_refresh_contact_allocation_source_report, [
                 "direction_routing",
                 "additionalProperties",
                 "properties",
                 field,
                 "items",
                 "pattern"
               ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    candidate_refresh_contact_contention_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "contact_contention_report",
        "properties"
      ])

    Enum.each(
      [
        "conflict_group_count",
        "invalid_contact_input_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_contact_contention_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_contact_contention_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "resource_scope_counts",
        "contact_contention_ground_station_counts",
        "contact_contention_contact_id_counts",
        "direction_counts",
        "required_operator_action_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_contact_contention_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_contact_contention_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        ["invalid_contact_input_ids", "items"],
        ["contact_ids_by_direction", "additionalProperties", "items"],
        [
          "direction_routing",
          "additionalProperties",
          "properties",
          "contact_ids",
          "items"
        ]
      ],
      fn path ->
        assert get_in(candidate_refresh_contact_contention_source_report, path ++ ["pattern"]) ==
                 "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_contact_contention_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "contact_count",
             "type"
           ]) == "integer"

    assert get_in(candidate_refresh_contact_contention_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "contact_count",
             "minimum"
           ]) == 0

    candidate_refresh_contact_contention_resolution_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "contact_contention_resolution_report",
        "properties"
      ])

    Enum.each(
      [
        "conflict_group_count",
        "recommendation_count",
        "review_recommendation_count",
        "deferred_contact_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_contact_contention_resolution_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_contact_contention_resolution_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "resolution_status_counts",
        "selection_reason_counts",
        "resource_scope_counts",
        "direction_counts",
        "required_operator_action_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_contact_contention_resolution_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_contact_contention_resolution_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        ["recommendation_group_ids", "items"],
        ["review_group_ids", "items"],
        ["ambiguous_group_ids", "items"],
        ["ambiguous_duplicate_contact_ids", "items"],
        ["selected_contact_ids", "items"],
        ["deferred_contact_ids", "items"],
        ["review_contact_ids", "items"],
        ["ambiguous_duplicate_contact_ids_by_group_id", "additionalProperties", "items"],
        ["selected_contact_ids_by_group_id", "additionalProperties", "items"],
        ["deferred_contact_ids_by_group_id", "additionalProperties", "items"],
        ["review_contact_ids_by_group_id", "additionalProperties", "items"],
        ["selected_contact_ids_by_selection_reason", "additionalProperties", "items"],
        ["selected_contact_ids_by_ground_station", "additionalProperties", "items"],
        ["deferred_contact_ids_by_ground_station", "additionalProperties", "items"],
        ["selected_contact_ids_by_resource_scope", "additionalProperties", "items"],
        ["deferred_contact_ids_by_resource_scope", "additionalProperties", "items"],
        ["review_contact_ids_by_resource_scope", "additionalProperties", "items"],
        ["contact_ids_by_direction", "additionalProperties", "items"],
        ["review_contact_ids_by_action", "additionalProperties", "items"],
        [
          "direction_routing",
          "additionalProperties",
          "properties",
          "contact_ids",
          "items"
        ]
      ],
      fn path ->
        assert get_in(
                 candidate_refresh_contact_contention_resolution_source_report,
                 path ++
                   [
                     "pattern"
                   ]
               ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_contact_contention_resolution_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "contact_count",
             "type"
           ]) == "integer"

    assert get_in(candidate_refresh_contact_contention_resolution_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "contact_count",
             "minimum"
           ]) == 0

    candidate_refresh_link_capacity_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "link_capacity_report",
        "properties"
      ])

    Enum.each(
      [
        "selected_shortfall_row_count",
        "actual_shortfall_row_count",
        "actual_throughput_row_count",
        "capacity_adjusted_throughput_row_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_link_capacity_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_link_capacity_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "capacity_adjusted_throughput_mb_total",
        "selected_capacity_adjusted_throughput_mb_total",
        "unused_capacity_adjusted_throughput_mb_total"
      ],
      fn field ->
        assert get_in(candidate_refresh_link_capacity_source_report, [
                 field,
                 "type"
               ]) == "number"
      end
    )

    Enum.each(
      [
        "ground_station_counts",
        "spacecraft_counts",
        "direction_counts",
        "selected_contact_id_counts",
        "actual_throughput_contact_id_counts",
        "downlink_requirement_status_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_link_capacity_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_link_capacity_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "capacity_adjusted_throughput_mb_by_ground_station",
        "selected_capacity_adjusted_throughput_mb_by_ground_station",
        "unused_capacity_adjusted_throughput_mb_by_ground_station",
        "capacity_adjusted_throughput_mb_by_direction",
        "selected_capacity_adjusted_throughput_mb_by_direction",
        "unused_capacity_adjusted_throughput_mb_by_direction"
      ],
      fn field ->
        assert get_in(candidate_refresh_link_capacity_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "number"
      end
    )

    assert get_in(candidate_refresh_link_capacity_source_report, [
             "directions",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        ["selected_contact_ids", "items"],
        ["selected_source_window_ids", "items"],
        ["selected_station_calendar_entry_ids", "items"],
        ["selected_station_calendar_provider_entry_ids", "items"],
        ["actual_throughput_contact_ids", "items"],
        ["actual_throughput_source_window_ids", "items"],
        ["actual_throughput_station_calendar_entry_ids", "items"],
        ["actual_throughput_station_calendar_provider_entry_ids", "items"],
        ["contact_ids_by_direction", "additionalProperties", "items"],
        ["source_window_ids_by_direction", "additionalProperties", "items"],
        ["station_calendar_entry_ids_by_direction", "additionalProperties", "items"],
        ["station_calendar_provider_entry_ids_by_direction", "additionalProperties", "items"],
        ["contact_ids_by_ground_station", "additionalProperties", "items"],
        ["source_window_ids_by_ground_station", "additionalProperties", "items"],
        ["station_calendar_entry_ids_by_ground_station", "additionalProperties", "items"],
        [
          "station_calendar_provider_entry_ids_by_ground_station",
          "additionalProperties",
          "items"
        ],
        ["contact_ids_by_spacecraft", "additionalProperties", "items"],
        ["source_window_ids_by_spacecraft", "additionalProperties", "items"],
        ["station_calendar_entry_ids_by_spacecraft", "additionalProperties", "items"],
        ["station_calendar_provider_entry_ids_by_spacecraft", "additionalProperties", "items"],
        ["contact_ids_by_requirement_status", "additionalProperties", "items"],
        ["source_window_ids_by_requirement_status", "additionalProperties", "items"],
        [
          "station_calendar_entry_ids_by_requirement_status",
          "additionalProperties",
          "items"
        ],
        [
          "station_calendar_provider_entry_ids_by_requirement_status",
          "additionalProperties",
          "items"
        ],
        [
          "direction_routing",
          "additionalProperties",
          "properties",
          "contact_ids",
          "items"
        ],
        [
          "direction_routing",
          "additionalProperties",
          "properties",
          "source_window_ids",
          "items"
        ],
        [
          "direction_routing",
          "additionalProperties",
          "properties",
          "station_calendar_entry_ids",
          "items"
        ],
        [
          "direction_routing",
          "additionalProperties",
          "properties",
          "station_calendar_provider_entry_ids",
          "items"
        ]
      ],
      fn path ->
        assert get_in(candidate_refresh_link_capacity_source_report, path ++ ["pattern"]) ==
                 "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_link_capacity_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "contact_count",
             "minimum"
           ]) == 0

    Enum.each(
      [
        "capacity_adjusted_throughput_mb",
        "selected_capacity_adjusted_throughput_mb",
        "unused_capacity_adjusted_throughput_mb"
      ],
      fn field ->
        assert get_in(candidate_refresh_link_capacity_source_report, [
                 "direction_routing",
                 "additionalProperties",
                 "properties",
                 field,
                 "type"
               ]) == "number"
      end
    )

    candidate_refresh_resource_projection_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "resource_projection_report",
        "properties"
      ])

    Enum.each(
      [
        "projected_resource_count",
        "invalid_activity_input_count",
        "invalid_resource_summary_input_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_resource_projection_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_resource_projection_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "resource_pressure_status_counts",
        "resource_projection_spacecraft_counts",
        "resource_pressure_type_counts",
        "resource_pressure_activity_id_counts",
        "resource_pressure_direction_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_resource_projection_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_resource_projection_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    assert get_in(candidate_refresh_resource_projection_source_report, [
             "resource_pressure_directions",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        "invalid_activity_input_ids",
        "invalid_resource_summary_input_ids"
      ],
      fn field ->
        assert get_in(candidate_refresh_resource_projection_source_report, [
                 field,
                 "items",
                 "pattern"
               ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    Enum.each(
      [
        "resource_pressure_activity_ids_by_status",
        "resource_pressure_activity_ids_by_type",
        "resource_pressure_activity_ids_by_ground_station",
        "resource_pressure_activity_ids_by_spacecraft",
        "resource_pressure_activity_ids_by_direction"
      ],
      fn field ->
        assert get_in(candidate_refresh_resource_projection_source_report, [
                 field,
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_resource_projection_source_report, [
             "resource_pressure_direction_routing",
             "additionalProperties",
             "properties",
             "pressure_count",
             "minimum"
           ]) == 0

    assert get_in(candidate_refresh_resource_projection_source_report, [
             "resource_pressure_direction_routing",
             "additionalProperties",
             "properties",
             "activity_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    candidate_refresh_command_window_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "command_window_report",
        "properties"
      ])

    assert get_in(candidate_refresh_command_window_source_report, [
             "command_feedback_count",
             "type"
           ]) == "integer"

    assert get_in(candidate_refresh_command_window_source_report, [
             "command_feedback_count",
             "minimum"
           ]) == 0

    assert get_in(candidate_refresh_command_window_source_report, [
             "input_keys",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        "direction_counts",
        "required_operator_action_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_command_window_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_command_window_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        ["activity_ids_by_direction", "additionalProperties", "items"],
        ["window_ids_by_direction", "additionalProperties", "items"],
        [
          "direction_routing",
          "additionalProperties",
          "properties",
          "activity_ids",
          "items"
        ],
        [
          "direction_routing",
          "additionalProperties",
          "properties",
          "window_ids",
          "items"
        ]
      ],
      fn path ->
        assert get_in(candidate_refresh_command_window_source_report, path ++ ["pattern"]) ==
                 "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_command_window_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "activity_count",
             "minimum"
           ]) == 0

    candidate_refresh_maneuver_review_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "maneuver_review_report",
        "properties"
      ])

    Enum.each(
      [
        "maneuver_success_feedback_count",
        "execution_uncertainty_declared_count",
        "execution_uncertainty_missing_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_maneuver_review_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_maneuver_review_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    assert get_in(candidate_refresh_maneuver_review_source_report, [
             "input_keys",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        "maneuver_id_counts",
        "required_operator_action_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_maneuver_review_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_maneuver_review_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    candidate_refresh_provider_counteroffer_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "provider_counteroffer_report",
        "properties"
      ])

    Enum.each(
      [
        "reviewable_count",
        "counteroffer_cost_delta_count",
        "counteroffer_timing_shift_count",
        "counteroffer_start_delta_count",
        "counteroffer_end_delta_count",
        "counteroffer_duration_delta_count",
        "counteroffer_lock_deadline_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_provider_counteroffer_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_provider_counteroffer_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "counteroffer_cost_delta_total",
        "earliest_counteroffer_lock_deadline_s"
      ],
      fn field ->
        assert get_in(candidate_refresh_provider_counteroffer_source_report, [
                 field,
                 "type"
               ]) == "number"
      end
    )

    assert get_in(candidate_refresh_provider_counteroffer_source_report, [
             "counteroffer_status_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(candidate_refresh_provider_counteroffer_source_report, [
             "required_operator_action_counts",
             "propertyNames",
             "enum"
           ]) ==
             OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_actions

    assert get_in(candidate_refresh_provider_counteroffer_source_report, [
             "required_operator_action_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    candidate_refresh_model_acceptance_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "model_acceptance_report",
        "properties"
      ])

    Enum.each(
      [
        "record_count",
        "model_count",
        "accepted_count",
        "review_required_count",
        "blocked_count",
        "unknown_model_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_model_acceptance_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_model_acceptance_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "intended_use_counts",
        "status_counts",
        "validation_level_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_model_acceptance_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_model_acceptance_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "model_ids_by_status",
        "model_ids_by_validation_level",
        "model_ids_by_intended_use"
      ],
      fn field ->
        assert get_in(candidate_refresh_model_acceptance_source_report, [
                 field,
                 "additionalProperties",
                 "items",
                 "type"
               ]) == "string"
      end
    )

    candidate_refresh_operational_readiness_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "operational_readiness_report",
        "properties"
      ])

    Enum.each(
      [
        "gate_count",
        "passed_gate_count",
        "review_gate_count",
        "analysis_gate_count",
        "blocked_gate_count",
        "review_required_count",
        "source_model_limit_count",
        "resource_availability_pressure_count",
        "adapter_context_count",
        "adapter_trust_boundary_declared_count",
        "ready_for_import_count",
        "manifest_review_required_count",
        "blocked_import_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_operational_readiness_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_operational_readiness_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "readiness_level_counts",
        "import_classification_counts",
        "status_counts",
        "review_type_counts",
        "import_action_counts",
        "source_review_type_counts",
        "resource_availability_reason_counts",
        "station_availability_reason_counts",
        "resource_blocking_dimension_counts",
        "adapter_boundary_status_counts",
        "import_status_counts",
        "cadence_import_status_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_operational_readiness_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_operational_readiness_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "resource_availability_reason_ids",
        "station_availability_reason_ids",
        "unavailable_resource_reason_ids"
      ],
      fn field ->
        assert get_in(candidate_refresh_operational_readiness_source_report, [
                 field,
                 "items",
                 "type"
               ]) == "string"
      end
    )

    assert get_in(candidate_refresh_operational_readiness_source_report, [
             "resource_blocked_contact_ids_by_blocking_dimension",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    candidate_refresh_freshness_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "freshness_report",
        "properties"
      ])

    Enum.each(["stale_reason_count", "unknown_reason_count"], fn field ->
      assert get_in(candidate_refresh_freshness_source_report, [
               field,
               "type"
             ]) == "integer"

      assert get_in(candidate_refresh_freshness_source_report, [
               field,
               "minimum"
             ]) == 0
    end)

    Enum.each(["status_counts", "stale_reason_counts", "unknown_reason_counts"], fn field ->
      assert get_in(candidate_refresh_freshness_source_report, [
               field,
               "additionalProperties",
               "minimum"
             ]) == 0
    end)

    Enum.each(["stale_reasons", "unknown_reasons"], fn field ->
      assert get_in(candidate_refresh_freshness_source_report, [
               field,
               "items",
               "type"
             ]) == "string"
    end)

    candidate_refresh_objective_satisfaction_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "objective_satisfaction_report",
        "properties"
      ])

    candidate_refresh_objective_tradeoff_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "objective_tradeoff_report",
        "properties"
      ])

    candidate_refresh_score_term_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "score_term_report",
        "properties"
      ])

    Enum.each(
      [
        candidate_refresh_objective_satisfaction_source_report,
        candidate_refresh_objective_tradeoff_source_report,
        candidate_refresh_score_term_source_report
      ],
      fn source_report ->
        Enum.each(
          [
            "downlink_gap_row_count",
            "target_gap_row_count",
            "collection_latency_gap_row_count"
          ],
          fn field ->
            assert get_in(source_report, [field, "minimum"]) == 0
          end
        )

        Enum.each(
          [
            "ground_station_counts",
            "target_counts",
            "collection_counts",
            "source_activity_id_counts"
          ],
          fn field ->
            assert get_in(source_report, [
                     field,
                     "additionalProperties",
                     "minimum"
                   ]) == 0
          end
        )
      end
    )

    assert get_in(candidate_refresh_objective_satisfaction_source_report, [
             "gap_row_count",
             "minimum"
           ]) == 0

    assert get_in(candidate_refresh_objective_satisfaction_source_report, [
             "objective_type_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(candidate_refresh_score_term_source_report, [
             "term_key_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    candidate_refresh_refresh_budget_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "refresh_budget_report",
        "properties"
      ])

    Enum.each(
      [
        "input_candidate_count",
        "kept_candidate_count",
        "dropped_candidate_count",
        "invalid_candidate_limit_policy_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_refresh_budget_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_refresh_budget_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    assert get_in(candidate_refresh_refresh_budget_source_report, [
             "invalid_candidate_limit_policy_reason_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    Enum.each(["kept_candidate_ids", "dropped_candidate_ids"], fn field ->
      assert get_in(candidate_refresh_refresh_budget_source_report, [
               field,
               "items",
               "pattern"
             ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
    end)

    candidate_refresh_validation_safety_case_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "validation_safety_case_summary",
        "properties"
      ])

    Enum.each(
      [
        "accepted_evidence_count",
        "review_required_evidence_count",
        "blocked_evidence_count",
        "model_blocked_count",
        "schema_warning_count",
        "schema_validation_failed_report_count",
        "fixture_failed_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_validation_safety_case_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_validation_safety_case_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "status_counts",
        "evidence_status_counts",
        "input_contract_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_validation_safety_case_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_validation_safety_case_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "evidence_refs_by_status",
        "evidence_refs_by_contract"
      ],
      fn field ->
        assert get_in(candidate_refresh_validation_safety_case_source_report, [
                 field,
                 "additionalProperties",
                 "items",
                 "type"
               ]) == "string"
      end
    )

    candidate_refresh_operational_timeline_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "operational_timeline_report",
        "properties"
      ])

    assert get_in(candidate_refresh_operational_timeline_source_report, [
             "input_keys",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        "contact_feedback_count",
        "command_feedback_count",
        "maneuver_feedback_count",
        "observation_feedback_count",
        "station_throughput_feedback_count",
        "timeline_integrity_issue_count",
        "dependency_integrity_issue_count",
        "exclusivity_integrity_issue_count",
        "station_reservation_evidence_row_count",
        "station_reservation_expiration_evidence_row_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_operational_timeline_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_operational_timeline_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "operational_kind_counts",
        "activity_id_counts",
        "activity_status_counts",
        "approval_status_counts",
        "required_operator_action_counts",
        "cadence_import_status_counts",
        "timeline_integrity_issue_type_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_operational_timeline_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_operational_timeline_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    candidate_refresh_timeline_transition_application_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_transition_application_report",
        "properties"
      ])

    Enum.each(
      [
        "application_count",
        "selected_activity_count",
        "review_required_count",
        "preserved_source_count",
        "recorded_replacement_count",
        "withheld_review_count",
        "duplicate_timeline_identity_count",
        "duplicate_source_timeline_identity_count",
        "duplicate_replacement_timeline_identity_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_transition_application_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_transition_application_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "selected_activity_id_counts",
        "review_activity_id_counts",
        "application_status_counts",
        "transition_decision_counts",
        "required_operator_action_counts",
        "duplicate_timeline_identity_scope_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_transition_application_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_transition_application_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    candidate_refresh_quality_gate_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "quality_gate_report",
        "properties"
      ])

    Enum.each(
      [
        "gate_count",
        "passed_gate_count",
        "review_gate_count",
        "analysis_gate_count",
        "blocked_gate_count",
        "ready_for_import_count",
        "manifest_review_required_count",
        "blocked_import_count",
        "missing_import_count",
        "invalid_cadence_import_count",
        "resource_availability_pressure_count",
        "source_readiness_report_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_quality_gate_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_quality_gate_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "readiness_level_counts",
        "import_classification_counts",
        "status_counts",
        "gate_status_counts",
        "gate_classification_counts",
        "freshness_status_counts",
        "schema_validation_status_counts",
        "import_status_counts",
        "cadence_import_status_counts",
        "resource_availability_reason_counts",
        "station_availability_reason_counts",
        "resource_blocking_dimension_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_quality_gate_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_quality_gate_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "resource_availability_reason_ids",
        "station_availability_reason_ids",
        "unavailable_resource_reason_ids",
        "review_required_quality_gate_row_ids",
        "blocked_quality_gate_row_ids",
        "ready_quality_gate_row_ids",
        "analysis_only_quality_gate_row_ids",
        "stale_or_unknown_freshness_quality_gate_row_ids",
        "import_preparation_quality_gate_row_ids",
        "blocked_import_quality_gate_row_ids",
        "import_readiness_gate_ids"
      ],
      fn field ->
        assert get_in(candidate_refresh_quality_gate_source_report, [
                 field,
                 "items",
                 "type"
               ]) == "string"
      end
    )

    Enum.each(
      [
        "quality_gate_row_ids_by_status",
        "quality_gate_ids_by_status"
      ],
      fn field ->
        assert get_in(candidate_refresh_quality_gate_source_report, [
                 field,
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    candidate_refresh_schema_validation_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "schema_validation_report",
        "properties"
      ])

    Enum.each(
      [
        "error_count",
        "warning_count",
        "remediation_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_schema_validation_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_schema_validation_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "status_counts",
        "validated_contract_counts",
        "validation_mode_counts",
        "remediation_action_counts",
        "remediation_category_counts",
        "remediation_path_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_schema_validation_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_schema_validation_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    candidate_refresh_timeline_diff_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_diff_report",
        "properties"
      ])

    Enum.each(
      [
        "duplicate_timeline_identity_count",
        "duplicate_source_timeline_identity_count",
        "duplicate_replacement_timeline_identity_count",
        "removed_downlink_count",
        "removed_observation_count",
        "changed_downlink_shortfall_count",
        "changed_contact_feedback_count",
        "changed_observation_count",
        "changed_observation_quality_feedback_count",
        "changed_command_feedback_count",
        "changed_maneuver_feedback_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_diff_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_diff_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "diff_status_counts",
        "required_operator_action_counts",
        "duplicate_timeline_identity_scope_counts",
        "source_activity_id_counts",
        "replacement_activity_id_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_diff_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_diff_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    candidate_refresh_timeline_feedback_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_feedback_report",
        "properties"
      ])

    assert get_in(candidate_refresh_timeline_feedback_source_report, [
             "input_keys",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        "station_reservation_evidence_row_count",
        "station_reservation_expiration_evidence_row_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_feedback_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_feedback_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "status_counts",
        "feedback_kind_counts",
        "match_strategy_counts",
        "activity_id_counts",
        "cadence_import_status_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_feedback_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_feedback_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    candidate_refresh_timeline_publication_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_publication_summary",
        "properties"
      ])

    Enum.each(
      [
        "dependency_impact_row_count",
        "timeline_diff_row_count",
        "timeline_diff_changed_count",
        "timeline_diff_review_required_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_publication_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_publication_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "publication_status_counts",
        "dependency_impact_status_counts",
        "publication_authority_counts",
        "source_artifact_type_counts",
        "timeline_publication_source_artifact_type_counts",
        "changed_field_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_publication_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_publication_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "publication_ids",
        "source_artifact_ids",
        "supersedes_artifact_ids",
        "downstream_product_ids",
        "invalidated_downstream_product_ids",
        "impacted_dependency_activity_ids",
        "impacted_dependency_timeline_ids",
        "impacted_exclusive_with_activity_ids",
        "impacted_exclusive_with_timeline_ids",
        "changed_timeline_ids",
        "review_timeline_ids"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_publication_source_report, [
                 field,
                 "items",
                 "pattern"
               ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_timeline_publication_source_report, [
             "timeline_ids_by_changed_field",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    candidate_refresh_timeline_dependency_impact_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_dependency_impact_summary",
        "properties"
      ])

    Enum.each(
      [
        "source_activity_count",
        "replacement_activity_count",
        "changed_source_activity_count",
        "changed_source_timeline_count",
        "dependent_activity_count",
        "source_dependent_activity_count",
        "replacement_dependent_activity_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_dependency_impact_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_dependency_impact_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "dependency_impact_status_counts",
        "dependency_impact_scope_counts",
        "required_operator_action_counts",
        "impacted_source_activity_id_counts",
        "impacted_source_timeline_id_counts",
        "impacted_dependency_activity_id_counts",
        "impacted_dependency_timeline_id_counts",
        "impacted_exclusive_activity_id_counts",
        "impacted_exclusive_timeline_id_counts",
        "dependent_activity_id_counts",
        "dependent_timeline_id_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_dependency_impact_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_dependency_impact_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    candidate_refresh_constraint_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "constraint_report",
        "properties"
      ])

    Enum.each(
      [
        "downlink_gap_row_count",
        "resource_margin_row_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_constraint_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_constraint_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "status_counts",
        "ground_station_counts",
        "constraint_metric_counts",
        "constraint_id_counts",
        "source_activity_id_counts",
        "constraint_resource_counts",
        "constraint_spacecraft_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_constraint_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_constraint_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    candidate_refresh_candidate_diff_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "candidate_diff_report",
        "properties"
      ])

    Enum.each(
      [
        "retained_candidate_count",
        "new_candidate_count",
        "invalidated_candidate_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_candidate_diff_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_candidate_diff_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "diff_reason_counts",
        "invalidated_reason_counts",
        "semantic_change_reason_counts",
        "candidate_diff_changed_field_counts",
        "candidate_diff_candidate_id_counts",
        "candidate_diff_ground_station_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_candidate_diff_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_candidate_diff_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    candidate_refresh_candidate_rejection_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "candidate_rejection_report",
        "properties"
      ])

    Enum.each(
      [
        "rejected_count",
        "reviewable_count",
        "invalid_candidate_input_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_candidate_rejection_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_candidate_rejection_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "rejection_reason_counts",
        "required_operator_action_counts",
        "candidate_rejection_candidate_id_counts",
        "candidate_rejection_ground_station_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_candidate_rejection_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_candidate_rejection_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    candidate_refresh_timeline_activity_precondition_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_activity_precondition_summary",
        "properties"
      ])

    Enum.each(
      [
        "blocked_precondition_count",
        "review_precondition_count",
        "invalid_activity_input_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_activity_precondition_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_activity_precondition_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "source_summary_model_counts",
        "source_summary_schema_contract_counts",
        "precondition_status_counts",
        "blocked_precondition_type_counts",
        "review_precondition_type_counts",
        "invalid_activity_input_reason_counts",
        "activity_id_counts",
        "timeline_id_counts",
        "dependency_activity_id_counts",
        "dependency_timeline_id_counts",
        "exclusive_with_activity_id_counts",
        "exclusive_with_timeline_id_counts",
        "allow_overlap_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_activity_precondition_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_activity_precondition_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    assert get_in(candidate_refresh_timeline_activity_precondition_source_report, [
             "invalid_activity_input_reasons",
             "items",
             "type"
           ]) == "string"

    candidate_refresh_timeline_activity_state_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "timeline_activity_state",
        "properties"
      ])

    Enum.each(
      [
        "review_required_count",
        "invalid_activity_input_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_activity_state_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_activity_state_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "invalid_activity_input_reason_counts",
        "state_status_counts",
        "transition_decision_counts",
        "planned_status_category_counts",
        "realized_status_category_counts",
        "planned_approval_category_counts",
        "realized_approval_category_counts",
        "status_transition_category_counts",
        "approval_transition_category_counts",
        "required_operator_action_counts",
        "import_action_counts",
        "activity_id_counts",
        "timeline_id_counts",
        "review_activity_id_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_activity_state_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_timeline_activity_state_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    assert get_in(candidate_refresh_timeline_activity_state_source_report, [
             "invalid_activity_input_reasons",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        ["action_routing", "additionalProperties", "properties", "activity_ids", "items"],
        ["action_routing", "additionalProperties", "properties", "timeline_ids", "items"]
      ],
      fn path ->
        assert get_in(
                 candidate_refresh_timeline_activity_state_source_report,
                 path ++ ["pattern"]
               ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_timeline_activity_state_source_report, [
             "action_routing",
             "additionalProperties",
             "properties",
             "review_count",
             "minimum"
           ]) == 0

    Enum.each(
      [
        "status_transition_categories",
        "approval_transition_categories"
      ],
      fn field ->
        assert get_in(candidate_refresh_timeline_activity_state_source_report, [
                 "action_routing",
                 "additionalProperties",
                 "properties",
                 field,
                 "items",
                 "type"
               ]) == "string"
      end
    )

    candidate_refresh_contact_filter_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "contact_filter_report",
        "properties"
      ])

    Enum.each(
      [
        "suppressed_candidate_count",
        "invalid_contact_input_count",
        "station_suppression_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_contact_filter_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_contact_filter_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "suppressed_reason_counts",
        "direction_counts",
        "station_suppression_ground_station_counts",
        "station_suppression_availability_counts",
        "station_suppression_status_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_contact_filter_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_contact_filter_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    assert get_in(candidate_refresh_contact_filter_source_report, [
             "directions",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        ["invalid_contact_input_ids", "items"],
        ["contact_ids_by_suppressed_reason", "additionalProperties", "items"],
        ["contact_ids_by_direction", "additionalProperties", "items"],
        [
          "station_suppression_contact_ids_by_ground_station",
          "additionalProperties",
          "items"
        ],
        [
          "station_suppression_contact_ids_by_availability",
          "additionalProperties",
          "items"
        ],
        ["station_suppression_contact_ids_by_status", "additionalProperties", "items"],
        [
          "station_suppression_station_calendar_entry_ids_by_ground_station",
          "additionalProperties",
          "items"
        ],
        [
          "station_suppression_station_calendar_entry_ids_by_availability",
          "additionalProperties",
          "items"
        ],
        [
          "station_suppression_station_calendar_entry_ids_by_status",
          "additionalProperties",
          "items"
        ],
        [
          "station_suppression_station_calendar_provider_entry_ids_by_ground_station",
          "additionalProperties",
          "items"
        ],
        [
          "station_suppression_station_calendar_provider_entry_ids_by_availability",
          "additionalProperties",
          "items"
        ],
        [
          "station_suppression_station_calendar_provider_entry_ids_by_status",
          "additionalProperties",
          "items"
        ],
        [
          "station_suppression_station_reservation_ids_by_ground_station",
          "additionalProperties",
          "items"
        ],
        [
          "station_suppression_station_reservation_ids_by_availability",
          "additionalProperties",
          "items"
        ],
        [
          "station_suppression_station_reservation_ids_by_status",
          "additionalProperties",
          "items"
        ],
        [
          "direction_routing",
          "additionalProperties",
          "properties",
          "contact_ids",
          "items"
        ]
      ],
      fn path ->
        assert get_in(candidate_refresh_contact_filter_source_report, path ++ ["pattern"]) ==
                 "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_contact_filter_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "contact_count",
             "minimum"
           ]) == 0

    candidate_refresh_resource_filter_source_report =
      get_in(schemas, [
        "candidate_refresh.v1",
        "properties",
        "provenance",
        "properties",
        "source_reports",
        "properties",
        "resource_filter_report",
        "properties"
      ])

    Enum.each(
      [
        "suppressed_candidate_count",
        "invalid_resource_summary_input_count"
      ],
      fn field ->
        assert get_in(candidate_refresh_resource_filter_source_report, [
                 field,
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_resource_filter_source_report, [
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "suppressed_reason_counts",
        "resource_filter_spacecraft_counts",
        "resource_filter_resource_counts",
        "resource_filter_blocking_dimension_counts",
        "direction_counts"
      ],
      fn field ->
        assert get_in(candidate_refresh_resource_filter_source_report, [
                 field,
                 "additionalProperties",
                 "type"
               ]) == "integer"

        assert get_in(candidate_refresh_resource_filter_source_report, [
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    assert get_in(candidate_refresh_resource_filter_source_report, [
             "directions",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        ["invalid_resource_summary_input_ids", "items"],
        ["candidate_ids_by_suppressed_reason", "additionalProperties", "items"],
        ["candidate_ids_by_spacecraft", "additionalProperties", "items"],
        ["candidate_ids_by_resource", "additionalProperties", "items"],
        ["candidate_ids_by_blocking_dimension", "additionalProperties", "items"],
        ["candidate_ids_by_direction", "additionalProperties", "items"],
        [
          "direction_routing",
          "additionalProperties",
          "properties",
          "candidate_ids",
          "items"
        ]
      ],
      fn path ->
        assert get_in(candidate_refresh_resource_filter_source_report, path ++ ["pattern"]) ==
                 "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(candidate_refresh_resource_filter_source_report, [
             "direction_routing",
             "additionalProperties",
             "properties",
             "candidate_count",
             "minimum"
           ]) == 0

    assert Map.has_key?(schemas, "contact_allocation_summary.v1")
    assert Map.has_key?(schemas, "contact_allocation_reservation_conflict_summary.v1")
    assert Map.has_key?(schemas, "contact_allocation_station_pressure_summary.v1")
    assert Map.has_key?(schemas, "contact_allocation_capacity_pack_summary.v1")
    assert Map.has_key?(schemas, "contact_allocation_provider_reservation_request_summary.v1")

    assert get_in(schemas, [
             "contact_allocation_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) ==
             OrbitalDynamics.Communications.ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert get_in(schemas, [
             "contact_allocation_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_contact_allocation_summary"

    assert get_in(schemas, [
             "contact_allocation_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) ==
             OrbitalDynamics.Communications.ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert get_in(schemas, [
             "contact_allocation_reservation_conflict_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_contact_allocation_reservation_conflict_summary"

    assert get_in(schemas, [
             "contact_allocation_reservation_conflict_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) ==
             OrbitalDynamics.Communications.ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert get_in(schemas, [
             "contact_allocation_station_pressure_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_contact_allocation_station_pressure_summary"

    assert get_in(schemas, [
             "contact_allocation_station_pressure_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) ==
             OrbitalDynamics.Communications.ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert get_in(schemas, [
             "contact_allocation_capacity_pack_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_contact_allocation_capacity_pack_summary"

    assert get_in(schemas, [
             "contact_allocation_capacity_pack_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) ==
             OrbitalDynamics.Communications.ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    provider_reservation_request_schema =
      schemas["contact_allocation_provider_reservation_request_summary.v1"]

    assert get_in(provider_reservation_request_schema, [
             "properties",
             "model",
             "const"
           ]) == "artifact_only_contact_allocation_provider_reservation_request_summary"

    assert get_in(provider_reservation_request_schema, [
             "properties",
             "source",
             "type"
           ]) == "string"

    assert get_in(provider_reservation_request_schema, [
             "properties",
             "model_limits",
             "const"
           ]) ==
             OrbitalDynamics.Communications.ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    Enum.each(
      [
        "provider_reservation_no_request_contact_ids_by_direction",
        "provider_reservation_request_contact_ids_by_direction",
        "provider_reservation_review_contact_ids_by_direction"
      ],
      fn field ->
        assert get_in(provider_reservation_request_schema, [
                 "properties",
                 field,
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

        refute field in provider_reservation_request_schema["required"]
      end
    )

    assert Map.has_key?(schemas, "station_calendar_precedence_summary.v1")

    assert get_in(schemas, [
             "station_calendar_precedence_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_station_calendar_precedence_summary"

    assert get_in(schemas, [
             "station_calendar_precedence_summary.v1",
             "properties",
             "source"
           ]) == %{"type" => "string"}

    assert get_in(schemas, [
             "station_calendar_precedence_summary.v1",
             "properties",
             "reserved_under_higher_precedence_reservation_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "station_calendar_precedence_summary.v1",
             "properties",
             "reserved_under_higher_precedence_reservation_ids_by_status",
             "type"
           ]) == "object"

    assert get_in(schemas, [
             "station_calendar_precedence_summary.v1",
             "properties",
             "reserved_under_higher_precedence_contact_ids_by_reservation_status",
             "type"
           ]) == "object"

    assert get_in(schemas, [
             "station_calendar_precedence_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) ==
             OrbitalDynamics.Communications.StationCalendar.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert Map.has_key?(schemas, "operational_readiness_report.v1")
    assert Map.has_key?(schemas, "operational_import_eligibility_summary.v1")
    assert Map.has_key?(schemas, "operational_readiness_gate_summary.v1")
    assert Map.has_key?(schemas, "operational_execution_boundary_summary.v1")
    assert Map.has_key?(schemas, "operational_quality_gate_summary.v1")
    assert Map.has_key?(schemas, "operational_quality_gate_unavailable_resource_summary.v1")
    assert Map.has_key?(schemas, "operational_quality_gate_operator_training_summary.v1")
    assert Map.has_key?(schemas, "operational_quality_gate_schema_validation_summary.v1")
    assert Map.has_key?(schemas, "operational_quality_gate_import_readiness_summary.v1")

    readiness_report_schema = schemas["operational_readiness_report.v1"]

    assert get_in(readiness_report_schema, ["properties", "model_limits", "const"]) ==
             operational_readiness_model_limits()

    readiness_gate_summary_schema =
      schemas["operational_readiness_gate_summary.v1"]

    assert get_in(readiness_gate_summary_schema, ["properties", "model_limits", "const"]) ==
             operational_readiness_gate_summary_model_limits()

    execution_boundary_summary_schema =
      schemas["operational_execution_boundary_summary.v1"]

    assert get_in(execution_boundary_summary_schema, ["properties", "model_limits", "const"]) ==
             operational_execution_boundary_summary_model_limits()

    import_eligibility_summary_schema =
      schemas["operational_import_eligibility_summary.v1"]

    assert get_in(import_eligibility_summary_schema, ["properties", "model_limits", "const"]) ==
             operational_import_eligibility_summary_model_limits()

    quality_gate_summary_schema =
      schemas["operational_quality_gate_summary.v1"]

    assert get_in(quality_gate_summary_schema, ["properties", "model_limits", "const"]) ==
             quality_gate_summary_model_limits()

    schema_validation_summary_schema =
      schemas["operational_quality_gate_schema_validation_summary.v1"]

    assert get_in(schema_validation_summary_schema, ["properties", "model_limits", "const"]) ==
             quality_gate_schema_validation_summary_model_limits()

    operator_training_schema =
      schemas["operational_quality_gate_operator_training_summary.v1"]

    assert get_in(operator_training_schema, ["properties", "model_limits", "const"]) ==
             quality_gate_operator_training_summary_model_limits()

    unavailable_resource_schema =
      schemas["operational_quality_gate_unavailable_resource_summary.v1"]

    assert get_in(unavailable_resource_schema, [
             "properties",
             "station_availability_reason_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(unavailable_resource_schema, ["properties", "model_limits", "const"]) ==
             quality_gate_unavailable_resource_summary_model_limits()

    assert get_in(unavailable_resource_schema, [
             "properties",
             "station_availability_reason_ids",
             "items",
             "type"
           ]) == "string"

    refute "station_availability_reason_counts" in unavailable_resource_schema["required"]
    refute "station_availability_reason_ids" in unavailable_resource_schema["required"]

    import_readiness_schema =
      schemas["operational_quality_gate_import_readiness_summary.v1"]

    assert get_in(import_readiness_schema, [
             "properties",
             "analysis_only_quality_gate_row_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(import_readiness_schema, ["properties", "model_limits", "const"]) ==
             quality_gate_import_readiness_summary_model_limits()

    refute "analysis_only_quality_gate_row_ids" in import_readiness_schema["required"]

    assert Map.has_key?(schemas, "objective_satisfaction_report.v1")
    assert Map.has_key?(schemas, "monte_carlo_reproducibility_report.v1")
    assert Map.has_key?(schemas, "timeline_diff_summary.v1")

    assert Map.has_key?(schemas, "timeline_diff_report.v1")

    timeline_diff_report_schema = schemas["timeline_diff_report.v1"]

    assert get_in(timeline_diff_report_schema, ["properties", "model", "const"]) ==
             "timeline_identity_activity_diff"

    assert get_in(timeline_diff_report_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert Map.has_key?(schemas, "command_window_report.v1")

    command_window_report_schema = schemas["command_window_report.v1"]

    assert get_in(command_window_report_schema, ["properties", "model", "const"]) ==
             "artifact_only_command_window_report"

    assert get_in(command_window_report_schema, ["properties", "source", "type"]) == "string"

    timeline_diff_summary_schema = schemas["timeline_diff_summary.v1"]

    assert get_in(timeline_diff_summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_diff_summary"

    assert get_in(timeline_diff_summary_schema, [
             "properties",
             "validation_level",
             "const"
           ]) == "artifact_contract"

    assert get_in(timeline_diff_summary_schema, [
             "properties",
             "source_artifact_type",
             "const"
           ]) == "timeline_diff_report.v1"

    assert get_in(timeline_diff_summary_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(timeline_diff_summary_schema, [
             "properties",
             "review_timeline_ids_by_required_operator_action",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(timeline_diff_summary_schema, [
             "properties",
             "review_rows",
             "items",
             "required"
           ]) == [
             "id",
             "rank",
             "timeline_id",
             "diff_status",
             "changed_fields",
             "requires_operator_review",
             "required_operator_action",
             "reason"
           ]

    assert Map.has_key?(schemas, "timeline_transition_application_summary.v1")

    transition_application_summary_schema =
      schemas["timeline_transition_application_summary.v1"]

    assert get_in(transition_application_summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_transition_application_summary"

    assert get_in(transition_application_summary_schema, [
             "properties",
             "validation_level",
             "const"
           ]) == "artifact_contract"

    assert get_in(transition_application_summary_schema, [
             "properties",
             "source_artifact_type",
             "const"
           ]) == "timeline_transition_application_report.v1"

    assert get_in(transition_application_summary_schema, ["properties", "source", "type"]) ==
             "string"

    assert get_in(transition_application_summary_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(transition_application_summary_schema, [
             "properties",
             "selected_timeline_integrity_issue_types",
             "items",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types

    assert get_in(transition_application_summary_schema, [
             "properties",
             "selected_activity_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(transition_application_summary_schema, [
             "properties",
             "review_timeline_ids_by_required_operator_action",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(transition_application_summary_schema, [
             "properties",
             "review_timeline_ids_by_status_transition_category",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(transition_application_summary_schema, [
             "properties",
             "review_timeline_ids_by_approval_transition_category",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(transition_application_summary_schema, [
             "properties",
             "review_applications",
             "items",
             "required"
           ]) == [
             "id",
             "rank",
             "timeline_id",
             "diff_status",
             "transition_decision",
             "requires_operator_review",
             "required_operator_action",
             "reason",
             "changed_fields",
             "application_status",
             "source_timeline_diff"
           ]

    assert get_in(transition_application_summary_schema, [
             "x-orbital-dynamics",
             "nested_contracts"
           ]) == [
             "timeline_revision.v1",
             "timeline_transition_application_report.v1"
           ]

    assert Map.has_key?(schemas, "timeline_revision.v1")

    timeline_revision_schema = schemas["timeline_revision.v1"]

    assert get_in(timeline_revision_schema, ["properties", "schema_contract", "const"]) ==
             "timeline_revision.v1"

    assert get_in(timeline_revision_schema, ["properties", "identity_scheme", "const"]) ==
             "sha256_canonical_json"

    assert get_in(timeline_revision_schema, ["properties", "transition_batch_id", "pattern"]) =~
             "[0-9a-f]{64}"

    assert Map.has_key?(schemas, "timeline_transition_application_report.v1")

    transition_application_report_schema =
      schemas["timeline_transition_application_report.v1"]

    assert get_in(transition_application_report_schema, ["properties", "schema_contract", "const"]) ==
             "timeline_transition_application_report.v1"

    assert get_in(transition_application_report_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_transition_application"

    assert get_in(transition_application_report_schema, ["properties", "source", "type"]) ==
             "string"

    assert get_in(transition_application_report_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(transition_application_report_schema, [
             "properties",
             "selected_timeline_integrity_issue_types",
             "items",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types

    assert get_in(transition_application_report_schema, [
             "properties",
             "applications",
             "items",
             "required"
           ]) == [
             "id",
             "rank",
             "timeline_id",
             "diff_status",
             "transition_decision",
             "requires_operator_review",
             "required_operator_action",
             "reason",
             "changed_fields",
             "application_status",
             "source_timeline_diff"
           ]

    assert get_in(transition_application_report_schema, [
             "properties",
             "selected_activities",
             "items",
             "required"
           ]) == [
             "activity_id",
             "timeline_id",
             "activity_type",
             "status",
             "approval_status",
             "locked",
             "has_source_window",
             "has_cadence_import",
             "timeline_identity"
           ]

    assert Map.has_key?(schemas, "timeline_integrity_report.v1")

    timeline_integrity_schema = schemas["timeline_integrity_report.v1"]

    assert get_in(timeline_integrity_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_integrity_summary"

    assert get_in(timeline_integrity_schema, [
             "properties",
             "validation_level",
             "const"
           ]) == "artifact_contract"

    assert get_in(timeline_integrity_schema, ["properties", "source", "type"]) == "string"

    assert get_in(timeline_integrity_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(timeline_integrity_schema, [
             "properties",
             "timeline_integrity_issue_types",
             "items",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types

    assert get_in(timeline_integrity_schema, [
             "properties",
             "review_timeline_ids_by_required_operator_action",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(timeline_integrity_schema, ["properties", "rows", "items", "required"]) == [
             "id",
             "activity_id",
             "timeline_id",
             "activity_type",
             "status",
             "approval_status",
             "locked",
             "has_source_window",
             "has_cadence_import",
             "timeline_identity"
           ]

    assert Map.has_key?(schemas, "timeline_dependency_impact_summary.v1")

    dependency_impact_schema = schemas["timeline_dependency_impact_summary.v1"]

    assert get_in(dependency_impact_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_dependency_impact_summary"

    assert get_in(dependency_impact_schema, [
             "properties",
             "validation_level",
             "const"
           ]) == "artifact_contract"

    assert get_in(dependency_impact_schema, ["properties", "source", "const"]) ==
             "timeline_diff_report.v1"

    assert get_in(dependency_impact_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(dependency_impact_schema, [
             "properties",
             "impacted_exclusive_with_timeline_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(dependency_impact_schema, [
             "properties",
             "dependency_impact_rows",
             "items",
             "required"
           ]) == [
             "id",
             "scope",
             "dependency_impact_status",
             "required_operator_action",
             "operator_action_reason",
             "activity_id",
             "timeline_id",
             "activity_type"
           ]

    assert get_in(dependency_impact_schema, [
             "properties",
             "dependency_impact_rows",
             "items",
             "properties",
             "operator_action_reason",
             "enum"
           ]) == [
             "dependency_changed_or_removed_source_activity",
             "exclusivity_changed_or_removed_source_activity",
             "dependency_and_exclusivity_changed_or_removed_source_activity"
           ]

    assert Map.has_key?(schemas, "timeline_publication_summary.v1")

    publication_schema = schemas["timeline_publication_summary.v1"]

    assert get_in(publication_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_publication_summary"

    assert get_in(publication_schema, ["properties", "publication_sequence", "minimum"]) == 0

    assert get_in(publication_schema, ["properties", "publication_status", "enum"]) == [
             "published",
             "published_with_downstream_invalidations",
             "review_required"
           ]

    assert get_in(publication_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert Map.has_key?(schemas, "timeline_activity_state.v1")

    activity_state_schema = schemas["timeline_activity_state.v1"]

    assert get_in(activity_state_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_activity_state"

    assert get_in(activity_state_schema, ["properties", "validation_level", "const"]) ==
             "artifact_contract"

    assert get_in(activity_state_schema, ["properties", "model_limits", "const"]) ==
             Enum.map(
               OrbitalDynamics.TimelineFeedback.capabilities().known_limits,
               &Atom.to_string/1
             )

    assert get_in(activity_state_schema, ["properties", "rows", "items", "required"]) == [
             "activity_id",
             "status"
           ]

    assert Map.has_key?(schemas, "timeline_activity_precondition_summary.v1")

    precondition_summary_schema = schemas["timeline_activity_precondition_summary.v1"]
    precondition_capabilities = OrbitalDynamics.Timeline.capabilities()

    assert get_in(precondition_summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_activity_precondition_summary"

    assert get_in(precondition_summary_schema, ["properties", "validation_level", "const"]) ==
             "artifact_contract"

    assert get_in(precondition_summary_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(precondition_summary_schema, ["properties", "precondition_status", "enum"]) ==
             precondition_capabilities.activity_precondition_statuses

    assert get_in(precondition_summary_schema, [
             "properties",
             "preconditions",
             "items",
             "required"
           ]) == ["type", "status", "field", "reason"]

    assert get_in(precondition_summary_schema, [
             "properties",
             "preconditions",
             "items",
             "properties",
             "type",
             "enum"
           ]) == precondition_capabilities.activity_precondition_types

    assert get_in(precondition_summary_schema, [
             "properties",
             "dependency_activity_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(precondition_summary_schema, [
             "properties",
             "dependency_timeline_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(precondition_summary_schema, [
             "properties",
             "exclusive_with_activity_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(precondition_summary_schema, [
             "properties",
             "exclusive_with_timeline_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(precondition_summary_schema, ["properties", "allow_overlap", "type"]) ==
             "boolean"

    assert Map.has_key?(schemas, "timeline_activity_status_state.v1")

    status_state_schema = schemas["timeline_activity_status_state.v1"]

    assert get_in(status_state_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_activity_status_state"

    assert get_in(status_state_schema, ["properties", "validation_level", "const"]) ==
             "artifact_contract"

    assert get_in(status_state_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(status_state_schema, ["properties", "operator_action_reason", "type"]) ==
             "string"

    assert get_in(status_state_schema, ["properties", "planned_status_category", "type"]) ==
             "string"

    assert get_in(status_state_schema, ["properties", "realized_status_category", "type"]) ==
             "string"

    assert Map.has_key?(schemas, "timeline_activity_approval_state.v1")

    approval_state_schema = schemas["timeline_activity_approval_state.v1"]

    assert get_in(approval_state_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_activity_approval_state"

    assert get_in(approval_state_schema, ["properties", "validation_level", "const"]) ==
             "artifact_contract"

    assert get_in(approval_state_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(approval_state_schema, ["properties", "operator_action_reason", "type"]) ==
             "string"

    assert get_in(approval_state_schema, ["properties", "planned_approval_category", "type"]) ==
             "string"

    assert get_in(approval_state_schema, ["properties", "realized_approval_category", "type"]) ==
             "string"

    assert Map.has_key?(schemas, "timeline_activity_lifecycle_state.v1")

    lifecycle_state_schema = schemas["timeline_activity_lifecycle_state.v1"]

    assert get_in(lifecycle_state_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_activity_lifecycle_state"

    assert get_in(lifecycle_state_schema, ["properties", "validation_level", "const"]) ==
             "artifact_contract"

    assert get_in(lifecycle_state_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(lifecycle_state_schema, ["properties", "import_action", "type"]) == "string"

    assert get_in(lifecycle_state_schema, ["properties", "planned_status_category", "type"]) ==
             "string"

    assert get_in(lifecycle_state_schema, ["properties", "planned_approval_category", "type"]) ==
             "string"

    assert get_in(lifecycle_state_schema, [
             "properties",
             "operator_action_reasons",
             "items",
             "type"
           ]) ==
             "string"

    assert get_in(lifecycle_state_schema, [
             "properties",
             "planned_protection_decision",
             "properties",
             "timeline_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert Map.has_key?(schemas, "timeline_lifecycle_state_summary.v1")

    lifecycle_summary_schema = schemas["timeline_lifecycle_state_summary.v1"]

    assert get_in(lifecycle_summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_lifecycle_state_summary"

    assert get_in(lifecycle_summary_schema, ["properties", "validation_level", "const"]) ==
             "artifact_contract"

    assert get_in(lifecycle_summary_schema, ["properties", "source", "type"]) == "string"

    assert get_in(lifecycle_summary_schema, [
             "properties",
             "rows",
             "items",
             "required"
           ]) == [
             "rank",
             "timeline_id",
             "transition_decision",
             "review_required",
             "required_operator_action",
             "import_action"
           ]

    assert get_in(lifecycle_summary_schema, [
             "properties",
             "review_timeline_ids_by_required_operator_action",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert Map.has_key?(schemas, "timeline_preservation_report.v1")
    assert Map.has_key?(schemas, "timeline_preservation_status.v1")

    preservation_report_schema = schemas["timeline_preservation_report.v1"]
    preservation_status_schema = schemas["timeline_preservation_status.v1"]

    assert get_in(preservation_report_schema, ["properties", "model", "const"]) ==
             "artifact_only_lifecycle_preservation_summary"

    assert get_in(preservation_report_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(preservation_report_schema, ["properties", "source", "type"]) == "string"

    assert get_in(preservation_status_schema, ["properties", "model", "const"]) ==
             "artifact_only_lifecycle_preservation_status"

    assert get_in(preservation_status_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert Map.has_key?(schemas, "candidate_rejection_report.v1")

    candidate_rejection_schema = schemas["candidate_rejection_report.v1"]

    assert get_in(candidate_rejection_schema, ["properties", "model", "const"]) ==
             "artifact_only_candidate_rejection_explanation"

    assert get_in(candidate_rejection_schema, ["properties", "source", "type"]) == "string"

    assert get_in(candidate_rejection_schema, ["properties", "model_limits", "const"]) == [
             "artifact_only",
             "does_not_select_candidates",
             "does_not_mutate_schedules",
             "derived_reasons_use_declared_candidate_fields"
           ]

    assert get_in(candidate_rejection_schema, [
             "properties",
             "candidate_ids_by_required_operator_action",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().candidate_rejection_actions

    assert Map.has_key?(schemas, "result_artifact.v1")
    assert Map.has_key?(schemas, "validation_tolerance_policy.v1")
    assert Map.has_key?(schemas, "backend_acceptance_policy.v1")
    assert Map.has_key?(schemas, "capability_catalog.v1")
    assert Map.has_key?(schemas, "spacecraft_state_estimate.v1")
    assert Map.has_key?(schemas, "maneuver_execution_delta.v1")
    assert Map.has_key?(schemas, "validation_check.v1")
    assert Map.has_key?(schemas, "validation_record.v1")
    assert Map.has_key?(schemas, "validation_reference_report.v1")
    assert Map.has_key?(schemas, "candidate_diff_row.v1")
    assert Map.has_key?(schemas, "freshness_report.v1")

    validation_levels = [
      "analysis",
      "artifact_contract",
      "assumption_declared",
      "educational",
      "validated"
    ]

    assert get_in(schemas, ["validation_record.v1", "properties", "validation_level", "enum"]) ==
             validation_levels

    assert get_in(schemas, [
             "validation_reference_report.v1",
             "properties",
             "validation_level",
             "enum"
           ]) == validation_levels

    assert Enum.any?(
             schemas["validation_record.v1"]["allOf"],
             &(get_in(&1, ["if", "properties", "id", "const"]) == "propagator.two_body" and
                 get_in(&1, ["then", "properties", "model", "const"]) == "point_mass_two_body")
           )

    assert get_in(schemas, ["freshness_report.v1", "properties", "model", "const"]) ==
             "accepted_snapshot_horizon_and_quality_freshness"

    assert get_in(schemas, ["freshness_report.v1", "properties", "model_limits", "const"]) ==
             OrbitalDynamics.CandidateRefresh.model_limits()

    assert Map.has_key?(schemas, "invalidated_candidate.v1")
    assert Map.has_key?(schemas, "refresh_budget_report.v1")
    assert Map.has_key?(schemas, "refreshed_window.v1")
    assert Map.has_key?(schemas, "remaining_horizon.v1")
    assert Map.has_key?(schemas, "source_window_lineage.v1")
    assert Map.has_key?(schemas, "campaign_request_lint.v1")
    assert Map.has_key?(schemas, "study_manifest_lint.v1")
    assert Map.has_key?(schemas, "strategy_branch.v1")

    assert get_in(schemas, [
             "capability_catalog.v1",
             "properties",
             "model",
             "const"
           ]) == "public_capability_catalog"

    assert get_in(schemas, [
             "refresh_budget_report.v1",
             "properties",
             "model",
             "const"
           ]) == "deterministic_candidate_limit_after_filters"

    assert get_in(schemas, [
             "refresh_budget_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == OrbitalDynamics.CandidateRefresh.model_limits()

    assert get_in(schemas, [
             "refresh_budget_report.v1",
             "properties",
             "input_candidate_count",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "refresh_budget_report.v1",
             "properties",
             "max_candidate_activities",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "pareto_frontier_report.v1",
             "properties",
             "model",
             "const"
           ]) == "objective_vector_pareto_frontier"

    assert get_in(schemas, [
             "ranking_comparison_report.v1",
             "properties",
             "model",
             "const"
           ]) == "scenario_ranking_pairwise_delta"

    assert get_in(schemas, [
             "objective_satisfaction_report.v1",
             "properties",
             "model",
             "const"
           ]) == "campaign_v1_selected_activity_objective_summary"

    assert get_in(schemas, [
             "objective_tradeoff_report.v1",
             "properties",
             "model",
             "enum"
           ]) == [
             "ranked_timeline_score_term_tradeoffs",
             "repair_score_term_tradeoffs",
             "strategy_branch_score_term_tradeoffs"
           ]

    assert get_in(schemas, [
             "execution_report.v1",
             "properties",
             "failed_scenarios",
             "items",
             "properties",
             "scenario_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "result_artifact.v1",
             "properties",
             "ground_track_crossings",
             "items",
             "properties",
             "crossing",
             "enum"
           ]) == ["latitude", "longitude"]

    assert get_in(schemas, [
             "backend_acceptance_policy.v1",
             "x-orbital-dynamics",
             "nested_contracts"
           ]) == ["validation_tolerance_policy.v1"]

    assert get_in(schemas, [
             "backend_acceptance_policy.v1",
             "x-orbital-dynamics",
             "nested_contract_definition_scope"
           ]) == "direct_declared_contracts"

    assert get_in(schemas, [
             "backend_acceptance_policy.v1",
             "x-orbital-dynamics",
             "compatibility_policy"
           ]) == Schema.compatibility_policy()

    assert get_in(schemas, [
             "backend_acceptance_policy.v1",
             "x-orbital-dynamics",
             "identity_policy",
             "stable_id_pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    publication_id_scope =
      schemas
      |> get_in([
        "backend_acceptance_policy.v1",
        "x-orbital-dynamics",
        "identity_policy",
        "generated_id_scopes"
      ])
      |> Enum.find(&(&1["scope"] == "timeline_publication_summary.v1.publication_id"))

    assert publication_id_scope["generated_id_field"] == "publication_id"

    assert publication_id_scope["identity_fields"] == [
             "publication_sequence",
             "source_artifact_id",
             "supersedes_artifact_ids"
           ]

    assert publication_id_scope["semantic_invariants"] == [
             "source_record_order_must_not_change_publication_id",
             "same_publication_sequence_and_artifact_lineage_must_keep_publication_id",
             "publication_id_serializes_declared_artifact_lineage"
           ]

    assert get_in(schemas, [
             "backend_acceptance_policy.v1",
             "$defs",
             "validation_tolerance_policy.v1",
             "properties",
             "schema_contract",
             "const"
           ]) == "validation_tolerance_policy.v1"

    refute Map.has_key?(
             get_in(schemas, [
               "backend_acceptance_policy.v1",
               "$defs",
               "validation_tolerance_policy.v1"
             ]),
             "$defs"
           )

    refute Map.has_key?(
             get_in(schemas, [
               "backend_acceptance_policy.v1",
               "$defs",
               "validation_tolerance_policy.v1",
               "x-orbital-dynamics"
             ]),
             "identity_policy"
           )

    assert "contact_schedule_change" in get_in(schemas, [
             "contact_intent.v1",
             "$defs",
             "approval_requirement.v1",
             "properties",
             "requirement_type",
             "enum"
           ])

    assert get_in(schemas, [
             "schema_validation_report.v1",
             "properties",
             "model",
             "const"
           ]) == "executable_artifact_contract_validation"

    assert get_in(schemas, [
             "schema_validation_report.v1",
             "properties",
             "errors",
             "items",
             "properties",
             "severity",
             "enum"
           ]) == ["error", "warning"]

    Enum.each(["error_count", "warning_count", "remediation_count"], fn field ->
      assert get_in(schemas, ["schema_validation_report.v1", "properties", field, "minimum"]) ==
               0
    end)

    Enum.each(
      [
        "file_count",
        "artifact_count",
        "skipped_count",
        "error_count",
        "warning_count",
        "remediation_count"
      ],
      fn field ->
        assert get_in(schemas, [
                 "schema_validation_batch_report.v1",
                 "properties",
                 field,
                 "minimum"
               ]) == 0
      end
    )

    assert get_in(schemas, [
             "schema_validation_batch_report.v1",
             "properties",
             "model",
             "const"
           ]) == "executable_artifact_contract_batch_validation"

    assert get_in(schemas, [
             "schema_validation_batch_report.v1",
             "properties",
             "status_counts",
             "propertyNames",
             "enum"
           ]) == ["pass", "fail"]

    assert Map.has_key?(schemas, "schema_migration_report.v1")

    assert get_in(schemas, [
             "schema_migration_report.v1",
             "properties",
             "model",
             "const"
           ]) == "executable_schema_migration_and_deprecation_report"

    schema_migration_model_limits = [
      "artifact_only_schema_registry_snapshot",
      "deprecation_hints_are_caller_declared",
      "no_automatic_artifact_migration",
      "no_backward_compatibility_certification"
    ]

    assert get_in(schemas, [
             "schema_migration_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == schema_migration_model_limits

    assert get_in(schemas, [
             "schema_migration_report.v1",
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == schema_migration_model_limits

    Enum.each(
      [
        "contract_count",
        "current_contract_count",
        "deprecated_contract_count",
        "future_contract_count",
        "migration_row_count",
        "deprecation_warning_count"
      ],
      fn field ->
        assert get_in(schemas, ["schema_migration_report.v1", "properties", field, "minimum"]) ==
                 0
      end
    )

    assert get_in(schemas, [
             "schema_migration_report.v1",
             "properties",
             "status_counts",
             "propertyNames",
             "enum"
           ]) == ["current", "deprecated", "future"]

    assert get_in(schemas, [
             "schema_migration_report.v1",
             "properties",
             "migration_action_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "schema_migration_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "status",
             "enum"
           ]) == ["current", "deprecated", "future"]

    assert get_in(schemas, [
             "schema_migration_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "migration_action",
             "enum"
           ]) == Validation.capabilities().schema_migration_actions

    assert get_in(schemas, ["campaign_request_lint.v1", "properties", "error_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schemas, [
             "campaign_request_lint.v1",
             "properties",
             "request",
             "properties",
             "sha256"
           ]) == %{
             "type" => "string",
             "pattern" => "^[0-9a-f]{64}$"
           }

    assert get_in(schemas, [
             "campaign_request_lint.v1",
             "properties",
             "source_plan",
             "properties",
             "sha256"
           ]) == %{
             "type" => "string",
             "pattern" => "^[0-9a-f]{64}$"
           }

    Enum.each(["error_count", "warning_count"], fn field ->
      assert get_in(schemas, ["study_manifest_lint.v1", "properties", field]) == %{
               "type" => "integer",
               "minimum" => 0
             }
    end)

    assert get_in(schemas, ["study_manifest_lint.v1", "properties", "scenario_count"]) == %{
             "type" => ["integer", "null"],
             "minimum" => 0
           }

    assert get_in(schemas, ["contact_intent.v1", "properties", "cadence_import", "type"]) ==
             "object"

    refute "cadence_import" in get_in(schemas, ["contact_intent.v1", "required"])

    assert get_in(schemas, [
             "contact_intent.v1",
             "properties",
             "approval_requirements",
             "items",
             "properties",
             "schema_contract",
             "const"
           ]) == "approval_requirement.v1"

    assert get_in(schemas, [
             "contact_intent.v1",
             "properties",
             "approval_rule_matches",
             "items",
             "properties",
             "rule_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, ["station_calendar_provider.v1", "properties", "entries", "type"]) ==
             "array"

    assert get_in(schemas, [
             "station_calendar_provider.v1",
             "properties",
             "entries",
             "items",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    availability_schema =
      get_in(schemas, [
        "station_calendar_provider.v1",
        "properties",
        "entries",
        "items",
        "properties",
        "availability"
      ])

    assert %{"type" => "string", "enum" => availability_values} =
             Enum.find(availability_schema["oneOf"], &(&1["type"] == "string"))

    assert availability_values == [
             "available",
             "unavailable",
             "outage",
             "down",
             "offline",
             "reduced_capacity",
             "maintenance",
             "reserved",
             "hold",
             "held",
             "on_hold",
             "onhold",
             "reservation_held",
             "reserved_hold",
             "reservation_hold"
           ]

    assert %{"type" => "number"} =
             number_availability_schema =
             Enum.find(availability_schema["oneOf"], &(&1["type"] == "number"))

    assert number_availability_schema["minimum"] == 0.0
    assert number_availability_schema["maximum"] == 1.0

    assert get_in(schemas, [
             "station_calendar_provider.v1",
             "properties",
             "entries",
             "items",
             "properties",
             "reservation_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "station_calendar_provider.v1",
             "properties",
             "trust_boundary",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "station_calendar_report.v1",
             "properties",
             "model",
             "const"
           ]) == "campaign_ground_network_interval_overlay"

    assert get_in(schemas, [
             "station_calendar_report.v1",
             "properties",
             "station_reservation_match_status_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "station_reservation_report.v1",
             "properties",
             "schema_contract",
             "const"
           ]) == "station_reservation_report.v1"

    assert get_in(schemas, [
             "station_reservation_review_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_station_reservation_review_summary"

    station_calendar_model_limits =
      OrbitalDynamics.Communications.StationCalendar.capabilities().known_limits
      |> Enum.map(&Atom.to_string/1)

    assert get_in(schemas, [
             "station_reservation_review_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == station_calendar_model_limits

    assert get_in(schemas, [
             "station_reservation_hold_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_station_reservation_hold_summary"

    assert get_in(schemas, [
             "station_reservation_hold_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == station_calendar_model_limits

    assert get_in(schemas, [
             "station_reservation_hold_import_readiness_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_station_reservation_hold_import_readiness_summary"

    assert get_in(schemas, [
             "station_reservation_hold_import_readiness_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == station_calendar_model_limits

    assert get_in(schemas, [
             "provider_counteroffer_review_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_provider_counteroffer_review_summary"

    assert get_in(schemas, [
             "provider_counteroffer_import_readiness_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_provider_counteroffer_import_readiness_summary"

    assert get_in(schemas, [
             "provider_counteroffer_plan_impact_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_provider_counteroffer_plan_impact_summary"

    assert get_in(schemas, [
             "provider_counteroffer_report.v1",
             "properties",
             "model",
             "enum"
           ]) == [
             "artifact_only_provider_counteroffer_review",
             "preserved_provider_counteroffer_rows",
             "preserved_provider_counteroffer_plan_impact_summary",
             "preserved_provider_counteroffer_import_readiness_summary"
           ]

    assert get_in(schemas, [
             "station_reservation_report.v1",
             "properties",
             "model",
             "enum"
           ]) == [
             "artifact_only_station_reservation_summary",
             "preserved_station_reservation_hold_summary",
             "preserved_station_reservation_hold_import_readiness_summary"
           ]

    for field <- [
          "affected_contact_reservation_count",
          "provider_calendar_contention_group_count",
          "reservation_review_count"
        ] do
      assert get_in(schemas, [
               "station_reservation_report.v1",
               "properties",
               field,
               "minimum"
             ]) == 0
    end

    for field <- [
          "station_reservation_match_status_counts",
          "reservation_status_counts"
        ] do
      assert get_in(schemas, [
               "station_reservation_report.v1",
               "properties",
               field,
               "additionalProperties"
             ]) == %{"type" => "integer", "minimum" => 0}
    end

    assert get_in(schemas, [
             "contact_filter_report.v1",
             "properties",
             "model",
             "const"
           ]) == "thin_ground_network_availability_filter"

    assert get_in(schemas, [
             "contact_filter_report.v1",
             "properties",
             "station_calendar_trust_boundary_status_counts",
             "propertyNames",
             "enum"
           ]) == ["declared", "missing", "untrusted"]

    assert get_in(schemas, [
             "contact_filter_report.v1",
             "properties",
             "station_reservation_match_status_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "resource_filter_report.v1",
             "properties",
             "model",
             "const"
           ]) == "resource_summary_availability_and_margin_filter"

    assert get_in(schemas, [
             "resource_filter_report.v1",
             "properties",
             "resource_source_quality_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "resource_filter_report.v1",
             "properties",
             "suppressed_resource_trust_boundary_status_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "contact_allocation_report.v1",
             "properties",
             "station_reservation_match_status_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "contact_allocation_report.v1",
             "properties",
             "model",
             "const"
           ]) == "deterministic_station_contact_allocation"

    assert get_in(schemas, [
             "contact_allocation_report.v1",
             "properties",
             "source",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "contact_allocation_report.v1",
             "properties",
             "station_calendar_trust_boundary_status_counts",
             "propertyNames",
             "enum"
           ]) == ["declared", "missing", "untrusted"]

    assert get_in(schemas, [
             "contact_allocation_report.v1",
             "properties",
             "calendar_entry_trust_boundary_status_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    for contract_name <- ["operator_review_package.v1", "cadence_import_manifest.v1"] do
      assert get_in(schemas, [
               contract_name,
               "properties",
               "calendar_entry_trust_boundary_status_counts",
               "additionalProperties"
             ]) == %{"type" => "integer", "minimum" => 0}

      assert get_in(schemas, [
               contract_name,
               "properties",
               "station_reservation_match_status_counts",
               "additionalProperties"
             ]) == %{"type" => "integer", "minimum" => 0}
    end

    assert %{"required" => ["trust_boundary"]} in schemas["station_calendar_provider.v1"][
             "anyOf"
           ]

    assert %{
             "properties" => %{
               "provenance" => %{
                 "required" => ["trust_boundary"]
               }
             }
           } =
             Enum.find(
               schemas["station_calendar_provider.v1"]["anyOf"],
               &(&1["required"] == ["provenance"])
             )

    assert get_in(schemas, ["policy_bundle.v1", "properties", "approval_policy", "type"]) ==
             "object"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "degraded",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "payload_available",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "directions",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "required_operator_actions",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "operator_action_reason",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "station_reservation_ids",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "station_reservation_match_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "station_calendar_reserved_bys",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "station_calendar_reservation_statuses",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "station_calendar_entry_ambiguous",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "station_calendar_ambiguous_entry_ids",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "station_calendar_ambiguous_entry_count_min",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "allocation_statuses",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "policy_classifications",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "policy_classification",
             "enum"
           ]) == classification_values

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "policy_classifications",
             "items",
             "enum"
           ]) == classification_values

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "effective_allocation_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "allocation_reasons",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "suppressed_reason",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "resource_blocking_dimensions",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "ground_station_ids",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "transition_decisions",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "application_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "source_timeline_integrity_statuses",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "source_timeline_integrity_issue_type",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "replacement_timeline_integrity_statuses",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "replacement_timeline_integrity_issue_type",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "planned_protection_decisions",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "planned_protection_category",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "timeline_integrity_statuses",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "timeline_integrity_issue_type",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "source_protection_categories",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "replacement_protection_decision",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "escalation_queue",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "sla_s",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "classification",
             "enum"
           ]) == ["auto_approvable", "operator_review_required", "blocked_by_policy"]

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "cadence_import_status",
             "enum"
           ]) == OrbitalDynamics.Policy.capabilities().cadence_import_statuses

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "cadence_import_statuses",
             "items",
             "enum"
           ]) == OrbitalDynamics.Policy.capabilities().cadence_import_statuses

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "command_results",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "contact_results",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "observation_results",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "maneuver_results",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "command_results",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "observation_results",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "maneuver_results",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "contact_results",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, ["policy_decision.v1", "properties", "policy_bundle_id", "type"]) ==
             "string"

    assert get_in(schemas, ["policy_decision.v1", "properties", "escalations", "type"]) ==
             "array"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "classification",
             "enum"
           ]) == classification_values

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "ground_station_id",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "cadence_import_status",
             "enum"
           ]) == OrbitalDynamics.Policy.capabilities().cadence_import_statuses

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "allocation_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "effective_allocation_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "allocation_reason",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "policy_classification",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "policy_classification",
             "enum"
           ]) == classification_values

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "transition_decision",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "application_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "planned_protection_decision",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "planned_protection_category",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "timeline_integrity_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "timeline_integrity_issue_types",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "required_operator_action",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "operator_action_reason",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "source_timeline_integrity_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "source_timeline_integrity_issue_types",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "replacement_timeline_integrity_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "replacement_timeline_integrity_issue_types",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "source_protection_decision",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "replacement_protection_category",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "rule_matches",
             "items",
             "properties",
             "sla_s",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "policy_decision.v1",
             "properties",
             "escalations",
             "items",
             "properties",
             "required_authority",
             "type"
           ]) == "string"

    refute "policy_bundle_id" in get_in(schemas, ["policy_decision.v1", "required"])

    assert get_in(schemas, [
             "environment_provider_capability.v1",
             "properties",
             "model",
             "type"
           ]) == "string"

    assert "model" in get_in(schemas, ["environment_provider_capability.v1", "required"])

    validation_levels = [
      "analysis",
      "artifact_contract",
      "assumption_declared",
      "educational",
      "validated"
    ]

    assert get_in(schemas, [
             "environment_provider_capability.v1",
             "properties",
             "validation_level",
             "enum"
           ]) == validation_levels

    assert get_in(schemas, [
             "environment_model_capability.v1",
             "properties",
             "validation_level",
             "enum"
           ]) == validation_levels

    assert get_in(schemas, [
             "subsystem_model_capability.v1",
             "properties",
             "validation_level",
             "enum"
           ]) == validation_levels

    assert get_in(schemas, [
             "subsystem_model_capability.v1",
             "properties",
             "fidelity_tier",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "subsystem_model_capability.v1",
             "properties",
             "state_variables",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "environment_provider_capability.v1",
             "properties",
             "source",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "environment_provider_capability.v1",
             "properties",
             "outputs",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "environment_provider_capability.v1",
             "properties",
             "network_access",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "environment_model_capability.v1",
             "properties",
             "supported_bodies",
             "items",
             "type"
           ]) == "string"

    assert Enum.any?(
             schemas["environment_model_capability.v1"]["allOf"],
             &(get_in(&1, ["if", "properties", "id", "const"]) ==
                 "environment.solar.fixed_inertial_direction" and
                 get_in(&1, ["then", "properties", "known_limits", "const"]) ==
                   [
                     "not an ephemeris provider",
                     "no Sun range or light-time correction",
                     "no time-varying apparent solar direction"
                   ])
           )

    assert Enum.any?(
             schemas["environment_model_capability.v1"]["allOf"],
             &(get_in(&1, ["if", "properties", "id", "const"]) ==
                 "environment.earth_rotation.constant_rate" and
                 get_in(&1, ["then", "properties", "known_limits", "const"]) ==
                   [
                     "no Earth orientation parameters",
                     "no UT1 or polar-motion correction",
                     "spherical surface geometry"
                   ])
           )

    assert get_in(schemas, [
             "environment_provider_capability.v1",
             "properties",
             "known_limits",
             "items",
             "type"
           ]) == "string"

    Enum.each(OrbitalDynamics.Environment.provider_capabilities(), fn provider ->
      assert Enum.any?(
               schemas["environment_provider_capability.v1"]["allOf"],
               &(get_in(&1, ["if", "properties", "id", "const"]) == provider["id"] and
                   get_in(&1, ["then", "properties", "known_limits", "const"]) ==
                     provider["known_limits"])
             )
    end)

    Enum.each(OrbitalDynamics.SubsystemModel.capabilities(), fn subsystem ->
      assert Enum.any?(
               schemas["subsystem_model_capability.v1"]["allOf"],
               &(get_in(&1, ["if", "properties", "id", "const"]) == subsystem["id"] and
                   get_in(&1, ["then", "properties", "known_limits", "const"]) ==
                     subsystem["known_limits"])
             )
    end)

    assert get_in(schemas, ["constraint_report.v1", "properties", "rows", "type"]) == "array"

    assert get_in(schemas, ["constraint_report.v1", "properties", "model", "enum"]) == [
             "artifact_metric_threshold",
             "campaign_planner_local_constraint_summary",
             "campaign_repair_local_constraint_summary"
           ]

    assert get_in(schemas, [
             "constraint_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "operator",
             "enum"
           ]) == ["<", "<=", "==", ">=", ">"]

    assert get_in(schemas, [
             "constraint_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "status",
             "enum"
           ]) == ["pass", "fail", "warning"]

    assert Enum.any?(
             schemas["constraint_report.v1"]["allOf"],
             &(get_in(&1, ["if", "properties", "model", "const"]) ==
                 "campaign_repair_local_constraint_summary" and
                 get_in(&1, ["then", "properties", "model_limits", "const"]) ==
                   [
                     "planner_local_constraints_only",
                     "evaluated_after_candidate_generation_filters",
                     "resource_projection_constraints_are_planning_grade",
                     "link_capacity_constraints_are_fixed_rate_summaries",
                     "not_a_general_constraint_solver"
                   ])
           )

    assert get_in(schemas, [
             "objective_tradeoff_report.v1",
             "properties",
             "score_term_keys",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "objective_tradeoff_report.v1",
             "properties",
             "tradeoffs",
             "items",
             "properties",
             "scenario_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "objective_tradeoff_report.v1",
             "properties",
             "tradeoffs",
             "items",
             "properties",
             "activity_ids",
             "type"
           ]) == "array"

    assert get_in(schemas, ["score_term_report.v1", "properties", "rows", "type"]) == "array"

    assert get_in(schemas, [
             "score_term_report.v1",
             "properties",
             "model",
             "enum"
           ]) == [
             "ranked_timeline_score_terms",
             "repair_score_terms",
             "strategy_branch_score_terms"
           ]

    assert get_in(schemas, [
             "score_term_report.v1",
             "properties",
             "source",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "score_term_report.v1",
             "properties",
             "score_term_keys",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "score_term_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "term_key",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "score_term_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "selected",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "optimizer_contract.v1",
             "properties",
             "selected_activity_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "optimizer_contract.v1",
             "properties",
             "score_term_keys",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, ["branch_comparison_report.v1", "properties", "rows", "type"]) ==
             "array"

    assert get_in(schemas, ["branch_comparison_report.v1", "properties", "model", "const"]) ==
             "deterministic_strategy_branch_score_comparison"

    assert get_in(schemas, ["branch_comparison_report.v1", "properties", "source", "const"]) ==
             "campaign_strategy.branches"

    assert get_in(schemas, [
             "branch_comparison_report.v1",
             "properties",
             "rows",
             "items",
             "required"
           ]) == [
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
           ]

    assert get_in(schemas, [
             "branch_comparison_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "branch_probability",
             "minimum"
           ]) == 0.0

    assert get_in(schemas, [
             "branch_comparison_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "projected_downlink_margin",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "branch_comparison_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "risk_types",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "branch_comparison_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "high_risk_types",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "branch_comparison_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "resource_pressure_statuses",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "branch_comparison_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "branch_station_calendar_provider_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "branch_comparison_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "branch_station_calendar_directions",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, ["link_capacity_report.v1", "properties", "rows", "type"]) ==
             "array"

    assert get_in(schemas, [
             "link_capacity_report.v1",
             "properties",
             "model",
             "const"
           ]) == "fixed_rate_downlink_capacity_summary"

    assert get_in(schemas, [
             "link_capacity_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_link_capacity_summary"

    assert get_in(schemas, [
             "relay_data_path_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_relay_data_path_summary"

    assert get_in(schemas, [
             "relay_data_path_summary.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "route_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "relay_data_path_summary.v1",
             "properties",
             "assumptions",
             "properties",
             "provider_reservation",
             "const"
           ]) == "not_performed"

    assert get_in(schemas, [
             "relay_data_path_summary.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "relay_hop_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "link_capacity_report.v1",
             "properties",
             "source",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "link_capacity_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "link_capacity_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "selected_estimated_throughput_mb",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "link_capacity_report.v1",
             "properties",
             "ignored_contact_reason_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "link_capacity_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "ignored_selected_contact_reason_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "campaign_plan.v1",
             "properties",
             "resource_projection_report",
             "type"
           ]) == "object"

    assert get_in(schemas, [
             "resource_projection_report.v1",
             "properties",
             "model",
             "enum"
           ]) == [
             "thin_battery_handoff_resource_projection_fixture",
             "thin_campaign_selected_activity_resource_projection",
             "thin_repaired_activity_resource_projection",
             "thin_selected_activity_resource_projection",
             "thin_stale_derived_margin_resource_projection_fixture",
             "thin_strategy_branch_activity_resource_projection"
           ]

    assert get_in(schemas, [
             "resource_projection_report.v1",
             "properties",
             "projected_resources",
             "items",
             "properties",
             "spacecraft_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "resource_projection_report.v1",
             "properties",
             "projected_resources",
             "items",
             "properties",
             "projected_downlink_margin",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "resource_projection_report.v1",
             "properties",
             "resource_source_quality_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "resource_projection_report.v1",
             "properties",
             "resource_trust_boundary_status_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "resource_projection_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) ==
             OrbitalDynamics.ResourceProjection.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert get_in(schemas, [
             "resource_projection_flow_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_selected_activity_resource_flow_summary"

    assert get_in(schemas, [
             "resource_projection_flow_summary.v1",
             "properties",
             "source"
           ]) == %{"type" => "string"}

    Enum.each(["resource_flow_status", "resource_pressure_status", "latency_status"], fn field ->
      assert get_in(schemas, [
               "resource_projection_flow_summary.v1",
               "properties",
               field
             ]) == %{"type" => "string", "enum" => ["clear", "review_required"]}
    end)

    assert get_in(schemas, [
             "resource_projection_flow_summary.v1",
             "properties",
             "activity_resource_flow",
             "items",
             "properties",
             "resource_effect_status",
             "enum"
           ]) ==
             OrbitalDynamics.ResourceSummary.capabilities().roll_forward_resource_effect_statuses

    assert get_in(schemas, [
             "resource_projection_flow_summary.v1",
             "properties",
             "activity_resource_flow",
             "items",
             "properties",
             "battery_state_of_charge_after"
           ]) == %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}

    assert get_in(schemas, [
             "accepted_planning_state.v1",
             "properties",
             "spacecraft_states",
             "items",
             "properties",
             "state_vector",
             "properties",
             "position_km",
             "minItems"
           ]) == 3

    assert get_in(schemas, [
             "accepted_planning_state.v1",
             "properties",
             "spacecraft_states",
             "items",
             "properties",
             "quality",
             "properties",
             "position_sigma_km",
             "maxItems"
           ]) == 3

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "warnings",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        "source_report_timeline_publication_ids",
        "source_report_timeline_publication_source_artifact_ids",
        "source_report_timeline_publication_supersedes_artifact_ids",
        "source_report_timeline_publication_downstream_product_ids",
        "source_report_timeline_publication_invalidated_downstream_product_ids",
        "source_report_operational_readiness_publication_ids",
        "source_report_operational_readiness_source_artifact_ids",
        "source_report_operational_readiness_supersedes_artifact_ids",
        "source_report_operational_readiness_downstream_product_ids",
        "source_report_operational_readiness_invalidated_downstream_product_ids",
        "source_report_quality_gate_publication_ids",
        "source_report_quality_gate_source_artifact_ids",
        "source_report_quality_gate_supersedes_artifact_ids",
        "source_report_quality_gate_downstream_product_ids",
        "source_report_quality_gate_invalidated_downstream_product_ids"
      ],
      fn field ->
        assert get_in(schemas, [
                 "candidate_refresh.v1",
                 "properties",
                 field,
                 "type"
               ]) == "array"

        assert get_in(schemas, [
                 "candidate_refresh.v1",
                 "properties",
                 field,
                 "items",
                 "pattern"
               ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    Enum.each(
      [
        "source_report_timeline_publication_source_artifact_type_counts",
        "source_report_operational_readiness_timeline_publication_source_artifact_type_counts",
        "source_report_quality_gate_timeline_publication_source_artifact_type_counts"
      ],
      fn field ->
        assert get_in(schemas, [
                 "candidate_refresh.v1",
                 "properties",
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "source_report_operational_readiness_resource_availability_pressure_count",
        "source_report_quality_gate_resource_availability_pressure_count"
      ],
      fn field ->
        assert get_in(schemas, [
                 "candidate_refresh.v1",
                 "properties",
                 field,
                 "type"
               ]) == "integer"

        assert get_in(schemas, [
                 "candidate_refresh.v1",
                 "properties",
                 field,
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "source_report_operational_readiness_resource_availability_reason_counts",
        "source_report_operational_readiness_station_availability_reason_counts",
        "source_report_operational_readiness_resource_blocking_dimension_counts",
        "source_report_quality_gate_resource_availability_reason_counts",
        "source_report_quality_gate_station_availability_reason_counts",
        "source_report_quality_gate_resource_blocking_dimension_counts"
      ],
      fn field ->
        assert get_in(schemas, [
                 "candidate_refresh.v1",
                 "properties",
                 field,
                 "additionalProperties",
                 "minimum"
               ]) == 0
      end
    )

    Enum.each(
      [
        "source_report_operational_readiness_resource_availability_reason_ids",
        "source_report_operational_readiness_station_availability_reason_ids",
        "source_report_operational_readiness_unavailable_resource_reason_ids",
        "source_report_quality_gate_resource_availability_reason_ids",
        "source_report_quality_gate_station_availability_reason_ids",
        "source_report_quality_gate_unavailable_resource_reason_ids"
      ],
      fn field ->
        assert get_in(schemas, [
                 "candidate_refresh.v1",
                 "properties",
                 field,
                 "type"
               ]) == "array"

        assert get_in(schemas, [
                 "candidate_refresh.v1",
                 "properties",
                 field,
                 "items",
                 "type"
               ]) == "string"
      end
    )

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "validation_records",
             "items",
             "properties",
             "known_limits",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "source_window_lineage",
             "items",
             "properties",
             "source_window_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "source_window_lineage",
             "items",
             "required"
           ]) == [
             "candidate_activity_id",
             "source_window_id",
             "source_window_type",
             "scenario_id"
           ]

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "invalidated_candidates",
             "items",
             "properties",
             "replacement_candidate_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "invalidated_candidates",
             "items",
             "properties",
             "semantic_change_reasons",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "refresh_budget_report",
             "type"
           ]) == "object"

    assert "refresh_budget_report.v1" in get_in(schemas, [
             "candidate_refresh.v1",
             "x-orbital-dynamics",
             "nested_contracts"
           ])

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "candidate_activities",
             "items",
             "properties",
             "source_window_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert "source_window" in get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "candidate_activities",
             "items",
             "required"
           ])

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "candidate_activities",
             "items",
             "properties",
             "score_terms",
             "type"
           ]) == "object"

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "contact_intents",
             "items",
             "properties",
             "direction",
             "enum"
           ]) == ["downlink", "uplink", "command", "tracking", "health_check"]

    assert get_in(schemas, [
             "planned_activity.v1",
             "properties",
             "direction",
             "enum"
           ]) == ["downlink", "uplink", "command", "tracking", "health_check"]

    assert get_in(schemas, ["planned_activity.v1", "required"]) == [
             "id",
             "scenario_id",
             "starts_at_s",
             "ends_at_s"
           ]

    assert get_in(schemas, ["planned_activity.v1", "anyOf"]) == [
             %{"required" => ["type"]},
             %{"required" => ["activity_type"]}
           ]

    assert get_in(schemas, [
             "planned_activity.v1",
             "properties",
             "activity_type",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "candidate_activities",
             "items",
             "properties",
             "station_calendar_directions",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "candidate_refresh.v1",
             "properties",
             "resource_summaries",
             "items",
             "properties",
             "spacecraft_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "campaign_plan.v1",
             "properties",
             "warnings",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "campaign_plan.v1",
             "properties",
             "activities",
             "items",
             "properties",
             "source_window_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "campaign_plan.v1",
             "properties",
             "candidate_activities",
             "items",
             "properties",
             "score_terms",
             "type"
           ]) == "object"

    assert get_in(schemas, [
             "campaign_plan.v1",
             "properties",
             "ranked_timelines",
             "items",
             "properties",
             "activities",
             "items",
             "properties",
             "source_window",
             "properties",
             "id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "campaign_plan.v1",
             "properties",
             "proposed_contacts",
             "items",
             "properties",
             "cadence_import",
             "properties",
             "schema_contract",
             "const"
           ]) == "proposed_contact.v1"

    assert get_in(schemas, [
             "campaign_plan.v1",
             "properties",
             "proposed_contacts",
             "items",
             "properties",
             "direction",
             "enum"
           ]) == ["downlink", "uplink", "command", "tracking"]

    assert get_in(schemas, [
             "campaign_plan.v1",
             "properties",
             "proposed_contacts",
             "items",
             "properties",
             "station_calendar_directions",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "campaign_plan.v1",
             "properties",
             "contact_intents",
             "items",
             "properties",
             "schema_contract",
             "const"
           ]) == "contact_intent.v1"

    assert get_in(schemas, [
             "strategy_recommendation.v1",
             "properties",
             "approval_status",
             "enum"
           ]) == strategy_approval_status_values

    assert get_in(schemas, [
             "strategy_recommendation.v1",
             "properties",
             "ranked_branch_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "campaign_strategy.v3",
             "properties",
             "recommendation",
             "properties",
             "ranked_branch_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "campaign_strategy.v3",
             "properties",
             "recommendation",
             "properties",
             "approval_status",
             "enum"
           ]) == strategy_approval_status_values

    assert get_in(schemas, [
             "campaign_strategy.v3",
             "properties",
             "strategy_policy",
             "properties",
             "risk_weight",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "campaign_strategy.v3",
             "properties",
             "strategy_policy",
             "properties",
             "probability_weight",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "campaign_strategy.v3",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "policy_classifications",
             "items",
             "enum"
           ]) == classification_values

    assert get_in(schemas, [
             "campaign_repair.v2",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "policy_classifications",
             "items",
             "enum"
           ]) == classification_values

    assert get_in(schemas, [
             "campaign_repair.v2",
             "properties",
             "policy_decision",
             "properties",
             "classification",
             "enum"
           ]) == classification_values

    assert get_in(schemas, [
             "campaign_strategy.v3",
             "properties",
             "branches",
             "items",
             "properties",
             "policy_decision",
             "properties",
             "classification",
             "enum"
           ]) == classification_values

    row_policy_decision_paths = [
      {"link_capacity_report.v1",
       ["properties", "rows", "items", "properties", "policy_decision"]},
      {"contact_allocation_report.v1",
       ["properties", "rows", "items", "properties", "policy_decision"]},
      {"contact_contention_report.v1",
       ["properties", "conflict_groups", "items", "properties", "policy_decision"]},
      {"contact_contention_resolution_report.v1",
       ["properties", "recommendations", "items", "properties", "policy_decision"]},
      {"contact_filter_report.v1",
       ["properties", "suppressed_candidates", "items", "properties", "policy_decision"]},
      {"resource_filter_report.v1",
       ["properties", "suppressed_candidates", "items", "properties", "policy_decision"]},
      {"resource_projection_report.v1",
       ["properties", "projected_resources", "items", "properties", "policy_decision"]},
      {"contact_intent.v1", ["properties", "policy_decision"]},
      {"maneuver_review_report.v1",
       ["properties", "rows", "items", "properties", "policy_decision"]},
      {"command_window_report.v1",
       ["properties", "rows", "items", "properties", "policy_decision"]},
      {"station_calendar_report.v1",
       ["properties", "affected_contacts", "items", "properties", "policy_decision"]}
    ]

    assert get_in(schemas, [
             "contact_contention_report.v1",
             "properties",
             "model",
             "const"
           ]) == "single_station_interval_overlap"

    assert get_in(schemas, [
             "contact_contention_resolution_report.v1",
             "properties",
             "model",
             "const"
           ]) == "deterministic_contact_contention_recommendation"

    assert get_in(schemas, [
             "contact_contention_resolution_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_contact_contention_resolution_summary"

    assert get_in(schemas, [
             "contact_contention_resolution_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) ==
             OrbitalDynamics.Communications.ContactContention.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    Enum.each(row_policy_decision_paths, fn {contract_name, path} ->
      assert get_in(schemas, [contract_name | path] ++ ["properties", "classification", "enum"]) ==
               classification_values

      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "properties",
                   "rule_matches",
                   "items",
                   "properties",
                   "policy_classification",
                   "enum"
                 ]
             ) == classification_values
    end)

    assert get_in(schemas, [
             "contact_contention_resolution_report.v1",
             "properties",
             "policy",
             "properties",
             "requested_priority_fields",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "contact_contention_resolution_report.v1",
             "properties",
             "recommendations",
             "items",
             "properties",
             "priority_field_evidence_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    assert get_in(schemas, [
             "contact_contention_resolution_report.v1",
             "properties",
             "recommendations",
             "items",
             "properties",
             "priority_fields_without_numeric_evidence_count",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "contact_allocation_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "priority_field_evidence_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "contact_allocation_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "priority_fields_without_numeric_evidence_count",
             "type"
           ]) == "integer"

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_cadence_import_manifest"

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "model_limits",
             "const"
           ]) == cadence_import_manifest_model_limits()

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "priority_field_evidence_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "priority_fields_without_numeric_evidence_count",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "priority_fields_without_numeric_evidence",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "policy_bundle.v1",
             "properties",
             "approval_policy",
             "properties",
             "action_rules",
             "items",
             "properties",
             "priority_fields_without_numeric_evidence_count_min",
             "minimum"
           ]) == 0

    source_policy_decision_paths = [
      {"operator_review_package.v1",
       ["properties", "rows", "items", "properties", "source_policy_decision"]},
      {"cadence_import_manifest.v1",
       ["properties", "rows", "items", "properties", "source_policy_decision"]}
    ]

    Enum.each(source_policy_decision_paths, fn {contract_name, path} ->
      assert get_in(schemas, [contract_name | path] ++ ["properties", "classification", "enum"]) ==
               classification_values

      assert get_in(schemas, [contract_name | path] ++ ["properties", "schema_contract", "const"]) ==
               "policy_decision.v1"
    end)

    source_policy_escalation_paths = [
      {"operator_review_package.v1",
       ["properties", "rows", "items", "properties", "source_policy_escalation"]},
      {"cadence_import_manifest.v1",
       ["properties", "rows", "items", "properties", "source_policy_escalation"]}
    ]

    Enum.each(source_policy_escalation_paths, fn {contract_name, path} ->
      assert get_in(schemas, [contract_name | path] ++ ["properties", "classification", "enum"]) ==
               classification_values

      assert get_in(schemas, [contract_name | path] ++ ["properties", "sla_s", "type"]) ==
               "number"
    end)

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "import_action",
             "enum"
           ]) == OrbitalDynamics.CadenceImport.capability().import_actions

    operational_readiness_analysis_context_paths = [
      {"operational_readiness_report.v1", ["properties", "gates", "items", "properties"]},
      {"quality_gate_report.v1", ["properties", "rows", "items", "properties"]},
      {"operator_review_package.v1", ["properties", "rows", "items", "properties"]},
      {"cadence_import_manifest.v1", ["properties", "rows", "items", "properties"]},
      {"cadence_import_manifest.v1",
       ["properties", "rows", "items", "properties", "source_review_row", "properties"]}
    ]

    assert get_in(schemas, [
             "operational_readiness_report.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_operational_readiness_classifier"

    assert get_in(schemas, [
             "operational_readiness_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == operational_readiness_model_limits()

    assert get_in(schemas, [
             "operational_readiness_gate_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_operational_readiness_gate_summary"

    assert get_in(schemas, [
             "operational_readiness_gate_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == operational_readiness_gate_summary_model_limits()

    assert get_in(schemas, [
             "operational_import_eligibility_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_import_eligibility_summary"

    assert get_in(schemas, [
             "operational_import_eligibility_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == operational_import_eligibility_summary_model_limits()

    assert get_in(schemas, [
             "operational_execution_boundary_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_operational_execution_boundary_summary"

    assert get_in(schemas, [
             "operational_execution_boundary_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == operational_execution_boundary_summary_model_limits()

    assert get_in(schemas, [
             "operational_quality_gate_import_readiness_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_quality_gate_import_readiness_summary"

    assert get_in(schemas, [
             "operational_quality_gate_import_readiness_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == quality_gate_import_readiness_summary_model_limits()

    assert get_in(schemas, [
             "operational_quality_gate_operator_training_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_quality_gate_operator_training_summary"

    assert get_in(schemas, [
             "operational_quality_gate_operator_training_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == quality_gate_operator_training_summary_model_limits()

    assert get_in(schemas, [
             "operational_quality_gate_schema_validation_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_quality_gate_schema_validation_summary"

    assert get_in(schemas, [
             "operational_quality_gate_schema_validation_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == quality_gate_schema_validation_summary_model_limits()

    assert get_in(schemas, [
             "operational_quality_gate_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_quality_gate_summary"

    assert get_in(schemas, [
             "operational_quality_gate_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == quality_gate_summary_model_limits()

    assert get_in(schemas, [
             "operational_quality_gate_unavailable_resource_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_quality_gate_unavailable_resource_summary"

    assert get_in(schemas, [
             "operational_quality_gate_unavailable_resource_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == quality_gate_unavailable_resource_summary_model_limits()

    assert get_in(schemas, [
             "quality_gate_report.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_operational_quality_gate_report"

    assert get_in(schemas, [
             "quality_gate_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == quality_gate_report_model_limits()

    Enum.each(operational_readiness_analysis_context_paths, fn {contract_name, path} ->
      assert get_in(
               schemas,
               [contract_name | path] ++ ["analysis_mode", "enum"]
             ) == OrbitalDynamics.OperationalReadiness.capabilities().analysis_modes

      assert get_in(
               schemas,
               [contract_name | path] ++ ["analysis_mode_source", "type"]
             ) == "string"
    end)

    operational_readiness_operator_training_context_paths = [
      {"operational_readiness_report.v1", ["properties", "gates", "items", "properties"]},
      {"operational_readiness_report.v1", ["properties", "evidence", "properties"]},
      {"quality_gate_report.v1", ["properties", "rows", "items", "properties"]},
      {"operator_review_package.v1", ["properties", "rows", "items", "properties"]},
      {"cadence_import_manifest.v1", ["properties", "rows", "items", "properties"]},
      {"cadence_import_manifest.v1",
       ["properties", "rows", "items", "properties", "source_review_row", "properties"]}
    ]

    Enum.each(operational_readiness_operator_training_context_paths, fn {contract_name, path} ->
      assert get_in(
               schemas,
               [contract_name | path] ++ ["operator_training_requirement_count", "minimum"]
             ) == 0

      assert get_in(
               schemas,
               [contract_name | path] ++
                 ["operator_training_requirement_counts", "additionalProperties", "minimum"]
             ) == 0

      Enum.each(
        ~w(
          required_operator_roles
          required_training_ids
          required_certification_ids
          required_qualification_ids
        ),
        fn field ->
          assert get_in(
                   schemas,
                   [contract_name | path] ++ [field, "items", "type"]
                 ) == "string"
        end
      )
    end)

    operational_readiness_source_report_context_paths = [
      {"operator_review_package.v1", ["properties", "rows", "items", "properties"]},
      {"cadence_import_manifest.v1", ["properties", "rows", "items", "properties"]},
      {"cadence_import_manifest.v1",
       ["properties", "rows", "items", "properties", "source_review_row", "properties"]}
    ]

    Enum.each(operational_readiness_source_report_context_paths, fn {contract_name, path} ->
      assert get_in(
               schemas,
               [contract_name | path] ++
                 ["source_operational_readiness_report", "properties", "report_id", "pattern"]
             ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "source_operational_readiness_report",
                   "properties",
                   "source_artifact_type",
                   "type"
                 ]
             ) == "string"

      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "source_operational_readiness_report",
                   "properties",
                   "source_artifact_id",
                   "pattern"
                 ]
             ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

      assert get_in(
               schemas,
               [contract_name | path] ++
                 ["source_operational_readiness_report", "properties", "readiness_level", "enum"]
             ) == OrbitalDynamics.OperationalReadiness.capabilities().readiness_levels

      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "source_operational_readiness_report",
                   "properties",
                   "import_classification",
                   "enum"
                 ]
             ) == OrbitalDynamics.OperationalReadiness.capabilities().import_classifications

      assert get_in(
               schemas,
               [contract_name | path] ++
                 ["source_operational_readiness_report", "properties", "status", "enum"]
             ) == OrbitalDynamics.OperationalReadiness.capabilities().gate_statuses

      Enum.each(
        ~w(gate_count passed_gate_count review_gate_count analysis_gate_count blocked_gate_count),
        fn field ->
          assert get_in(
                   schemas,
                   [contract_name | path] ++
                     ["source_operational_readiness_report", "properties", field, "minimum"]
                 ) == 0
        end
      )

      assert get_in(
               schemas,
               [contract_name | path] ++
                 ["source_quality_gate_report", "properties", "report_id", "pattern"]
             ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

      assert get_in(
               schemas,
               [contract_name | path] ++
                 ["source_quality_gate_report", "properties", "source_artifact_type", "type"]
             ) == "string"

      assert get_in(
               schemas,
               [contract_name | path] ++
                 ["source_quality_gate_report", "properties", "source_artifact_id", "pattern"]
             ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

      assert get_in(
               schemas,
               [contract_name | path] ++
                 ["source_quality_gate_report", "properties", "readiness_level", "enum"]
             ) == OrbitalDynamics.OperationalReadiness.capabilities().readiness_levels

      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "source_quality_gate_report",
                   "properties",
                   "gate_status_counts",
                   "additionalProperties",
                   "minimum"
                 ]
             ) == 0

      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "source_quality_gate_report",
                   "properties",
                   "gate_classification_counts",
                   "additionalProperties",
                   "minimum"
                 ]
             ) == 0
    end)

    operational_readiness_resource_context_paths = [
      {"operational_readiness_report.v1", ["properties", "gates", "items", "properties"]},
      {"quality_gate_report.v1", ["properties", "rows", "items", "properties"]},
      {"operator_review_package.v1", ["properties", "rows", "items", "properties"]},
      {"cadence_import_manifest.v1", ["properties", "rows", "items", "properties"]},
      {"candidate_refresh.v1",
       [
         "properties",
         "provenance",
         "properties",
         "source_reports",
         "additionalProperties",
         "properties"
       ]}
    ]

    Enum.each(operational_readiness_resource_context_paths, fn {contract_name, path} ->
      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "resource_availability_pressure_count",
                   "minimum"
                 ]
             ) == 0

      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "resource_availability_reason_counts",
                   "additionalProperties",
                   "minimum"
                 ]
             ) == 0

      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "resource_availability_reason_ids",
                   "items",
                   "type"
                 ]
             ) == "string"

      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "unavailable_resource_reason_ids",
                   "items",
                   "type"
                 ]
             ) == "string"

      assert get_in(
               schemas,
               [contract_name | path] ++
                 [
                   "resource_blocking_dimension_counts",
                   "additionalProperties",
                   "minimum"
                 ]
             ) == 0
    end)

    candidate_refresh_source_report_summary_path = [
      "properties",
      "provenance",
      "properties",
      "source_reports",
      "additionalProperties",
      "properties"
    ]

    timeline_integrity_source_report_summary_path = [
      "properties",
      "provenance",
      "properties",
      "source_reports",
      "properties",
      "timeline_integrity_report",
      "properties"
    ]

    timeline_activity_lifecycle_source_report_summary_path = [
      "properties",
      "provenance",
      "properties",
      "source_reports",
      "properties",
      "timeline_activity_lifecycle_state",
      "properties"
    ]

    timeline_lifecycle_state_source_report_summary_path = [
      "properties",
      "provenance",
      "properties",
      "source_reports",
      "properties",
      "timeline_lifecycle_state_summary",
      "properties"
    ]

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_lifecycle_state_source_report_summary_path] ++
               ["review_required_count", "minimum"]
           ) == 0

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_lifecycle_state_source_report_summary_path] ++
               ["transition_decision_counts", "additionalProperties", "minimum"]
           ) == 0

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_lifecycle_state_source_report_summary_path] ++
               ["review_timeline_ids", "items", "pattern"]
           ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_lifecycle_state_source_report_summary_path] ++
               [
                 "review_timeline_ids_by_required_operator_action",
                 "additionalProperties",
                 "items",
                 "pattern"
               ]
           ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_lifecycle_state_source_report_summary_path] ++
               [
                 "review_routing",
                 "additionalProperties",
                 "properties",
                 "activity_ids",
                 "items",
                 "pattern"
               ]
           ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_activity_lifecycle_source_report_summary_path] ++
               ["review_required_count", "minimum"]
           ) == 0

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_activity_lifecycle_source_report_summary_path] ++
               ["transition_decision_counts", "additionalProperties", "minimum"]
           ) == 0

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_activity_lifecycle_source_report_summary_path] ++
               ["review_activity_id_counts", "additionalProperties", "type"]
           ) == "integer"

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_activity_lifecycle_source_report_summary_path] ++
               [
                 "action_routing",
                 "additionalProperties",
                 "properties",
                 "activity_ids",
                 "items",
                 "pattern"
               ]
           ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_activity_lifecycle_source_report_summary_path] ++
               [
                 "action_routing",
                 "additionalProperties",
                 "properties",
                 "protection_categories",
                 "items",
                 "type"
               ]
           ) == "string"

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_integrity_source_report_summary_path] ++
               ["timeline_integrity_issue_count", "minimum"]
           ) == 0

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_integrity_source_report_summary_path] ++
               ["timeline_integrity_issue_type_counts", "additionalProperties", "minimum"]
           ) == 0

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_integrity_source_report_summary_path] ++
               ["required_operator_action_counts", "additionalProperties", "minimum"]
           ) == 0

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_integrity_source_report_summary_path] ++
               ["review_activity_id_counts", "additionalProperties", "type"]
           ) == "integer"

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | timeline_integrity_source_report_summary_path] ++
               ["exclusivity_violation_group_counts", "additionalProperties", "minimum"]
           ) == 0

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
               ["station_pressure_contact_count", "minimum"]
           ) == 0

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
               ["trust_boundary_status", "type"]
           ) == "string"

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
               ["trust_boundaries", "items", "type"]
           ) == "string"

    Enum.each(
      [
        "invalid_activity_input_count",
        "projected_resource_count",
        "invalid_resource_summary_input_count"
      ],
      fn field ->
        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [field, "type"]
               ) == "integer"

        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [field, "minimum"]
               ) == 0
      end
    )

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
               ["invalid_activity_input_reasons", "items", "type"]
           ) == "string"

    Enum.each(
      [
        "ground_station_counts",
        "target_counts",
        "collection_counts",
        "constraint_metric_counts",
        "constraint_resource_counts",
        "constraint_spacecraft_counts",
        "resource_pressure_status_counts",
        "resource_projection_spacecraft_counts",
        "resource_pressure_type_counts",
        "resource_pressure_activity_id_counts",
        "resource_pressure_direction_counts",
        "source_artifact_type_counts",
        "source_flow_summary_model_counts",
        "resource_filter_spacecraft_counts",
        "resource_filter_resource_counts",
        "resource_filter_blocking_dimension_counts",
        "contact_contention_ground_station_counts",
        "contact_contention_contact_id_counts",
        "candidate_rejection_candidate_id_counts",
        "candidate_rejection_ground_station_counts",
        "selected_contact_id_counts",
        "actual_throughput_contact_id_counts",
        "station_pressure_ground_station_counts",
        "station_pressure_availability_counts",
        "station_pressure_precedence_availability_counts",
        "station_pressure_precedence_rank_counts",
        "analysis_mode_counts",
        "source_summary_model_counts",
        "source_summary_schema_contract_counts",
        "invalid_activity_input_reason_counts",
        "status_counts",
        "stale_reason_counts",
        "unknown_reason_counts",
        "invalid_candidate_limit_policy_reason_counts",
        "validated_contract_counts",
        "validation_mode_counts",
        "remediation_action_counts",
        "remediation_category_counts",
        "remediation_path_counts",
        "timeline_publication_source_artifact_type_counts"
      ],
      fn field ->
        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [field, "type"]
               ) == "object"

        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [field, "additionalProperties", "minimum"]
               ) == 0
      end
    )

    Enum.each(
      [
        "stale_reason_count",
        "unknown_reason_count",
        "input_candidate_count",
        "kept_candidate_count",
        "dropped_candidate_count",
        "invalid_candidate_limit_policy_count",
        "error_count",
        "warning_count",
        "remediation_count"
      ],
      fn field ->
        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [field, "minimum"]
               ) == 0
      end
    )

    Enum.each(
      [
        "stale_reasons",
        "unknown_reasons",
        "kept_candidate_ids",
        "dropped_candidate_ids"
      ],
      fn field ->
        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [field, "items", "type"]
               ) == "string"
      end
    )

    Enum.each(
      [
        "invalid_activity_input_ids",
        "invalid_resource_summary_input_ids"
      ],
      fn field ->
        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [field, "items", "pattern"]
               ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
               ["resource_pressure_directions", "items", "type"]
           ) == "string"

    Enum.each(
      [
        "resource_pressure_activity_ids_by_status",
        "resource_pressure_activity_ids_by_type",
        "resource_pressure_activity_ids_by_ground_station",
        "resource_pressure_activity_ids_by_spacecraft",
        "resource_pressure_activity_ids_by_direction",
        "resource_pressure_ground_station_ids_by_type",
        "resource_pressure_source_window_ids_by_status",
        "resource_pressure_source_window_ids_by_type",
        "resource_pressure_station_calendar_entry_ids_by_status",
        "resource_pressure_station_calendar_entry_ids_by_type",
        "resource_pressure_station_calendar_provider_ids_by_status",
        "resource_pressure_station_calendar_provider_ids_by_type",
        "resource_pressure_station_calendar_provider_entry_ids_by_status",
        "resource_pressure_station_calendar_provider_entry_ids_by_type"
      ],
      fn field ->
        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [
                     field,
                     "additionalProperties",
                     "items",
                     "pattern"
                   ]
               ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      end
    )

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
               [
                 "resource_pressure_direction_routing",
                 "additionalProperties",
                 "properties",
                 "pressure_count",
                 "minimum"
               ]
           ) == 0

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
               [
                 "resource_pressure_direction_routing",
                 "additionalProperties",
                 "properties",
                 "activity_ids",
                 "items",
                 "pattern"
               ]
           ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    Enum.each(
      [
        "station_feedback_count",
        "station_calendar_status_counts",
        "policy_classification_counts",
        "capacity_pack_required_contact_count",
        "capacity_pack_required_capacity_fraction",
        "required_capacity_fraction_contact_ids_by_source",
        "directions"
      ],
      fn field ->
        refute Map.has_key?(
                 get_in(schemas, [
                   "candidate_refresh.v1" | candidate_refresh_source_report_summary_path
                 ]),
                 field
               )
      end
    )

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
               ["station_suppression_count", "minimum"]
           ) == 0

    Enum.each(
      [
        "station_suppression_ground_station_counts",
        "station_suppression_availability_counts",
        "station_suppression_status_counts"
      ],
      fn field ->
        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [field, "additionalProperties", "minimum"]
               ) == 0
      end
    )

    Enum.each(
      [
        "affected_contact_ground_station_counts",
        "affected_contact_availability_counts",
        "provider_calendar_contention_provider_counts",
        "provider_calendar_contention_ground_station_counts"
      ],
      fn field ->
        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [field, "additionalProperties", "minimum"]
               ) == 0
      end
    )

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "import_status",
             "enum"
           ]) == OrbitalDynamics.CadenceImport.capability().import_statuses

    Enum.each(
      [
        "cadence_import_status",
        "source_cadence_import_status",
        "replacement_cadence_import_status"
      ],
      fn status_field ->
        assert get_in(schemas, [
                 "cadence_import_manifest.v1",
                 "properties",
                 "rows",
                 "items",
                 "properties",
                 status_field,
                 "enum"
               ]) == OrbitalDynamics.CadenceImport.capability().cadence_import_statuses
      end
    )

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "source_review_type",
             "enum"
           ]) == OrbitalDynamics.CadenceImport.capability().source_review_types

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "source_review_row",
             "properties",
             "review_type",
             "enum"
           ]) == OrbitalDynamics.CadenceImport.capability().source_review_types

    stable_id_pattern = OrbitalDynamics.Schema.identity_policy()["stable_id_pattern"]

    for contract <- ["operator_review_package.v1", "cadence_import_manifest.v1"] do
      row_properties_path = [
        contract,
        "properties",
        "rows",
        "items",
        "properties"
      ]

      assert get_in(schemas, row_properties_path ++ ["dependency_impact_scope", "enum"]) == [
               "source",
               "replacement"
             ]

      Enum.each(
        [
          "changed_source_activity_count",
          "changed_source_timeline_count",
          "dependent_activity_count",
          "source_dependent_activity_count",
          "replacement_dependent_activity_count"
        ],
        fn field ->
          assert get_in(schemas, row_properties_path ++ [field, "minimum"]) == 0
        end
      )

      Enum.each(
        [
          "impacted_source_activity_ids",
          "impacted_source_timeline_ids",
          "dependent_activity_ids",
          "dependent_timeline_ids",
          "source_dependent_activity_ids",
          "source_dependent_timeline_ids",
          "replacement_dependent_activity_ids",
          "replacement_dependent_timeline_ids",
          "dependency_activity_ids",
          "dependency_timeline_ids",
          "exclusive_with_activity_ids",
          "exclusive_with_timeline_ids",
          "impacted_dependency_activity_ids",
          "impacted_dependency_timeline_ids",
          "impacted_exclusive_with_activity_ids",
          "impacted_exclusive_with_timeline_ids"
        ],
        fn field ->
          assert get_in(schemas, row_properties_path ++ [field, "items", "pattern"]) ==
                   stable_id_pattern
        end
      )
    end

    assert get_in(schemas, [
             "campaign_strategy.v3",
             "properties",
             "approval_policy",
             "properties",
             "blocked_risk_types",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "strategy_recommendation.v1",
             "properties",
             "tradeoffs",
             "items",
             "properties",
             "delta",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "strategy_recommendation.v1",
             "properties",
             "requires_approval",
             "items",
             "properties",
             "schema_contract",
             "const"
           ]) == "approval_requirement.v1"

    assert get_in(schemas, [
             "maneuver_recommendation.v1",
             "properties",
             "delta_v_km_s",
             "minItems"
           ]) == 3

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "timeline_protection_count",
             "type"
           ]) == "integer"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "review_type",
             "enum"
           ])
           |> Enum.member?("timeline_protection")

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "protection_decision",
             "enum"
           ]) == ["preserved", "changed"]

    assert get_in(schemas, [
             "campaign_repair.v2",
             "properties",
             "warnings",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "campaign_repair.v2",
             "properties",
             "activities",
             "items",
             "properties",
             "source_window_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "campaign_repair.v2",
             "properties",
             "source_candidate_activities",
             "items",
             "properties",
             "score_terms",
             "type"
           ]) == "object"

    assert get_in(schemas, [
             "campaign_repair.v2",
             "properties",
             "deltas",
             "items",
             "properties",
             "planned",
             "properties",
             "timeline_identity",
             "type"
           ]) == "object"

    assert get_in(schemas, [
             "campaign_repair.v2",
             "properties",
             "approval_requirements",
             "items",
             "properties",
             "policy_classification",
             "enum"
           ]) == ["auto_approvable", "operator_review_required", "blocked_by_policy"]

    assert get_in(schemas, [
             "campaign_repair.v2",
             "properties",
             "operational_timeline_report",
             "type"
           ]) == "object"

    refute "operational_timeline_report" in get_in(schemas, ["campaign_repair.v2", "required"])

    assert get_in(schemas, ["objective_satisfaction_report.v1", "properties", "rows", "type"]) ==
             "array"

    assert get_in(schemas, [
             "objective_satisfaction_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "status",
             "enum"
           ]) == [
             "met",
             "partial",
             "unmet",
             "selected",
             "candidate_available",
             "no_candidate_window",
             "no_requirement"
           ]

    assert get_in(schemas, [
             "objective_satisfaction_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "selected_activity_ids",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "monte_carlo_reproducibility_report.v1",
             "properties",
             "model",
             "const"
           ]) == "seeded_independent_normal_cartesian_dispersion"

    assert get_in(schemas, [
             "monte_carlo_reproducibility_report.v1",
             "properties",
             "generated_scenario_ids",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "monte_carlo_reproducibility_report.v1",
             "properties",
             "known_limits",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "monte_carlo_reproducibility_report.v1",
             "properties",
             "position_sigma_km",
             "minItems"
           ]) == 3

    assert get_in(schemas, [
             "monte_carlo_reproducibility_report.v1",
             "properties",
             "velocity_sigma_km_s",
             "items",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_state_snapshot.v1",
             "properties",
             "activities",
             "items",
             "properties",
             "status",
             "enum"
           ]) == [
             "completed",
             "executed",
             "partial",
             "missed",
             "failed",
             "delayed",
             "canceled",
             "cancelled",
             "rejected"
           ]

    assert get_in(schemas, [
             "realized_state_snapshot.v1",
             "properties",
             "spacecraft_states",
             "items",
             "properties",
             "scenario_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "attitude_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "resource_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "activity_type",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "battery_state_of_charge",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "battery_energy_generated_wh",
             "minimum"
           ]) == 0.0

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "payload_available",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "command_authority_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "command_authorized",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "suppressed_activity_types",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "pointing_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "off_nadir_angle_deg",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "pointing_confidence",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "thermal_zone_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "actual_temperature_c",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "thermal_confidence",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "eclipse_overlap_fraction",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "lighting_condition",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "lighting_confidence",
             "type"
           ]) == ["number", "string"]

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "frequency_band",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "data_rate_mbps",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "carrier_lock",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "collection_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "product_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "actual_data_volume_mb",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "actual_latency_s",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "contact_result",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "contact_success_factor",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "observation_success",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "maneuver_success_factor_source",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "delta_v_km_s",
             "minItems"
           ]) == 3

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "actual_delta_v_km_s",
             "maxItems"
           ]) == 3

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "execution_uncertainty",
             "type"
           ]) == "object"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "delta_v_3sigma_km_s",
             "items",
             "type"
           ]) == "number"

    assert get_in(schemas, ["realized_activity.v1", "properties", "roll_deg", "type"]) ==
             "number"

    assert get_in(schemas, [
             "realized_activity.v1",
             "properties",
             "attitude_confidence",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "candidate_activity.v1",
             "properties",
             "activity_context",
             "properties",
             "target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "candidate_activity.v1",
             "properties",
             "source_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "candidate_activity.v1",
             "properties",
             "source_target",
             "type"
           ]) == "object"

    assert get_in(schemas, [
             "candidate_activity.v1",
             "properties",
             "target_latitude_deg",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "candidate_activity.v1",
             "properties",
             "activity_context",
             "properties",
             "source_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "candidate_activity.v1",
             "properties",
             "activity_context",
             "properties",
             "target_minimum_elevation_deg",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "candidate_diff_row.v1",
             "properties",
             "source_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "candidate_diff_report.v1",
             "properties",
             "model",
             "const"
           ]) == "candidate_id_set_diff_with_semantic_change_reasons"

    assert get_in(schemas, [
             "candidate_diff_report.v1",
             "properties",
             "new_candidates",
             "items",
             "properties",
             "target_latitude_deg",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "candidate_diff_row.v1",
             "properties",
             "target_priority",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "candidate_diff_report.v1",
             "properties",
             "new_candidates",
             "items",
             "properties",
             "target_priority_source",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "candidate_diff_report.v1",
             "properties",
             "new_candidates",
             "items",
             "properties",
             "candidate_diff_changed_fields",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "candidate_diff_report.v1",
             "properties",
             "new_candidates",
             "items",
             "properties",
             "candidate_diff_changed_field_count",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "candidate_diff_report.v1",
             "properties",
             "new_candidates",
             "items",
             "properties",
             "semantic_change_details",
             "items",
             "properties",
             "field",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "candidate_diff_report.v1",
             "properties",
             "invalidated_candidates",
             "items",
             "properties",
             "source_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "candidate_diff_report.v1",
             "properties",
             "invalidated_candidates",
             "items",
             "properties",
             "target_priority_objective_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "source_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "target_latitude_deg",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "target_priority",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "candidate_diff_changed_fields",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "eclipse_overlap_fraction",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "attitude_confidence",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "command_authority_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "realized_command_authorized",
             "type"
           ]) == "boolean"

    for {field, type} <- [
          {"command_authority_status", "string"},
          {"required_authority", "string"},
          {"command_safety_status", "string"},
          {"command_authorized", "boolean"},
          {"command_safety_checked", "boolean"}
        ] do
      assert get_in(schemas, [
               "operator_review_package.v1",
               "properties",
               "rows",
               "items",
               "properties",
               "source_operational_timeline",
               "properties",
               field,
               "type"
             ]) == type
    end

    assert_exported_precondition_handoff = fn properties_path ->
      assert get_in(schemas, properties_path ++ ["precondition_status", "enum"]) ==
               precondition_capabilities.activity_precondition_statuses

      assert get_in(schemas, properties_path ++ ["blocked_precondition_count", "minimum"]) == 0
      assert get_in(schemas, properties_path ++ ["review_precondition_count", "minimum"]) == 0

      assert get_in(schemas, properties_path ++ ["blocked_precondition_types", "items", "type"]) ==
               "string"

      assert get_in(schemas, properties_path ++ ["review_precondition_types", "items", "type"]) ==
               "string"

      assert get_in(
               schemas,
               properties_path ++
                 [
                   "preconditions",
                   "items",
                   "properties",
                   "type",
                   "enum"
                 ]
             ) == precondition_capabilities.activity_precondition_types

      assert get_in(
               schemas,
               properties_path ++
                 [
                   "preconditions",
                   "items",
                   "properties",
                   "status",
                   "enum"
                 ]
             ) == precondition_capabilities.activity_precondition_statuses

      assert get_in(schemas, properties_path ++ ["preconditions", "items", "required"]) == [
               "type",
               "status",
               "field",
               "reason"
             ]
    end

    operator_review_row_properties_path = [
      "operator_review_package.v1",
      "properties",
      "rows",
      "items",
      "properties"
    ]

    assert_exported_precondition_handoff.(operator_review_row_properties_path)

    assert_exported_precondition_handoff.(
      operator_review_row_properties_path ++
        [
          "source_operational_timeline",
          "properties"
        ]
    )

    assert get_in(schemas, [
             "strategy_branch.v1",
             "properties",
             "events",
             "items",
             "properties",
             "source_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "strategy_branch.v1",
             "properties",
             "events",
             "items",
             "properties",
             "target_minimum_elevation_deg",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "strategy_branch.v1",
             "properties",
             "events",
             "items",
             "properties",
             "target_priority_source",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "strategy_branch.v1",
             "properties",
             "events",
             "items",
             "properties",
             "semantic_change_details",
             "items",
             "properties",
             "refreshed_value",
             "anyOf"
           ])

    assert get_in(schemas, [
             "strategy_branch.v1",
             "properties",
             "events",
             "items",
             "properties",
             "candidate_diff_changed_field_count",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "source_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "target_minimum_elevation_deg",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "target_priority",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "candidate_diff_changed_fields",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "lighting_confidence",
             "type"
           ]) == ["number", "string"]

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "attitude_source",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "command_safety_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "command_safety_checked",
             "type"
           ]) == "boolean"

    for {field, type} <- [
          {"command_authority_status", "string"},
          {"required_authority", "string"},
          {"command_safety_status", "string"},
          {"command_authorized", "boolean"},
          {"command_safety_checked", "boolean"}
        ] do
      assert get_in(schemas, [
               "cadence_import_manifest.v1",
               "properties",
               "rows",
               "items",
               "properties",
               "source_operational_timeline",
               "properties",
               field,
               "type"
             ]) == type

      assert get_in(schemas, [
               "cadence_import_manifest.v1",
               "properties",
               "rows",
               "items",
               "properties",
               "source_review_row",
               "properties",
               "source_operational_timeline",
               "properties",
               field,
               "type"
             ]) == type
    end

    cadence_import_row_properties_path = [
      "cadence_import_manifest.v1",
      "properties",
      "rows",
      "items",
      "properties"
    ]

    assert_exported_precondition_handoff.(cadence_import_row_properties_path)

    assert_exported_precondition_handoff.(
      cadence_import_row_properties_path ++
        [
          "source_operational_timeline",
          "properties"
        ]
    )

    cadence_source_review_row_properties_path =
      cadence_import_row_properties_path ++
        [
          "source_review_row",
          "properties"
        ]

    assert_exported_precondition_handoff.(cadence_source_review_row_properties_path)

    assert_exported_precondition_handoff.(
      cadence_source_review_row_properties_path ++
        [
          "source_operational_timeline",
          "properties"
        ]
    )

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "source_review_row",
             "properties",
             "realized_command_safety_checked",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "cadence_import_manifest.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "import_activity_context",
             "properties",
             "activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]
  end

  defp cadence_import_manifest_model_limits do
    OrbitalDynamics.CadenceImport.capability()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp operational_readiness_model_limits do
    OrbitalDynamics.OperationalReadiness.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp operational_readiness_gate_summary_model_limits do
    [
      "operational_readiness_gate_summary_routes_only",
      "operational_readiness_gate_summary_does_not_approve_or_import"
    ]
  end

  defp operational_execution_boundary_summary_model_limits do
    [
      "operational_execution_boundary_summary_routes_only",
      "operational_execution_boundary_summary_does_not_execute_or_import"
    ]
  end

  defp operational_import_eligibility_summary_model_limits do
    [
      "operational_import_eligibility_summary_routes_only",
      "operational_import_eligibility_summary_does_not_approve_or_import"
    ]
  end

  defp quality_gate_report_model_limits do
    [
      "quality_gate_report_derives_classification_from_gate_rows",
      "quality_gate_report_does_not_approve_or_import"
    ]
  end

  defp quality_gate_summary_model_limits do
    [
      "quality_gate_summary_derives_classification_from_gate_rows",
      "quality_gate_summary_does_not_approve_or_import"
    ]
  end

  defp quality_gate_unavailable_resource_summary_model_limits do
    [
      "quality_gate_unavailable_resource_summary_routes_only",
      "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
    ]
  end

  defp quality_gate_operator_training_summary_model_limits do
    [
      "quality_gate_operator_training_summary_routes_only",
      "quality_gate_operator_training_summary_does_not_approve_or_import"
    ]
  end

  defp quality_gate_schema_validation_summary_model_limits do
    [
      "quality_gate_schema_validation_summary_routes_only",
      "quality_gate_schema_validation_summary_does_not_approve_or_import"
    ]
  end

  defp quality_gate_import_readiness_summary_model_limits do
    [
      "quality_gate_import_readiness_summary_routes_only",
      "quality_gate_import_readiness_summary_does_not_approve_or_import"
    ]
  end
end
