defmodule OrbitalDynamics.CandidateRefresh.LinkCapacityPressureReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "link capacity replay treats contact routing and count maps as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_link_capacity_report"],
            "spacecraft_counts" => %{"leo_1" => 1},
            "contact_ids_by_ground_station" => %{"equator_prime" => ["selected_contact"]},
            "contact_ids_by_spacecraft" => %{"leo_1" => ["selected_contact"]},
            "contact_ids_by_requirement_status" => %{"actual_shortfall" => ["actual_contact"]},
            "source_window_ids_by_direction" => %{"downlink" => ["window_selected"]},
            "station_calendar_entry_ids_by_direction" => %{
              "downlink" => ["station_entry_selected"]
            },
            "station_calendar_provider_entry_ids_by_direction" => %{
              "downlink" => ["provider_entry_selected"]
            },
            "source_window_ids_by_ground_station" => %{"equator_prime" => ["window_selected"]},
            "station_calendar_entry_ids_by_ground_station" => %{
              "equator_prime" => ["station_entry_selected"]
            },
            "station_calendar_provider_entry_ids_by_ground_station" => %{
              "equator_prime" => ["provider_entry_selected"]
            },
            "source_window_ids_by_spacecraft" => %{"leo_1" => ["window_selected"]},
            "station_calendar_entry_ids_by_spacecraft" => %{
              "leo_1" => ["station_entry_selected"]
            },
            "station_calendar_provider_entry_ids_by_spacecraft" => %{
              "leo_1" => ["provider_entry_selected"]
            },
            "source_window_ids_by_requirement_status" => %{
              "actual_shortfall" => ["window_actual"]
            },
            "station_calendar_entry_ids_by_requirement_status" => %{
              "actual_shortfall" => ["station_entry_actual"]
            },
            "station_calendar_provider_entry_ids_by_requirement_status" => %{
              "actual_shortfall" => ["provider_entry_actual"]
            },
            "selected_contact_ids" => ["selected_contact"],
            "selected_source_window_ids" => ["window_selected"],
            "selected_station_calendar_entry_ids" => ["station_entry_selected"],
            "selected_station_calendar_provider_entry_ids" => ["provider_entry_selected"],
            "actual_throughput_contact_ids" => ["actual_contact"],
            "actual_throughput_source_window_ids" => ["window_actual"],
            "actual_throughput_station_calendar_entry_ids" => ["station_entry_actual"],
            "actual_throughput_station_calendar_provider_entry_ids" => [
              "provider_entry_actual"
            ],
            "selected_contact_id_counts" => %{"selected_contact" => 1},
            "actual_throughput_contact_id_counts" => %{"actual_contact" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.link_capacity_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["spacecraft_counts"] == %{"leo_1" => 1}
    assert summary["contact_ids_by_ground_station"] == %{"equator_prime" => ["selected_contact"]}
    assert summary["contact_ids_by_spacecraft"] == %{"leo_1" => ["selected_contact"]}

    assert summary["contact_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["actual_contact"]
           }

    assert summary["source_window_ids_by_direction"] == %{"downlink" => ["window_selected"]}

    assert summary["station_calendar_entry_ids_by_direction"] == %{
             "downlink" => ["station_entry_selected"]
           }

    assert summary["station_calendar_provider_entry_ids_by_direction"] == %{
             "downlink" => ["provider_entry_selected"]
           }

    assert summary["source_window_ids_by_ground_station"] == %{
             "equator_prime" => ["window_selected"]
           }

    assert summary["station_calendar_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["station_entry_selected"]
           }

    assert summary["station_calendar_provider_entry_ids_by_ground_station"] == %{
             "equator_prime" => ["provider_entry_selected"]
           }

    assert summary["source_window_ids_by_spacecraft"] == %{
             "leo_1" => ["window_selected"]
           }

    assert summary["station_calendar_entry_ids_by_spacecraft"] == %{
             "leo_1" => ["station_entry_selected"]
           }

    assert summary["station_calendar_provider_entry_ids_by_spacecraft"] == %{
             "leo_1" => ["provider_entry_selected"]
           }

    assert summary["source_window_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["window_actual"]
           }

    assert summary["station_calendar_entry_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["station_entry_actual"]
           }

    assert summary["station_calendar_provider_entry_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["provider_entry_actual"]
           }

    assert summary["selected_contact_id_counts"] == %{"selected_contact" => 1}
    assert summary["selected_contact_ids"] == ["selected_contact"]
    assert summary["selected_source_window_ids"] == ["window_selected"]
    assert summary["selected_station_calendar_entry_ids"] == ["station_entry_selected"]

    assert summary["selected_station_calendar_provider_entry_ids"] == [
             "provider_entry_selected"
           ]

    assert summary["actual_throughput_contact_id_counts"] == %{"actual_contact" => 1}
    assert summary["actual_throughput_contact_ids"] == ["actual_contact"]
    assert summary["actual_throughput_source_window_ids"] == ["window_actual"]

    assert summary["actual_throughput_station_calendar_entry_ids"] == [
             "station_entry_actual"
           ]

    assert summary["actual_throughput_station_calendar_provider_entry_ids"] == [
             "provider_entry_actual"
           ]

    assert summary["branch_local_link_capacity_pressure"]
    assert summary["branch_local_downlink_shortfall_pressure"]
    assert summary["branch_local_actual_throughput_pressure"]
  end

  test "link capacity replay treats capacity-adjusted throughput maps as family pressure" do
    base_summary = %{
      "contract" => "link_capacity_report.v1",
      "count" => 1,
      "row_count" => 0,
      "paths" => ["source_link_capacity_report"],
      "selected_shortfall_row_count" => 0,
      "actual_shortfall_row_count" => 0,
      "actual_throughput_row_count" => 0,
      "capacity_adjusted_throughput_row_count" => 0,
      "capacity_adjusted_throughput_mb_total" => 0.0,
      "selected_capacity_adjusted_throughput_mb_total" => 0.0,
      "unused_capacity_adjusted_throughput_mb_total" => 0.0,
      "ground_station_counts" => %{},
      "capacity_adjusted_throughput_mb_by_ground_station" => %{},
      "selected_capacity_adjusted_throughput_mb_by_ground_station" => %{},
      "unused_capacity_adjusted_throughput_mb_by_ground_station" => %{},
      "capacity_adjusted_throughput_mb_by_direction" => %{},
      "selected_capacity_adjusted_throughput_mb_by_direction" => %{},
      "unused_capacity_adjusted_throughput_mb_by_direction" => %{},
      "downlink_requirement_status_counts" => %{},
      "direction_counts" => %{},
      "spacecraft_counts" => %{},
      "contact_ids_by_direction" => %{},
      "contact_ids_by_ground_station" => %{},
      "contact_ids_by_spacecraft" => %{},
      "contact_ids_by_requirement_status" => %{},
      "selected_contact_id_counts" => %{},
      "selected_contact_ids" => [],
      "actual_throughput_contact_id_counts" => %{},
      "actual_throughput_contact_ids" => []
    }

    cases = [
      {"capacity total", %{"capacity_adjusted_throughput_mb_total" => 120.0}},
      {"selected total", %{"selected_capacity_adjusted_throughput_mb_total" => 80.0}},
      {"unused total", %{"unused_capacity_adjusted_throughput_mb_total" => 40.0}},
      {"capacity station map",
       %{"capacity_adjusted_throughput_mb_by_ground_station" => %{"equator_prime" => 120.0}}},
      {"selected station map",
       %{
         "selected_capacity_adjusted_throughput_mb_by_ground_station" => %{
           "equator_prime" => 80.0
         }
       }},
      {"unused station map",
       %{
         "unused_capacity_adjusted_throughput_mb_by_ground_station" => %{
           "equator_prime" => 40.0
         }
       }},
      {"capacity direction map",
       %{"capacity_adjusted_throughput_mb_by_direction" => %{"downlink" => 120.0}}},
      {"selected direction map",
       %{
         "selected_capacity_adjusted_throughput_mb_by_direction" => %{
           "downlink" => 80.0
         }
       }},
      {"unused direction map",
       %{
         "unused_capacity_adjusted_throughput_mb_by_direction" => %{
           "downlink" => 40.0
         }
       }}
    ]

    for {label, evidence} <- cases do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "link_capacity_report" => Map.merge(base_summary, evidence)
          }
        }
      }

      summary = CandidateRefresh.link_capacity_replay_summary(artifact)

      assert summary["source_report_count"] == 1, label
      assert summary["selected_shortfall_row_count"] == 0, label
      assert summary["actual_shortfall_row_count"] == 0, label
      assert summary["actual_throughput_row_count"] == 0, label
      assert summary["capacity_adjusted_throughput_row_count"] == 0, label
      assert summary["ground_station_counts"] == %{}, label
      assert summary["downlink_requirement_status_counts"] == %{}, label
      assert summary["direction_counts"] == %{}, label
      assert summary["spacecraft_counts"] == %{}, label
      refute summary["branch_local_downlink_shortfall_pressure"], label
      refute summary["branch_local_actual_throughput_pressure"], label
      assert summary["branch_local_capacity_adjusted_throughput_pressure"], label
      assert summary["branch_local_link_capacity_pressure"], label
    end
  end
end
