defmodule OrbitalDynamics.CandidateRefresh.CandidateRejectionReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "source report summary derives candidate rejection routing maps from rows" do
    refresh = %{
      "source_candidate_rejection_report" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "row_count" => 2,
        "rejected_count" => 2,
        "reviewable_count" => 1,
        "invalid_candidate_input_count" => 1,
        "rejection_reason_counts" => %{
          "stale_rejection_reason" => 99
        },
        "required_operator_action_counts" => %{
          "stale_required_action" => 99
        },
        "rows" => [
          %{
            "id" => "candidate_rejection:dl_reserved",
            "candidate_id" => "dl_reserved",
            "ground_station_id" => "equator_prime",
            "rejection_reasons" => ["station_reserved"],
            "primary_rejection_reason" => "station_reserved",
            "required_operator_action" => "review_candidate_rejection"
          },
          %{
            "id" => "candidate_rejection:bad_candidate",
            "candidate_id" => "bad_candidate",
            "activity_context" => %{"ground_station_id" => "dss_43"},
            "rejection_reasons" => ["invalid_candidate_input"],
            "primary_rejection_reason" => "invalid_candidate_input",
            "required_operator_action" => "none"
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_candidate_rejection"}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_candidate_rejection_contract" => "candidate_rejection_report.v1",
             "source_report_candidate_rejection_count" => 1,
             "source_report_candidate_rejection_row_count" => 2,
             "source_report_candidate_rejection_paths" => [
               "source_candidate_rejection_report"
             ],
             "source_report_candidate_rejection_rejected_count" => 2,
             "source_report_candidate_rejection_reviewable_count" => 1,
             "source_report_candidate_rejection_invalid_candidate_input_count" => 1,
             "source_report_candidate_rejection_rejection_reason_counts" => %{
               "invalid_candidate_input" => 1,
               "station_reserved" => 1
             },
             "source_report_candidate_rejection_required_operator_action_counts" => %{
               "none" => 1,
               "review_candidate_rejection" => 1
             },
             "source_report_candidate_rejection_candidate_id_counts" => %{
               "bad_candidate" => 1,
               "dl_reserved" => 1
             },
             "source_report_candidate_rejection_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_report_candidate_rejection_branch_local_rejection_pressure" => true,
             "source_report_candidate_rejection_branch_local_review_pressure" => true,
             "source_report_candidate_rejection_branch_local_invalid_input_pressure" => true,
             "source_reports" => %{
               "candidate_rejection_report" => %{
                 "row_count" => 2,
                 "rejected_count" => 2,
                 "candidate_rejection_candidate_id_counts" => %{
                   "bad_candidate" => 1,
                   "dl_reserved" => 1
                 },
                 "candidate_rejection_ground_station_counts" => %{
                   "dss_43" => 1,
                   "equator_prime" => 1
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_candidate_rejection_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.candidate_rejection_report",
      "contract" => "candidate_rejection_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 2,
      "source_report_paths" => ["source_candidate_rejection_report"],
      "rejected_count" => 2,
      "reviewable_count" => 1,
      "invalid_candidate_input_count" => 1,
      "rejection_reason_counts" => %{
        "invalid_candidate_input" => 1,
        "station_reserved" => 1
      },
      "required_operator_action_counts" => %{
        "none" => 1,
        "review_candidate_rejection" => 1
      },
      "candidate_rejection_candidate_id_counts" => %{
        "bad_candidate" => 1,
        "dl_reserved" => 1
      },
      "candidate_rejection_ground_station_counts" => %{
        "dss_43" => 1,
        "equator_prime" => 1
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_candidate_rejection"],
      "branch_local_rejection_pressure" => true,
      "branch_local_review_pressure" => true,
      "branch_local_invalid_input_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "candidate_rejection_source_report_provenance_only",
        "operator_authority" => "not_granted_by_candidate_rejection_replay_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_candidate_rejection_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.candidate_rejection_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_candidate_rejection_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" =>
          Map.put(summary["source_reports"], "quality_gate_report", %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 1,
            "rejection_reason_counts" => %{"unrelated" => 99},
            "trust_boundary_status" => "declared"
          })
      }
    }

    assert %{
             "source_report_family_count" => 2,
             "source_report_candidate_rejection_contract" => "candidate_rejection_report.v1",
             "source_report_candidate_rejection_count" => 1,
             "source_report_candidate_rejection_row_count" => 2,
             "source_report_candidate_rejection_paths" => [
               "source_candidate_rejection_report"
             ],
             "source_report_candidate_rejection_rejected_count" => 2,
             "source_report_candidate_rejection_rejection_reason_counts" => %{
               "invalid_candidate_input" => 1,
               "station_reserved" => 1
             },
             "source_report_candidate_rejection_candidate_id_counts" => %{
               "bad_candidate" => 1,
               "dl_reserved" => 1
             },
             "source_report_candidate_rejection_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_report_candidate_rejection_branch_local_rejection_pressure" => true,
             "source_report_candidate_rejection_branch_local_review_pressure" => true,
             "source_report_candidate_rejection_branch_local_invalid_input_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.candidate_rejection_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_candidate_rejection_replay_summary(artifact) ==
             replay_summary
  end

  test "source report summary replays exact candidate rejection reports from result artifacts" do
    source_report =
      Timeline.candidate_rejection_report(
        [
          %{
            id: :exact_reserved_downlink,
            type: :downlink,
            ground_station_id: :equator_prime,
            station_availability: "Reservation Hold",
            starts_at_s: 10.0,
            ends_at_s: 15.0,
            min_duration_s: 20.0,
            provenance: %{trust_boundary: :exact_source_rejection_row}
          }
        ],
        source: "exact.source.rejections"
      )
      |> Map.put("provenance", %{"trust_boundary" => "exact_source_rejection_report"})

    result_report =
      Timeline.candidate_rejection_report(
        [
          %{
            id: :exact_unavailable_downlink,
            type: :downlink,
            ground_station_id: :dss_43,
            station_availability: "unavailable",
            reviewable: false,
            starts_at_s: 30.0,
            ends_at_s: 60.0,
            provenance: %{trust_boundary: :exact_result_rejection_row}
          }
        ],
        source: "exact.result.rejections"
      )
      |> Map.put("provenance", %{"trust_boundary" => "exact_result_rejection_report"})

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(source_report)

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(result_report)

    refresh = %{
      "source_result_artifact" => source_report,
      "result_artifact" => result_report
    }

    assert %{
             "source_report_candidate_rejection_contract" => "candidate_rejection_report.v1",
             "source_report_candidate_rejection_count" => 2,
             "source_report_candidate_rejection_row_count" => 2,
             "source_report_candidate_rejection_paths" => [
               "source_result_artifact",
               "result_artifact"
             ],
             "source_report_candidate_rejection_rejected_count" => 2,
             "source_report_candidate_rejection_reviewable_count" => 1,
             "source_report_candidate_rejection_invalid_candidate_input_count" => 0,
             "source_report_candidate_rejection_rejection_reason_counts" => %{
               "contact_too_short" => 1,
               "station_reserved" => 1,
               "station_unavailable" => 1
             },
             "source_report_candidate_rejection_required_operator_action_counts" => %{
               "none" => 1,
               "review_candidate_rejection" => 1
             },
             "source_report_candidate_rejection_candidate_id_counts" => %{
               "exact_reserved_downlink" => 1,
               "exact_unavailable_downlink" => 1
             },
             "source_report_candidate_rejection_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_reports" => %{
               "candidate_rejection_report" => %{
                 "paths" => ["source_result_artifact", "result_artifact"],
                 "contract" => "candidate_rejection_report.v1",
                 "count" => 2,
                 "row_count" => 2,
                 "rejected_count" => 2,
                 "reviewable_count" => 1,
                 "invalid_candidate_input_count" => 0,
                 "rejection_reason_counts" => %{
                   "contact_too_short" => 1,
                   "station_reserved" => 1,
                   "station_unavailable" => 1
                 },
                 "required_operator_action_counts" => %{
                   "none" => 1,
                   "review_candidate_rejection" => 1
                 },
                 "candidate_rejection_candidate_id_counts" => %{
                   "exact_reserved_downlink" => 1,
                   "exact_unavailable_downlink" => 1
                 },
                 "candidate_rejection_ground_station_counts" => %{
                   "dss_43" => 1,
                   "equator_prime" => 1
                 },
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "exact_result_rejection_report",
                   "exact_result_rejection_row",
                   "exact_source_rejection_report",
                   "exact_source_rejection_row"
                 ]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "contract" => "candidate_rejection_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => ["source_result_artifact", "result_artifact"],
             "rejected_count" => 2,
             "reviewable_count" => 1,
             "invalid_candidate_input_count" => 0,
             "rejection_reason_counts" => %{
               "contact_too_short" => 1,
               "station_reserved" => 1,
               "station_unavailable" => 1
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_candidate_rejection" => 1
             },
             "candidate_rejection_candidate_id_counts" => %{
               "exact_reserved_downlink" => 1,
               "exact_unavailable_downlink" => 1
             },
             "candidate_rejection_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "trust_boundaries" => [
               "exact_result_rejection_report",
               "exact_result_rejection_row",
               "exact_source_rejection_report",
               "exact_source_rejection_row"
             ],
             "branch_local_rejection_pressure" => true,
             "branch_local_review_pressure" => true,
             "branch_local_invalid_input_pressure" => false
           } = CandidateRefresh.candidate_rejection_replay_summary(refresh)
  end

  test "candidate rejection replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.candidate_rejection_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_candidate_rejection_contract")
    refute Map.has_key?(source_summary, "source_report_candidate_rejection_count")
    refute Map.has_key?(source_summary, "source_report_candidate_rejection_row_count")
    refute Map.has_key?(source_summary, "source_report_candidate_rejection_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_rejection_pressure"]
  end

  test "candidate rejection source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "candidate_rejection_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.candidate_rejection_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.candidate_rejection_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "candidate_rejection_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_candidate_rejection_contract"] ==
                 "candidate_rejection_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_candidate_rejection_contract")
      end

      refute Map.has_key?(source_summary, "source_report_candidate_rejection_count")
      refute Map.has_key?(source_summary, "source_report_candidate_rejection_row_count")
      refute Map.has_key?(source_summary, "source_report_candidate_rejection_paths")
    end
  end

  test "candidate rejection source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "candidate_rejection_report" => %{
            "contract" => "candidate_rejection_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.candidate_rejection_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_candidate_rejection_contract"] ==
             "candidate_rejection_report.v1"

    assert source_summary["source_report_candidate_rejection_count"] == 0
    assert source_summary["source_report_candidate_rejection_row_count"] == 0

    assert source_summary["source_report_candidate_rejection_paths"] == [
             "provenance.source_reports.candidate_rejection_report"
           ]
  end

  test "candidate rejection source summary omits missing identity paths after preserving counts" do
    summaries = [
      {"missing paths",
       %{
         "contract" => "candidate_rejection_report.v1",
         "count" => 1,
         "row_count" => 2
       }},
      {"nil paths",
       %{
         "contract" => "candidate_rejection_report.v1",
         "count" => 1,
         "row_count" => 2,
         "paths" => nil
       }}
    ]

    for {label, candidate_rejection_summary} <- summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "candidate_rejection_report" => candidate_rejection_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_candidate_rejection_contract"] ==
               "candidate_rejection_report.v1",
             label

      assert source_summary["source_report_candidate_rejection_count"] == 1, label
      assert source_summary["source_report_candidate_rejection_row_count"] == 2, label
      refute Map.has_key?(source_summary, "source_report_candidate_rejection_paths"), label
    end
  end

  test "candidate rejection source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "candidate_rejection_report" => %{
            "contract" => "candidate_rejection_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_candidate_rejection_contract"] ==
             "candidate_rejection_report.v1"

    assert source_summary["source_report_candidate_rejection_count"] == 1
    assert source_summary["source_report_candidate_rejection_row_count"] == 2
    assert source_summary["source_report_candidate_rejection_paths"] == []
  end

  test "candidate rejection replay preserves pressure maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "candidate_rejection_report" => %{
            "contract" => "candidate_rejection_report.v1",
            "count" => 1,
            "rejection_reason_counts" => %{"invalid_candidate_input" => 1},
            "required_operator_action_counts" => %{"review_candidate_rejection" => 1},
            "candidate_rejection_candidate_id_counts" => %{"bad_candidate" => 1},
            "candidate_rejection_ground_station_counts" => %{"equator_prime" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_candidate_rejection_count")
    refute Map.has_key?(source_summary, "source_report_candidate_rejection_row_count")
    refute Map.has_key?(source_summary, "source_report_candidate_rejection_paths")

    assert source_summary["source_report_candidate_rejection_rejection_reason_counts"] == %{
             "invalid_candidate_input" => 1
           }

    assert source_summary[
             "source_report_candidate_rejection_required_operator_action_counts"
           ] == %{"review_candidate_rejection" => 1}

    assert source_summary[
             "source_report_candidate_rejection_candidate_id_counts"
           ] == %{"bad_candidate" => 1}

    assert source_summary[
             "source_report_candidate_rejection_ground_station_counts"
           ] == %{"equator_prime" => 1}

    summary = CandidateRefresh.candidate_rejection_replay_summary(artifact)

    assert summary["branch_local_rejection_pressure"]
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_invalid_input_pressure"]
  end

  test "candidate rejection replay treats preserved maps as branch-local pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "candidate_rejection_report" => %{
            "contract" => "candidate_rejection_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.candidate_rejection_report"],
            "rejected_count" => 0,
            "reviewable_count" => 0,
            "invalid_candidate_input_count" => 0,
            "rejection_reason_counts" => %{"invalid_candidate_input" => 1},
            "required_operator_action_counts" => %{"review_candidate_rejection" => 1},
            "candidate_rejection_candidate_id_counts" => %{"bad_candidate" => 1},
            "candidate_rejection_ground_station_counts" => %{"equator_prime" => 1},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_candidate_rejection"]
          }
        }
      }
    }

    summary = CandidateRefresh.candidate_rejection_replay_summary(artifact)

    assert summary["rejected_count"] == 0
    assert summary["reviewable_count"] == 0
    assert summary["invalid_candidate_input_count"] == 0
    assert summary["rejection_reason_counts"] == %{"invalid_candidate_input" => 1}
    assert summary["required_operator_action_counts"] == %{"review_candidate_rejection" => 1}
    assert summary["candidate_rejection_candidate_id_counts"] == %{"bad_candidate" => 1}
    assert summary["candidate_rejection_ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["branch_local_rejection_pressure"]
    assert summary["branch_local_review_pressure"]
    assert summary["branch_local_invalid_input_pressure"]
  end
end
