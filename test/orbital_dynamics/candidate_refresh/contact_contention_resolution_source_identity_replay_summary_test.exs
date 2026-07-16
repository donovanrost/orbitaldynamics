defmodule OrbitalDynamics.CandidateRefresh.ContactContentionResolutionSourceIdentityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "contact contention resolution replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_contract")
    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_contact_contention_resolution_pressure"]
  end

  test "contact contention resolution source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "contact_contention_resolution_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.contact_contention_resolution_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.contact_contention_resolution_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_contention_resolution_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_contact_contention_resolution_contract"] ==
                 "contact_contention_resolution_report.v1"
      else
        refute Map.has_key?(
                 source_summary,
                 "source_report_contact_contention_resolution_contract"
               )
      end

      refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_count")
      refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_row_count")
      refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_paths")
    end
  end

  test "contact contention resolution source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.contact_contention_resolution_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_contact_contention_resolution_contract"] ==
             "contact_contention_resolution_report.v1"

    assert source_summary["source_report_contact_contention_resolution_count"] == 0
    assert source_summary["source_report_contact_contention_resolution_row_count"] == 0

    assert source_summary["source_report_contact_contention_resolution_paths"] == [
             "provenance.source_reports.contact_contention_resolution_report"
           ]
  end

  test "contact contention resolution source summary omits missing identity paths after preserving counts" do
    partial_summaries = [
      %{
        "contract" => "contact_contention_resolution_report.v1",
        "count" => 1,
        "row_count" => 2
      },
      %{
        "contract" => "contact_contention_resolution_report.v1",
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
            "contact_contention_resolution_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)
      replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

      assert source_summary["source_report_contact_contention_resolution_contract"] ==
               "contact_contention_resolution_report.v1"

      assert source_summary["source_report_contact_contention_resolution_count"] == 1
      assert source_summary["source_report_contact_contention_resolution_row_count"] == 2
      refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_paths")

      assert replay_summary["contract"] == "contact_contention_resolution_report.v1"
      assert replay_summary["source_report_count"] == 1
      assert replay_summary["source_report_row_count"] == 2
      assert replay_summary["source_report_paths"] == []
    end
  end

  test "contact contention resolution source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    assert source_summary["source_report_contact_contention_resolution_contract"] ==
             "contact_contention_resolution_report.v1"

    assert source_summary["source_report_contact_contention_resolution_count"] == 1
    assert source_summary["source_report_contact_contention_resolution_row_count"] == 2
    assert Map.has_key?(source_summary, "source_report_contact_contention_resolution_paths")
    assert source_summary["source_report_contact_contention_resolution_paths"] == []

    assert replay_summary["contract"] == "contact_contention_resolution_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 2
    assert replay_summary["source_report_paths"] == []
  end

  test "contact contention resolution replay preserves pressure maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 1,
            "resolution_status_counts" => %{"deferred" => 1},
            "selection_reason_counts" => %{"highest_score" => 1},
            "selected_contact_ids" => ["selected_contact"],
            "deferred_contact_ids" => ["deferred_contact"],
            "selected_contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "deferred_contact_ids_by_ground_station" => %{
              "equator_prime" => ["deferred_contact"]
            },
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["selected_contact"]},
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["selected_contact"]
              }
            },
            "required_operator_action_counts" => %{
              "review_contact_contention_resolution" => 1
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    assert source_summary["source_report_contact_contention_resolution_contract"] ==
             "contact_contention_resolution_report.v1"

    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_paths")

    assert source_summary["source_report_contact_contention_resolution_status_counts"] == %{
             "deferred" => 1
           }

    assert source_summary["source_report_contact_contention_resolution_selection_reason_counts"] ==
             %{"highest_score" => 1}

    assert source_summary["source_report_contact_contention_resolution_selected_contact_ids"] == [
             "selected_contact"
           ]

    assert source_summary["source_report_contact_contention_resolution_deferred_contact_ids"] == [
             "deferred_contact"
           ]

    assert source_summary[
             "source_report_contact_contention_resolution_selected_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["selected_contact"]}

    assert source_summary[
             "source_report_contact_contention_resolution_deferred_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["deferred_contact"]}

    assert source_summary["source_report_contact_contention_resolution_direction_counts"] == %{
             "downlink" => 1
           }

    assert source_summary["source_report_contact_contention_resolution_contact_ids_by_direction"] ==
             %{"downlink" => ["selected_contact"]}

    assert source_summary["source_report_contact_contention_resolution_direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"]
             }
           }

    assert source_summary[
             "source_report_contact_contention_resolution_required_operator_action_counts"
           ] == %{"review_contact_contention_resolution" => 1}

    assert replay_summary["contract"] == "contact_contention_resolution_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []
    assert replay_summary["resolution_status_counts"] == %{"deferred" => 1}
    assert replay_summary["selection_reason_counts"] == %{"highest_score" => 1}
    assert replay_summary["selected_contact_ids"] == ["selected_contact"]
    assert replay_summary["deferred_contact_ids"] == ["deferred_contact"]

    assert replay_summary["selected_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert replay_summary["deferred_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["deferred_contact"]
           }

    assert replay_summary["direction_counts"] == %{"downlink" => 1}
    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["selected_contact"]}

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"]
             }
           }

    assert replay_summary["required_operator_action_counts"] == %{
             "review_contact_contention_resolution" => 1
           }

    assert replay_summary["branch_local_contact_contention_resolution_pressure"]
    assert replay_summary["branch_local_deferred_contact_pressure"]
    assert replay_summary["branch_local_contact_contention_resolution_action_pressure"]
  end
end
