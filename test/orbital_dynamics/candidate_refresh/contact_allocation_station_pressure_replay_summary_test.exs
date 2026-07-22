defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationStationPressureReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary replays contact allocation station-pressure summaries" do
    refresh = %{
      "source_contact_allocation_station_pressure_summary" =>
        contact_allocation_station_pressure_summary_fixture()
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_counts_by_family" => %{"contact_allocation_report" => 1},
             "source_report_contact_allocation_station_pressure_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_contact_ids" => [
               "dl_station_pressure"
             ],
             "source_report_contact_allocation_station_pressure_review_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_ground_station_counts" => %{
               "equator_prime" => 1
             },
             "source_report_contact_allocation_station_pressure_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["dl_station_pressure"]},
             "source_report_contact_allocation_station_pressure_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => ["dl_station_pressure"]}
               },
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "paths" => ["source_contact_allocation_station_pressure_summary"],
                 "station_pressure_summary_schema_contract" =>
                   "contact_allocation_station_pressure_summary.v1"
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "station_pressure_contact_count" => 1,
             "station_pressure_contact_ids" => ["dl_station_pressure"],
             "station_pressure_review_contact_count" => 1,
             "station_pressure_contact_ids_by_ground_station" => %{
               "equator_prime" => ["dl_station_pressure"]
             },
             "station_pressure_contact_ids_by_direction_and_ground_station" => %{
               "downlink" => %{"equator_prime" => ["dl_station_pressure"]}
             },
             "station_pressure_availability_counts" => %{"reserved" => 1},
             "station_pressure_summary_schema_contract" =>
               "contact_allocation_station_pressure_summary.v1",
             "branch_local_contact_allocation_pressure" => true,
             "branch_local_station_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary"
             }
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  test "source report summary preserves station-pressure summary routing maps without rows" do
    summary =
      contact_allocation_station_pressure_summary_fixture()
      |> Map.put("rows", [])
      |> Map.put("review_rows", [])
      |> Map.put("station_pressure_contact_count", 99)
      |> Map.put("station_pressure_review_contact_count", 99)
      |> Map.put("station_pressure_contact_ids_by_direction", %{
        "downlink" => ["dl_station_pressure"]
      })

    refresh = %{"source_contact_allocation_station_pressure_summary" => summary}

    assert %{
             "source_report_contact_allocation_station_pressure_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_contact_ids" => [
               "dl_station_pressure"
             ],
             "source_report_contact_allocation_station_pressure_review_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_contact_ids_by_precedence_availability" =>
               %{"reserved" => ["dl_station_pressure"]},
             "source_report_contact_allocation_station_pressure_contact_ids_by_precedence_rank" =>
               %{"2" => ["dl_station_pressure"]},
             "source_report_contact_allocation_station_pressure_contact_ids_by_direction" => %{
               "downlink" => ["dl_station_pressure"]
             },
             "source_report_contact_allocation_station_pressure_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => ["dl_station_pressure"]}
               },
             "source_report_contact_allocation_station_pressure_review_contact_ids" => [
               "dl_station_pressure"
             ],
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "station_pressure_contact_ids_by_precedence_availability" => %{
                   "reserved" => ["dl_station_pressure"]
                 },
                 "station_pressure_contact_ids_by_precedence_rank" => %{
                   "2" => ["dl_station_pressure"]
                 },
                 "station_pressure_contact_ids_by_direction" => %{
                   "downlink" => ["dl_station_pressure"]
                 },
                 "station_pressure_contact_ids_by_direction_and_ground_station" => %{
                   "downlink" => %{"equator_prime" => ["dl_station_pressure"]}
                 },
                 "station_pressure_review_contact_ids" => ["dl_station_pressure"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "station_pressure_contact_count" => 1,
             "station_pressure_contact_ids" => ["dl_station_pressure"],
             "station_pressure_review_contact_count" => 1,
             "station_pressure_contact_ids_by_precedence_availability" => %{
               "reserved" => ["dl_station_pressure"]
             },
             "station_pressure_contact_ids_by_precedence_rank" => %{
               "2" => ["dl_station_pressure"]
             },
             "station_pressure_contact_ids_by_direction" => %{
               "downlink" => ["dl_station_pressure"]
             },
             "station_pressure_contact_ids_by_direction_and_ground_station" => %{
               "downlink" => %{"equator_prime" => ["dl_station_pressure"]}
             },
             "station_pressure_review_contact_ids" => ["dl_station_pressure"],
             "branch_local_contact_allocation_pressure" => true,
             "branch_local_station_pressure" => true
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.contact_allocation_replay_summary(artifact) ==
             CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  test "contact allocation source summary rederives stale station-pressure provenance counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "station_pressure_contact_count" => 99,
            "station_pressure_review_contact_count" => 99,
            "station_pressure_contact_ids_by_direction_and_ground_station" => %{
              "downlink" => %{
                "equator_prime" => ["station_pressure_a", "station_pressure_b"]
              }
            },
            "station_pressure_review_contact_ids" => ["station_pressure_a"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary["source_report_contact_allocation_station_pressure_contact_count"] == 2

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids"
           ] == ["station_pressure_a", "station_pressure_b"]

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["station_pressure_a", "station_pressure_b"]}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_direction"
           ] == %{"downlink" => ["station_pressure_a", "station_pressure_b"]}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_ground_station_counts"
           ] == nil

    assert source_summary[
             "source_report_contact_allocation_station_pressure_direction_counts"
           ] == nil

    assert get_in(
             source_summary,
             [
               "source_report_contact_allocation_direction_routing",
               "downlink",
               "station_pressure_contact_ids"
             ]
           ) == ["station_pressure_a", "station_pressure_b"]

    assert source_summary[
             "source_report_contact_allocation_station_pressure_review_contact_count"
           ] == 1

    assert replay_summary["station_pressure_contact_count"] == 2

    assert replay_summary["station_pressure_contact_ids"] == [
             "station_pressure_a",
             "station_pressure_b"
           ]

    assert replay_summary["station_pressure_review_contact_count"] == 1

    assert replay_summary["station_pressure_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["station_pressure_a", "station_pressure_b"]
           }

    assert replay_summary["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => ["station_pressure_a", "station_pressure_b"]
           }

    assert replay_summary["station_pressure_ground_station_counts"] == %{}
    assert replay_summary["station_pressure_direction_counts"] == nil

    assert get_in(replay_summary, [
             "direction_routing",
             "downlink",
             "station_pressure_contact_ids"
           ]) == ["station_pressure_a", "station_pressure_b"]

    refute get_in(replay_summary, [
             "direction_routing",
             "downlink",
             "station_pressure_contact_count"
           ])
  end

  test "station-pressure replay correlates parent routes and local counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "station_pressure_contact_count" => 99,
            "station_pressure_contact_ids" => [
              "direct_top_pressure",
              "direct_pressure",
              "direct_top_pressure",
              "invalid contact"
            ],
            "station_pressure_ground_station_counts" => %{
              "equator_prime" => 2,
              "station_count_only" => 3,
              "invalid station" => 4
            },
            "station_pressure_contact_ids_by_ground_station" => %{
              "equator_prime" => ["direct_pressure"]
            },
            "station_pressure_availability_counts" => %{
              "reserved" => 2,
              "availability_count_only" => 3,
              "invalid status" => 4
            },
            "station_pressure_contact_ids_by_availability" => %{
              "reserved" => ["nested_pressure", "direct_pressure", "direct_pressure"],
              "availability_route_only" => ["availability_route"],
              "invalid status" => ["orphan_pressure"]
            },
            "station_pressure_precedence_availability_counts" => %{
              "reduced_capacity" => 1
            },
            "station_pressure_contact_ids_by_precedence_availability" => %{
              "reduced_capacity" => ["direct_pressure", "nested_pressure"]
            },
            "station_pressure_precedence_rank_counts" => %{"2" => 2},
            "station_pressure_contact_ids_by_precedence_rank" => %{
              "2" => ["nested_pressure", "direct_pressure"]
            },
            "station_pressure_status_counts" => %{
              "maintenance" => 0,
              "status_count_only" => 2
            },
            "station_pressure_contact_ids_by_status" => %{
              "maintenance" => ["status_route_only"]
            },
            "station_pressure_direction_counts" => %{
              "Down Link" => 1,
              "dl" => 1,
              "tracking" => 3,
              "nil" => 4
            },
            "station_pressure_contact_ids_by_direction" => %{
              "Down Link" => ["direct_pressure"]
            },
            "station_pressure_contact_ids_by_direction_and_ground_station" => %{
              "dl" => %{"equator_prime" => ["nested_pressure"]}
            },
            "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
              "downlink" => %{
                "equator_prime" => ["nested_pressure"],
                "invalid station" => ["orphan_pressure"]
              }
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)
    expected_ids = ["direct_pressure", "nested_pressure"]

    expected_top_ids = [
      "availability_route",
      "direct_pressure",
      "direct_top_pressure",
      "nested_pressure",
      "status_route_only"
    ]

    assert source_summary["source_report_contact_allocation_station_pressure_contact_count"] == 5

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids"
           ] == expected_top_ids

    assert source_summary[
             "source_report_contact_allocation_station_pressure_ground_station_counts"
           ] == %{"equator_prime" => 2, "station_count_only" => 3}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_ground_station"
           ] == %{"equator_prime" => expected_ids}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_availability_counts"
           ] == %{"availability_count_only" => 3, "reserved" => 2}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_availability"
           ] == %{
             "availability_route_only" => ["availability_route"],
             "reserved" => expected_ids
           }

    assert source_summary[
             "source_report_contact_allocation_station_pressure_precedence_availability_counts"
           ] == nil

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_precedence_availability"
           ] == %{"reduced_capacity" => expected_ids}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_precedence_rank_counts"
           ] == %{"2" => 2}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_precedence_rank"
           ] == %{"2" => expected_ids}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_status_counts"
           ] == %{"status_count_only" => 2}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_status"
           ] == %{"maintenance" => ["status_route_only"]}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_direction_counts"
           ] == %{"downlink" => 2, "tracking" => 3}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_direction"
           ] == %{"downlink" => expected_ids}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_direction_and_ground_station"
           ] == %{"downlink" => %{"equator_prime" => ["nested_pressure"]}}

    assert replay_summary["station_pressure_ground_station_counts"] == %{
             "equator_prime" => 2,
             "station_count_only" => 3
           }

    assert replay_summary["station_pressure_contact_count"] == 5
    assert replay_summary["station_pressure_contact_ids"] == expected_top_ids

    assert replay_summary["station_pressure_contact_ids_by_ground_station"] == %{
             "equator_prime" => expected_ids
           }

    assert replay_summary["station_pressure_availability_counts"] == %{
             "availability_count_only" => 3,
             "reserved" => 2
           }

    assert replay_summary["station_pressure_contact_ids_by_availability"] == %{
             "availability_route_only" => ["availability_route"],
             "reserved" => expected_ids
           }

    assert replay_summary["station_pressure_precedence_availability_counts"] == %{}

    assert replay_summary["station_pressure_contact_ids_by_precedence_availability"] == %{
             "reduced_capacity" => expected_ids
           }

    assert replay_summary["station_pressure_precedence_rank_counts"] == %{"2" => 2}

    assert replay_summary["station_pressure_contact_ids_by_precedence_rank"] == %{
             "2" => expected_ids
           }

    assert replay_summary["station_pressure_status_counts"] == %{"status_count_only" => 2}

    assert replay_summary["station_pressure_contact_ids_by_status"] == %{
             "maintenance" => ["status_route_only"]
           }

    assert replay_summary["station_pressure_direction_counts"] == %{
             "downlink" => 2,
             "tracking" => 3
           }

    assert replay_summary["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => expected_ids
           }

    assert get_in(replay_summary, [
             "direction_routing",
             "downlink",
             "station_pressure_contact_ids"
           ]) == expected_ids

    assert get_in(replay_summary, [
             "direction_routing",
             "downlink",
             "station_pressure_contact_count"
           ]) == 2
  end

  test "undersized station-pressure counts do not suppress parent identity routes" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "station_pressure_ground_station_counts" => %{"equator_prime" => 1},
            "station_pressure_contact_ids_by_ground_station" => %{
              "equator_prime" => ["pressure_a"]
            },
            "station_pressure_direction_counts" => %{"downlink" => 1},
            "station_pressure_contact_ids_by_direction" => %{
              "downlink" => ["pressure_a"]
            },
            "station_pressure_contact_ids_by_direction_and_ground_station" => %{
              "downlink" => %{"equator_prime" => ["pressure_b"]}
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)
    expected_ids = ["pressure_a", "pressure_b"]

    assert source_summary["source_report_contact_allocation_station_pressure_contact_count"] == 2

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids"
           ] == expected_ids

    assert source_summary[
             "source_report_contact_allocation_station_pressure_ground_station_counts"
           ] == nil

    assert source_summary[
             "source_report_contact_allocation_station_pressure_direction_counts"
           ] == nil

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_ground_station"
           ] == %{"equator_prime" => expected_ids}

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_direction"
           ] == %{"downlink" => expected_ids}

    assert replay_summary["station_pressure_ground_station_counts"] == %{}
    assert replay_summary["station_pressure_direction_counts"] == nil

    assert replay_summary["station_pressure_contact_ids_by_ground_station"] == %{
             "equator_prime" => expected_ids
           }

    assert replay_summary["station_pressure_contact_count"] == 2
    assert replay_summary["station_pressure_contact_ids"] == expected_ids

    assert replay_summary["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => expected_ids
           }
  end

  test "contact allocation replay treats explicit empty station-pressure maps as zero counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "station_pressure_contact_count" => 99,
            "station_pressure_contact_ids" => [],
            "station_pressure_review_contact_count" => 99,
            "station_pressure_contact_ids_by_ground_station" => %{},
            "station_pressure_contact_ids_by_direction" => %{},
            "station_pressure_contact_ids_by_direction_and_ground_station" => %{},
            "station_pressure_review_contact_ids" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert source_summary["source_report_contact_allocation_station_pressure_contact_count"] == 0

    assert source_summary[
             "source_report_contact_allocation_station_pressure_review_contact_count"
           ] == 0

    assert replay_summary["station_pressure_contact_count"] == 0
    assert replay_summary["station_pressure_contact_ids"] == nil
    assert replay_summary["station_pressure_review_contact_count"] == 0
    refute replay_summary["branch_local_station_pressure"]
  end

  test "contact allocation station-pressure summary counts non-id ground-station maps" do
    summary =
      contact_allocation_station_pressure_summary_fixture()
      |> Map.put("rows", [])
      |> Map.put("review_rows", [])
      |> Map.put("station_pressure_contact_count", 99)
      |> Map.delete("station_pressure_contact_ids")
      |> Map.put("station_pressure_contact_ids_by_ground_station_id", %{})
      |> Map.delete("station_pressure_contact_ids_by_availability")
      |> Map.delete("station_pressure_contact_ids_by_status")
      |> Map.delete("station_pressure_contact_counts_by_status")
      |> Map.delete("station_pressure_contact_ids_by_precedence_availability")
      |> Map.delete("station_pressure_contact_ids_by_precedence_rank")
      |> Map.delete("station_pressure_contact_ids_by_direction")
      |> Map.delete("station_pressure_contact_ids_by_direction_and_ground_station_id")
      |> Map.put("station_pressure_contact_ids_by_ground_station", %{
        "equator_prime" => ["station_pressure_a"]
      })

    refresh = %{"source_contact_allocation_station_pressure_summary" => summary}
    source_summary = CandidateRefresh.source_report_summary(refresh)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(refresh)

    assert source_summary["source_report_contact_allocation_station_pressure_contact_count"] == 1

    assert source_summary[
             "source_report_contact_allocation_station_pressure_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["station_pressure_a"]}

    assert replay_summary["station_pressure_contact_count"] == 1

    assert replay_summary["station_pressure_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["station_pressure_a"]
           }
  end

  test "contact allocation station-pressure summary falls back to scalar counts" do
    summary =
      contact_allocation_station_pressure_summary_fixture()
      |> Map.put("rows", [])
      |> Map.put("review_rows", [])
      |> Map.put("station_pressure_contact_count", 2)
      |> Map.put("station_pressure_review_contact_count", 1)
      |> Map.delete("station_pressure_contact_ids")
      |> Map.delete("station_pressure_review_contact_ids")
      |> Map.delete("station_pressure_contact_ids_by_ground_station_id")
      |> Map.delete("station_pressure_contact_ids_by_availability")
      |> Map.delete("station_pressure_contact_ids_by_status")
      |> Map.delete("station_pressure_contact_counts_by_status")
      |> Map.delete("station_pressure_contact_ids_by_precedence_availability")
      |> Map.delete("station_pressure_contact_ids_by_precedence_rank")
      |> Map.delete("station_pressure_contact_ids_by_direction")
      |> Map.delete("station_pressure_contact_ids_by_direction_and_ground_station_id")

    refresh = %{"source_contact_allocation_station_pressure_summary" => summary}
    source_summary = CandidateRefresh.source_report_summary(refresh)
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(refresh)

    assert source_summary["source_report_contact_allocation_station_pressure_contact_count"] == 2

    assert source_summary[
             "source_report_contact_allocation_station_pressure_review_contact_count"
           ] == 1

    assert replay_summary["station_pressure_contact_count"] == 2
    assert replay_summary["station_pressure_review_contact_count"] == 1
  end

  defp contact_allocation_station_pressure_summary_fixture do
    nominal_row = %{
      "contact_id" => "dl_nominal",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    station_pressure_row = %{
      "contact_id" => "dl_station_pressure",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_calendar_entry_id" => "station_reserved_1",
      "station_calendar_overlap_availabilities" => ["reserved"],
      "station_calendar_precedence_availability" => "reserved",
      "station_calendar_precedence_rank" => 2,
      "station_calendar_status" => "reserved"
    }

    %{
      "schema_contract" => "contact_allocation_station_pressure_summary.v1",
      "model" => "artifact_only_contact_allocation_station_pressure_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.contact_allocation_station_pressure_summary",
      "input_contact_count" => 2,
      "station_pressure_contact_count" => 1,
      "station_pressure_review_contact_count" => 1,
      "station_pressure_contact_ids" => ["dl_station_pressure"],
      "station_pressure_review_contact_ids" => ["dl_station_pressure"],
      "station_pressure_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_ground_station_id" => %{"equator_prime" => 1},
      "station_pressure_contact_ids_by_availability" => %{"reserved" => ["dl_station_pressure"]},
      "station_pressure_contact_counts_by_availability" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_precedence_availability" => %{
        "reserved" => ["dl_station_pressure"]
      },
      "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_precedence_rank" => %{"2" => ["dl_station_pressure"]},
      "station_pressure_contact_counts_by_precedence_rank" => %{"2" => 1},
      "station_pressure_contact_ids_by_status" => %{"reserved" => ["dl_station_pressure"]},
      "station_pressure_contact_counts_by_status" => %{"reserved" => 1},
      "station_pressure_contact_ids_by_direction" => %{
        "downlink" => ["dl_station_pressure"]
      },
      "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
        "downlink" => %{"equator_prime" => ["dl_station_pressure"]}
      },
      "rows" => [nominal_row, station_pressure_row],
      "review_rows" => [station_pressure_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_station_pressure_summary"
      },
      "provenance" => %{"trust_boundary" => "station_pressure_fixture"}
    }
  end
end
