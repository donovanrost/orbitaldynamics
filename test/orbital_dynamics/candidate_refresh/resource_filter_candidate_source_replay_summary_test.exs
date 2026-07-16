defmodule OrbitalDynamics.CandidateRefresh.ResourceFilterCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "resource filter replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_filter_report" => %{
              "contract" => "resource_filter_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_resource_filter_report"
              ],
              "suppressed_candidate_count" => 2,
              "invalid_resource_summary_input_count" => 1,
              "invalid_resource_summary_input_ids" => ["bad_branch_resource_summary"],
              "suppressed_reason_counts" => %{"payload_unavailable" => 2},
              "candidate_ids_by_suppressed_reason" => %{
                "payload_unavailable" => ["branch_obs", "branch_downlink"]
              },
              "resource_filter_spacecraft_counts" => %{"leo_1" => 2},
              "candidate_ids_by_spacecraft" => %{
                "leo_1" => ["branch_downlink", "branch_obs"]
              },
              "resource_filter_resource_counts" => %{"payload_1" => 2},
              "candidate_ids_by_resource" => %{
                "payload_1" => ["branch_downlink", "branch_obs"]
              },
              "resource_filter_blocking_dimension_counts" => %{"payload" => 2},
              "candidate_ids_by_blocking_dimension" => %{
                "payload" => ["branch_downlink", "branch_obs"]
              },
              "direction_counts" => %{"downlink" => 1},
              "directions" => ["downlink"],
              "candidate_ids_by_direction" => %{"downlink" => ["branch_downlink"]},
              "direction_routing" => %{
                "downlink" => %{
                  "candidate_count" => 1,
                  "candidate_ids" => ["branch_downlink"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_resource_filter"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_resource_filter_report"],
            "suppressed_candidate_count" => 99,
            "candidate_ids_by_resource" => %{"provenance_resource" => ["provenance_candidate"]}
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_filter_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_filter_report"
           ]

    assert summary["suppressed_candidate_count"] == 2
    assert summary["invalid_resource_summary_input_count"] == 1
    assert summary["invalid_resource_summary_input_ids"] == ["bad_branch_resource_summary"]
    assert summary["suppressed_reason_counts"] == %{"payload_unavailable" => 2}

    assert summary["candidate_ids_by_suppressed_reason"] == %{
             "payload_unavailable" => ["branch_obs", "branch_downlink"]
           }

    assert summary["resource_filter_spacecraft_counts"] == %{"leo_1" => 2}

    assert summary["candidate_ids_by_spacecraft"] == %{
             "leo_1" => ["branch_downlink", "branch_obs"]
           }

    assert summary["resource_filter_resource_counts"] == %{"payload_1" => 2}

    assert summary["candidate_ids_by_resource"] == %{
             "payload_1" => ["branch_downlink", "branch_obs"]
           }

    assert summary["resource_filter_blocking_dimension_counts"] == %{"payload" => 2}

    assert summary["candidate_ids_by_blocking_dimension"] == %{
             "payload" => ["branch_downlink", "branch_obs"]
           }

    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["directions"] == ["downlink"]
    assert summary["candidate_ids_by_direction"] == %{"downlink" => ["branch_downlink"]}

    assert summary["direction_routing"] == %{
             "downlink" => %{
               "candidate_count" => 1,
               "candidate_ids" => ["branch_downlink"]
             }
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_resource_filter"]
    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_invalid_resource_summary_pressure"]
    assert summary["branch_local_resource_blocking_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_filter_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_resource_filter_replay_summary(artifact) ==
             summary
  end

  test "resource filter replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_resource_filter_report"
            ],
            "candidate_ids_by_resource" => %{
              "payload_1" => ["direct_branch_candidate"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_filter_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_filter_report"
           ]

    assert summary["candidate_ids_by_resource"] == %{
             "payload_1" => ["direct_branch_candidate"]
           }

    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_resource_blocking_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_filter_candidate_source_report_summary_only"
  end

  test "resource filter replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_filter_report" => %{},
            "resource_projection_report" => %{
              "contract" => "resource_projection_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_resource_filter_report"],
            "invalid_resource_summary_input_count" => 1,
            "invalid_resource_summary_input_ids" => ["provenance_bad_resource_summary"]
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.resource_filter_report"

    assert summary["source_report_paths"] == ["source_resource_filter_report"]
    assert summary["invalid_resource_summary_input_count"] == 1

    assert summary["invalid_resource_summary_input_ids"] == [
             "provenance_bad_resource_summary"
           ]

    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_invalid_resource_summary_pressure"]
    refute summary["branch_local_candidate_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_filter_source_report_provenance_only"
  end

  test "resource filter replay falls back when branch family is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_projection_report" => %{
              "contract" => "resource_projection_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "paths" => ["source_resource_filter_report"],
            "candidate_ids_by_resource" => %{
              "payload_1" => ["provenance_candidate"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.resource_filter_report"

    assert summary["source_report_paths"] == ["source_resource_filter_report"]

    assert summary["candidate_ids_by_resource"] == %{
             "payload_1" => ["provenance_candidate"]
           }

    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_resource_blocking_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_filter_source_report_provenance_only"
  end

  test "resource filter replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_filter_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_resource_filter_report"
              ],
              "candidate_ids_by_blocking_dimension" => %{
                "payload" => ["partial_branch_candidate"]
              }
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_resource_filter_report"],
            "suppressed_candidate_count" => 9,
            "candidate_ids_by_blocking_dimension" => %{
              "power" => ["provenance_candidate"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_filter_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_filter_report"
           ]

    assert summary["suppressed_candidate_count"] == 0

    assert summary["candidate_ids_by_blocking_dimension"] == %{
             "payload" => ["partial_branch_candidate"]
           }

    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_resource_blocking_pressure"]
    refute summary["branch_local_invalid_resource_summary_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_filter_candidate_source_report_summary_only"
  end
end
