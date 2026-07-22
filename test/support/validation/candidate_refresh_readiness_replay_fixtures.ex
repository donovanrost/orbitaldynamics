defmodule OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtures do
  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Validation}
  alias OrbitalDynamics.Validation.QualityGateFixtures

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

  def candidate_refresh_quality_gate_unavailable_resource_selection_challenge_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_quality_gate_unavailable_resource_selection_challenge_fixture()
    )
  end

  def candidate_refresh_quality_gate_unavailable_resource_selection_challenge_fixture do
    unavailable_resource_selection_result_set()
    |> CandidateRefresh.build(
      candidate_refresh:
        candidate_refresh_quality_gate_unavailable_resource_selection_challenge_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_quality_gate_unavailable_resource_selection_challenge_request do
    blocked_contact_id = "leo_1_downlink_equator_prime_1"
    cross_spacecraft_contact_id = "leo_2_downlink_dss_43_1"

    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-quality-gate-selection-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [
          %{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"},
          %{"spacecraft_id" => "sat_2", "scenario_id" => "leo_2"}
        ],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"},
        "operational_quality_gate_unavailable_resource_summary" =>
          candidate_refresh_quality_gate_unavailable_resource_selection_challenge_summary(
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

  def candidate_refresh_quality_gate_unavailable_resource_selection_challenge_summary(
        blocked_contact_id,
        cross_spacecraft_contact_id
      ) do
    blocked_contact_ids = [blocked_contact_id, cross_spacecraft_contact_id]

    QualityGateFixtures.operational_quality_gate_unavailable_resource_summary_fixture()
    |> Map.merge(%{
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source_artifact_id" => "quality-gate-selection-challenge",
      "source_quality_gate_report_id" => "quality_gate:unavailable_resource_selection_challenge",
      "source_readiness_report_id" => "operational_readiness:quality_gate_selection_challenge",
      "resource_blocking_dimension_counts" => %{"antenna" => 1},
      "blocked_contact_ids_by_blocking_dimension" => %{
        "antenna" => blocked_contact_ids
      },
      "blocked_contact_ids_by_spacecraft_id" => %{
        "sat_1" => blocked_contact_ids
      },
      "blocked_contact_ids_by_status" => %{
        "review_required" => blocked_contact_ids
      },
      "provenance" => %{
        "trust_boundary" => "generated_quality_gate_selection_challenge"
      }
    })
  end

  def candidate_refresh_operational_readiness_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_operational_readiness_fixture())
  end

  def candidate_refresh_candidate_scoped_readiness_selection_challenge_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_candidate_scoped_readiness_selection_challenge_fixture()
    )
  end

  def candidate_refresh_candidate_scoped_readiness_selection_challenge_fixture do
    exact_activity_selection_result_set()
    |> CandidateRefresh.build(
      candidate_refresh:
        candidate_refresh_candidate_scoped_readiness_selection_challenge_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_candidate_scoped_readiness_nonmatching_challenge_fixture do
    request =
      candidate_refresh_candidate_scoped_readiness_selection_challenge_request()
      |> put_in(
        ["accepted_planning_state", "operational_readiness_report"],
        candidate_refresh_candidate_scoped_readiness_selection_challenge_report(
          "stale_observe_target_a_1"
        )
      )

    exact_activity_selection_result_set()
    |> CandidateRefresh.build(
      candidate_refresh: request,
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_candidate_scoped_readiness_selection_challenge_request do
    blocked_candidate_id = "leo_1_observe_target_a_1"

    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-candidate-scoped-readiness-selection-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"},
        "operational_readiness_report" =>
          candidate_refresh_candidate_scoped_readiness_selection_challenge_report(
            blocked_candidate_id
          )
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "prior_candidate_activities" => [
        %{
          "id" => blocked_candidate_id,
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 120.0,
          "ends_at_s" => 240.0
        }
      ]
    }
  end

  def candidate_refresh_candidate_scoped_readiness_selection_challenge_report(candidate_id) do
    %{
      "schema_contract" => "cadence_import_manifest.v1",
      "model" => "candidate_scoped_readiness_selection_challenge_manifest",
      "manifest_id" => "manifest:#{candidate_id}",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => candidate_id,
      "model_limits" => ["adapter_handoff_only"],
      "rows" => [
        %{
          "id" => "import:#{candidate_id}",
          "rank" => 1,
          "import_action" => "review_candidate_activity",
          "import_status" => "blocked_missing_cadence_import",
          "cadence_import_status" => "invalid"
        }
      ]
    }
    |> OrbitalDynamics.operational_readiness_report()
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_candidate_scoped_readiness_selection_challenge"
    })
  end

  def candidate_refresh_candidate_scoped_quality_gate_selection_challenge_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_candidate_scoped_quality_gate_selection_challenge_fixture()
    )
  end

  def candidate_refresh_candidate_scoped_quality_gate_selection_challenge_fixture do
    exact_activity_selection_result_set()
    |> CandidateRefresh.build(
      candidate_refresh:
        candidate_refresh_candidate_scoped_quality_gate_selection_challenge_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_candidate_scoped_quality_gate_nonmatching_challenge_fixture do
    request =
      candidate_refresh_candidate_scoped_quality_gate_selection_challenge_request()
      |> put_in(
        ["accepted_planning_state", "quality_gate_report"],
        candidate_refresh_candidate_scoped_quality_gate_selection_challenge_report(
          "stale_observe_target_a_1"
        )
      )

    exact_activity_selection_result_set()
    |> CandidateRefresh.build(
      candidate_refresh: request,
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_candidate_scoped_quality_gate_selection_challenge_request do
    blocked_candidate_id = "leo_1_observe_target_a_1"

    candidate_refresh_candidate_scoped_readiness_selection_challenge_request()
    |> Map.update!("accepted_planning_state", fn accepted_state ->
      accepted_state
      |> Map.drop(["operational_readiness_report"])
      |> Map.put(
        "snapshot_id",
        "ops-state-candidate-scoped-quality-gate-selection-challenge"
      )
      |> Map.put(
        "quality_gate_report",
        candidate_refresh_candidate_scoped_quality_gate_selection_challenge_report(
          blocked_candidate_id
        )
      )
    end)
  end

  def candidate_refresh_candidate_scoped_quality_gate_selection_challenge_report(candidate_id) do
    %{
      "schema_contract" => "cadence_import_manifest.v1",
      "model" => "candidate_scoped_quality_gate_selection_challenge_manifest",
      "manifest_id" => "manifest:#{candidate_id}",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => candidate_id,
      "model_limits" => ["adapter_handoff_only"],
      "rows" => [
        %{
          "id" => "import:#{candidate_id}",
          "rank" => 1,
          "import_action" => "review_candidate_activity",
          "import_status" => "blocked_missing_cadence_import",
          "cadence_import_status" => "invalid"
        }
      ]
    }
    |> OrbitalDynamics.operational_quality_gate_report()
    |> Map.put("provenance", %{
      "trust_boundary" => "generated_candidate_scoped_quality_gate_selection_challenge"
    })
  end

  def candidate_refresh_operational_readiness_selection_challenge_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(
      candidate_refresh_operational_readiness_selection_challenge_fixture()
    )
  end

  def candidate_refresh_operational_readiness_selection_challenge_fixture do
    unavailable_resource_selection_result_set()
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
      "operational_readiness:resource_projection_report.v1:readiness-selection-challenge"
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

  defp unavailable_resource_selection_result_set do
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

  defp exact_activity_selection_result_set do
    ResultSet.new!(%{
      study_id: :validation,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :target_visibility,
          events: [
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 80.0,
                minimum_elevation_deg: 10.0,
                sample_count: 3
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        access_event_result(:leo_1, :equator_prime, 300.0, 420.0)
      ],
      errors: [],
      assumptions: %{
        propagator: OrbitalDynamics.Propagators.TwoBody,
        outputs: [:target_visibility, :access_windows]
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
