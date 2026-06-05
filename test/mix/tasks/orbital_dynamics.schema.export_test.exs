defmodule Mix.Tasks.OrbitalDynamics.Schema.ExportTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.{Schema, Validation}

  test "exports a single contract schema" do
    output_path = Path.join(System.tmp_dir!(), "campaign_plan.v1.schema.json")

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.export", [
          "--contract",
          "campaign_plan.v1",
          "--output",
          output_path
        ])
      end)

    assert output =~ "OrbitalDynamics schema export"
    assert output =~ "wrote: #{output_path}"

    assert %{
             "$schema" => "https://json-schema.org/draft/2020-12/schema",
             "required" => required,
             "properties" => %{"schema_version" => %{"const" => 1}},
             "x-orbital-dynamics" => %{"schema_contract" => "campaign_plan.v1"}
           } = output_path |> File.read!() |> :json.decode()

    assert "plan_id" in required
  end

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

    assert get_in(schemas, [
             "link_capacity_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == link_capacity_model_limits

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
    assert Map.has_key?(schemas, "operational_timeline_report.v1")
    assert Map.has_key?(schemas, "timeline_diff_summary.v1")

    operational_timeline_schema = schemas["operational_timeline_report.v1"]

    assert get_in(operational_timeline_schema, ["properties", "model", "const"]) ==
             "selected_activity_operational_context_summary"

    assert get_in(operational_timeline_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    operational_timeline_row_properties =
      get_in(operational_timeline_schema, ["properties", "rows", "items", "properties"])

    assert get_in(operational_timeline_row_properties, [
             "command_authority_status",
             "type"
           ]) == "string"

    assert get_in(operational_timeline_row_properties, ["required_authority", "type"]) ==
             "string"

    assert get_in(operational_timeline_row_properties, [
             "command_safety_status",
             "type"
           ]) == "string"

    assert get_in(operational_timeline_row_properties, ["command_authorized", "type"]) ==
             "boolean"

    assert get_in(operational_timeline_row_properties, [
             "command_safety_checked",
             "type"
           ]) == "boolean"

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
           ]) == ["timeline_transition_application_report.v1"]

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

    assert Map.has_key?(schemas, "timeline_feedback_report.v1")

    feedback_schema = schemas["timeline_feedback_report.v1"]

    assert get_in(feedback_schema, ["properties", "model", "const"]) ==
             "planned_vs_realized_activity_reconciliation"

    assert get_in(feedback_schema, ["properties", "model_limits", "const"]) ==
             timeline_feedback_report_model_limits()

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
           ]) == classification_values

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
           ]) == classification_values

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
             "operator_review_package.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_operator_review_package"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "model_limits",
             "const"
           ]) == operator_review_package_model_limits()

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "priority_fields_without_numeric_evidence",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "priority_fields_without_numeric_evidence_count",
             "minimum"
           ]) == 0

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

    assert get_in(
             schemas,
             ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
               ["station_feedback_count", "minimum"]
           ) == 0

    Enum.each(
      [
        "station_calendar_status_counts",
        "cadence_import_status_counts",
        "policy_classification_counts"
      ],
      fn field ->
        assert get_in(
                 schemas,
                 ["candidate_refresh.v1" | candidate_refresh_source_report_summary_path] ++
                   [field, "additionalProperties", "minimum"]
               ) == 0
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
             "maneuver_review_report.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_maneuver_review_report"

    assert get_in(schemas, [
             "maneuver_review_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == maneuver_review_report_model_limits()

    assert get_in(schemas, [
             "maneuver_review_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "delta_v_km_s",
             "items",
             "type"
           ]) == "number"

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
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "status",
             "enum"
           ]) == ["matched", "planned_only", "realized_only"]

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "lighting_condition",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "realized_activity_context",
             "properties",
             "lighting_confidence",
             "type"
           ]) == ["number", "string"]

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "attitude_confidence",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "command_authority_status",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "realized_command_authorized",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "realized_activity_context",
             "properties",
             "command_safety_checked",
             "type"
           ]) == "boolean"

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
             "timeline_feedback_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "source_activity_context",
             "properties",
             "attitude_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

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

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == OrbitalDynamics.Timeline.model_limits()

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "source",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "rows",
             "type"
           ]) == "array"

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "rows",
             "items",
             "required"
           ]) == [
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

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "locked",
             "type"
           ]) == "boolean"

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "activity_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().activity_statuses

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "required_operator_action_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().required_operator_actions

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "operational_kind_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "roll_deg",
             "type"
           ]) == "number"

    assert get_in(schemas, [
             "operational_timeline_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "timeline_identity",
             "properties",
             "timeline_id",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schemas, [
             "model_acceptance_report.v1",
             "properties",
             "model",
             "const"
           ]) == "registry_model_acceptance_classifier"

    validation_model_limits = OrbitalDynamics.Validation.capabilities().known_limits

    assert get_in(schemas, [
             "model_acceptance_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == validation_model_limits

    assert get_in(schemas, [
             "model_acceptance_report.v1",
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == validation_model_limits

    assert get_in(schemas, [
             "validation_safety_case_summary.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_validation_safety_case_summary"

    assert get_in(schemas, [
             "validation_safety_case_summary.v1",
             "properties",
             "model_limits",
             "const"
           ]) == validation_model_limits

    assert get_in(schemas, [
             "validation_safety_case_summary.v1",
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == validation_model_limits

    assert get_in(schemas, [
             "model_acceptance_report.v1",
             "properties",
             "status_counts",
             "propertyNames",
             "enum"
           ]) == ["accepted", "review_required", "blocked"]

    assert get_in(schemas, [
             "validation_reference_fixture_report.v1",
             "properties",
             "fixture_count",
             "minimum"
           ]) == 0

    assert get_in(schemas, [
             "validation_reference_fixture_report.v1",
             "properties",
             "status_counts",
             "propertyNames",
             "enum"
           ]) == ["pass", "fail"]

    assert get_in(schemas, [
             "validation_reference_fixture_report.v1",
             "properties",
             "reports",
             "items",
             "properties",
             "status_counts",
             "propertyNames",
             "enum"
           ]) == ["pass", "fail"]

    assert get_in(schemas, [
             "validation_reference_fixture_report.v1",
             "properties",
             "reports",
             "items",
             "properties",
             "checks",
             "items",
             "properties",
             "status",
             "enum"
           ]) == ["pass", "fail"]
  end

  test "requires either a contract or all flag" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.schema.export") end)

    assert_raise Mix.Error, ~r/--contract is required/, fn ->
      Mix.Task.run("orbital_dynamics.schema.export", ["--output", "unused.json"])
    end
  end

  test "exports all individual contract schemas to a directory" do
    output_dir =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_schema_export_#{System.unique_integer([:positive])}"
      )

    bundle_path = Path.join(output_dir, "orbital_dynamics.schema_bundle.v1.json")

    on_exit(fn ->
      File.rm_rf(output_dir)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.schema.export", [
          "--all",
          "--directory",
          output_dir,
          "--output",
          bundle_path
        ])
      end)

    expected_contracts =
      Schema.contracts()
      |> Map.keys()
      |> Enum.sort()

    assert output =~ "OrbitalDynamics schema export"
    assert output =~ "wrote: #{bundle_path}"

    Enum.each(expected_contracts, fn contract ->
      schema_path = Path.join(output_dir, "#{contract}.schema.json")

      assert output =~ "wrote: #{schema_path}"
      assert File.exists?(schema_path)

      assert get_in(schema_path |> File.read!() |> :json.decode(), [
               "x-orbital-dynamics",
               "schema_contract"
             ]) == contract
    end)

    assert File.exists?(bundle_path)

    assert %{"schema_count" => count, "schemas" => schemas} =
             bundle_path |> File.read!() |> :json.decode()

    assert count == length(expected_contracts)
    assert schemas |> Map.keys() |> Enum.sort() == expected_contracts
  end

  defp timeline_feedback_report_model_limits do
    OrbitalDynamics.TimelineFeedback.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp maneuver_review_report_model_limits do
    OrbitalDynamics.ManeuverReview.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp operator_review_package_model_limits do
    OrbitalDynamics.OperatorReview.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
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
