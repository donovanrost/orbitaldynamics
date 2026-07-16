defmodule OrbitalDynamics.CandidateRefresh.ContactContentionCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "contact contention replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_contention_report" => %{
              "contract" => "contact_contention_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_contention_report"
              ],
              "conflict_group_count" => 2,
              "invalid_contact_input_count" => 1,
              "invalid_contact_input_ids" => ["bad_branch_contact"],
              "resource_scope_counts" => %{"ground_station" => 2},
              "contact_contention_ground_station_counts" => %{"equator_prime" => 2},
              "contact_contention_contact_id_counts" => %{
                "branch_command_contact" => 1,
                "branch_downlink_contact" => 1
              },
              "required_operator_action_counts" => %{
                "review_contact_contention" => 1,
                "review_invalid_contact_contention_input" => 1
              },
              "direction_counts" => %{"command" => 1, "downlink" => 1},
              "contact_ids_by_direction" => %{
                "command" => ["branch_command_contact"],
                "downlink" => ["branch_downlink_contact"]
              },
              "direction_routing" => %{
                "command" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_command_contact"]
                },
                "downlink" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_downlink_contact"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_contact_contention"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["source_contact_contention_report"],
            "conflict_group_count" => 0,
            "invalid_contact_input_count" => 0,
            "contact_contention_contact_id_counts" => %{},
            "required_operator_action_counts" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_contention_report"
           ]

    assert summary["conflict_group_count"] == 2
    assert summary["invalid_contact_input_count"] == 1
    assert summary["invalid_contact_input_ids"] == ["bad_branch_contact"]
    assert summary["resource_scope_counts"] == %{"ground_station" => 2}
    assert summary["contact_contention_ground_station_counts"] == %{"equator_prime" => 2}

    assert summary["contact_contention_contact_id_counts"] == %{
             "branch_command_contact" => 1,
             "branch_downlink_contact" => 1
           }

    assert summary["required_operator_action_counts"] == %{
             "review_contact_contention" => 1,
             "review_invalid_contact_contention_input" => 1
           }

    assert summary["direction_counts"] == %{"command" => 1, "downlink" => 1}

    assert summary["contact_ids_by_direction"] == %{
             "command" => ["branch_command_contact"],
             "downlink" => ["branch_downlink_contact"]
           }

    assert summary["direction_routing"] == %{
             "command" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_command_contact"]
             },
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_downlink_contact"]
             }
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_contact_contention"]
    assert summary["branch_local_contact_contention_pressure"]
    assert summary["branch_local_contact_contention_conflict_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    assert summary["branch_local_contact_contention_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_candidate_source_report_summary_only"

    assert %{
             "source_report_contact_contention_branch_local_contact_contention_pressure" => true,
             "source_report_contact_contention_branch_local_conflict_pressure" => true,
             "source_report_contact_contention_branch_local_invalid_contact_input_pressure" =>
               true,
             "source_report_contact_contention_branch_local_review_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_contact_contention_replay_summary(artifact) ==
             summary
  end

  test "contact contention replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_contact_contention_report"
            ],
            "contact_ids_by_direction" => %{
              "downlink" => ["direct_branch_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_contention_report"
           ]

    assert summary["contact_ids_by_direction"] == %{
             "downlink" => ["direct_branch_contact"]
           }

    assert summary["branch_local_contact_contention_pressure"]
    refute summary["branch_local_contact_contention_conflict_pressure"]
    refute summary["branch_local_invalid_contact_input_pressure"]
    refute summary["branch_local_contact_contention_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_candidate_source_report_summary_only"
  end

  test "contact contention replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_contention_report" => %{},
            "contact_filter_report" => %{
              "contract" => "contact_filter_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_contact_contention_report"],
            "invalid_contact_input_count" => 1,
            "invalid_contact_input_ids" => ["provenance_bad_contact"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_contention_report"

    assert summary["source_report_paths"] == ["source_contact_contention_report"]
    assert summary["invalid_contact_input_count"] == 1
    assert summary["invalid_contact_input_ids"] == ["provenance_bad_contact"]
    assert summary["branch_local_contact_contention_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    refute summary["branch_local_contact_contention_conflict_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_source_report_provenance_only"
  end

  test "contact contention replay falls back when branch family is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_filter_report" => %{
              "contract" => "contact_filter_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 1,
            "paths" => ["source_contact_contention_report"],
            "contact_ids_by_direction" => %{
              "downlink" => ["provenance_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_contention_report"

    assert summary["source_report_paths"] == ["source_contact_contention_report"]

    assert summary["contact_ids_by_direction"] == %{
             "downlink" => ["provenance_contact"]
           }

    assert summary["branch_local_contact_contention_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_source_report_provenance_only"
  end

  test "contact contention replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_contention_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_contention_report"
              ],
              "resource_scope_counts" => %{"ground_station" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_contention_report"],
            "conflict_group_count" => 9,
            "resource_scope_counts" => %{"provenance_scope" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_contention_report"
           ]

    assert summary["conflict_group_count"] == 0
    assert summary["resource_scope_counts"] == %{"ground_station" => 1}
    assert summary["branch_local_contact_contention_pressure"]
    refute summary["branch_local_contact_contention_conflict_pressure"]
    refute summary["branch_local_invalid_contact_input_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_candidate_source_report_summary_only"
  end
end
