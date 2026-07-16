defmodule OrbitalDynamics.CandidateRefresh.ContactIntentRequiredCapacityRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates contact intent required capacity demand" do
    refresh = %{
      "source_contact_intents" => [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_direct_capacity",
          "activity_id" => "intent_direct_capacity",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "Down Link",
          "starts_at_s" => 10.0,
          "ends_at_s" => 70.0,
          "station_calendar_status" => "reserved",
          "cadence_import_status" => "ready_for_import",
          "policy_classification" => "review_only",
          "required_capacity_fraction" => 0.25,
          "capacity_pack_required_capacity_fraction" => 99.0,
          "direction_counts" => %{"stale_direction" => 99},
          "contact_ids_by_direction" => %{"stale_direction" => ["stale_contact_intent"]},
          "provenance" => %{"trust_boundary" => "ops_contact_intent"}
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_nested_capacity",
          "activity_id" => "intent_nested_capacity",
          "scenario_id" => "leo_1",
          "ground_station_id" => "dss_43",
          "direction" => "tracking_pass",
          "starts_at_s" => 80.0,
          "ends_at_s" => 130.0,
          "station_availability" => "unavailable",
          "cadence_import_status" => "blocked",
          "policy_classification" => "blocked_by_policy",
          "capacity_model" => %{"station_capacity_requirement" => "0.4"},
          "provenance" => %{"trust_boundary" => "ops_contact_intent"}
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_station_only",
          "activity_id" => "intent_station_only",
          "scenario_id" => "leo_1",
          "ground_station_id" => "dss_43",
          "direction" => "Command",
          "starts_at_s" => 140.0,
          "ends_at_s" => 180.0,
          "provenance" => %{"trust_boundary" => "ops_contact_intent"}
        }
      ]
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_contact_intent_contract" => "contact_intent.v1",
             "source_report_contact_intent_count" => 3,
             "source_report_contact_intent_row_count" => 3,
             "source_report_contact_intent_paths" => [
               "source_contact_intents[0]",
               "source_contact_intents[1]",
               "source_contact_intents[2]"
             ],
             "source_report_contact_intent_capacity_pack_required_contact_count" => 2,
             "source_report_contact_intent_capacity_pack_required_capacity_fraction" => 0.65,
             "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_ground_station" =>
               %{
                 "dss_43" => 0.4,
                 "equator_prime" => 0.25
               },
             "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_direction" =>
               %{
                 "downlink" => 0.25,
                 "tracking" => 0.4
               },
             "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => 0.25},
                 "tracking" => %{"dss_43" => 0.4}
               },
             "source_report_contact_intent_required_capacity_fraction_source_counts" => %{
               "capacity_model" => 1,
               "contact_required_capacity_fraction" => 1
             },
             "source_report_contact_intent_required_capacity_fraction_contact_ids_by_source" => %{
               "capacity_model" => ["intent_nested_capacity"],
               "contact_required_capacity_fraction" => ["intent_direct_capacity"]
             },
             "source_report_contact_intent_capacity_pack_contact_ids_by_ground_station" => %{
               "dss_43" => ["intent_nested_capacity"],
               "equator_prime" => ["intent_direct_capacity"]
             },
             "source_report_contact_intent_contact_ids_by_ground_station" => %{
               "dss_43" => ["intent_nested_capacity", "intent_station_only"],
               "equator_prime" => ["intent_direct_capacity"]
             },
             "source_report_contact_intent_capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["intent_direct_capacity"],
               "tracking" => ["intent_nested_capacity"]
             },
             "source_report_contact_intent_capacity_pack_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
                 "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
               },
             "source_report_contact_intent_contact_ids_by_direction_and_ground_station" => %{
               "command" => %{"dss_43" => ["intent_station_only"]},
               "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
               "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
             },
             "source_report_contact_intent_directions" => ["command", "downlink", "tracking"],
             "source_report_contact_intent_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "tracking" => 1
             },
             "source_report_contact_intent_contact_ids_by_direction" => %{
               "command" => ["intent_station_only"],
               "downlink" => ["intent_direct_capacity"],
               "tracking" => ["intent_nested_capacity"]
             },
             "source_reports" => %{
               "contact_intent" => %{
                 "capacity_pack_required_capacity_fraction" => 0.65,
                 "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                   "dss_43" => 0.4,
                   "equator_prime" => 0.25
                 },
                 "capacity_pack_required_capacity_fraction_by_direction" => %{
                   "downlink" => 0.25,
                   "tracking" => 0.4
                 },
                 "capacity_pack_required_capacity_fraction_by_direction_and_ground_station" => %{
                   "downlink" => %{"equator_prime" => 0.25},
                   "tracking" => %{"dss_43" => 0.4}
                 },
                 "capacity_pack_contact_ids_by_direction" => %{
                   "downlink" => ["intent_direct_capacity"],
                   "tracking" => ["intent_nested_capacity"]
                 },
                 "capacity_pack_contact_ids_by_direction_and_ground_station" => %{
                   "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
                   "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
                 },
                 "contact_ids_by_direction_and_ground_station" => %{
                   "command" => %{"dss_43" => ["intent_station_only"]},
                   "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
                   "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
                 },
                 "contact_ids_by_ground_station" => %{
                   "dss_43" => ["intent_nested_capacity", "intent_station_only"],
                   "equator_prime" => ["intent_direct_capacity"]
                 },
                 "directions" => ["command", "downlink", "tracking"],
                 "direction_counts" => %{
                   "command" => 1,
                   "downlink" => 1,
                   "tracking" => 1
                 },
                 "contact_ids_by_direction" => %{
                   "command" => ["intent_station_only"],
                   "downlink" => ["intent_direct_capacity"],
                   "tracking" => ["intent_nested_capacity"]
                 },
                 "direction_routing" => %{
                   "command" => %{
                     "contact_count" => 1,
                     "contact_ids" => ["intent_station_only"],
                     "capacity_pack_contact_ids" => [],
                     "ground_station_ids" => ["dss_43"],
                     "contact_ids_by_ground_station" => %{
                       "dss_43" => ["intent_station_only"]
                     }
                   },
                   "downlink" => %{
                     "contact_count" => 1,
                     "contact_ids" => ["intent_direct_capacity"],
                     "capacity_pack_required_capacity_fraction" => 0.25,
                     "capacity_pack_contact_ids" => ["intent_direct_capacity"],
                     "ground_station_ids" => ["equator_prime"],
                     "contact_ids_by_ground_station" => %{
                       "equator_prime" => ["intent_direct_capacity"]
                     },
                     "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                       "equator_prime" => 0.25
                     },
                     "capacity_pack_contact_ids_by_ground_station" => %{
                       "equator_prime" => ["intent_direct_capacity"]
                     }
                   },
                   "tracking" => %{
                     "contact_count" => 1,
                     "contact_ids" => ["intent_nested_capacity"],
                     "capacity_pack_required_capacity_fraction" => 0.4,
                     "capacity_pack_contact_ids" => ["intent_nested_capacity"],
                     "ground_station_ids" => ["dss_43"],
                     "contact_ids_by_ground_station" => %{
                       "dss_43" => ["intent_nested_capacity"]
                     },
                     "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                       "dss_43" => 0.4
                     },
                     "capacity_pack_contact_ids_by_ground_station" => %{
                       "dss_43" => ["intent_nested_capacity"]
                     }
                   }
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_contact_intent_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.contact_intent",
      "contract" => "contact_intent.v1",
      "source_report_count" => 3,
      "source_report_row_count" => 3,
      "source_report_paths" => [
        "source_contact_intents[0]",
        "source_contact_intents[1]",
        "source_contact_intents[2]"
      ],
      "station_feedback_count" => 2,
      "station_calendar_status_counts" => %{
        "reserved" => 1,
        "unavailable" => 1
      },
      "cadence_import_status_counts" => %{
        "blocked" => 1,
        "ready_for_import" => 1
      },
      "policy_classification_counts" => %{
        "blocked_by_policy" => 1,
        "review_only" => 1
      },
      "capacity_pack_required_contact_count" => 2,
      "capacity_pack_required_capacity_fraction" => 0.65,
      "capacity_pack_required_capacity_fraction_by_ground_station" => %{
        "dss_43" => 0.4,
        "equator_prime" => 0.25
      },
      "capacity_pack_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.25,
        "tracking" => 0.4
      },
      "capacity_pack_required_capacity_fraction_by_direction_and_ground_station" => %{
        "downlink" => %{"equator_prime" => 0.25},
        "tracking" => %{"dss_43" => 0.4}
      },
      "required_capacity_fraction_source_counts" => %{
        "capacity_model" => 1,
        "contact_required_capacity_fraction" => 1
      },
      "required_capacity_fraction_contact_ids_by_source" => %{
        "capacity_model" => ["intent_nested_capacity"],
        "contact_required_capacity_fraction" => ["intent_direct_capacity"]
      },
      "capacity_pack_contact_ids_by_ground_station" => %{
        "dss_43" => ["intent_nested_capacity"],
        "equator_prime" => ["intent_direct_capacity"]
      },
      "contact_ids_by_ground_station" => %{
        "dss_43" => ["intent_nested_capacity", "intent_station_only"],
        "equator_prime" => ["intent_direct_capacity"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "downlink" => ["intent_direct_capacity"],
        "tracking" => ["intent_nested_capacity"]
      },
      "capacity_pack_contact_ids_by_direction_and_ground_station" => %{
        "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
        "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
      },
      "directions" => ["command", "downlink", "tracking"],
      "direction_counts" => %{
        "command" => 1,
        "downlink" => 1,
        "tracking" => 1
      },
      "contact_ids_by_direction" => %{
        "command" => ["intent_station_only"],
        "downlink" => ["intent_direct_capacity"],
        "tracking" => ["intent_nested_capacity"]
      },
      "contact_ids_by_direction_and_ground_station" => %{
        "command" => %{"dss_43" => ["intent_station_only"]},
        "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
        "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
      },
      "direction_routing" => %{
        "command" => %{
          "contact_count" => 1,
          "contact_ids" => ["intent_station_only"],
          "capacity_pack_contact_ids" => [],
          "ground_station_ids" => ["dss_43"],
          "contact_ids_by_ground_station" => %{
            "dss_43" => ["intent_station_only"]
          }
        },
        "downlink" => %{
          "contact_count" => 1,
          "contact_ids" => ["intent_direct_capacity"],
          "capacity_pack_required_capacity_fraction" => 0.25,
          "capacity_pack_contact_ids" => ["intent_direct_capacity"],
          "ground_station_ids" => ["equator_prime"],
          "contact_ids_by_ground_station" => %{
            "equator_prime" => ["intent_direct_capacity"]
          },
          "capacity_pack_required_capacity_fraction_by_ground_station" => %{
            "equator_prime" => 0.25
          },
          "capacity_pack_contact_ids_by_ground_station" => %{
            "equator_prime" => ["intent_direct_capacity"]
          }
        },
        "tracking" => %{
          "contact_count" => 1,
          "contact_ids" => ["intent_nested_capacity"],
          "capacity_pack_required_capacity_fraction" => 0.4,
          "capacity_pack_contact_ids" => ["intent_nested_capacity"],
          "ground_station_ids" => ["dss_43"],
          "contact_ids_by_ground_station" => %{
            "dss_43" => ["intent_nested_capacity"]
          },
          "capacity_pack_required_capacity_fraction_by_ground_station" => %{
            "dss_43" => 0.4
          },
          "capacity_pack_contact_ids_by_ground_station" => %{
            "dss_43" => ["intent_nested_capacity"]
          }
        }
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_contact_intent"],
      "branch_local_contact_intent_pressure" => true,
      "branch_local_station_feedback_pressure" => true,
      "branch_local_capacity_pack_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "contact_intent_source_report_provenance_only",
        "operator_authority" => "not_granted_by_contact_intent_replay_summary",
        "contact_generation" => "not_performed_by_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_intent_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.contact_intent_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_intent_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_contact_intent_contract" => "contact_intent.v1",
             "source_report_contact_intent_count" => 3,
             "source_report_contact_intent_row_count" => 3,
             "source_report_contact_intent_paths" => [
               "source_contact_intents[0]",
               "source_contact_intents[1]",
               "source_contact_intents[2]"
             ],
             "source_report_contact_intent_capacity_pack_required_capacity_fraction" => 0.65,
             "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_ground_station" =>
               %{"dss_43" => 0.4, "equator_prime" => 0.25},
             "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_direction" =>
               %{"downlink" => 0.25, "tracking" => 0.4},
             "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => 0.25},
                 "tracking" => %{"dss_43" => 0.4}
               },
             "source_report_contact_intent_capacity_pack_contact_ids_by_ground_station" => %{
               "dss_43" => ["intent_nested_capacity"],
               "equator_prime" => ["intent_direct_capacity"]
             },
             "source_report_contact_intent_contact_ids_by_ground_station" => %{
               "dss_43" => ["intent_nested_capacity", "intent_station_only"],
               "equator_prime" => ["intent_direct_capacity"]
             },
             "source_report_contact_intent_capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["intent_direct_capacity"],
               "tracking" => ["intent_nested_capacity"]
             },
             "source_report_contact_intent_capacity_pack_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
                 "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
               },
             "source_report_contact_intent_contact_ids_by_direction_and_ground_station" => %{
               "command" => %{"dss_43" => ["intent_station_only"]},
               "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
               "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
             },
             "source_report_contact_intent_directions" => ["command", "downlink", "tracking"],
             "source_report_contact_intent_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "tracking" => 1
             },
             "source_report_contact_intent_contact_ids_by_direction" => %{
               "command" => ["intent_station_only"],
               "downlink" => ["intent_direct_capacity"],
               "tracking" => ["intent_nested_capacity"]
             },
             "source_report_contact_intent_direction_routing" => %{
               "command" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["intent_station_only"],
                 "capacity_pack_contact_ids" => [],
                 "ground_station_ids" => ["dss_43"],
                 "contact_ids_by_ground_station" => %{
                   "dss_43" => ["intent_station_only"]
                 }
               },
               "downlink" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["intent_direct_capacity"],
                 "capacity_pack_required_capacity_fraction" => 0.25,
                 "capacity_pack_contact_ids" => ["intent_direct_capacity"],
                 "ground_station_ids" => ["equator_prime"],
                 "contact_ids_by_ground_station" => %{
                   "equator_prime" => ["intent_direct_capacity"]
                 },
                 "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                   "equator_prime" => 0.25
                 },
                 "capacity_pack_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["intent_direct_capacity"]
                 }
               },
               "tracking" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["intent_nested_capacity"],
                 "capacity_pack_required_capacity_fraction" => 0.4,
                 "capacity_pack_contact_ids" => ["intent_nested_capacity"],
                 "ground_station_ids" => ["dss_43"],
                 "contact_ids_by_ground_station" => %{
                   "dss_43" => ["intent_nested_capacity"]
                 },
                 "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                   "dss_43" => 0.4
                 },
                 "capacity_pack_contact_ids_by_ground_station" => %{
                   "dss_43" => ["intent_nested_capacity"]
                 }
               }
             },
             "source_report_contact_intent_branch_local_contact_intent_pressure" => true,
             "source_report_contact_intent_branch_local_station_feedback_pressure" => true,
             "source_report_contact_intent_branch_local_capacity_pack_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.contact_intent_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_intent_replay_summary(artifact) ==
             replay_summary
  end
end
