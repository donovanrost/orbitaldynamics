defmodule OrbitalDynamics.CampaignPlanner.TestSupport do
  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.CampaignPlanner.MissionState

  def repair(plan_overrides, opts) do
    request =
      opts
      |> Map.new()
      |> Map.put(:prior_plan, base_plan(plan_overrides))

    CampaignPlanner.repair(request)
  end

  def strategy(prior_plan, opts) do
    request =
      opts
      |> Map.new()
      |> Map.put(:prior_plan, prior_plan)
      |> Map.put_new(:remaining_horizon, %{"starts_at_s" => 0.0, "ends_at_s" => 2_000.0})
      |> Map.put_new(:generated_at, ~U[2026-05-14 00:00:00Z])

    CampaignPlanner.strategy(request)
  end

  def branch(strategy_artifact, branch_id) do
    Enum.find(strategy_artifact["branches"], &(&1["branch_id"] == branch_id))
  end

  def base_plan(overrides) do
    Map.merge(
      %{
        "schema_version" => 1,
        "generated_at" => "2026-05-13T00:00:00Z",
        "planner" => "OrbitalDynamics.CampaignPlanner.V1",
        "plan_id" => "campaign_plan:test:2026-05-13T00:00:00Z",
        "study_id" => "test",
        "planning_horizon" => %{"duration_s" => 1_000.0, "output_step_s" => 60.0},
        "activities" => [],
        "candidate_activities" => [],
        "assumptions" => %{
          "constraints" => %{},
          "scoring_policy" => %{}
        },
        "provenance" => %{},
        "ranking_explanation" => %{
          "policy" => %{
            "target_value_weight" => 1.0,
            "contact_value_weight" => 0.2,
            "schedule_churn_cost_weight" => 100.0,
            "schedule_move_cost_weight" => 0.01
          }
        }
      },
      overrides
    )
  end

  def downlink(id, starts_at_s, ends_at_s) do
    %{
      "id" => id,
      "type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => 10.0
    }
  end

  def refreshed_downlink(id, starts_at_s, ends_at_s) do
    id
    |> downlink(starts_at_s, ends_at_s)
    |> Map.merge(%{
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
      "source_window" => %{
        "id" => "window:leo_1:ground_station_access:equator_prime:1",
        "type" => "ground_station_access"
      },
      "score_terms" => %{"contact_value" => 10.0},
      "cadence_import" => %{
        "activity_type" => "contact",
        "external_id" => id,
        "schema_contract" => "proposed_contact.v1"
      },
      "direction" => "downlink",
      "estimated_throughput_mb" => ends_at_s - starts_at_s
    })
  end

  def observe(id, scenario_id, target_id, starts_at_s, ends_at_s, score) do
    %{
      "id" => id,
      "type" => "observe",
      "scenario_id" => scenario_id,
      "target_id" => target_id,
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => score
    }
  end

  def maneuver(id, epoch_s) do
    %{
      "id" => id,
      "type" => "maneuver",
      "scenario_id" => "leo_1",
      "starts_at_s" => epoch_s,
      "ends_at_s" => epoch_s + 30.0,
      "duration_s" => 30.0,
      "score" => 5.0
    }
  end

  def health_check(id, scenario_id, starts_at_s, ends_at_s) do
    %{
      "id" => id,
      "type" => "health_check",
      "scenario_id" => scenario_id,
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => 1.0
    }
  end

  def mission_state(objectives, opts \\ []) do
    %MissionState{
      snapshot_id: "ops-snapshot",
      captured_at: "2026-05-14T00:00:00Z",
      spacecraft_states: [%{scenario_id: "leo_1", mode: "nominal"}],
      ground_network: [%{ground_station_id: "equator_prime", status: "available"}],
      resources: Keyword.get(opts, :resources, %{"fuel_margin" => 1.0}),
      objectives: objectives,
      prior_plan_history: ["campaign_plan:test:2026-05-13T00:00:00Z"],
      operational_status: %{"cadence_source" => "future"},
      assumptions: %{"resource_model" => "thin_summary"}
    }
  end

  def branch_candidate_refresh_request do
    %{
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["access_windows", "target_visibility", "eclipses"],
      "ground_stations" => [
        %{
          "id" => "equator_prime",
          "latitude_deg" => 0.0,
          "longitude_deg" => 0.0,
          "minimum_elevation_deg" => 5.0
        }
      ],
      "sun_direction" => [1.0, 0.0, 0.0],
      "candidate_refresh" => %{
        "accepted_planning_state" => %{
          "schema_version" => 1,
          "artifact_type" => "accepted_planning_state",
          "snapshot_id" => "ops-state-branch",
          "accepted_at" => "2026-05-14T00:00:00Z",
          "spacecraft_states" => [
            %{
              "spacecraft_id" => "sat_1",
              "scenario_id" => "leo_1",
              "dry_mass_kg" => 250.0,
              "epoch" => %{"seconds_since_j2000" => 0.0, "time_scale" => "tdb"},
              "frame" => "earth_inertial_j2000",
              "state_vector" => %{
                "position_km" => [7000.0, 0.0, 0.0],
                "velocity_km_s" => [0.0, 7.546053290107542, 0.0]
              },
              "source" => %{"system" => "operator_import"},
              "quality" => %{"level" => "accepted"}
            }
          ],
          "maneuver_execution_deltas" => [],
          "source" => %{"system" => "cadence_snapshot"},
          "quality" => %{"level" => "planning_accepted"},
          "provenance" => %{"created_by" => "campaign_planner_test"}
        },
        "current_epoch_s" => 0.0,
        "remaining_horizon" => %{
          "starts_at_s" => 0.0,
          "ends_at_s" => 600.0,
          "output_step_s" => 60.0
        },
        "targets" => [
          %{
            "id" => "target_a",
            "latitude_deg" => 0.0,
            "longitude_deg" => 0.0,
            "minimum_elevation_deg" => 10.0,
            "priority" => 2.0
          }
        ],
        "constraints" => %{"avoid_eclipse" => false, "min_activity_duration_s" => 60.0},
        "scoring_policy" => %{
          "contact_value_weight" => 0.2,
          "target_value_weight" => 1.0,
          "downlink_rate_mb_s" => 2.0
        },
        "model_assumptions" => %{"candidate_refresh_level" => "branch_generated_v1"}
      }
    }
  end

  def mission_state_with_refresh_inputs do
    %{
      snapshot_id: "ops-rich",
      captured_at: "2026-05-14T00:00:00Z",
      spacecraft_states: [
        %{
          scenario_id: "leo_1",
          spacecraft_id: "sat_1",
          dry_mass_kg: 250.0,
          epoch: %{seconds_since_j2000: 0.0, time_scale: "tdb"},
          frame: "earth_inertial_j2000",
          state_vector: %{
            position_km: [7000.0, 0.0, 0.0],
            velocity_km_s: [0.0, 7.546053290107542, 0.0]
          },
          source: %{system: "mission_state"},
          quality: %{level: "accepted"}
        }
      ],
      ground_stations: [
        %{
          id: "equator_prime",
          latitude_deg: 0.0,
          longitude_deg: 0.0,
          minimum_elevation_deg: 5.0
        }
      ],
      targets: [
        %{
          id: "target_a",
          latitude_deg: 0.0,
          longitude_deg: 0.0,
          minimum_elevation_deg: 10.0,
          priority: 2.0
        }
      ],
      resources: %{"fuel_margin" => 1.0},
      objectives: [],
      candidate_refresh_defaults: %{
        output_step_s: 60.0,
        constraints: %{avoid_eclipse: false, min_activity_duration_s: 60.0},
        scoring_policy: %{downlink_rate_mb_s: 2.0, target_value_weight: 1.0}
      },
      assumptions: %{"resource_model" => "thin_summary"}
    }
  end
end
