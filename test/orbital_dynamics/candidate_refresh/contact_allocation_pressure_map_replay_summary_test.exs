defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationPressureMapReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.{
    BlockedInputIdentityCorrelation,
    CountMapCorrelation,
    OutcomeIdentityCorrelation,
    RowCountCorrelation
  }

  test "allocation count maps merge string-equivalent positive entries" do
    counts = %{
      :allocated => 2,
      "allocated" => 1,
      "negative" => -1,
      "non_integer" => "1",
      "zero" => 0
    }

    assert CountMapCorrelation.positive_counts(counts) == %{"allocated" => 3}
    assert CountMapCorrelation.correlated_counts(counts, 3) == %{"allocated" => 3}
    assert CountMapCorrelation.correlated_counts(counts, 2) == nil
    assert CountMapCorrelation.correlated_counts(counts, nil) == nil
  end

  test "primary outcome counts allow de-duplicated identity cardinality" do
    fields = %{
      "allocated_contact_count" => 1,
      "allocated_contact_ids" => ["allocated_b", "allocated_a", "allocated_a", "bad id"]
    }

    assert OutcomeIdentityCorrelation.fields(fields) == %{
             "allocated_contact_ids" => ["allocated_a", "allocated_b"]
           }

    assert OutcomeIdentityCorrelation.correlated_count(
             3,
             ["allocated_a", "allocated_b"]
           ) == 3
  end

  test "blocked-input counts allow de-duplicated identity cardinality" do
    fields = %{
      "resource_blocked_contact_count" => 1,
      "resource_blocked_contact_ids" => ["resource_b", "resource_a"]
    }

    assert BlockedInputIdentityCorrelation.fields(fields) == %{
             "resource_blocked_contact_ids" => ["resource_a", "resource_b"]
           }
  end

  test "blocked and deferred row counts form a bounded pair" do
    assert RowCountCorrelation.correlated_counts(2, 1, 1) == %{
             "blocked_row_count" => 1,
             "deferred_row_count" => 1
           }

    assert RowCountCorrelation.correlated_counts(nil, 0, 0) == %{
             "blocked_row_count" => 0,
             "deferred_row_count" => 0
           }

    assert RowCountCorrelation.correlated_counts_or_nil(nil, nil, nil) == nil

    assert RowCountCorrelation.correlated_counts(2, 2, 1) == %{
             "blocked_row_count" => 0,
             "deferred_row_count" => 0
           }

    assert RowCountCorrelation.correlated_counts(2, -1, 0) == %{
             "blocked_row_count" => 0,
             "deferred_row_count" => 0
           }
  end

  test "contact allocation replay preserves pressure maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "capacity_pack_selected_contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "capacity_pack_deferred_contact_ids_by_ground_station" => %{
              "equator_prime" => ["deferred_contact"]
            },
            "deferred_contact_ids" => ["deferred_contact"],
            "station_pressure_contact_ids_by_ground_station" => %{
              "polar_prime" => ["station_pressure_contact"]
            },
            "station_pressure_review_contact_ids" => ["station_pressure_contact"],
            "reservation_conflict_contact_ids" => ["reservation_conflict_contact"],
            "invalid_contact_input_ids" => ["invalid_contact"],
            "review_contact_ids" => ["review_contact"],
            "allocation_status_counts" => %{
              "allocated" => 3,
              "zero_status" => 0
            },
            "effective_allocation_status_counts" => %{
              "selected_custom" => 2,
              "zero_effective_status" => 0
            },
            "allocation_reason_counts" => %{
              "selected_by_policy" => 1,
              "zero_reason" => 0
            },
            "direction_counts" => %{
              "Down Link" => 1,
              "tracking" => 1,
              "uplink" => 1
            },
            "contact_ids_by_direction" => %{
              "down" => ["selected_contact"],
              "missing_direction" => ["orphan_contact"],
              "uplink" => ["shifted_uplink_a", "shifted_uplink_b"]
            },
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["selected_contact"]
              },
              "stale_direction" => %{
                "contact_count" => 99,
                "contact_ids" => ["stale_contact"]
              }
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary["source_report_contact_allocation_contract"] ==
             "contact_allocation_report.v1"

    refute Map.has_key?(source_summary, "source_report_contact_allocation_count")
    refute Map.has_key?(source_summary, "source_report_contact_allocation_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_allocation_paths")

    assert source_summary[
             "source_report_contact_allocation_capacity_pack_selected_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["selected_contact"]}

    assert source_summary[
             "source_report_contact_allocation_capacity_pack_deferred_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["deferred_contact"]}

    assert source_summary["source_report_contact_allocation_deferred_contact_ids"] == [
             "deferred_contact"
           ]

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_ground_station"
           ] == %{"polar_prime" => ["station_pressure_contact"]}

    assert source_summary["source_report_contact_allocation_station_pressure_review_contact_ids"] ==
             ["station_pressure_contact"]

    assert source_summary["source_report_contact_allocation_reservation_conflict_contact_ids"] ==
             [
               "reservation_conflict_contact"
             ]

    assert source_summary["source_report_contact_allocation_invalid_contact_input_ids"] == [
             "invalid_contact"
           ]

    assert source_summary["source_report_contact_allocation_review_contact_ids"] == [
             "review_contact"
           ]

    refute Map.has_key?(
             source_summary,
             "source_report_contact_allocation_allocation_status_counts"
           )

    refute Map.has_key?(
             source_summary,
             "source_report_contact_allocation_effective_allocation_status_counts"
           )

    refute Map.has_key?(
             source_summary,
             "source_report_contact_allocation_allocation_reason_counts"
           )

    assert source_summary["source_report_contact_allocation_direction_counts"] == %{
             "downlink" => 1,
             "tracking" => 1,
             "uplink" => 1
           }

    assert source_summary["source_report_contact_allocation_contact_ids_by_direction"] == %{
             "downlink" => ["selected_contact"]
           }

    assert source_summary["source_report_contact_allocation_direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"],
               "provider_reservation_no_request_contact_ids" => [],
               "provider_reservation_request_contact_ids" => [],
               "provider_reservation_review_contact_ids" => [],
               "reservation_conflict_contact_ids" => [],
               "station_pressure_contact_ids" => []
             }
           }

    assert replay_summary["contract"] == "contact_allocation_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []

    assert replay_summary["capacity_pack_selected_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert replay_summary["capacity_pack_deferred_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["deferred_contact"]
           }

    assert replay_summary["deferred_contact_ids"] == ["deferred_contact"]

    assert replay_summary["station_pressure_contact_ids_by_ground_station"] == %{
             "polar_prime" => ["station_pressure_contact"]
           }

    assert replay_summary["station_pressure_review_contact_ids"] == ["station_pressure_contact"]
    assert replay_summary["reservation_conflict_contact_ids"] == ["reservation_conflict_contact"]
    assert replay_summary["invalid_contact_input_ids"] == ["invalid_contact"]
    assert replay_summary["review_contact_ids"] == ["review_contact"]
    assert replay_summary["allocation_status_counts"] == %{}
    assert replay_summary["effective_allocation_status_counts"] == %{}
    assert replay_summary["allocation_reason_counts"] == %{}

    assert replay_summary["direction_counts"] == %{
             "downlink" => 1,
             "tracking" => 1,
             "uplink" => 1
           }

    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["selected_contact"]}

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"],
               "provider_reservation_no_request_contact_ids" => [],
               "provider_reservation_request_contact_ids" => [],
               "provider_reservation_review_contact_ids" => [],
               "reservation_conflict_contact_ids" => [],
               "station_pressure_contact_ids" => []
             }
           }

    assert replay_summary["branch_local_contact_allocation_pressure"]
    assert replay_summary["branch_local_capacity_pack_pressure"]
    assert replay_summary["branch_local_deferred_allocation_pressure"]
    assert replay_summary["branch_local_station_pressure"]
    assert replay_summary["branch_local_reservation_conflict_pressure"]
  end

  test "contact allocation replay retains only maps bounded by row count" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 2,
            "allocation_status_counts" => %{"blocked" => 1, "deferred" => 1},
            "effective_allocation_status_counts" => %{"overstated_custom_status" => 3},
            "allocation_reason_counts" => %{"partial_custom_reason" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary["source_report_contact_allocation_allocation_status_counts"] == %{
             "blocked" => 1,
             "deferred" => 1
           }

    refute Map.has_key?(
             source_summary,
             "source_report_contact_allocation_effective_allocation_status_counts"
           )

    assert source_summary["source_report_contact_allocation_allocation_reason_counts"] == %{
             "partial_custom_reason" => 1
           }

    assert replay_summary["allocation_status_counts"] == %{
             "blocked" => 1,
             "deferred" => 1
           }

    assert replay_summary["effective_allocation_status_counts"] == %{}
    assert replay_summary["allocation_reason_counts"] == %{"partial_custom_reason" => 1}
    assert replay_summary["branch_local_contact_allocation_pressure"]
  end

  test "contact allocation replay ignores zero-only compact count maps" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "allocation_status_counts" => %{"stale_status" => 0},
            "effective_allocation_status_counts" => %{"stale_effective_status" => 0},
            "allocation_reason_counts" => %{"stale_reason" => 0}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    refute Map.has_key?(
             source_summary,
             "source_report_contact_allocation_allocation_status_counts"
           )

    refute Map.has_key?(
             source_summary,
             "source_report_contact_allocation_effective_allocation_status_counts"
           )

    refute Map.has_key?(
             source_summary,
             "source_report_contact_allocation_allocation_reason_counts"
           )

    assert replay_summary["allocation_status_counts"] == %{}
    assert replay_summary["effective_allocation_status_counts"] == %{}
    assert replay_summary["allocation_reason_counts"] == %{}
    refute replay_summary["branch_local_contact_allocation_pressure"]
  end

  test "contact allocation replay preserves identities but drops undersized counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "allocated_contact_count" => 1,
            "allocated_contact_ids" => ["allocated_b", "allocated_a"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    refute Map.has_key?(
             source_summary,
             "source_report_contact_allocation_allocated_contact_count"
           )

    assert source_summary["source_report_contact_allocation_allocated_contact_ids"] == [
             "allocated_a",
             "allocated_b"
           ]

    assert replay_summary["allocated_contact_count"] == nil
    assert replay_summary["allocated_contact_ids"] == ["allocated_a", "allocated_b"]
    assert replay_summary["branch_local_contact_allocation_pressure"]
  end

  test "contact allocation replay rebuilds identities from station routes" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "allocated_contact_ids_by_ground_station" => %{
              "equator_prime" => ["allocated_b", "allocated_a", "allocated_a"],
              "invalid station" => ["orphan_contact"]
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary["source_report_contact_allocation_allocated_contact_ids"] == [
             "allocated_a",
             "allocated_b"
           ]

    assert source_summary[
             "source_report_contact_allocation_allocated_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["allocated_a", "allocated_b"]}

    assert replay_summary["allocated_contact_ids"] == ["allocated_a", "allocated_b"]

    assert replay_summary["allocated_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["allocated_a", "allocated_b"]
           }

    assert replay_summary["branch_local_contact_allocation_pressure"]
  end

  test "contact allocation replay correlates reason-scoped identities" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 1,
            "allocation_reason_counts" => %{"counted_reason" => 1},
            "contact_ids_by_allocation_reason" => %{
              "counted_reason" => ["contact_b", "contact_a"],
              "route_only_reason" => ["route_only_contact"],
              "invalid reason" => ["orphan_contact"]
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary["source_report_contact_allocation_contact_ids_by_allocation_reason"] ==
             %{"route_only_reason" => ["route_only_contact"]}

    assert replay_summary["contact_ids_by_allocation_reason"] == %{
             "route_only_reason" => ["route_only_contact"]
           }

    assert replay_summary["branch_local_contact_allocation_pressure"]
  end

  test "contact allocation replay canonicalizes identity-only review contacts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "review_contact_ids" => ["review_b", "review_a", "review_a", "invalid id"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary["source_report_contact_allocation_review_contact_ids"] == [
             "review_a",
             "review_b"
           ]

    assert replay_summary["review_contact_ids"] == ["review_a", "review_b"]
    assert replay_summary["branch_local_contact_allocation_pressure"]
  end

  test "contact allocation replay correlates station-pressure review identity and count" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "station_pressure_review_contact_count" => 99,
            "station_pressure_review_contact_ids" => [
              "station_review_b",
              "station_review_a",
              "station_review_a",
              "invalid id"
            ]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary[
             "source_report_contact_allocation_station_pressure_review_contact_count"
           ] == 2

    assert source_summary[
             "source_report_contact_allocation_station_pressure_review_contact_ids"
           ] == ["station_review_a", "station_review_b"]

    assert replay_summary["station_pressure_review_contact_count"] == 2

    assert replay_summary["station_pressure_review_contact_ids"] == [
             "station_review_a",
             "station_review_b"
           ]

    assert replay_summary["branch_local_station_pressure"]
  end

  test "contact allocation replay correlates reservation-conflict identity routing" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "reservation_conflict_contact_count" => 99,
            "reservation_conflict_contact_ids" => ["direct_conflict"],
            "reservation_conflict_match_status_counts" => %{
              "overlap" => 2,
              "count_only" => 3,
              "invalid status" => 4
            },
            "reservation_conflict_contact_ids_by_match_status" => %{
              "overlap" => ["match_b", "match_a", "match_a"],
              "invalid status" => ["orphan_contact"]
            },
            "reservation_conflict_reservation_ids_by_match_status" => %{
              "overlap" => ["reservation_b", "reservation_a"],
              "invalid status" => ["orphan_reservation"]
            },
            "reservation_conflict_direction_counts" => %{
              "Down Link" => 1,
              "dl" => 1,
              "tracking" => 2,
              "nil" => 4
            },
            "reservation_conflict_contact_ids_by_direction" => %{
              "Down Link" => ["direction_only"],
              "nil" => ["orphan_contact"]
            },
            "reservation_conflict_contact_ids_by_direction_and_ground_station" => %{
              "dl" => %{
                "equator_prime" => ["nested_only"],
                "invalid station" => ["orphan_contact"]
              }
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    expected_ids = [
      "direct_conflict",
      "direction_only",
      "match_a",
      "match_b",
      "nested_only"
    ]

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_count"
           ] == 5

    assert source_summary["source_report_contact_allocation_reservation_conflict_contact_ids"] ==
             expected_ids

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_match_status"
           ] == %{"overlap" => ["match_a", "match_b"]}

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_match_status_counts"
           ] == %{"count_only" => 3, "overlap" => 2}

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_reservation_ids_by_match_status"
           ] == %{"overlap" => ["reservation_a", "reservation_b"]}

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction"
           ] == %{"downlink" => ["direction_only"]}

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_direction_counts"
           ] == %{"downlink" => 2, "tracking" => 2}

    assert source_summary[
             "source_report_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station"
           ] == %{"downlink" => %{"equator_prime" => ["nested_only"]}}

    assert replay_summary["reservation_conflict_contact_count"] == 5
    assert replay_summary["reservation_conflict_contact_ids"] == expected_ids

    assert replay_summary["reservation_conflict_match_status_counts"] == %{
             "count_only" => 3,
             "overlap" => 2
           }

    assert replay_summary["reservation_conflict_contact_ids_by_match_status"] == %{
             "overlap" => ["match_a", "match_b"]
           }

    assert replay_summary["reservation_conflict_reservation_ids_by_match_status"] == %{
             "overlap" => ["reservation_a", "reservation_b"]
           }

    assert replay_summary["reservation_conflict_contact_ids_by_direction"] == %{
             "downlink" => ["direction_only"]
           }

    assert replay_summary["reservation_conflict_direction_counts"] == %{
             "downlink" => 2,
             "tracking" => 2
           }

    assert replay_summary[
             "reservation_conflict_contact_ids_by_direction_and_ground_station"
           ] == %{"downlink" => %{"equator_prime" => ["nested_only"]}}

    assert replay_summary["branch_local_reservation_conflict_pressure"]
  end

  test "contact allocation replay correlates resource-blocking routes" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "resource_blocked_contact_count" => 1,
            "resource_blocking_dimension_counts" => %{"antenna" => 1, "zero" => 0},
            "resource_blocked_contact_ids_by_blocking_dimension" => %{
              "antenna" => ["resource_b", "resource_a"],
              "route_only_dimension" => ["dimension_only"],
              "invalid dimension" => ["orphan_contact"]
            },
            "resource_blocked_contact_ids_by_spacecraft" => %{
              "leo_1" => ["spacecraft_only"],
              "invalid spacecraft" => ["orphan_contact"]
            },
            "resource_blocked_contact_ids" => ["direct_resource"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary[
             "source_report_contact_allocation_resource_blocking_dimension_counts"
           ] == %{"antenna" => 1}

    assert source_summary[
             "source_report_contact_allocation_resource_blocked_contact_ids_by_blocking_dimension"
           ] == %{"route_only_dimension" => ["dimension_only"]}

    assert source_summary[
             "source_report_contact_allocation_resource_blocked_contact_ids_by_spacecraft"
           ] == %{"leo_1" => ["spacecraft_only"]}

    assert source_summary["source_report_contact_allocation_resource_blocked_contact_ids"] == [
             "dimension_only",
             "direct_resource",
             "spacecraft_only"
           ]

    refute Map.has_key?(
             source_summary,
             "source_report_contact_allocation_resource_blocked_contact_count"
           )

    assert replay_summary["resource_blocking_dimension_counts"] == %{"antenna" => 1}

    assert replay_summary["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "route_only_dimension" => ["dimension_only"]
           }

    assert replay_summary["resource_blocked_contact_ids_by_spacecraft"] == %{
             "leo_1" => ["spacecraft_only"]
           }

    assert replay_summary["resource_blocked_contact_ids"] == [
             "dimension_only",
             "direct_resource",
             "spacecraft_only"
           ]

    assert replay_summary["resource_blocked_contact_count"] == nil
    assert replay_summary["branch_local_contact_allocation_pressure"]
  end

  test "contact allocation replay preserves blocked identities but drops undersized counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "resource_blocked_contact_count" => 1,
            "resource_blocked_contact_ids" => ["resource_b", "resource_a"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    refute Map.has_key?(
             source_summary,
             "source_report_contact_allocation_resource_blocked_contact_count"
           )

    assert source_summary["source_report_contact_allocation_resource_blocked_contact_ids"] == [
             "resource_a",
             "resource_b"
           ]

    assert replay_summary["resource_blocked_contact_count"] == nil
    assert replay_summary["resource_blocked_contact_ids"] == ["resource_a", "resource_b"]
    assert replay_summary["branch_local_contact_allocation_pressure"]
  end

  test "contact allocation replay drops contradictory row-pressure scalars" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 2,
            "blocked_row_count" => 2,
            "deferred_row_count" => 1
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary["source_report_contact_allocation_blocked_row_count"] == 0
    assert source_summary["source_report_contact_allocation_deferred_row_count"] == 0
    assert replay_summary["blocked_row_count"] == 0
    assert replay_summary["deferred_row_count"] == 0
    refute replay_summary["branch_local_blocked_allocation_pressure"]
    refute replay_summary["branch_local_deferred_allocation_pressure"]
    refute replay_summary["branch_local_contact_allocation_pressure"]
  end

  test "contact allocation replay treats preserved ID maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "paths" => ["provenance.source_reports.contact_allocation_report"],
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "blocked_row_count" => 0,
            "deferred_row_count" => 0,
            "station_pressure_contact_count" => 0,
            "station_pressure_review_contact_count" => 0,
            "capacity_pack_required_capacity_fraction" => 0.0,
            "capacity_pack_selected_required_capacity_fraction" => 0.0,
            "capacity_pack_deferred_required_capacity_fraction" => 0.0,
            "capacity_pack_selected_contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "capacity_pack_deferred_contact_ids_by_ground_station" => %{
              "equator_prime" => ["deferred_contact"]
            },
            "deferred_contact_count" => 0,
            "deferred_contact_ids" => ["deferred_contact"],
            "deferred_contact_ids_by_ground_station" => %{
              "equator_prime" => ["deferred_contact"]
            },
            "station_pressure_contact_ids_by_ground_station" => %{
              "polar_prime" => ["station_pressure_contact"]
            },
            "station_pressure_contact_ids_by_availability" => %{
              "reserved" => ["station_pressure_contact"]
            },
            "station_pressure_review_contact_ids" => ["station_pressure_contact"],
            "reservation_conflict_contact_count" => 0,
            "reservation_conflict_contact_ids" => ["reservation_conflict_contact"],
            "invalid_contact_input_count" => 0,
            "invalid_contact_input_ids" => ["invalid_contact"],
            "review_contact_ids" => ["review_contact"],
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_contact_allocation"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert summary["blocked_row_count"] == 0
    assert summary["deferred_row_count"] == 0
    assert summary["station_pressure_contact_count"] == 1
    assert summary["station_pressure_review_contact_count"] == 1
    assert summary["reservation_conflict_contact_count"] == 1
    assert summary["invalid_contact_input_count"] == nil

    assert summary["capacity_pack_selected_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert summary["capacity_pack_deferred_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["deferred_contact"]
           }

    assert summary["deferred_contact_ids"] == ["deferred_contact"]

    assert summary["station_pressure_contact_ids_by_ground_station"] == %{
             "polar_prime" => ["station_pressure_contact"]
           }

    assert summary["reservation_conflict_contact_ids"] == ["reservation_conflict_contact"]
    assert summary["invalid_contact_input_ids"] == ["invalid_contact"]
    assert summary["review_contact_ids"] == ["review_contact"]
    assert summary["branch_local_contact_allocation_pressure"]
    refute summary["branch_local_blocked_allocation_pressure"]
    assert summary["branch_local_deferred_allocation_pressure"]
    assert summary["branch_local_station_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
    assert summary["branch_local_reservation_conflict_pressure"]
  end
end
