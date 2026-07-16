defmodule OrbitalDynamics.OperatorReview.CandidateRefreshContactIntentTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source contact intents become operator review rows" do
    source_intent = %{
      "schema_contract" => "contact_intent.v1",
      "id" => "review_source_downlink",
      "activity_id" => "review_source_downlink",
      "activity_type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "starts_at_s" => 120.0,
      "ends_at_s" => 180.0,
      "approval_status" => "operator_review_required",
      "approval_requirements" => [
        %{
          "schema_contract" => "approval_requirement.v1",
          "action" => "review_contact_intent",
          "requirement_type" => "contact_schedule_change",
          "required_authority" => "contact_schedule_authority",
          "reason" => "source contact intent requires schedule review"
        }
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "policy_bundle_id" => "command_contact_authority_v1",
        "classification" => "operator_review_required"
      }
    }

    singular_intent = %{
      source_intent
      | "id" => "blocked_source_command",
        "activity_id" => "blocked_source_command",
        "direction" => "command",
        "approval_status" => "blocked_by_policy",
        "approval_requirements" => []
    }

    ignored_import_ready_intent = %{
      source_intent
      | "id" => "ready_source_downlink",
        "activity_id" => "ready_source_downlink",
        "approval_status" => "approved",
        "approval_requirements" => [],
        "policy_decision" => nil
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_contact_intent_review:001",
      "source_contact_intents" => [source_intent, ignored_import_ready_intent],
      "contact_intent" => singular_intent
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_contact_intent_review:001",
             "review_count" => 2,
             "contact_intent_review_count" => 2
           } = package

    assert [
             %{
               "review_type" => "contact_intent_review",
               "source" => "candidate_refresh.source_contact_intents[0]",
               "activity_id" => "review_source_downlink",
               "contact_id" => "review_source_downlink",
               "required_operator_action" => "review_contact_intent",
               "approval_status" => "operator_review_required",
               "required_authority" => "contact_schedule_authority",
               "policy_bundle_id" => "command_contact_authority_v1",
               "source_policy_decision" => %{
                 "policy_bundle_id" => "command_contact_authority_v1"
               },
               "source_contact_intent" => %{
                 "schema_contract" => "contact_intent.v1",
                 "activity_id" => "review_source_downlink"
               }
             },
             %{
               "review_type" => "contact_intent_review",
               "source" => "candidate_refresh.contact_intent",
               "activity_id" => "blocked_source_command",
               "required_operator_action" => "review_contact_intent",
               "approval_status" => "blocked_by_policy",
               "source_contact_intent" => %{
                 "schema_contract" => "contact_intent.v1",
                 "activity_id" => "blocked_source_command"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source contact intent containers become operator review rows" do
    reviewed_intent = %{
      "schema_contract" => "contact_intent.v1",
      "id" => "reviewed_source_downlink",
      "activity_id" => "reviewed_source_downlink",
      "activity_type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "starts_at_s" => 300.0,
      "ends_at_s" => 360.0,
      "approval_status" => "operator_review_required",
      "approval_requirements" => [
        %{
          "schema_contract" => "approval_requirement.v1",
          "action" => "review_contact_intent",
          "requirement_type" => "contact_schedule_change",
          "required_authority" => "contact_schedule_authority",
          "reason" => "reviewed source contact intent requires schedule review"
        }
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "policy_bundle_id" => "command_contact_authority_v1",
        "classification" => "operator_review_required"
      }
    }

    imported_intent = %{
      reviewed_intent
      | "id" => "imported_source_command",
        "activity_id" => "imported_source_command",
        "direction" => "command",
        "approval_status" => "blocked_by_policy"
    }

    wrapper_intent = %{
      reviewed_intent
      | "id" => "wrapped_source_tracking",
        "activity_id" => "wrapped_source_tracking",
        "direction" => "tracking"
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_intent_container_review:001",
      "source_operator_review_package" => OperatorReview.from_contact_intent(reviewed_intent),
      "source_cadence_import_manifest" =>
        imported_intent
        |> OperatorReview.from_contact_intent()
        |> CadenceImport.from_operator_review_package(),
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "contact_intents" => [wrapper_intent]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_intent_container_review:001",
             "review_count" => 3,
             "contact_intent_review_count" => 3
           } = package

    assert [
             %{
               "review_type" => "contact_intent_review",
               "source" =>
                 "candidate_refresh.source_operator_review_package.rows.source_contact_intent[0]",
               "activity_id" => "reviewed_source_downlink",
               "required_operator_action" => "review_contact_intent",
               "source_contact_intent" => %{"activity_id" => "reviewed_source_downlink"}
             },
             %{
               "review_type" => "contact_intent_review",
               "source" =>
                 "candidate_refresh.source_cadence_import_manifest.rows.source_contact_intent[0]",
               "activity_id" => "imported_source_command",
               "required_operator_action" => "review_contact_intent",
               "source_contact_intent" => %{"activity_id" => "imported_source_command"}
             },
             %{
               "review_type" => "contact_intent_review",
               "source" => "candidate_refresh.source_result_artifact.contact_intents[0]",
               "activity_id" => "wrapped_source_tracking",
               "required_operator_action" => "review_contact_intent",
               "source_contact_intent" => %{"activity_id" => "wrapped_source_tracking"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh contact intent summaries become direction-scoped review rows" do
    summary = %{
      "schema_contract" => "contact_intent_summary.v1",
      "model" => "artifact_only_contact_intent_summary",
      "source_artifact_type" => "contact_intent.v1",
      "source" => "operator_review_test.compact_contact_intent_summary",
      "contact_intent_count" => 3,
      "capacity_pack_required_contact_count" => 2,
      "capacity_pack_required_capacity_fraction" => 0.65,
      "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
        "dss_43" => 0.4,
        "equator_prime" => 0.25
      },
      "capacity_pack_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.25,
        "tracking" => 0.4
      },
      "contact_ids_by_ground_station_id" => %{
        "dss_43" => ["intent_nested_capacity", "intent_station_only"],
        "equator_prime" => ["intent_direct_capacity"]
      },
      "contact_ids_by_direction" => %{
        "command" => ["intent_station_only"],
        "downlink" => ["intent_direct_capacity"],
        "tracking" => ["intent_nested_capacity"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "downlink" => ["intent_direct_capacity"],
        "tracking" => ["intent_nested_capacity"]
      },
      "directions" => ["command", "downlink", "tracking"],
      "direction_routing" => %{
        "command" => %{
          "contact_count" => 1,
          "contact_ids" => ["intent_station_only"],
          "capacity_pack_contact_ids" => []
        },
        "downlink" => %{
          "contact_count" => 1,
          "contact_ids" => ["intent_direct_capacity"],
          "capacity_pack_required_capacity_fraction" => 0.25,
          "capacity_pack_contact_ids" => ["intent_direct_capacity"]
        },
        "tracking" => %{
          "contact_count" => 1,
          "contact_ids" => ["intent_nested_capacity"],
          "capacity_pack_required_capacity_fraction" => 0.4,
          "capacity_pack_contact_ids" => ["intent_nested_capacity"]
        }
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation"
      }
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:compact_contact_intent_summary_review",
      "source_contact_intent_summary" => summary
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:compact_contact_intent_summary_review",
             "review_count" => 3,
             "contact_intent_review_count" => 3
           } = package

    assert Enum.map(package["rows"], & &1["direction"]) == ["command", "downlink", "tracking"]

    assert %{
             "source" => "candidate_refresh.source_contact_intent_summary.summary_contacts",
             "activity_id" =>
               "contact_intent_summary:candidate_refresh.source_contact_intent_summary:downlink",
             "contact_id" => "intent_direct_capacity",
             "contact_ids" => ["intent_direct_capacity"],
             "capacity_pack_contact_ids" => ["intent_direct_capacity"],
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "contact_intent_summary.direction_routing",
             "source_summary_model" => "artifact_only_contact_intent_summary",
             "source_summary_schema_contract" => "contact_intent_summary.v1",
             "source_summary_source" => "operator_review_test.compact_contact_intent_summary",
             "source_contact_intent_summary" => %{
               "direction_routing" => %{
                 "downlink" => %{
                   "contact_ids" => ["intent_direct_capacity"],
                   "capacity_pack_contact_ids" => ["intent_direct_capacity"],
                   "capacity_pack_required_capacity_fraction" => 0.25
                 }
               }
             },
             "source_contact_intent" => %{
               "direction" => "downlink",
               "source_contact_intent_summary" => %{
                 "contact_ids_by_direction" => %{
                   "downlink" => ["intent_direct_capacity"]
                 }
               }
             }
           } = Enum.find(package["rows"], &(&1["direction"] == "downlink"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh accepted planning state contact intent summaries become review rows" do
    summary = %{
      "schema_contract" => "contact_intent_summary.v1",
      "model" => "artifact_only_contact_intent_summary",
      "source_artifact_type" => "contact_intent.v1",
      "source" => "operator_review_test.accepted_contact_intent_summary",
      "contact_intent_count" => 2,
      "capacity_pack_required_contact_count" => 1,
      "contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["accepted_downlink_intent"],
        "dss_43" => ["accepted_command_intent"]
      },
      "contact_ids_by_direction" => %{
        "command" => ["accepted_command_intent"],
        "downlink" => ["accepted_downlink_intent"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "downlink" => ["accepted_downlink_intent"]
      },
      "direction_routing" => %{
        "command" => %{
          "contact_count" => 1,
          "contact_ids" => ["accepted_command_intent"],
          "capacity_pack_contact_ids" => []
        },
        "downlink" => %{
          "contact_count" => 1,
          "contact_ids" => ["accepted_downlink_intent"],
          "capacity_pack_required_capacity_fraction" => 0.35,
          "capacity_pack_contact_ids" => ["accepted_downlink_intent"]
        }
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_contact_generation_or_schedule_mutation"
      }
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:accepted_contact_intent_summary_review",
      "accepted_planning_state" => %{
        "source_contact_intent_summary" => summary
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_contact_intent_summary_review",
             "review_count" => 2,
             "contact_intent_review_count" => 2,
             "review_type_counts" => %{"contact_intent_review" => 2}
           } = package

    assert Enum.map(package["rows"], & &1["direction"]) == ["command", "downlink"]

    assert %{
             "source" =>
               "candidate_refresh.accepted_planning_state.source_contact_intent_summary.summary_contacts",
             "activity_id" =>
               "contact_intent_summary:candidate_refresh.accepted_planning_state.source_contact_intent_summary:downlink",
             "contact_id" => "accepted_downlink_intent",
             "contact_ids" => ["accepted_downlink_intent"],
             "capacity_pack_contact_ids" => ["accepted_downlink_intent"],
             "required_capacity_fraction" => 0.35,
             "source_summary_schema_contract" => "contact_intent_summary.v1",
             "source_summary_source" => "operator_review_test.accepted_contact_intent_summary",
             "source_contact_intent_summary" => %{
               "schema_contract" => "contact_intent_summary.v1",
               "source" => "operator_review_test.accepted_contact_intent_summary",
               "direction_routing" => %{
                 "downlink" => %{
                   "contact_ids" => ["accepted_downlink_intent"],
                   "capacity_pack_contact_ids" => ["accepted_downlink_intent"]
                 }
               }
             },
             "source_contact_intent" => %{
               "direction" => "downlink",
               "source_contact_intent_summary" => %{
                 "schema_contract" => "contact_intent_summary.v1"
               }
             }
           } = Enum.find(package["rows"], &(&1["direction"] == "downlink"))

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_contact_intent_summary_review",
             "row_count" => 2,
             "import_action_counts" => %{"review_contact_intent" => 2},
             "source_review_type_counts" => %{"contact_intent_review" => 2}
           } = manifest

    assert %{
             "import_action" => "review_contact_intent",
             "source_review_type" => "contact_intent_review",
             "activity_id" =>
               "contact_intent_summary:candidate_refresh.accepted_planning_state.source_contact_intent_summary:downlink",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_contact_intent_summary.summary_contacts",
               "source_contact_intent_summary" => %{
                 "schema_contract" => "contact_intent_summary.v1"
               }
             }
           } = Enum.find(manifest["rows"], &(&1["direction"] == "downlink"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh mission state contact intent summaries become review rows" do
    summary = %{
      "schema_contract" => "contact_intent_summary.v1",
      "model" => "artifact_only_contact_intent_summary",
      "source_artifact_type" => "contact_intent.v1",
      "source" => "operator_review_test.mission_contact_intent_summary",
      "contact_intent_count" => 1,
      "capacity_pack_required_contact_count" => 1,
      "contact_ids_by_ground_station_id" => %{
        "dss_14" => ["mission_tracking_intent"]
      },
      "contact_ids_by_direction" => %{
        "tracking" => ["mission_tracking_intent"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "tracking" => ["mission_tracking_intent"]
      },
      "direction_routing" => %{
        "tracking" => %{
          "contact_count" => 1,
          "contact_ids" => ["mission_tracking_intent"],
          "capacity_pack_required_capacity_fraction" => 0.55,
          "capacity_pack_contact_ids" => ["mission_tracking_intent"]
        }
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_contact_generation_or_schedule_mutation"
      }
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:mission_contact_intent_summary_review",
      "mission_state" => %{
        "contact_intent_summary" => summary
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:mission_contact_intent_summary_review",
             "review_count" => 1,
             "contact_intent_review_count" => 1,
             "review_type_counts" => %{"contact_intent_review" => 1}
           } = package

    assert [
             %{
               "source" =>
                 "candidate_refresh.mission_state.contact_intent_summary.summary_contacts",
               "activity_id" =>
                 "contact_intent_summary:candidate_refresh.mission_state.contact_intent_summary:tracking",
               "direction" => "tracking",
               "contact_id" => "mission_tracking_intent",
               "contact_ids" => ["mission_tracking_intent"],
               "capacity_pack_contact_ids" => ["mission_tracking_intent"],
               "required_capacity_fraction" => 0.55,
               "source_summary_schema_contract" => "contact_intent_summary.v1",
               "source_summary_source" => "operator_review_test.mission_contact_intent_summary",
               "source_contact_intent_summary" => %{
                 "schema_contract" => "contact_intent_summary.v1",
                 "direction_routing" => %{
                   "tracking" => %{
                     "contact_ids" => ["mission_tracking_intent"],
                     "capacity_pack_contact_ids" => ["mission_tracking_intent"]
                   }
                 }
               }
             }
           ] = package["rows"]

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:mission_contact_intent_summary_review",
             "row_count" => 1,
             "import_action_counts" => %{"review_contact_intent" => 1},
             "source_review_type_counts" => %{"contact_intent_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_contact_intent",
               "source_review_type" => "contact_intent_review",
               "activity_id" =>
                 "contact_intent_summary:candidate_refresh.mission_state.contact_intent_summary:tracking",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.contact_intent_summary.summary_contacts",
                 "source_contact_intent_summary" => %{
                   "schema_contract" => "contact_intent_summary.v1"
                 }
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh result-artifact contact intent summaries become review rows" do
    summary = %{
      "schema_contract" => "contact_intent_summary.v1",
      "model" => "artifact_only_contact_intent_summary",
      "source_artifact_type" => "contact_intent.v1",
      "source" => "operator_review_test.result_contact_intent_summary",
      "contact_intent_count" => 2,
      "capacity_pack_required_contact_count" => 1,
      "contact_ids_by_ground_station_id" => %{
        "dss_43" => ["result_downlink_intent", "result_command_intent"]
      },
      "contact_ids_by_direction" => %{
        "command" => ["result_command_intent"],
        "downlink" => ["result_downlink_intent"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "downlink" => ["result_downlink_intent"]
      },
      "direction_routing" => %{
        "command" => %{
          "contact_count" => 1,
          "contact_ids" => ["result_command_intent"],
          "capacity_pack_contact_ids" => []
        },
        "downlink" => %{
          "contact_count" => 1,
          "contact_ids" => ["result_downlink_intent"],
          "capacity_pack_required_capacity_fraction" => 0.45,
          "capacity_pack_contact_ids" => ["result_downlink_intent"]
        }
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_contact_generation_or_schedule_mutation"
      }
    }

    cases = [
      {%{"source_result_artifact" => [summary]},
       "candidate_refresh.source_result_artifact[0].summary_contacts",
       "candidate_refresh.source_result_artifact_0"},
      {%{
         "result_artifact" => %{
           "schema_contract" => "result_artifact.v1",
           "contact_intent_summary" => summary
         }
       }, "candidate_refresh.result_artifact.contact_intent_summary.summary_contacts",
       "candidate_refresh.result_artifact.contact_intent_summary"}
    ]

    expected_rows = %{
      "command" => %{
        contact_id: "result_command_intent",
        contact_ids: ["result_command_intent"],
        capacity_pack_contact_ids: []
      },
      "downlink" => %{
        contact_id: "result_downlink_intent",
        contact_ids: ["result_downlink_intent"],
        capacity_pack_contact_ids: ["result_downlink_intent"],
        required_capacity_fraction: 0.45
      }
    }

    Enum.each(cases, fn {artifact_fields, source, activity_source} ->
      artifact =
        Map.merge(
          %{
            "schema_contract" => "candidate_refresh.v1",
            "refresh_id" => "candidate_refresh:result_contact_intent_summary_review"
          },
          artifact_fields
        )

      package = OperatorReview.from_candidate_refresh_artifact(artifact)
      manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

      assert %{
               "review_count" => 2,
               "contact_intent_review_count" => 2,
               "review_type_counts" => %{"contact_intent_review" => 2}
             } = package

      assert %{
               "row_count" => 2,
               "import_action_counts" => %{"review_contact_intent" => 2},
               "source_review_type_counts" => %{"contact_intent_review" => 2}
             } = manifest

      package_rows_by_direction = Map.new(package["rows"], &{&1["direction"], &1})
      manifest_rows_by_direction = Map.new(manifest["rows"], &{&1["direction"], &1})

      assert Map.keys(package_rows_by_direction) |> Enum.sort() == ["command", "downlink"]
      assert Map.keys(manifest_rows_by_direction) |> Enum.sort() == ["command", "downlink"]

      Enum.each(expected_rows, fn {direction, expected} ->
        contact_id = expected.contact_id
        contact_ids = expected.contact_ids
        capacity_pack_contact_ids = expected.capacity_pack_contact_ids
        activity_id = "contact_intent_summary:#{activity_source}:#{direction}"

        assert %{
                 "source" => ^source,
                 "activity_id" => ^activity_id,
                 "direction" => ^direction,
                 "contact_id" => ^contact_id,
                 "contact_ids" => ^contact_ids,
                 "capacity_pack_contact_ids" => ^capacity_pack_contact_ids,
                 "required_operator_action" => "review_contact_intent",
                 "source_contact_intent_summary" => %{
                   "schema_contract" => "contact_intent_summary.v1",
                   "direction_routing" => %{
                     ^direction => %{
                       "contact_ids" => ^contact_ids,
                       "capacity_pack_contact_ids" => ^capacity_pack_contact_ids
                     }
                   }
                 },
                 "source_contact_intent" => %{
                   "direction" => ^direction,
                   "source_contact_intent_summary" => %{
                     "schema_contract" => "contact_intent_summary.v1"
                   }
                 }
               } = package_rows_by_direction[direction]

        assert %{
                 "import_action" => "review_contact_intent",
                 "source_review_type" => "contact_intent_review",
                 "activity_id" => ^activity_id,
                 "direction" => ^direction,
                 "contact_id" => ^contact_id,
                 "contact_ids" => ^contact_ids,
                 "capacity_pack_contact_ids" => ^capacity_pack_contact_ids,
                 "source_contact_intent_summary" => %{
                   "schema_contract" => "contact_intent_summary.v1",
                   "direction_routing" => %{
                     ^direction => %{
                       "contact_ids" => ^contact_ids,
                       "capacity_pack_contact_ids" => ^capacity_pack_contact_ids
                     }
                   }
                 },
                 "source_contact_intent" => %{
                   "direction" => ^direction,
                   "source_contact_intent_summary" => %{
                     "schema_contract" => "contact_intent_summary.v1"
                   }
                 },
                 "source_review_row" => %{
                   "source" => ^source,
                   "activity_id" => ^activity_id,
                   "direction" => ^direction,
                   "contact_id" => ^contact_id,
                   "contact_ids" => ^contact_ids,
                   "capacity_pack_contact_ids" => ^capacity_pack_contact_ids,
                   "source_contact_intent_summary" => %{
                     "schema_contract" => "contact_intent_summary.v1",
                     "direction_routing" => %{
                       ^direction => %{
                         "contact_ids" => ^contact_ids,
                         "capacity_pack_contact_ids" => ^capacity_pack_contact_ids
                       }
                     }
                   }
                 }
               } = manifest_rows_by_direction[direction]

        case expected do
          %{required_capacity_fraction: required_capacity_fraction} ->
            assert package_rows_by_direction[direction]["required_capacity_fraction"] ==
                     required_capacity_fraction

            assert manifest_rows_by_direction[direction]["required_capacity_fraction"] ==
                     required_capacity_fraction

            assert manifest_rows_by_direction[direction]["source_review_row"][
                     "required_capacity_fraction"
                   ] == required_capacity_fraction

          _ ->
            refute Map.has_key?(
                     package_rows_by_direction[direction],
                     "required_capacity_fraction"
                   )

            refute Map.has_key?(
                     manifest_rows_by_direction[direction],
                     "required_capacity_fraction"
                   )

            refute Map.has_key?(
                     manifest_rows_by_direction[direction]["source_review_row"],
                     "required_capacity_fraction"
                   )
        end
      end)

      assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
               Schema.validate_artifact(package)

      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end)
  end
end
