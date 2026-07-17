defmodule OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtures do
  alias OrbitalDynamics.{CandidateRefresh, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures,
    only: [result_set: 1]

  def candidate_refresh_resource_projection_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_resource_projection_fixture())
  end

  def candidate_refresh_resource_projection_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_resource_projection_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_resource_projection_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-resource-projection-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_resource_projection_report" => [
        candidate_refresh_resource_projection_report()
      ]
    }
  end

  def candidate_refresh_resource_projection_report do
    %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "downlink_shortfall",
          "resource_pressure_types" => ["downlink_shortfall", "storage_pressure"],
          "first_resource_pressure_activity_id" => "dl_pressure_1",
          "first_resource_pressure_direction" => "Down Link",
          "first_resource_pressure_ground_station_id" => "equator_prime",
          "source_window_id" => "flow_access_window_1",
          "station_calendar_entry_id" => "station_flow_window_1",
          "station_calendar_provider_id" => "ops_calendar_flow",
          "station_calendar_provider_entry_id" => "provider_flow_window_1"
        },
        %{
          "spacecraft_id" => "leo_2",
          "resource_pressure_status" => "storage_shortfall",
          "resource_pressure_types" => ["storage_shortfall"],
          "source_activity_ids" => ["imaging_1", "imaging_2"],
          "direction" => "tracking_pass",
          "ground_station_id" => "dss_43",
          "source_window" => %{"id" => "tracking_window_1"},
          "source_station_calendar_entry" => %{
            "station_calendar_entry_id" => "station_tracking_window_1",
            "station_calendar_provider_id" => "ops_calendar_tracking",
            "station_calendar_provider_entry_id" => "provider_tracking_window_1"
          }
        }
      ],
      "invalid_activity_inputs" => [%{"activity_id" => "bad_activity"}],
      "invalid_resource_summary_inputs" => [%{"spacecraft_id" => "bad_resource_summary"}],
      "resource_pressure_status_counts" => %{"stale_status" => 99},
      "resource_pressure_activity_ids_by_status" => %{"stale_status" => ["stale_activity"]},
      "provenance" => %{"trust_boundary" => "generated_resource_projection_fixture"}
    }
  end

  def candidate_refresh_quality_gate_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_quality_gate_fixture())
  end

  def candidate_refresh_quality_gate_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_quality_gate_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_quality_gate_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-quality-gate-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_quality_gate_report" => candidate_refresh_quality_gate_report()
    }
  end

  def candidate_refresh_quality_gate_report do
    quality_gate_resource_pressure_fixture()
    |> Map.put("provenance", %{"trust_boundary" => "generated_quality_gate_fixture"})
  end

  def candidate_refresh_operational_readiness_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_operational_readiness_fixture())
  end

  def candidate_refresh_operational_readiness_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_operational_readiness_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_operational_readiness_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-operational-readiness-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_operational_readiness_report" => candidate_refresh_operational_readiness_report()
    }
  end

  def candidate_refresh_operational_readiness_report do
    operational_readiness_resource_pressure_fixture()
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_operational_readiness_fixture"
    })
  end

  def operational_readiness_resource_pressure_fixture do
    read_json!("study_results/operational_readiness_resource_pressure_v1.json")
  end

  def quality_gate_resource_pressure_fixture do
    read_json!("study_results/quality_gate_resource_pressure_v1.json")
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
