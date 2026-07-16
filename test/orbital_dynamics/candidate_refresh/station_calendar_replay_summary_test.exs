defmodule OrbitalDynamics.CandidateRefresh.StationCalendarReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Communications.StationCalendar

  test "station calendar replay preserves direct precedence summaries as station-calendar provenance" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      entries: [
        %{
          id: :equator_reduced,
          station_id: :equator_prime,
          availability: :available,
          capacity_fraction: 0.5,
          start_s: 90.0,
          end_s: 170.0
        },
        %{
          id: :equator_reserved,
          station_id: :equator_prime,
          availability: :reserved,
          reservation_id: :reservation_42,
          reserved_by: :ops_team_b,
          reservation_status: :confirmed,
          start_s: 90.0,
          end_s: 170.0
        },
        %{
          id: :equator_outage,
          station_id: :equator_prime,
          availability: "Outage",
          start_s: 90.0,
          end_s: 170.0
        }
      ]
    }

    precedence_summary =
      contacts
      |> StationCalendar.precedence_summary(provider, source: "ops_calendar")
      |> Map.put("provenance", %{"trust_boundary" => "ops_precedence_summary"})

    refresh = %{
      "accepted_planning_state" => %{
        "station_calendar_precedence_summary" => precedence_summary
      },
      "mission_state" => %{
        "source_station_calendar_precedence_summary" => precedence_summary
      },
      "source_station_calendar_precedence_summary" => precedence_summary,
      "source_result_artifact" => %{
        "schema_contract" => "candidate_refresh.v1",
        "station_calendar_precedence_summary" => precedence_summary,
        "provenance" => %{"trust_boundary" => "artifact_boundary"}
      }
    }

    assert %{
             "source_report_station_calendar_contract" =>
               "station_calendar_precedence_summary.v1",
             "source_report_station_calendar_count" => 4,
             "source_report_station_calendar_row_count" => 4,
             "source_report_station_calendar_paths" => [
               "accepted_planning_state.station_calendar_precedence_summary",
               "mission_state.source_station_calendar_precedence_summary",
               "source_station_calendar_precedence_summary",
               "source_result_artifact.station_calendar_precedence_summary"
             ],
             "source_report_station_calendar_affected_contact_count" => 4,
             "source_report_station_calendar_source_summary_model_counts" => %{
               "artifact_only_station_calendar_precedence_summary" => 4
             },
             "source_report_station_calendar_source_summary_schema_contract_counts" => %{
               "station_calendar_precedence_summary.v1" => 4
             },
             "source_report_station_calendar_source_artifact_type_counts" => %{
               "station_calendar_report.v1" => 4
             },
             "source_report_station_calendar_affected_contact_ids" => ["dl_1"],
             "source_report_station_calendar_contact_ids_by_status" => %{
               "unavailable" => ["dl_1"]
             },
             "source_report_station_calendar_contact_ids_by_availability" => %{
               "unavailable" => ["dl_1"]
             },
             "source_report_station_calendar_applied_availability_counts" => %{
               "unavailable" => 4
             },
             "source_report_station_calendar_overlap_availability_counts" => %{
               "reduced_capacity" => 4,
               "reserved" => 4,
               "unavailable" => 4
             },
             "source_report_station_calendar_affected_contact_ids_by_applied_availability" => %{
               "unavailable" => ["dl_1"]
             },
             "source_report_station_calendar_affected_contact_ids_by_overlap_availability" => %{
               "reduced_capacity" => ["dl_1"],
               "reserved" => ["dl_1"],
               "unavailable" => ["dl_1"]
             },
             "source_report_station_calendar_reserved_under_higher_precedence_contact_count" => 4,
             "source_report_station_calendar_reserved_under_higher_precedence_contact_ids" => [
               "dl_1"
             ],
             "source_report_station_calendar_reserved_under_higher_precedence_contact_ids_by_applied_availability" =>
               %{
                 "unavailable" => ["dl_1"]
               },
             "source_report_station_calendar_reserved_under_higher_precedence_reservation_ids" =>
               [
                 "reservation_42"
               ],
             "source_report_station_calendar_reserved_under_higher_precedence_reservation_ids_by_status" =>
               %{
                 "confirmed" => ["reservation_42"]
               },
             "source_report_station_calendar_reserved_under_higher_precedence_reservation_ids_by_reserved_by" =>
               %{
                 "ops_team_b" => ["reservation_42"]
               },
             "source_report_station_calendar_reserved_under_higher_precedence_contact_ids_by_reservation_status" =>
               %{
                 "confirmed" => ["dl_1"]
               },
             "source_report_station_calendar_reserved_under_higher_precedence_contact_ids_by_reserved_by" =>
               %{
                 "ops_team_b" => ["dl_1"]
               },
             "source_reports" => %{
               "station_calendar_report" => station_summary
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert station_summary["contract"] == "station_calendar_precedence_summary.v1"
    assert station_summary["count"] == 4
    assert station_summary["row_count"] == 4

    assert station_summary["paths"] == [
             "accepted_planning_state.station_calendar_precedence_summary",
             "mission_state.source_station_calendar_precedence_summary",
             "source_station_calendar_precedence_summary",
             "source_result_artifact.station_calendar_precedence_summary"
           ]

    assert station_summary["trust_boundary_status"] == "declared"
    assert station_summary["trust_boundaries"] == ["ops_precedence_summary"]

    assert station_summary["reserved_under_higher_precedence_reservation_ids"] == [
             "reservation_42"
           ]

    assert station_summary["reserved_under_higher_precedence_reservation_ids_by_status"] == %{
             "confirmed" => ["reservation_42"]
           }

    assert station_summary["reserved_under_higher_precedence_reservation_ids_by_reserved_by"] ==
             %{
               "ops_team_b" => ["reservation_42"]
             }

    assert station_summary[
             "reserved_under_higher_precedence_contact_ids_by_reservation_status"
           ] == %{
             "confirmed" => ["dl_1"]
           }

    assert station_summary["reserved_under_higher_precedence_contact_ids_by_reserved_by"] == %{
             "ops_team_b" => ["dl_1"]
           }

    replay_summary = CandidateRefresh.station_calendar_replay_summary(refresh)

    assert replay_summary["contract"] == "station_calendar_precedence_summary.v1"
    assert replay_summary["source_report_paths"] == station_summary["paths"]
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 4

    assert replay_summary["source_summary_model_counts"] ==
             station_summary["source_summary_model_counts"]

    assert replay_summary["source_summary_schema_contract_counts"] ==
             station_summary["source_summary_schema_contract_counts"]

    assert replay_summary["affected_contact_count"] == 4
    assert replay_summary["affected_contact_ids"] == ["dl_1"]
    assert replay_summary["affected_contact_availability_counts"] == %{"unavailable" => 4}
    assert replay_summary["applied_availability_counts"] == %{"unavailable" => 4}

    assert replay_summary["overlap_availability_counts"] == %{
             "reduced_capacity" => 4,
             "reserved" => 4,
             "unavailable" => 4
           }

    assert replay_summary["affected_contact_ids_by_overlap_availability"] == %{
             "reduced_capacity" => ["dl_1"],
             "reserved" => ["dl_1"],
             "unavailable" => ["dl_1"]
           }

    assert replay_summary["reserved_under_higher_precedence_contact_count"] == 4
    assert replay_summary["reserved_under_higher_precedence_contact_ids"] == ["dl_1"]

    assert replay_summary["reserved_under_higher_precedence_reservation_ids"] == [
             "reservation_42"
           ]

    assert replay_summary["reserved_under_higher_precedence_reservation_ids_by_status"] == %{
             "confirmed" => ["reservation_42"]
           }

    assert replay_summary["reserved_under_higher_precedence_reservation_ids_by_reserved_by"] ==
             %{
               "ops_team_b" => ["reservation_42"]
             }

    assert replay_summary[
             "reserved_under_higher_precedence_contact_ids_by_reservation_status"
           ] == %{
             "confirmed" => ["dl_1"]
           }

    assert replay_summary["reserved_under_higher_precedence_contact_ids_by_reserved_by"] == %{
             "ops_team_b" => ["dl_1"]
           }

    assert replay_summary["trust_boundaries"] == ["ops_precedence_summary"]
    assert replay_summary["branch_local_station_calendar_pressure"]
    assert replay_summary["branch_local_affected_contact_pressure"]
    assert replay_summary["branch_local_station_availability_pressure"]
    refute replay_summary["branch_local_provider_contention_pressure"]
  end

  test "source report summary tolerates provider contention without direction evidence" do
    refresh = %{
      "source_station_calendar_report" => %{
        "schema_contract" => "station_calendar_report.v1",
        "provider_calendar_contention_groups" => [
          %{
            "id" => "station_calendar_provider_contention:no_direction",
            "provider_ids" => ["ops_calendar"],
            "provider_entry_ids" => ["provider_entry_no_direction"],
            "ground_station_id" => "equator_prime",
            "source_station_calendar_entries" => [
              %{
                "id" => "provider_entry_source_no_direction",
                "ground_station_id" => "equator_prime"
              }
            ]
          }
        ]
      }
    }

    summary = CandidateRefresh.source_report_summary(refresh)

    assert summary["source_report_station_calendar_provider_calendar_contention_group_count"] == 1

    assert summary["source_report_station_calendar_provider_calendar_contention_group_ids"] == [
             "station_calendar_provider_contention:no_direction"
           ]

    assert summary[
             "source_report_station_calendar_provider_calendar_contention_provider_entry_ids"
           ] ==
             ["provider_entry_no_direction"]

    assert summary["source_report_station_calendar_provider_calendar_contention_source_entry_ids"] ==
             ["provider_entry_source_no_direction"]

    refute Map.has_key?(
             summary,
             "source_report_station_calendar_provider_calendar_contention_direction_counts"
           )

    refute Map.has_key?(summary, "source_report_station_calendar_direction_routing")

    station_summary = get_in(summary, ["source_reports", "station_calendar_report"])

    refute Map.has_key?(station_summary, "provider_calendar_contention_direction_counts")
    refute Map.has_key?(station_summary, "provider_calendar_contention_group_ids_by_direction")

    refute Map.has_key?(
             station_summary,
             "provider_calendar_contention_provider_entry_ids_by_direction"
           )

    refute Map.has_key?(
             station_summary,
             "provider_calendar_contention_provider_ids_by_direction"
           )

    refute Map.has_key?(station_summary, "direction_routing")
  end

  test "station calendar replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.station_calendar_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_station_calendar_contract")
    refute Map.has_key?(source_summary, "source_report_station_calendar_count")
    refute Map.has_key?(source_summary, "source_report_station_calendar_row_count")
    refute Map.has_key?(source_summary, "source_report_station_calendar_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_station_calendar_pressure"]
  end

  test "station calendar source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "station_calendar_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.station_calendar_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.station_calendar_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "station_calendar_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_station_calendar_contract"] ==
                 "station_calendar_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_station_calendar_contract")
      end

      refute Map.has_key?(source_summary, "source_report_station_calendar_count")
      refute Map.has_key?(source_summary, "source_report_station_calendar_row_count")
      refute Map.has_key?(source_summary, "source_report_station_calendar_paths")
    end
  end

  test "station calendar source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_calendar_report" => %{
            "contract" => "station_calendar_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.station_calendar_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_station_calendar_contract"] ==
             "station_calendar_report.v1"

    assert source_summary["source_report_station_calendar_count"] == 0
    assert source_summary["source_report_station_calendar_row_count"] == 0

    assert source_summary["source_report_station_calendar_paths"] == [
             "provenance.source_reports.station_calendar_report"
           ]
  end

  test "station calendar source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_calendar_report" => %{
            "contract" => "station_calendar_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_station_calendar_contract"] ==
             "station_calendar_report.v1"

    assert source_summary["source_report_station_calendar_count"] == 1
    assert source_summary["source_report_station_calendar_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_station_calendar_paths")
  end

  test "station calendar source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_calendar_report" => %{
            "contract" => "station_calendar_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_station_calendar_contract"] ==
             "station_calendar_report.v1"

    assert source_summary["source_report_station_calendar_count"] == 1
    assert source_summary["source_report_station_calendar_row_count"] == 2
    assert source_summary["source_report_station_calendar_paths"] == []
  end

  test "station calendar replay treats preserved capacity and routing maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "station_calendar_report" => %{
            "contract" => "station_calendar_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_station_calendar_report"],
            "affected_contact_count" => 0,
            "provider_calendar_contention_group_count" => 0,
            "affected_contact_ids" => ["contact_map_only"],
            "contact_ids_by_direction" => %{"downlink" => ["contact_map_only"]},
            "provider_calendar_contention_group_ids" => ["contention_group_map_only"],
            "provider_calendar_contention_source_entry_ids" => ["provider_entry_map_only"],
            "provider_calendar_contention_provider_entry_ids" => [
              "provider_calendar_entry_map_only"
            ],
            "provider_calendar_contention_provider_entry_ids_by_provider" => %{
              "ops_calendar" => ["provider_calendar_entry_map_only"]
            },
            "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
              "equator_prime" => ["provider_calendar_entry_map_only"]
            },
            "provider_calendar_contention_provider_ids_by_direction" => %{
              "downlink" => ["ops_calendar"]
            },
            "provider_calendar_contention_provider_entry_ids_by_direction" => %{
              "downlink" => ["provider_calendar_entry_map_only"]
            },
            "provider_calendar_contention_capacity_fractions_by_provider" => %{
              "ops_calendar" => [0.35]
            },
            "provider_calendar_contention_capacity_fractions_by_direction" => %{
              "downlink" => [0.35]
            },
            "station_capacity_fractions_by_ground_station" => %{"equator_prime" => [0.55]}
          }
        }
      }
    }

    summary = CandidateRefresh.station_calendar_replay_summary(artifact)

    assert summary["affected_contact_count"] == 0
    assert summary["provider_calendar_contention_group_count"] == 0
    assert summary["affected_contact_ids"] == ["contact_map_only"]
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["contact_map_only"]}

    assert summary["provider_calendar_contention_group_ids"] == [
             "contention_group_map_only"
           ]

    assert summary["provider_calendar_contention_source_entry_ids"] == [
             "provider_entry_map_only"
           ]

    assert summary["provider_calendar_contention_provider_entry_ids"] == [
             "provider_calendar_entry_map_only"
           ]

    assert summary["provider_calendar_contention_provider_entry_ids_by_provider"] == %{
             "ops_calendar" => ["provider_calendar_entry_map_only"]
           }

    assert summary["provider_calendar_contention_provider_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["provider_calendar_entry_map_only"]
           }

    assert summary["provider_calendar_contention_provider_ids_by_direction"] == %{
             "downlink" => ["ops_calendar"]
           }

    assert summary["provider_calendar_contention_provider_entry_ids_by_direction"] == %{
             "downlink" => ["provider_calendar_entry_map_only"]
           }

    assert summary["provider_calendar_contention_capacity_fractions_by_provider"] == %{
             "ops_calendar" => [0.35]
           }

    assert summary["provider_calendar_contention_capacity_fractions_by_direction"] == %{
             "downlink" => [0.35]
           }

    assert summary["station_capacity_fractions_by_ground_station"] == %{
             "equator_prime" => [0.55]
           }

    assert summary["branch_local_station_calendar_pressure"]
    assert summary["branch_local_affected_contact_pressure"]
    assert summary["branch_local_provider_contention_pressure"]
    assert summary["branch_local_station_availability_pressure"]
  end

  test "station calendar replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "station_calendar_report" => %{
              "contract" => "station_calendar_report.v1",
              "count" => 1,
              "row_count" => 0,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_station_calendar_report"
              ],
              "affected_contact_count" => 0,
              "provider_calendar_contention_group_count" => 0,
              "affected_contact_ids" => ["branch_contact"],
              "contact_ids_by_direction" => %{"downlink" => ["branch_contact"]},
              "provider_calendar_contention_group_ids" => ["branch_contention_group"],
              "provider_calendar_contention_source_entry_ids" => ["branch_source_entry"],
              "provider_calendar_contention_provider_entry_ids" => ["branch_provider_entry"],
              "provider_calendar_contention_provider_entry_ids_by_provider" => %{
                "ops_calendar" => ["branch_provider_entry"]
              },
              "provider_calendar_contention_provider_entry_ids_by_ground_station" => %{
                "equator_prime" => ["branch_provider_entry"]
              },
              "provider_calendar_contention_provider_ids_by_direction" => %{
                "downlink" => ["ops_calendar"]
              },
              "provider_calendar_contention_provider_entry_ids_by_direction" => %{
                "downlink" => ["branch_provider_entry"]
              },
              "provider_calendar_contention_capacity_fractions_by_provider" => %{
                "ops_calendar" => [0.35]
              },
              "provider_calendar_contention_capacity_fractions_by_direction" => %{
                "downlink" => [0.35]
              },
              "station_capacity_fractions_by_ground_station" => %{"equator_prime" => [0.55]},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_station_calendar"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "station_calendar_report" => %{
            "contract" => "station_calendar_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["source_station_calendar_report"],
            "affected_contact_count" => 0,
            "provider_calendar_contention_group_count" => 0,
            "affected_contact_ids" => [],
            "provider_calendar_contention_group_ids" => []
          }
        }
      }
    }

    summary = CandidateRefresh.station_calendar_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.station_calendar_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_station_calendar_report"
           ]

    assert summary["affected_contact_ids"] == ["branch_contact"]
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["branch_contact"]}

    assert summary["provider_calendar_contention_group_ids"] == ["branch_contention_group"]
    assert summary["provider_calendar_contention_source_entry_ids"] == ["branch_source_entry"]
    assert summary["provider_calendar_contention_provider_entry_ids"] == ["branch_provider_entry"]

    assert summary["provider_calendar_contention_provider_entry_ids_by_provider"] == %{
             "ops_calendar" => ["branch_provider_entry"]
           }

    assert summary["provider_calendar_contention_provider_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_provider_entry"]
           }

    assert summary["provider_calendar_contention_provider_ids_by_direction"] == %{
             "downlink" => ["ops_calendar"]
           }

    assert summary["provider_calendar_contention_provider_entry_ids_by_direction"] == %{
             "downlink" => ["branch_provider_entry"]
           }

    assert summary["provider_calendar_contention_capacity_fractions_by_provider"] == %{
             "ops_calendar" => [0.35]
           }

    assert summary["provider_calendar_contention_capacity_fractions_by_direction"] == %{
             "downlink" => [0.35]
           }

    assert summary["station_capacity_fractions_by_ground_station"] == %{
             "equator_prime" => [0.55]
           }

    assert summary["trust_boundaries"] == ["branch_station_calendar"]
    assert summary["branch_local_station_calendar_pressure"]
    assert summary["branch_local_affected_contact_pressure"]
    assert summary["branch_local_provider_contention_pressure"]
    assert summary["branch_local_station_availability_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "station_calendar_candidate_source_report_summary_only"

    assert %{
             "source_report_station_calendar_branch_local_station_calendar_pressure" => true,
             "source_report_station_calendar_branch_local_affected_contact_pressure" => true,
             "source_report_station_calendar_branch_local_provider_contention_pressure" => true,
             "source_report_station_calendar_branch_local_station_availability_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_station_calendar_replay_summary(artifact) == summary
  end
end
