defmodule OrbitalDynamics.CandidateRefresh.ContactIntentCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "contact intent replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_intent" => %{
              "contract" => "contact_intent.v1",
              "count" => 2,
              "row_count" => 2,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_intents[0]"
              ],
              "station_feedback_count" => 1,
              "station_calendar_status_counts" => %{"reserved" => 1},
              "cadence_import_status_counts" => %{"ready_for_import" => 1},
              "policy_classification_counts" => %{"review_only" => 1},
              "capacity_pack_required_contact_count" => 1,
              "capacity_pack_required_capacity_fraction" => 0.35,
              "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                "equator_prime" => 0.35
              },
              "capacity_pack_required_capacity_fraction_by_direction" => %{
                "downlink" => 0.35
              },
              "required_capacity_fraction_source_counts" => %{
                "contact_required_capacity_fraction" => 1
              },
              "required_capacity_fraction_contact_ids_by_source" => %{
                "contact_required_capacity_fraction" => ["branch_downlink_intent"]
              },
              "capacity_pack_contact_ids_by_ground_station" => %{
                "equator_prime" => ["branch_downlink_intent"]
              },
              "contact_ids_by_ground_station" => %{
                "dss_43" => ["branch_command_intent"],
                "equator_prime" => ["branch_downlink_intent"]
              },
              "capacity_pack_contact_ids_by_direction" => %{
                "downlink" => ["branch_downlink_intent"]
              },
              "directions" => ["command", "downlink"],
              "direction_counts" => %{"command" => 1, "downlink" => 1},
              "contact_ids_by_direction" => %{
                "command" => ["branch_command_intent"],
                "downlink" => ["branch_downlink_intent"]
              },
              "direction_routing" => %{
                "command" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_command_intent"],
                  "capacity_pack_contact_ids" => []
                },
                "downlink" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_downlink_intent"],
                  "capacity_pack_required_capacity_fraction" => 0.35,
                  "capacity_pack_contact_ids" => ["branch_downlink_intent"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_contact_intent"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_intent"

    assert summary["contract"] == "contact_intent.v1"
    assert summary["source_report_count"] == 2
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_intents[0]"
           ]

    assert summary["station_feedback_count"] == 1
    assert summary["station_calendar_status_counts"] == %{"reserved" => 1}
    assert summary["cadence_import_status_counts"] == %{"ready_for_import" => 1}
    assert summary["policy_classification_counts"] == %{"review_only" => 1}
    assert summary["capacity_pack_required_contact_count"] == 1
    assert summary["capacity_pack_required_capacity_fraction"] == 0.35

    assert summary["capacity_pack_required_capacity_fraction_by_ground_station"] == %{
             "equator_prime" => 0.35
           }

    assert summary["capacity_pack_required_capacity_fraction_by_direction"] == %{
             "downlink" => 0.35
           }

    assert summary["required_capacity_fraction_source_counts"] == %{
             "contact_required_capacity_fraction" => 1
           }

    assert summary["required_capacity_fraction_contact_ids_by_source"] == %{
             "contact_required_capacity_fraction" => ["branch_downlink_intent"]
           }

    assert summary["capacity_pack_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_downlink_intent"]
           }

    assert summary["contact_ids_by_ground_station"] == %{
             "dss_43" => ["branch_command_intent"],
             "equator_prime" => ["branch_downlink_intent"]
           }

    assert summary["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["branch_downlink_intent"]
           }

    assert summary["directions"] == ["command", "downlink"]
    assert summary["direction_counts"] == %{"command" => 1, "downlink" => 1}

    assert summary["contact_ids_by_direction"] == %{
             "command" => ["branch_command_intent"],
             "downlink" => ["branch_downlink_intent"]
           }

    assert summary["direction_routing"] == %{
             "command" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_command_intent"],
               "capacity_pack_contact_ids" => []
             },
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_downlink_intent"],
               "capacity_pack_required_capacity_fraction" => 0.35,
               "capacity_pack_contact_ids" => ["branch_downlink_intent"]
             }
           }

    assert summary["trust_boundaries"] == ["branch_contact_intent"]
    assert summary["branch_local_contact_intent_pressure"]
    assert summary["branch_local_station_feedback_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_intent_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_contact_intent_replay_summary(artifact) ==
             summary
  end

  test "contact intent replay derives branch candidate-source routing from raw intents" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "source_contact_intents" => [
          %{
            "schema_contract" => "contact_intent.v1",
            "id" => "raw_branch_downlink_intent",
            "activity_id" => "raw_branch_downlink_intent",
            "scenario_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "starts_at_s" => 10.0,
            "ends_at_s" => 70.0,
            "station_calendar_status" => "reserved",
            "cadence_import_status" => "ready_for_import",
            "policy_classification" => "review_only",
            "required_capacity_fraction" => 0.35,
            "direction_counts" => %{"stale_direction" => 99},
            "contact_ids_by_direction" => %{"stale_direction" => ["stale_contact"]},
            "direction_routing" => %{
              "stale_direction" => %{
                "contact_count" => 99,
                "contact_ids" => ["stale_contact"]
              }
            },
            "provenance" => %{"trust_boundary" => "branch_raw_contact_intent"}
          },
          %{
            "schema_contract" => "contact_intent.v1",
            "id" => "raw_branch_command_intent",
            "activity_id" => "raw_branch_command_intent",
            "scenario_id" => "leo_1",
            "ground_station_id" => "dss_43",
            "direction" => "Command",
            "starts_at_s" => 80.0,
            "ends_at_s" => 120.0,
            "provenance" => %{"trust_boundary" => "branch_raw_contact_intent"}
          }
        ]
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_intent"],
            "directions" => ["uplink"],
            "direction_counts" => %{"uplink" => 9},
            "contact_ids_by_direction" => %{"uplink" => ["provenance_intent"]}
          }
        }
      }
    }

    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_intent"

    assert summary["contract"] == "contact_intent.v1"
    assert summary["source_report_count"] == 2
    assert summary["source_report_row_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_intents[0]",
             "candidate_source.candidate_refresh_request.source_contact_intents[1]"
           ]

    assert summary["station_feedback_count"] == 1
    assert summary["station_calendar_status_counts"] == %{"reserved" => 1}
    assert summary["cadence_import_status_counts"] == %{"ready_for_import" => 1}
    assert summary["policy_classification_counts"] == %{"review_only" => 1}
    assert summary["capacity_pack_required_contact_count"] == 1
    assert summary["capacity_pack_required_capacity_fraction"] == 0.35

    assert summary["capacity_pack_required_capacity_fraction_by_direction"] == %{
             "downlink" => 0.35
           }

    assert summary["capacity_pack_required_capacity_fraction_by_direction_and_ground_station"] ==
             %{
               "downlink" => %{"equator_prime" => 0.35}
             }

    assert summary["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["raw_branch_downlink_intent"]
           }

    assert summary["capacity_pack_contact_ids_by_direction_and_ground_station"] == %{
             "downlink" => %{"equator_prime" => ["raw_branch_downlink_intent"]}
           }

    assert summary["directions"] == ["command", "downlink"]
    assert summary["direction_counts"] == %{"command" => 1, "downlink" => 1}

    assert summary["contact_ids_by_direction"] == %{
             "command" => ["raw_branch_command_intent"],
             "downlink" => ["raw_branch_downlink_intent"]
           }

    assert summary["contact_ids_by_direction_and_ground_station"] == %{
             "command" => %{"dss_43" => ["raw_branch_command_intent"]},
             "downlink" => %{"equator_prime" => ["raw_branch_downlink_intent"]}
           }

    assert summary["direction_routing"] == %{
             "command" => %{
               "contact_count" => 1,
               "contact_ids" => ["raw_branch_command_intent"],
               "capacity_pack_contact_ids" => [],
               "ground_station_ids" => ["dss_43"],
               "contact_ids_by_ground_station" => %{
                 "dss_43" => ["raw_branch_command_intent"]
               }
             },
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["raw_branch_downlink_intent"],
               "capacity_pack_required_capacity_fraction" => 0.35,
               "capacity_pack_contact_ids" => ["raw_branch_downlink_intent"],
               "ground_station_ids" => ["equator_prime"],
               "contact_ids_by_ground_station" => %{
                 "equator_prime" => ["raw_branch_downlink_intent"]
               },
               "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                 "equator_prime" => 0.35
               },
               "capacity_pack_contact_ids_by_ground_station" => %{
                 "equator_prime" => ["raw_branch_downlink_intent"]
               }
             }
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_raw_contact_intent"]
    assert summary["branch_local_contact_intent_pressure"]
    assert summary["branch_local_station_feedback_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_intent_candidate_source_report_summary_only"
  end

  test "contact intent replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_contact_intent"
            ],
            "station_feedback_count" => 1,
            "station_calendar_status_counts" => %{"reserved" => 1},
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["direct_branch_intent"]},
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["direct_branch_intent"],
                "capacity_pack_contact_ids" => []
              }
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_intent_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_intent"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_intent"
           ]

    assert summary["station_feedback_count"] == 1
    assert summary["station_calendar_status_counts"] == %{"reserved" => 1}
    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["direct_branch_intent"]}

    assert summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["direct_branch_intent"],
               "capacity_pack_contact_ids" => []
             }
           }

    assert summary["branch_local_contact_intent_pressure"]
    assert summary["branch_local_station_feedback_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_intent_candidate_source_report_summary_only"
  end

  test "contact intent replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_intent" => %{},
            "command_window_report" => %{
              "contract" => "command_window_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_command_window_report"
              ]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_contact_intent"],
            "station_feedback_count" => 1,
            "station_calendar_status_counts" => %{"reserved" => 1},
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["provenance_intent"]},
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["provenance_intent"],
                "capacity_pack_contact_ids" => []
              }
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    assert summary["source"] == "candidate_refresh.source_report_provenance.contact_intent"
    assert summary["source_report_paths"] == ["source_contact_intent"]
    assert summary["station_feedback_count"] == 1
    assert summary["station_calendar_status_counts"] == %{"reserved" => 1}
    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["provenance_intent"]}

    assert summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["provenance_intent"],
               "capacity_pack_contact_ids" => []
             }
           }

    assert summary["branch_local_contact_intent_pressure"]
    assert summary["branch_local_station_feedback_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_intent_source_report_provenance_only"
  end

  test "contact intent replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_intent" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_intent"
              ],
              "directions" => ["downlink"],
              "direction_counts" => %{"downlink" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_intent"],
            "station_feedback_count" => 9,
            "directions" => ["uplink"],
            "direction_counts" => %{"uplink" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_intent"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_intent"
           ]

    assert summary["station_feedback_count"] == 0
    assert summary["directions"] == ["downlink"]
    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["branch_local_contact_intent_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_intent_candidate_source_report_summary_only"
  end
end
