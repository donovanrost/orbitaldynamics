defmodule OrbitalDynamics.ResourceStateTraceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{ResourceProjection, ResourceStateTrace, Schema}

  test "declares a separate Tier 1 public artifact without changing projection defaults" do
    assert %{
             artifact_contract: "resource_state_trace.v1",
             model: :tier_1_declared_activity_resource_state_trace,
             fidelity_tier: :tier_1,
             validation_level: :artifact_contract,
             public_facades: [:resource_state_trace],
             input_resource_contract: "resource_summary.v1",
             input_activity_effect_path: ["resource_effects"],
             declared_effect_fields: declared_effect_fields,
             effect_statuses: ["applied", "ignored"],
             ordering: [:effect_at_s, :starts_at_s, :activity_id],
             subsystem_model_capability_ids: subsystem_model_capability_ids,
             known_limits: known_limits
           } = ResourceStateTrace.capabilities()

    assert declared_effect_fields == [
             "energy_consumed_wh",
             "energy_generated_wh",
             "data_stored_mb",
             "data_removed_mb"
           ]

    assert subsystem_model_capability_ids == [
             "subsystem.power.battery.energy_storage.planning_grade",
             "subsystem.data_recorder.storage_buffer.planning_grade"
           ]

    assert :no_continuous_resource_dynamics in known_limits
    assert :no_thermal_model in known_limits
    assert :no_fuel_model in known_limits
    assert :no_schedule_mutation in known_limits
    assert :no_mission_calibration in known_limits
    assert :not_digital_twin_state in known_limits

    assert OrbitalDynamics.capability_catalog().operations.resource_state_trace ==
             ResourceStateTrace.capabilities()

    assert function_exported?(ResourceStateTrace, :trace, 2)
    assert function_exported?(ResourceStateTrace, :trace, 3)
    assert function_exported?(OrbitalDynamics, :resource_state_trace, 2)
    assert function_exported?(OrbitalDynamics, :resource_state_trace, 3)

    assert ResourceProjection.capabilities().public_facades == [
             :resource_projection_report,
             :resource_projection_flow_report,
             :resource_projection_flow_summary
           ]

    assert {:ok, contract} = Schema.contract("resource_state_trace.v1")
    assert contract["artifact_family"] == "resource_state_trace"

    assert {:ok, schema} = Schema.json_schema("resource_state_trace.v1")
    assert schema["required"] == contract["required_fields"]

    assert get_in(schema, ["properties", "model"]) == %{
             "type" => "string",
             "const" => ResourceStateTrace.model()
           }

    assert get_in(schema, ["properties", "model_limits"]) == %{
             "type" => "array",
             "const" => ResourceStateTrace.model_limits()
           }

    assert get_in(schema, [
             "properties",
             "trace_rows",
             "items",
             "properties",
             "state_before",
             "required"
           ]) ==
             [
               "battery_capacity_wh",
               "battery_energy_remaining_wh",
               "battery_state_of_charge",
               "recorder_capacity_mb",
               "recorder_fill_fraction",
               "recorder_remaining_mb",
               "recorder_used_mb"
             ]
  end

  test "emits reproducible time-ordered before and after state with stable IDs" do
    activities = [
      activity("observe_late", 20, 30,
        energy_consumed_wh: 15,
        data_stored_mb: 30,
        provenance: %{estimate: :payload_profile_a}
      ),
      activity("downlink_early", 10, 15,
        energy_generated_wh: 5,
        data_removed_mb: 5,
        assumptions: %{link_volume: :declared}
      )
    ]

    trace =
      OrbitalDynamics.resource_state_trace(activities, initial_summary(),
        as_of_s: 5,
        source: "selected_timeline_revision:7",
        provenance: %{timeline_revision: 7}
      )

    assert %{
             "schema_contract" => "resource_state_trace.v1",
             "id" => "resource_state_trace:" <> _digest,
             "model" => "tier_1_declared_activity_resource_state_trace",
             "spacecraft_id" => "sc_1",
             "status" => "clear",
             "input_activity_count" => 2,
             "applied_activity_count" => 2,
             "ignored_activity_count" => 0,
             "invalid_activity_count" => 0,
             "violation_count" => 0,
             "trace_rows" => [early, late]
           } = trace

    assert early["id"] == "resource_state_event:sc_1:downlink_early"
    assert early["activity_id"] == "downlink_early"
    assert early["effect_at_s"] == 15.0
    assert early["effect_status"] == "applied"
    assert early["state_status"] == "nominal"
    assert early["state_before"]["battery_energy_remaining_wh"] == 80.0
    assert early["state_after"]["battery_energy_remaining_wh"] == 85.0
    assert early["state_before"]["recorder_used_mb"] == 10.0
    assert early["state_after"]["recorder_used_mb"] == 5.0
    assert early["declared_effects"]["battery_delta_wh"] == 5.0
    assert early["declared_effects"]["recorder_delta_mb"] == -5.0
    assert early["assumptions"] == %{"link_volume" => "declared"}

    assert late["id"] == "resource_state_event:sc_1:observe_late"
    assert late["effect_at_s"] == 30.0
    assert late["state_before"] == early["state_after"]
    assert late["state_after"]["battery_energy_remaining_wh"] == 70.0
    assert late["state_after"]["recorder_used_mb"] == 35.0

    assert trace["initial_state"]["at_s"] == 5.0
    assert trace["final_state"] == Map.put(late["state_after"], "at_s", 30.0)

    assert get_in(trace, ["provenance", "source"]) == "selected_timeline_revision:7"
    assert get_in(trace, ["provenance", "caller", "timeline_revision"]) == 7

    assert get_in(trace, ["trace_rows", Access.at(1), "provenance", "source_effect_provenance"]) ==
             %{"estimate" => "payload_profile_a"}

    assert trace["assumptions"]["effect_timing"] =~ "atomically"
    assert trace["model_limits"] == ResourceStateTrace.model_limits()

    assert trace ==
             OrbitalDynamics.resource_state_trace(Enum.reverse(activities), initial_summary(),
               as_of_s: 5,
               source: "selected_timeline_revision:7",
               provenance: %{timeline_revision: 7}
             )

    json = trace |> :json.encode() |> IO.iodata_to_binary()
    refute json =~ ~s("nil")

    assert {:ok, decoded} =
             json |> :json.decode() |> Schema.validate_artifact()

    assert decoded["status"] == "pass"
  end

  test "does not accept a forged contract tag through a unary trace shortcut" do
    forged = %{"schema_contract" => "resource_state_trace.v1"}

    refute function_exported?(ResourceStateTrace, :trace, 1)
    refute function_exported?(OrbitalDynamics, :resource_state_trace, 1)

    assert_raise UndefinedFunctionError, fn ->
      apply(ResourceStateTrace, :trace, [forged])
    end

    assert_raise UndefinedFunctionError, fn ->
      apply(OrbitalDynamics, :resource_state_trace, [forged])
    end
  end

  test "preserves battery depletion and recorder overflow evidence at bounded state" do
    summary =
      initial_summary(%{
        battery_energy_used_wh: 90,
        storage_used_mb: 90
      })

    trace =
      OrbitalDynamics.resource_state_trace(
        [activity("limit_crossing", 10, 20, energy_consumed_wh: 25, data_stored_mb: 30)],
        summary
      )

    assert %{
             "status" => "limit_exceeded",
             "violation_count" => 1,
             "violation_types" => ["battery_depletion", "recorder_overflow"],
             "activity_ids_by_violation_type" => %{
               "battery_depletion" => ["limit_crossing"],
               "recorder_overflow" => ["limit_crossing"]
             },
             "trace_rows" => [row]
           } = trace

    assert row["state_status"] == "overflow_and_depletion"
    assert row["state_before"]["battery_energy_remaining_wh"] == 10.0
    assert row["state_after"]["battery_energy_remaining_wh"] == 0.0
    assert row["state_after"]["battery_state_of_charge"] == 0.0
    assert row["state_before"]["recorder_used_mb"] == 90.0
    assert row["state_after"]["recorder_used_mb"] == 100.0
    assert row["state_after"]["recorder_fill_fraction"] == 1.0

    assert row["limit_evidence"] == %{
             "unconstrained_battery_energy_remaining_wh" => -15.0,
             "unconstrained_recorder_used_mb" => 120.0,
             "battery_depletion_wh" => 15.0,
             "battery_overflow_wh" => 0.0,
             "recorder_depletion_mb" => 0.0,
             "recorder_overflow_mb" => 20.0
           }

    assert {:ok, _report} = Schema.validate_artifact(trace)
  end

  test "audits an explicitly ignored activity without changing state" do
    ignored =
      activity("rejected_observation", 10, 20,
        status: "ignored",
        ignored_reason: "approval_rejected",
        energy_consumed_wh: 500,
        data_stored_mb: 500,
        provenance: %{approval_revision: "approval:9"}
      )

    trace = OrbitalDynamics.resource_state_trace([ignored], initial_summary())

    assert %{
             "status" => "clear",
             "applied_activity_count" => 0,
             "ignored_activity_count" => 1,
             "violation_count" => 0,
             "trace_rows" => [row]
           } = trace

    assert row["effect_status"] == "ignored"
    assert row["ignored_reason"] == "approval_rejected"
    assert row["state_status"] == "ignored"
    assert row["declared_effects"]["energy_consumed_wh"] == 500.0
    assert row["declared_effects"]["data_stored_mb"] == 500.0
    assert row["applied_effects"]["energy_consumed_wh"] == 0.0
    assert row["applied_effects"]["data_stored_mb"] == 0.0
    assert row["state_after"] == row["state_before"]
    assert trace["final_state"] == Map.put(row["state_before"], "at_s", 20.0)
    assert {:ok, _report} = Schema.validate_artifact(trace)
  end

  test "routes malformed and duplicate activities to deterministic review evidence" do
    activities = [
      activity("bad_energy", 10, 20, energy_consumed_wh: "not-a-number"),
      %{"id" => "bad id", "type" => "observe", "starts_at_s" => 1, "resource_effects" => %{}},
      activity("duplicate", 20, 30, data_stored_mb: 2),
      activity("duplicate", 30, 40, data_stored_mb: 3),
      :not_an_activity
    ]

    trace = OrbitalDynamics.resource_state_trace(activities, initial_summary())

    assert %{
             "status" => "review_required",
             "input_activity_count" => 5,
             "applied_activity_count" => 0,
             "ignored_activity_count" => 0,
             "invalid_activity_count" => 5,
             "trace_rows" => [],
             "invalid_activity_ids" => invalid_activity_ids,
             "invalid_activities" => invalid_activities
           } = trace

    assert length(Enum.uniq(invalid_activity_ids)) == 5

    assert Enum.all?(
             invalid_activity_ids,
             &String.starts_with?(&1, "resource_state_invalid_activity:")
           )

    assert Enum.any?(invalid_activities, fn row ->
             row["activity_id"] == "bad_energy" and
               "malformed_energy_consumed_wh" in row["reason_codes"]
           end)

    assert Enum.count(invalid_activities, &(&1["activity_id"] == "duplicate")) == 2

    assert Enum.all?(
             Enum.filter(invalid_activities, &(&1["activity_id"] == "duplicate")),
             &("duplicate_activity_id" in &1["reason_codes"])
           )

    assert Enum.any?(invalid_activities, &(&1["reason_codes"] == ["invalid_activity_shape"]))

    assert trace ==
             OrbitalDynamics.resource_state_trace(Enum.reverse(activities), initial_summary())

    assert {:ok, _report} = Schema.validate_artifact(trace)

    assert_raise ArgumentError, ~r/invalid initial resource summary.*must not exceed/, fn ->
      OrbitalDynamics.resource_state_trace([], initial_summary(%{storage_used_mb: 101}))
    end
  end

  test "executable validation rejects ordering, chain, and identity drift" do
    trace =
      OrbitalDynamics.resource_state_trace(
        [
          activity("first", 10, 20, energy_consumed_wh: 5),
          activity("second", 20, 30, data_stored_mb: 5)
        ],
        initial_summary()
      )

    stale = Map.put(trace, "trace_rows", Enum.reverse(trace["trace_rows"]))

    assert {:error, report} = Schema.validate_artifact(stale)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.trace_rows" and
                 &1["message"] == "must use deterministic effect-time ordering")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.trace_rows[0].state_before" and
                 &1["message"] == "must equal the prior transition state")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.id" and
                 &1["message"] == "must be the deterministic content identity for this trace")
           )

    stale_evidence =
      put_in(
        trace,
        ["trace_rows", Access.at(0), "limit_evidence", "battery_depletion_wh"],
        1.0
      )

    assert {:error, evidence_report} = Schema.validate_artifact(stale_evidence)

    assert Enum.any?(
             evidence_report["errors"],
             &(&1["path"] == "$.trace_rows[0].limit_evidence.battery_depletion_wh" and
                 &1["message"] == "must equal unmet battery depletion")
           )
  end

  defp initial_summary(overrides \\ %{}) do
    Map.merge(
      %{
        spacecraft_id: "sc_1",
        battery_capacity_wh: 100,
        battery_energy_used_wh: 20,
        storage_capacity_mb: 100,
        storage_used_mb: 10,
        assumptions: %{initial_state: :operator_declared},
        provenance: %{
          source_quality: :operator_supplied,
          trust_boundary: :operator_declared
        }
      },
      overrides
    )
  end

  defp activity(id, starts_at_s, ends_at_s, effect_opts) do
    {provenance, effect_opts} = Keyword.pop(effect_opts, :provenance, %{})
    {assumptions, effect_opts} = Keyword.pop(effect_opts, :assumptions, %{})

    %{
      id: id,
      type: "observe",
      spacecraft_id: "sc_1",
      starts_at_s: starts_at_s,
      ends_at_s: ends_at_s,
      resource_effects:
        effect_opts
        |> Map.new()
        |> Map.put(:assumptions, assumptions)
        |> Map.put(:provenance, provenance)
    }
  end
end
