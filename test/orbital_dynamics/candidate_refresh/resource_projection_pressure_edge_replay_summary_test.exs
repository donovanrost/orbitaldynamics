defmodule OrbitalDynamics.CandidateRefresh.ResourceProjectionPressureEdgeReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

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
end
