defmodule OrbitalDynamics.CandidateRefresh.ContactFilterCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "contact filter replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_filter_report" => %{
              "contract" => "contact_filter_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_filter_report"
              ],
              "suppressed_candidate_count" => 2,
              "invalid_contact_input_count" => 1,
              "invalid_contact_input_ids" => ["bad_branch_contact"],
              "suppressed_reason_counts" => %{"ground_station_unavailable" => 2},
              "contact_ids_by_suppressed_reason" => %{
                "ground_station_unavailable" => ["branch_downlink", "branch_tracking"]
              },
              "direction_counts" => %{"downlink" => 1, "tracking" => 1},
              "directions" => ["downlink", "tracking"],
              "contact_ids_by_direction" => %{
                "downlink" => ["branch_downlink"],
                "tracking" => ["branch_tracking"]
              },
              "direction_routing" => %{
                "downlink" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_downlink"]
                }
              },
              "station_suppression_count" => 1,
              "station_suppression_ground_station_counts" => %{"equator_prime" => 1},
              "station_suppression_availability_counts" => %{"unavailable" => 1},
              "station_suppression_status_counts" => %{"unavailable" => 1},
              "station_suppression_contact_ids_by_ground_station" => %{
                "equator_prime" => ["branch_downlink"]
              },
              "station_suppression_contact_ids_by_availability" => %{
                "unavailable" => ["branch_downlink"]
              },
              "station_suppression_contact_ids_by_status" => %{
                "unavailable" => ["branch_downlink"]
              },
              "station_suppression_station_calendar_entry_ids_by_ground_station" => %{
                "equator_prime" => ["entry_branch"]
              },
              "station_suppression_station_calendar_entry_ids_by_availability" => %{
                "unavailable" => ["entry_branch"]
              },
              "station_suppression_station_calendar_entry_ids_by_status" => %{
                "unavailable" => ["entry_branch"]
              },
              "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
                "equator_prime" => ["provider_branch"]
              },
              "station_suppression_station_calendar_provider_entry_ids_by_availability" => %{
                "unavailable" => ["provider_branch"]
              },
              "station_suppression_station_calendar_provider_entry_ids_by_status" => %{
                "unavailable" => ["provider_branch"]
              },
              "station_suppression_station_reservation_ids_by_ground_station" => %{
                "equator_prime" => ["reservation_branch"]
              },
              "station_suppression_station_reservation_ids_by_availability" => %{
                "unavailable" => ["reservation_branch"]
              },
              "station_suppression_station_reservation_ids_by_status" => %{
                "unavailable" => ["reservation_branch"]
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_contact_filter"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_filter_report"],
            "suppressed_candidate_count" => 99,
            "contact_ids_by_suppressed_reason" => %{
              "provenance_reason" => ["provenance_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_filter_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_filter_report"
           ]

    assert summary["suppressed_candidate_count"] == 2
    assert summary["invalid_contact_input_count"] == 1
    assert summary["invalid_contact_input_ids"] == ["bad_branch_contact"]
    assert summary["suppressed_reason_counts"] == %{"ground_station_unavailable" => 2}

    assert summary["contact_ids_by_suppressed_reason"] == %{
             "ground_station_unavailable" => ["branch_downlink", "branch_tracking"]
           }

    assert summary["direction_counts"] == %{"downlink" => 1, "tracking" => 1}
    assert summary["directions"] == ["downlink", "tracking"]

    assert summary["contact_ids_by_direction"] == %{
             "downlink" => ["branch_downlink"],
             "tracking" => ["branch_tracking"]
           }

    assert summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_downlink"]
             }
           }

    assert summary["station_suppression_count"] == 1
    assert summary["station_suppression_ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["station_suppression_availability_counts"] == %{"unavailable" => 1}
    assert summary["station_suppression_status_counts"] == %{"unavailable" => 1}

    assert summary["station_suppression_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_downlink"]
           }

    assert summary["station_suppression_contact_ids_by_availability"] == %{
             "unavailable" => ["branch_downlink"]
           }

    assert summary["station_suppression_contact_ids_by_status"] == %{
             "unavailable" => ["branch_downlink"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["entry_branch"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_availability"] == %{
             "unavailable" => ["entry_branch"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_status"] == %{
             "unavailable" => ["entry_branch"]
           }

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_ground_station"] ==
             %{"equator_prime" => ["provider_branch"]}

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_availability"] ==
             %{"unavailable" => ["provider_branch"]}

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_status"] ==
             %{"unavailable" => ["provider_branch"]}

    assert summary["station_suppression_station_reservation_ids_by_ground_station"] == %{
             "equator_prime" => ["reservation_branch"]
           }

    assert summary["station_suppression_station_reservation_ids_by_availability"] == %{
             "unavailable" => ["reservation_branch"]
           }

    assert summary["station_suppression_station_reservation_ids_by_status"] == %{
             "unavailable" => ["reservation_branch"]
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_contact_filter"]
    assert summary["branch_local_contact_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    assert summary["branch_local_station_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_filter_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_contact_filter_replay_summary(artifact) ==
             summary
  end

  test "contact filter replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_contact_filter_report"
            ],
            "contact_ids_by_direction" => %{
              "downlink" => ["direct_branch_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_filter_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_filter_report"
           ]

    assert summary["contact_ids_by_direction"] == %{
             "downlink" => ["direct_branch_contact"]
           }

    assert summary["branch_local_contact_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_filter_candidate_source_report_summary_only"
  end

  test "contact filter replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_filter_report" => %{},
            "link_capacity_report" => %{
              "contract" => "link_capacity_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_contact_filter_report"],
            "invalid_contact_input_count" => 1,
            "invalid_contact_input_ids" => ["provenance_bad_contact"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_filter_report"

    assert summary["source_report_paths"] == ["source_contact_filter_report"]
    assert summary["invalid_contact_input_count"] == 1
    assert summary["invalid_contact_input_ids"] == ["provenance_bad_contact"]
    assert summary["branch_local_contact_filter_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    refute summary["branch_local_candidate_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_filter_source_report_provenance_only"
  end

  test "contact filter replay falls back when branch family is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "link_capacity_report" => %{
              "contract" => "link_capacity_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "paths" => ["source_contact_filter_report"],
            "contact_ids_by_direction" => %{
              "downlink" => ["provenance_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_filter_report"

    assert summary["source_report_paths"] == ["source_contact_filter_report"]

    assert summary["contact_ids_by_direction"] == %{
             "downlink" => ["provenance_contact"]
           }

    assert summary["branch_local_contact_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_filter_source_report_provenance_only"
  end

  test "contact filter replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_filter_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_filter_report"
              ],
              "station_suppression_contact_ids_by_ground_station" => %{
                "equator_prime" => ["partial_branch_contact"]
              }
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_filter_report"],
            "suppressed_candidate_count" => 9,
            "station_suppression_contact_ids_by_ground_station" => %{
              "dss_43" => ["provenance_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_filter_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_filter_report"
           ]

    assert summary["suppressed_candidate_count"] == 0

    assert summary["station_suppression_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["partial_branch_contact"]
           }

    assert summary["branch_local_contact_filter_pressure"]
    refute summary["branch_local_candidate_suppression_pressure"]
    refute summary["branch_local_invalid_contact_input_pressure"]
    assert summary["branch_local_station_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_filter_candidate_source_report_summary_only"
  end
end
