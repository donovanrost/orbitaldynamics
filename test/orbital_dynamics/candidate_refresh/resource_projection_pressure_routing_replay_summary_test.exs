defmodule OrbitalDynamics.CandidateRefresh.ResourceProjectionPressureRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

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
end
