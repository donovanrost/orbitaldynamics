defmodule OrbitalDynamics.CandidateRefresh.ResourceProjectionSourceIdentityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

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
end
