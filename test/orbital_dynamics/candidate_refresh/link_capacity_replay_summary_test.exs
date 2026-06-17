defmodule OrbitalDynamics.CandidateRefresh.LinkCapacityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  alias OrbitalDynamics.Communications.LinkCapacity

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

  test "link capacity replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.link_capacity_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_link_capacity_contract")
    refute Map.has_key?(source_summary, "source_report_link_capacity_count")
    refute Map.has_key?(source_summary, "source_report_link_capacity_row_count")
    refute Map.has_key?(source_summary, "source_report_link_capacity_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_link_capacity_pressure"]
  end

  test "link capacity source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "link_capacity_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.link_capacity_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.link_capacity_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "link_capacity_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_link_capacity_contract"] ==
                 "link_capacity_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_link_capacity_contract")
      end

      refute Map.has_key?(source_summary, "source_report_link_capacity_count")
      refute Map.has_key?(source_summary, "source_report_link_capacity_row_count")
      refute Map.has_key?(source_summary, "source_report_link_capacity_paths")
    end
  end

  test "link capacity source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.link_capacity_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_link_capacity_contract"] ==
             "link_capacity_report.v1"

    assert source_summary["source_report_link_capacity_count"] == 0
    assert source_summary["source_report_link_capacity_row_count"] == 0

    assert source_summary["source_report_link_capacity_paths"] == [
             "provenance.source_reports.link_capacity_report"
           ]
  end

  test "link capacity source summary omits missing identity paths after preserving counts" do
    partial_summaries = [
      %{
        "contract" => "link_capacity_report.v1",
        "count" => 1,
        "row_count" => 2
      },
      %{
        "contract" => "link_capacity_report.v1",
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
            "link_capacity_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)
      replay_summary = CandidateRefresh.link_capacity_replay_summary(artifact)

      assert source_summary["source_report_link_capacity_contract"] ==
               "link_capacity_report.v1"

      assert source_summary["source_report_link_capacity_count"] == 1
      assert source_summary["source_report_link_capacity_row_count"] == 2
      refute Map.has_key?(source_summary, "source_report_link_capacity_paths")

      assert replay_summary["contract"] == "link_capacity_report.v1"
      assert replay_summary["source_report_count"] == 1
      assert replay_summary["source_report_row_count"] == 2
      assert replay_summary["source_report_paths"] == []
    end
  end

  test "link capacity source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.link_capacity_replay_summary(artifact)

    assert source_summary["source_report_link_capacity_contract"] ==
             "link_capacity_report.v1"

    assert source_summary["source_report_link_capacity_count"] == 1
    assert source_summary["source_report_link_capacity_row_count"] == 2
    assert Map.has_key?(source_summary, "source_report_link_capacity_paths")
    assert source_summary["source_report_link_capacity_paths"] == []

    assert replay_summary["contract"] == "link_capacity_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 2
    assert replay_summary["source_report_paths"] == []
  end

  test "link capacity replay preserves throughput and routing maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 1,
            "capacity_adjusted_throughput_mb_by_ground_station" => %{
              "equator_prime" => 120.0
            },
            "capacity_adjusted_throughput_mb_by_direction" => %{"downlink" => 120.0},
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["selected_contact"]},
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["selected_contact"],
                "capacity_adjusted_throughput_mb" => 120.0
              }
            },
            "contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "selected_contact_ids" => ["selected_contact"],
            "actual_throughput_contact_ids" => ["actual_contact"],
            "downlink_requirement_status_counts" => %{"actual_shortfall" => 1},
            "contact_ids_by_requirement_status" => %{
              "actual_shortfall" => ["actual_contact"]
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.link_capacity_replay_summary(artifact)

    assert source_summary["source_report_link_capacity_contract"] ==
             "link_capacity_report.v1"

    refute Map.has_key?(source_summary, "source_report_link_capacity_count")
    refute Map.has_key?(source_summary, "source_report_link_capacity_row_count")
    refute Map.has_key?(source_summary, "source_report_link_capacity_paths")

    assert source_summary[
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_ground_station"
           ] == %{"equator_prime" => 120.0}

    assert source_summary[
             "source_report_link_capacity_capacity_adjusted_throughput_mb_by_direction"
           ] == %{"downlink" => 120.0}

    assert source_summary["source_report_link_capacity_direction_counts"] == %{"downlink" => 1}

    assert source_summary["source_report_link_capacity_contact_ids_by_direction"] == %{
             "downlink" => ["selected_contact"]
           }

    assert source_summary["source_report_link_capacity_direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"],
               "capacity_adjusted_throughput_mb" => 120.0
             }
           }

    assert source_summary["source_report_link_capacity_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert source_summary["source_report_link_capacity_selected_contact_ids"] == [
             "selected_contact"
           ]

    assert source_summary["source_report_link_capacity_actual_throughput_contact_ids"] == [
             "actual_contact"
           ]

    assert source_summary["source_report_link_capacity_downlink_requirement_status_counts"] == %{
             "actual_shortfall" => 1
           }

    assert source_summary["source_report_link_capacity_contact_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["actual_contact"]
           }

    assert replay_summary["contract"] == "link_capacity_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []

    assert replay_summary["capacity_adjusted_throughput_mb_by_ground_station"] == %{
             "equator_prime" => 120.0
           }

    assert replay_summary["capacity_adjusted_throughput_mb_by_direction"] == %{
             "downlink" => 120.0
           }

    assert replay_summary["direction_counts"] == %{"downlink" => 1}
    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["selected_contact"]}

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"],
               "capacity_adjusted_throughput_mb" => 120.0
             }
           }

    assert replay_summary["contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert replay_summary["selected_contact_ids"] == ["selected_contact"]
    assert replay_summary["actual_throughput_contact_ids"] == ["actual_contact"]
    assert replay_summary["downlink_requirement_status_counts"] == %{"actual_shortfall" => 1}

    assert replay_summary["contact_ids_by_requirement_status"] == %{
             "actual_shortfall" => ["actual_contact"]
           }

    assert replay_summary["branch_local_link_capacity_pressure"]
    assert replay_summary["branch_local_capacity_adjusted_throughput_pressure"]
    assert replay_summary["branch_local_downlink_shortfall_pressure"]
    assert replay_summary["branch_local_actual_throughput_pressure"]
  end

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

  test "source report summary replays relay data path summaries" do
    summary = relay_data_path_summary_fixture()

    refresh = %{
      "accepted_planning_state" => %{"relay_data_path_summary" => summary},
      "mission_state" => %{"source_relay_data_path_summary" => summary},
      "source_relay_data_path_summary" => summary,
      "source_result_artifact" => %{"relay_data_path_summary" => summary}
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_contract" => %{"relay_data_path_summary.v1" => 4},
             "source_report_row_counts_by_contract" => %{"relay_data_path_summary.v1" => 8},
             "source_report_link_capacity_contract" => "relay_data_path_summary.v1",
             "source_report_link_capacity_count" => 4,
             "source_report_link_capacity_row_count" => 8,
             "source_report_link_capacity_paths" => [
               "accepted_planning_state.relay_data_path_summary",
               "mission_state.source_relay_data_path_summary",
               "source_relay_data_path_summary",
               "source_result_artifact.relay_data_path_summary"
             ],
             "source_report_link_capacity_ground_station_counts" => %{
               "dss_14" => 4,
               "dss_35" => 4
             },
             "source_reports" => %{
               "link_capacity_report" => %{
                 "paths" => [
                   "accepted_planning_state.relay_data_path_summary",
                   "mission_state.source_relay_data_path_summary",
                   "source_relay_data_path_summary",
                   "source_result_artifact.relay_data_path_summary"
                 ],
                 "contract" => "relay_data_path_summary.v1",
                 "count" => 4,
                 "row_count" => 8,
                 "source_summary_model_counts" => %{
                   "artifact_only_relay_data_path_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "relay_data_path_summary.v1" => 4
                 },
                 "relay_route_count" => 4,
                 "direct_downlink_route_count" => 4,
                 "relay_route_ids" => ["route_direct", "route_relay_alpha"],
                 "source_spacecraft_ids" => ["sat_a", "sat_b"],
                 "relay_spacecraft_ids" => ["relay_1", "relay_2"],
                 "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
                 "relay_custody_status_counts" => %{"confirmed" => 4, "missing_ack" => 4},
                 "relay_latency_status_counts" => %{"exceeds_limit" => 4, "within_limit" => 4},
                 "relay_risk_status_counts" => %{"high" => 4, "nominal" => 4},
                 "relay_route_ids_by_custody_status" => %{
                   "confirmed" => ["route_relay_alpha"],
                   "missing_ack" => ["route_direct"]
                 },
                 "relay_route_ids_by_latency_status" => %{
                   "exceeds_limit" => ["route_direct"],
                   "within_limit" => ["route_relay_alpha"]
                 },
                 "relay_route_ids_by_risk_status" => %{
                   "high" => ["route_direct"],
                   "nominal" => ["route_relay_alpha"]
                 },
                 "relay_route_ids_by_ground_station" => %{
                   "dss_14" => ["route_relay_alpha"],
                   "dss_35" => ["route_direct"]
                 },
                 "ground_station_counts" => %{"dss_14" => 4, "dss_35" => 4},
                 "spacecraft_counts" => %{"sat_a" => 4, "sat_b" => 4},
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["relay_ops"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.link_capacity_replay_summary(refresh)

    assert replay_summary["contract"] == "relay_data_path_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 8
    assert replay_summary["relay_route_count"] == 4
    assert replay_summary["direct_downlink_route_count"] == 4
    assert replay_summary["relay_route_ids"] == ["route_direct", "route_relay_alpha"]
    assert replay_summary["source_spacecraft_ids"] == ["sat_a", "sat_b"]
    assert replay_summary["relay_spacecraft_ids"] == ["relay_1", "relay_2"]
    assert replay_summary["ground_downlink_contact_ids"] == ["downlink_1", "downlink_2"]

    assert replay_summary["relay_custody_status_counts"] == %{
             "confirmed" => 4,
             "missing_ack" => 4
           }

    assert replay_summary["relay_latency_status_counts"] == %{
             "exceeds_limit" => 4,
             "within_limit" => 4
           }

    assert replay_summary["relay_risk_status_counts"] == %{"high" => 4, "nominal" => 4}

    assert replay_summary["relay_route_ids_by_ground_station"] == %{
             "dss_14" => ["route_relay_alpha"],
             "dss_35" => ["route_direct"]
           }

    assert replay_summary["ground_station_counts"] == %{"dss_14" => 4, "dss_35" => 4}
    assert replay_summary["spacecraft_counts"] == %{"sat_a" => 4, "sat_b" => 4}
    assert replay_summary["trust_boundary_status"] == "declared"
    assert replay_summary["trust_boundaries"] == ["relay_ops"]
    assert replay_summary["branch_local_link_capacity_pressure"]
    refute replay_summary["branch_local_capacity_adjusted_throughput_pressure"]
    refute replay_summary["branch_local_downlink_shortfall_pressure"]
    refute replay_summary["branch_local_actual_throughput_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.link_capacity_replay_summary(artifact) == replay_summary
  end

  test "relay data path source summaries derive stale aggregate pressure from rows" do
    stale_summary =
      relay_data_path_summary_fixture()
      |> Map.merge(%{
        "route_count" => 99,
        "relay_route_count" => 99,
        "direct_downlink_route_count" => 99,
        "custody_status_counts" => %{"stale_custody" => 99},
        "latency_status_counts" => %{"stale_latency" => 99},
        "risk_status_counts" => %{"stale_risk" => 99},
        "route_ids" => ["stale_route"],
        "source_spacecraft_ids" => ["stale_source_spacecraft"],
        "relay_spacecraft_ids" => ["stale_relay"],
        "ground_station_ids" => ["stale_station"],
        "ground_downlink_contact_ids" => ["stale_downlink"],
        "route_ids_by_custody_status" => %{"stale_custody" => ["stale_route"]},
        "route_ids_by_latency_status" => %{"stale_latency" => ["stale_route"]},
        "route_ids_by_risk_status" => %{"stale_risk" => ["stale_route"]},
        "route_ids_by_ground_station_id" => %{"stale_station" => ["stale_route"]}
      })

    refresh = %{"source_relay_data_path_summary" => stale_summary}

    assert %{
             "source_report_link_capacity_contract" => "relay_data_path_summary.v1",
             "source_report_link_capacity_count" => 1,
             "source_report_link_capacity_row_count" => 2,
             "source_report_link_capacity_ground_station_counts" => %{
               "dss_14" => 1,
               "dss_35" => 1
             },
             "source_report_link_capacity_spacecraft_counts" => %{"sat_a" => 1, "sat_b" => 1},
             "source_report_link_capacity_branch_local_link_capacity_pressure" => true,
             "source_reports" => %{
               "link_capacity_report" => %{
                 "relay_route_count" => 1,
                 "direct_downlink_route_count" => 1,
                 "relay_route_ids" => ["route_direct", "route_relay_alpha"],
                 "source_spacecraft_ids" => ["sat_a", "sat_b"],
                 "relay_spacecraft_ids" => ["relay_1", "relay_2"],
                 "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
                 "relay_custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
                 "relay_latency_status_counts" => %{
                   "exceeds_limit" => 1,
                   "within_limit" => 1
                 },
                 "relay_risk_status_counts" => %{"high" => 1, "nominal" => 1},
                 "relay_route_ids_by_ground_station" => %{
                   "dss_14" => ["route_relay_alpha"],
                   "dss_35" => ["route_direct"]
                 }
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    refute "stale_route" in get_in(source_summary, [
             "source_reports",
             "link_capacity_report",
             "relay_route_ids"
           ])

    assert %{
             "source_report_row_count" => 2,
             "relay_route_count" => 1,
             "direct_downlink_route_count" => 1,
             "relay_route_ids" => ["route_direct", "route_relay_alpha"],
             "source_spacecraft_ids" => ["sat_a", "sat_b"],
             "relay_spacecraft_ids" => ["relay_1", "relay_2"],
             "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
             "relay_custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
             "relay_latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
             "relay_risk_status_counts" => %{"high" => 1, "nominal" => 1},
             "relay_route_ids_by_ground_station" => %{
               "dss_14" => ["route_relay_alpha"],
               "dss_35" => ["route_direct"]
             },
             "ground_station_counts" => %{"dss_14" => 1, "dss_35" => 1},
             "spacecraft_counts" => %{"sat_a" => 1, "sat_b" => 1},
             "branch_local_link_capacity_pressure" => true
           } = CandidateRefresh.link_capacity_replay_summary(refresh)
  end

  test "source report summary replays wrapped relay data path summaries" do
    direct_summary =
      relay_data_path_summary_fixture()
      |> Map.put("source", "relay_ops.direct")

    nested_summary =
      relay_data_path_summary_fixture()
      |> Map.put("source", "relay_ops.nested")

    refresh = %{
      "source_result_artifact" => [
        direct_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "relay_data_path_summary" => nested_summary
        }
      ]
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert get_in(source_summary, ["source_reports", "link_capacity_report", "paths"]) == [
             "source_result_artifact[0]",
             "source_result_artifact[1].relay_data_path_summary"
           ]

    assert get_in(source_summary, ["source_reports", "link_capacity_report", "contract"]) ==
             "relay_data_path_summary.v1"

    assert get_in(source_summary, ["source_reports", "link_capacity_report", "count"]) == 2
    assert get_in(source_summary, ["source_reports", "link_capacity_report", "row_count"]) == 4

    assert get_in(source_summary, ["source_reports", "link_capacity_report", "relay_route_count"]) ==
             2

    replay_summary = CandidateRefresh.link_capacity_replay_summary(refresh)

    assert replay_summary["source_report_paths"] == [
             "source_result_artifact[0]",
             "source_result_artifact[1].relay_data_path_summary"
           ]

    assert replay_summary["relay_route_count"] == 2
    assert replay_summary["direct_downlink_route_count"] == 2
    assert replay_summary["branch_local_link_capacity_pressure"]
  end

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

  test "derives downlink completion objectives from source link capacity reports" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 900.0,
          "selected_downlink_shortfall_mb" => 420.0,
          "capacity_adjusted_throughput_mb" => 480.0,
          "selected_capacity_adjusted_throughput_mb" => 360.0,
          "unused_capacity_adjusted_throughput_mb" => 120.0,
          "downlink_requirement_status" => "shortfall",
          "selected_contact_ids" => ["dl_prior"],
          "source_window_id" => "window_prior",
          "trust_boundary" => "cadence_ops"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_link_capacity_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0
    assert downlink["source_capacity_adjusted_throughput_mb"] == 480.0
    assert downlink["source_selected_capacity_adjusted_throughput_mb"] == 360.0
    assert downlink["source_unused_capacity_adjusted_throughput_mb"] == 120.0

    assert get_in(downlink, ["activity_context", "source_capacity_adjusted_throughput_mb"]) ==
             480.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives station throughput feedback from source link capacity reports" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "selected_capacity_adjusted_throughput_mb" => 360.0,
          "actual_throughput_mb" => 120.0,
          "actual_downlink_shortfall_mb" => 240.0,
          "actual_downlink_requirement_status" => "shortfall",
          "actual_throughput_contact_ids" => ["dl_prior"],
          "trust_boundary" => "cadence_ops"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_link_capacity_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 1 / 3
           }

    assert get_in(artifact, ["provenance", "operational_feedback", "trust_boundary"]) ==
             "cadence_ops"

    assert "station_throughput_factor" in get_in(artifact, [
             "provenance",
             "operational_feedback",
             "input_keys"
           ])

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 240.0
    assert downlink["estimated_throughput_mb"] == 120.0
    assert downlink["candidate_downlink_mb"] == 120.0
    assert downlink["selected_downlink_shortfall_mb"] == 120.0

    assert get_in(downlink, ["throughput_model", "station_throughput_factor"]) == 1 / 3

    assert get_in(downlink, ["throughput_model", "station_throughput_factor_source"]) ==
             "operational_feedback.station_throughput_factor.station"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays link capacity shortfall from result artifact wrappers" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "selected_downlink_shortfall_mb" => 420.0,
          "downlink_requirement_status" => "shortfall"
        }
      ]
    }

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "link_capacity_report" => report,
      "provenance" => %{"trust_boundary" => "mission_planning"}
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", wrapper),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays link capacity shortfall from operator review packages" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "selected_downlink_shortfall_mb" => 420.0,
          "downlink_requirement_status" => "shortfall"
        }
      ]
    }

    package = OperatorReview.from_link_capacity_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays link capacity shortfall from Cadence import manifests" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [
        %{
          "spacecraft_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "actual_downlink_shortfall_mb" => 420.0,
          "actual_downlink_requirement_status" => "shortfall",
          "source_window_id" => "window_actual"
        }
      ]
    }

    manifest = CadenceImport.from_link_capacity_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert %{
             "source_report_link_capacity_paths" => [
               "source_cadence_import_manifest.rows.source_link_capacity"
             ],
             "source_report_link_capacity_source_window_ids_by_direction" => %{
               "downlink" => ["window_actual"]
             },
             "source_report_link_capacity_source_window_ids_by_ground_station" => %{
               "equator_prime" => ["window_actual"]
             },
             "source_report_link_capacity_source_window_ids_by_spacecraft" => %{
               "leo_1" => ["window_actual"]
             },
             "source_report_link_capacity_source_window_ids_by_requirement_status" => %{
               "shortfall" => ["window_actual"]
             }
           } = CandidateRefresh.source_report_summary(artifact)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp result_set do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :target_visibility,
          events: [
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 80.0,
                minimum_elevation_deg: 10.0,
                sample_count: 3,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :target_visibility_linear_margin_interpolation,
                start_boundary: :clipped_start,
                end_boundary: :visibility_end,
                start_boundary_detail: %{
                  boundary: :clipped_start,
                  interpolation: :clipped_to_sample,
                  interpolation_fraction: 0.0,
                  sample_index: 1,
                  elevation_deg: 80.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :visibility_end,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.5,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 10.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :target_visibility,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :aos_los_linear_margin_interpolation,
                start_boundary: :aos,
                end_boundary: :los,
                start_boundary_detail: %{
                  edge: :start,
                  boundary: :aos,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.25,
                  before_sample_index: 2,
                  after_sample_index: 3,
                  before_elevation_deg: 0.0,
                  after_elevation_deg: 20.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :los,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.75,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :access_windows,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :other,
          event_type: :eclipse,
          events: [
            %{
              type: :eclipse,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{sample_count: 3}
            }
          ],
          source: %{shadow_model: :cylindrical_central_body_shadow}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp refresh_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ],
      "prior_candidate_activities" => [
        %{
          "id" => "stale_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }
  end

  defp relay_data_path_summary_fixture do
    %{
      "schema_contract" => "relay_data_path_summary.v1",
      "schema_version" => 1,
      "model" => "artifact_only_relay_data_path_summary",
      "source" => "relay_ops",
      "route_count" => 2,
      "relay_route_count" => 1,
      "direct_downlink_route_count" => 1,
      "custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
      "latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
      "risk_status_counts" => %{"high" => 1, "nominal" => 1},
      "route_ids" => ["route_relay_alpha", "route_direct"],
      "source_spacecraft_ids" => ["sat_a", "sat_b"],
      "relay_spacecraft_ids" => ["relay_1", "relay_2"],
      "ground_station_ids" => ["dss_14", "dss_35"],
      "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
      "route_ids_by_custody_status" => %{
        "confirmed" => ["route_relay_alpha"],
        "missing_ack" => ["route_direct"]
      },
      "route_ids_by_latency_status" => %{
        "exceeds_limit" => ["route_direct"],
        "within_limit" => ["route_relay_alpha"]
      },
      "route_ids_by_risk_status" => %{
        "high" => ["route_direct"],
        "nominal" => ["route_relay_alpha"]
      },
      "route_ids_by_ground_station_id" => %{
        "dss_14" => ["route_relay_alpha"],
        "dss_35" => ["route_direct"]
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
        "crosslink_visibility_model" => "not_evaluated",
        "custody_acknowledgement_delivery" => "not_performed",
        "provider_reservation" => "not_performed",
        "operator_authority" => "not_granted_by_summary"
      },
      "provenance" => %{"trust_boundary" => "relay_ops"},
      "rows" => [
        %{
          "route_id" => "route_relay_alpha",
          "source_spacecraft_id" => "sat_a",
          "relay_chain_spacecraft_ids" => ["relay_2", "relay_1"],
          "relay_hop_count" => 2,
          "ground_station_id" => "dss_14",
          "ground_downlink_contact_id" => "downlink_1",
          "custody_status" => "confirmed",
          "latency_s" => 180.0,
          "latency_limit_s" => 240.0,
          "latency_status" => "within_limit",
          "risk_status" => "nominal",
          "product_ids" => ["image_alpha"],
          "collection_ids" => ["collection_alpha"]
        },
        %{
          "route_id" => "route_direct",
          "source_spacecraft_id" => "sat_b",
          "relay_chain_spacecraft_ids" => [],
          "relay_hop_count" => 0,
          "ground_station_id" => "dss_35",
          "ground_downlink_contact_id" => "downlink_2",
          "custody_status" => "missing_ack",
          "latency_s" => 500.0,
          "latency_limit_s" => 300.0,
          "latency_status" => "exceeds_limit",
          "risk_status" => "high",
          "risk_reasons" => [
            "custody_missing_ack",
            "latency_exceeds_limit",
            "operator review queued"
          ],
          "product_ids" => ["image_beta"],
          "collection_ids" => []
        }
      ]
    }
  end

  test "operator review and import lift link capacity summaries from candidate refresh artifacts" do
    link_capacity_summary = fn source, station_id, contact_id ->
      %{
        "schema_contract" => "link_capacity_report.v1",
        "source" => source,
        "rows" => [
          %{
            "ground_station_id" => station_id,
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
            "contact_ids" => [contact_id],
            "selected_contact_ids" => [contact_id],
            "actual_throughput_contact_ids" => [contact_id],
            "station_calendar_entry_ids" => ["station_entry_#{station_id}"],
            "station_calendar_provider_entry_ids" => ["provider_entry_#{station_id}"]
          }
        ]
      }
      |> LinkCapacity.summary()
      |> Map.put("provenance", %{"trust_boundary" => source})
    end

    direct_summary =
      link_capacity_summary.(
        "unit_test.link_capacity.direct",
        "direct_station",
        "direct_downlink"
      )

    canonical_summary =
      link_capacity_summary.(
        "unit_test.link_capacity.canonical",
        "canonical_station",
        "canonical_downlink"
      )

    wrapped_summary =
      link_capacity_summary.(
        "unit_test.link_capacity.wrapped",
        "wrapped_station",
        "wrapped_downlink"
      )

    nested_summary =
      link_capacity_summary.(
        "unit_test.link_capacity.nested",
        "nested_station",
        "nested_downlink"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:link_capacity_summary_handoff",
      "source_link_capacity_summary" => [direct_summary],
      "link_capacity_summary" => canonical_summary,
      "source_result_artifact" => [
        wrapped_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "link_capacity_summary" => nested_summary
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    link_rows = Enum.filter(review["rows"], &(&1["review_type"] == "link_capacity_review"))

    assert length(link_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:link_capacity_summary_handoff",
             "link_capacity_review_count" => 4,
             "review_type_counts" => %{"link_capacity_review" => 4}
           } = review

    assert Enum.sort(Enum.map(link_rows, & &1["source"])) == [
             "candidate_refresh.link_capacity_summary.rows",
             "candidate_refresh.source_link_capacity_summary[0].rows",
             "candidate_refresh.source_result_artifact[0].rows",
             "candidate_refresh.source_result_artifact[1].link_capacity_summary.rows"
           ]

    assert Enum.any?(
             link_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.link_capacity_summary.rows",
                 "ground_station_id" => "canonical_station",
                 "selected_downlink_shortfall_mb" => 20.0,
                 "actual_downlink_shortfall_mb" => 5.0,
                 "capacity_adjusted_throughput_mb" => 80.0,
                 "selected_capacity_adjusted_throughput_mb" => 60.0,
                 "unused_capacity_adjusted_throughput_mb" => 20.0,
                 "selected_contact_ids" => ["canonical_downlink"],
                 "actual_throughput_contact_ids" => ["canonical_downlink"],
                 "source_link_capacity" => %{
                   "schema_contract" => "link_capacity_summary.v1",
                   "source_link_capacity_summary" => %{
                     "schema_contract" => "link_capacity_summary.v1",
                     "source" => "unit_test.link_capacity.canonical",
                     "station_count" => 1
                   }
                 }
               },
               &1
             )
           )

    import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "link_capacity_review"))

    assert length(import_rows) == 4

    assert %{
             "import_action_counts" => %{"review_link_capacity" => 4},
             "source_review_type_counts" => %{"link_capacity_review" => 4}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_link_capacity" and
                 &1["source_review_row"]["source_link_capacity"]["source_link_capacity_summary"])
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end
end
