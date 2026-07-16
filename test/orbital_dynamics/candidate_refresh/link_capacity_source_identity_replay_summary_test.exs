defmodule OrbitalDynamics.CandidateRefresh.LinkCapacitySourceIdentityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "link capacity replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.link_capacity_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_link_capacity_contract")
    refute Map.has_key?(source_summary, "source_report_link_capacity_count")
    refute Map.has_key?(source_summary, "source_report_link_capacity_row_count")
    refute Map.has_key?(source_summary, "source_report_link_capacity_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_link_capacity_pressure"]
  end

  test "link capacity source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "link_capacity_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.link_capacity_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.link_capacity_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "link_capacity_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_link_capacity_contract"] ==
                 "link_capacity_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_link_capacity_contract")
      end

      refute Map.has_key?(source_summary, "source_report_link_capacity_count")
      refute Map.has_key?(source_summary, "source_report_link_capacity_row_count")
      refute Map.has_key?(source_summary, "source_report_link_capacity_paths")
    end
  end

  test "link capacity source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.link_capacity_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_link_capacity_contract"] ==
             "link_capacity_report.v1"

    assert source_summary["source_report_link_capacity_count"] == 0
    assert source_summary["source_report_link_capacity_row_count"] == 0

    assert source_summary["source_report_link_capacity_paths"] == [
             "provenance.source_reports.link_capacity_report"
           ]
  end

  test "link capacity source summary omits missing identity paths after preserving counts" do
    partial_summaries = [
      %{
        "contract" => "link_capacity_report.v1",
        "count" => 1,
        "row_count" => 2
      },
      %{
        "contract" => "link_capacity_report.v1",
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
            "link_capacity_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)
      replay_summary = CandidateRefresh.link_capacity_replay_summary(artifact)

      assert source_summary["source_report_link_capacity_contract"] ==
               "link_capacity_report.v1"

      assert source_summary["source_report_link_capacity_count"] == 1
      assert source_summary["source_report_link_capacity_row_count"] == 2
      refute Map.has_key?(source_summary, "source_report_link_capacity_paths")

      assert replay_summary["contract"] == "link_capacity_report.v1"
      assert replay_summary["source_report_count"] == 1
      assert replay_summary["source_report_row_count"] == 2
      assert replay_summary["source_report_paths"] == []
    end
  end

  test "link capacity source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.link_capacity_replay_summary(artifact)

    assert source_summary["source_report_link_capacity_contract"] ==
             "link_capacity_report.v1"

    assert source_summary["source_report_link_capacity_count"] == 1
    assert source_summary["source_report_link_capacity_row_count"] == 2
    assert Map.has_key?(source_summary, "source_report_link_capacity_paths")
    assert source_summary["source_report_link_capacity_paths"] == []

    assert replay_summary["contract"] == "link_capacity_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 2
    assert replay_summary["source_report_paths"] == []
  end

  test "link capacity replay preserves throughput and routing maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 1,
            "capacity_adjusted_throughput_mb_by_ground_station" => %{
              "equator_prime" => 120.0
            },
            "capacity_adjusted_throughput_mb_by_direction" => %{"downlink" => 120.0},
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["selected_contact"]},
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["selected_contact"],
                "capacity_adjusted_throughput_mb" => 120.0
              }
            },
            "contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "selected_contact_ids" => ["selected_contact"],
            "actual_throughput_contact_ids" => ["actual_contact"],
            "downlink_requirement_status_counts" => %{"actual_shortfall" => 1},
            "contact_ids_by_requirement_status" => %{
              "actual_shortfall" => ["actual_contact"]
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.link_capacity_replay_summary(artifact)

    assert source_summary["source_report_link_capacity_contract"] ==
             "link_capacity_report.v1"

    refute Map.has_key?(source_summary, "source_report_link_capacity_count")
    refute Map.has_key?(source_summary, "source_report_link_capacity_row_count")
    refute Map.has_key?(source_summary, "source_report_link_capacity_paths")

    assert source_summary[
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_ground_station"
           ] == %{"equator_prime" => 120.0}

    assert source_summary[
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_direction"
           ] == %{"downlink" => 120.0}

    assert source_summary["source_report_link_capacity_direction_counts"] == %{"downlink" => 1}

    assert source_summary["source_report_link_capacity_contact_ids_by_direction"] == %{
             "downlink" => ["selected_contact"]
           }

    assert source_summary["source_report_link_capacity_direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"],
               "capacity_adjusted_throughput_mb" => 120.0
             }
           }

    assert source_summary["source_report_link_capacity_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert source_summary["source_report_link_capacity_selected_contact_ids"] == [
             "selected_contact"
           ]

    assert source_summary["source_report_link_capacity_actual_throughput_contact_ids"] == [
             "actual_contact"
           ]

    assert source_summary["source_report_link_capacity_downlink_requirement_status_counts"] == %{
             "actual_shortfall" => 1
           }

    assert source_summary["source_report_link_capacity_contact_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["actual_contact"]
           }

    assert replay_summary["contract"] == "link_capacity_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []

    assert replay_summary["capacity_adjusted_throughput_mb_by_ground_station"] == %{
             "equator_prime" => 120.0
           }

    assert replay_summary["capacity_adjusted_throughput_mb_by_direction"] == %{
             "downlink" => 120.0
           }

    assert replay_summary["direction_counts"] == %{"downlink" => 1}
    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["selected_contact"]}

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"],
               "capacity_adjusted_throughput_mb" => 120.0
             }
           }

    assert replay_summary["contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert replay_summary["selected_contact_ids"] == ["selected_contact"]
    assert replay_summary["actual_throughput_contact_ids"] == ["actual_contact"]
    assert replay_summary["downlink_requirement_status_counts"] == %{"actual_shortfall" => 1}

    assert replay_summary["contact_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["actual_contact"]
           }

    assert replay_summary["branch_local_link_capacity_pressure"]
    assert replay_summary["branch_local_capacity_adjusted_throughput_pressure"]
    assert replay_summary["branch_local_downlink_shortfall_pressure"]
    assert replay_summary["branch_local_actual_throughput_pressure"]
  end
end
