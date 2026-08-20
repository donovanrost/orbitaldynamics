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
               "value" => %{
                 "type" => "number",
                 "minimum" => 100.0,
                 "maximum" => 6_000.0
               },
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

    assert get_in(schema, [
             "properties",
             "spacecraft_terminal",
             "properties",
             "carrier_frequency",
             "properties",
             "value"
           ]) == %{"type" => "number", "minimum" => 100.0e6, "maximum" => 100.0e9}

    assert DownlinkLinkBudget.input_envelopes() ==
             get_in(DownlinkLinkBudget.assumptions(), ["input_envelopes"])
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

  test "rejects typed low and high values outside every finite input envelope" do
    cases = [
      {"slant_range", &put_in(&1, [:geometry, :slant_range, :value], 99.999)},
      {"slant_range", &put_in(&1, [:geometry, :slant_range, :value], 6_000.001)},
      {"elevation", &put_in(&1, [:geometry, :elevation, :value], -0.001)},
      {"elevation", &put_in(&1, [:geometry, :elevation, :value], 90.001)},
      {"sample_at", &put_in(&1, [:geometry, :sample_at, :value], -0.001)},
      {"sample_at", &put_in(&1, [:geometry, :sample_at, :value], 1.0e12 + 1.0)},
      {"carrier_frequency", &put_frequency(&1, 99_999_999.0)},
      {"carrier_frequency", &put_frequency(&1, 100_000_000_001.0)},
      {"occupied_bandwidth", &put_in(&1, [:rf_link, :occupied_bandwidth, :value], 0.999)},
      {"occupied_bandwidth", &put_in(&1, [:rf_link, :occupied_bandwidth, :value], 1.0e9 + 1.0)},
      {"transmit_power", &put_in(&1, [:spacecraft_terminal, :transmit_power, :value], 0.000_999)},
      {"transmit_power",
       &put_in(&1, [:spacecraft_terminal, :transmit_power, :value], 10_000.001)},
      {"transmit_antenna_gain",
       &put_in(&1, [:spacecraft_terminal, :transmit_antenna_gain, :value], -0.001)},
      {"receive_antenna_gain",
       &put_in(&1, [:ground_terminal, :receive_antenna_gain, :value], 100.001)},
      {"system_noise_temperature",
       &put_in(&1, [:ground_terminal, :system_noise_temperature, :value], 0.999)},
      {"system_noise_temperature",
       &put_in(&1, [:ground_terminal, :system_noise_temperature, :value], 10_000.001)},
      {"explicit_losses", &put_in(&1, [:rf_link, :explicit_losses, :value], -0.001)},
      {"explicit_losses", &put_in(&1, [:rf_link, :explicit_losses, :value], 300.001)},
      {"coding_efficiency", &put_in(&1, [:rf_link, :coding_efficiency, :value], 0.009)},
      {"coding_efficiency", &put_in(&1, [:rf_link, :coding_efficiency, :value], 1.001)},
      {"modulation_efficiency", &put_in(&1, [:rf_link, :modulation_efficiency, :value], 0.009)},
      {"modulation_efficiency", &put_in(&1, [:rf_link, :modulation_efficiency, :value], 16.001)},
      {"minimum_elevation", &put_in(&1, [:margin_policy, :minimum_elevation, :value], -0.001)},
      {"minimum_elevation", &put_in(&1, [:margin_policy, :minimum_elevation, :value], 90.001)},
      {"required_eb_n0", &put_in(&1, [:margin_policy, :required_eb_n0, :value], -0.001)},
      {"required_eb_n0", &put_in(&1, [:margin_policy, :required_eb_n0, :value], 100.001)},
      {"required_margin", &put_in(&1, [:margin_policy, :required_margin, :value], -0.001)},
      {"required_margin", &put_in(&1, [:margin_policy, :required_margin, :value], 100.001)}
    ]

    Enum.each(cases, fn {field, mutate} ->
      assert_raise ArgumentError, ~r/#{field}\.value must be in/, fn ->
        parameters() |> mutate.() |> then(&DownlinkLinkBudget.build(contact(), &1))
      end
    end)

    assert_raise ArgumentError, ~r/ends_at_s must be in/, fn ->
      DownlinkLinkBudget.build(%{contact() | ends_at_s: 1.0e12 + 1.0}, parameters())
    end

    minimum =
      parameters()
      |> put_frequency(100.0e6)
      |> put_in([:geometry, :slant_range, :value], 100.0)
      |> then(&DownlinkLinkBudget.build(contact(), &1))

    assert minimum["derived"]["free_space_path_loss_db"] > 0.0
    assert {:ok, _validation} = Schema.validate_artifact(minimum)

    maximum =
      parameters()
      |> put_frequency(100.0e9)
      |> put_in([:geometry, :slant_range, :value], 6_000.0)
      |> put_in([:geometry, :elevation, :value], 90.0)
      |> put_in([:spacecraft_terminal, :transmit_power, :value], 10_000.0)
      |> put_in([:spacecraft_terminal, :transmit_antenna_gain, :value], 100.0)
      |> put_in([:ground_terminal, :receive_antenna_gain, :value], 100.0)
      |> put_in([:ground_terminal, :system_noise_temperature, :value], 10_000.0)
      |> put_in([:rf_link, :occupied_bandwidth, :value], 1.0e9)
      |> put_in([:rf_link, :explicit_losses, :value], 300.0)
      |> put_in([:rf_link, :coding_efficiency, :value], 1.0)
      |> put_in([:rf_link, :modulation_efficiency, :value], 16.0)
      |> put_in([:margin_policy, :minimum_elevation, :value], 90.0)
      |> put_in([:margin_policy, :required_eb_n0, :value], 100.0)
      |> put_in([:margin_policy, :required_margin, :value], 100.0)
      |> then(&DownlinkLinkBudget.build(contact(), &1))

    assert maximum["derived"]["free_space_path_loss_db"] > 0.0
    assert {:ok, _validation} = Schema.validate_artifact(maximum)
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

    assert get_in(report, ["rows", Access.at(0), "downlink_link_budget_contact_ids"]) == [
             "dl_1"
           ]

    refute "no_link_budget_model" in report["model_limits"]
    refute "no_modulation_or_coding_model" in report["model_limits"]

    assert {:ok, link_schema} = Schema.json_schema("link_capacity_report.v1")

    schema_model_limits =
      link_schema
      |> get_in(["properties", "model_limits", "oneOf"])
      |> Enum.map(& &1["const"])

    assert report["model_limits"] in schema_model_limits

    assert_schema_rejects(
      Map.put(
        report,
        "model_limits",
        LinkCapacity.capabilities().known_limits |> Enum.map(&Atom.to_string/1)
      )
    )

    assert report["assumptions"]["link_budget_model"] =~
             "supported_volume_overrides_fixed_rate"

    assert {:ok, _validation} = Schema.validate_artifact(report)

    {allocated, allocation_report} = ContactAllocation.allocate_contacts([budgeted_contact], [])

    assert [allocated_contact] = allocated
    assert allocated_contact["downlink_link_budget"] == budget

    assert [allocation_row] = allocation_report["rows"]
    assert allocation_row["downlink_link_budget"] == budget
    assert allocation_row["downlink_link_budget_id"] == budget["id"]
    assert allocation_row["source_window_revision"] == "window-r7"
    assert allocation_row["candidate_downlink_mb"] == 7.5
    assert {:ok, _validation} = Schema.validate_artifact(allocation_report)
  end

  test "budget override recomputes completion evidence before approval policy evaluation" do
    budget = DownlinkLinkBudget.build(contact(), parameters())

    contradictory =
      contact()
      |> Map.merge(%{
        status: :completed,
        required_downlink_mb: 10.0,
        candidate_downlink_mb: 1_000.0,
        downlink_completion_ratio: 1.0,
        selected_downlink_shortfall_mb: 0.0,
        downlink_requirement_status: "satisfied",
        downlink_link_budget: budget
      })

    {_allocated, report} =
      ContactAllocation.allocate_contacts([contradictory], [],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [row] = report["rows"]
    assert row["candidate_downlink_mb"] == 7.5
    assert row["downlink_completion_ratio"] == 0.75
    assert row["selected_downlink_shortfall_mb"] == 2.5
    assert row["downlink_requirement_status"] == "shortfall"

    assert [requirement] = row["approval_requirements"]
    context = requirement["activity_context"]
    assert context["candidate_downlink_mb"] == 7.5
    assert context["downlink_completion_ratio"] == 0.75
    assert context["selected_downlink_shortfall_mb"] == 2.5
    assert context["downlink_requirement_status"] == "shortfall"
    assert context["downlink_link_budget_id"] == budget["id"]
    assert {:ok, _validation} = Schema.validate_artifact(report)

    for {field, value} <- [
          {"candidate_downlink_mb", 8.0},
          {"downlink_completion_ratio", 0.8},
          {"selected_downlink_shortfall_mb", 2.0},
          {"downlink_requirement_status", "satisfied"}
        ] do
      assert_schema_rejects(put_in(report, ["rows", Access.at(0), field], value))
    end

    unbound_contradiction =
      contact()
      |> Map.put(:downlink_completion_ratio, 0.5)
      |> Map.put(:downlink_link_budget, budget)

    assert_raise ArgumentError, ~r/required_downlink_mb is required to reconcile/, fn ->
      ContactAllocation.allocate_contacts([unbound_contradiction], [])
    end
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
    assert flow_row["downlink_link_budget_id"] == budget["id"]
    assert flow_row["source_window_revision"] == "window-r7"
    assert flow_row["contact_mode"] == "fixed_single_carrier"
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
    assert "no_link_budget_model" in report["model_limits"]
    assert "no_modulation_or_coding_model" in report["model_limits"]
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

    {_allocated, allocation_report} = ContactAllocation.allocate_contacts([contact()], [])
    assert [allocation_row] = allocation_report["rows"]
    refute Map.has_key?(allocation_row, "downlink_link_budget")
    refute Map.has_key?(allocation_row, "downlink_link_budget_id")
    refute Map.has_key?(allocation_row, "source_window_revision")

    projection_report =
      ResourceProjection.report(
        [contact()],
        [Map.put(initial_resource_summary(), :downlink_capacity_mb, 100.0)]
      )

    assert [legacy_flow] =
             get_in(projection_report, [
               "projected_resources",
               Access.at(0),
               "activity_resource_flow"
             ])

    refute Map.has_key?(legacy_flow, "downlink_link_budget")
    refute Map.has_key?(legacy_flow, "downlink_link_budget_id")
    refute Map.has_key?(legacy_flow, "source_window_revision")
    refute Map.has_key?(legacy_flow, "contact_mode")
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
      trace
      |> put_in(["trace_rows", Access.at(0), "applied_effects", "data_removed_mb"], 8.0)
      |> reidentify_trace()

    assert {:error, _validation} = Schema.validate_artifact(forged)
  end

  test "runtime validators reject valid re-ID'd budgets that are stale for enclosing rows" do
    budget = DownlinkLinkBudget.build(contact(), parameters())
    forged_budget = forge_budget_contact_id(budget, "dl_forged")
    assert :ok = DownlinkLinkBudget.validate_artifact(forged_budget)

    budgeted_contact = Map.put(contact(), :downlink_link_budget, budget)
    link_report = LinkCapacity.report([budgeted_contact], [budgeted_contact])

    forged_link_report =
      link_report
      |> put_in(["downlink_link_budgets", Access.at(0)], forged_budget)
      |> put_in(["downlink_link_budget_ids", Access.at(0)], forged_budget["id"])
      |> put_in(
        ["rows", Access.at(0), "downlink_link_budget_ids", Access.at(0)],
        forged_budget["id"]
      )
      |> put_in(
        ["rows", Access.at(0), "downlink_link_budget_contact_ids", Access.at(0)],
        "dl_forged"
      )

    assert_schema_rejects(forged_link_report)
    assert_schema_rejects(Map.delete(link_report, "downlink_link_budgets"))

    station_tamper = put_in(link_report, ["rows", Access.at(0), "ground_station_id"], "gs_2")
    assert_schema_rejects(station_tamper)

    direction_tamper =
      put_in(link_report, ["rows", Access.at(0), "station_calendar_directions"], ["uplink"])

    assert_schema_rejects(direction_tamper)

    {_allocated, allocation_report} =
      ContactAllocation.allocate_contacts([budgeted_contact], [])

    forged_allocation =
      allocation_report
      |> put_in(["rows", Access.at(0), "downlink_link_budget"], forged_budget)
      |> put_in(["rows", Access.at(0), "downlink_link_budget_id"], forged_budget["id"])

    assert_schema_rejects(forged_allocation)

    for {field, value} <- [
          {"downlink_link_budget_id", "downlink_link_budget:forged"},
          {"contact_id", "dl_2"},
          {"spacecraft_id", "sc_2"},
          {"ground_station_id", "gs_2"},
          {"source_window_id", "access_2"},
          {"source_window_revision", "window-r8"},
          {"starts_at_s", 101.0},
          {"ends_at_s", 219.0},
          {"direction", "uplink"},
          {"mode", "adaptive"}
        ] do
      assert_schema_rejects(put_in(allocation_report, ["rows", Access.at(0), field], value))
    end

    windowed_contact = Map.put(budgeted_contact, :source_window, parameters().access_window)

    {_allocated, windowed_allocation} =
      ContactAllocation.allocate_contacts([windowed_contact], [])

    assert_schema_rejects(
      put_in(
        windowed_allocation,
        ["rows", Access.at(0), "source_window", "revision"],
        "window-r8"
      )
    )

    assert_schema_rejects(
      put_in(
        windowed_allocation,
        ["rows", Access.at(0), "source_window", "starts_at_s"],
        91.0
      )
    )

    projection_report =
      ResourceProjection.report(
        [budgeted_contact],
        [Map.put(initial_resource_summary(), :downlink_capacity_mb, 100.0)]
      )

    forged_projection =
      projection_report
      |> put_in(
        [
          "projected_resources",
          Access.at(0),
          "activity_resource_flow",
          Access.at(0),
          "downlink_link_budget"
        ],
        forged_budget
      )
      |> put_in(
        [
          "projected_resources",
          Access.at(0),
          "activity_resource_flow",
          Access.at(0),
          "downlink_link_budget_id"
        ],
        forged_budget["id"]
      )

    assert_schema_rejects(forged_projection)

    flow_path = ["projected_resources", Access.at(0), "activity_resource_flow", Access.at(0)]

    for {field, value} <- [
          {"downlink_link_budget_id", "downlink_link_budget:forged"},
          {"activity_id", "dl_2"},
          {"ground_station_id", "gs_2"},
          {"source_window_id", "access_2"},
          {"source_window_revision", "window-r8"},
          {"starts_at_s", 101.0},
          {"ends_at_s", 219.0},
          {"direction", "uplink"},
          {"contact_mode", "adaptive"},
          {"planned_downlink_mb", 8.0},
          {"downlinked_mb", 8.0}
        ] do
      assert_schema_rejects(put_in(projection_report, flow_path ++ [field], value))
    end

    assert_schema_rejects(
      put_in(projection_report, ["projected_resources", Access.at(0), "spacecraft_id"], "sc_2")
    )

    windowed_projection =
      ResourceProjection.report(
        [windowed_contact],
        [Map.put(initial_resource_summary(), :downlink_capacity_mb, 100.0)]
      )

    assert_schema_rejects(
      put_in(
        windowed_projection,
        [
          "projected_resources",
          Access.at(0),
          "activity_resource_flow",
          Access.at(0),
          "source_window",
          "ends_at_s"
        ],
        229.0
      )
    )
  end

  test "trace reconciles required budget provenance and every applied, limited, and unused volume" do
    budget = DownlinkLinkBudget.build(contact(), parameters())

    activity =
      contact()
      |> Map.put(:downlink_link_budget, budget)
      |> Map.put(:resource_effects, %{data_removed_mb: 5.0})

    trace = ResourceStateTrace.trace([activity], initial_resource_summary(), as_of_s: 0.0)

    assert {:ok, trace_schema} = Schema.json_schema("resource_state_trace.v1")

    conditional =
      get_in(trace_schema, [
        "properties",
        "trace_rows",
        "items",
        "allOf",
        Access.at(0)
      ])

    assert get_in(conditional, ["if", "required"]) == ["downlink_link_budget"]

    assert get_in(conditional, [
             "then",
             "properties",
             "limit_evidence",
             "required"
           ]) ==
             ~w(downlink_link_budget_id requested_data_removed_mb status_eligible_data_removed_mb link_budget_supported_volume_mb link_budget_applied_data_removed_mb link_budget_limited_data_removed_mb unused_link_budget_volume_mb)

    assert get_in(conditional, ["then", "properties", "provenance", "required"]) == [
             "downlink_link_budget_id"
           ]

    for {path, value} <- [
          {["provenance", "downlink_link_budget_id"], "downlink_link_budget:forged"},
          {["limit_evidence", "downlink_link_budget_id"], "downlink_link_budget:forged"},
          {["limit_evidence", "requested_data_removed_mb"], 4.0},
          {["limit_evidence", "status_eligible_data_removed_mb"], 4.0},
          {["limit_evidence", "link_budget_supported_volume_mb"], 8.0},
          {["limit_evidence", "link_budget_applied_data_removed_mb"], 4.0},
          {["limit_evidence", "link_budget_limited_data_removed_mb"], 1.0},
          {["limit_evidence", "unused_link_budget_volume_mb"], 1.0}
        ] do
      forged =
        trace
        |> put_in(["trace_rows", Access.at(0)] ++ path, value)
        |> reidentify_trace()

      assert_schema_rejects(forged)
    end

    missing_limit_evidence =
      trace
      |> update_in(
        ["trace_rows", Access.at(0), "limit_evidence"],
        &Map.delete(&1, "unused_link_budget_volume_mb")
      )
      |> reidentify_trace()

    assert_schema_rejects(missing_limit_evidence)

    missing_provenance =
      trace
      |> update_in(
        ["trace_rows", Access.at(0), "provenance"],
        &Map.delete(&1, "downlink_link_budget_id")
      )
      |> reidentify_trace()

    assert_schema_rejects(missing_provenance)

    forged_budget = forge_budget_contact_id(budget, "dl_forged")

    forged_binding =
      trace
      |> put_in(["trace_rows", Access.at(0), "downlink_link_budget"], forged_budget)
      |> put_in(
        ["trace_rows", Access.at(0), "provenance", "downlink_link_budget_id"],
        forged_budget["id"]
      )
      |> put_in(
        ["trace_rows", Access.at(0), "limit_evidence", "downlink_link_budget_id"],
        forged_budget["id"]
      )
      |> reidentify_trace()

    assert_schema_rejects(forged_binding)
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

  defp put_frequency(parameters, frequency_hz) do
    parameters
    |> put_in([:spacecraft_terminal, :carrier_frequency, :value], frequency_hz)
    |> put_in([:ground_terminal, :carrier_frequency, :value], frequency_hz)
    |> put_in([:rf_link, :carrier_frequency, :value], frequency_hz)
  end

  defp forge_budget_contact_id(budget, contact_id) do
    core =
      budget
      |> put_in(["contact_binding", "contact_id"], contact_id)
      |> Map.delete("id")

    Map.put(core, "id", DownlinkLinkBudget.artifact_id(core))
  end

  defp reidentify_trace(trace) do
    core = Map.delete(trace, "id")
    Map.put(core, "id", ResourceStateTrace.artifact_id(core))
  end

  defp assert_schema_rejects(artifact) do
    assert {:error, %{"errors" => errors}} = Schema.validate_artifact(artifact)
    assert errors != []
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
