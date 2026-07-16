defmodule OrbitalDynamics.CandidateRefresh.ContactFilterReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "contact filter replay treats preserved station maps and invalid IDs as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_contact_filter_report"],
            "suppressed_candidate_count" => 0,
            "invalid_contact_input_count" => 0,
            "invalid_contact_input_ids" => ["bad_contact"],
            "suppressed_reason_counts" => %{"ground_station_unavailable" => 1},
            "contact_ids_by_suppressed_reason" => %{
              "ground_station_unavailable" => ["dl_station_block"]
            },
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["dl_station_block"]},
            "station_suppression_count" => 0,
            "station_suppression_ground_station_counts" => %{"equator_prime" => 1},
            "station_suppression_availability_counts" => %{"unavailable" => 1},
            "station_suppression_status_counts" => %{"unavailable" => 1},
            "station_suppression_contact_ids_by_ground_station" => %{
              "equator_prime" => ["dl_station_block"]
            },
            "station_suppression_contact_ids_by_availability" => %{
              "unavailable" => ["dl_station_block"]
            },
            "station_suppression_contact_ids_by_status" => %{
              "unavailable" => ["dl_station_block"]
            },
            "station_suppression_station_calendar_entry_ids_by_ground_station" => %{
              "equator_prime" => ["entry_station_block"]
            },
            "station_suppression_station_calendar_entry_ids_by_availability" => %{
              "unavailable" => ["entry_station_block"]
            },
            "station_suppression_station_calendar_entry_ids_by_status" => %{
              "unavailable" => ["entry_station_block"]
            },
            "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
              "equator_prime" => ["provider_entry_station_block"]
            },
            "station_suppression_station_calendar_provider_entry_ids_by_availability" => %{
              "unavailable" => ["provider_entry_station_block"]
            },
            "station_suppression_station_calendar_provider_entry_ids_by_status" => %{
              "unavailable" => ["provider_entry_station_block"]
            },
            "station_suppression_station_reservation_ids_by_ground_station" => %{
              "equator_prime" => ["reservation_station_block"]
            },
            "station_suppression_station_reservation_ids_by_availability" => %{
              "unavailable" => ["reservation_station_block"]
            },
            "station_suppression_station_reservation_ids_by_status" => %{
              "unavailable" => ["reservation_station_block"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert summary["suppressed_candidate_count"] == 0
    assert summary["invalid_contact_input_count"] == 0
    assert summary["invalid_contact_input_ids"] == ["bad_contact"]
    assert summary["suppressed_reason_counts"] == %{"ground_station_unavailable" => 1}

    assert summary["contact_ids_by_suppressed_reason"] == %{
             "ground_station_unavailable" => ["dl_station_block"]
           }

    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["dl_station_block"]}
    assert summary["station_suppression_count"] == 0
    assert summary["station_suppression_ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["station_suppression_availability_counts"] == %{"unavailable" => 1}
    assert summary["station_suppression_status_counts"] == %{"unavailable" => 1}

    assert summary["station_suppression_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["dl_station_block"]
           }

    assert summary["station_suppression_contact_ids_by_availability"] == %{
             "unavailable" => ["dl_station_block"]
           }

    assert summary["station_suppression_contact_ids_by_status"] == %{
             "unavailable" => ["dl_station_block"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["entry_station_block"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_availability"] == %{
             "unavailable" => ["entry_station_block"]
           }

    assert summary["station_suppression_station_calendar_entry_ids_by_status"] == %{
             "unavailable" => ["entry_station_block"]
           }

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_ground_station"] ==
             %{
               "equator_prime" => ["provider_entry_station_block"]
             }

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_availability"] ==
             %{
               "unavailable" => ["provider_entry_station_block"]
             }

    assert summary["station_suppression_station_calendar_provider_entry_ids_by_status"] == %{
             "unavailable" => ["provider_entry_station_block"]
           }

    assert summary["station_suppression_station_reservation_ids_by_ground_station"] == %{
             "equator_prime" => ["reservation_station_block"]
           }

    assert summary["station_suppression_station_reservation_ids_by_availability"] == %{
             "unavailable" => ["reservation_station_block"]
           }

    assert summary["station_suppression_station_reservation_ids_by_status"] == %{
             "unavailable" => ["reservation_station_block"]
           }

    assert summary["branch_local_contact_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    assert summary["branch_local_station_suppression_pressure"]
  end

  test "contact filter replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_contact_filter_contract")
    refute Map.has_key?(source_summary, "source_report_contact_filter_count")
    refute Map.has_key?(source_summary, "source_report_contact_filter_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_filter_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_contact_filter_pressure"]
  end

  test "contact filter source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "contact_filter_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.contact_filter_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.contact_filter_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_filter_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_contact_filter_contract"] ==
                 "contact_filter_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_contact_filter_contract")
      end

      refute Map.has_key?(source_summary, "source_report_contact_filter_count")
      refute Map.has_key?(source_summary, "source_report_contact_filter_row_count")
      refute Map.has_key?(source_summary, "source_report_contact_filter_paths")
    end
  end

  test "contact filter source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.contact_filter_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_contact_filter_contract"] ==
             "contact_filter_report.v1"

    assert source_summary["source_report_contact_filter_count"] == 0
    assert source_summary["source_report_contact_filter_row_count"] == 0

    assert source_summary["source_report_contact_filter_paths"] == [
             "provenance.source_reports.contact_filter_report"
           ]
  end

  test "contact filter source summary omits missing identity paths after preserving counts" do
    partial_summaries = [
      %{
        "contract" => "contact_filter_report.v1",
        "count" => 1,
        "row_count" => 2
      },
      %{
        "contract" => "contact_filter_report.v1",
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
            "contact_filter_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)
      replay_summary = CandidateRefresh.contact_filter_replay_summary(artifact)

      assert source_summary["source_report_contact_filter_contract"] ==
               "contact_filter_report.v1"

      assert source_summary["source_report_contact_filter_count"] == 1
      assert source_summary["source_report_contact_filter_row_count"] == 2
      refute Map.has_key?(source_summary, "source_report_contact_filter_paths")

      assert replay_summary["contract"] == "contact_filter_report.v1"
      assert replay_summary["source_report_count"] == 1
      assert replay_summary["source_report_row_count"] == 2
      assert replay_summary["source_report_paths"] == []
    end
  end

  test "contact filter source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert source_summary["source_report_contact_filter_contract"] ==
             "contact_filter_report.v1"

    assert source_summary["source_report_contact_filter_count"] == 1
    assert source_summary["source_report_contact_filter_row_count"] == 2
    assert Map.has_key?(source_summary, "source_report_contact_filter_paths")
    assert source_summary["source_report_contact_filter_paths"] == []

    assert replay_summary["contract"] == "contact_filter_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 2
    assert replay_summary["source_report_paths"] == []
  end

  test "contact filter replay preserves suppression and station maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_filter_report" => %{
            "contract" => "contact_filter_report.v1",
            "count" => 1,
            "suppressed_reason_counts" => %{"ground_station_unavailable" => 1},
            "contact_ids_by_suppressed_reason" => %{
              "ground_station_unavailable" => ["filtered_contact"]
            },
            "invalid_contact_input_ids" => ["invalid_contact"],
            "direction_counts" => %{"downlink" => 1},
            "directions" => ["downlink"],
            "contact_ids_by_direction" => %{"downlink" => ["filtered_contact"]},
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["filtered_contact"]
              }
            },
            "station_suppression_ground_station_counts" => %{"equator_prime" => 1},
            "station_suppression_availability_counts" => %{"unavailable" => 1},
            "station_suppression_status_counts" => %{"unavailable" => 1},
            "station_suppression_contact_ids_by_ground_station" => %{
              "equator_prime" => ["filtered_contact"]
            },
            "station_suppression_station_calendar_entry_ids_by_ground_station" => %{
              "equator_prime" => ["station_entry"]
            },
            "station_suppression_station_calendar_provider_entry_ids_by_ground_station" => %{
              "equator_prime" => ["provider_entry"]
            },
            "station_suppression_station_reservation_ids_by_ground_station" => %{
              "equator_prime" => ["reservation"]
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_filter_replay_summary(artifact)

    assert source_summary["source_report_contact_filter_contract"] ==
             "contact_filter_report.v1"

    refute Map.has_key?(source_summary, "source_report_contact_filter_count")
    refute Map.has_key?(source_summary, "source_report_contact_filter_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_filter_paths")

    assert source_summary["source_report_contact_filter_suppressed_reason_counts"] == %{
             "ground_station_unavailable" => 1
           }

    assert source_summary["source_report_contact_filter_contact_ids_by_suppressed_reason"] == %{
             "ground_station_unavailable" => ["filtered_contact"]
           }

    assert source_summary["source_report_contact_filter_invalid_contact_input_ids"] == [
             "invalid_contact"
           ]

    assert source_summary["source_report_contact_filter_direction_counts"] == %{"downlink" => 1}
    assert source_summary["source_report_contact_filter_directions"] == ["downlink"]

    assert source_summary["source_report_contact_filter_contact_ids_by_direction"] == %{
             "downlink" => ["filtered_contact"]
           }

    assert source_summary["source_report_contact_filter_direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["filtered_contact"]
             }
           }

    assert source_summary[
             "source_report_contact_filter_station_suppression_ground_station_counts"
           ] ==
             %{"equator_prime" => 1}

    assert source_summary["source_report_contact_filter_station_suppression_availability_counts"] ==
             %{"unavailable" => 1}

    assert source_summary["source_report_contact_filter_station_suppression_status_counts"] == %{
             "unavailable" => 1
           }

    assert source_summary[
             "source_report_contact_filter_station_suppression_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["filtered_contact"]}

    assert source_summary[
             "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_ground_station"
           ] == %{"equator_prime" => ["station_entry"]}

    assert source_summary[
             "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_ground_station"
           ] == %{"equator_prime" => ["provider_entry"]}

    assert source_summary[
             "source_report_contact_filter_station_suppression_station_reservation_ids_by_ground_station"
           ] == %{"equator_prime" => ["reservation"]}

    assert replay_summary["contract"] == "contact_filter_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []
    assert replay_summary["suppressed_reason_counts"] == %{"ground_station_unavailable" => 1}

    assert replay_summary["contact_ids_by_suppressed_reason"] == %{
             "ground_station_unavailable" => ["filtered_contact"]
           }

    assert replay_summary["invalid_contact_input_ids"] == ["invalid_contact"]
    assert replay_summary["direction_counts"] == %{"downlink" => 1}
    assert replay_summary["directions"] == ["downlink"]
    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["filtered_contact"]}

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["filtered_contact"]
             }
           }

    assert replay_summary["station_suppression_ground_station_counts"] == %{
             "equator_prime" => 1
           }

    assert replay_summary["station_suppression_availability_counts"] == %{"unavailable" => 1}
    assert replay_summary["station_suppression_status_counts"] == %{"unavailable" => 1}

    assert replay_summary["station_suppression_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["filtered_contact"]
           }

    assert replay_summary[
             "station_suppression_station_calendar_entry_ids_by_ground_station"
           ] == %{"equator_prime" => ["station_entry"]}

    assert replay_summary[
             "station_suppression_station_calendar_provider_entry_ids_by_ground_station"
           ] == %{"equator_prime" => ["provider_entry"]}

    assert replay_summary["station_suppression_station_reservation_ids_by_ground_station"] == %{
             "equator_prime" => ["reservation"]
           }

    assert replay_summary["branch_local_contact_filter_pressure"]
    assert replay_summary["branch_local_candidate_suppression_pressure"]
    assert replay_summary["branch_local_invalid_contact_input_pressure"]
    assert replay_summary["branch_local_station_suppression_pressure"]
  end
end
