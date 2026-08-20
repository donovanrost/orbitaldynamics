defmodule OrbitalDynamics.Communications.DownlinkLinkBudgetTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Communications.{ContactAllocation, DownlinkLinkBudget, LinkCapacity}
  alias OrbitalDynamics.{ResourceProjection, ResourceStateTrace, Schema}

  test "publishes a schema-backed one-way fixed-mode capability" do
    assert %{
             artifact_contract: "downlink_link_budget.v1",
             model: :deterministic_point_one_way_downlink_budget,
             validation_level: :artifact_contract,
             supported_direction: :downlink,
             supported_mode: :fixed_single_carrier,
             public_facades: [:downlink_link_budget],
             known_limits: known_limits
           } = DownlinkLinkBudget.capabilities()

    assert :explicit_losses_only in known_limits
    assert :no_adaptive_coding_or_modulation in known_limits
    assert :no_atmospheric_rain_or_polarization_integration in known_limits
    assert :no_hidden_calibration in known_limits
    assert :no_provider_reservation_or_network_truth in known_limits
    assert :no_schedule_mutation in known_limits

    assert OrbitalDynamics.capability_catalog().operations.downlink_link_budget ==
             DownlinkLinkBudget.capabilities()

    assert function_exported?(OrbitalDynamics, :downlink_link_budget, 2)
    assert function_exported?(LinkCapacity, :downlink_link_budget, 2)

    assert {:ok, contract} = Schema.contract("downlink_link_budget.v1")
    assert contract["artifact_family"] == "downlink_link_budget"

    assert {:ok, schema} = Schema.json_schema("downlink_link_budget.v1")
    assert schema["required"] == contract["required_fields"]

    assert get_in(schema, ["properties", "geometry", "properties", "slant_range"]) == %{
             "type" => "object",
             "additionalProperties" => false,
             "required" => ["value", "unit"],
             "properties" => %{
               "value" => %{"type" => "number", "exclusiveMinimum" => 0.0},
               "unit" => %{
                 "type" => "string",
                 "const" => "km",
                 "enum" => [
                   "km",
                   "deg",
                   "s",
                   "Hz",
                   "W",
                   "dBi",
                   "K",
                   "dB",
                   "ratio",
                   "bit/s/Hz"
                 ]
               }
             }
           }
  end

  test "derives received power, C/N0, Eb/N0, fixed-mode rate, bounded volume, and margin" do
    budget = OrbitalDynamics.downlink_link_budget(contact(), parameters())

    assert %{
             "schema_contract" => "downlink_link_budget.v1",
             "id" => "downlink_link_budget:" <> digest,
             "model" => "deterministic_point_one_way_downlink_budget",
             "status" => "supported",
             "pass" => true,
             "derived" => derived
           } = budget

    assert String.length(digest) == 64
    assert_in_delta derived["configured_data_rate_bps"], 500_000.0, 1.0e-9
    assert_in_delta derived["supported_data_rate_bps"], 500_000.0, 1.0e-9
    assert_in_delta derived["supported_data_rate_mbps"], 0.5, 1.0e-12
    assert_in_delta derived["supported_volume_mb"], 7.5, 1.0e-12
    assert derived["received_power_dbw"] < 0.0
    assert derived["c_n0_db_hz"] > 0.0
    assert derived["eb_n0_db"] > 0.0
    assert derived["pass_fail_margin_db"] > 0.0
    assert derived["geometry_margin_deg"] == 20.0

    assert budget["contact_binding"] == %{
             "contact_id" => "dl_1",
             "spacecraft_id" => "sc_1",
             "ground_station_id" => "gs_1",
             "direction" => "downlink",
             "mode" => "fixed_single_carrier",
             "starts_at_s" => 100.0,
             "ends_at_s" => 220.0,
             "duration_s" => 120.0,
             "source_window_id" => "access_1",
             "source_window_revision" => "window-r7"
           }

    assert budget["geometry"] == %{
             "slant_range" => %{"value" => 1_000.0, "unit" => "km"},
             "elevation" => %{"value" => 30.0, "unit" => "deg"},
             "sample_at" => %{"value" => 160.0, "unit" => "s"}
           }

    assert budget["provenance"] == %{
             "source" => "mission_rf_configuration",
             "source_revision" => "rf-config-r4",
             "access_window_source" => "access_windows.v1",
             "access_window_source_revision" => "trajectory-r12",
             "spacecraft_terminal_source" => "spacecraft_terminal_catalog",
             "spacecraft_terminal_revision" => "sc-terminal-r3",
             "ground_terminal_source" => "ground_terminal_catalog",
             "ground_terminal_revision" => "gs-terminal-r9",
             "builder" => "OrbitalDynamics.Communications.DownlinkLinkBudget.build/2"
           }

    assert budget["assumptions"]["calibration"] == "none"
    assert budget["assumptions"]["megabyte_definition_bits"] == 8_000_000.0
    assert budget["model_limits"] == DownlinkLinkBudget.model_limits()

    json = budget |> :json.encode() |> IO.iodata_to_binary()
    assert {:ok, report} = json |> :json.decode() |> Schema.validate_artifact()
    assert report["status"] == "pass"
  end

  test "uses inclusive geometry and RF thresholds without adaptive fallback" do
    baseline = DownlinkLinkBudget.build(contact(), zero_margin_parameters())
    available_eb_n0_db = baseline["derived"]["eb_n0_db"]

    threshold_parameters =
      parameters()
      |> put_in([:margin_policy, :minimum_elevation, :value], 30.0)
      |> put_in([:margin_policy, :required_eb_n0, :value], available_eb_n0_db - 2.0)
      |> put_in([:margin_policy, :required_margin, :value], 2.0)

    threshold = DownlinkLinkBudget.build(contact(), threshold_parameters)
    assert threshold["status"] == "supported"
    assert threshold["pass"]
    assert threshold["derived"]["geometry_margin_deg"] == 0.0
    assert threshold["derived"]["pass_fail_margin_db"] == 0.0
    assert threshold["derived"]["supported_data_rate_bps"] == 500_000.0

    failed =
      threshold_parameters
      |> put_in([:margin_policy, :required_margin, :value], 2.000_001)
      |> then(&DownlinkLinkBudget.build(contact(), &1))

    assert failed["status"] == "insufficient_link_margin"
    refute failed["pass"]
    assert failed["derived"]["pass_fail_margin_db"] < 0.0
    assert failed["derived"]["supported_data_rate_bps"] == 0.0
    assert failed["derived"]["supported_volume_mb"] == 0.0

    below_elevation =
      threshold_parameters
      |> put_in([:margin_policy, :minimum_elevation, :value], 30.000_001)
      |> then(&DownlinkLinkBudget.build(contact(), &1))

    assert below_elevation["status"] == "below_minimum_elevation"
    assert below_elevation["derived"]["supported_volume_mb"] == 0.0
  end

  test "rejects missing or malformed units and parameters" do
    invalid_parameters = [
      update_in(parameters(), [:geometry, :slant_range], &Map.delete(&1, :unit)),
      put_in(parameters(), [:geometry, :slant_range, :unit], "m"),
      update_in(parameters(), [:rf_link], &Map.delete(&1, :coding_efficiency)),
      update_in(parameters(), [:ground_terminal], &Map.delete(&1, :source)),
      Map.delete(parameters(), :source_revision)
    ]

    Enum.each(invalid_parameters, fn invalid ->
      assert_raise ArgumentError, fn -> DownlinkLinkBudget.build(contact(), invalid) end
    end)
  end

  test "rejects impossible geometry, unsupported direction/mode/frequency, and nonfinite or negative values" do
    invalid_inputs = [
      {contact(), put_in(parameters(), [:geometry, :slant_range, :value], 0.0)},
      {contact(), put_in(parameters(), [:geometry, :elevation, :value], 90.1)},
      {contact(), put_in(parameters(), [:geometry, :sample_at, :value], 221.0)},
      {%{contact() | direction: "uplink"}, parameters()},
      {%{contact() | mode: "adaptive"}, parameters()},
      {contact(), put_in(parameters(), [:rf_link, :direction], "uplink")},
      {contact(), put_in(parameters(), [:spacecraft_terminal, :mode], "adaptive")},
      {contact(), put_in(parameters(), [:ground_terminal, :carrier_frequency, :value], 2.1e9)},
      {contact(), put_in(parameters(), [:rf_link, :explicit_losses, :value], -1.0)},
      {contact(),
       put_in(parameters(), [:spacecraft_terminal, :transmit_antenna_gain, :value], -0.1)},
      {contact(), put_in(parameters(), [:rf_link, :occupied_bandwidth, :value], :infinity)}
    ]

    Enum.each(invalid_inputs, fn {invalid_contact, invalid_parameters} ->
      assert_raise ArgumentError, fn ->
        DownlinkLinkBudget.build(invalid_contact, invalid_parameters)
      end
    end)
  end

  test "rejects stale or mismatched contact and access-window identity" do
    stale_contact = %{contact() | source_window_revision: "window-r8"}
    mismatched_window = put_in(parameters(), [:access_window, :id], "access_2")
    mismatched_spacecraft = put_in(parameters(), [:access_window, :spacecraft_id], "sc_2")

    mismatched_spacecraft_terminal =
      put_in(parameters(), [:spacecraft_terminal, :spacecraft_id], "sc_2")

    mismatched_ground_terminal =
      put_in(parameters(), [:ground_terminal, :ground_station_id], "gs_2")

    outside_window = put_in(parameters(), [:access_window, :ends_at_s], 219.0)

    assert_raise ArgumentError, fn ->
      DownlinkLinkBudget.build(stale_contact, parameters())
    end

    for invalid <- [
          mismatched_window,
          mismatched_spacecraft,
          mismatched_spacecraft_terminal,
          mismatched_ground_terminal,
          outside_window
        ] do
      assert_raise ArgumentError, fn -> DownlinkLinkBudget.build(contact(), invalid) end
    end

    evidence = DownlinkLinkBudget.build(contact(), parameters())

    stale_attached =
      stale_contact
      |> Map.put(:downlink_link_budget, evidence)

    assert_raise ArgumentError, ~r/stale or mismatched/, fn ->
      LinkCapacity.report([stale_attached], [stale_attached])
    end
  end

  test "link-capacity and allocation completion use budget volume and preserve evidence" do
    budget = DownlinkLinkBudget.build(contact(), parameters())

    budgeted_contact =
      contact()
      |> Map.put(:estimated_throughput_mb, 1_000.0)
      |> Map.put(:candidate_downlink_mb, 2_000.0)
      |> Map.put(:downlink_link_budget, budget)

    report = LinkCapacity.report([budgeted_contact], [budgeted_contact])

    assert report["estimated_throughput_mb"] == 7.5
    assert report["selected_estimated_throughput_mb"] == 7.5
    assert report["downlink_link_budget_count"] == 1
    assert report["downlink_link_budget_ids"] == [budget["id"]]
    assert report["downlink_link_budgets"] == [budget]
    assert get_in(report, ["rows", Access.at(0), "downlink_link_budget_ids"]) == [budget["id"]]

    assert report["assumptions"]["link_budget_model"] =~
             "supported_volume_overrides_fixed_rate"

    assert {:ok, _validation} = Schema.validate_artifact(report)

    {allocated, allocation_report} = ContactAllocation.allocate_contacts([budgeted_contact], [])

    assert [allocated_contact] = allocated
    assert allocated_contact["downlink_link_budget"] == budget

    assert [allocation_row] = allocation_report["rows"]
    assert allocation_row["downlink_link_budget"] == budget
    assert allocation_row["candidate_downlink_mb"] == 7.5
    assert {:ok, _validation} = Schema.validate_artifact(allocation_report)
  end

  test "resource projection applies station capacity after the bounded budget volume" do
    budget = DownlinkLinkBudget.build(contact(), parameters())

    budgeted_contact =
      contact()
      |> Map.put(:estimated_throughput_mb, 1_000.0)
      |> Map.put(:station_capacity_fraction, 0.5)
      |> Map.put(:downlink_link_budget, budget)

    resource_summary =
      initial_resource_summary()
      |> Map.put(:downlink_capacity_mb, 100.0)

    report = ResourceProjection.report([budgeted_contact], [resource_summary])
    assert [projection] = report["projected_resources"]
    assert projection["estimated_downlink_mb"] == 3.75

    assert [flow_row] = projection["activity_resource_flow"]
    assert flow_row["planned_downlink_mb"] == 3.75
    assert flow_row["downlinked_mb"] == 3.75
    assert flow_row["downlink_link_budget"] == budget
    assert {:ok, _validation} = Schema.validate_artifact(report)
  end

  test "legacy fixed-rate contacts remain byte-for-byte free of budget evidence" do
    legacy_contact = %{
      id: :legacy_dl,
      type: :downlink,
      spacecraft_id: :sc_1,
      ground_station_id: :gs_1,
      starts_at_s: 10.0,
      ends_at_s: 30.0,
      estimated_throughput_mb: 12.0
    }

    report = LinkCapacity.report([legacy_contact], [legacy_contact])

    assert report["model"] == "fixed_rate_downlink_capacity_summary"
    assert report["estimated_throughput_mb"] == 12.0
    assert report["selected_estimated_throughput_mb"] == 12.0
    assert report["assumptions"]["link_budget_model"] == "none"
    refute Map.has_key?(report, "downlink_link_budget_count")
    refute Map.has_key?(report, "downlink_link_budget_ids")
    refute Map.has_key?(report, "downlink_link_budgets")
    refute Map.has_key?(hd(report["rows"]), "downlink_link_budget_count")

    assert report ==
             LinkCapacity.report(
               [legacy_contact |> Map.to_list() |> Enum.reverse() |> Map.new()],
               [legacy_contact]
             )

    assert {:ok, _validation} = Schema.validate_artifact(report)
  end

  test "IDs and report evidence ordering reproduce under reordered input maps and contacts" do
    contact_1 = contact()
    params_1 = parameters()
    budget_1 = DownlinkLinkBudget.build(contact_1, params_1)

    reordered_params = params_1 |> Map.to_list() |> Enum.reverse() |> Map.new()
    assert DownlinkLinkBudget.build(contact_1, reordered_params) == budget_1

    contact_2 =
      contact()
      |> Map.merge(%{
        id: "dl_2",
        starts_at_s: 300.0,
        ends_at_s: 360.0,
        source_window_id: "access_2",
        source_window_revision: "window-r8"
      })

    params_2 =
      parameters()
      |> put_in([:access_window, :id], "access_2")
      |> put_in([:access_window, :revision], "window-r8")
      |> put_in([:access_window, :starts_at_s], 290.0)
      |> put_in([:access_window, :ends_at_s], 370.0)
      |> put_in([:geometry, :sample_at, :value], 330.0)

    budget_2 = DownlinkLinkBudget.build(contact_2, params_2)
    budgeted_1 = Map.put(contact_1, :downlink_link_budget, budget_1)
    budgeted_2 = Map.put(contact_2, :downlink_link_budget, budget_2)

    first = LinkCapacity.report([budgeted_2, budgeted_1], [budgeted_1, budgeted_2])
    second = LinkCapacity.report([budgeted_1, budgeted_2], [budgeted_2, budgeted_1])

    assert first == second

    assert first["downlink_link_budget_ids"] ==
             [budget_1, budget_2]
             |> Enum.sort_by(&{&1["contact_binding"]["contact_id"], &1["id"]})
             |> Enum.map(& &1["id"])
  end

  test "recorder removal is capped by link-budget volume with declared demand retained" do
    budget = DownlinkLinkBudget.build(contact(), parameters())

    activity =
      contact()
      |> Map.put(:downlink_link_budget, budget)
      |> Map.put(:resource_effects, %{
        energy_consumed_wh: 0.0,
        energy_generated_wh: 0.0,
        data_stored_mb: 0.0,
        data_removed_mb: 50.0
      })

    trace =
      ResourceStateTrace.trace(activity |> List.wrap(), initial_resource_summary(), as_of_s: 0.0)

    assert [row] = trace["trace_rows"]
    assert row["downlink_link_budget"] == budget
    assert row["declared_effects"]["data_removed_mb"] == 50.0
    assert row["applied_effects"]["data_removed_mb"] == 7.5
    assert row["state_before"]["recorder_used_mb"] == 40.0
    assert row["state_after"]["recorder_used_mb"] == 32.5

    assert row["limit_evidence"] ==
             Map.merge(
               Map.take(row["limit_evidence"], [
                 "unconstrained_battery_energy_remaining_wh",
                 "unconstrained_recorder_used_mb",
                 "battery_depletion_wh",
                 "battery_overflow_wh",
                 "recorder_depletion_mb",
                 "recorder_overflow_mb"
               ]),
               %{
                 "downlink_link_budget_id" => budget["id"],
                 "requested_data_removed_mb" => 50.0,
                 "status_eligible_data_removed_mb" => 50.0,
                 "link_budget_supported_volume_mb" => 7.5,
                 "link_budget_applied_data_removed_mb" => 7.5,
                 "link_budget_limited_data_removed_mb" => 42.5,
                 "unused_link_budget_volume_mb" => 0.0
               }
             )

    assert {:ok, _validation} = Schema.validate_artifact(trace)

    forged =
      put_in(trace, ["trace_rows", Access.at(0), "applied_effects", "data_removed_mb"], 8.0)

    assert {:error, _validation} = Schema.validate_artifact(forged)
  end

  test "tampered evidence is rejected by schema and every bounded-volume consumer" do
    budget = DownlinkLinkBudget.build(contact(), parameters())
    tampered = update_in(budget, ["derived", "supported_volume_mb"], &(&1 + 1.0))
    unexpected = Map.put(budget, "unexpected", true)

    assert {:error, _validation} = Schema.validate_artifact(tampered)
    assert {:error, _validation} = Schema.validate_artifact(unexpected)

    tampered_contact = Map.put(contact(), :downlink_link_budget, tampered)

    assert_raise ArgumentError, ~r/invalid downlink_link_budget evidence/, fn ->
      LinkCapacity.report([tampered_contact], [])
    end

    assert_raise ArgumentError, ~r/invalid downlink_link_budget evidence/, fn ->
      ContactAllocation.allocate_contacts([tampered_contact], [])
    end

    assert_raise ArgumentError, ~r/invalid downlink_link_budget evidence/, fn ->
      ResourceProjection.report(
        [tampered_contact],
        [Map.put(initial_resource_summary(), :downlink_capacity_mb, 100.0)]
      )
    end

    assert_raise ArgumentError, ~r/invalid downlink_link_budget evidence/, fn ->
      ResourceStateTrace.trace(
        [Map.put(tampered_contact, :resource_effects, %{data_removed_mb: 1.0})],
        initial_resource_summary(),
        as_of_s: 0.0
      )
    end
  end

  defp zero_margin_parameters do
    parameters()
    |> put_in([:margin_policy, :required_eb_n0, :value], 0.0)
    |> put_in([:margin_policy, :required_margin, :value], 0.0)
  end

  defp contact do
    %{
      id: "dl_1",
      type: "downlink",
      spacecraft_id: "sc_1",
      ground_station_id: "gs_1",
      direction: "downlink",
      mode: "fixed_single_carrier",
      starts_at_s: 100.0,
      ends_at_s: 220.0,
      source_window_id: "access_1",
      source_window_revision: "window-r7"
    }
  end

  defp parameters do
    %{
      source: "mission_rf_configuration",
      source_revision: "rf-config-r4",
      access_window: %{
        id: "access_1",
        revision: "window-r7",
        spacecraft_id: "sc_1",
        ground_station_id: "gs_1",
        starts_at_s: 90.0,
        ends_at_s: 230.0,
        source: "access_windows.v1",
        source_revision: "trajectory-r12"
      },
      geometry: %{
        slant_range: %{value: 1_000.0, unit: "km"},
        elevation: %{value: 30.0, unit: "deg"},
        sample_at: %{value: 160.0, unit: "s"}
      },
      spacecraft_terminal: %{
        id: "sc_terminal_1",
        spacecraft_id: "sc_1",
        source: "spacecraft_terminal_catalog",
        revision: "sc-terminal-r3",
        direction: "downlink",
        mode: "fixed_single_carrier",
        carrier_frequency: %{value: 2.2e9, unit: "Hz"},
        transmit_power: %{value: 20.0, unit: "W"},
        transmit_antenna_gain: %{value: 5.0, unit: "dBi"}
      },
      ground_terminal: %{
        id: "gs_terminal_1",
        ground_station_id: "gs_1",
        source: "ground_terminal_catalog",
        revision: "gs-terminal-r9",
        direction: "downlink",
        mode: "fixed_single_carrier",
        carrier_frequency: %{value: 2.2e9, unit: "Hz"},
        receive_antenna_gain: %{value: 35.0, unit: "dBi"},
        system_noise_temperature: %{value: 500.0, unit: "K"}
      },
      rf_link: %{
        direction: "downlink",
        mode: "fixed_single_carrier",
        carrier_frequency: %{value: 2.2e9, unit: "Hz"},
        occupied_bandwidth: %{value: 1.0e6, unit: "Hz"},
        explicit_losses: %{value: 3.0, unit: "dB"},
        coding_efficiency: %{value: 0.5, unit: "ratio"},
        modulation_efficiency: %{value: 1.0, unit: "bit/s/Hz"}
      },
      margin_policy: %{
        minimum_elevation: %{value: 10.0, unit: "deg"},
        required_eb_n0: %{value: 3.0, unit: "dB"},
        required_margin: %{value: 2.0, unit: "dB"}
      }
    }
  end

  defp initial_resource_summary do
    %{
      spacecraft_id: "sc_1",
      battery_capacity_wh: 100.0,
      battery_energy_used_wh: 20.0,
      storage_capacity_mb: 100.0,
      storage_used_mb: 40.0,
      assumptions: %{initial_state: :operator_declared},
      provenance: %{
        source_quality: :operator_supplied,
        trust_boundary: :operator_declared
      }
    }
  end
end
