defmodule OrbitalDynamics.Schema.RegistryCapabilityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, Epoch, ResultSet, Schema}

  test "declares and enforces stable artifact identity policy" do
    policy = Schema.identity_policy()

    assert policy["policy_version"] == 1
    assert policy["stable_id_pattern"] == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
    assert "emit_identifier_with_whitespace" in policy["breaking_changes"]

    assert %{
             "generated_id_field" => "id",
             "identity_fields" => [
               "type",
               "scenario_id",
               "target_id",
               "ground_station_id",
               "starts_at_s",
               "ends_at_s"
             ],
             "ordering" => [
               "type",
               "scenario_id",
               "target_id",
               "ground_station_id",
               "starts_at_s",
               "id"
             ],
             "semantic_invariants" => [
               "source_record_order_must_not_change_generated_window_id",
               "canonical_source_event_sort_key_must_drive_window_index",
               "same_semantic_source_window_must_keep_generated_window_id"
             ]
           } =
             Enum.find(
               policy["generated_id_scopes"],
               &(&1["scope"] ==
                   "candidate_refresh.v1.refreshed_windows.generated_window_id")
             )

    assert %{
             "generated_id_field" => "id",
             "identity_fields" => [
               "resource_scope",
               "ground_station_id",
               "spacecraft_id",
               "starts_at_s",
               "ends_at_s",
               "contact_ids"
             ],
             "ordering" => [
               "resource_scope",
               "ground_station_id",
               "spacecraft_id",
               "starts_at_s",
               "id"
             ],
             "semantic_invariants" => [
               "source_record_order_must_not_change_generated_group_id",
               "canonical_contact_sort_key_must_drive_conflict_group_index",
               "same_semantic_contention_group_must_keep_generated_group_id"
             ]
           } =
             Enum.find(
               policy["generated_id_scopes"],
               &(&1["scope"] ==
                   "contact_contention_report.v1.conflict_groups.generated_group_id")
             )

    assert %{
             "generated_id_field" => "group_id",
             "identity_fields" => [
               "group_id",
               "resource_scope",
               "ground_station_id",
               "spacecraft_id",
               "starts_at_s",
               "selected_contact_id",
               "deferred_contact_ids"
             ],
             "ordering" => [
               "resource_scope",
               "ground_station_id",
               "spacecraft_id",
               "starts_at_s",
               "group_id"
             ],
             "semantic_invariants" => [
               "contention_group_id_must_flow_to_recommendation_group_id",
               "source_record_order_must_not_change_recommendation_group_id",
               "resolution_ordering_must_not_change_group_identity"
             ]
           } =
             Enum.find(
               policy["generated_id_scopes"],
               &(&1["scope"] ==
                   "contact_contention_resolution_report.v1.recommendations.generated_group_id")
             )

    assert %{
             "identity_fields" => [
               "source_spacecraft_id",
               "relay_chain_spacecraft_ids",
               "ground_station_id",
               "ground_downlink_contact_id",
               "latency_s",
               "latency_limit_s",
               "product_ids",
               "collection_ids"
             ],
             "explicit_id_fields" => ["route_id", "id", "data_path_id"],
             "ordering" => [
               "source_spacecraft_id",
               "ground_downlink_contact_id",
               "semantic_route_fingerprint"
             ],
             "semantic_invariants" => [
               "source_record_order_must_not_change_generated_route_id",
               "semantic_route_evidence_changes_must_change_generated_route_id",
               "explicit_route_id_takes_precedence_over_generated_route_id"
             ]
           } =
             Enum.find(
               policy["generated_id_scopes"],
               &(&1["scope"] == "relay_data_path_summary.v1.rows.generated_route_id")
             )

    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")
    assert schema["properties"]["plan_id"]["pattern"] == policy["stable_id_pattern"]

    invalid_artifact = Map.put(campaign_artifact(), "plan_id", "campaign plan with spaces")

    assert {:error, report} = Schema.validate_artifact(invalid_artifact)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.plan_id"))
  end

  test "declares executable schema registry capabilities" do
    capabilities = Schema.capabilities()

    assert capabilities.model == :executable_artifact_contract_registry
    assert capabilities.artifact_contracts == Schema.contracts() |> Map.keys() |> Enum.sort()
    assert capabilities.artifact_contract_count == map_size(Schema.contracts())
    assert capabilities.json_schema_draft == "https://json-schema.org/draft/2020-12/schema"

    assert capabilities.compatibility_policy_version ==
             Schema.compatibility_policy()["policy_version"]

    assert capabilities.identity_policy_version == Schema.identity_policy()["policy_version"]

    publication_id_scope =
      Enum.find(
        Schema.identity_policy()["generated_id_scopes"],
        &(&1["scope"] == "timeline_publication_summary.v1.publication_id")
      )

    assert publication_id_scope["generated_id_field"] == "publication_id"

    assert publication_id_scope["identity_fields"] == [
             "publication_sequence",
             "source_artifact_id",
             "supersedes_artifact_ids"
           ]

    assert publication_id_scope["ordering"] == [
             "publication_sequence",
             "source_artifact_id",
             "supersedes_artifact_ids"
           ]

    assert publication_id_scope["semantic_invariants"] == [
             "source_record_order_must_not_change_publication_id",
             "same_publication_sequence_and_artifact_lineage_must_keep_publication_id",
             "publication_id_serializes_declared_artifact_lineage"
           ]

    assert capabilities.validation_report_contracts == [
             "schema_validation_report.v1",
             "schema_validation_batch_report.v1",
             "schema_migration_report.v1"
           ]

    assert :schema_validation_validated_contract_metadata in capabilities.validation_report_semantics

    assert :schema_validation_status_and_issue_counts in capabilities.validation_report_semantics
    assert :schema_validation_remediation_rows in capabilities.validation_report_semantics
    assert :schema_validation_model_limit_enforcement in capabilities.validation_report_semantics

    assert :schema_validation_batch_file_artifact_and_skip_counts in capabilities.validation_report_semantics

    assert :schema_validation_batch_nested_report_entries in capabilities.validation_report_semantics

    assert :schema_migration_deprecation_warning_rollups in capabilities.validation_report_semantics

    assert :schema_migration_status_and_action_counts in capabilities.validation_report_semantics

    assert :compatibility_policy_version_breadcrumbs in capabilities.compatibility_export_semantics
    assert :identity_policy_version_breadcrumbs in capabilities.compatibility_export_semantics
    assert :direct_declared_nested_contract_defs in capabilities.compatibility_export_semantics

    assert "top_level_json_schema_compatibility_export" in capabilities.known_limits
  end

  test "validates activity template schema contract" do
    assert {:ok, contract} = Schema.contract("activity_template.v1")
    assert contract["artifact_family"] == "activity_template"
    assert "activity_template.v1" in Schema.capabilities().artifact_contracts

    assert {:ok, schema} = Schema.json_schema("activity_template.v1")
    assert schema["properties"]["schema_contract"]["const"] == "activity_template.v1"
    assert schema["properties"]["id"]["pattern"]

    assert schema["properties"]["activity_type"]["enum"] ==
             OrbitalDynamics.Timeline.capabilities().supported_activity_types

    assert schema["properties"]["template_version"]["minimum"] == 1
    assert schema["properties"]["validation_level"]["const"] == "artifact_contract"

    assert schema["properties"]["precondition_hints"]["items"]["properties"][
             "precondition_type"
           ]["enum"] == OrbitalDynamics.Timeline.capabilities().activity_precondition_types

    assert schema["properties"]["subsystem_state_hints"]["properties"]["required_states"][
             "items"
           ]["required"] == ["subsystem", "state"]

    assert schema["properties"]["lifecycle_defaults"]["properties"]["status"]["enum"] ==
             OrbitalDynamics.Timeline.capabilities().activity_statuses

    template = %{
      "schema_contract" => "activity_template.v1",
      "id" => "template:observe:basic",
      "activity_type" => "observe",
      "template_version" => 1,
      "validation_level" => "artifact_contract",
      "required_fields" => ["id", "type", "target_id", "starts_at_s", "ends_at_s"],
      "optional_fields" => [
        "payload_id",
        "instrument_id",
        "allow_overlap",
        "setup_duration_s",
        "cooldown_duration_s",
        "telemetry_confirmation_required",
        "telemetry_confirmation_status"
      ],
      "field_count" => 12,
      "required_field_count" => 5,
      "optional_field_count" => 7,
      "default_fields" => %{"type" => "observe", "allow_overlap" => false},
      "lifecycle_defaults" => %{
        "status" => "planned",
        "approval_status" => "not_evaluated",
        "locked" => false,
        "allow_overlap" => false
      },
      "operational_hints" => %{
        "setup_duration_s" => 120.0,
        "cooldown_duration_s" => 60.0,
        "telemetry_confirmation_required" => true,
        "telemetry_confirmation_status" => "required"
      },
      "subsystem_state_hints" => %{
        "required_states" => [
          %{
            "subsystem" => "payload",
            "state" => "ready",
            "reason" => "payload must be ready before observation",
            "blocking" => true
          }
        ],
        "produced_states" => [
          %{
            "subsystem" => "payload",
            "state" => "observation_collected",
            "reason" => "observation activity produces collection evidence"
          }
        ]
      },
      "resource_hints" => %{
        "requires_payload" => true,
        "uses_storage" => true,
        "suppressed_activity_types" => ["downlink"],
        "estimated_data_volume_mb" => 48.0
      },
      "precondition_hints" => [
        %{
          "precondition_type" => "payload_unavailable",
          "status" => "review_required",
          "reason" => "payload availability must be checked",
          "blocking" => true
        }
      ],
      "assumptions" => %{"boundary" => "template_only_no_schedule_mutation"},
      "known_limits" => ["template_only_no_schedule_mutation", "no_resource_reservation"]
    }

    assert {:ok, %{"schema_contract" => "activity_template.v1", "status" => "pass"}} =
             Schema.validate_artifact(template)

    invalid_id = %{template | "id" => "bad id"}
    assert {:error, report} = Schema.validate_artifact(invalid_id)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.id"))

    unsupported_type = %{template | "activity_type" => "payload_warmup"}
    assert {:error, report} = Schema.validate_artifact(unsupported_type)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.activity_type"))

    stale_field_count = %{template | "field_count" => 7}
    assert {:error, report} = Schema.validate_artifact(stale_field_count)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.field_count"))

    malformed_fields = %{template | "required_fields" => ["id", 42]}
    assert {:error, report} = Schema.validate_artifact(malformed_fields)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.required_fields[1]"))

    undeclared_default = %{template | "default_fields" => %{"undeclared" => true}}
    assert {:error, report} = Schema.validate_artifact(undeclared_default)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.default_fields.undeclared"))

    invalid_display_name = Map.put(template, "display_name", 123)
    assert {:error, report} = Schema.validate_artifact(invalid_display_name)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.display_name"))

    invalid_assumptions = %{template | "assumptions" => "not-map"}
    assert {:error, report} = Schema.validate_artifact(invalid_assumptions)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.assumptions"))

    null_default_fields = %{template | "default_fields" => nil}
    assert {:error, report} = Schema.validate_artifact(null_default_fields)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.default_fields"))

    null_resource_hints = %{template | "resource_hints" => nil}
    assert {:error, report} = Schema.validate_artifact(null_resource_hints)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.resource_hints"))

    null_field_count = %{template | "field_count" => nil}
    assert {:error, report} = Schema.validate_artifact(null_field_count)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.field_count"))

    null_lifecycle_status = put_in(template, ["lifecycle_defaults", "status"], nil)
    assert {:error, report} = Schema.validate_artifact(null_lifecycle_status)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.lifecycle_defaults.status"))

    negative_setup_duration = put_in(template, ["operational_hints", "setup_duration_s"], -1.0)
    assert {:error, report} = Schema.validate_artifact(negative_setup_duration)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.operational_hints.setup_duration_s"))

    malformed_confirmation_required =
      put_in(template, ["operational_hints", "telemetry_confirmation_required"], "yes")

    assert {:error, report} = Schema.validate_artifact(malformed_confirmation_required)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.operational_hints.telemetry_confirmation_required")
           )

    invalid_subsystem_state_hints = put_in(template, ["subsystem_state_hints"], "not-map")
    assert {:error, report} = Schema.validate_artifact(invalid_subsystem_state_hints)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.subsystem_state_hints"))

    invalid_required_states =
      put_in(template, ["subsystem_state_hints", "required_states"], "not-list")

    assert {:error, report} = Schema.validate_artifact(invalid_required_states)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.subsystem_state_hints.required_states")
           )

    invalid_state_hint =
      put_in(template, ["subsystem_state_hints", "required_states", Access.at(0)], %{
        "subsystem" => "payload"
      })

    assert {:error, report} = Schema.validate_artifact(invalid_state_hint)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.subsystem_state_hints.required_states[0].state")
           )

    invalid_blocking =
      put_in(
        template,
        ["subsystem_state_hints", "required_states", Access.at(0), "blocking"],
        "yes"
      )

    assert {:error, report} = Schema.validate_artifact(invalid_blocking)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.subsystem_state_hints.required_states[0].blocking")
           )

    invalid_precondition = %{
      template
      | "precondition_hints" => [
          %{"precondition_type" => "payload_ready", "status" => "review_required"}
        ]
    }

    assert {:error, report} = Schema.validate_artifact(invalid_precondition)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.precondition_hints[0].precondition_type")
           )

    null_precondition_status =
      put_in(template, ["precondition_hints", Access.at(0), "status"], nil)

    assert {:error, report} = Schema.validate_artifact(null_precondition_status)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.precondition_hints[0].status")
           )
  end

  test "validates the capability catalog artifact contract" do
    artifact = OrbitalDynamics.capability_catalog_artifact()

    assert {:ok, %{"schema_contract" => "capability_catalog.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    invalid =
      put_in(
        artifact,
        ["validation", "schema", "artifact_contract_count"],
        artifact["validation"]["schema"]["artifact_contract_count"] + 1
      )

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.validation.schema.artifact_contract_count" and
                 &1["message"] =~ "must equal")
           )
  end

  test "validates subsystem model capability contract and checked-in fixture" do
    capability = OrbitalDynamics.battery_energy_storage_model()
    storage_capability = OrbitalDynamics.data_storage_buffer_model()

    assert [^capability, ^storage_capability] = OrbitalDynamics.subsystem_model_capabilities()
    assert :ok = OrbitalDynamics.validate_subsystem_model_capability(capability)
    assert :ok = OrbitalDynamics.validate_subsystem_model_capability(storage_capability)

    assert {:ok, %{"schema_contract" => "subsystem_model_capability.v1", "status" => "pass"}} =
             Schema.validate_artifact(capability)

    assert {:ok, %{"schema_contract" => "subsystem_model_capability.v1", "status" => "pass"}} =
             Schema.validate_artifact(storage_capability)

    battery_fixture = read_json!("study_results/subsystem_model_capability_v1.json")
    storage_fixture = read_json!("study_results/subsystem_model_capability_storage_v1.json")

    assert battery_fixture == capability
    assert storage_fixture == storage_capability

    stale_limits = Map.put(capability, "known_limits", ["different"])

    assert {:error, report} =
             Schema.validate_artifact(stale_limits,
               schema_contract: "subsystem_model_capability.v1"
             )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.known_limits" and
                 &1["message"] == "must match SubsystemModel.capabilities known limits")
           )

    Enum.each(
      [
        {"id", "bad id with spaces"},
        {"subsystem", 1},
        {"model", 1},
        {"source", 1},
        {"fidelity_tier", 1}
      ],
      fn {field, value} ->
        invalid = Map.put(capability, field, value)

        assert {:error, {:invalid_field, ^field}} =
                 OrbitalDynamics.validate_subsystem_model_capability(invalid)

        assert {:error, invalid_report} =
                 Schema.validate_artifact(invalid,
                   schema_contract: "subsystem_model_capability.v1"
                 )

        assert Enum.any?(invalid_report["errors"], &(&1["path"] == "$.#{field}"))
      end
    )
  end

  defp campaign_artifact do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          %{
            scenario_id: :leo_1,
            event_type: :ground_station_access,
            events: [
              %{
                type: :ground_station_access,
                starts_at: Epoch.new!(100.0, :tdb),
                ends_at: Epoch.new!(160.0, :tdb),
                metadata: %{
                  max_elevation_deg: 45.0,
                  minimum_elevation_deg: 5.0
                }
              }
            ],
            source: %{ground_station_id: :equator_prime}
          }
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    CampaignPlanner.build(result_set,
      generated_at: ~U[2026-05-14 00:00:00Z],
      campaign: %{
        "planning_horizon" => %{"duration_s" => 600.0},
        "constraints" => %{},
        "scoring_policy" => %{"downlink_rate_mb_s" => 2.0}
      }
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
