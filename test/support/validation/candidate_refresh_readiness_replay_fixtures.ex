defmodule OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtures do
  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Validation}

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

  def candidate_refresh_operational_readiness_selection_challenge_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_operational_readiness_selection_challenge_fixture()
    )
  end

  def candidate_refresh_operational_readiness_selection_challenge_fixture do
    operational_readiness_selection_result_set()
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_operational_readiness_selection_challenge_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_operational_readiness_selection_challenge_request do
    blocked_contact_id = "leo_1_downlink_equator_prime_1"
    cross_spacecraft_contact_id = "leo_2_downlink_dss_43_1"

    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-operational-readiness-selection-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [
          %{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"},
          %{"spacecraft_id" => "sat_2", "scenario_id" => "leo_2"}
        ],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"},
        "source_operational_readiness_report" =>
          candidate_refresh_operational_readiness_selection_challenge_report(
            blocked_contact_id,
            cross_spacecraft_contact_id
          )
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{"min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "prior_candidate_activities" => [
        %{
          "id" => blocked_contact_id,
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
        }
      ]
    }
  end

  def candidate_refresh_operational_readiness_selection_challenge_report(
        blocked_contact_id,
        cross_spacecraft_contact_id
      ) do
    operational_readiness_resource_pressure_fixture()
    |> Map.put(
      "report_id",
      "operational_readiness:contact_selection:stale_scope_challenge"
    )
    |> Map.put("source_artifact_id", "readiness-selection-challenge")
    |> put_in(
      ["evidence", "resource_blocked_contact_ids_by_spacecraft_id"],
      %{"sat_1" => [blocked_contact_id, cross_spacecraft_contact_id]}
    )
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_operational_readiness_selection_challenge"
    })
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

  defp operational_readiness_selection_result_set do
    ResultSet.new!(%{
      study_id: :validation,
      trajectory_results: [],
      event_results: [
        access_event_result(:leo_1, :equator_prime, 300.0, 420.0),
        access_event_result(:leo_2, :dss_43, 320.0, 440.0)
      ],
      errors: [],
      assumptions: %{
        propagator: OrbitalDynamics.Propagators.TwoBody,
        outputs: [:access_windows]
      },
      metadata: %{}
    })
  end

  defp access_event_result(scenario_id, ground_station_id, starts_at_s, ends_at_s) do
    %{
      scenario_id: scenario_id,
      event_type: :ground_station_access,
      events: [
        %{
          type: :ground_station_access,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            max_elevation_deg: 70.0,
            minimum_elevation_deg: 5.0,
            sample_count: 4
          }
        }
      ],
      source: %{ground_station_id: ground_station_id}
    }
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
