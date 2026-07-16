defmodule OrbitalDynamics.CandidateRefresh.ContactIntentReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview, Schema}
  alias OrbitalDynamics.Communications.ContactIntent

  test "source report summary replays compact contact intent summaries" do
    direct_summary =
      [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "summary_downlink_contact",
          "activity_id" => "summary_downlink_contact",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "required_capacity_fraction" => 0.25
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "summary_command_contact",
          "activity_id" => "summary_command_contact",
          "ground_station_id" => "dss_43",
          "direction" => "command"
        }
      ]
      |> ContactIntent.summary()
      |> Map.merge(%{
        "contact_intent_count" => 99,
        "capacity_pack_required_contact_count" => 99,
        "direction_counts" => %{"uplink" => 99},
        "direction_routing" => %{
          "uplink" => %{
            "contact_count" => 99,
            "contact_ids" => ["stale_route_from_embedded_summary"]
          }
        }
      })
      |> Map.put("provenance", %{"trust_boundary" => "direct_contact_summary"})

    wrapped_summary =
      [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "summary_tracking_contact",
          "activity_id" => "summary_tracking_contact",
          "ground_station_id" => "dss_43",
          "direction" => "tracking",
          "capacity_model" => %{"station_capacity_requirement" => "0.4"}
        }
      ]
      |> ContactIntent.summary()

    refresh = %{
      "source_contact_intent_summary" => direct_summary,
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "provenance" => %{"trust_boundary" => "wrapped_contact_summary"},
        "contact_intent_summary" => wrapped_summary
      }
    }

    expected_direction_routing = %{
      "command" => %{
        "contact_count" => 1,
        "contact_ids" => ["summary_command_contact"],
        "capacity_pack_contact_ids" => [],
        "ground_station_ids" => ["dss_43"],
        "contact_ids_by_ground_station" => %{
          "dss_43" => ["summary_command_contact"]
        }
      },
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["summary_downlink_contact"],
        "capacity_pack_required_capacity_fraction" => 0.25,
        "capacity_pack_contact_ids" => ["summary_downlink_contact"],
        "ground_station_ids" => ["equator_prime"],
        "contact_ids_by_ground_station" => %{
          "equator_prime" => ["summary_downlink_contact"]
        },
        "capacity_pack_required_capacity_fraction_by_ground_station" => %{
          "equator_prime" => 0.25
        },
        "capacity_pack_contact_ids_by_ground_station" => %{
          "equator_prime" => ["summary_downlink_contact"]
        }
      },
      "tracking" => %{
        "contact_count" => 1,
        "contact_ids" => ["summary_tracking_contact"],
        "capacity_pack_required_capacity_fraction" => 0.4,
        "capacity_pack_contact_ids" => ["summary_tracking_contact"],
        "ground_station_ids" => ["dss_43"],
        "contact_ids_by_ground_station" => %{
          "dss_43" => ["summary_tracking_contact"]
        },
        "capacity_pack_required_capacity_fraction_by_ground_station" => %{
          "dss_43" => 0.4
        },
        "capacity_pack_contact_ids_by_ground_station" => %{
          "dss_43" => ["summary_tracking_contact"]
        }
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 2,
             "source_report_row_count" => 3,
             "source_report_counts_by_contract" => %{"contact_intent_summary.v1" => 2},
             "source_report_row_counts_by_contract" => %{"contact_intent_summary.v1" => 3},
             "source_report_contact_intent_contract" => "contact_intent_summary.v1",
             "source_report_contact_intent_count" => 2,
             "source_report_contact_intent_row_count" => 3,
             "source_report_contact_intent_paths" => [
               "source_contact_intent_summary",
               "source_result_artifact.contact_intent_summary"
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
               "capacity_model" => ["summary_tracking_contact"],
               "contact_required_capacity_fraction" => ["summary_downlink_contact"]
             },
             "source_report_contact_intent_capacity_pack_contact_ids_by_ground_station" => %{
               "dss_43" => ["summary_tracking_contact"],
               "equator_prime" => ["summary_downlink_contact"]
             },
             "source_report_contact_intent_contact_ids_by_ground_station" => %{
               "dss_43" => ["summary_command_contact", "summary_tracking_contact"],
               "equator_prime" => ["summary_downlink_contact"]
             },
             "source_report_contact_intent_capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["summary_downlink_contact"],
               "tracking" => ["summary_tracking_contact"]
             },
             "source_report_contact_intent_capacity_pack_contact_ids_by_direction_and_ground_station" =>
               %{
                 "downlink" => %{"equator_prime" => ["summary_downlink_contact"]},
                 "tracking" => %{"dss_43" => ["summary_tracking_contact"]}
               },
             "source_report_contact_intent_contact_ids_by_direction_and_ground_station" => %{
               "command" => %{"dss_43" => ["summary_command_contact"]},
               "downlink" => %{"equator_prime" => ["summary_downlink_contact"]},
               "tracking" => %{"dss_43" => ["summary_tracking_contact"]}
             },
             "source_report_contact_intent_directions" => ["command", "downlink", "tracking"],
             "source_report_contact_intent_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "tracking" => 1
             },
             "source_report_contact_intent_contact_ids_by_direction" => %{
               "command" => ["summary_command_contact"],
               "downlink" => ["summary_downlink_contact"],
               "tracking" => ["summary_tracking_contact"]
             },
             "source_reports" => %{
               "contact_intent" => %{
                 "contract" => "contact_intent_summary.v1",
                 "source_summary_model_counts" => %{
                   "artifact_only_contact_intent_summary" => 2
                 },
                 "source_summary_schema_contract_counts" => %{
                   "contact_intent_summary.v1" => 2
                 },
                 "source_artifact_type_counts" => %{"contact_intent.v1" => 2},
                 "paths" => [
                   "source_contact_intent_summary",
                   "source_result_artifact.contact_intent_summary"
                 ],
                 "directions" => ["command", "downlink", "tracking"],
                 "direction_routing" => ^expected_direction_routing,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "direct_contact_summary",
                   "wrapped_contact_summary"
                 ]
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.contact_intent_replay_summary(refresh)

    assert %{
             "contract" => "contact_intent_summary.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 3,
             "source_report_paths" => [
               "source_contact_intent_summary",
               "source_result_artifact.contact_intent_summary"
             ],
             "station_feedback_count" => 0,
             "capacity_pack_required_contact_count" => 2,
             "capacity_pack_required_capacity_fraction" => 0.65,
             "capacity_pack_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25,
               "tracking" => 0.4
             },
             "capacity_pack_required_capacity_fraction_by_direction_and_ground_station" => %{
               "downlink" => %{"equator_prime" => 0.25},
               "tracking" => %{"dss_43" => 0.4}
             },
             "capacity_pack_contact_ids_by_direction_and_ground_station" => %{
               "downlink" => %{"equator_prime" => ["summary_downlink_contact"]},
               "tracking" => %{"dss_43" => ["summary_tracking_contact"]}
             },
             "contact_ids_by_direction_and_ground_station" => %{
               "command" => %{"dss_43" => ["summary_command_contact"]},
               "downlink" => %{"equator_prime" => ["summary_downlink_contact"]},
               "tracking" => %{"dss_43" => ["summary_tracking_contact"]}
             },
             "directions" => ["command", "downlink", "tracking"],
             "direction_counts" => %{"command" => 1, "downlink" => 1, "tracking" => 1},
             "contact_ids_by_direction" => %{
               "command" => ["summary_command_contact"],
               "downlink" => ["summary_downlink_contact"],
               "tracking" => ["summary_tracking_contact"]
             },
             "direction_routing" => ^expected_direction_routing,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["direct_contact_summary", "wrapped_contact_summary"],
             "branch_local_contact_intent_pressure" => true,
             "branch_local_capacity_pack_pressure" => true
           } = replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert CandidateRefresh.contact_intent_replay_summary(artifact) == replay_summary
  end

  test "compact contact intent source summaries derive stale aggregate routing from rows" do
    rows = [
      %{
        "schema_contract" => "contact_intent.v1",
        "id" => "row_downlink_contact",
        "activity_id" => "row_downlink_contact",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "required_capacity_fraction" => 0.4
      },
      %{
        "schema_contract" => "contact_intent.v1",
        "id" => "row_command_contact",
        "activity_id" => "row_command_contact",
        "ground_station_id" => "dss_43",
        "direction" => "command"
      }
    ]

    stale_summary =
      rows
      |> ContactIntent.summary()
      |> Map.put("rows", rows)
      |> Map.put("provenance", %{"trust_boundary" => "row_derived_contact_summary"})
      |> Map.merge(%{
        "contact_intent_count" => 99,
        "capacity_pack_required_contact_count" => 99,
        "capacity_pack_required_capacity_fraction" => 9.9,
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "stale_station" => 9.9
        },
        "capacity_pack_required_capacity_fraction_by_direction" => %{"uplink" => 9.9},
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id" => %{
          "uplink" => %{"stale_station" => 9.9}
        },
        "required_capacity_fraction_contact_ids_by_source" => %{
          "stale_source" => ["stale_contact"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "stale_station" => ["stale_contact"]
        },
        "contact_ids_by_ground_station_id" => %{"stale_station" => ["stale_contact"]},
        "capacity_pack_contact_ids_by_direction" => %{"uplink" => ["stale_contact"]},
        "capacity_pack_contact_ids_by_direction_and_ground_station_id" => %{
          "uplink" => %{"stale_station" => ["stale_contact"]}
        },
        "contact_ids_by_direction_and_ground_station_id" => %{
          "uplink" => %{"stale_station" => ["stale_contact"]}
        },
        "directions" => ["uplink"],
        "direction_counts" => %{"uplink" => 99},
        "contact_ids_by_direction" => %{"uplink" => ["stale_contact"]},
        "direction_routing" => %{
          "uplink" => %{
            "contact_count" => 99,
            "contact_ids" => ["stale_contact"],
            "capacity_pack_required_capacity_fraction" => 9.9,
            "capacity_pack_contact_ids" => ["stale_contact"]
          }
        }
      })

    refresh = %{"source_contact_intent_summary" => stale_summary}

    expected_direction_routing = %{
      "command" => %{
        "contact_count" => 1,
        "contact_ids" => ["row_command_contact"],
        "capacity_pack_contact_ids" => [],
        "ground_station_ids" => ["dss_43"],
        "contact_ids_by_ground_station" => %{"dss_43" => ["row_command_contact"]}
      },
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["row_downlink_contact"],
        "capacity_pack_required_capacity_fraction" => 0.4,
        "capacity_pack_contact_ids" => ["row_downlink_contact"],
        "ground_station_ids" => ["equator_prime"],
        "contact_ids_by_ground_station" => %{
          "equator_prime" => ["row_downlink_contact"]
        },
        "capacity_pack_required_capacity_fraction_by_ground_station" => %{
          "equator_prime" => 0.4
        },
        "capacity_pack_contact_ids_by_ground_station" => %{
          "equator_prime" => ["row_downlink_contact"]
        }
      }
    }

    assert %{
             "source_report_contact_intent_count" => 1,
             "source_report_contact_intent_row_count" => 2,
             "source_report_contact_intent_capacity_pack_required_contact_count" => 1,
             "source_report_contact_intent_capacity_pack_required_capacity_fraction" => 0.4,
             "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 0.4},
             "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_direction" =>
               %{"downlink" => 0.4},
             "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
               %{"downlink" => %{"equator_prime" => 0.4}},
             "source_report_contact_intent_capacity_pack_contact_ids_by_ground_station" => %{
               "equator_prime" => ["row_downlink_contact"]
             },
             "source_report_contact_intent_contact_ids_by_ground_station" => %{
               "dss_43" => ["row_command_contact"],
               "equator_prime" => ["row_downlink_contact"]
             },
             "source_report_contact_intent_capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["row_downlink_contact"]
             },
             "source_report_contact_intent_contact_ids_by_direction_and_ground_station" => %{
               "command" => %{"dss_43" => ["row_command_contact"]},
               "downlink" => %{"equator_prime" => ["row_downlink_contact"]}
             },
             "source_report_contact_intent_directions" => ["command", "downlink"],
             "source_report_contact_intent_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_report_contact_intent_contact_ids_by_direction" => %{
               "command" => ["row_command_contact"],
               "downlink" => ["row_downlink_contact"]
             },
             "source_report_contact_intent_direction_routing" => ^expected_direction_routing
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    refute Map.has_key?(
             source_summary["source_report_contact_intent_contact_ids_by_direction"],
             "uplink"
           )

    assert %{
             "source_report_row_count" => 2,
             "capacity_pack_required_contact_count" => 1,
             "capacity_pack_required_capacity_fraction" => 0.4,
             "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.4},
             "capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["row_downlink_contact"]
             },
             "directions" => ["command", "downlink"],
             "direction_counts" => %{"command" => 1, "downlink" => 1},
             "contact_ids_by_direction" => %{
               "command" => ["row_command_contact"],
               "downlink" => ["row_downlink_contact"]
             },
             "direction_routing" => ^expected_direction_routing,
             "branch_local_contact_intent_pressure" => true,
             "branch_local_capacity_pack_pressure" => true
           } = CandidateRefresh.contact_intent_replay_summary(refresh)
  end

  test "operator review and import lift contact intent summaries from candidate refresh artifacts" do
    intent_summary = fn source, prefix ->
      [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "#{prefix}_downlink_contact",
          "activity_id" => "#{prefix}_downlink_contact",
          "ground_station_id" => "#{prefix}_station",
          "direction" => "downlink",
          "required_capacity_fraction" => 0.25
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "#{prefix}_command_contact",
          "activity_id" => "#{prefix}_command_contact",
          "ground_station_id" => "#{prefix}_station",
          "direction" => "command"
        }
      ]
      |> ContactIntent.summary()
      |> Map.put("source", source)
      |> Map.put("provenance", %{"trust_boundary" => source})
    end

    direct_summary = intent_summary.("unit_test.contact_intent_summary.direct", "direct")
    canonical_summary = intent_summary.("unit_test.contact_intent_summary.canonical", "canonical")
    wrapped_summary = intent_summary.("unit_test.contact_intent_summary.wrapped", "wrapped")
    nested_summary = intent_summary.("unit_test.contact_intent_summary.nested", "nested")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_intent_summary_handoff",
      "source_contact_intent_summary" => [direct_summary],
      "contact_intent_summary" => canonical_summary,
      "source_result_artifact" => [
        wrapped_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_intent_summary" => nested_summary
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    intent_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "contact_intent_review"))

    assert length(intent_rows) == 8

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_intent_summary_handoff",
             "contact_intent_review_count" => 8,
             "review_type_counts" => %{"contact_intent_review" => 8}
           } = review

    assert Enum.sort(Enum.uniq(Enum.map(intent_rows, & &1["source"]))) == [
             "candidate_refresh.contact_intent_summary.summary_contacts",
             "candidate_refresh.source_contact_intent_summary[0].summary_contacts",
             "candidate_refresh.source_result_artifact[0].summary_contacts",
             "candidate_refresh.source_result_artifact[1].contact_intent_summary.summary_contacts"
           ]

    assert Enum.any?(
             intent_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.contact_intent_summary.summary_contacts",
                 "direction" => "downlink",
                 "ground_station_id" => "canonical_station",
                 "required_capacity_fraction" => 0.25,
                 "capacity_pack_required_capacity_fraction" => 0.25,
                 "capacity_pack_contact_ids" => ["canonical_downlink_contact"],
                 "contact_ids" => ["canonical_downlink_contact"],
                 "source_summary_schema_contract" => "contact_intent_summary.v1",
                 "source_contact_intent_summary" => %{
                   "schema_contract" => "contact_intent_summary.v1",
                   "source" => "unit_test.contact_intent_summary.canonical",
                   "contact_intent_count" => 2,
                   "direction_routing" => %{
                     "downlink" => %{
                       "contact_ids" => ["canonical_downlink_contact"],
                       "capacity_pack_contact_ids" => ["canonical_downlink_contact"]
                     }
                   }
                 },
                 "source_contact_intent" => %{
                   "schema_contract" => "contact_intent_summary.v1",
                   "source_contact_intent_summary" => %{
                     "schema_contract" => "contact_intent_summary.v1"
                   }
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             intent_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.contact_intent_summary.summary_contacts",
                 "direction" => "command",
                 "capacity_pack_contact_ids" => [],
                 "contact_ids" => ["canonical_command_contact"]
               },
               &1
             )
           )

    import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "contact_intent_review"))

    assert length(import_rows) == 8

    assert %{
             "import_action_counts" => %{"review_contact_intent" => 8},
             "source_review_type_counts" => %{"contact_intent_review" => 8}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_contact_intent" and
                 &1["source_contact_intent_summary"]["schema_contract"] ==
                   "contact_intent_summary.v1" and
                 &1["source_review_row"]["source_contact_intent_summary"]["schema_contract"] ==
                   "contact_intent_summary.v1")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "contact intent replay treats capacity-pack routing maps as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_contact_intent"],
            "station_feedback_count" => 0,
            "capacity_pack_required_contact_count" => 0,
            "capacity_pack_required_capacity_fraction" => 0.0,
            "capacity_pack_required_capacity_fraction_by_ground_station" => %{},
            "capacity_pack_required_capacity_fraction_by_direction" => %{},
            "required_capacity_fraction_source_counts" => %{"capacity_model" => 1},
            "required_capacity_fraction_contact_ids_by_source" => %{
              "capacity_model" => ["intent_nested_capacity"]
            },
            "capacity_pack_contact_ids_by_ground_station" => %{
              "dss_43" => ["intent_nested_capacity"]
            },
            "contact_ids_by_ground_station" => %{
              "dss_43" => ["intent_nested_capacity"]
            },
            "capacity_pack_contact_ids_by_direction" => %{
              "tracking" => ["intent_nested_capacity"]
            },
            "direction_routing" => %{
              "tracking" => %{
                "capacity_pack_contact_ids" => ["intent_nested_capacity"]
              }
            },
            "station_calendar_status_counts" => %{},
            "cadence_import_status_counts" => %{},
            "policy_classification_counts" => %{},
            "direction_counts" => %{},
            "contact_ids_by_direction" => %{},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_contact_intent"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["station_feedback_count"] == 0
    assert summary["capacity_pack_required_contact_count"] == 1
    assert summary["capacity_pack_required_capacity_fraction"] == 0.0
    assert summary["capacity_pack_required_capacity_fraction_by_ground_station"] == %{}
    assert summary["capacity_pack_required_capacity_fraction_by_direction"] == %{}
    assert summary["required_capacity_fraction_source_counts"] == %{"capacity_model" => 1}

    assert summary["required_capacity_fraction_contact_ids_by_source"] == %{
             "capacity_model" => ["intent_nested_capacity"]
           }

    assert summary["capacity_pack_contact_ids_by_ground_station"] == %{
             "dss_43" => ["intent_nested_capacity"]
           }

    assert summary["contact_ids_by_ground_station"] == %{
             "dss_43" => ["intent_nested_capacity"]
           }

    assert summary["capacity_pack_contact_ids_by_direction"] == %{
             "tracking" => ["intent_nested_capacity"]
           }

    assert summary["direction_routing"] == %{
             "tracking" => %{
               "capacity_pack_contact_ids" => ["intent_nested_capacity"]
             }
           }

    assert summary["station_calendar_status_counts"] == %{}
    assert summary["cadence_import_status_counts"] == %{}
    assert summary["policy_classification_counts"] == %{}
    assert summary["direction_counts"] == %{}
    assert summary["contact_ids_by_direction"] == %{}
    assert summary["branch_local_contact_intent_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
    refute summary["branch_local_station_feedback_pressure"]
  end

  test "contact intent replay preserves all-contact station routing as contact pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_intent" => %{
            "contract" => "contact_intent.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_contact_intent"],
            "station_feedback_count" => 0,
            "capacity_pack_required_contact_count" => 0,
            "capacity_pack_required_capacity_fraction" => 0.0,
            "capacity_pack_required_capacity_fraction_by_ground_station" => %{},
            "capacity_pack_required_capacity_fraction_by_direction" => %{},
            "required_capacity_fraction_source_counts" => %{},
            "required_capacity_fraction_contact_ids_by_source" => %{},
            "capacity_pack_contact_ids_by_ground_station" => %{},
            "capacity_pack_contact_ids_by_direction" => %{},
            "contact_ids_by_ground_station" => %{
              "dss_43" => ["intent_station_only"]
            },
            "station_calendar_status_counts" => %{},
            "cadence_import_status_counts" => %{},
            "policy_classification_counts" => %{},
            "direction_counts" => %{},
            "contact_ids_by_direction" => %{},
            "direction_routing" => %{},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_contact_intent"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_intent_replay_summary(artifact)

    assert summary["source_report_count"] == 1

    assert summary["contact_ids_by_ground_station"] == %{
             "dss_43" => ["intent_station_only"]
           }

    assert summary["capacity_pack_contact_ids_by_ground_station"] == %{}
    assert summary["branch_local_contact_intent_pressure"]
    refute summary["branch_local_capacity_pack_pressure"]
    refute summary["branch_local_station_feedback_pressure"]
  end

  test "source report summary aggregates contact intent station feedback maps" do
    refresh = %{
      "source_contact_intents" => [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_reserved_station",
          "activity_id" => "intent_reserved_station",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "starts_at_s" => 10.0,
          "ends_at_s" => 70.0,
          "station_calendar_status" => "reserved",
          "cadence_import_status" => "ready_for_import",
          "policy_classification" => "review_only",
          "provenance" => %{"trust_boundary" => "ops_contact_intent"}
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_unavailable_station",
          "activity_id" => "intent_unavailable_station",
          "scenario_id" => "leo_1",
          "ground_station_id" => "dss_43",
          "direction" => "tracking",
          "starts_at_s" => 80.0,
          "ends_at_s" => 130.0,
          "station_availability" => "unavailable",
          "cadence_import_status" => "blocked",
          "policy_classification" => "blocked_by_policy",
          "provenance" => %{"trust_boundary" => "ops_contact_intent"}
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "intent_zero_capacity_station",
          "activity_id" => "intent_zero_capacity_station",
          "scenario_id" => "leo_1",
          "ground_station_id" => "dss_43",
          "direction" => "downlink",
          "starts_at_s" => 140.0,
          "ends_at_s" => 190.0,
          "capacity_fraction" => 0.0,
          "cadence_import_status" => "review_required",
          "policy_classification" => "analysis_only",
          "provenance" => %{"trust_boundary" => "ops_contact_intent"}
        }
      ]
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_contact_intent_station_feedback_count" => 3,
             "source_report_contact_intent_station_calendar_status_counts" => %{
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_report_contact_intent_cadence_import_status_counts" => %{
               "blocked" => 1,
               "ready_for_import" => 1,
               "review_required" => 1
             },
             "source_report_contact_intent_policy_classification_counts" => %{
               "analysis_only" => 1,
               "blocked_by_policy" => 1,
               "review_only" => 1
             },
             "source_reports" => %{
               "contact_intent" => %{
                 "station_feedback_count" => 3,
                 "station_calendar_status_counts" => %{
                   "reserved" => 1,
                   "unavailable" => 1
                 },
                 "cadence_import_status_counts" => %{
                   "blocked" => 1,
                   "ready_for_import" => 1,
                   "review_required" => 1
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_contact_intent_station_feedback_count" => 3,
             "source_report_contact_intent_station_calendar_status_counts" => %{
               "reserved" => 1,
               "unavailable" => 1
             },
             "source_report_contact_intent_policy_classification_counts" => %{
               "analysis_only" => 1,
               "blocked_by_policy" => 1,
               "review_only" => 1
             }
           } = CandidateRefresh.source_report_summary(artifact)
  end
end
