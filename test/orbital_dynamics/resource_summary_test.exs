defmodule OrbitalDynamics.ResourceSummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.ResourceSummary

  test "declares resource summary capabilities" do
    assert %{
             product: :resource_summary,
             validation_level: :assumption_declared,
             units: %{
               margins: :unit_interval,
               storage_capacity_mb: :megabytes,
               battery_capacity_wh: :watt_hours,
               thermal_margin_c: :celsius
             },
             known_limits: known_limits,
             resource_availability_aliases: resource_availability_aliases,
             resource_degraded_aliases: resource_degraded_aliases,
             resource_margin_aliases: resource_margin_aliases,
             resource_unit_interval_aliases: resource_unit_interval_aliases,
             battery_energy_generated_aliases: battery_energy_generated_aliases,
             resource_availability_true_tokens: resource_availability_true_tokens,
             resource_availability_false_tokens: resource_availability_false_tokens,
             resource_activity_type_aliases: resource_activity_type_aliases,
             roll_forward_flow_statuses: roll_forward_flow_statuses,
             roll_forward_pressure_statuses: roll_forward_pressure_statuses,
             roll_forward_pressure_types: roll_forward_pressure_types,
             roll_forward_resource_effect_statuses: roll_forward_resource_effect_statuses,
             roll_forward_ignored_effect_reason_families:
               roll_forward_ignored_effect_reason_families,
             roll_forward_helpers: roll_forward_helpers,
             roll_forward_contract: roll_forward_contract,
             public_facades: public_facades,
             spacecraft_stable_identity_fields: spacecraft_stable_identity_fields,
             row_semantics: row_semantics
           } = ResourceSummary.capabilities()

    assert :no_subsystem_simulation in known_limits
    assert :battery_state_of_charge_is_externally_supplied_or_derived_summary in known_limits
    assert :source_quality_is_declared_or_inferred_from_provenance in known_limits
    assert "resource_source_quality" in ResourceSummary.capabilities().source_quality_aliases

    assert "provenance.resource_source_quality" in ResourceSummary.capabilities().source_quality_aliases

    assert "resource_trust_boundary" in ResourceSummary.capabilities().trust_boundary_aliases

    assert "provenance.resource_trust_boundary" in ResourceSummary.capabilities().trust_boundary_aliases

    assert "suppressed_activity_types" in ResourceSummary.capabilities().activity_type_list_fields

    assert "incompatible_activity_types" in ResourceSummary.capabilities().activity_type_list_fields

    assert spacecraft_stable_identity_fields == [
             "spacecraft_id",
             "satellite_id",
             "spacecraft.spacecraft_id",
             "spacecraft.satellite_id",
             "spacecraft.id",
             "satellite.spacecraft_id",
             "satellite.satellite_id",
             "satellite.id"
           ]

    assert :spacecraft_stable_identity_fields in row_semantics
    assert :resource_source_quality_aliases in row_semantics
    assert :resource_trust_boundary_aliases in row_semantics
    assert :resource_activity_type_list_fields in row_semantics
    assert :resource_availability_aliases in row_semantics
    assert :resource_availability_status_tokens in row_semantics
    assert :resource_degraded_aliases in row_semantics
    assert :resource_margin_aliases in row_semantics
    assert :resource_unit_interval_aliases in row_semantics
    assert :battery_energy_generated_aliases in row_semantics
    assert :resource_activity_type_aliases in row_semantics
    assert :selected_activity_resource_roll_forward in row_semantics
    assert :resource_summary_roll_forward_flow_status_values in row_semantics
    assert :resource_summary_roll_forward_pressure_status_values in row_semantics
    assert :resource_summary_roll_forward_pressure_type_values in row_semantics
    assert :resource_summary_roll_forward_pressure_direction_and_capacity_maps in row_semantics
    assert :resource_summary_roll_forward_resource_effect_status_values in row_semantics
    assert :resource_summary_roll_forward_ignored_effect_reason_families in row_semantics
    assert :thin_selected_activity_roll_forward_contract in row_semantics
    assert roll_forward_helpers == [:roll_forward]

    assert roll_forward_flow_statuses == ["clear", "review_required"]
    assert roll_forward_pressure_statuses == ["clear", "review_required"]

    assert roll_forward_pressure_types == [
             "activity_type_incompatible_with_resource_summary",
             "activity_type_suppressed_by_resource_summary",
             "antenna_unavailable",
             "battery_depletion",
             "downlink_shortfall",
             "payload_unavailable",
             "spacecraft_degraded_payload_unavailable",
             "spacecraft_unavailable",
             "storage_overflow",
             "thermal_margin_below_limit"
           ]

    assert roll_forward_resource_effect_statuses == ["projected", "ignored"]

    assert roll_forward_ignored_effect_reason_families == [
             "activity_status_*",
             "approval_status_rejected",
             "contact_allocation_*",
             "activity_type_suppressed_by_resource_summary",
             "activity_type_incompatible_with_resource_summary",
             "spacecraft_unavailable",
             "payload_unavailable",
             "spacecraft_degraded_payload_unavailable",
             "antenna_unavailable"
           ]

    assert roll_forward_contract == %{
             input_contracts: ["resource_summary.v1", "selected_activity_rows"],
             output_contract: "resource_projection_flow_summary.v1",
             validation_level: :schema_validated_artifact,
             boundary: :thin_selected_activity_projection,
             model: :resource_projection_flow_report,
             execution_boundary: :artifact_only_no_schedule_mutation
           }

    assert public_facades == [:resource_summary_roll_forward]

    assert resource_availability_aliases == %{
             "payload_available" => ["payload_available?", "payload_status"],
             "antenna_available" => ["antenna_available?", "antenna_status"],
             "spacecraft_available" => [
               "spacecraft_available?",
               "spacecraft_availability",
               "spacecraft_status"
             ]
           }

    assert resource_degraded_aliases == ["degraded?"]

    assert resource_margin_aliases == %{
             "storage_margin" => ["storage_capacity_margin"],
             "downlink_margin" => ["downlink_capacity_margin"]
           }

    assert resource_unit_interval_aliases == %{
             "battery_state_of_charge" => ["battery_soc"]
           }

    assert battery_energy_generated_aliases == [
             "energy_generated_wh",
             "estimated_energy_generated_wh",
             "estimated_battery_energy_generated_wh",
             "planned_energy_generated_wh"
           ]

    assert "enabled" in resource_availability_true_tokens
    assert "operational" in resource_availability_true_tokens
    assert "outage" in resource_availability_false_tokens
    assert "maintenance" in resource_availability_false_tokens
    assert resource_activity_type_aliases["sband_command"] == "command"
    assert resource_activity_type_aliases["downlinking"] == "downlink"
    assert resource_activity_type_aliases["tracking_pass"] == "tracking"
  end

  test "normalizes planning resource summaries and derives storage margin" do
    summary =
      ResourceSummary.from_map!(%{
        spacecraft_id: "leo_1",
        mode: "nominal",
        fuel_margin: 0.8,
        power_margin: 0.7,
        storage_capacity_mb: 1000.0,
        storage_used_mb: 250.0,
        downlink_margin: 0.6,
        payload_available: true,
        antenna_available: false,
        assumptions: %{model: "operator_summary"},
        provenance: %{source: "ops", trust_boundary: "operator_declared_resource_summary"}
      })

    assert summary.storage_margin == 0.75

    assert %{
             "schema_contract" => "resource_summary.v1",
             "spacecraft_id" => "leo_1",
             "storage_margin" => 0.75,
             "source_quality" => "operator_supplied",
             "trust_boundary" => "operator_declared_resource_summary",
             "antenna_available" => false
           } = ResourceSummary.to_map(summary)
  end

  test "normalizes nested spacecraft identity" do
    summary =
      ResourceSummary.from_map!(%{
        spacecraft: %{id: :leo_1},
        storage_capacity_mb: 1000.0,
        storage_used_mb: 250.0
      })

    assert %ResourceSummary{spacecraft_id: "leo_1", storage_margin: 0.75} = summary
    assert %{"spacecraft_id" => "leo_1"} = ResourceSummary.to_map(summary)
  end

  test "normalizes stable spacecraft identities before serialization" do
    assert %{"spacecraft_id" => "leo_1"} =
             %{spacecraft_id: :leo_1}
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert %{"spacecraft_id" => "42"} =
             %{satellite_id: 42}
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert {:ok, %{"schema_contract" => "resource_summary.v1"}} =
             %{spacecraft_id: :leo_1}
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()
             |> OrbitalDynamics.Schema.validate_artifact()

    assert %{"spacecraft_id" => "leo_2"} =
             %ResourceSummary{spacecraft_id: :leo_2}
             |> ResourceSummary.to_map()
  end

  test "rejects unstable spacecraft identities before artifact serialization" do
    assert_raise ArgumentError, ~r/spacecraft_id must be a stable ID/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "bad spacecraft id"})
    end

    assert_raise ArgumentError, ~r/spacecraft_id must be a stable ID/, fn ->
      ResourceSummary.from_map!(%{spacecraft: %{id: :"bad spacecraft id"}})
    end

    assert_raise ArgumentError, ~r/spacecraft_id must be a stable ID/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "nil"})
    end

    assert_raise ArgumentError, ~r/spacecraft_id must be a stable ID/, fn ->
      ResourceSummary.to_map(%ResourceSummary{spacecraft_id: "bad spacecraft id"})
    end
  end

  test "normalizes numeric string resource quantities and margins" do
    summary =
      ResourceSummary.from_map!(%{
        spacecraft_id: "leo_1",
        fuel_margin: "0.80",
        thermal_margin_c: "-2.5",
        battery_capacity_wh: "1200.0",
        battery_energy_used_wh: "300.0",
        estimated_battery_energy_generated_wh: "45.0",
        battery_soc: "0.75",
        storage_capacity_mb: "1000.0",
        storage_used_mb: "250.0",
        storage_capacity_margin: "0.75",
        downlink_capacity_mb: "500.0",
        downlink_capacity_margin: "0.60"
      })

    summary_map = ResourceSummary.to_map(summary)

    assert %{
             "fuel_margin" => 0.8,
             "thermal_margin_c" => -2.5,
             "power_margin" => 0.75,
             "battery_capacity_wh" => 1200.0,
             "battery_energy_used_wh" => 300.0,
             "battery_energy_generated_wh" => 45.0,
             "battery_state_of_charge" => 0.75,
             "storage_capacity_mb" => 1000.0,
             "storage_used_mb" => 250.0,
             "storage_margin" => 0.75,
             "downlink_capacity_mb" => 500.0,
             "downlink_margin" => 0.6
           } = summary_map

    assert {:ok, %{"schema_contract" => "resource_summary.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(summary_map)

    invalid_generated = Map.put(summary_map, "battery_energy_generated_wh", -1.0)

    assert {:error, invalid_generated_report} =
             OrbitalDynamics.Schema.validate_artifact(invalid_generated)

    assert Enum.any?(
             invalid_generated_report["errors"],
             &(&1["path"] == "$.battery_energy_generated_wh")
           )
  end

  test "accepts struct-style boolean availability aliases in map inputs" do
    assert %{
             "payload_available" => false,
             "antenna_available" => false,
             "spacecraft_available" => false,
             "degraded" => true
           } =
             %{
               spacecraft_id: "leo_1",
               payload_available?: false,
               antenna_available?: false,
               spacecraft_available?: false,
               degraded?: true
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert %{"payload_available" => true} =
             %{
               spacecraft_id: "leo_1",
               payload_available: true,
               payload_available?: false
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert %{"spacecraft_available" => false} =
             %{
               spacecraft_id: "leo_1",
               spacecraft_availability: false
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()
  end

  test "normalizes JSON-style boolean availability values in map inputs" do
    assert %{
             "payload_available" => false,
             "antenna_available" => true,
             "spacecraft_available" => false,
             "degraded" => true
           } =
             %{
               spacecraft_id: "leo_1",
               payload_available: "false",
               antenna_available: "true",
               spacecraft_availability: "false",
               degraded: "true"
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert_raise ArgumentError, ~r/payload_available must be a boolean/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "leo_1", payload_available: "unknown"})
    end
  end

  test "normalizes operational status-word availability values in map inputs" do
    assert %{
             "payload_available" => false,
             "antenna_available" => true,
             "spacecraft_available" => false,
             "degraded" => false
           } =
             %{
               spacecraft_id: "leo_1",
               payload_status: "unavailable",
               antenna_status: "enabled",
               spacecraft_status: "offline",
               degraded: "no"
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert %{
             "payload_available" => false,
             "antenna_available" => false,
             "spacecraft_available" => false
           } =
             %{
               spacecraft_id: "leo_2",
               payload_status: "down",
               antenna_status: "outage",
               spacecraft_status: "maintenance"
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()
  end

  test "accepts downlink capacity margin alias in map inputs" do
    assert %{"downlink_margin" => 0.4} =
             %{
               spacecraft_id: "leo_1",
               downlink_capacity_margin: 0.4
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert %{"downlink_margin" => 0.7} =
             %{
               spacecraft_id: "leo_1",
               downlink_margin: 0.7,
               downlink_capacity_margin: 0.4
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()
  end

  test "normalizes explicit activity-type suppression declarations" do
    assert %{
             "suppressed_activity_types" => ["observe", "command", "tracking"],
             "incompatible_activity_types" => ["command", "health_check", "downlink"]
           } =
             %{
               spacecraft_id: "leo_1",
               suppressed_activity_types: [
                 :observe,
                 %{direction: "s-band command"},
                 "observe",
                 "tracking-pass"
               ],
               incompatible_activity_types: "commands, health-check, downlinking"
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    refute Map.has_key?(
             %{spacecraft_id: "leo_1"}
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map(),
             "suppressed_activity_types"
           )

    assert {:ok, %{"schema_contract" => "resource_summary.v1"}} =
             %{
               spacecraft_id: "leo_1",
               suppressed_activity_types: [:observe],
               incompatible_activity_types: [%{activity_type: "downlink"}]
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()
             |> OrbitalDynamics.Schema.validate_artifact()
  end

  test "rejects malformed activity-type suppression declarations" do
    assert_raise ArgumentError, ~r/suppressed_activity_types entries must be non-empty/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "leo_1", suppressed_activity_types: ""})
    end

    assert_raise ArgumentError, ~r/incompatible_activity_types map entries require/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "leo_1", incompatible_activity_types: [%{}]})
    end

    assert_raise ArgumentError, ~r/suppressed_activity_types entries must be strings/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "leo_1", suppressed_activity_types: [42]})
    end
  end

  test "preserves battery summary fields and derives power margin when absent" do
    assert %{
             "battery_capacity_wh" => 1200.0,
             "battery_energy_used_wh" => 300.0,
             "battery_state_of_charge" => 0.75,
             "power_margin" => 0.75
           } =
             %{
               spacecraft_id: "leo_1",
               battery_capacity_wh: 1200.0,
               battery_energy_used_wh: 300.0
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert %{
             "battery_state_of_charge" => 0.6,
             "power_margin" => 0.4
           } =
             %{
               spacecraft_id: "leo_1",
               power_margin: 0.4,
               battery_state_of_charge: 0.6
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert %{
             "battery_state_of_charge" => 0.6,
             "power_margin" => 0.6
           } =
             %{
               spacecraft_id: "leo_1",
               battery_soc: 0.6
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()
  end

  test "rejects impossible battery state of charge values" do
    assert_raise ArgumentError, ~r/battery_state_of_charge must be between 0 and 1/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "leo_1", battery_state_of_charge: 1.2})
    end
  end

  test "rejects stale derived storage and battery margin values" do
    assert_raise ArgumentError,
                 ~r/battery_state_of_charge must match capacity and used values/,
                 fn ->
                   ResourceSummary.from_map!(%{
                     spacecraft_id: "leo_1",
                     battery_capacity_wh: 1200.0,
                     battery_energy_used_wh: 300.0,
                     battery_state_of_charge: 0.5
                   })
                 end

    assert_raise ArgumentError,
                 ~r/battery_state_of_charge must match capacity and used values/,
                 fn ->
                   ResourceSummary.from_map!(%{
                     spacecraft_id: "leo_1",
                     battery_capacity_wh: 1200.0,
                     battery_energy_used_wh: 300.0,
                     battery_soc: 0.5
                   })
                 end

    assert_raise ArgumentError, ~r/storage_margin must match capacity and used values/, fn ->
      ResourceSummary.from_map!(%{
        spacecraft_id: "leo_1",
        storage_capacity_mb: 1000.0,
        storage_used_mb: 250.0,
        storage_margin: 0.5
      })
    end

    assert_raise ArgumentError, ~r/storage_margin must match capacity and used values/, fn ->
      ResourceSummary.from_map!(%{
        spacecraft_id: "leo_1",
        storage_capacity_mb: 1000.0,
        storage_used_mb: 250.0,
        storage_capacity_margin: 0.5
      })
    end
  end

  test "rejects negative resource capacity and used values" do
    for field <- [
          :battery_capacity_wh,
          :battery_energy_used_wh,
          :battery_energy_generated_wh,
          :storage_capacity_mb,
          :storage_used_mb,
          :downlink_capacity_mb
        ] do
      assert_raise ArgumentError, ~r/#{field} must be non-negative/, fn ->
        ResourceSummary.from_map!(%{field => -1.0, spacecraft_id: "leo_1"})
      end
    end
  end

  test "public facades normalize planning resource summaries" do
    source = %{
      spacecraft_id: "leo_1",
      storage_capacity_mb: 1000.0,
      storage_used_mb: 250.0,
      provenance: %{source: "ops"}
    }

    summary = OrbitalDynamics.resource_summary_from_map!(source)

    assert summary == ResourceSummary.from_map!(source)
    assert OrbitalDynamics.resource_summary_to_map(summary) == ResourceSummary.to_map(summary)

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "storage_margin" => 0.75,
               "source_quality" => "operator_supplied"
             }
           ] = OrbitalDynamics.resource_summaries_to_maps([source])
  end

  test "preserves top-level resource trust boundary" do
    assert %{
             "trust_boundary" => "simulated_resource_fixture",
             "provenance" => %{"source" => "simulation"}
           } =
             %{
               spacecraft_id: "leo_1",
               trust_boundary: "simulated_resource_fixture",
               provenance: %{source: "simulation"}
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert_raise ArgumentError, ~r/trust_boundary must be a non-empty string/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "leo_1", trust_boundary: :operator})
    end
  end

  test "accepts flattened resource provenance aliases from handoff rows" do
    assert %{
             "source_quality" => "branch_generated",
             "trust_boundary" => "branch_resource_projection"
           } =
             %{
               spacecraft_id: "leo_1",
               resource_source_quality: "branch_generated",
               resource_trust_boundary: "branch_resource_projection"
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert %{
             "source_quality" => "projection_model",
             "trust_boundary" => "resource_projection"
           } =
             %{
               spacecraft_id: "leo_1",
               provenance: %{
                 resource_source_quality: "projection_model",
                 resource_trust_boundary: "resource_projection"
               }
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert %{
             "source_quality" => "canonical",
             "trust_boundary" => "canonical_boundary"
           } =
             %{
               spacecraft_id: "leo_1",
               source_quality: "canonical",
               trust_boundary: "canonical_boundary",
               resource_source_quality: "resource_alias",
               resource_trust_boundary: "resource_alias_boundary"
             }
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()
  end

  test "accepts explicit source quality and rejects malformed values" do
    assert %{"source_quality" => "stale_snapshot"} =
             %{spacecraft_id: "leo_1", source_quality: "stale_snapshot"}
             |> ResourceSummary.from_map!()
             |> ResourceSummary.to_map()

    assert_raise ArgumentError, ~r/source_quality must be a string/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "leo_1", source_quality: :operator})
    end
  end

  test "rejects impossible margin values" do
    assert_raise ArgumentError, ~r/fuel_margin must be between 0 and 1/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "leo_1", fuel_margin: 2.0})
    end

    assert_raise ArgumentError, ~r/thermal_margin_c must be numeric/, fn ->
      ResourceSummary.from_map!(%{spacecraft_id: "leo_1", thermal_margin_c: :hot})
    end
  end

  test "rolls one resource summary forward across selected activities" do
    summary = %{
      spacecraft_id: :leo_1,
      storage_capacity_mb: 100.0,
      storage_used_mb: 40.0,
      downlink_capacity_mb: 25.0,
      assumptions: %{model: "operator_summary"},
      provenance: %{source: "ops"}
    }

    selected_activities = [
      %{
        id: :obs_collect,
        type: :observe,
        spacecraft_id: :leo_1,
        starts_at_s: 10.0,
        estimated_storage_mb: 50.0
      },
      %{
        id: :dl_contact,
        type: :downlink,
        spacecraft_id: :leo_1,
        starts_at_s: 20.0,
        estimated_throughput_mb: 30.0
      }
    ]

    assert %{
             "schema_contract" => "resource_projection_flow_summary.v1",
             "model" => "artifact_only_selected_activity_resource_flow_summary",
             "source" => "resource_summary_roll_forward_test",
             "activity_count" => 2,
             "valid_activity_count" => 2,
             "input_resource_summary_count" => 1,
             "valid_resource_summary_count" => 1,
             "resource_flow_status" => "review_required",
             "resource_pressure_types" => ["downlink_shortfall"],
             "resource_pressure_spacecraft_ids_by_type" => %{
               "downlink_shortfall" => ["leo_1"]
             },
             "resource_pressure_activity_ids_by_type" => %{
               "downlink_shortfall" => ["dl_contact"]
             },
             "total_storage_produced_mb" => 50.0,
             "total_planned_downlink_mb" => 30.0,
             "total_storage_limited_downlinked_mb" => 30.0,
             "total_downlink_shortfall_mb" => 5.0,
             "total_projected_storage_remaining_mb" => 40.0,
             "total_projected_downlink_remaining_mb" => +0.0,
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "starting_storage_used_mb" => 40.0,
                 "projected_storage_used_mb" => 60.0,
                 "projected_storage_remaining_mb" => 40.0,
                 "projected_downlink_shortfall_mb" => 5.0
               }
             ],
             "activity_resource_flow" => [
               %{
                 "activity_id" => "obs_collect",
                 "storage_used_before_mb" => 40.0,
                 "storage_used_after_mb" => 90.0
               },
               %{
                 "activity_id" => "dl_contact",
                 "storage_used_before_mb" => 90.0,
                 "storage_used_after_mb" => 60.0,
                 "downlink_shortfall_mb" => 5.0
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "projection_model" => "thin_time_ordered_resource_roll_forward",
               "subsystem_simulation" => "not_performed"
             }
           } =
             report =
             ResourceSummary.roll_forward(summary, selected_activities,
               source: "resource_summary_roll_forward_test"
             )

    assert OrbitalDynamics.resource_summary_roll_forward(
             ResourceSummary.from_map!(summary),
             selected_activities,
             source: "resource_summary_roll_forward_test"
           ) == report

    assert report["resource_flow_status"] in ResourceSummary.capabilities().roll_forward_flow_statuses

    assert report["resource_pressure_status"] in ResourceSummary.capabilities().roll_forward_pressure_statuses

    assert report["resource_pressure_types"] --
             ResourceSummary.capabilities().roll_forward_pressure_types ==
             []

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)

    assert_raise ArgumentError,
                 ~r/resource summary must be a map or ResourceSummary struct/,
                 fn ->
                   ResourceSummary.roll_forward(:bad_summary, selected_activities)
                 end

    assert_raise ArgumentError, ~r/selected activities must be a list/, fn ->
      ResourceSummary.roll_forward(summary, :bad_activities)
    end
  end

  test "validates flow summary resource-pressure routing maps against rows" do
    summary = %{
      spacecraft_id: :leo_1,
      storage_capacity_mb: 100.0,
      storage_used_mb: 80.0,
      downlink_capacity_mb: 10.0
    }

    selected_activities = [
      %{
        id: :dl_contact,
        type: :downlink,
        spacecraft_id: :leo_1,
        starts_at_s: 10.0,
        estimated_throughput_mb: 25.0,
        ground_station_id: :equator_prime,
        source_window_id: :window_alpha,
        station_calendar_entry_id: :station_entry_alpha,
        station_calendar_provider_id: :provider_alpha,
        station_calendar_provider_entry_id: :provider_entry_alpha,
        station_calendar_directions: [:downlink],
        throughput_model: %{station_capacity_fraction: 0.5}
      }
    ]

    report = ResourceSummary.roll_forward(summary, selected_activities)

    assert %{
             "resource_pressure_types" => ["downlink_shortfall"],
             "resource_pressure_activity_ids_by_type" => %{
               "downlink_shortfall" => ["dl_contact"]
             },
             "resource_pressure_ground_station_ids_by_type" => %{
               "downlink_shortfall" => ["equator_prime"]
             },
             "resource_pressure_source_window_ids_by_type" => %{
               "downlink_shortfall" => ["window_alpha"]
             },
             "resource_pressure_station_calendar_entry_ids_by_type" => %{
               "downlink_shortfall" => ["station_entry_alpha"]
             },
             "resource_pressure_station_calendar_provider_ids_by_type" => %{
               "downlink_shortfall" => ["provider_alpha"]
             },
             "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
               "downlink_shortfall" => ["provider_entry_alpha"]
             },
             "resource_pressure_station_calendar_directions_by_type" => %{
               "downlink_shortfall" => ["downlink"]
             },
             "resource_pressure_capacity_fractions_by_type" => %{
               "downlink_shortfall" => [0.5]
             }
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)

    [
      {
        "resource_pressure_activity_ids_by_type",
        %{"downlink_shortfall" => ["stale_activity"]},
        "must equal row-derived resource_pressure_activity_ids_by_type"
      },
      {
        "resource_pressure_ground_station_ids_by_type",
        %{"downlink_shortfall" => ["stale_station"]},
        "must equal row-derived resource_pressure_ground_station_ids_by_type"
      },
      {
        "resource_pressure_source_window_ids_by_type",
        %{"downlink_shortfall" => ["stale_window"]},
        "must equal row-derived resource_pressure_source_window_ids_by_type"
      },
      {
        "resource_pressure_station_calendar_entry_ids_by_type",
        %{"downlink_shortfall" => ["stale_station_entry"]},
        "must equal row-derived resource_pressure_station_calendar_entry_ids_by_type"
      },
      {
        "resource_pressure_station_calendar_provider_ids_by_type",
        %{"downlink_shortfall" => ["stale_provider"]},
        "must equal row-derived resource_pressure_station_calendar_provider_ids_by_type"
      },
      {
        "resource_pressure_station_calendar_provider_entry_ids_by_type",
        %{"downlink_shortfall" => ["stale_provider_entry"]},
        "must equal row-derived resource_pressure_station_calendar_provider_entry_ids_by_type"
      },
      {
        "resource_pressure_station_calendar_directions_by_type",
        %{"downlink_shortfall" => ["uplink"]},
        "must equal row-derived resource_pressure_station_calendar_directions_by_type"
      },
      {
        "resource_pressure_capacity_fractions_by_type",
        %{"downlink_shortfall" => [0.75]},
        "must equal row-derived resource_pressure_capacity_fractions_by_type"
      }
    ]
    |> Enum.each(fn {field, stale_value, message} ->
      stale_report = Map.put(report, field, stale_value)

      assert {:error, validation_report} =
               OrbitalDynamics.Schema.validate_artifact(stale_report)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.#{field}" and &1["message"] == message)
             )
    end)
  end

  test "roll-forward audits terminal and approval-rejected selected activities as ignored effects" do
    summary = %{
      spacecraft_id: :leo_1,
      storage_capacity_mb: 100.0,
      storage_used_mb: 10.0,
      downlink_capacity_mb: 100.0
    }

    selected_activities = [
      %{
        id: :obs_active,
        type: :observe,
        spacecraft_id: :leo_1,
        starts_at_s: 10.0,
        estimated_storage_mb: 30.0
      },
      %{
        id: :obs_canceled,
        type: :observe,
        spacecraft_id: :leo_1,
        starts_at_s: 20.0,
        estimated_storage_mb: 30.0,
        status: :canceled
      },
      %{
        id: :dl_completed,
        type: :downlink,
        spacecraft_id: :leo_1,
        starts_at_s: 30.0,
        estimated_throughput_mb: 50.0,
        status: :completed
      },
      %{
        id: :dl_rejected,
        type: :planned_contact,
        direction: :downlink,
        spacecraft_id: :leo_1,
        starts_at_s: 40.0,
        estimated_throughput_mb: 25.0,
        approval_status: :rejected
      },
      %{
        id: :dl_completed_rejected,
        type: :planned_contact,
        direction: :downlink,
        spacecraft_id: :leo_1,
        starts_at_s: 50.0,
        estimated_throughput_mb: 25.0,
        status: :completed,
        approval_status: :rejected
      }
    ]

    assert %{
             "schema_contract" => "resource_projection_flow_summary.v1",
             "model" => "artifact_only_selected_activity_resource_flow_summary",
             "activity_count" => 5,
             "valid_activity_count" => 5,
             "ignored_activity_count" => 4,
             "ignored_activity_ids" => [
               "dl_completed",
               "dl_completed_rejected",
               "dl_rejected",
               "obs_canceled"
             ],
             "ignored_activity_reason_counts" => %{
               "activity_status_canceled" => 1,
               "activity_status_completed" => 1,
               "approval_status_rejected" => 2
             },
             "ignored_activity_ids_by_reason" => %{
               "activity_status_canceled" => ["obs_canceled"],
               "activity_status_completed" => ["dl_completed"],
               "approval_status_rejected" => ["dl_completed_rejected", "dl_rejected"]
             },
             "total_storage_produced_mb" => 30.0,
             "total_planned_downlink_mb" => +0.0,
             "total_projected_storage_remaining_mb" => 60.0,
             "activity_resource_flow" => [
               %{
                 "activity_id" => "obs_active",
                 "resource_effect_status" => "projected",
                 "resource_effect_reason" => "active_planning_activity",
                 "storage_delta_mb" => 30.0,
                 "storage_used_after_mb" => 40.0
               },
               %{
                 "activity_id" => "obs_canceled",
                 "resource_effect_status" => "ignored",
                 "resource_effect_reason" => "activity_status_canceled",
                 "storage_delta_mb" => +0.0,
                 "storage_used_after_mb" => 40.0
               },
               %{
                 "activity_id" => "dl_completed",
                 "resource_effect_status" => "ignored",
                 "resource_effect_reason" => "activity_status_completed",
                 "planned_downlink_mb" => +0.0,
                 "storage_used_after_mb" => 40.0
               },
               %{
                 "activity_id" => "dl_rejected",
                 "approval_status" => "rejected",
                 "resource_effect_status" => "ignored",
                 "resource_effect_reason" => "approval_status_rejected",
                 "planned_downlink_mb" => +0.0,
                 "storage_used_after_mb" => 40.0
               },
               %{
                 "activity_id" => "dl_completed_rejected",
                 "approval_status" => "rejected",
                 "resource_effect_status" => "ignored",
                 "resource_effect_reason" => "approval_status_rejected",
                 "planned_downlink_mb" => +0.0,
                 "storage_used_after_mb" => 40.0
               }
             ],
             "assumptions" => %{
               "activity_status_model" =>
                 "terminal_or_approval_rejected_activities_are_audited_with_zero_projected_resource_effect"
             }
           } = report = ResourceSummary.roll_forward(summary, selected_activities)

    assert report["activity_resource_flow"]
           |> Enum.map(& &1["resource_effect_status"])
           |> Enum.uniq()
           |> Enum.all?(
             &(&1 in ResourceSummary.capabilities().roll_forward_resource_effect_statuses)
           )

    invalid_effect_status =
      put_in(
        report,
        ["activity_resource_flow", Access.at(1), "resource_effect_status"],
        "silently_reconciled"
      )

    assert {:error, invalid_effect_status_report} =
             OrbitalDynamics.Schema.validate_artifact(invalid_effect_status)

    assert Enum.any?(
             invalid_effect_status_report["errors"],
             &(&1["path"] == "$.activity_resource_flow[1].resource_effect_status")
           )

    assert report["ignored_activity_reason_counts"]
           |> Map.keys()
           |> Enum.all?(fn reason ->
             reason in ResourceSummary.capabilities().roll_forward_ignored_effect_reason_families or
               String.starts_with?(reason, "activity_status_")
           end)

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)
  end
end
