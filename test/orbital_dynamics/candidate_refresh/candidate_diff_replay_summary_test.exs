defmodule OrbitalDynamics.CandidateRefresh.CandidateDiffReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary preserves candidate diff reasons and routing maps" do
    refresh = %{
      "mission_state" => %{
        "source_candidate_diff_report" => %{
          "schema_contract" => "candidate_diff_report.v1",
          "retained_candidates" => [
            %{
              "id" => "dl_retained",
              "ground_station_id" => "gs_equator",
              "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
              "semantic_change_reasons" => [
                "contact_window_shifted",
                "station_reservation_changed"
              ],
              "candidate_diff_changed_fields" => [
                "starts_at_s",
                "station_reservation_status"
              ],
              "trust_boundary" => "mission_state_candidate_diff_rows"
            }
          ],
          "new_candidates" => [
            %{
              "id" => "dl_new",
              "source_window" => %{"ground_station_id" => "gs_equator"},
              "diff_reason" => "not_present_in_prior_candidate_set"
            }
          ],
          "invalidated_candidates" => [
            %{
              "id" => "dl_stale",
              "source_window" => %{"ground_station_id" => "gs_polar"},
              "invalidated_reason" => "not_present_in_refreshed_candidate_set",
              "semantic_change_reasons" => ["station_reservation_changed"],
              "candidate_diff_changed_fields" => ["station_reservation_status"]
            }
          ],
          "provenance" => %{"trust_boundary" => "mission_state_candidate_diff_report"}
        }
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 3,
             "source_report_candidate_diff_contract" => "candidate_diff_report.v1",
             "source_report_candidate_diff_count" => 1,
             "source_report_candidate_diff_row_count" => 3,
             "source_report_candidate_diff_paths" => [
               "mission_state.source_candidate_diff_report"
             ],
             "source_report_candidate_diff_retained_candidate_count" => 1,
             "source_report_candidate_diff_new_candidate_count" => 1,
             "source_report_candidate_diff_invalidated_candidate_count" => 1,
             "source_report_candidate_diff_diff_reason_counts" => %{
               "not_present_in_prior_candidate_set" => 1,
               "present_in_prior_candidate_set_with_semantic_changes" => 1
             },
             "source_report_candidate_diff_invalidated_reason_counts" => %{
               "not_present_in_refreshed_candidate_set" => 1
             },
             "source_report_candidate_diff_semantic_change_reason_counts" => %{
               "contact_window_shifted" => 1,
               "station_reservation_changed" => 2
             },
             "source_report_candidate_diff_changed_field_counts" => %{
               "starts_at_s" => 1,
               "station_reservation_status" => 2
             },
             "source_report_candidate_diff_candidate_id_counts" => %{
               "dl_new" => 1,
               "dl_retained" => 1,
               "dl_stale" => 1
             },
             "source_report_candidate_diff_ground_station_counts" => %{
               "gs_equator" => 2,
               "gs_polar" => 1
             },
             "source_report_candidate_diff_branch_local_diff_pressure" => true,
             "source_report_candidate_diff_branch_local_new_candidate_pressure" => true,
             "source_report_candidate_diff_branch_local_invalidated_candidate_pressure" => true,
             "source_report_candidate_diff_branch_local_semantic_change_pressure" => true,
             "source_reports" => %{
               "candidate_diff_report" => %{
                 "paths" => ["mission_state.source_candidate_diff_report"],
                 "count" => 1,
                 "row_count" => 3,
                 "retained_candidate_count" => 1,
                 "new_candidate_count" => 1,
                 "invalidated_candidate_count" => 1,
                 "diff_reason_counts" => %{
                   "not_present_in_prior_candidate_set" => 1,
                   "present_in_prior_candidate_set_with_semantic_changes" => 1
                 },
                 "invalidated_reason_counts" => %{
                   "not_present_in_refreshed_candidate_set" => 1
                 },
                 "semantic_change_reason_counts" => %{
                   "contact_window_shifted" => 1,
                   "station_reservation_changed" => 2
                 },
                 "candidate_diff_changed_field_counts" => %{
                   "starts_at_s" => 1,
                   "station_reservation_status" => 2
                 },
                 "candidate_diff_candidate_id_counts" => %{
                   "dl_new" => 1,
                   "dl_retained" => 1,
                   "dl_stale" => 1
                 },
                 "candidate_diff_ground_station_counts" => %{
                   "gs_equator" => 2,
                   "gs_polar" => 1
                 },
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "mission_state_candidate_diff_report",
                   "mission_state_candidate_diff_rows"
                 ]
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "model" => "artifact_only_candidate_refresh_candidate_diff_replay_summary",
             "source" => "candidate_refresh.source_report_provenance.candidate_diff_report",
             "contract" => "candidate_diff_report.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "source_report_paths" => ["mission_state.source_candidate_diff_report"],
             "retained_candidate_count" => 1,
             "new_candidate_count" => 1,
             "invalidated_candidate_count" => 1,
             "diff_reason_counts" => %{
               "not_present_in_prior_candidate_set" => 1,
               "present_in_prior_candidate_set_with_semantic_changes" => 1
             },
             "invalidated_reason_counts" => %{
               "not_present_in_refreshed_candidate_set" => 1
             },
             "semantic_change_reason_counts" => %{
               "contact_window_shifted" => 1,
               "station_reservation_changed" => 2
             },
             "candidate_diff_changed_field_counts" => %{
               "starts_at_s" => 1,
               "station_reservation_status" => 2
             },
             "candidate_diff_candidate_id_counts" => %{
               "dl_new" => 1,
               "dl_retained" => 1,
               "dl_stale" => 1
             },
             "candidate_diff_ground_station_counts" => %{
               "gs_equator" => 2,
               "gs_polar" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "mission_state_candidate_diff_report",
               "mission_state_candidate_diff_rows"
             ],
             "branch_local_diff_pressure" => true,
             "branch_local_new_candidate_pressure" => true,
             "branch_local_invalidated_candidate_pressure" => true,
             "branch_local_semantic_change_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" => "candidate_diff_source_report_provenance_only",
               "operator_authority" => "not_granted_by_candidate_diff_replay_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.candidate_diff_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_candidate_diff_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" =>
          Map.put(summary["source_reports"], "quality_gate_report", %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 1,
            "diff_reason_counts" => %{"unrelated" => 99},
            "trust_boundary_status" => "declared"
          })
      }
    }

    assert %{
             "source_report_family_count" => 2,
             "source_report_candidate_diff_contract" => "candidate_diff_report.v1",
             "source_report_candidate_diff_count" => 1,
             "source_report_candidate_diff_row_count" => 3,
             "source_report_candidate_diff_paths" => [
               "mission_state.source_candidate_diff_report"
             ],
             "source_report_candidate_diff_retained_candidate_count" => 1,
             "source_report_candidate_diff_diff_reason_counts" => %{
               "not_present_in_prior_candidate_set" => 1,
               "present_in_prior_candidate_set_with_semantic_changes" => 1
             },
             "source_report_candidate_diff_ground_station_counts" => %{
               "gs_equator" => 2,
               "gs_polar" => 1
             },
             "source_report_candidate_diff_branch_local_diff_pressure" => true,
             "source_report_candidate_diff_branch_local_new_candidate_pressure" => true,
             "source_report_candidate_diff_branch_local_invalidated_candidate_pressure" => true,
             "source_report_candidate_diff_branch_local_semantic_change_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.candidate_diff_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_candidate_diff_replay_summary(artifact) ==
             replay_summary
  end

  test "candidate diff replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.candidate_diff_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_candidate_diff_contract")
    refute Map.has_key?(source_summary, "source_report_candidate_diff_count")
    refute Map.has_key?(source_summary, "source_report_candidate_diff_row_count")
    refute Map.has_key?(source_summary, "source_report_candidate_diff_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_diff_pressure"]
  end

  test "candidate diff source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "candidate_diff_report.v1"},
      %{"count" => 1},
      %{"row_count" => 3},
      %{"paths" => ["provenance.source_reports.candidate_diff_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.candidate_diff_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "candidate_diff_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_candidate_diff_contract"] ==
                 "candidate_diff_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_candidate_diff_contract")
      end

      refute Map.has_key?(source_summary, "source_report_candidate_diff_count")
      refute Map.has_key?(source_summary, "source_report_candidate_diff_row_count")
      refute Map.has_key?(source_summary, "source_report_candidate_diff_paths")
    end
  end

  test "candidate diff source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "candidate_diff_report" => %{
            "contract" => "candidate_diff_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.candidate_diff_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_candidate_diff_contract"] ==
             "candidate_diff_report.v1"

    assert source_summary["source_report_candidate_diff_count"] == 0
    assert source_summary["source_report_candidate_diff_row_count"] == 0

    assert source_summary["source_report_candidate_diff_paths"] == [
             "provenance.source_reports.candidate_diff_report"
           ]
  end

  test "candidate diff source summary omits missing identity paths after preserving counts" do
    summaries = [
      {"missing paths",
       %{
         "contract" => "candidate_diff_report.v1",
         "count" => 1,
         "row_count" => 3
       }},
      {"nil paths",
       %{
         "contract" => "candidate_diff_report.v1",
         "count" => 1,
         "row_count" => 3,
         "paths" => nil
       }}
    ]

    for {label, candidate_diff_summary} <- summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "candidate_diff_report" => candidate_diff_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_candidate_diff_contract"] ==
               "candidate_diff_report.v1",
             label

      assert source_summary["source_report_candidate_diff_count"] == 1, label
      assert source_summary["source_report_candidate_diff_row_count"] == 3, label
      refute Map.has_key?(source_summary, "source_report_candidate_diff_paths"), label
    end
  end

  test "candidate diff source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "candidate_diff_report" => %{
            "contract" => "candidate_diff_report.v1",
            "count" => 1,
            "row_count" => 3,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_candidate_diff_contract"] ==
             "candidate_diff_report.v1"

    assert source_summary["source_report_candidate_diff_count"] == 1
    assert source_summary["source_report_candidate_diff_row_count"] == 3
    assert source_summary["source_report_candidate_diff_paths"] == []
  end

  test "candidate diff replay preserves pressure maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "candidate_diff_report" => %{
            "contract" => "candidate_diff_report.v1",
            "count" => 1,
            "diff_reason_counts" => %{
              "not_present_in_prior_candidate_set" => 1,
              "present_in_prior_candidate_set_with_semantic_changes" => 1
            },
            "invalidated_reason_counts" => %{
              "not_present_in_refreshed_candidate_set" => 1
            },
            "semantic_change_reason_counts" => %{"contact_window_shifted" => 1},
            "candidate_diff_changed_field_counts" => %{"starts_at_s" => 1},
            "candidate_diff_candidate_id_counts" => %{"changed_candidate" => 1},
            "candidate_diff_ground_station_counts" => %{"equator_prime" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_candidate_diff_count")
    refute Map.has_key?(source_summary, "source_report_candidate_diff_row_count")
    refute Map.has_key?(source_summary, "source_report_candidate_diff_paths")

    assert source_summary["source_report_candidate_diff_diff_reason_counts"] == %{
             "not_present_in_prior_candidate_set" => 1,
             "present_in_prior_candidate_set_with_semantic_changes" => 1
           }

    assert source_summary["source_report_candidate_diff_invalidated_reason_counts"] == %{
             "not_present_in_refreshed_candidate_set" => 1
           }

    assert source_summary["source_report_candidate_diff_semantic_change_reason_counts"] == %{
             "contact_window_shifted" => 1
           }

    assert source_summary["source_report_candidate_diff_changed_field_counts"] == %{
             "starts_at_s" => 1
           }

    assert source_summary["source_report_candidate_diff_candidate_id_counts"] == %{
             "changed_candidate" => 1
           }

    assert source_summary["source_report_candidate_diff_ground_station_counts"] == %{
             "equator_prime" => 1
           }

    summary = CandidateRefresh.candidate_diff_replay_summary(artifact)

    assert summary["branch_local_diff_pressure"]
    assert summary["branch_local_new_candidate_pressure"]
    assert summary["branch_local_invalidated_candidate_pressure"]
    assert summary["branch_local_semantic_change_pressure"]
  end

  test "candidate diff replay treats preserved maps as branch-local pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "candidate_diff_report" => %{
            "contract" => "candidate_diff_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.candidate_diff_report"],
            "retained_candidate_count" => 0,
            "new_candidate_count" => 0,
            "invalidated_candidate_count" => 0,
            "diff_reason_counts" => %{
              "not_present_in_prior_candidate_set" => 1,
              "present_in_prior_candidate_set_with_semantic_changes" => 1
            },
            "invalidated_reason_counts" => %{
              "not_present_in_refreshed_candidate_set" => 1
            },
            "semantic_change_reason_counts" => %{},
            "candidate_diff_changed_field_counts" => %{},
            "candidate_diff_candidate_id_counts" => %{"changed_candidate" => 1},
            "candidate_diff_ground_station_counts" => %{"equator_prime" => 1},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_candidate_diff"]
          }
        }
      }
    }

    summary = CandidateRefresh.candidate_diff_replay_summary(artifact)

    assert summary["retained_candidate_count"] == 0
    assert summary["new_candidate_count"] == 0
    assert summary["invalidated_candidate_count"] == 0

    assert summary["diff_reason_counts"] == %{
             "not_present_in_prior_candidate_set" => 1,
             "present_in_prior_candidate_set_with_semantic_changes" => 1
           }

    assert summary["invalidated_reason_counts"] == %{
             "not_present_in_refreshed_candidate_set" => 1
           }

    assert summary["candidate_diff_candidate_id_counts"] == %{"changed_candidate" => 1}
    assert summary["candidate_diff_ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["branch_local_diff_pressure"]
    assert summary["branch_local_new_candidate_pressure"]
    assert summary["branch_local_invalidated_candidate_pressure"]
    assert summary["branch_local_semantic_change_pressure"]
  end
end
