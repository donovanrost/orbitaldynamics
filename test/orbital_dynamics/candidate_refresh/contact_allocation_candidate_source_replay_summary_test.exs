defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "contact allocation replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_allocation_report" => %{
              "contract" => "contact_allocation_report.v1",
              "count" => 1,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_allocation_report"
              ],
              "blocked_row_count" => 1,
              "deferred_row_count" => 1,
              "allocation_status_counts" => %{"blocked" => 1, "deferred" => 1},
              "effective_allocation_status_counts" => %{
                "resource_blocked" => 1,
                "station_deferred" => 1
              },
              "allocation_reason_counts" => %{"resource_unavailable" => 1},
              "capacity_pack_status_counts" => %{"partial" => 1},
              "capacity_pack_required_capacity_fraction" => 0.5,
              "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                "equator_prime" => 0.5
              },
              "capacity_pack_selected_contact_ids_by_ground_station" => %{
                "equator_prime" => ["branch_selected_contact"]
              },
              "capacity_pack_deferred_contact_ids_by_ground_station" => %{
                "polar_prime" => ["branch_deferred_contact"]
              },
              "capacity_pack_contact_ids_by_ground_station" => %{
                "equator_prime" => ["branch_selected_contact"],
                "polar_prime" => ["branch_deferred_contact"]
              },
              "deferred_contact_ids" => ["branch_deferred_contact"],
              "blocked_contact_ids" => ["branch_blocked_contact"],
              "station_pressure_contact_count" => 1,
              "station_pressure_contact_ids_by_ground_station" => %{
                "polar_prime" => ["branch_deferred_contact"]
              },
              "station_pressure_contact_ids_by_availability" => %{
                "reserved" => ["branch_deferred_contact"]
              },
              "station_pressure_contact_ids_by_precedence_availability" => %{
                "unavailable" => ["branch_deferred_contact"]
              },
              "station_pressure_contact_ids_by_precedence_rank" => %{
                "0" => ["branch_deferred_contact"]
              },
              "station_pressure_contact_ids_by_status" => %{
                "maintenance_window" => ["branch_deferred_contact"]
              },
              "station_pressure_review_contact_ids" => ["branch_deferred_contact"],
              "reservation_conflict_contact_ids" => ["branch_reservation_conflict"],
              "invalid_contact_input_ids" => ["branch_invalid_contact"],
              "review_contact_ids" => ["branch_review_contact"],
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_contact_allocation"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_allocation_report"],
            "blocked_row_count" => 9
          }
        }
      }
    }

    summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_allocation_report"

    assert summary["contract"] == "contact_allocation_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_allocation_report"
           ]

    assert summary["blocked_row_count"] == 1
    assert summary["deferred_row_count"] == 1
    assert summary["allocation_status_counts"] == %{"blocked" => 1, "deferred" => 1}

    assert summary["effective_allocation_status_counts"] == %{
             "resource_blocked" => 1,
             "station_deferred" => 1
           }

    assert summary["allocation_reason_counts"] == %{"resource_unavailable" => 1}
    assert summary["capacity_pack_status_counts"] == %{"partial" => 1}
    assert summary["capacity_pack_required_capacity_fraction"] == 0.5

    assert summary["capacity_pack_required_capacity_fraction_by_ground_station"] == %{
             "equator_prime" => 0.5
           }

    assert summary["capacity_pack_selected_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_selected_contact"]
           }

    assert summary["capacity_pack_deferred_contact_ids_by_ground_station"] == %{
             "polar_prime" => ["branch_deferred_contact"]
           }

    assert summary["capacity_pack_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_selected_contact"],
             "polar_prime" => ["branch_deferred_contact"]
           }

    assert summary["deferred_contact_ids"] == ["branch_deferred_contact"]
    assert summary["blocked_contact_ids"] == ["branch_blocked_contact"]
    assert summary["station_pressure_contact_count"] == 1

    assert summary["station_pressure_contact_ids_by_ground_station"] == %{
             "polar_prime" => ["branch_deferred_contact"]
           }

    assert summary["station_pressure_contact_ids_by_availability"] == %{
             "reserved" => ["branch_deferred_contact"]
           }

    assert summary["station_pressure_contact_ids_by_precedence_availability"] == %{
             "unavailable" => ["branch_deferred_contact"]
           }

    assert summary["station_pressure_contact_ids_by_precedence_rank"] == %{
             "0" => ["branch_deferred_contact"]
           }

    assert summary["station_pressure_contact_ids_by_status"] == %{
             "maintenance_window" => ["branch_deferred_contact"]
           }

    assert summary["station_pressure_review_contact_ids"] == ["branch_deferred_contact"]
    assert summary["reservation_conflict_contact_ids"] == ["branch_reservation_conflict"]
    assert summary["invalid_contact_input_ids"] == ["branch_invalid_contact"]
    assert summary["review_contact_ids"] == ["branch_review_contact"]
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_contact_allocation"]
    assert summary["branch_local_contact_allocation_pressure"]
    assert summary["branch_local_blocked_allocation_pressure"]
    assert summary["branch_local_deferred_allocation_pressure"]
    assert summary["branch_local_station_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
    assert summary["branch_local_reservation_conflict_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_allocation_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_contact_allocation_replay_summary(artifact) ==
             summary
  end

  test "contact allocation replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_contact_allocation_report"
            ],
            "capacity_pack_contact_ids_by_ground_station" => %{
              "equator_prime" => ["direct_branch_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_allocation_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_allocation_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_allocation_report"
           ]

    assert summary["capacity_pack_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["direct_branch_contact"]
           }

    assert summary["branch_local_contact_allocation_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_allocation_candidate_source_report_summary_only"
  end

  test "contact allocation replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_allocation_report" => %{},
            "station_calendar_report" => %{
              "contract" => "station_calendar_provider.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_contact_allocation_report"],
            "blocked_row_count" => 1,
            "blocked_contact_ids" => ["provenance_blocked_contact"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_allocation_report"

    assert summary["source_report_paths"] == ["source_contact_allocation_report"]
    assert summary["blocked_row_count"] == 1
    assert summary["blocked_contact_ids"] == ["provenance_blocked_contact"]
    assert summary["branch_local_contact_allocation_pressure"]
    assert summary["branch_local_blocked_allocation_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_allocation_source_report_provenance_only"
  end

  test "contact allocation replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_allocation_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_allocation_report"
              ],
              "capacity_pack_contact_ids_by_ground_station" => %{
                "equator_prime" => ["partial_branch_contact"]
              }
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_allocation_report"],
            "blocked_row_count" => 9,
            "capacity_pack_contact_ids_by_ground_station" => %{
              "polar_prime" => ["provenance_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_allocation_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_allocation_report"
           ]

    assert summary["blocked_row_count"] == 0

    assert summary["capacity_pack_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["partial_branch_contact"]
           }

    assert summary["branch_local_contact_allocation_pressure"]
    refute summary["branch_local_blocked_allocation_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_allocation_candidate_source_report_summary_only"
  end
end
