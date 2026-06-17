defmodule OrbitalDynamics.CandidateRefresh.ResourceProjectionReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResourceProjection,
    ResultSet,
    Schema
  }

  test "source report summary aggregates resource projection pressure routing maps" do
    refresh = %{
      "source_resource_projection_report" => [
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
          "ground_station_counts" => %{"stale_station" => 99},
          "resource_projection_spacecraft_counts" => %{"stale_spacecraft" => 99},
          "resource_pressure_activity_ids_by_status" => %{"stale_status" => ["stale_activity"]},
          "resource_pressure_activity_ids_by_type" => %{"stale_type" => ["stale_activity"]},
          "resource_pressure_activity_ids_by_ground_station" => %{
            "stale_station" => ["stale_activity"]
          },
          "resource_pressure_activity_ids_by_spacecraft" => %{
            "stale_spacecraft" => ["stale_activity"]
          },
          "resource_pressure_source_window_ids_by_status" => %{
            "stale_status" => ["stale_window"]
          },
          "resource_pressure_station_calendar_entry_ids_by_status" => %{
            "stale_status" => ["stale_station_entry"]
          },
          "resource_pressure_station_calendar_provider_ids_by_status" => %{
            "stale_status" => ["stale_provider"]
          },
          "resource_pressure_station_calendar_provider_entry_ids_by_status" => %{
            "stale_status" => ["stale_provider_entry"]
          },
          "provenance" => %{"trust_boundary" => "ops_resource_projection"}
        }
      ]
    }

    expected_pressure_direction_routing = %{
      "downlink" => %{
        "pressure_count" => 1,
        "activity_ids" => ["dl_pressure_1"]
      },
      "tracking" => %{
        "pressure_count" => 1,
        "activity_ids" => ["imaging_1", "imaging_2"]
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_resource_projection_contract" => "resource_projection_report.v1",
             "source_report_resource_projection_count" => 1,
             "source_report_resource_projection_row_count" => 4,
             "source_report_resource_projection_paths" => ["source_resource_projection_report[0]"],
             "source_report_resource_projection_projected_resource_count" => 2,
             "source_report_resource_projection_invalid_activity_input_count" => 1,
             "source_report_resource_projection_invalid_resource_summary_input_count" => 1,
             "source_report_resource_projection_invalid_activity_input_ids" => [
               "bad_activity"
             ],
             "source_report_resource_projection_invalid_resource_summary_input_ids" => [
               "bad_resource_summary"
             ],
             "source_report_resource_projection_resource_pressure_status_counts" => %{
               "downlink_shortfall" => 1,
               "storage_shortfall" => 1
             },
             "source_report_resource_projection_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_report_resource_projection_spacecraft_counts" => %{
               "leo_1" => 1,
               "leo_2" => 1
             },
             "source_report_resource_projection_resource_pressure_type_counts" => %{
               "downlink_shortfall" => 1,
               "storage_pressure" => 1,
               "storage_shortfall" => 1
             },
             "source_report_resource_projection_resource_pressure_activity_id_counts" => %{
               "dl_pressure_1" => 1,
               "imaging_1" => 1,
               "imaging_2" => 1
             },
             "source_report_resource_projection_resource_pressure_activity_ids_by_status" => %{
               "downlink_shortfall" => ["dl_pressure_1"],
               "storage_shortfall" => ["imaging_1", "imaging_2"]
             },
             "source_report_resource_projection_resource_pressure_activity_ids_by_type" => %{
               "downlink_shortfall" => ["dl_pressure_1"],
               "storage_pressure" => ["dl_pressure_1"],
               "storage_shortfall" => ["imaging_1", "imaging_2"]
             },
             "source_report_resource_projection_resource_pressure_activity_ids_by_ground_station" =>
               %{
                 "dss_43" => ["imaging_1", "imaging_2"],
                 "equator_prime" => ["dl_pressure_1"]
               },
             "source_report_resource_projection_resource_pressure_activity_ids_by_spacecraft" =>
               %{
                 "leo_1" => ["dl_pressure_1"],
                 "leo_2" => ["imaging_1", "imaging_2"]
               },
             "source_report_resource_projection_resource_pressure_direction_counts" => %{
               "downlink" => 1,
               "tracking" => 1
             },
             "source_report_resource_projection_resource_pressure_directions" => [
               "downlink",
               "tracking"
             ],
             "source_report_resource_projection_resource_pressure_activity_ids_by_direction" => %{
               "downlink" => ["dl_pressure_1"],
               "tracking" => ["imaging_1", "imaging_2"]
             },
             "source_report_resource_projection_resource_pressure_direction_routing" =>
               ^expected_pressure_direction_routing,
             "source_report_resource_projection_branch_local_resource_projection_pressure" =>
               true,
             "source_report_resource_projection_branch_local_projected_resource_pressure" => true,
             "source_report_resource_projection_branch_local_invalid_resource_projection_pressure" =>
               true,
             "source_report_resource_projection_branch_local_activity_pressure" => true,
             "source_report_resource_projection_resource_pressure_ground_station_ids_by_type" =>
               %{
                 "downlink_shortfall" => ["equator_prime"],
                 "storage_pressure" => ["equator_prime"],
                 "storage_shortfall" => ["dss_43"]
               },
             "source_report_resource_projection_resource_pressure_source_window_ids_by_status" =>
               %{
                 "downlink_shortfall" => ["flow_access_window_1"],
                 "storage_shortfall" => ["tracking_window_1"]
               },
             "source_report_resource_projection_resource_pressure_source_window_ids_by_type" => %{
               "downlink_shortfall" => ["flow_access_window_1"],
               "storage_pressure" => ["flow_access_window_1"],
               "storage_shortfall" => ["tracking_window_1"]
             },
             "source_report_resource_projection_resource_pressure_station_calendar_entry_ids_by_status" =>
               %{
                 "downlink_shortfall" => ["station_flow_window_1"],
                 "storage_shortfall" => ["station_tracking_window_1"]
               },
             "source_report_resource_projection_resource_pressure_station_calendar_entry_ids_by_type" =>
               %{
                 "downlink_shortfall" => ["station_flow_window_1"],
                 "storage_pressure" => ["station_flow_window_1"],
                 "storage_shortfall" => ["station_tracking_window_1"]
               },
             "source_report_resource_projection_resource_pressure_station_calendar_provider_ids_by_status" =>
               %{
                 "downlink_shortfall" => ["ops_calendar_flow"],
                 "storage_shortfall" => ["ops_calendar_tracking"]
               },
             "source_report_resource_projection_resource_pressure_station_calendar_provider_ids_by_type" =>
               %{
                 "downlink_shortfall" => ["ops_calendar_flow"],
                 "storage_pressure" => ["ops_calendar_flow"],
                 "storage_shortfall" => ["ops_calendar_tracking"]
               },
             "source_report_resource_projection_resource_pressure_station_calendar_provider_entry_ids_by_status" =>
               %{
                 "downlink_shortfall" => ["provider_flow_window_1"],
                 "storage_shortfall" => ["provider_tracking_window_1"]
               },
             "source_report_resource_projection_resource_pressure_station_calendar_provider_entry_ids_by_type" =>
               %{
                 "downlink_shortfall" => ["provider_flow_window_1"],
                 "storage_pressure" => ["provider_flow_window_1"],
                 "storage_shortfall" => ["provider_tracking_window_1"]
               },
             "source_reports" => %{
               "resource_projection_report" => %{
                 "projected_resource_count" => 2,
                 "invalid_activity_input_count" => 1,
                 "invalid_resource_summary_input_count" => 1,
                 "invalid_activity_input_ids" => ["bad_activity"],
                 "invalid_resource_summary_input_ids" => ["bad_resource_summary"],
                 "resource_pressure_status_counts" => %{
                   "downlink_shortfall" => 1,
                   "storage_shortfall" => 1
                 },
                 "resource_pressure_direction_counts" => %{
                   "downlink" => 1,
                   "tracking" => 1
                 },
                 "resource_pressure_directions" => [
                   "downlink",
                   "tracking"
                 ],
                 "resource_pressure_activity_ids_by_direction" => %{
                   "downlink" => ["dl_pressure_1"],
                   "tracking" => ["imaging_1", "imaging_2"]
                 },
                 "resource_pressure_direction_routing" => ^expected_pressure_direction_routing,
                 "resource_pressure_activity_ids_by_status" => %{
                   "downlink_shortfall" => ["dl_pressure_1"],
                   "storage_shortfall" => ["imaging_1", "imaging_2"]
                 },
                 "resource_pressure_activity_ids_by_type" => %{
                   "downlink_shortfall" => ["dl_pressure_1"],
                   "storage_pressure" => ["dl_pressure_1"],
                   "storage_shortfall" => ["imaging_1", "imaging_2"]
                 },
                 "resource_pressure_activity_ids_by_ground_station" => %{
                   "dss_43" => ["imaging_1", "imaging_2"],
                   "equator_prime" => ["dl_pressure_1"]
                 },
                 "resource_pressure_activity_ids_by_spacecraft" => %{
                   "leo_1" => ["dl_pressure_1"],
                   "leo_2" => ["imaging_1", "imaging_2"]
                 },
                 "resource_pressure_ground_station_ids_by_type" => %{
                   "downlink_shortfall" => ["equator_prime"],
                   "storage_pressure" => ["equator_prime"],
                   "storage_shortfall" => ["dss_43"]
                 },
                 "resource_pressure_source_window_ids_by_status" => %{
                   "downlink_shortfall" => ["flow_access_window_1"],
                   "storage_shortfall" => ["tracking_window_1"]
                 },
                 "resource_pressure_source_window_ids_by_type" => %{
                   "downlink_shortfall" => ["flow_access_window_1"],
                   "storage_pressure" => ["flow_access_window_1"],
                   "storage_shortfall" => ["tracking_window_1"]
                 },
                 "resource_pressure_station_calendar_entry_ids_by_status" => %{
                   "downlink_shortfall" => ["station_flow_window_1"],
                   "storage_shortfall" => ["station_tracking_window_1"]
                 },
                 "resource_pressure_station_calendar_entry_ids_by_type" => %{
                   "downlink_shortfall" => ["station_flow_window_1"],
                   "storage_pressure" => ["station_flow_window_1"],
                   "storage_shortfall" => ["station_tracking_window_1"]
                 },
                 "resource_pressure_station_calendar_provider_entry_ids_by_status" => %{
                   "downlink_shortfall" => ["provider_flow_window_1"],
                   "storage_shortfall" => ["provider_tracking_window_1"]
                 },
                 "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
                   "downlink_shortfall" => ["provider_flow_window_1"],
                   "storage_pressure" => ["provider_flow_window_1"],
                   "storage_shortfall" => ["provider_tracking_window_1"]
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_resource_projection_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.resource_projection_report",
      "contract" => "resource_projection_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 4,
      "source_report_paths" => ["source_resource_projection_report[0]"],
      "projected_resource_count" => 2,
      "invalid_activity_input_count" => 1,
      "invalid_resource_summary_input_count" => 1,
      "invalid_activity_input_ids" => ["bad_activity"],
      "invalid_resource_summary_input_ids" => ["bad_resource_summary"],
      "resource_pressure_status_counts" => %{
        "downlink_shortfall" => 1,
        "storage_shortfall" => 1
      },
      "ground_station_counts" => %{
        "dss_43" => 1,
        "equator_prime" => 1
      },
      "resource_projection_spacecraft_counts" => %{
        "leo_1" => 1,
        "leo_2" => 1
      },
      "resource_pressure_type_counts" => %{
        "downlink_shortfall" => 1,
        "storage_pressure" => 1,
        "storage_shortfall" => 1
      },
      "resource_pressure_activity_id_counts" => %{
        "dl_pressure_1" => 1,
        "imaging_1" => 1,
        "imaging_2" => 1
      },
      "resource_pressure_activity_ids_by_status" => %{
        "downlink_shortfall" => ["dl_pressure_1"],
        "storage_shortfall" => ["imaging_1", "imaging_2"]
      },
      "resource_pressure_activity_ids_by_type" => %{
        "downlink_shortfall" => ["dl_pressure_1"],
        "storage_pressure" => ["dl_pressure_1"],
        "storage_shortfall" => ["imaging_1", "imaging_2"]
      },
      "resource_pressure_activity_ids_by_ground_station" => %{
        "dss_43" => ["imaging_1", "imaging_2"],
        "equator_prime" => ["dl_pressure_1"]
      },
      "resource_pressure_activity_ids_by_spacecraft" => %{
        "leo_1" => ["dl_pressure_1"],
        "leo_2" => ["imaging_1", "imaging_2"]
      },
      "resource_pressure_direction_counts" => %{
        "downlink" => 1,
        "tracking" => 1
      },
      "resource_pressure_directions" => [
        "downlink",
        "tracking"
      ],
      "resource_pressure_activity_ids_by_direction" => %{
        "downlink" => ["dl_pressure_1"],
        "tracking" => ["imaging_1", "imaging_2"]
      },
      "resource_pressure_direction_routing" => expected_pressure_direction_routing,
      "resource_pressure_ground_station_ids_by_type" => %{
        "downlink_shortfall" => ["equator_prime"],
        "storage_pressure" => ["equator_prime"],
        "storage_shortfall" => ["dss_43"]
      },
      "resource_pressure_source_window_ids_by_status" => %{
        "downlink_shortfall" => ["flow_access_window_1"],
        "storage_shortfall" => ["tracking_window_1"]
      },
      "resource_pressure_source_window_ids_by_type" => %{
        "downlink_shortfall" => ["flow_access_window_1"],
        "storage_pressure" => ["flow_access_window_1"],
        "storage_shortfall" => ["tracking_window_1"]
      },
      "resource_pressure_station_calendar_entry_ids_by_status" => %{
        "downlink_shortfall" => ["station_flow_window_1"],
        "storage_shortfall" => ["station_tracking_window_1"]
      },
      "resource_pressure_station_calendar_entry_ids_by_type" => %{
        "downlink_shortfall" => ["station_flow_window_1"],
        "storage_pressure" => ["station_flow_window_1"],
        "storage_shortfall" => ["station_tracking_window_1"]
      },
      "resource_pressure_station_calendar_provider_ids_by_status" => %{
        "downlink_shortfall" => ["ops_calendar_flow"],
        "storage_shortfall" => ["ops_calendar_tracking"]
      },
      "resource_pressure_station_calendar_provider_ids_by_type" => %{
        "downlink_shortfall" => ["ops_calendar_flow"],
        "storage_pressure" => ["ops_calendar_flow"],
        "storage_shortfall" => ["ops_calendar_tracking"]
      },
      "resource_pressure_station_calendar_provider_entry_ids_by_status" => %{
        "downlink_shortfall" => ["provider_flow_window_1"],
        "storage_shortfall" => ["provider_tracking_window_1"]
      },
      "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
        "downlink_shortfall" => ["provider_flow_window_1"],
        "storage_pressure" => ["provider_flow_window_1"],
        "storage_shortfall" => ["provider_tracking_window_1"]
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_resource_projection"],
      "branch_local_resource_projection_pressure" => true,
      "branch_local_projected_resource_pressure" => true,
      "branch_local_invalid_resource_projection_pressure" => true,
      "branch_local_activity_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "resource_projection_source_report_provenance_only",
        "operator_authority" => "not_granted_by_resource_projection_replay_summary",
        "resource_projection" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_resource_projection_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.resource_projection_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_resource_projection_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_resource_projection_contract" => "resource_projection_report.v1",
             "source_report_resource_projection_count" => 1,
             "source_report_resource_projection_row_count" => 4,
             "source_report_resource_projection_paths" => ["source_resource_projection_report[0]"],
             "source_report_resource_projection_projected_resource_count" => 2,
             "source_report_resource_projection_invalid_activity_input_ids" => [
               "bad_activity"
             ],
             "source_report_resource_projection_invalid_resource_summary_input_ids" => [
               "bad_resource_summary"
             ],
             "source_report_resource_projection_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_report_resource_projection_resource_pressure_activity_id_counts" => %{
               "dl_pressure_1" => 1,
               "imaging_1" => 1,
               "imaging_2" => 1
             },
             "source_report_resource_projection_resource_pressure_activity_ids_by_status" => %{
               "downlink_shortfall" => ["dl_pressure_1"],
               "storage_shortfall" => ["imaging_1", "imaging_2"]
             },
             "source_report_resource_projection_resource_pressure_activity_ids_by_type" => %{
               "downlink_shortfall" => ["dl_pressure_1"],
               "storage_pressure" => ["dl_pressure_1"],
               "storage_shortfall" => ["imaging_1", "imaging_2"]
             },
             "source_report_resource_projection_resource_pressure_activity_ids_by_ground_station" =>
               %{
                 "dss_43" => ["imaging_1", "imaging_2"],
                 "equator_prime" => ["dl_pressure_1"]
               },
             "source_report_resource_projection_resource_pressure_activity_ids_by_spacecraft" =>
               %{
                 "leo_1" => ["dl_pressure_1"],
                 "leo_2" => ["imaging_1", "imaging_2"]
               },
             "source_report_resource_projection_resource_pressure_directions" => [
               "downlink",
               "tracking"
             ],
             "source_report_resource_projection_resource_pressure_activity_ids_by_direction" => %{
               "downlink" => ["dl_pressure_1"],
               "tracking" => ["imaging_1", "imaging_2"]
             },
             "source_report_resource_projection_resource_pressure_direction_routing" =>
               ^expected_pressure_direction_routing,
             "source_report_resource_projection_branch_local_resource_projection_pressure" =>
               true,
             "source_report_resource_projection_branch_local_projected_resource_pressure" => true,
             "source_report_resource_projection_branch_local_invalid_resource_projection_pressure" =>
               true,
             "source_report_resource_projection_branch_local_activity_pressure" => true,
             "source_report_resource_projection_resource_pressure_ground_station_ids_by_type" =>
               %{
                 "downlink_shortfall" => ["equator_prime"],
                 "storage_pressure" => ["equator_prime"],
                 "storage_shortfall" => ["dss_43"]
               },
             "source_report_resource_projection_resource_pressure_source_window_ids_by_status" =>
               %{
                 "downlink_shortfall" => ["flow_access_window_1"],
                 "storage_shortfall" => ["tracking_window_1"]
               },
             "source_report_resource_projection_resource_pressure_source_window_ids_by_type" => %{
               "downlink_shortfall" => ["flow_access_window_1"],
               "storage_pressure" => ["flow_access_window_1"],
               "storage_shortfall" => ["tracking_window_1"]
             },
             "source_report_resource_projection_resource_pressure_station_calendar_entry_ids_by_status" =>
               %{
                 "downlink_shortfall" => ["station_flow_window_1"],
                 "storage_shortfall" => ["station_tracking_window_1"]
               },
             "source_report_resource_projection_resource_pressure_station_calendar_entry_ids_by_type" =>
               %{
                 "downlink_shortfall" => ["station_flow_window_1"],
                 "storage_pressure" => ["station_flow_window_1"],
                 "storage_shortfall" => ["station_tracking_window_1"]
               },
             "source_report_resource_projection_resource_pressure_station_calendar_provider_ids_by_status" =>
               %{
                 "downlink_shortfall" => ["ops_calendar_flow"],
                 "storage_shortfall" => ["ops_calendar_tracking"]
               },
             "source_report_resource_projection_resource_pressure_station_calendar_provider_ids_by_type" =>
               %{
                 "downlink_shortfall" => ["ops_calendar_flow"],
                 "storage_pressure" => ["ops_calendar_flow"],
                 "storage_shortfall" => ["ops_calendar_tracking"]
               },
             "source_report_resource_projection_resource_pressure_station_calendar_provider_entry_ids_by_status" =>
               %{
                 "downlink_shortfall" => ["provider_flow_window_1"],
                 "storage_shortfall" => ["provider_tracking_window_1"]
               },
             "source_report_resource_projection_resource_pressure_station_calendar_provider_entry_ids_by_type" =>
               %{
                 "downlink_shortfall" => ["provider_flow_window_1"],
                 "storage_pressure" => ["provider_flow_window_1"],
                 "storage_shortfall" => ["provider_tracking_window_1"]
               }
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.resource_projection_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_resource_projection_replay_summary(artifact) ==
             replay_summary
  end

  test "resource projection replay treats activity routing maps as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_resource_projection_report"],
            "projected_resource_count" => 0,
            "invalid_activity_input_count" => 0,
            "invalid_resource_summary_input_count" => 0,
            "resource_pressure_status_counts" => %{},
            "ground_station_counts" => %{},
            "resource_projection_spacecraft_counts" => %{},
            "resource_pressure_type_counts" => %{},
            "resource_pressure_activity_id_counts" => %{"dl_pressure_1" => 1},
            "resource_pressure_activity_ids_by_status" => %{},
            "resource_pressure_activity_ids_by_type" => %{},
            "resource_pressure_activity_ids_by_ground_station" => %{},
            "resource_pressure_activity_ids_by_spacecraft" => %{},
            "resource_pressure_direction_counts" => %{},
            "resource_pressure_activity_ids_by_direction" => %{},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_resource_projection"]
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["projected_resource_count"] == 0
    assert summary["invalid_activity_input_count"] == 0
    assert summary["invalid_resource_summary_input_count"] == 0
    assert summary["resource_pressure_status_counts"] == %{}
    assert summary["ground_station_counts"] == %{}
    assert summary["resource_projection_spacecraft_counts"] == %{}
    assert summary["resource_pressure_type_counts"] == %{}
    assert summary["resource_pressure_activity_id_counts"] == %{"dl_pressure_1" => 1}
    assert summary["resource_pressure_activity_ids_by_status"] == %{}
    assert summary["resource_pressure_activity_ids_by_type"] == %{}
    assert summary["resource_pressure_activity_ids_by_ground_station"] == %{}
    assert summary["resource_pressure_activity_ids_by_spacecraft"] == %{}
    assert summary["resource_pressure_direction_counts"] == %{}
    assert summary["resource_pressure_activity_ids_by_direction"] == %{}
    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_projected_resource_pressure"]
    assert summary["branch_local_activity_pressure"]
    refute summary["branch_local_invalid_resource_projection_pressure"]
  end

  test "resource projection replay treats preserved activity ID pressure maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_resource_projection_report"],
            "projected_resource_count" => 0,
            "invalid_activity_input_count" => 0,
            "invalid_resource_summary_input_count" => 0,
            "resource_pressure_activity_ids_by_status" => %{
              "downlink_shortfall" => ["dl_pressure_1"]
            },
            "resource_pressure_activity_ids_by_type" => %{
              "storage_pressure" => ["dl_pressure_1"]
            },
            "resource_pressure_activity_ids_by_ground_station" => %{
              "equator_prime" => ["dl_pressure_1"]
            },
            "resource_pressure_activity_ids_by_spacecraft" => %{
              "leo_1" => ["dl_pressure_1"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert summary["resource_pressure_activity_ids_by_status"] == %{
             "downlink_shortfall" => ["dl_pressure_1"]
           }

    assert summary["resource_pressure_activity_ids_by_type"] == %{
             "storage_pressure" => ["dl_pressure_1"]
           }

    assert summary["resource_pressure_activity_ids_by_ground_station"] == %{
             "equator_prime" => ["dl_pressure_1"]
           }

    assert summary["resource_pressure_activity_ids_by_spacecraft"] == %{
             "leo_1" => ["dl_pressure_1"]
           }

    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_projected_resource_pressure"]
    assert summary["branch_local_activity_pressure"]
    refute summary["branch_local_invalid_resource_projection_pressure"]
  end

  test "resource projection source summary preserves invalid IDs as pressure" do
    refresh = %{
      "source_resource_projection_report" => %{
        "schema_contract" => "resource_projection_report.v1",
        "projected_resources" => [],
        "projected_resource_count" => 0,
        "invalid_activity_input_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "invalid_activity_input_ids" => ["bad_activity_map_only"],
        "invalid_resource_summary_input_ids" => ["bad_resource_summary_map_only"]
      }
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert get_in(source_summary, [
             "source_reports",
             "resource_projection_report",
             "invalid_activity_input_ids"
           ]) == ["bad_activity_map_only"]

    assert get_in(source_summary, [
             "source_reports",
             "resource_projection_report",
             "invalid_resource_summary_input_ids"
           ]) == ["bad_resource_summary_map_only"]

    assert source_summary["source_report_resource_projection_invalid_activity_input_ids"] == [
             "bad_activity_map_only"
           ]

    assert source_summary[
             "source_report_resource_projection_invalid_resource_summary_input_ids"
           ] == ["bad_resource_summary_map_only"]

    assert source_summary[
             "source_report_resource_projection_branch_local_resource_projection_pressure"
           ]

    assert source_summary[
             "source_report_resource_projection_branch_local_invalid_resource_projection_pressure"
           ]

    refute source_summary[
             "source_report_resource_projection_branch_local_projected_resource_pressure"
           ]

    refute source_summary[
             "source_report_resource_projection_branch_local_activity_pressure"
           ]

    replay_summary = CandidateRefresh.resource_projection_replay_summary(refresh)

    assert replay_summary["projected_resource_count"] == 0
    assert replay_summary["invalid_activity_input_count"] == 0
    assert replay_summary["invalid_resource_summary_input_count"] == 0
    assert replay_summary["invalid_activity_input_ids"] == ["bad_activity_map_only"]

    assert replay_summary["invalid_resource_summary_input_ids"] == [
             "bad_resource_summary_map_only"
           ]

    assert replay_summary["branch_local_resource_projection_pressure"]
    assert replay_summary["branch_local_invalid_resource_projection_pressure"]
    refute replay_summary["branch_local_projected_resource_pressure"]
    refute replay_summary["branch_local_activity_pressure"]
  end

  test "resource projection replay treats preserved routing maps and invalid IDs as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.resource_projection_report"],
            "projected_resource_count" => 0,
            "invalid_activity_input_count" => 0,
            "invalid_resource_summary_input_count" => 0,
            "resource_pressure_status_counts" => %{},
            "ground_station_counts" => %{},
            "resource_projection_spacecraft_counts" => %{},
            "resource_pressure_type_counts" => %{},
            "resource_pressure_activity_id_counts" => %{},
            "resource_pressure_direction_counts" => %{},
            "resource_pressure_activity_ids_by_direction" => %{},
            "resource_pressure_ground_station_ids_by_type" => %{
              "downlink_shortfall" => ["equator_prime"]
            },
            "resource_pressure_source_window_ids_by_status" => %{
              "downlink_shortfall" => ["flow_access_window_1"]
            },
            "resource_pressure_source_window_ids_by_type" => %{
              "downlink_shortfall" => ["flow_access_window_1"]
            },
            "resource_pressure_station_calendar_entry_ids_by_status" => %{
              "downlink_shortfall" => ["station_flow_window_1"]
            },
            "resource_pressure_station_calendar_entry_ids_by_type" => %{
              "downlink_shortfall" => ["station_flow_window_1"]
            },
            "resource_pressure_station_calendar_provider_ids_by_status" => %{
              "downlink_shortfall" => ["ops_calendar_flow"]
            },
            "resource_pressure_station_calendar_provider_ids_by_type" => %{
              "downlink_shortfall" => ["ops_calendar_flow"]
            },
            "resource_pressure_station_calendar_provider_entry_ids_by_status" => %{
              "downlink_shortfall" => ["provider_flow_window_1"]
            },
            "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
              "downlink_shortfall" => ["provider_flow_window_1"]
            },
            "invalid_activity_input_ids" => ["bad_activity"],
            "invalid_resource_summary_input_ids" => ["bad_resource_summary"]
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert summary["projected_resource_count"] == 0
    assert summary["invalid_activity_input_count"] == 0
    assert summary["invalid_resource_summary_input_count"] == 0

    assert summary["resource_pressure_ground_station_ids_by_type"] == %{
             "downlink_shortfall" => ["equator_prime"]
           }

    assert summary["resource_pressure_source_window_ids_by_status"] == %{
             "downlink_shortfall" => ["flow_access_window_1"]
           }

    assert summary["resource_pressure_source_window_ids_by_type"] == %{
             "downlink_shortfall" => ["flow_access_window_1"]
           }

    assert summary["resource_pressure_station_calendar_entry_ids_by_status"] == %{
             "downlink_shortfall" => ["station_flow_window_1"]
           }

    assert summary["resource_pressure_station_calendar_entry_ids_by_type"] == %{
             "downlink_shortfall" => ["station_flow_window_1"]
           }

    assert summary["resource_pressure_station_calendar_provider_ids_by_status"] == %{
             "downlink_shortfall" => ["ops_calendar_flow"]
           }

    assert summary["resource_pressure_station_calendar_provider_ids_by_type"] == %{
             "downlink_shortfall" => ["ops_calendar_flow"]
           }

    assert summary["resource_pressure_station_calendar_provider_entry_ids_by_status"] == %{
             "downlink_shortfall" => ["provider_flow_window_1"]
           }

    assert summary["resource_pressure_station_calendar_provider_entry_ids_by_type"] == %{
             "downlink_shortfall" => ["provider_flow_window_1"]
           }

    assert summary["invalid_activity_input_ids"] == ["bad_activity"]
    assert summary["invalid_resource_summary_input_ids"] == ["bad_resource_summary"]
    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_projected_resource_pressure"]
    assert summary["branch_local_invalid_resource_projection_pressure"]
    refute summary["branch_local_activity_pressure"]
  end

  test "resource projection replay treats preserved provider ID routing maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.resource_projection_report"],
            "projected_resource_count" => 0,
            "invalid_activity_input_count" => 0,
            "invalid_resource_summary_input_count" => 0,
            "resource_pressure_station_calendar_provider_ids_by_status" => %{
              "downlink_shortfall" => ["ops_calendar"]
            },
            "resource_pressure_station_calendar_provider_ids_by_type" => %{
              "downlink_shortfall" => ["ops_calendar"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert summary["resource_pressure_station_calendar_provider_ids_by_status"] == %{
             "downlink_shortfall" => ["ops_calendar"]
           }

    assert summary["resource_pressure_station_calendar_provider_ids_by_type"] == %{
             "downlink_shortfall" => ["ops_calendar"]
           }

    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_projected_resource_pressure"]
    refute summary["branch_local_invalid_resource_projection_pressure"]
    refute summary["branch_local_activity_pressure"]
  end

  test "resource projection replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_resource_projection_contract")
    refute Map.has_key?(source_summary, "source_report_resource_projection_count")
    refute Map.has_key?(source_summary, "source_report_resource_projection_row_count")
    refute Map.has_key?(source_summary, "source_report_resource_projection_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_resource_projection_pressure"]
  end

  test "resource projection source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "resource_projection_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.resource_projection_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.resource_projection_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "resource_projection_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_resource_projection_contract"] ==
                 "resource_projection_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_resource_projection_contract")
      end

      refute Map.has_key?(source_summary, "source_report_resource_projection_count")
      refute Map.has_key?(source_summary, "source_report_resource_projection_row_count")
      refute Map.has_key?(source_summary, "source_report_resource_projection_paths")
    end
  end

  test "resource projection source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.resource_projection_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_resource_projection_contract"] ==
             "resource_projection_report.v1"

    assert source_summary["source_report_resource_projection_count"] == 0
    assert source_summary["source_report_resource_projection_row_count"] == 0

    assert source_summary["source_report_resource_projection_paths"] == [
             "provenance.source_reports.resource_projection_report"
           ]
  end

  test "resource projection source summary omits missing identity paths after preserving counts" do
    partial_summaries = [
      %{
        "contract" => "resource_projection_report.v1",
        "count" => 1,
        "row_count" => 2
      },
      %{
        "contract" => "resource_projection_report.v1",
        "count" => 1,
        "row_count" => 2,
        "paths" => nil
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "resource_projection_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)
      replay_summary = CandidateRefresh.resource_projection_replay_summary(artifact)

      assert source_summary["source_report_resource_projection_contract"] ==
               "resource_projection_report.v1"

      assert source_summary["source_report_resource_projection_count"] == 1
      assert source_summary["source_report_resource_projection_row_count"] == 2
      refute Map.has_key?(source_summary, "source_report_resource_projection_paths")

      assert replay_summary["contract"] == "resource_projection_report.v1"
      assert replay_summary["source_report_count"] == 1
      assert replay_summary["source_report_row_count"] == 2
      assert replay_summary["source_report_paths"] == []
    end
  end

  test "resource projection replay preserves pressure maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "invalid_activity_input_ids" => ["bad_activity"],
            "invalid_resource_summary_input_ids" => ["bad_resource_summary"],
            "resource_pressure_status_counts" => %{"downlink_shortfall" => 1},
            "ground_station_counts" => %{"equator_prime" => 1},
            "resource_projection_spacecraft_counts" => %{"leo_1" => 1},
            "resource_pressure_type_counts" => %{"storage_pressure" => 1},
            "resource_pressure_activity_id_counts" => %{"pressure_activity" => 1},
            "resource_pressure_activity_ids_by_status" => %{
              "downlink_shortfall" => ["pressure_activity"]
            },
            "resource_pressure_activity_ids_by_type" => %{
              "storage_pressure" => ["pressure_activity"]
            },
            "resource_pressure_activity_ids_by_ground_station" => %{
              "equator_prime" => ["pressure_activity"]
            },
            "resource_pressure_activity_ids_by_spacecraft" => %{
              "leo_1" => ["pressure_activity"]
            },
            "resource_pressure_direction_counts" => %{"downlink" => 1},
            "resource_pressure_directions" => ["downlink"],
            "resource_pressure_activity_ids_by_direction" => %{
              "downlink" => ["pressure_activity"]
            },
            "resource_pressure_direction_routing" => %{
              "downlink" => %{
                "pressure_count" => 1,
                "activity_ids" => ["pressure_activity"]
              }
            },
            "resource_pressure_source_window_ids_by_status" => %{
              "downlink_shortfall" => ["source_window"]
            },
            "resource_pressure_station_calendar_entry_ids_by_status" => %{
              "downlink_shortfall" => ["station_entry"]
            },
            "resource_pressure_station_calendar_provider_entry_ids_by_status" => %{
              "downlink_shortfall" => ["provider_entry"]
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert source_summary["source_report_resource_projection_contract"] ==
             "resource_projection_report.v1"

    refute Map.has_key?(source_summary, "source_report_resource_projection_count")
    refute Map.has_key?(source_summary, "source_report_resource_projection_row_count")
    refute Map.has_key?(source_summary, "source_report_resource_projection_paths")

    assert source_summary["source_report_resource_projection_invalid_activity_input_ids"] == [
             "bad_activity"
           ]

    assert source_summary["source_report_resource_projection_invalid_resource_summary_input_ids"] ==
             ["bad_resource_summary"]

    assert source_summary["source_report_resource_projection_resource_pressure_status_counts"] ==
             %{"downlink_shortfall" => 1}

    assert source_summary["source_report_resource_projection_ground_station_counts"] == %{
             "equator_prime" => 1
           }

    assert source_summary["source_report_resource_projection_spacecraft_counts"] == %{
             "leo_1" => 1
           }

    assert source_summary["source_report_resource_projection_resource_pressure_type_counts"] == %{
             "storage_pressure" => 1
           }

    assert source_summary[
             "source_report_resource_projection_resource_pressure_activity_id_counts"
           ] == %{"pressure_activity" => 1}

    assert source_summary[
             "source_report_resource_projection_resource_pressure_activity_ids_by_status"
           ] == %{"downlink_shortfall" => ["pressure_activity"]}

    assert source_summary[
             "source_report_resource_projection_resource_pressure_activity_ids_by_type"
           ] == %{"storage_pressure" => ["pressure_activity"]}

    assert source_summary[
             "source_report_resource_projection_resource_pressure_activity_ids_by_ground_station"
           ] == %{"equator_prime" => ["pressure_activity"]}

    assert source_summary[
             "source_report_resource_projection_resource_pressure_activity_ids_by_spacecraft"
           ] == %{"leo_1" => ["pressure_activity"]}

    assert source_summary[
             "source_report_resource_projection_resource_pressure_direction_counts"
           ] == %{"downlink" => 1}

    assert source_summary["source_report_resource_projection_resource_pressure_directions"] == [
             "downlink"
           ]

    assert source_summary[
             "source_report_resource_projection_resource_pressure_activity_ids_by_direction"
           ] == %{"downlink" => ["pressure_activity"]}

    assert source_summary[
             "source_report_resource_projection_resource_pressure_direction_routing"
           ] == %{
             "downlink" => %{
               "pressure_count" => 1,
               "activity_ids" => ["pressure_activity"]
             }
           }

    assert replay_summary["contract"] == "resource_projection_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []
    assert replay_summary["invalid_activity_input_ids"] == ["bad_activity"]
    assert replay_summary["invalid_resource_summary_input_ids"] == ["bad_resource_summary"]
    assert replay_summary["resource_pressure_status_counts"] == %{"downlink_shortfall" => 1}
    assert replay_summary["ground_station_counts"] == %{"equator_prime" => 1}
    assert replay_summary["resource_projection_spacecraft_counts"] == %{"leo_1" => 1}
    assert replay_summary["resource_pressure_type_counts"] == %{"storage_pressure" => 1}
    assert replay_summary["resource_pressure_activity_id_counts"] == %{"pressure_activity" => 1}

    assert replay_summary["resource_pressure_activity_ids_by_status"] == %{
             "downlink_shortfall" => ["pressure_activity"]
           }

    assert replay_summary["resource_pressure_activity_ids_by_type"] == %{
             "storage_pressure" => ["pressure_activity"]
           }

    assert replay_summary["resource_pressure_activity_ids_by_ground_station"] == %{
             "equator_prime" => ["pressure_activity"]
           }

    assert replay_summary["resource_pressure_activity_ids_by_spacecraft"] == %{
             "leo_1" => ["pressure_activity"]
           }

    assert replay_summary["resource_pressure_direction_counts"] == %{"downlink" => 1}
    assert replay_summary["resource_pressure_directions"] == ["downlink"]

    assert replay_summary["resource_pressure_activity_ids_by_direction"] == %{
             "downlink" => ["pressure_activity"]
           }

    assert replay_summary["resource_pressure_direction_routing"] == %{
             "downlink" => %{
               "pressure_count" => 1,
               "activity_ids" => ["pressure_activity"]
             }
           }

    assert replay_summary["branch_local_resource_projection_pressure"]
    assert replay_summary["branch_local_projected_resource_pressure"]
    assert replay_summary["branch_local_invalid_resource_projection_pressure"]
    assert replay_summary["branch_local_activity_pressure"]
  end

  test "resource projection source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_resource_projection_contract"] ==
             "resource_projection_report.v1"

    assert source_summary["source_report_resource_projection_count"] == 1
    assert source_summary["source_report_resource_projection_row_count"] == 2
    assert source_summary["source_report_resource_projection_paths"] == []
  end

  test "resource projection replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_projection_report" => %{
              "contract" => "resource_projection_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_resource_projection_report"
              ],
              "projected_resource_count" => 2,
              "source_artifact_type_counts" => %{"resource_summary.v1" => 1},
              "source_flow_summary_model_counts" => %{
                "artifact_only_resource_projection_flow_summary" => 1
              },
              "invalid_activity_input_count" => 1,
              "invalid_resource_summary_input_count" => 1,
              "resource_pressure_status_counts" => %{"downlink_shortfall" => 1},
              "ground_station_counts" => %{"equator_prime" => 1},
              "resource_projection_spacecraft_counts" => %{"leo_1" => 1},
              "resource_pressure_type_counts" => %{"storage_pressure" => 1},
              "resource_pressure_activity_id_counts" => %{"branch_activity" => 1},
              "resource_pressure_activity_ids_by_status" => %{
                "downlink_shortfall" => ["branch_activity"]
              },
              "resource_pressure_activity_ids_by_type" => %{
                "storage_pressure" => ["branch_activity"]
              },
              "resource_pressure_activity_ids_by_ground_station" => %{
                "equator_prime" => ["branch_activity"]
              },
              "resource_pressure_activity_ids_by_spacecraft" => %{
                "leo_1" => ["branch_activity"]
              },
              "resource_pressure_direction_counts" => %{"downlink" => 1},
              "resource_pressure_directions" => ["downlink"],
              "resource_pressure_activity_ids_by_direction" => %{
                "downlink" => ["branch_activity"]
              },
              "resource_pressure_direction_routing" => %{
                "downlink" => %{
                  "pressure_count" => 1,
                  "activity_ids" => ["branch_activity"]
                }
              },
              "resource_pressure_ground_station_ids_by_type" => %{
                "storage_pressure" => ["equator_prime"]
              },
              "resource_pressure_source_window_ids_by_status" => %{
                "downlink_shortfall" => ["branch_window"]
              },
              "resource_pressure_source_window_ids_by_type" => %{
                "storage_pressure" => ["branch_window"]
              },
              "resource_pressure_station_calendar_entry_ids_by_status" => %{
                "downlink_shortfall" => ["branch_station_entry"]
              },
              "resource_pressure_station_calendar_entry_ids_by_type" => %{
                "storage_pressure" => ["branch_station_entry"]
              },
              "resource_pressure_station_calendar_provider_ids_by_status" => %{
                "downlink_shortfall" => ["branch_provider"]
              },
              "resource_pressure_station_calendar_provider_ids_by_type" => %{
                "storage_pressure" => ["branch_provider"]
              },
              "resource_pressure_station_calendar_provider_entry_ids_by_status" => %{
                "downlink_shortfall" => ["branch_provider_entry"]
              },
              "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
                "storage_pressure" => ["branch_provider_entry"]
              },
              "invalid_activity_input_ids" => ["bad_branch_activity"],
              "invalid_resource_summary_input_ids" => ["bad_branch_resource"],
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_resource_projection"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_resource_projection_report"],
            "projected_resource_count" => 99,
            "resource_pressure_activity_id_counts" => %{"provenance_activity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_projection_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_projection_report"
           ]

    assert summary["projected_resource_count"] == 2
    assert summary["source_artifact_type_counts"] == %{"resource_summary.v1" => 1}

    assert summary["source_flow_summary_model_counts"] == %{
             "artifact_only_resource_projection_flow_summary" => 1
           }

    assert summary["invalid_activity_input_count"] == 1
    assert summary["invalid_resource_summary_input_count"] == 1
    assert summary["resource_pressure_status_counts"] == %{"downlink_shortfall" => 1}
    assert summary["ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["resource_projection_spacecraft_counts"] == %{"leo_1" => 1}
    assert summary["resource_pressure_type_counts"] == %{"storage_pressure" => 1}
    assert summary["resource_pressure_activity_id_counts"] == %{"branch_activity" => 1}

    assert summary["resource_pressure_activity_ids_by_status"] == %{
             "downlink_shortfall" => ["branch_activity"]
           }

    assert summary["resource_pressure_activity_ids_by_type"] == %{
             "storage_pressure" => ["branch_activity"]
           }

    assert summary["resource_pressure_activity_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_activity"]
           }

    assert summary["resource_pressure_activity_ids_by_spacecraft"] == %{
             "leo_1" => ["branch_activity"]
           }

    assert summary["resource_pressure_direction_counts"] == %{"downlink" => 1}
    assert summary["resource_pressure_directions"] == ["downlink"]

    assert summary["resource_pressure_activity_ids_by_direction"] == %{
             "downlink" => ["branch_activity"]
           }

    assert summary["resource_pressure_direction_routing"] == %{
             "downlink" => %{
               "pressure_count" => 1,
               "activity_ids" => ["branch_activity"]
             }
           }

    assert summary["resource_pressure_ground_station_ids_by_type"] == %{
             "storage_pressure" => ["equator_prime"]
           }

    assert summary["resource_pressure_source_window_ids_by_status"] == %{
             "downlink_shortfall" => ["branch_window"]
           }

    assert summary["resource_pressure_source_window_ids_by_type"] == %{
             "storage_pressure" => ["branch_window"]
           }

    assert summary["resource_pressure_station_calendar_entry_ids_by_status"] == %{
             "downlink_shortfall" => ["branch_station_entry"]
           }

    assert summary["resource_pressure_station_calendar_entry_ids_by_type"] == %{
             "storage_pressure" => ["branch_station_entry"]
           }

    assert summary["resource_pressure_station_calendar_provider_ids_by_status"] == %{
             "downlink_shortfall" => ["branch_provider"]
           }

    assert summary["resource_pressure_station_calendar_provider_ids_by_type"] == %{
             "storage_pressure" => ["branch_provider"]
           }

    assert summary["resource_pressure_station_calendar_provider_entry_ids_by_status"] == %{
             "downlink_shortfall" => ["branch_provider_entry"]
           }

    assert summary["resource_pressure_station_calendar_provider_entry_ids_by_type"] == %{
             "storage_pressure" => ["branch_provider_entry"]
           }

    assert summary["invalid_activity_input_ids"] == ["bad_branch_activity"]
    assert summary["invalid_resource_summary_input_ids"] == ["bad_branch_resource"]
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_resource_projection"]
    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_projected_resource_pressure"]
    assert summary["branch_local_invalid_resource_projection_pressure"]
    assert summary["branch_local_activity_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_projection_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_resource_projection_replay_summary(artifact) ==
             summary
  end

  test "resource projection replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_resource_projection_report"
            ],
            "resource_pressure_direction_routing" => %{
              "downlink" => %{
                "pressure_count" => 1,
                "activity_ids" => ["direct_branch_activity"]
              }
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_projection_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_projection_report"
           ]

    assert summary["resource_pressure_direction_routing"] == %{
             "downlink" => %{
               "pressure_count" => 1,
               "activity_ids" => ["direct_branch_activity"]
             }
           }

    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_projected_resource_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_projection_candidate_source_report_summary_only"
  end

  test "resource projection replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_projection_report" => %{},
            "link_capacity_report" => %{
              "contract" => "link_capacity_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_resource_projection_report"],
            "invalid_activity_input_count" => 1,
            "invalid_activity_input_ids" => ["provenance_bad_activity"]
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.resource_projection_report"

    assert summary["source_report_paths"] == ["source_resource_projection_report"]
    assert summary["invalid_activity_input_count"] == 1
    assert summary["invalid_activity_input_ids"] == ["provenance_bad_activity"]
    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_invalid_resource_projection_pressure"]
    refute summary["branch_local_projected_resource_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_projection_source_report_provenance_only"
  end

  test "resource projection replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_projection_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_resource_projection_report"
              ],
              "resource_pressure_source_window_ids_by_type" => %{
                "downlink_shortfall" => ["branch_window"]
              }
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_resource_projection_report"],
            "projected_resource_count" => 9,
            "resource_pressure_source_window_ids_by_type" => %{
              "storage_pressure" => ["provenance_window"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_projection_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_projection_report"
           ]

    assert summary["projected_resource_count"] == 0

    assert summary["resource_pressure_source_window_ids_by_type"] == %{
             "downlink_shortfall" => ["branch_window"]
           }

    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_projected_resource_pressure"]
    refute summary["branch_local_invalid_resource_projection_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_projection_candidate_source_report_summary_only"
  end

  test "derives downlink completion objectives from source resource projection reports" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "nominal",
          "projected_downlink_shortfall_mb" => 0.0
        },
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "downlink_shortfall",
          "resource_pressure_types" => ["downlink_shortfall"],
          "projected_downlink_shortfall_mb" => 420.0,
          "first_resource_pressure_activity_id" => "dl_pressure_1",
          "first_resource_pressure_ground_station_id" => "equator_prime"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_resource_projection_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives downlink completion objectives from source resource projection flow summaries" do
    flow_summary = resource_projection_flow_summary_fixture()

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("mission_state", %{
            "source_resource_projection_flow_summary" => flow_summary
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert %{
             "paths" => ["mission_state.source_resource_projection_flow_summary"],
             "contract" => "resource_projection_report.v1",
             "count" => 1,
             "row_count" => 1,
             "projected_resource_count" => 1,
             "source_artifact_type_counts" => %{"resource_projection_flow_summary.v1" => 1},
             "source_flow_summary_model_counts" => %{
               "artifact_only_selected_activity_resource_flow_summary" => 1
             },
             "invalid_activity_input_count" => 0,
             "invalid_resource_summary_input_count" => 0,
             "resource_pressure_status_counts" => %{"downlink_shortfall" => 1},
             "ground_station_counts" => %{"equator_prime" => 1},
             "resource_projection_spacecraft_counts" => %{"leo_1" => 1},
             "resource_pressure_type_counts" => %{"downlink_shortfall" => 1},
             "resource_pressure_activity_id_counts" => %{"dl_flow_pressure" => 1},
             "resource_pressure_ground_station_ids_by_type" => %{
               "downlink_shortfall" => ["equator_prime"]
             },
             "resource_pressure_source_window_ids_by_type" => %{
               "downlink_shortfall" => ["flow_access_window_1"]
             },
             "resource_pressure_station_calendar_entry_ids_by_type" => %{
               "downlink_shortfall" => ["station_flow_window_1"]
             },
             "resource_pressure_station_calendar_provider_ids_by_type" => %{
               "downlink_shortfall" => ["ops_calendar_flow"]
             },
             "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
               "downlink_shortfall" => ["provider_flow_window_1"]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["flight_dynamics_model"]
           } = get_in(artifact, ["provenance", "source_reports", "resource_projection_report"])

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_resource_projection_contract"] ==
             "resource_projection_report.v1"

    assert source_summary["source_report_resource_projection_count"] == 1
    assert source_summary["source_report_resource_projection_row_count"] == 1

    assert source_summary["source_report_resource_projection_paths"] == [
             "mission_state.source_resource_projection_flow_summary"
           ]

    assert source_summary[
             "source_report_resource_projection_source_artifact_type_counts"
           ] == %{"resource_projection_flow_summary.v1" => 1}

    assert source_summary[
             "source_report_resource_projection_source_flow_summary_model_counts"
           ] == %{"artifact_only_selected_activity_resource_flow_summary" => 1}

    replay_summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert replay_summary["source_artifact_type_counts"] == %{
             "resource_projection_flow_summary.v1" => 1
           }

    assert replay_summary["source_flow_summary_model_counts"] == %{
             "artifact_only_selected_activity_resource_flow_summary" => 1
           }

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays resource projection flow summaries from result artifact wrappers" do
    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "source_resource_projection_flow_summary" =>
        resource_projection_flow_summary_fixture()
        |> Map.delete("provenance"),
      "provenance" => %{"trust_boundary" => "mission_planning"}
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", wrapper),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert %{
             "paths" => ["source_result_artifact.source_resource_projection_flow_summary"],
             "contract" => "resource_projection_report.v1",
             "count" => 1,
             "projected_resource_count" => 1,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_planning"]
           } = get_in(artifact, ["provenance", "source_reports", "resource_projection_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays resource projection downlink pressure from operator review packages" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "downlink shortfall",
          "resource_pressure_types" => ["downlink_shortfall"],
          "projected_downlink_shortfall_mb" => 420.0,
          "first_resource_pressure_activity_id" => "dl_pressure_1",
          "first_resource_pressure_ground_station_id" => "equator_prime"
        }
      ]
    }

    package = OperatorReview.from_resource_projection_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays resource projection downlink pressure from Cadence import manifests" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "downlink_shortfall",
          "resource_pressure_types" => ["downlink_shortfall"],
          "projected_downlink_shortfall_mb" => 420.0,
          "first_resource_pressure_activity_id" => "dl_pressure_1",
          "first_resource_pressure_ground_station_id" => "equator_prime"
        }
      ]
    }

    manifest = CadenceImport.from_resource_projection_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "preserves invalid resource projection summary replay provenance from Cadence imports" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            estimated_storage_mb: 10.0
          }
        ],
        [
          %{
            storage_capacity_mb: 500.0,
            storage_used_mb: 50.0,
            source_quality: :fleet_default,
            provenance: %{trust_boundary: :fleet_model}
          },
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 0.0,
            source_quality: :operator_supplied,
            provenance: %{trust_boundary: :cadence_ops}
          }
        ]
      )

    manifest = CadenceImport.from_resource_projection_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => ["source_cadence_import_manifest.rows.source_resource_projection"],
             "contract" => "resource_projection_report.v1",
             "count" => 1,
             "row_count" => 2,
             "projected_resource_count" => 1,
             "invalid_activity_input_count" => 0,
             "invalid_resource_summary_input_count" => 1,
             "resource_pressure_status_counts" => %{"nominal" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["cadence_ops", "fleet_model"]
           } = get_in(artifact, ["provenance", "source_reports", "resource_projection_report"])

    assert "source resource projection reports include invalid inputs requiring review" in artifact[
             "warnings"
           ]

    refute get_in(artifact, [
             "operational_feedback",
             "resource_margin_overrides",
             "all_spacecraft:mixed_scope"
           ])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives resource availability feedback from source resource projection reports" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "sat_1",
          "resource_pressure_status" => "payload_unavailable",
          "resource_pressure_types" => ["payload_unavailable"],
          "payload_available" => false,
          "antenna_available" => true,
          "resource_trust_boundary" => "cadence_ops"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_resource_projection_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["payload_available"] == false and
                 &1["antenna_available"] == true and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "trust_boundary"]) == "cadence_ops")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "payload_unavailable",
               "resource_blocking_dimension" => "payload",
               "resource_trust_boundary" => "cadence_ops"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert artifact["operational_feedback"]["resource_availability_overrides"]["sat_1"][
             "payload_available"
           ] == false

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives resource margin feedback from reviewed resource projection reports" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "storage_overflow",
          "resource_pressure_types" => ["storage_overflow"],
          "projected_storage_overflow_mb" => 25.0,
          "projected_storage_margin" => -0.25,
          "resource_trust_boundary" => "cadence_ops"
        }
      ]
    }

    package = OperatorReview.from_resource_projection_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["resource_filter_policy"], %{"min_observe_storage_margin" => 0.1})
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["storage_margin"] == 0.0 and
                 &1["source_quality"] == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "leo_1",
               "suppressed_reason" => "storage_margin_below_observe_policy",
               "resource_blocking_dimension" => "storage"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert artifact["resource_filter_report"]["invalid_resource_summary_input_count"] == 0
    assert artifact["resource_filter_report"]["invalid_resource_summary_inputs"] == []

    assert artifact["operational_feedback"]["resource_margin_overrides"]["leo_1"][
             "storage_margin"
           ] == 0.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp result_set do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
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
                sample_count: 3,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :target_visibility_linear_margin_interpolation,
                start_boundary: :clipped_start,
                end_boundary: :visibility_end,
                start_boundary_detail: %{
                  boundary: :clipped_start,
                  interpolation: :clipped_to_sample,
                  interpolation_fraction: 0.0,
                  sample_index: 1,
                  elevation_deg: 80.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :visibility_end,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.5,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 10.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :target_visibility,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :aos_los_linear_margin_interpolation,
                start_boundary: :aos,
                end_boundary: :los,
                start_boundary_detail: %{
                  edge: :start,
                  boundary: :aos,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.25,
                  before_sample_index: 2,
                  after_sample_index: 3,
                  before_elevation_deg: 0.0,
                  after_elevation_deg: 20.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :los,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.75,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :access_windows,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :other,
          event_type: :eclipse,
          events: [
            %{
              type: :eclipse,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{sample_count: 3}
            }
          ],
          source: %{shadow_model: :cylindrical_central_body_shadow}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp refresh_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ],
      "prior_candidate_activities" => [
        %{
          "id" => "stale_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }
  end

  defp resource_projection_flow_summary_fixture do
    ResourceProjection.report(
      [
        %{
          id: :dl_flow_pressure,
          type: :downlink,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          source_window_id: :flow_access_window_1,
          station_calendar_entry_id: :station_flow_window_1,
          station_calendar_provider_id: :ops_calendar_flow,
          station_calendar_provider_entry_id: :provider_flow_window_1,
          estimated_throughput_mb: 420.0
        }
      ],
      [
        %{
          spacecraft_id: :leo_1,
          storage_capacity_mb: 1_000.0,
          storage_used_mb: 420.0,
          downlink_capacity_mb: 0.0
        }
      ],
      source: "flow_summary_replay_test"
    )
    |> ResourceProjection.flow_summary()
    |> Map.put("provenance", %{"trust_boundary" => "flight_dynamics_model"})
  end
end
