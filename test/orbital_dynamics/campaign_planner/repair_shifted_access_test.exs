Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairShiftedAccessTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport, only: [base_plan: 1]

  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.CandidateRefresh.ExecutionPolicy
  alias OrbitalDynamics.Schema

  @generated_at ~U[2026-05-14 00:00:00Z]
  @horizon %{
    "starts_at_s" => 0.0,
    "ends_at_s" => 7_200.0,
    "output_step_s" => 10.0
  }
  @spacecraft %{
    "spacecraft_id" => "sat_a",
    "scenario_id" => "scenario_a",
    "dry_mass_kg" => 100.0,
    "propellant_mass_kg" => 5.0,
    "drag_area_m2" => 2.0,
    "drag_coefficient" => 2.2
  }
  @station %{
    "ground_station_id" => "station_a",
    "latitude_deg" => 0.0,
    "longitude_deg" => 0.0,
    "altitude_km" => 0.0,
    "minimum_elevation_deg" => 5.0
  }
  @before_position [7_000.0, 0.0, 0.0]
  @before_velocity [0.0, 7.5, 0.0]
  @shifted_position [-7_000.0, 0.0, 0.0]
  @shifted_velocity [0.0, -7.5, 0.0]

  test "a 180-degree accepted-state phase shift refreshes repair access and preserves protected work" do
    before_request =
      repair_request(
        "accepted_snapshot_before_phase_shift",
        @before_position,
        @before_velocity
      )

    shifted_request =
      repair_request(
        "accepted_snapshot_after_phase_shift",
        @shifted_position,
        @shifted_velocity
      )

    before = CampaignPlanner.repair(before_request)
    shifted = CampaignPlanner.repair(shifted_request)

    assert shifted == CampaignPlanner.repair(shifted_request)

    atom_selected_request =
      update_in(shifted_request, [:candidate_refresh_request], fn refresh_request ->
        refresh_request
        |> Map.delete("execution_path")
        |> Map.put(:execution_path, "candidate_refresh_run_v1")
      end)

    assert shifted == CampaignPlanner.repair(atom_selected_request)

    before_policy = captured_policy(before)
    shifted_policy = captured_policy(shifted)

    assert stable_policy(before_policy) == stable_policy(shifted_policy)
    assert before_policy["bundle_id"] == ExecutionPolicy.bundle_id()
    assert shifted_policy["bundle_id"] == ExecutionPolicy.bundle_id()
    assert before_policy["coverage"] == shifted_policy["coverage"]
    assert before_policy["spacecraft"] == shifted_policy["spacecraft"]
    assert before_policy["ground_station"] == shifted_policy["ground_station"]

    assert before_policy["initial_state"]["position_km"] == @before_position
    assert before_policy["initial_state"]["velocity_km_s"] == @before_velocity
    assert shifted_policy["initial_state"]["position_km"] == @shifted_position
    assert shifted_policy["initial_state"]["velocity_km_s"] == @shifted_velocity

    assert Enum.zip(
             before_policy["initial_state"]["position_km"],
             shifted_policy["initial_state"]["position_km"]
           )
           |> Enum.all?(fn {before_component, shifted_component} ->
             shifted_component == -before_component
           end)

    assert Enum.zip(
             before_policy["initial_state"]["velocity_km_s"],
             shifted_policy["initial_state"]["velocity_km_s"]
           )
           |> Enum.all?(fn {before_component, shifted_component} ->
             shifted_component == -before_component
           end)

    before_windows = access_windows(before)
    shifted_windows = access_windows(shifted)

    assert [first_before, second_before] = before_windows
    assert [shifted_window] = shifted_windows
    assert first_before["starts_at_s"] == 0.0
    assert second_before["starts_at_s"] > 5_700.0
    assert shifted_window["starts_at_s"] > 2_700.0
    assert shifted_window["starts_at_s"] < 2_900.0
    refute window_timings(before_windows) == window_timings(shifted_windows)

    before_source = get_in(before, ["repair_metadata", "candidate_source"])
    shifted_source = get_in(shifted, ["repair_metadata", "candidate_source"])

    assert before_source["snapshot_id"] == "accepted_snapshot_before_phase_shift"
    assert shifted_source["snapshot_id"] == "accepted_snapshot_after_phase_shift"
    refute before_source["refresh_id"] == shifted_source["refresh_id"]
    assert before_source["scope"] == "repair_generated"
    assert shifted_source["scope"] == "repair_generated"

    assert get_in(before, [
             "source_candidate_refresh_provenance",
             "accepted_planning_state",
             "provenance",
             "source_snapshot_id"
           ]) == "accepted_snapshot_before_phase_shift"

    assert get_in(shifted, [
             "source_candidate_refresh_provenance",
             "accepted_planning_state",
             "provenance",
             "source_snapshot_id"
           ]) == "accepted_snapshot_after_phase_shift"

    assert [shifted_lineage] = shifted["source_window_lineage"]
    assert shifted_lineage["candidate_activity_id"] == shifted_replacement(shifted)["id"]
    assert shifted_lineage["source_window_id"] == shifted_window["id"]

    assert Map.take(shifted_lineage["source_window"], ["starts_at_s", "ends_at_s"]) ==
             Map.take(shifted_window, ["starts_at_s", "ends_at_s"])

    before_replacement = shifted_replacement(before)
    shifted_replacement = shifted_replacement(shifted)

    assert before_replacement["starts_at_s"] == second_before["starts_at_s"]
    assert shifted_replacement["starts_at_s"] == shifted_window["starts_at_s"]
    refute before_replacement["starts_at_s"] == shifted_replacement["starts_at_s"]

    assert shifted["remaining_horizon"] == Map.take(@horizon, ["starts_at_s", "ends_at_s"])
    assert shifted_replacement["starts_at_s"] >= shifted["remaining_horizon"]["starts_at_s"]
    assert shifted_replacement["ends_at_s"] <= shifted["remaining_horizon"]["ends_at_s"]

    assert Enum.map(shifted["source_candidate_activities"], & &1["id"]) == [
             shifted_replacement["id"]
           ]

    refute Enum.any?(shifted["source_candidate_activities"], &(&1["id"] == "stale_prior_access"))
    refute Enum.any?(shifted["activities"], &(&1["id"] == "stale_prior_access"))

    assert Enum.any?(
             shifted["source_candidate_diff_report"]["invalidated_candidates"],
             &(&1["id"] == "stale_prior_access")
           )

    assert activity(before, "executed_contact") == activity(shifted, "executed_contact")
    assert activity(before, "locked_contact") == activity(shifted, "locked_contact")
    assert activity(shifted, "executed_contact")["repair"]["action"] == "preserved_executed"
    assert activity(shifted, "locked_contact")["repair"]["action"] == "preserved"

    assert %{
             "preserved_executed_activity_ids" => ["executed_contact"],
             "preserved_locked_or_approved_activity_ids" => ["locked_contact"]
           } = get_in(shifted, ["repair_metadata", "timeline_protection"])

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(shifted)
  end

  test "rejects atom/string execution-path collisions before selection" do
    colliding_request =
      "colliding_selector_snapshot"
      |> repair_request(@shifted_position, @shifted_velocity)
      |> update_in([:candidate_refresh_request], fn refresh_request ->
        refresh_request
        |> Map.delete("execution_path")
        |> Map.put(:execution_path, "candidate_refresh_run_v1")
        |> Map.put("execution_path", nil)
      end)

    error =
      assert_raise ArgumentError, fn ->
        CampaignPlanner.repair(colliding_request)
      end

    assert error.message ==
             "invalid repair candidate_refresh_request: {:duplicate_normalized_key, \"$\", \"execution_path\"}"

    refute error.message =~ "campaign_repair.v2"
  end

  test "a selected non-map refresh preserves public validate-input typing and returns no repair" do
    invalid_request =
      "invalid_shifted_snapshot"
      |> repair_request(@shifted_position, @shifted_velocity)
      |> put_in([:candidate_refresh_request, "candidate_refresh"], "malformed_refresh")

    error =
      assert_raise ArgumentError, fn ->
        CampaignPlanner.repair(invalid_request)
      end

    assert error.message =~
             "{:candidate_refresh_execution_failed, :validate_input, {:invalid_input, :candidate_refresh}}"

    refute error.message =~ "campaign_repair.v2"
  end

  defp repair_request(snapshot_id, position_km, velocity_km_s) do
    %{
      prior_plan: prior_plan(),
      realized_state: %{
        activities: [
          %{id: "executed_contact", status: "executed"},
          %{id: "missed_contact", status: "missed", reason: "station outage"}
        ]
      },
      current_epoch_s: 0.0,
      remaining_horizon: @horizon,
      generated_at: @generated_at,
      candidate_refresh_request: %{
        "execution_path" => "candidate_refresh_run_v1",
        "candidate_refresh" => refresh_input(snapshot_id, position_km, velocity_km_s)
      }
    }
  end

  defp prior_plan do
    base_plan(%{
      "planning_horizon" => %{"duration_s" => 7_200.0, "output_step_s" => 10.0},
      "activities" => [
        contact("executed_contact", 100.0, 160.0),
        contact("missed_contact", 500.0, 560.0),
        contact("locked_contact", 4_000.0, 4_060.0)
        |> Map.put("metadata", %{"approval_status" => "approved", "locked" => true})
      ],
      "candidate_activities" => [stale_candidate()]
    })
  end

  defp refresh_input(snapshot_id, position_km, velocity_km_s) do
    %{
      "accepted_planning_state" =>
        accepted_planning_state(snapshot_id, position_km, velocity_km_s),
      "current_epoch_s" => 0.0,
      "remaining_horizon" => @horizon,
      "spacecraft" => @spacecraft,
      "ground_station" => @station,
      "constraints" => %{"avoid_eclipse" => false},
      "scoring_policy" => %{
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"repair_case" => "domain_13_shifted_access"},
      "prior_candidate_activities" => [stale_candidate()]
    }
  end

  defp accepted_planning_state(snapshot_id, position_km, velocity_km_s) do
    %{
      "schema_version" => 1,
      "schema_contract" => "accepted_planning_state.v1",
      "artifact_type" => "accepted_planning_state",
      "snapshot_id" => snapshot_id,
      "accepted_at" => DateTime.to_iso8601(@generated_at),
      "spacecraft_states" => [
        %{
          "spacecraft_id" => @spacecraft["spacecraft_id"],
          "scenario_id" => @spacecraft["scenario_id"],
          "epoch" => %{"seconds_since_j2000" => 0.0, "time_scale" => "tdb"},
          "frame" => "earth_inertial_j2000",
          "state_vector" => %{
            "position_km" => position_km,
            "velocity_km_s" => velocity_km_s
          },
          "source" => %{"system" => "operator_import", "source_id" => snapshot_id},
          "provenance" => %{
            "trust_boundary" => "operator_supplied",
            "source_snapshot_id" => snapshot_id
          },
          "quality" => %{"level" => "accepted"}
        }
      ],
      "maneuver_execution_deltas" => [],
      "source" => %{"system" => "cadence_snapshot", "source_id" => snapshot_id},
      "quality" => %{"level" => "planning_accepted"},
      "provenance" => %{
        "created_by" => "repair_shifted_access_test",
        "source_snapshot_id" => snapshot_id
      }
    }
  end

  defp stale_candidate do
    contact("stale_prior_access", 1_000.0, 1_100.0)
    |> Map.put("source_window_id", "window:stale_prior_access")
  end

  defp contact(id, starts_at_s, ends_at_s) do
    %{
      "id" => id,
      "type" => "downlink",
      "direction" => "downlink",
      "scenario_id" => @spacecraft["scenario_id"],
      "ground_station_id" => @station["ground_station_id"],
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => 10.0,
      "source_window_id" => "window:#{id}",
      "source_window" => %{"id" => "window:#{id}", "type" => "ground_station_access"},
      "cadence_import" => %{
        "activity_type" => "contact",
        "external_id" => id,
        "schema_contract" => "proposed_contact.v1"
      }
    }
  end

  defp captured_policy(repair) do
    get_in(repair, [
      "source_candidate_refresh_assumptions",
      "model_assumptions",
      ExecutionPolicy.reserved_key()
    ])
  end

  defp stable_policy(policy) do
    policy
    |> Map.drop(["policy_fingerprint"])
    |> update_in(["initial_state"], fn state ->
      Map.drop(state, ["position_km", "velocity_km_s", "snapshot_id"])
    end)
  end

  defp access_windows(repair), do: repair["source_refreshed_windows"]["access_windows"]

  defp window_timings(windows) do
    Enum.map(windows, &Map.take(&1, ["starts_at_s", "ends_at_s"]))
  end

  defp shifted_replacement(repair) do
    replacement_id =
      repair["deltas"]
      |> Enum.find(&(&1["activity_id"] == "missed_contact"))
      |> Map.fetch!("replacement_activity_id")

    activity(repair, replacement_id)
  end

  defp activity(repair, id), do: Enum.find(repair["activities"], &(&1["id"] == id))
end
