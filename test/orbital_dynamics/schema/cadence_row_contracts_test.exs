defmodule OrbitalDynamics.Schema.CadenceRowContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, Epoch, ResultSet, Schema}

  test "validates standalone Cadence-facing row contracts" do
    artifact = campaign_artifact()
    proposed_contact = List.first(artifact["proposed_contacts"])
    contact_intent = List.first(artifact["contact_intents"])

    resource_summary = %{
      "schema_contract" => "resource_summary.v1",
      "spacecraft_id" => "leo_1",
      "mode" => "payload_safe",
      "fuel_margin" => 0.72,
      "power_margin" => 0.51,
      "battery_capacity_wh" => 1200.0,
      "battery_energy_used_wh" => 588.0,
      "battery_state_of_charge" => 0.51,
      "thermal_margin_c" => 8.5,
      "storage_capacity_mb" => 1000.0,
      "storage_used_mb" => 250.0,
      "storage_margin" => 0.75,
      "downlink_capacity_mb" => 500.0,
      "downlink_margin" => 0.6,
      "spacecraft_available" => true,
      "source_quality" => "operator_supplied",
      "trust_boundary" => "operator_declared_resource_summary",
      "suppressed_activity_types" => ["observe"],
      "incompatible_activity_types" => ["command"],
      "payload_available" => true,
      "antenna_available" => true,
      "degraded" => false,
      "assumptions" => %{"model" => "operator_summary"},
      "provenance" => %{"source" => "cadence_snapshot"}
    }

    planned_activity = %{
      "id" => "cmd_1",
      "type" => "command",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "command",
      "starts_at_s" => 300.0,
      "ends_at_s" => 360.0,
      "spacecraft_id" => "leo_1",
      "resource_id" => "leo_1",
      "resource_source_quality" => "declared",
      "resource_trust_boundary" => "operator_supplied_resource_summary",
      "resource_trust_boundary_status" => "declared",
      "resource_provenance" => %{
        "source" => "mission_database",
        "trust_boundary" => "operator_supplied_resource_summary"
      },
      "resource_blocking_dimension" => "power",
      "fuel_margin" => 0.71,
      "power_margin" => 0.44,
      "storage_margin" => 0.28,
      "downlink_margin" => 0.32,
      "spacecraft_available" => true,
      "payload_available" => true,
      "degraded" => false,
      "mode" => "payload_safe",
      "product_ids" => ["cmd_packet:repoint"],
      "data_volume_mb" => 18.5,
      "downlink_rate_mb_s" => 1.0,
      "thermal_margin_c" => 8.5,
      "dependency_activity_ids" => ["health_check:leo_1"],
      "exclusive_with_timeline_ids" => ["timeline:leo_1:payload:target_a"],
      "suppressed_activity_types" => ["observe"],
      "cadence_import" => %{
        "external_id" => "cadence_cmd_1",
        "activity_type" => "command",
        "schema_contract" => "planned_activity.v1"
      }
    }

    assert {:ok, %{"schema_contract" => "proposed_contact.v1"}} =
             Schema.validate_artifact(proposed_contact)

    fixture_proposed_contact = read_json!("study_results/proposed_contact_v1.json")

    assert {:ok, %{"schema_contract" => "proposed_contact.v1"}} =
             Schema.validate_artifact(fixture_proposed_contact)

    assert {:ok, proposed_contact_schema} = Schema.json_schema("proposed_contact.v1")

    assert get_in(proposed_contact_schema, ["properties", "source_window_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(proposed_contact_schema, ["properties", "timeline_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(proposed_contact_schema, [
             "properties",
             "timeline_identity",
             "properties",
             "timeline_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(proposed_contact_schema, ["properties", "station_availability", "type"]) ==
             "string"

    assert get_in(proposed_contact_schema, ["properties", "schedule_conflict_status", "type"]) ==
             "string"

    assert get_in(proposed_contact_schema, ["properties", "model_limits", "items", "enum"]) == [
             "artifact_level_only",
             "no_provider_reservation",
             "no_schedule_mutation"
           ]

    invalid_proposed_contact_timeline =
      Map.put(fixture_proposed_contact, "timeline_id", "timeline id with spaces")

    assert {:error, invalid_proposed_timeline_report} =
             Schema.validate_artifact(invalid_proposed_contact_timeline)

    assert Enum.any?(
             invalid_proposed_timeline_report["errors"],
             &(&1["path"] == "$.timeline_id")
           )

    invalid_proposed_contact_limits =
      Map.put(fixture_proposed_contact, "model_limits", ["artifact_level_only"])

    assert {:error, invalid_proposed_limits_report} =
             Schema.validate_artifact(invalid_proposed_contact_limits)

    assert Enum.any?(
             invalid_proposed_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(contact_intent)

    assert {:ok, %{"schema_contract" => "resource_summary.v1"}} =
             Schema.validate_artifact(resource_summary)

    assert {:ok, resource_summary_schema} = Schema.json_schema("resource_summary.v1")

    assert get_in(resource_summary_schema, [
             "properties",
             "suppressed_activity_types",
             "items",
             "type"
           ]) == "string"

    assert get_in(resource_summary_schema, [
             "properties",
             "incompatible_activity_types",
             "items",
             "type"
           ]) == "string"

    invalid_resource_soc = Map.put(resource_summary, "battery_state_of_charge", 1.2)

    assert {:error, invalid_resource_soc_report} =
             Schema.validate_artifact(invalid_resource_soc)

    assert Enum.any?(
             invalid_resource_soc_report["errors"],
             &(&1["path"] == "$.battery_state_of_charge" and
                 &1["message"] == "must be between 0.0 and 1.0")
           )

    invalid_resource_stale_soc = Map.put(resource_summary, "battery_state_of_charge", 0.52)

    assert {:error, invalid_resource_stale_soc_report} =
             Schema.validate_artifact(invalid_resource_stale_soc)

    assert Enum.any?(
             invalid_resource_stale_soc_report["errors"],
             &(&1["path"] == "$.battery_state_of_charge" and
                 &1["message"] ==
                   "must equal battery_capacity_wh/battery_energy_used_wh-derived battery_state_of_charge")
           )

    invalid_resource_stale_storage = Map.put(resource_summary, "storage_margin", 0.7)

    assert {:error, invalid_resource_stale_storage_report} =
             Schema.validate_artifact(invalid_resource_stale_storage)

    assert Enum.any?(
             invalid_resource_stale_storage_report["errors"],
             &(&1["path"] == "$.storage_margin" and
                 &1["message"] ==
                   "must equal storage_capacity_mb/storage_used_mb-derived storage_margin")
           )

    invalid_resource_capacity = Map.put(resource_summary, "storage_capacity_mb", -1.0)

    assert {:error, invalid_resource_capacity_report} =
             Schema.validate_artifact(invalid_resource_capacity)

    assert Enum.any?(
             invalid_resource_capacity_report["errors"],
             &(&1["path"] == "$.storage_capacity_mb" and
                 &1["message"] == "must be non-negative")
           )

    invalid_resource_activity_types =
      Map.put(resource_summary, "suppressed_activity_types", ["observe", 42])

    assert {:error, invalid_resource_activity_type_report} =
             Schema.validate_artifact(invalid_resource_activity_types)

    assert Enum.any?(
             invalid_resource_activity_type_report["errors"],
             &(&1["path"] == "$.suppressed_activity_types[1]")
           )

    resource_projection_report = %{
      "schema_contract" => "resource_projection_report.v1",
      "model" => "thin_repaired_activity_resource_projection",
      "input_resource_summary_count" => 1,
      "activity_count" => 2,
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "activity_count" => 2,
          "observation_count" => 1,
          "downlink_count" => 1,
          "estimated_storage_produced_mb" => 40.0,
          "estimated_downlink_mb" => 60.0,
          "resource_source_quality" => "operator_supplied",
          "projected_storage_margin" => 0.77,
          "projected_downlink_margin" => 0.88,
          "activity_resource_flow" => [
            %{
              "activity_id" => "obs_1",
              "activity_type" => "observe",
              "planned_latency_s" => 120.0,
              "latency_status" => "within_limit"
            },
            %{
              "activity_id" => "dl_1",
              "activity_type" => "downlink",
              "planned_latency_s" => 180.0,
              "latency_status" => "within_limit"
            }
          ]
        }
      ],
      "assumptions" => %{"source" => "source_resource_summaries"}
    }

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(resource_projection_report)

    invalid_projection_latency =
      put_in(
        resource_projection_report,
        [
          "projected_resources",
          Access.at(0),
          "activity_resource_flow",
          Access.at(0),
          "planned_latency_s"
        ],
        -1.0
      )

    assert {:error, invalid_projection_latency_report} =
             Schema.validate_artifact(invalid_projection_latency)

    assert Enum.any?(
             invalid_projection_latency_report["errors"],
             &(&1["path"] ==
                 "$.projected_resources[0].activity_resource_flow[0].planned_latency_s")
           )

    invalid_projection_completed_fraction =
      put_in(
        resource_projection_report,
        [
          "projected_resources",
          Access.at(0),
          "activity_resource_flow",
          Access.at(0),
          "completed_fraction"
        ],
        1.2
      )

    assert {:error, invalid_projection_completed_fraction_report} =
             Schema.validate_artifact(invalid_projection_completed_fraction)

    assert Enum.any?(
             invalid_projection_completed_fraction_report["errors"],
             &(&1["path"] ==
                 "$.projected_resources[0].activity_resource_flow[0].completed_fraction" and
                 &1["message"] == "must be between 0.0 and 1.0")
           )

    invalid_projection_battery_state_of_charge_after =
      put_in(
        resource_projection_report,
        [
          "projected_resources",
          Access.at(0),
          "activity_resource_flow",
          Access.at(0),
          "battery_state_of_charge_after"
        ],
        1.2
      )

    assert {:error, invalid_projection_battery_soc_report} =
             Schema.validate_artifact(invalid_projection_battery_state_of_charge_after)

    assert Enum.any?(
             invalid_projection_battery_soc_report["errors"],
             &(&1["path"] ==
                 "$.projected_resources[0].activity_resource_flow[0].battery_state_of_charge_after" and
                 &1["message"] == "must be between 0.0 and 1.0")
           )

    resource_filter_report = %{
      "schema_contract" => "resource_filter_report.v1",
      "model" => "resource_summary_availability_and_margin_filter",
      "input_candidate_count" => 1,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 1,
      "resource_source_quality_counts" => %{"operator_supplied" => 1},
      "suppressed_candidates" => [
        %{
          "id" => "leo_1_observe_target_a_1",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "suppressed_reason" => "payload_unavailable"
        }
      ]
    }

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(resource_filter_report)

    station_calendar_report = %{
      "schema_contract" => "station_calendar_report.v1",
      "model" => "campaign_ground_network_interval_overlay",
      "input_contact_count" => 1,
      "calendar_entry_count" => 1,
      "affected_contact_count" => 1,
      "affected_duration_s" => 60.0,
      "affected_contacts" => [
        %{
          "id" => "station_calendar:dl_1:equator_capacity",
          "contact_id" => "dl_1",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "overlap_starts_at_s" => 100.0,
          "overlap_ends_at_s" => 160.0,
          "overlap_duration_s" => 60.0,
          "station_calendar_entry_id" => "equator_capacity",
          "status" => "available",
          "station_availability" => "reduced_capacity",
          "capacity_fraction" => 0.5
        }
      ],
      "assumptions" => %{
        "source" => "ops_calendar",
        "execution_boundary" => "artifact_only_no_provider_reservation"
      }
    }

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(station_calendar_report)

    assert {:ok, %{"schema_contract" => "planned_activity.v1"}} =
             Schema.validate_artifact(planned_activity, schema_contract: "planned_activity.v1")

    alias_planned_activity =
      planned_activity
      |> Map.delete("type")
      |> Map.put("activity_type", "command")

    assert {:ok, %{"schema_contract" => "planned_activity.v1"}} =
             Schema.validate_artifact(alias_planned_activity,
               schema_contract: "planned_activity.v1"
             )

    invalid_alias_planned_activity =
      alias_planned_activity
      |> Map.delete("activity_type")

    assert {:error, alias_report} =
             Schema.validate_artifact(invalid_alias_planned_activity,
               schema_contract: "planned_activity.v1"
             )

    assert Enum.any?(
             alias_report["errors"],
             &(&1["path"] == "$" and &1["message"] == "must include type or activity_type")
           )

    assert {:ok, planned_activity_schema} = Schema.json_schema("planned_activity.v1")

    assert planned_activity_schema["required"] == [
             "id",
             "scenario_id",
             "starts_at_s",
             "ends_at_s"
           ]

    assert planned_activity_schema["anyOf"] == [
             %{"required" => ["type"]},
             %{"required" => ["activity_type"]}
           ]

    assert get_in(planned_activity_schema, ["properties", "activity_type", "type"]) ==
             "string"

    assert get_in(planned_activity_schema, ["properties", "resource_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(planned_activity_schema, ["properties", "resource_provenance", "type"]) ==
             "object"

    assert get_in(planned_activity_schema, [
             "properties",
             "resource_trust_boundary_status",
             "type"
           ]) == "string"

    assert get_in(planned_activity_schema, ["properties", "fuel_margin", "type"]) == "number"

    assert get_in(planned_activity_schema, ["properties", "storage_margin", "maximum"]) == 1.0

    assert get_in(planned_activity_schema, ["properties", "spacecraft_available", "type"]) ==
             "boolean"

    assert get_in(planned_activity_schema, ["properties", "product_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(planned_activity_schema, [
             "properties",
             "exclusive_with_timeline_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(planned_activity_schema, [
             "properties",
             "suppressed_activity_types",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        "contact_success_factor",
        "command_success_factor",
        "observation_success_factor",
        "cloud_cover_fraction",
        "blur_score",
        "maneuver_success_factor"
      ],
      fn field ->
        assert get_in(planned_activity_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(planned_activity_schema, ["properties", "downlink_rate_mb_s", "type"]) ==
             "number"

    assert get_in(planned_activity_schema, [
             "properties",
             "command_success_factor_source",
             "type"
           ]) == "string"

    assert get_in(planned_activity_schema, [
             "properties",
             "maneuver_success_factor_source",
             "type"
           ]) == "string"

    assert get_in(planned_activity_schema, ["properties", "execution_uncertainty", "type"]) ==
             "object"

    assert get_in(planned_activity_schema, [
             "properties",
             "execution_uncertainty",
             "properties",
             "delta_v_3sigma_km_s",
             "minItems"
           ]) == 3

    checked_in_planned_activity = read_json!("study_results/planned_activity_v1.json")

    assert {:ok, %{"schema_contract" => "planned_activity.v1"}} =
             Schema.validate_artifact(checked_in_planned_activity)

    invalid_command_success =
      Map.put(checked_in_planned_activity, "command_success_factor", 1.5)

    assert {:error, command_success_report} = Schema.validate_artifact(invalid_command_success)

    assert Enum.any?(
             command_success_report["errors"],
             &(&1["path"] == "$.command_success_factor")
           )

    invalid_planned_quality =
      Map.put(checked_in_planned_activity, "cloud_cover_fraction", 1.2)

    assert {:error, planned_quality_report} = Schema.validate_artifact(invalid_planned_quality)

    assert Enum.any?(
             planned_quality_report["errors"],
             &(&1["path"] == "$.cloud_cover_fraction")
           )

    invalid_storage_margin = Map.put(checked_in_planned_activity, "storage_margin", 128.0)

    assert {:error, storage_margin_report} = Schema.validate_artifact(invalid_storage_margin)

    assert Enum.any?(
             storage_margin_report["errors"],
             &(&1["path"] == "$.storage_margin" and
                 &1["message"] == "must be between 0.0 and 1.0")
           )

    invalid_execution_uncertainty =
      Map.put(checked_in_planned_activity, "execution_uncertainty", "operator_estimate")

    assert {:error, uncertainty_report} = Schema.validate_artifact(invalid_execution_uncertainty)
    assert Enum.any?(uncertainty_report["errors"], &(&1["path"] == "$.execution_uncertainty"))

    invalid_execution_uncertainty_delta =
      Map.put(checked_in_planned_activity, "execution_uncertainty", %{
        "delta_v_3sigma_km_s" => [0.0, "uncertain", 0.0]
      })

    assert {:error, uncertainty_delta_report} =
             Schema.validate_artifact(invalid_execution_uncertainty_delta)

    assert Enum.any?(
             uncertainty_delta_report["errors"],
             &(&1["path"] == "$.execution_uncertainty.delta_v_3sigma_km_s")
           )

    invalid_planned_downlink_rate =
      Map.put(checked_in_planned_activity, "downlink_rate_mb_s", "1")

    assert {:error, planned_rate_report} =
             Schema.validate_artifact(invalid_planned_downlink_rate)

    assert Enum.any?(planned_rate_report["errors"], &(&1["path"] == "$.downlink_rate_mb_s"))

    invalid_intent = Map.put(contact_intent, "direction", "broadcast")

    assert {:error, report} = Schema.validate_artifact(invalid_intent)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.direction"))

    invalid_intent_import =
      Map.put(contact_intent, "cadence_import", %{"activity_type" => "contact"})

    assert {:error, import_report} = Schema.validate_artifact(invalid_intent_import)
    assert Enum.any?(import_report["errors"], &(&1["path"] == "$.cadence_import.external_id"))
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
