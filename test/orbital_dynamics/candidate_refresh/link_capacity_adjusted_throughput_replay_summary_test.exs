defmodule OrbitalDynamics.CandidateRefresh.LinkCapacityAdjustedThroughputReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates link capacity adjusted throughput" do
    refresh = %{
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => [
          %{
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "capacity_adjusted_throughput_mb" => 65.0,
            "selected_capacity_adjusted_throughput_mb" => 25.0,
            "unused_capacity_adjusted_throughput_mb" => 40.0,
            "selected_downlink_shortfall_mb" => 12.0,
            "actual_throughput_mb" => 21.0,
            "source_window_id" => "window_alpha",
            "station_calendar_entry_ids" => ["station_entry_alpha", "station_entry_beta"],
            "station_calendar_provider_entry_ids" => [
              "provider_entry_alpha",
              "provider_entry_beta"
            ],
            "selected_contacts" => [
              %{
                "id" => "contact_alpha",
                "direction" => "Down Link",
                "source_window_id" => "window_alpha",
                "station_calendar_entry_id" => "station_entry_alpha",
                "station_calendar_provider_entry_id" => "provider_entry_alpha"
              },
              %{
                "id" => "contact_beta",
                "direction" => "tracking_pass",
                "source_window_id" => "window_beta",
                "station_calendar_entry_id" => "station_entry_beta",
                "station_calendar_provider_entry_id" => "provider_entry_beta"
              }
            ],
            "actual_throughput_contact" => %{
              "id" => "contact_alpha",
              "source_window_id" => "window_alpha",
              "station_calendar_entry_id" => "station_entry_alpha",
              "station_calendar_provider_entry_id" => "provider_entry_alpha"
            },
            "downlink_requirement_status" => "selected_shortfall",
            "actual_downlink_requirement_status" => "actual_met"
          },
          %{
            "spacecraft_id" => "leo_2",
            "ground_station_id" => "dss_43",
            "direction" => "s-band command",
            "capacity_adjusted_throughput_mb" => 20.0,
            "selected_capacity_adjusted_throughput_mb" => 15.0,
            "unused_capacity_adjusted_throughput_mb" => 5.0,
            "actual_downlink_shortfall_mb" => 7.0,
            "source_window_ids" => ["window_gamma"],
            "station_calendar_entry_id" => "station_entry_gamma",
            "station_calendar_provider_entry_id" => "provider_entry_gamma",
            "selected_contact" => %{
              "id" => "contact_gamma",
              "source_window_id" => "window_gamma",
              "station_calendar_entry_id" => "station_entry_gamma",
              "station_calendar_provider_entry_id" => "provider_entry_gamma"
            },
            "actual_throughput_contact" => %{
              "id" => "contact_gamma",
              "source_window_id" => "window_gamma",
              "station_calendar_entry_id" => "station_entry_gamma",
              "station_calendar_provider_entry_id" => "provider_entry_gamma"
            },
            "downlink_requirement_status" => "selected_met",
            "actual_downlink_requirement_status" => "actual_shortfall"
          }
        ],
        "capacity_adjusted_throughput_mb_total" => 999.0,
        "selected_capacity_adjusted_throughput_mb_total" => 999.0,
        "unused_capacity_adjusted_throughput_mb_total" => 999.0,
        "capacity_adjusted_throughput_mb_by_ground_station" => %{"stale_station" => 999.0},
        "spacecraft_counts" => %{"stale_spacecraft" => 99},
        "contact_ids_by_ground_station" => %{"stale_station" => ["stale_contact"]},
        "contact_ids_by_spacecraft" => %{"stale_spacecraft" => ["stale_contact"]},
        "contact_ids_by_requirement_status" => %{"stale_status" => ["stale_contact"]},
        "selected_contact_ids" => ["stale_selected_contact"],
        "selected_source_window_ids" => ["stale_selected_window"],
        "selected_station_calendar_entry_ids" => ["stale_selected_station_entry"],
        "selected_station_calendar_provider_entry_ids" => ["stale_selected_provider_entry"],
        "actual_throughput_contact_ids" => ["stale_actual_contact"],
        "actual_throughput_source_window_ids" => ["stale_actual_window"],
        "actual_throughput_station_calendar_entry_ids" => ["stale_actual_station_entry"],
        "actual_throughput_station_calendar_provider_entry_ids" => [
          "stale_actual_provider_entry"
        ],
        "source_window_ids_by_direction" => %{"stale_direction" => ["stale_window"]},
        "station_calendar_entry_ids_by_direction" => %{
          "stale_direction" => ["stale_station_entry"]
        },
        "station_calendar_provider_entry_ids_by_direction" => %{
          "stale_direction" => ["stale_provider_entry"]
        },
        "source_window_ids_by_ground_station" => %{"stale_station" => ["stale_window"]},
        "station_calendar_entry_ids_by_ground_station" => %{
          "stale_station" => ["stale_station_entry"]
        },
        "station_calendar_provider_entry_ids_by_ground_station" => %{
          "stale_station" => ["stale_provider_entry"]
        },
        "source_window_ids_by_spacecraft" => %{"stale_spacecraft" => ["stale_window"]},
        "station_calendar_entry_ids_by_spacecraft" => %{
          "stale_spacecraft" => ["stale_station_entry"]
        },
        "station_calendar_provider_entry_ids_by_spacecraft" => %{
          "stale_spacecraft" => ["stale_provider_entry"]
        },
        "source_window_ids_by_requirement_status" => %{"stale_status" => ["stale_window"]},
        "station_calendar_entry_ids_by_requirement_status" => %{
          "stale_status" => ["stale_station_entry"]
        },
        "station_calendar_provider_entry_ids_by_requirement_status" => %{
          "stale_status" => ["stale_provider_entry"]
        },
        "provenance" => %{"trust_boundary" => "ops_link_capacity"}
      }
    }

    expected_direction_routing = %{
      "command" => %{
        "contact_count" => 1,
        "contact_ids" => ["contact_gamma"],
        "source_window_ids" => ["window_gamma"],
        "station_calendar_entry_ids" => ["station_entry_gamma"],
        "station_calendar_provider_entry_ids" => ["provider_entry_gamma"],
        "capacity_adjusted_throughput_mb" => 20.0,
        "selected_capacity_adjusted_throughput_mb" => 15.0,
        "unused_capacity_adjusted_throughput_mb" => 5.0
      },
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["contact_alpha"],
        "source_window_ids" => ["window_alpha"],
        "station_calendar_entry_ids" => ["station_entry_alpha", "station_entry_beta"],
        "station_calendar_provider_entry_ids" => [
          "provider_entry_alpha",
          "provider_entry_beta"
        ],
        "capacity_adjusted_throughput_mb" => 65.0,
        "selected_capacity_adjusted_throughput_mb" => 25.0,
        "unused_capacity_adjusted_throughput_mb" => 40.0
      },
      "tracking" => %{
        "contact_count" => 1,
        "contact_ids" => ["contact_beta"],
        "source_window_ids" => ["window_beta"],
        "station_calendar_entry_ids" => ["station_entry_beta"],
        "station_calendar_provider_entry_ids" => ["provider_entry_beta"]
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_link_capacity_contract" => "link_capacity_report.v1",
             "source_report_link_capacity_count" => 1,
             "source_report_link_capacity_row_count" => 2,
             "source_report_link_capacity_paths" => ["source_link_capacity_report"],
             "source_report_link_capacity_selected_shortfall_row_count" => 1,
             "source_report_link_capacity_actual_shortfall_row_count" => 1,
             "source_report_link_capacity_actual_throughput_row_count" => 1,
             "source_report_link_capacity_capacity_adjusted_throughput_row_count" => 2,
             "source_report_link_capacity_capacity_adjusted_throughput_mb_total" => 85.0,
             "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_total" => 40.0,
             "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 45.0,
             "source_report_link_capacity_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_report_link_capacity_spacecraft_counts" => %{
               "leo_1" => 1,
               "leo_2" => 1
             },
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_ground_station" => %{
               "dss_43" => 20.0,
               "equator_prime" => 65.0
             },
             "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_by_ground_station" =>
               %{
                 "dss_43" => 15.0,
                 "equator_prime" => 25.0
               },
             "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_by_ground_station" =>
               %{
                 "dss_43" => 5.0,
                 "equator_prime" => 40.0
               },
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_direction" => %{
               "command" => 20.0,
               "downlink" => 65.0
             },
             "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_by_direction" =>
               %{
                 "command" => 15.0,
                 "downlink" => 25.0
               },
             "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_by_direction" =>
               %{
                 "command" => 5.0,
                 "downlink" => 40.0
               },
             "source_report_link_capacity_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "tracking" => 1
             },
             "source_report_link_capacity_directions" => ["command", "downlink", "tracking"],
             "source_report_link_capacity_contact_ids_by_direction" => %{
               "command" => ["contact_gamma"],
               "downlink" => ["contact_alpha"],
               "tracking" => ["contact_beta"]
             },
             "source_report_link_capacity_source_window_ids_by_direction" => %{
               "command" => ["window_gamma"],
               "downlink" => ["window_alpha"],
               "tracking" => ["window_beta"]
             },
             "source_report_link_capacity_station_calendar_entry_ids_by_direction" => %{
               "command" => ["station_entry_gamma"],
               "downlink" => ["station_entry_alpha", "station_entry_beta"],
               "tracking" => ["station_entry_beta"]
             },
             "source_report_link_capacity_station_calendar_provider_entry_ids_by_direction" => %{
               "command" => ["provider_entry_gamma"],
               "downlink" => ["provider_entry_alpha", "provider_entry_beta"],
               "tracking" => ["provider_entry_beta"]
             },
             "source_report_link_capacity_direction_routing" => ^expected_direction_routing,
             "source_report_link_capacity_contact_ids_by_ground_station" => %{
               "dss_43" => ["contact_gamma"],
               "equator_prime" => ["contact_alpha", "contact_beta"]
             },
             "source_report_link_capacity_source_window_ids_by_ground_station" => %{
               "dss_43" => ["window_gamma"],
               "equator_prime" => ["window_alpha", "window_beta"]
             },
             "source_report_link_capacity_contact_ids_by_spacecraft" => %{
               "leo_1" => ["contact_alpha", "contact_beta"],
               "leo_2" => ["contact_gamma"]
             },
             "source_report_link_capacity_source_window_ids_by_spacecraft" => %{
               "leo_1" => ["window_alpha", "window_beta"],
               "leo_2" => ["window_gamma"]
             },
             "source_report_link_capacity_station_calendar_entry_ids_by_spacecraft" => %{
               "leo_1" => ["station_entry_alpha", "station_entry_beta"],
               "leo_2" => ["station_entry_gamma"]
             },
             "source_report_link_capacity_station_calendar_provider_entry_ids_by_spacecraft" => %{
               "leo_1" => ["provider_entry_alpha", "provider_entry_beta"],
               "leo_2" => ["provider_entry_gamma"]
             },
             "source_report_link_capacity_station_calendar_entry_ids_by_ground_station" => %{
               "dss_43" => ["station_entry_gamma"],
               "equator_prime" => ["station_entry_alpha", "station_entry_beta"]
             },
             "source_report_link_capacity_station_calendar_provider_entry_ids_by_ground_station" =>
               %{
                 "dss_43" => ["provider_entry_gamma"],
                 "equator_prime" => ["provider_entry_alpha", "provider_entry_beta"]
               },
             "source_report_link_capacity_selected_contact_id_counts" => %{
               "contact_alpha" => 1,
               "contact_beta" => 1,
               "contact_gamma" => 1
             },
             "source_report_link_capacity_selected_contact_ids" => [
               "contact_alpha",
               "contact_beta",
               "contact_gamma"
             ],
             "source_report_link_capacity_selected_source_window_ids" => [
               "window_alpha",
               "window_beta",
               "window_gamma"
             ],
             "source_report_link_capacity_selected_station_calendar_entry_ids" => [
               "station_entry_alpha",
               "station_entry_beta",
               "station_entry_gamma"
             ],
             "source_report_link_capacity_selected_station_calendar_provider_entry_ids" => [
               "provider_entry_alpha",
               "provider_entry_beta",
               "provider_entry_gamma"
             ],
             "source_report_link_capacity_actual_throughput_contact_id_counts" => %{
               "contact_alpha" => 1,
               "contact_gamma" => 1
             },
             "source_report_link_capacity_actual_throughput_contact_ids" => [
               "contact_alpha",
               "contact_gamma"
             ],
             "source_report_link_capacity_actual_throughput_source_window_ids" => [
               "window_alpha",
               "window_gamma"
             ],
             "source_report_link_capacity_actual_throughput_station_calendar_entry_ids" => [
               "station_entry_alpha",
               "station_entry_gamma"
             ],
             "source_report_link_capacity_actual_throughput_station_calendar_provider_entry_ids" =>
               [
                 "provider_entry_alpha",
                 "provider_entry_gamma"
               ],
             "source_report_link_capacity_downlink_requirement_status_counts" => %{
               "actual_met" => 1,
               "actual_shortfall" => 1,
               "selected_met" => 1,
               "selected_shortfall" => 1
             },
             "source_report_link_capacity_contact_ids_by_requirement_status" => %{
               "actual_met" => ["contact_alpha"],
               "actual_shortfall" => ["contact_gamma"],
               "selected_met" => ["contact_gamma"],
               "selected_shortfall" => ["contact_alpha", "contact_beta"]
             },
             "source_report_link_capacity_source_window_ids_by_requirement_status" => %{
               "actual_met" => ["window_alpha"],
               "actual_shortfall" => ["window_gamma"],
               "selected_met" => ["window_gamma"],
               "selected_shortfall" => ["window_alpha", "window_beta"]
             },
             "source_report_link_capacity_station_calendar_entry_ids_by_requirement_status" => %{
               "actual_met" => ["station_entry_alpha"],
               "actual_shortfall" => ["station_entry_gamma"],
               "selected_met" => ["station_entry_gamma"],
               "selected_shortfall" => ["station_entry_alpha", "station_entry_beta"]
             },
             "source_report_link_capacity_station_calendar_provider_entry_ids_by_requirement_status" =>
               %{
                 "actual_met" => ["provider_entry_alpha"],
                 "actual_shortfall" => ["provider_entry_gamma"],
                 "selected_met" => ["provider_entry_gamma"],
                 "selected_shortfall" => ["provider_entry_alpha", "provider_entry_beta"]
               },
             "source_reports" => %{
               "link_capacity_report" => %{
                 "selected_shortfall_row_count" => 1,
                 "actual_shortfall_row_count" => 1,
                 "actual_throughput_row_count" => 1,
                 "capacity_adjusted_throughput_row_count" => 2,
                 "capacity_adjusted_throughput_mb_total" => 85.0,
                 "selected_capacity_adjusted_throughput_mb_total" => 40.0,
                 "unused_capacity_adjusted_throughput_mb_total" => 45.0,
                 "capacity_adjusted_throughput_mb_by_direction" => %{
                   "command" => 20.0,
                   "downlink" => 65.0
                 },
                 "selected_capacity_adjusted_throughput_mb_by_direction" => %{
                   "command" => 15.0,
                   "downlink" => 25.0
                 },
                 "unused_capacity_adjusted_throughput_mb_by_direction" => %{
                   "command" => 5.0,
                   "downlink" => 40.0
                 },
                 "ground_station_counts" => %{
                   "dss_43" => 1,
                   "equator_prime" => 1
                 },
                 "spacecraft_counts" => %{
                   "leo_1" => 1,
                   "leo_2" => 1
                 },
                 "direction_counts" => %{
                   "command" => 1,
                   "downlink" => 1,
                   "tracking" => 1
                 },
                 "directions" => ["command", "downlink", "tracking"],
                 "contact_ids_by_direction" => %{
                   "command" => ["contact_gamma"],
                   "downlink" => ["contact_alpha"],
                   "tracking" => ["contact_beta"]
                 },
                 "source_window_ids_by_direction" => %{
                   "command" => ["window_gamma"],
                   "downlink" => ["window_alpha"],
                   "tracking" => ["window_beta"]
                 },
                 "station_calendar_entry_ids_by_direction" => %{
                   "command" => ["station_entry_gamma"],
                   "downlink" => ["station_entry_alpha", "station_entry_beta"],
                   "tracking" => ["station_entry_beta"]
                 },
                 "station_calendar_provider_entry_ids_by_direction" => %{
                   "command" => ["provider_entry_gamma"],
                   "downlink" => ["provider_entry_alpha", "provider_entry_beta"],
                   "tracking" => ["provider_entry_beta"]
                 },
                 "direction_routing" => ^expected_direction_routing,
                 "contact_ids_by_ground_station" => %{
                   "dss_43" => ["contact_gamma"],
                   "equator_prime" => ["contact_alpha", "contact_beta"]
                 },
                 "source_window_ids_by_ground_station" => %{
                   "dss_43" => ["window_gamma"],
                   "equator_prime" => ["window_alpha", "window_beta"]
                 },
                 "station_calendar_entry_ids_by_ground_station" => %{
                   "dss_43" => ["station_entry_gamma"],
                   "equator_prime" => ["station_entry_alpha", "station_entry_beta"]
                 },
                 "station_calendar_provider_entry_ids_by_ground_station" => %{
                   "dss_43" => ["provider_entry_gamma"],
                   "equator_prime" => ["provider_entry_alpha", "provider_entry_beta"]
                 },
                 "contact_ids_by_spacecraft" => %{
                   "leo_1" => ["contact_alpha", "contact_beta"],
                   "leo_2" => ["contact_gamma"]
                 },
                 "source_window_ids_by_spacecraft" => %{
                   "leo_1" => ["window_alpha", "window_beta"],
                   "leo_2" => ["window_gamma"]
                 },
                 "station_calendar_entry_ids_by_spacecraft" => %{
                   "leo_1" => ["station_entry_alpha", "station_entry_beta"],
                   "leo_2" => ["station_entry_gamma"]
                 },
                 "station_calendar_provider_entry_ids_by_spacecraft" => %{
                   "leo_1" => ["provider_entry_alpha", "provider_entry_beta"],
                   "leo_2" => ["provider_entry_gamma"]
                 },
                 "selected_contact_id_counts" => %{
                   "contact_alpha" => 1,
                   "contact_beta" => 1,
                   "contact_gamma" => 1
                 },
                 "selected_contact_ids" => [
                   "contact_alpha",
                   "contact_beta",
                   "contact_gamma"
                 ],
                 "selected_source_window_ids" => [
                   "window_alpha",
                   "window_beta",
                   "window_gamma"
                 ],
                 "selected_station_calendar_entry_ids" => [
                   "station_entry_alpha",
                   "station_entry_beta",
                   "station_entry_gamma"
                 ],
                 "selected_station_calendar_provider_entry_ids" => [
                   "provider_entry_alpha",
                   "provider_entry_beta",
                   "provider_entry_gamma"
                 ],
                 "actual_throughput_contact_id_counts" => %{
                   "contact_alpha" => 1,
                   "contact_gamma" => 1
                 },
                 "actual_throughput_contact_ids" => [
                   "contact_alpha",
                   "contact_gamma"
                 ],
                 "actual_throughput_source_window_ids" => [
                   "window_alpha",
                   "window_gamma"
                 ],
                 "actual_throughput_station_calendar_entry_ids" => [
                   "station_entry_alpha",
                   "station_entry_gamma"
                 ],
                 "actual_throughput_station_calendar_provider_entry_ids" => [
                   "provider_entry_alpha",
                   "provider_entry_gamma"
                 ],
                 "downlink_requirement_status_counts" => %{
                   "actual_met" => 1,
                   "actual_shortfall" => 1,
                   "selected_met" => 1,
                   "selected_shortfall" => 1
                 },
                 "contact_ids_by_requirement_status" => %{
                   "actual_met" => ["contact_alpha"],
                   "actual_shortfall" => ["contact_gamma"],
                   "selected_met" => ["contact_gamma"],
                   "selected_shortfall" => ["contact_alpha", "contact_beta"]
                 },
                 "source_window_ids_by_requirement_status" => %{
                   "actual_met" => ["window_alpha"],
                   "actual_shortfall" => ["window_gamma"],
                   "selected_met" => ["window_gamma"],
                   "selected_shortfall" => ["window_alpha", "window_beta"]
                 },
                 "station_calendar_entry_ids_by_requirement_status" => %{
                   "actual_met" => ["station_entry_alpha"],
                   "actual_shortfall" => ["station_entry_gamma"],
                   "selected_met" => ["station_entry_gamma"],
                   "selected_shortfall" => ["station_entry_alpha", "station_entry_beta"]
                 },
                 "station_calendar_provider_entry_ids_by_requirement_status" => %{
                   "actual_met" => ["provider_entry_alpha"],
                   "actual_shortfall" => ["provider_entry_gamma"],
                   "selected_met" => ["provider_entry_gamma"],
                   "selected_shortfall" => ["provider_entry_alpha", "provider_entry_beta"]
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_link_capacity_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.link_capacity_report",
      "contract" => "link_capacity_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 2,
      "source_report_paths" => ["source_link_capacity_report"],
      "selected_shortfall_row_count" => 1,
      "actual_shortfall_row_count" => 1,
      "actual_throughput_row_count" => 1,
      "capacity_adjusted_throughput_row_count" => 2,
      "capacity_adjusted_throughput_mb_total" => 85.0,
      "selected_capacity_adjusted_throughput_mb_total" => 40.0,
      "unused_capacity_adjusted_throughput_mb_total" => 45.0,
      "ground_station_counts" => %{
        "dss_43" => 1,
        "equator_prime" => 1
      },
      "spacecraft_counts" => %{
        "leo_1" => 1,
        "leo_2" => 1
      },
      "capacity_adjusted_throughput_mb_by_ground_station" => %{
        "dss_43" => 20.0,
        "equator_prime" => 65.0
      },
      "selected_capacity_adjusted_throughput_mb_by_ground_station" => %{
        "dss_43" => 15.0,
        "equator_prime" => 25.0
      },
      "unused_capacity_adjusted_throughput_mb_by_ground_station" => %{
        "dss_43" => 5.0,
        "equator_prime" => 40.0
      },
      "capacity_adjusted_throughput_mb_by_direction" => %{
        "command" => 20.0,
        "downlink" => 65.0
      },
      "selected_capacity_adjusted_throughput_mb_by_direction" => %{
        "command" => 15.0,
        "downlink" => 25.0
      },
      "unused_capacity_adjusted_throughput_mb_by_direction" => %{
        "command" => 5.0,
        "downlink" => 40.0
      },
      "direction_counts" => %{
        "command" => 1,
        "downlink" => 1,
        "tracking" => 1
      },
      "directions" => ["command", "downlink", "tracking"],
      "contact_ids_by_direction" => %{
        "command" => ["contact_gamma"],
        "downlink" => ["contact_alpha"],
        "tracking" => ["contact_beta"]
      },
      "source_window_ids_by_direction" => %{
        "command" => ["window_gamma"],
        "downlink" => ["window_alpha"],
        "tracking" => ["window_beta"]
      },
      "station_calendar_entry_ids_by_direction" => %{
        "command" => ["station_entry_gamma"],
        "downlink" => ["station_entry_alpha", "station_entry_beta"],
        "tracking" => ["station_entry_beta"]
      },
      "station_calendar_provider_entry_ids_by_direction" => %{
        "command" => ["provider_entry_gamma"],
        "downlink" => ["provider_entry_alpha", "provider_entry_beta"],
        "tracking" => ["provider_entry_beta"]
      },
      "direction_routing" => expected_direction_routing,
      "contact_ids_by_ground_station" => %{
        "dss_43" => ["contact_gamma"],
        "equator_prime" => ["contact_alpha", "contact_beta"]
      },
      "source_window_ids_by_ground_station" => %{
        "dss_43" => ["window_gamma"],
        "equator_prime" => ["window_alpha", "window_beta"]
      },
      "station_calendar_entry_ids_by_ground_station" => %{
        "dss_43" => ["station_entry_gamma"],
        "equator_prime" => ["station_entry_alpha", "station_entry_beta"]
      },
      "station_calendar_provider_entry_ids_by_ground_station" => %{
        "dss_43" => ["provider_entry_gamma"],
        "equator_prime" => ["provider_entry_alpha", "provider_entry_beta"]
      },
      "contact_ids_by_spacecraft" => %{
        "leo_1" => ["contact_alpha", "contact_beta"],
        "leo_2" => ["contact_gamma"]
      },
      "source_window_ids_by_spacecraft" => %{
        "leo_1" => ["window_alpha", "window_beta"],
        "leo_2" => ["window_gamma"]
      },
      "station_calendar_entry_ids_by_spacecraft" => %{
        "leo_1" => ["station_entry_alpha", "station_entry_beta"],
        "leo_2" => ["station_entry_gamma"]
      },
      "station_calendar_provider_entry_ids_by_spacecraft" => %{
        "leo_1" => ["provider_entry_alpha", "provider_entry_beta"],
        "leo_2" => ["provider_entry_gamma"]
      },
      "selected_contact_id_counts" => %{
        "contact_alpha" => 1,
        "contact_beta" => 1,
        "contact_gamma" => 1
      },
      "selected_contact_ids" => [
        "contact_alpha",
        "contact_beta",
        "contact_gamma"
      ],
      "selected_source_window_ids" => [
        "window_alpha",
        "window_beta",
        "window_gamma"
      ],
      "selected_station_calendar_entry_ids" => [
        "station_entry_alpha",
        "station_entry_beta",
        "station_entry_gamma"
      ],
      "selected_station_calendar_provider_entry_ids" => [
        "provider_entry_alpha",
        "provider_entry_beta",
        "provider_entry_gamma"
      ],
      "actual_throughput_contact_id_counts" => %{
        "contact_alpha" => 1,
        "contact_gamma" => 1
      },
      "actual_throughput_contact_ids" => [
        "contact_alpha",
        "contact_gamma"
      ],
      "actual_throughput_source_window_ids" => [
        "window_alpha",
        "window_gamma"
      ],
      "actual_throughput_station_calendar_entry_ids" => [
        "station_entry_alpha",
        "station_entry_gamma"
      ],
      "actual_throughput_station_calendar_provider_entry_ids" => [
        "provider_entry_alpha",
        "provider_entry_gamma"
      ],
      "downlink_requirement_status_counts" => %{
        "actual_met" => 1,
        "actual_shortfall" => 1,
        "selected_met" => 1,
        "selected_shortfall" => 1
      },
      "contact_ids_by_requirement_status" => %{
        "actual_met" => ["contact_alpha"],
        "actual_shortfall" => ["contact_gamma"],
        "selected_met" => ["contact_gamma"],
        "selected_shortfall" => ["contact_alpha", "contact_beta"]
      },
      "source_window_ids_by_requirement_status" => %{
        "actual_met" => ["window_alpha"],
        "actual_shortfall" => ["window_gamma"],
        "selected_met" => ["window_gamma"],
        "selected_shortfall" => ["window_alpha", "window_beta"]
      },
      "station_calendar_entry_ids_by_requirement_status" => %{
        "actual_met" => ["station_entry_alpha"],
        "actual_shortfall" => ["station_entry_gamma"],
        "selected_met" => ["station_entry_gamma"],
        "selected_shortfall" => ["station_entry_alpha", "station_entry_beta"]
      },
      "station_calendar_provider_entry_ids_by_requirement_status" => %{
        "actual_met" => ["provider_entry_alpha"],
        "actual_shortfall" => ["provider_entry_gamma"],
        "selected_met" => ["provider_entry_gamma"],
        "selected_shortfall" => ["provider_entry_alpha", "provider_entry_beta"]
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_link_capacity"],
      "branch_local_link_capacity_pressure" => true,
      "branch_local_capacity_adjusted_throughput_pressure" => true,
      "branch_local_downlink_shortfall_pressure" => true,
      "branch_local_actual_throughput_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "link_capacity_source_report_provenance_only",
        "operator_authority" => "not_granted_by_link_capacity_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_link_capacity_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.link_capacity_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_link_capacity_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_link_capacity_contract" => "link_capacity_report.v1",
             "source_report_link_capacity_count" => 1,
             "source_report_link_capacity_row_count" => 2,
             "source_report_link_capacity_paths" => ["source_link_capacity_report"],
             "source_report_link_capacity_selected_shortfall_row_count" => 1,
             "source_report_link_capacity_actual_shortfall_row_count" => 1,
             "source_report_link_capacity_actual_throughput_row_count" => 1,
             "source_report_link_capacity_capacity_adjusted_throughput_row_count" => 2,
             "source_report_link_capacity_capacity_adjusted_throughput_mb_total" => 85.0,
             "source_report_link_capacity_ground_station_counts" => %{
               "dss_43" => 1,
               "equator_prime" => 1
             },
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_ground_station" => %{
               "dss_43" => 20.0,
               "equator_prime" => 65.0
             },
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_direction" => %{
               "command" => 20.0,
               "downlink" => 65.0
             },
             "source_report_link_capacity_directions" => ["command", "downlink", "tracking"],
             "source_report_link_capacity_contact_ids_by_direction" => %{
               "command" => ["contact_gamma"],
               "downlink" => ["contact_alpha"],
               "tracking" => ["contact_beta"]
             },
             "source_report_link_capacity_source_window_ids_by_direction" => %{
               "command" => ["window_gamma"],
               "downlink" => ["window_alpha"],
               "tracking" => ["window_beta"]
             },
             "source_report_link_capacity_station_calendar_entry_ids_by_direction" => %{
               "command" => ["station_entry_gamma"],
               "downlink" => ["station_entry_alpha", "station_entry_beta"],
               "tracking" => ["station_entry_beta"]
             },
             "source_report_link_capacity_station_calendar_provider_entry_ids_by_direction" => %{
               "command" => ["provider_entry_gamma"],
               "downlink" => ["provider_entry_alpha", "provider_entry_beta"],
               "tracking" => ["provider_entry_beta"]
             },
             "source_report_link_capacity_direction_routing" => ^expected_direction_routing,
             "source_report_link_capacity_contact_ids_by_ground_station" => %{
               "dss_43" => ["contact_gamma"],
               "equator_prime" => ["contact_alpha", "contact_beta"]
             },
             "source_report_link_capacity_source_window_ids_by_ground_station" => %{
               "dss_43" => ["window_gamma"],
               "equator_prime" => ["window_alpha", "window_beta"]
             },
             "source_report_link_capacity_station_calendar_entry_ids_by_ground_station" => %{
               "dss_43" => ["station_entry_gamma"],
               "equator_prime" => ["station_entry_alpha", "station_entry_beta"]
             },
             "source_report_link_capacity_station_calendar_provider_entry_ids_by_ground_station" =>
               %{
                 "dss_43" => ["provider_entry_gamma"],
                 "equator_prime" => ["provider_entry_alpha", "provider_entry_beta"]
               },
             "source_report_link_capacity_selected_contact_id_counts" => %{
               "contact_alpha" => 1,
               "contact_beta" => 1,
               "contact_gamma" => 1
             },
             "source_report_link_capacity_selected_contact_ids" => [
               "contact_alpha",
               "contact_beta",
               "contact_gamma"
             ],
             "source_report_link_capacity_selected_source_window_ids" => [
               "window_alpha",
               "window_beta",
               "window_gamma"
             ],
             "source_report_link_capacity_selected_station_calendar_entry_ids" => [
               "station_entry_alpha",
               "station_entry_beta",
               "station_entry_gamma"
             ],
             "source_report_link_capacity_selected_station_calendar_provider_entry_ids" => [
               "provider_entry_alpha",
               "provider_entry_beta",
               "provider_entry_gamma"
             ],
             "source_report_link_capacity_actual_throughput_contact_id_counts" => %{
               "contact_alpha" => 1,
               "contact_gamma" => 1
             },
             "source_report_link_capacity_actual_throughput_contact_ids" => [
               "contact_alpha",
               "contact_gamma"
             ],
             "source_report_link_capacity_actual_throughput_source_window_ids" => [
               "window_alpha",
               "window_gamma"
             ],
             "source_report_link_capacity_actual_throughput_station_calendar_entry_ids" => [
               "station_entry_alpha",
               "station_entry_gamma"
             ],
             "source_report_link_capacity_actual_throughput_station_calendar_provider_entry_ids" =>
               [
                 "provider_entry_alpha",
                 "provider_entry_gamma"
               ],
             "source_report_link_capacity_downlink_requirement_status_counts" => %{
               "actual_met" => 1,
               "actual_shortfall" => 1,
               "selected_met" => 1,
               "selected_shortfall" => 1
             },
             "source_report_link_capacity_contact_ids_by_requirement_status" => %{
               "actual_met" => ["contact_alpha"],
               "actual_shortfall" => ["contact_gamma"],
               "selected_met" => ["contact_gamma"],
               "selected_shortfall" => ["contact_alpha", "contact_beta"]
             },
             "source_report_link_capacity_source_window_ids_by_requirement_status" => %{
               "actual_met" => ["window_alpha"],
               "actual_shortfall" => ["window_gamma"],
               "selected_met" => ["window_gamma"],
               "selected_shortfall" => ["window_alpha", "window_beta"]
             },
             "source_report_link_capacity_station_calendar_entry_ids_by_requirement_status" => %{
               "actual_met" => ["station_entry_alpha"],
               "actual_shortfall" => ["station_entry_gamma"],
               "selected_met" => ["station_entry_gamma"],
               "selected_shortfall" => ["station_entry_alpha", "station_entry_beta"]
             },
             "source_report_link_capacity_station_calendar_provider_entry_ids_by_requirement_status" =>
               %{
                 "actual_met" => ["provider_entry_alpha"],
                 "actual_shortfall" => ["provider_entry_gamma"],
                 "selected_met" => ["provider_entry_gamma"],
                 "selected_shortfall" => ["provider_entry_alpha", "provider_entry_beta"]
               },
             "source_report_link_capacity_branch_local_link_capacity_pressure" => true,
             "source_report_link_capacity_branch_local_capacity_adjusted_throughput_pressure" =>
               true,
             "source_report_link_capacity_branch_local_downlink_shortfall_pressure" => true,
             "source_report_link_capacity_branch_local_actual_throughput_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.link_capacity_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_link_capacity_replay_summary(artifact) ==
             replay_summary
  end
end
