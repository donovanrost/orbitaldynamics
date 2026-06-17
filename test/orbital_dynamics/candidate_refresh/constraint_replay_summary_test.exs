defmodule OrbitalDynamics.CandidateRefresh.ConstraintReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates constraint routing maps" do
    refresh = %{
      "source_constraint_report" => %{
        "schema_contract" => "constraint_report.v1",
        "rows" => [
          %{
            "constraint_id" => "downlink_shortfall",
            "metric" => "selected_downlink_shortfall_mb",
            "scenario_id" => "leo_1",
            "status" => "warning",
            "value" => 40.0,
            "ground_station_id" => "equator_prime",
            "activity_id" => "downlink_activity_1",
            "trust_boundary" => "ops_constraint_rows"
          },
          %{
            "constraint_id" => "battery_margin",
            "metric" => "battery_margin",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "scout_1",
            "status" => "fail",
            "resource_id" => "battery_1",
            "source_activity_ids" => ["charge_activity_1", "downlink_activity_1"],
            "value" => -0.2,
            "trust_boundary" => "ops_constraint_rows"
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_constraint_report"},
        "constraint_id_counts" => %{"stale_constraint" => 99},
        "source_activity_id_counts" => %{"stale_activity" => 99}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_constraint_contract" => "constraint_report.v1",
             "source_report_constraint_count" => 1,
             "source_report_constraint_row_count" => 2,
             "source_report_constraint_paths" => ["source_constraint_report"],
             "source_report_constraint_downlink_gap_row_count" => 1,
             "source_report_constraint_resource_margin_row_count" => 1,
             "source_report_constraint_status_counts" => %{
               "fail" => 1,
               "warning" => 1
             },
             "source_report_constraint_ground_station_counts" => %{"equator_prime" => 1},
             "source_report_constraint_metric_counts" => %{
               "battery_margin" => 1,
               "selected_downlink_shortfall_mb" => 1
             },
             "source_report_constraint_id_counts" => %{
               "battery_margin" => 1,
               "downlink_shortfall" => 1
             },
             "source_report_constraint_source_activity_id_counts" => %{
               "charge_activity_1" => 1,
               "downlink_activity_1" => 2
             },
             "source_report_constraint_resource_counts" => %{"battery_1" => 1},
             "source_report_constraint_spacecraft_counts" => %{"scout_1" => 1},
             "source_report_constraint_branch_local_constraint_pressure" => true,
             "source_report_constraint_branch_local_downlink_gap_pressure" => true,
             "source_report_constraint_branch_local_resource_margin_pressure" => true,
             "source_report_constraint_branch_local_constraint_routing_pressure" => true,
             "source_reports" => %{
               "constraint_report" => %{
                 "row_count" => 2,
                 "downlink_gap_row_count" => 1,
                 "resource_margin_row_count" => 1,
                 "status_counts" => %{"fail" => 1, "warning" => 1},
                 "constraint_id_counts" => %{
                   "battery_margin" => 1,
                   "downlink_shortfall" => 1
                 },
                 "source_activity_id_counts" => %{
                   "charge_activity_1" => 1,
                   "downlink_activity_1" => 2
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_constraint_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.constraint_report",
      "contract" => "constraint_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 2,
      "source_report_paths" => ["source_constraint_report"],
      "downlink_gap_row_count" => 1,
      "resource_margin_row_count" => 1,
      "status_counts" => %{"fail" => 1, "warning" => 1},
      "ground_station_counts" => %{"equator_prime" => 1},
      "constraint_metric_counts" => %{
        "battery_margin" => 1,
        "selected_downlink_shortfall_mb" => 1
      },
      "constraint_id_counts" => %{
        "battery_margin" => 1,
        "downlink_shortfall" => 1
      },
      "source_activity_id_counts" => %{
        "charge_activity_1" => 1,
        "downlink_activity_1" => 2
      },
      "constraint_resource_counts" => %{"battery_1" => 1},
      "constraint_spacecraft_counts" => %{"scout_1" => 1},
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_constraint_report", "ops_constraint_rows"],
      "branch_local_constraint_pressure" => true,
      "branch_local_downlink_gap_pressure" => true,
      "branch_local_resource_margin_pressure" => true,
      "branch_local_constraint_routing_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "constraint_source_report_provenance_only",
        "operator_authority" => "not_granted_by_constraint_replay_summary",
        "objective_generation" => "not_performed_by_summary",
        "resource_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_constraint_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.constraint_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_constraint_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_constraint_downlink_gap_row_count" => 1,
             "source_report_constraint_status_counts" => %{"fail" => 1, "warning" => 1},
             "source_report_constraint_metric_counts" => %{
               "battery_margin" => 1,
               "selected_downlink_shortfall_mb" => 1
             },
             "source_report_constraint_id_counts" => %{
               "battery_margin" => 1,
               "downlink_shortfall" => 1
             },
             "source_report_constraint_source_activity_id_counts" => %{
               "charge_activity_1" => 1,
               "downlink_activity_1" => 2
             },
             "source_report_constraint_branch_local_constraint_pressure" => true,
             "source_report_constraint_branch_local_downlink_gap_pressure" => true,
             "source_report_constraint_branch_local_resource_margin_pressure" => true,
             "source_report_constraint_branch_local_constraint_routing_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.constraint_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_constraint_replay_summary(artifact) ==
             replay_summary
  end

  test "constraint replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.constraint_replay_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_constraint_pressure"]
  end

  test "constraint source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.constraint_report"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "constraint_report" =>
              Map.put(
                placeholder,
                "contract",
                "constraint_report.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_constraint_contract"] ==
               "constraint_report.v1"

      refute Map.has_key?(source_summary, "source_report_constraint_count")
      refute Map.has_key?(source_summary, "source_report_constraint_row_count")
      refute Map.has_key?(source_summary, "source_report_constraint_paths")
    end
  end

  test "constraint source summary preserves non-identity rollups with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "constraint_report" => %{
            "contract" => "constraint_report.v1",
            "count" => 1,
            "status_counts" => %{"fail" => 1},
            "constraint_id_counts" => %{"visibility_conflict" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_constraint_contract"] == "constraint_report.v1"
    refute Map.has_key?(source_summary, "source_report_constraint_count")
    refute Map.has_key?(source_summary, "source_report_constraint_row_count")
    refute Map.has_key?(source_summary, "source_report_constraint_paths")
    assert source_summary["source_report_constraint_status_counts"] == %{"fail" => 1}

    assert source_summary["source_report_constraint_id_counts"] ==
             %{"visibility_conflict" => 1}
  end

  test "constraint source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "constraint_report" => %{
            "contract" => "constraint_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.constraint_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_constraint_contract"] == "constraint_report.v1"
    assert source_summary["source_report_constraint_count"] == 0
    assert source_summary["source_report_constraint_row_count"] == 0

    assert source_summary["source_report_constraint_paths"] == [
             "provenance.source_reports.constraint_report"
           ]
  end

  test "constraint source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "constraint_report" => %{
            "contract" => "constraint_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_constraint_contract"] == "constraint_report.v1"
    assert source_summary["source_report_constraint_count"] == 1
    assert source_summary["source_report_constraint_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_constraint_paths")
  end

  test "constraint source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "constraint_report" => %{
            "contract" => "constraint_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_constraint_contract"] == "constraint_report.v1"
    assert source_summary["source_report_constraint_count"] == 1
    assert source_summary["source_report_constraint_row_count"] == 2
    assert source_summary["source_report_constraint_paths"] == []
  end

  test "constraint replay summary treats routing maps as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "constraint_report" => %{
            "contract" => "constraint_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_constraint_report"],
            "downlink_gap_row_count" => 0,
            "resource_margin_row_count" => 0,
            "status_counts" => %{},
            "ground_station_counts" => %{"equator_prime" => 1},
            "constraint_metric_counts" => %{"visibility_window_s" => 1},
            "constraint_id_counts" => %{"visibility_conflict" => 1},
            "source_activity_id_counts" => %{"imaging_1" => 1},
            "constraint_resource_counts" => %{},
            "constraint_spacecraft_counts" => %{},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_constraint_rows"]
          }
        }
      }
    }

    summary = CandidateRefresh.constraint_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["downlink_gap_row_count"] == 0
    assert summary["resource_margin_row_count"] == 0
    assert summary["status_counts"] == %{}
    assert summary["ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["constraint_metric_counts"] == %{"visibility_window_s" => 1}
    assert summary["constraint_id_counts"] == %{"visibility_conflict" => 1}
    assert summary["source_activity_id_counts"] == %{"imaging_1" => 1}
    assert summary["branch_local_constraint_pressure"]
    assert summary["branch_local_constraint_routing_pressure"]
    refute summary["branch_local_downlink_gap_pressure"]
    refute summary["branch_local_resource_margin_pressure"]
  end

  test "constraint replay preserves routing pressure with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "constraint_report" => %{
            "contract" => "constraint_report.v1",
            "count" => 1,
            "paths" => ["source_constraint_report"],
            "downlink_gap_row_count" => 0,
            "resource_margin_row_count" => 0,
            "status_counts" => %{},
            "ground_station_counts" => %{"equator_prime" => 1},
            "constraint_metric_counts" => %{"visibility_window_s" => 1},
            "constraint_id_counts" => %{"visibility_conflict" => 1},
            "source_activity_id_counts" => %{"imaging_1" => 1},
            "constraint_resource_counts" => %{},
            "constraint_spacecraft_counts" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.constraint_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == ["source_constraint_report"]
    assert summary["ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["constraint_metric_counts"] == %{"visibility_window_s" => 1}
    assert summary["constraint_id_counts"] == %{"visibility_conflict" => 1}
    assert summary["source_activity_id_counts"] == %{"imaging_1" => 1}
    assert summary["branch_local_constraint_pressure"]
    assert summary["branch_local_constraint_routing_pressure"]
    refute summary["branch_local_downlink_gap_pressure"]
    refute summary["branch_local_resource_margin_pressure"]
  end
end
