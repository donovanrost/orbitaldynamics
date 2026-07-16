defmodule OrbitalDynamics.CandidateRefresh.LinkCapacityCompactSummaryReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Communications.LinkCapacity

  test "source report summary replays compact link capacity summaries" do
    link_capacity_report = %{
      "schema_contract" => "link_capacity_report.v1",
      "source" => "candidate_refresh.prior_link_capacity",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "contact_count" => 1,
          "effective_contact_count" => 1,
          "selected_contact_count" => 1,
          "selected_downlink_shortfall_mb" => 20.0,
          "actual_downlink_shortfall_mb" => 5.0,
          "capacity_adjusted_throughput_mb" => 80.0,
          "selected_capacity_adjusted_throughput_mb" => 60.0,
          "unused_capacity_adjusted_throughput_mb" => 20.0,
          "downlink_requirement_status" => "shortfall",
          "actual_downlink_requirement_status" => "shortfall",
          "contact_ids" => ["science_downlink"],
          "selected_contact_ids" => ["science_downlink"],
          "actual_throughput_contact_ids" => ["science_downlink"],
          "station_calendar_entry_ids" => ["station_entry_equator"],
          "station_calendar_provider_entry_ids" => ["provider_entry_equator"]
        }
      ]
    }

    summary =
      link_capacity_report
      |> LinkCapacity.summary()
      |> Map.put("provenance", %{"trust_boundary" => "ops_link_capacity_summary"})

    refresh = %{
      "accepted_planning_state" => %{"link_capacity_summary" => summary},
      "mission_state" => %{"source_link_capacity_summary" => summary},
      "source_link_capacity_summary" => summary,
      "source_result_artifact" => %{"link_capacity_summary" => summary}
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_contract" => %{"link_capacity_summary.v1" => 4},
             "source_report_row_counts_by_contract" => %{"link_capacity_summary.v1" => 4},
             "source_report_link_capacity_contract" => "link_capacity_summary.v1",
             "source_report_link_capacity_count" => 4,
             "source_report_link_capacity_row_count" => 4,
             "source_report_link_capacity_paths" => [
               "accepted_planning_state.link_capacity_summary",
               "mission_state.source_link_capacity_summary",
               "source_link_capacity_summary",
               "source_result_artifact.link_capacity_summary"
             ],
             "source_report_link_capacity_selected_shortfall_row_count" => 4,
             "source_report_link_capacity_actual_shortfall_row_count" => 4,
             "source_report_link_capacity_actual_throughput_row_count" => 4,
             "source_report_link_capacity_capacity_adjusted_throughput_row_count" => 4,
             "source_report_link_capacity_capacity_adjusted_throughput_mb_total" => 320.0,
             "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_total" =>
               240.0,
             "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 80.0,
             "source_report_link_capacity_ground_station_counts" => %{"equator_prime" => 4},
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_ground_station" => %{
               "equator_prime" => 320.0
             },
             "source_report_link_capacity_selected_contact_id_counts" => %{
               "science_downlink" => 4
             },
             "source_report_link_capacity_actual_throughput_contact_id_counts" => %{
               "science_downlink" => 4
             },
             "source_report_link_capacity_branch_local_link_capacity_pressure" => true,
             "source_report_link_capacity_branch_local_capacity_adjusted_throughput_pressure" =>
               true,
             "source_report_link_capacity_branch_local_downlink_shortfall_pressure" => true,
             "source_report_link_capacity_branch_local_actual_throughput_pressure" => true,
             "source_reports" => %{
               "link_capacity_report" => %{
                 "paths" => [
                   "accepted_planning_state.link_capacity_summary",
                   "mission_state.source_link_capacity_summary",
                   "source_link_capacity_summary",
                   "source_result_artifact.link_capacity_summary"
                 ],
                 "contract" => "link_capacity_summary.v1",
                 "count" => 4,
                 "row_count" => 4,
                 "source_summary_model_counts" => %{
                   "artifact_only_link_capacity_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "link_capacity_summary.v1" => 4
                 },
                 "source_artifact_type_counts" => %{"link_capacity_report.v1" => 4},
                 "selected_shortfall_row_count" => 4,
                 "actual_shortfall_row_count" => 4,
                 "actual_throughput_row_count" => 4,
                 "capacity_adjusted_throughput_row_count" => 4,
                 "capacity_adjusted_throughput_mb_total" => 320.0,
                 "selected_capacity_adjusted_throughput_mb_total" => 240.0,
                 "unused_capacity_adjusted_throughput_mb_total" => 80.0,
                 "ground_station_counts" => %{"equator_prime" => 4},
                 "capacity_adjusted_throughput_mb_by_ground_station" => %{
                   "equator_prime" => 320.0
                 },
                 "selected_capacity_adjusted_throughput_mb_by_ground_station" => %{
                   "equator_prime" => 240.0
                 },
                 "unused_capacity_adjusted_throughput_mb_by_ground_station" => %{
                   "equator_prime" => 80.0
                 },
                 "selected_contact_ids" => ["science_downlink"],
                 "actual_throughput_contact_ids" => ["science_downlink"],
                 "selected_contact_id_counts" => %{"science_downlink" => 4},
                 "actual_throughput_contact_id_counts" => %{"science_downlink" => 4},
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_link_capacity_summary"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.link_capacity_replay_summary(refresh)

    assert replay_summary["contract"] == "link_capacity_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 4

    assert replay_summary["source_report_paths"] == [
             "accepted_planning_state.link_capacity_summary",
             "mission_state.source_link_capacity_summary",
             "source_link_capacity_summary",
             "source_result_artifact.link_capacity_summary"
           ]

    assert replay_summary["capacity_adjusted_throughput_mb_total"] == 320.0
    assert replay_summary["selected_capacity_adjusted_throughput_mb_total"] == 240.0
    assert replay_summary["unused_capacity_adjusted_throughput_mb_total"] == 80.0
    assert replay_summary["ground_station_counts"] == %{"equator_prime" => 4}
    assert replay_summary["selected_contact_ids"] == ["science_downlink"]
    assert replay_summary["actual_throughput_contact_ids"] == ["science_downlink"]
    assert replay_summary["trust_boundary_status"] == "declared"
    assert replay_summary["trust_boundaries"] == ["ops_link_capacity_summary"]
    assert replay_summary["branch_local_link_capacity_pressure"]
    assert replay_summary["branch_local_capacity_adjusted_throughput_pressure"]
    assert replay_summary["branch_local_downlink_shortfall_pressure"]
    assert replay_summary["branch_local_actual_throughput_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.link_capacity_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_link_capacity_replay_summary(refresh) ==
             replay_summary
  end

  test "link capacity source summaries derive stale aggregate pressure from rows" do
    rows = [
      %{
        "ground_station_id" => "equator_prime",
        "spacecraft_id" => "leo_1",
        "direction" => "Down Link",
        "contact_count" => 1,
        "effective_contact_count" => 1,
        "selected_contact_count" => 1,
        "selected_downlink_shortfall_mb" => 12.0,
        "actual_downlink_shortfall_mb" => 3.0,
        "capacity_adjusted_throughput_mb" => 70.0,
        "selected_capacity_adjusted_throughput_mb" => 45.0,
        "unused_capacity_adjusted_throughput_mb" => 25.0,
        "downlink_requirement_status" => "shortfall",
        "actual_downlink_requirement_status" => "shortfall",
        "contact_ids" => ["row_capacity_contact"],
        "selected_contact_ids" => ["row_capacity_contact"],
        "actual_throughput_contact_ids" => ["row_capacity_contact"],
        "source_window_ids" => ["row_window"],
        "station_calendar_entry_ids" => ["row_station_entry"],
        "station_calendar_provider_entry_ids" => ["row_provider_entry"]
      }
    ]

    stale_summary =
      %{"schema_contract" => "link_capacity_report.v1", "rows" => rows}
      |> LinkCapacity.summary()
      |> Map.put("rows", rows)
      |> Map.put("provenance", %{"trust_boundary" => "row_derived_link_capacity_summary"})
      |> Map.merge(%{
        "station_count" => 99,
        "selected_downlink_shortfall_mb" => 999.0,
        "actual_downlink_shortfall_mb" => 999.0,
        "capacity_adjusted_throughput_mb" => 999.0,
        "selected_capacity_adjusted_throughput_mb" => 999.0,
        "unused_capacity_adjusted_throughput_mb" => 999.0,
        "ground_station_ids" => ["stale_station"],
        "capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "stale_station" => 999.0
        },
        "selected_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "stale_station" => 999.0
        },
        "unused_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "stale_station" => 999.0
        },
        "selected_contact_ids" => ["stale_selected_contact"],
        "actual_throughput_contact_ids" => ["stale_actual_contact"],
        "selected_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_selected_contact"]
        },
        "actual_throughput_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_actual_contact"]
        },
        "contact_ids_by_direction" => %{"uplink" => ["stale_contact"]},
        "source_window_ids_by_direction" => %{"uplink" => ["stale_window"]},
        "direction_routing" => %{
          "uplink" => %{
            "contact_count" => 99,
            "contact_ids" => ["stale_contact"]
          }
        }
      })

    refresh = %{"source_link_capacity_summary" => stale_summary}

    expected_direction_routing = %{
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["row_capacity_contact"],
        "source_window_ids" => ["row_window"],
        "station_calendar_entry_ids" => ["row_station_entry"],
        "station_calendar_provider_entry_ids" => ["row_provider_entry"],
        "capacity_adjusted_throughput_mb" => 70.0,
        "selected_capacity_adjusted_throughput_mb" => 45.0,
        "unused_capacity_adjusted_throughput_mb" => 25.0
      }
    }

    assert %{
             "source_report_link_capacity_contract" => "link_capacity_summary.v1",
             "source_report_link_capacity_count" => 1,
             "source_report_link_capacity_row_count" => 1,
             "source_report_link_capacity_selected_shortfall_row_count" => 1,
             "source_report_link_capacity_actual_shortfall_row_count" => 1,
             "source_report_link_capacity_actual_throughput_row_count" => 1,
             "source_report_link_capacity_capacity_adjusted_throughput_row_count" => 1,
             "source_report_link_capacity_capacity_adjusted_throughput_mb_total" => 70.0,
             "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_total" => 45.0,
             "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 25.0,
             "source_report_link_capacity_ground_station_counts" => %{"equator_prime" => 1},
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_ground_station" => %{
               "equator_prime" => 70.0
             },
             "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_by_ground_station" =>
               %{"equator_prime" => 45.0},
             "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_by_ground_station" =>
               %{"equator_prime" => 25.0},
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_direction" => %{
               "downlink" => 70.0
             },
             "source_report_link_capacity_contact_ids_by_direction" => %{
               "downlink" => ["row_capacity_contact"]
             },
             "source_report_link_capacity_source_window_ids_by_direction" => %{
               "downlink" => ["row_window"]
             },
             "source_report_link_capacity_direction_routing" => ^expected_direction_routing,
             "source_report_link_capacity_selected_contact_ids" => ["row_capacity_contact"],
             "source_report_link_capacity_actual_throughput_contact_ids" => [
               "row_capacity_contact"
             ],
             "source_report_link_capacity_branch_local_link_capacity_pressure" => true,
             "source_report_link_capacity_branch_local_capacity_adjusted_throughput_pressure" =>
               true,
             "source_report_link_capacity_branch_local_downlink_shortfall_pressure" => true,
             "source_report_link_capacity_branch_local_actual_throughput_pressure" => true
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    refute Map.has_key?(
             source_summary["source_report_link_capacity_contact_ids_by_direction"],
             "uplink"
           )

    assert %{
             "source_report_row_count" => 1,
             "capacity_adjusted_throughput_mb_total" => 70.0,
             "selected_capacity_adjusted_throughput_mb_total" => 45.0,
             "unused_capacity_adjusted_throughput_mb_total" => 25.0,
             "ground_station_counts" => %{"equator_prime" => 1},
             "capacity_adjusted_throughput_mb_by_ground_station" => %{
               "equator_prime" => 70.0
             },
             "contact_ids_by_direction" => %{"downlink" => ["row_capacity_contact"]},
             "source_window_ids_by_direction" => %{"downlink" => ["row_window"]},
             "direction_routing" => ^expected_direction_routing,
             "selected_contact_ids" => ["row_capacity_contact"],
             "actual_throughput_contact_ids" => ["row_capacity_contact"],
             "branch_local_link_capacity_pressure" => true,
             "branch_local_capacity_adjusted_throughput_pressure" => true,
             "branch_local_downlink_shortfall_pressure" => true,
             "branch_local_actual_throughput_pressure" => true
           } = CandidateRefresh.link_capacity_replay_summary(refresh)
  end
end
