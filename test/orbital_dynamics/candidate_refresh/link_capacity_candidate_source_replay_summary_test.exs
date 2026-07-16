defmodule OrbitalDynamics.CandidateRefresh.LinkCapacityCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "link capacity replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "link_capacity_report" => %{
              "contract" => "link_capacity_report.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_link_capacity_report"
              ],
              "selected_shortfall_row_count" => 1,
              "actual_shortfall_row_count" => 1,
              "actual_throughput_row_count" => 1,
              "capacity_adjusted_throughput_row_count" => 2,
              "capacity_adjusted_throughput_mb_total" => 85.0,
              "selected_capacity_adjusted_throughput_mb_total" => 40.0,
              "unused_capacity_adjusted_throughput_mb_total" => 45.0,
              "capacity_adjusted_throughput_mb_by_ground_station" => %{
                "equator_prime" => 65.0
              },
              "selected_capacity_adjusted_throughput_mb_by_ground_station" => %{
                "equator_prime" => 25.0
              },
              "unused_capacity_adjusted_throughput_mb_by_ground_station" => %{
                "equator_prime" => 40.0
              },
              "capacity_adjusted_throughput_mb_by_direction" => %{"downlink" => 65.0},
              "selected_capacity_adjusted_throughput_mb_by_direction" => %{
                "downlink" => 25.0
              },
              "unused_capacity_adjusted_throughput_mb_by_direction" => %{
                "downlink" => 40.0
              },
              "ground_station_counts" => %{"equator_prime" => 2},
              "direction_counts" => %{"downlink" => 2},
              "directions" => ["downlink"],
              "spacecraft_counts" => %{"leo_1" => 2},
              "contact_ids_by_direction" => %{"downlink" => ["branch_contact"]},
              "source_window_ids_by_direction" => %{"downlink" => ["branch_window"]},
              "station_calendar_entry_ids_by_direction" => %{
                "downlink" => ["branch_station_entry"]
              },
              "station_calendar_provider_entry_ids_by_direction" => %{
                "downlink" => ["branch_provider_entry"]
              },
              "direction_routing" => %{
                "downlink" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_contact"],
                  "source_window_ids" => ["branch_window"],
                  "station_calendar_entry_ids" => ["branch_station_entry"],
                  "station_calendar_provider_entry_ids" => ["branch_provider_entry"],
                  "capacity_adjusted_throughput_mb" => 65.0,
                  "selected_capacity_adjusted_throughput_mb" => 25.0,
                  "unused_capacity_adjusted_throughput_mb" => 40.0
                }
              },
              "contact_ids_by_ground_station" => %{"equator_prime" => ["branch_contact"]},
              "source_window_ids_by_ground_station" => %{"equator_prime" => ["branch_window"]},
              "station_calendar_entry_ids_by_ground_station" => %{
                "equator_prime" => ["branch_station_entry"]
              },
              "station_calendar_provider_entry_ids_by_ground_station" => %{
                "equator_prime" => ["branch_provider_entry"]
              },
              "contact_ids_by_spacecraft" => %{"leo_1" => ["branch_contact"]},
              "source_window_ids_by_spacecraft" => %{"leo_1" => ["branch_window"]},
              "station_calendar_entry_ids_by_spacecraft" => %{
                "leo_1" => ["branch_station_entry"]
              },
              "station_calendar_provider_entry_ids_by_spacecraft" => %{
                "leo_1" => ["branch_provider_entry"]
              },
              "selected_contact_id_counts" => %{"branch_contact" => 1},
              "selected_contact_ids" => ["branch_contact"],
              "selected_source_window_ids" => ["branch_window"],
              "selected_station_calendar_entry_ids" => ["branch_station_entry"],
              "selected_station_calendar_provider_entry_ids" => ["branch_provider_entry"],
              "actual_throughput_contact_id_counts" => %{"branch_contact" => 1},
              "actual_throughput_contact_ids" => ["branch_contact"],
              "actual_throughput_source_window_ids" => ["branch_window"],
              "actual_throughput_station_calendar_entry_ids" => ["branch_station_entry"],
              "actual_throughput_station_calendar_provider_entry_ids" => [
                "branch_provider_entry"
              ],
              "downlink_requirement_status_counts" => %{"actual_shortfall" => 1},
              "contact_ids_by_requirement_status" => %{
                "actual_shortfall" => ["branch_contact"]
              },
              "source_window_ids_by_requirement_status" => %{
                "actual_shortfall" => ["branch_window"]
              },
              "station_calendar_entry_ids_by_requirement_status" => %{
                "actual_shortfall" => ["branch_station_entry"]
              },
              "station_calendar_provider_entry_ids_by_requirement_status" => %{
                "actual_shortfall" => ["branch_provider_entry"]
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_link_capacity"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_link_capacity_report"],
            "capacity_adjusted_throughput_mb_total" => 999.0,
            "selected_contact_ids" => ["provenance_contact"]
          }
        }
      }
    }

    summary = CandidateRefresh.link_capacity_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.link_capacity_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_link_capacity_report"
           ]

    assert summary["capacity_adjusted_throughput_mb_total"] == 85.0
    assert summary["selected_capacity_adjusted_throughput_mb_total"] == 40.0
    assert summary["unused_capacity_adjusted_throughput_mb_total"] == 45.0

    assert summary["capacity_adjusted_throughput_mb_by_ground_station"] == %{
             "equator_prime" => 65.0
           }

    assert summary["capacity_adjusted_throughput_mb_by_direction"] == %{"downlink" => 65.0}
    assert summary["ground_station_counts"] == %{"equator_prime" => 2}
    assert summary["direction_counts"] == %{"downlink" => 2}
    assert summary["directions"] == ["downlink"]
    assert summary["spacecraft_counts"] == %{"leo_1" => 2}
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["branch_contact"]}
    assert summary["source_window_ids_by_direction"] == %{"downlink" => ["branch_window"]}

    assert summary["station_calendar_entry_ids_by_direction"] == %{
             "downlink" => ["branch_station_entry"]
           }

    assert summary["station_calendar_provider_entry_ids_by_direction"] == %{
             "downlink" => ["branch_provider_entry"]
           }

    assert summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_contact"],
               "source_window_ids" => ["branch_window"],
               "station_calendar_entry_ids" => ["branch_station_entry"],
               "station_calendar_provider_entry_ids" => ["branch_provider_entry"],
               "capacity_adjusted_throughput_mb" => 65.0,
               "selected_capacity_adjusted_throughput_mb" => 25.0,
               "unused_capacity_adjusted_throughput_mb" => 40.0
             }
           }

    assert summary["contact_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_contact"]
           }

    assert summary["source_window_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_window"]
           }

    assert summary["station_calendar_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_station_entry"]
           }

    assert summary["station_calendar_provider_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_provider_entry"]
           }

    assert summary["contact_ids_by_spacecraft"] == %{"leo_1" => ["branch_contact"]}
    assert summary["source_window_ids_by_spacecraft"] == %{"leo_1" => ["branch_window"]}

    assert summary["station_calendar_entry_ids_by_spacecraft"] == %{
             "leo_1" => ["branch_station_entry"]
           }

    assert summary["station_calendar_provider_entry_ids_by_spacecraft"] == %{
             "leo_1" => ["branch_provider_entry"]
           }

    assert summary["selected_contact_id_counts"] == %{"branch_contact" => 1}
    assert summary["selected_contact_ids"] == ["branch_contact"]
    assert summary["selected_source_window_ids"] == ["branch_window"]
    assert summary["selected_station_calendar_entry_ids"] == ["branch_station_entry"]
    assert summary["selected_station_calendar_provider_entry_ids"] == ["branch_provider_entry"]
    assert summary["actual_throughput_contact_id_counts"] == %{"branch_contact" => 1}
    assert summary["actual_throughput_contact_ids"] == ["branch_contact"]
    assert summary["actual_throughput_source_window_ids"] == ["branch_window"]
    assert summary["actual_throughput_station_calendar_entry_ids"] == ["branch_station_entry"]

    assert summary["actual_throughput_station_calendar_provider_entry_ids"] == [
             "branch_provider_entry"
           ]

    assert summary["downlink_requirement_status_counts"] == %{"actual_shortfall" => 1}

    assert summary["contact_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["branch_contact"]
           }

    assert summary["source_window_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["branch_window"]
           }

    assert summary["station_calendar_entry_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["branch_station_entry"]
           }

    assert summary["station_calendar_provider_entry_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["branch_provider_entry"]
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_link_capacity"]
    assert summary["branch_local_link_capacity_pressure"]
    assert summary["branch_local_capacity_adjusted_throughput_pressure"]
    assert summary["branch_local_downlink_shortfall_pressure"]
    assert summary["branch_local_actual_throughput_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "link_capacity_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_link_capacity_replay_summary(artifact) ==
             summary
  end

  test "link capacity replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 1,
            "paths" => ["candidate_source.candidate_refresh_request.source_link_capacity_report"],
            "capacity_adjusted_throughput_mb_by_direction" => %{"downlink" => 42.0}
          }
        }
      }
    }

    summary = CandidateRefresh.link_capacity_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.link_capacity_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_link_capacity_report"
           ]

    assert summary["capacity_adjusted_throughput_mb_by_direction"] == %{"downlink" => 42.0}
    assert summary["branch_local_link_capacity_pressure"]
    assert summary["branch_local_capacity_adjusted_throughput_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "link_capacity_candidate_source_report_summary_only"
  end

  test "link capacity replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "link_capacity_report" => %{},
            "contact_allocation_report" => %{
              "contract" => "contact_allocation_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_link_capacity_report"],
            "actual_shortfall_row_count" => 1,
            "actual_throughput_contact_ids" => ["provenance_actual_contact"]
          }
        }
      }
    }

    summary = CandidateRefresh.link_capacity_replay_summary(artifact)

    assert summary["source"] == "candidate_refresh.source_report_provenance.link_capacity_report"
    assert summary["source_report_paths"] == ["source_link_capacity_report"]
    assert summary["actual_shortfall_row_count"] == 1
    assert summary["actual_throughput_contact_ids"] == ["provenance_actual_contact"]
    assert summary["branch_local_link_capacity_pressure"]
    assert summary["branch_local_downlink_shortfall_pressure"]
    assert summary["branch_local_actual_throughput_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "link_capacity_source_report_provenance_only"
  end

  test "link capacity replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "link_capacity_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_link_capacity_report"
              ],
              "capacity_adjusted_throughput_mb_by_ground_station" => %{
                "equator_prime" => 120.0
              }
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_link_capacity_report"],
            "actual_shortfall_row_count" => 9,
            "capacity_adjusted_throughput_mb_by_ground_station" => %{
              "polar_prime" => 999.0
            }
          }
        }
      }
    }

    summary = CandidateRefresh.link_capacity_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.link_capacity_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_link_capacity_report"
           ]

    assert summary["actual_shortfall_row_count"] == 0

    assert summary["capacity_adjusted_throughput_mb_by_ground_station"] == %{
             "equator_prime" => 120.0
           }

    assert summary["branch_local_link_capacity_pressure"]
    assert summary["branch_local_capacity_adjusted_throughput_pressure"]
    refute summary["branch_local_downlink_shortfall_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "link_capacity_candidate_source_report_summary_only"
  end
end
