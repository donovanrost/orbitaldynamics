Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyReviewImportCommandFeedbackReplayTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives prior result-artifact activity feedback from source row keys" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_source_activity_wrapper", "leo_1", 100.0, 130.0),
          downlink("dl_source_proposed_wrapper", 200.0, 260.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          downlink("dl_source_realized_wrapper", 300.0, 360.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          observe(
            "obs_source_snapshot_wrapper",
            "leo_1",
            "target_source_snapshot",
            400.0,
            460.0,
            8.0
          )
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "source_activity_result_artifact",
          "metadata" => %{"trust_boundary" => "ops_source_activity_artifact"},
          "source_planned_activity" => %{
            "schema_contract" => "planned_activity.v1",
            "id" => "cmd_source_activity_wrapper",
            "type" => "command",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 130.0,
            "ground_station_id" => "equator_prime",
            "direction" => "command",
            "command_success_factor" => 0.3,
            "command_result" => ["accepted", "timed_out"],
            "cadence_import_status" => "missing",
            "planned_protection_decision" => "preserve"
          },
          "source_proposed_contact" => %{
            "schema_contract" => "proposed_contact.v1",
            "id" => "dl_source_proposed_wrapper",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 200.0,
            "ends_at_s" => 260.0,
            "direction" => "downlink",
            "contact_success_factor" => 0.45,
            "actual_throughput_mb" => 35.0,
            "estimated_throughput_mb" => 100.0,
            "cadence_import_status" => "present",
            "planned_protection_decision" => "mutable"
          },
          "source_realized_activity" => %{
            "schema_contract" => "realized_activity.v1",
            "id" => "realized:dl_source_realized_wrapper",
            "planned_activity_id" => "dl_source_realized_wrapper",
            "type" => "downlink",
            "status" => "partial",
            "scenario_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "actual_starts_at_s" => 305.0,
            "actual_ends_at_s" => 355.0,
            "direction" => "downlink",
            "completed_fraction" => 0.2,
            "actual_throughput_mb" => 20.0,
            "estimated_throughput_mb" => 100.0
          },
          "source_realized_state_snapshot" => %{
            "schema_contract" => "realized_state_snapshot.v1",
            "snapshot_id" => "source_snapshot:activity_wrapper",
            "activities" => [
              %{
                "schema_contract" => "realized_activity.v1",
                "id" => "realized:obs_source_snapshot_wrapper",
                "planned_activity_id" => "obs_source_snapshot_wrapper",
                "type" => "observe",
                "status" => "partial",
                "scenario_id" => "leo_1",
                "target_id" => "target_source_snapshot",
                "actual_starts_at_s" => 405.0,
                "actual_ends_at_s" => 455.0,
                "completed_fraction" => 0.5,
                "image_quality_score" => 0.5,
                "image_quality_status" => "usable",
                "image_quality_source" => "source_snapshot_quality"
              }
            ]
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branch =
      branch(artifact, "derived_operational_timeline_feedback_cmd_source_activity_wrapper")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_source_activity_wrapper",
             "command_success_factor" => 0.3,
             "feedback_source" => "prior_plan.source_result_artifact.source_planned_activity",
             "trust_boundary" => "ops_source_activity_artifact"
           } = List.first(command_branch["events"])

    proposed_branch =
      branch(artifact, "derived_operational_timeline_feedback_dl_source_proposed_wrapper")

    assert Enum.any?(
             proposed_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["contact_success_factor"] == 0.45 and
                 &1["feedback_source"] ==
                   "prior_plan.source_result_artifact.source_proposed_contact" and
                 &1["trust_boundary"] == "ops_source_activity_artifact")
           )

    realized_branch = branch(artifact, "derived_realized_feedback_dl_source_realized_wrapper")

    assert Enum.any?(
             realized_branch["events"],
             &(&1["type"] == "contact_success_feedback" and
                 &1["contact_success_factor"] == 0.2 and
                 &1["feedback_source"] ==
                   "prior_plan.source_result_artifact.source_realized_activity" and
                 &1["trust_boundary"] == "ops_source_activity_artifact")
           )

    snapshot_branch = branch(artifact, "derived_realized_feedback_obs_source_snapshot_wrapper")

    assert %{
             "type" => "observation_success_feedback",
             "activity_id" => "obs_source_snapshot_wrapper",
             "target_id" => "target_source_snapshot",
             "observation_success_factor" => 0.5,
             "image_quality_score" => 0.5,
             "image_quality_status" => "usable",
             "image_quality_source" => "source_snapshot_quality",
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_realized_state_snapshot.activities",
             "trust_boundary" => "ops_source_activity_artifact"
           } = List.first(snapshot_branch["events"])

    planned_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "prior_plan.planned_activity")
      )

    assert %{
             "source_report_paths" => [
               "prior_plan.source_result_artifact.source_planned_activity"
             ],
             "source_activity_type_counts" => %{"command" => 1},
             "source_direction_counts" => %{"command" => 1},
             "source_cadence_import_status_counts" => %{"missing" => 1},
             "source_planned_protection_decision_counts" => %{"preserve" => 1},
             "trust_boundaries" => ["ops_source_activity_artifact"]
           } = planned_source

    proposed_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "prior_plan.proposed_contact")
      )

    assert %{
             "source_report_paths" => [
               "prior_plan.source_result_artifact.source_proposed_contact"
             ],
             "source_activity_type_counts" => %{"downlink" => 1},
             "source_direction_counts" => %{"downlink" => 1},
             "source_cadence_import_status_counts" => %{"present" => 1},
             "source_planned_protection_decision_counts" => %{"mutable" => 1},
             "trust_boundaries" => ["ops_source_activity_artifact"]
           } = proposed_source

    realized_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "prior_plan.realized_activity")
      )

    assert %{
             "source_report_paths" => [
               "prior_plan.source_result_artifact.source_realized_activity",
               "prior_plan.source_result_artifact.source_realized_state_snapshot.activities"
             ],
             "source_activity_type_counts" => %{"downlink" => 1, "observe" => 1},
             "source_direction_counts" => %{"downlink" => 1},
             "source_realized_status_counts" => %{"partial" => 2},
             "trust_boundaries" => ["ops_source_activity_artifact"]
           } = realized_source

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy review-gates invalid review and import feedback factors before replay" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_bad_review", "leo_1", 100.0, 130.0),
          command("cmd_bad_import", "leo_1", 140.0, 170.0),
          downlink("dl_bad_review", 180.0, 240.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "review_count" => 2,
          "rows" => [
            %{
              "id" => "operator_review:command_window:cmd_bad_review",
              "review_type" => "command_window_review",
              "activity_id" => "cmd_bad_review",
              "activity_type" => "command",
              "source_command_window" => %{
                "activity_id" => "cmd_bad_review",
                "type" => "command",
                "command_success_factor" => 1.25
              }
            },
            %{
              "id" => "operator_review:realized_feedback:dl_bad_review",
              "review_type" => "realized_feedback",
              "activity_id" => "dl_bad_review",
              "activity_type" => "downlink",
              "feedback_status" => "matched",
              "source_feedback" => %{
                "activity_id" => "dl_bad_review",
                "type" => "downlink",
                "ground_station_id" => "equator_prime",
                "contact_success_factor" => -0.2
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "row_count" => 1,
          "rows" => [
            %{
              "id" => "cadence_import:command_window:cmd_bad_import",
              "import_action" => "review_command_window",
              "source_review_type" => "command_window_review",
              "activity_id" => "cmd_bad_import",
              "activity_type" => "command",
              "source_command_window" => %{
                "activity_id" => "cmd_bad_import",
                "type" => "command",
                "command_success_factor" => "bad"
              }
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "review"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_command_window_feedback_cmd_bad_review")
    refute branch(artifact, "derived_realized_feedback_dl_bad_review")
    refute branch(artifact, "derived_command_window_feedback_cmd_bad_import")

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{}
    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{}

    operator_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "prior_plan.operator_review_package.rows")
      )

    cadence_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] == "prior_plan.cadence_import_manifest.rows.source_review_row")
      )

    assert %{
             "input_keys" => ["invalid_operational_feedback_input"],
             "invalid_operational_feedback_input" => true,
             "invalid_operational_feedback_input_reason" =>
               "operational_feedback_sections_invalid",
             "invalid_operational_feedback_sections" => operator_invalid_sections
           } = operator_source

    assert %{
             "field" => "operator_review.rows.command_success_factor",
             "reason" => "value_must_be_between_0_and_1",
             "invalid_feedback_value" => 1.25,
             "row_id" => "operator_review:command_window:cmd_bad_review",
             "row_index" => 1
           } in operator_invalid_sections

    assert %{
             "field" => "operator_review.rows.contact_success_factor",
             "reason" => "value_must_be_between_0_and_1",
             "invalid_feedback_value" => -0.2,
             "row_id" => "operator_review:realized_feedback:dl_bad_review",
             "row_index" => 2
           } in operator_invalid_sections

    assert %{
             "input_keys" => ["invalid_operational_feedback_input"],
             "invalid_operational_feedback_input" => true,
             "invalid_operational_feedback_input_reason" =>
               "operational_feedback_sections_invalid",
             "invalid_operational_feedback_sections" => cadence_invalid_sections
           } = cadence_source

    assert %{
             "field" => "operator_review.rows.command_success_factor",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => "bad",
             "row_id" => "cadence_import:command_window:cmd_bad_import",
             "row_index" => 1
           } in cadence_invalid_sections

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent review and import command feedback for the same activity identity" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_shared_review", "leo_1", 100.0, 130.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:command_window:cmd_shared_review",
              "review_type" => "command_window_review",
              "activity_id" => "cmd_shared_review",
              "activity_type" => "command",
              "scenario_id" => "leo_1",
              "approval_status" => "operator_review_required",
              "source_command_window" => %{
                "activity_id" => "cmd_shared_review",
                "type" => "command",
                "scenario_id" => "leo_1",
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0,
                "command_success_factor" => 0.25,
                "command_result" => "rejected"
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "row_count" => 1,
          "review_required_count" => 1,
          "provenance" => %{"trust_boundary" => "cadence_review_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:command_window:cmd_shared_review",
              "import_action" => "review_command_window",
              "source_review_type" => "command_window_review",
              "approval_status" => "operator_review_required",
              "source_review_row" => %{
                "review_type" => "command_window_review",
                "activity_id" => "cmd_shared_review",
                "activity_type" => "command",
                "scenario_id" => "leo_1",
                "source_command_window" => %{
                  "activity_id" => "cmd_shared_review",
                  "type" => "command",
                  "scenario_id" => "leo_1",
                  "starts_at_s" => 100.0,
                  "ends_at_s" => 130.0,
                  "command_success_factor" => 0.6,
                  "command_result" => "partial"
                }
              }
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    base_id = "derived_command_window_feedback_cmd_shared_review"
    refute branch(artifact, base_id)

    command_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(command_branches) == 2

    assert MapSet.new(Enum.map(command_branches, & &1["derived_source"])) ==
             MapSet.new([
               "prior_plan.operator_review_package.rows.source_command_window",
               "prior_plan.cadence_import_manifest.rows.source_review_row.source_command_window"
             ])

    assert command_branches
           |> Enum.flat_map(& &1["events"])
           |> Enum.map(& &1["command_success_factor"])
           |> Enum.sort() == [0.25, 0.6]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays list-valued reviewed and imported command feedback from result artifacts" do
    operator_package = %{
      "schema_contract" => "operator_review_package.v1",
      "source_artifact_type" => "campaign_strategy.v3",
      "review_count" => 1,
      "rows" => [
        %{
          "id" => "operator_review:command_window:cmd_wrapped_review",
          "review_type" => "command_window_review",
          "activity_id" => "cmd_wrapped_review",
          "activity_type" => "command",
          "scenario_id" => "leo_1",
          "source_command_window" => %{
            "activity_id" => "cmd_wrapped_review",
            "type" => "command",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 130.0,
            "command_success_factor" => 0.3,
            "command_result" => "partial"
          }
        }
      ]
    }

    source_operator_package =
      put_in(operator_package, ["rows", Access.at(0), "activity_id"], "cmd_wrapped_source_review")
      |> put_in(
        ["rows", Access.at(0), "id"],
        "operator_review:command_window:cmd_wrapped_source_review"
      )
      |> put_in(
        ["rows", Access.at(0), "source_command_window", "activity_id"],
        "cmd_wrapped_source_review"
      )
      |> put_in(["rows", Access.at(0), "source_command_window", "command_success_factor"], 0.4)

    import_manifest = %{
      "schema_contract" => "cadence_import_manifest.v1",
      "source_artifact_type" => "operator_review_package.v1",
      "row_count" => 1,
      "rows" => [
        %{
          "id" => "cadence_import:command_window:cmd_wrapped_import",
          "import_action" => "review_command_window",
          "source_review_type" => "command_window_review",
          "approval_status" => "operator_review_required",
          "source_review_row" => %{
            "review_type" => "command_window_review",
            "activity_id" => "cmd_wrapped_import",
            "activity_type" => "command",
            "scenario_id" => "leo_1",
            "source_command_window" => %{
              "activity_id" => "cmd_wrapped_import",
              "type" => "command",
              "scenario_id" => "leo_1",
              "starts_at_s" => 140.0,
              "ends_at_s" => 170.0,
              "command_success_factor" => 0.6,
              "command_result" => "partial"
            }
          }
        }
      ]
    }

    source_import_manifest =
      put_in(
        import_manifest,
        ["rows", Access.at(0), "id"],
        "cadence_import:command_window:cmd_wrapped_source_import"
      )
      |> put_in(
        ["rows", Access.at(0), "source_review_row", "activity_id"],
        "cmd_wrapped_source_import"
      )
      |> put_in(
        ["rows", Access.at(0), "source_review_row", "source_command_window", "activity_id"],
        "cmd_wrapped_source_import"
      )
      |> put_in(
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_command_window",
          "command_success_factor"
        ],
        0.7
      )

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_wrapped_review", "leo_1", 100.0, 130.0),
          command("cmd_wrapped_source_review", "leo_1", 110.0, 140.0),
          command("cmd_wrapped_import", "leo_1", 140.0, 170.0),
          command("cmd_wrapped_source_import", "leo_1", 150.0, 180.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "source_operator_review_package" => [source_operator_package],
          "operator_review_package" => [operator_package],
          "source_cadence_import_manifest" => [source_import_manifest],
          "cadence_import_manifest" => [import_manifest],
          "provenance" => %{"trust_boundary" => "ops_prior_wrapper"}
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branches =
      artifact["branches"]
      |> Enum.filter(&String.starts_with?(&1["branch_id"], "derived_command_window_feedback_"))

    assert MapSet.new(Enum.map(command_branches, & &1["derived_source"])) ==
             MapSet.new([
               "prior_plan.source_result_artifact.source_operator_review_package[0].rows.source_command_window",
               "prior_plan.source_result_artifact.operator_review_package[0].rows.source_command_window",
               "prior_plan.source_result_artifact.source_cadence_import_manifest[0].rows.source_review_row.source_command_window",
               "prior_plan.source_result_artifact.cadence_import_manifest[0].rows.source_review_row.source_command_window"
             ])

    assert command_branches
           |> Enum.flat_map(& &1["events"])
           |> Enum.map(& &1["trust_boundary"])
           |> Enum.uniq() == ["ops_prior_wrapper"]

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_wrapped_import" => 0.6,
             "cmd_wrapped_review" => 0.3,
             "cmd_wrapped_source_import" => 0.7,
             "cmd_wrapped_source_review" => 0.4
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays direct list-valued reviewed and imported command feedback" do
    operator_package = %{
      "schema_contract" => "operator_review_package.v1",
      "source_artifact_type" => "campaign_strategy.v3",
      "review_count" => 1,
      "provenance" => %{"trust_boundary" => "ops_review_list"},
      "rows" => [
        %{
          "id" => "operator_review:command_window:cmd_direct_review_list",
          "review_type" => "command_window_review",
          "activity_id" => "cmd_direct_review_list",
          "activity_type" => "command",
          "scenario_id" => "leo_1",
          "source_command_window" => %{
            "activity_id" => "cmd_direct_review_list",
            "type" => "command",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 130.0,
            "command_success_factor" => 0.25,
            "command_result" => "partial"
          }
        }
      ]
    }

    import_manifest = %{
      "schema_contract" => "cadence_import_manifest.v1",
      "source_artifact_type" => "operator_review_package.v1",
      "row_count" => 1,
      "provenance" => %{"trust_boundary" => "ops_import_list"},
      "rows" => [
        %{
          "id" => "cadence_import:command_window:cmd_direct_import_list",
          "import_action" => "review_command_window",
          "source_review_type" => "command_window_review",
          "approval_status" => "operator_review_required",
          "source_review_row" => %{
            "review_type" => "command_window_review",
            "activity_id" => "cmd_direct_import_list",
            "activity_type" => "command",
            "scenario_id" => "leo_1",
            "source_command_window" => %{
              "activity_id" => "cmd_direct_import_list",
              "type" => "command",
              "scenario_id" => "leo_1",
              "starts_at_s" => 140.0,
              "ends_at_s" => 170.0,
              "command_success_factor" => 0.65,
              "command_result" => "partial"
            }
          }
        }
      ]
    }

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_direct_review_list", "leo_1", 100.0, 130.0),
          command("cmd_direct_import_list", "leo_1", 140.0, 170.0)
        ],
        "operator_review_package" => [operator_package],
        "cadence_import_manifest" => [import_manifest]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branches =
      artifact["branches"]
      |> Enum.filter(&String.starts_with?(&1["branch_id"], "derived_command_window_feedback_"))

    assert MapSet.new(Enum.map(command_branches, & &1["derived_source"])) ==
             MapSet.new([
               "prior_plan.operator_review_package[0].rows.source_command_window",
               "prior_plan.cadence_import_manifest[0].rows.source_review_row.source_command_window"
             ])

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_direct_import_list" => 0.65,
             "cmd_direct_review_list" => 0.25
           }

    assert Enum.any?(
             artifact["operational_feedback_provenance"]["sources"],
             &(&1["source"] == "prior_plan.operator_review_package.rows" and
                 &1["source_report_contract"] == "operator_review_package.v1" and
                 &1["source_report_paths"] == ["prior_plan.operator_review_package[0].rows"] and
                 &1["trust_boundaries"] == ["ops_review_list"])
           )

    assert Enum.any?(
             artifact["operational_feedback_provenance"]["sources"],
             &(&1["source"] ==
                 "prior_plan.cadence_import_manifest.rows.source_review_row" and
                 &1["source_report_contract"] == "cadence_import_manifest.v1" and
                 &1["source_report_paths"] == [
                   "prior_plan.cadence_import_manifest[0].rows.source_review_row"
                 ] and
                 &1["trust_boundaries"] == ["ops_import_list"])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy traces direct list-valued replayed operational feedback rows" do
    operator_package = %{
      "schema_contract" => "operator_review_package.v1",
      "source_artifact_type" => "campaign_strategy.v3",
      "review_count" => 1,
      "provenance" => %{"trust_boundary" => "ops_source_feedback_review_list"},
      "rows" => [
        %{
          "id" => "operator_review:strategy_recommendation:cmd_source_review_list",
          "review_type" => "strategy_recommendation",
          "action" => "review_strategy_recommendation",
          "required_operator_action" => "review_strategy_recommendation",
          "source_operational_feedback" => %{
            "command_success_rate" => %{"cmd_source_review_list" => 0.4}
          },
          "source_operational_feedback_provenance" => %{
            "source_count" => 1,
            "sources" => [
              %{
                "source" => "campaign_strategy.operational_feedback",
                "trust_boundary" => "ops_source_feedback_review_archive"
              }
            ]
          }
        }
      ]
    }

    import_manifest = %{
      "schema_contract" => "cadence_import_manifest.v1",
      "source_artifact_type" => "operator_review_package.v1",
      "row_count" => 1,
      "provenance" => %{"trust_boundary" => "ops_source_feedback_import_list"},
      "rows" => [
        %{
          "id" => "cadence_import:strategy_recommendation:cmd_source_import_list",
          "import_action" => "review_strategy_recommendation",
          "source_review_type" => "strategy_recommendation",
          "approval_status" => "operator_review_required",
          "source_review_row" => %{
            "id" => "operator_review:strategy_recommendation:cmd_source_import_list",
            "review_type" => "strategy_recommendation",
            "source_operational_feedback" => %{
              "command_success_rate" => %{"cmd_source_import_list" => 0.6}
            },
            "source_operational_feedback_provenance" => %{
              "source_count" => 1,
              "sources" => [
                %{
                  "source" => "operator_review.source_operational_feedback",
                  "trust_boundary" => "ops_source_feedback_import_archive"
                }
              ]
            }
          }
        }
      ]
    }

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_source_review_list", "leo_1", 100.0, 130.0),
          command("cmd_source_import_list", "leo_1", 140.0, 170.0)
        ],
        "operator_review_package" => [operator_package],
        "cadence_import_manifest" => [import_manifest]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_source_import_list" => 0.6,
             "cmd_source_review_list" => 0.4
           }

    assert %{
             "source_report_contract" => "operator_review_package.v1",
             "source_report_count" => 1,
             "source_report_paths" => ["prior_plan.operator_review_package[0].rows"],
             "source_report_row_count" => 1,
             "source_review_type_counts" => %{"strategy_recommendation" => 1},
             "source_review_action_counts" => %{"review_strategy_recommendation" => 1},
             "trust_boundaries" => [
               "ops_source_feedback_review_archive",
               "ops_source_feedback_review_list"
             ],
             "source_operational_feedback_provenance" => %{"source_count" => 1}
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "prior_plan.operator_review_package.rows.source_operational_feedback")
             )

    assert %{
             "source_report_contract" => "cadence_import_manifest.v1",
             "source_report_count" => 1,
             "source_report_paths" => [
               "prior_plan.cadence_import_manifest[0].rows.source_review_row"
             ],
             "source_report_row_count" => 1,
             "source_import_action_counts" => %{"review_strategy_recommendation" => 1},
             "source_review_type_counts" => %{"strategy_recommendation" => 1},
             "trust_boundaries" => [
               "ops_source_feedback_import_archive",
               "ops_source_feedback_import_list"
             ],
             "source_operational_feedback_provenance" => %{"source_count" => 1}
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "prior_plan.cadence_import_manifest.rows.source_operational_feedback")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays mission-state list-valued reviewed and imported command feedback" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_state_source_review_list", "leo_1", 80.0, 110.0),
          command("cmd_state_review_list", "leo_1", 100.0, 130.0),
          command("cmd_state_source_import_list", "leo_1", 120.0, 150.0),
          command("cmd_state_import_list", "leo_1", 140.0, 170.0)
        ]
      })

    operator_package = %{
      "schema_contract" => "operator_review_package.v1",
      "source_artifact_type" => "campaign_strategy.v3",
      "review_count" => 1,
      "provenance" => %{"trust_boundary" => "live_ops_review_list"},
      "rows" => [
        %{
          "id" => "operator_review:command_window:cmd_state_review_list",
          "review_type" => "command_window_review",
          "activity_id" => "cmd_state_review_list",
          "activity_type" => "command",
          "scenario_id" => "leo_1",
          "source_command_window" => %{
            "activity_id" => "cmd_state_review_list",
            "type" => "command",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 130.0,
            "command_success_factor" => 0.35,
            "command_result" => "partial"
          }
        }
      ]
    }

    source_operator_package =
      operator_package
      |> put_in(["provenance", "trust_boundary"], "live_source_ops_review_list")
      |> put_in(
        ["rows", Access.at(0), "id"],
        "operator_review:command_window:cmd_state_source_review_list"
      )
      |> put_in(["rows", Access.at(0), "activity_id"], "cmd_state_source_review_list")
      |> put_in(
        ["rows", Access.at(0), "source_command_window", "activity_id"],
        "cmd_state_source_review_list"
      )
      |> put_in(["rows", Access.at(0), "source_command_window", "starts_at_s"], 80.0)
      |> put_in(["rows", Access.at(0), "source_command_window", "ends_at_s"], 110.0)
      |> put_in(["rows", Access.at(0), "source_command_window", "command_success_factor"], 0.15)

    import_manifest = %{
      "schema_contract" => "cadence_import_manifest.v1",
      "source_artifact_type" => "operator_review_package.v1",
      "row_count" => 1,
      "provenance" => %{"trust_boundary" => "live_import_list"},
      "rows" => [
        %{
          "id" => "cadence_import:command_window:cmd_state_import_list",
          "import_action" => "review_command_window",
          "source_review_type" => "command_window_review",
          "approval_status" => "operator_review_required",
          "source_review_row" => %{
            "review_type" => "command_window_review",
            "activity_id" => "cmd_state_import_list",
            "activity_type" => "command",
            "scenario_id" => "leo_1",
            "source_command_window" => %{
              "activity_id" => "cmd_state_import_list",
              "type" => "command",
              "scenario_id" => "leo_1",
              "starts_at_s" => 140.0,
              "ends_at_s" => 170.0,
              "command_success_factor" => 0.75,
              "command_result" => "partial"
            }
          }
        }
      ]
    }

    source_import_manifest =
      import_manifest
      |> put_in(["provenance", "trust_boundary"], "live_source_import_list")
      |> put_in(
        ["rows", Access.at(0), "id"],
        "cadence_import:command_window:cmd_state_source_import_list"
      )
      |> put_in(
        ["rows", Access.at(0), "source_review_row", "activity_id"],
        "cmd_state_source_import_list"
      )
      |> put_in(
        ["rows", Access.at(0), "source_review_row", "source_command_window", "activity_id"],
        "cmd_state_source_import_list"
      )
      |> put_in(
        ["rows", Access.at(0), "source_review_row", "source_command_window", "starts_at_s"],
        120.0
      )
      |> put_in(
        ["rows", Access.at(0), "source_review_row", "source_command_window", "ends_at_s"],
        150.0
      )
      |> put_in(
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_command_window",
          "command_success_factor"
        ],
        0.55
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_operator_review_package, [source_operator_package])
      |> Map.put(:operator_review_package, [operator_package])
      |> Map.put(:source_cadence_import_manifest, [source_import_manifest])
      |> Map.put(:cadence_import_manifest, [import_manifest])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branches =
      artifact["branches"]
      |> Enum.filter(&String.starts_with?(&1["branch_id"], "derived_command_window_feedback_"))

    assert MapSet.new(Enum.map(command_branches, & &1["derived_source"])) ==
             MapSet.new([
               "mission_state.source_operator_review_package[0].rows.source_command_window",
               "mission_state.operator_review_package[0].rows.source_command_window",
               "mission_state.source_cadence_import_manifest[0].rows.source_review_row.source_command_window",
               "mission_state.cadence_import_manifest[0].rows.source_review_row.source_command_window"
             ])

    candidate_source =
      command_branches
      |> List.first()
      |> get_in(["assumptions", "candidate_source"])

    for source_path <- [
          "mission_state.source_operator_review_package",
          "mission_state.operator_review_package",
          "mission_state.source_cadence_import_manifest",
          "mission_state.cadence_import_manifest"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    command_window_paths =
      get_in(candidate_source, [
        "candidate_refresh_request_source_report_summary",
        "source_reports",
        "command_window_report",
        "paths"
      ])

    for source_path <- [
          "mission_state.source_operator_review_package.rows.source_command_window",
          "mission_state.operator_review_package.rows.source_command_window",
          "mission_state.source_cadence_import_manifest.rows.source_command_window",
          "mission_state.cadence_import_manifest.rows.source_command_window"
        ] do
      assert source_path in command_window_paths
    end

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_state_import_list" => 0.75,
             "cmd_state_review_list" => 0.35,
             "cmd_state_source_import_list" => 0.55,
             "cmd_state_source_review_list" => 0.15
           }

    assert %{
             "source_report_contract" => "operator_review_package.v1",
             "source_report_paths" => [
               "mission_state.operator_review_package[0].rows",
               "mission_state.source_operator_review_package[0].rows"
             ],
             "trust_boundaries" => ["live_ops_review_list", "live_source_ops_review_list"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] == "mission_state.operator_review_package.rows")
             )

    assert %{
             "source_report_contract" => "cadence_import_manifest.v1",
             "source_report_paths" => [
               "mission_state.cadence_import_manifest[0].rows.source_review_row",
               "mission_state.source_cadence_import_manifest[0].rows.source_review_row"
             ],
             "trust_boundaries" => ["live_import_list", "live_source_import_list"]
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "mission_state.cadence_import_manifest.rows.source_review_row")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays mission-state review and import command feedback handoffs" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_live_review", "leo_1", 100.0, 130.0)
        ]
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:operator_review_package, %{
        "schema_contract" => "operator_review_package.v1",
        "source_artifact_type" => "campaign_strategy.v3",
        "review_count" => 1,
        "provenance" => %{"trust_boundary" => "live_ops_review_queue"},
        "rows" => [
          %{
            "id" => "operator_review:command_window:cmd_live_review",
            "review_type" => "command_window_review",
            "activity_id" => "cmd_live_review",
            "activity_type" => "command",
            "scenario_id" => "leo_1",
            "approval_status" => "operator_review_required",
            "source_command_window" => %{
              "activity_id" => "cmd_live_review",
              "type" => "command",
              "scenario_id" => "leo_1",
              "starts_at_s" => 100.0,
              "ends_at_s" => 130.0,
              "command_success_factor" => 0.2,
              "command_result" => "rejected"
            }
          }
        ]
      })
      |> Map.put(:cadence_import_manifest, %{
        "schema_contract" => "cadence_import_manifest.v1",
        "source_artifact_type" => "operator_review_package.v1",
        "row_count" => 1,
        "review_required_count" => 1,
        "provenance" => %{"trust_boundary" => "live_cadence_import_queue"},
        "rows" => [
          %{
            "id" => "cadence_import:command_window:cmd_live_review",
            "import_action" => "review_command_window",
            "source_review_type" => "command_window_review",
            "approval_status" => "operator_review_required",
            "source_review_row" => %{
              "review_type" => "command_window_review",
              "activity_id" => "cmd_live_review",
              "activity_type" => "command",
              "scenario_id" => "leo_1",
              "source_command_window" => %{
                "activity_id" => "cmd_live_review",
                "type" => "command",
                "scenario_id" => "leo_1",
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0,
                "command_success_factor" => 0.55,
                "command_result" => "partial"
              }
            }
          }
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    base_id = "derived_command_window_feedback_cmd_live_review"
    refute branch(artifact, base_id)

    command_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(command_branches) == 2

    assert MapSet.new(Enum.map(command_branches, & &1["derived_source"])) ==
             MapSet.new([
               "mission_state.operator_review_package.rows.source_command_window",
               "mission_state.cadence_import_manifest.rows.source_review_row.source_command_window"
             ])

    assert command_branches
           |> Enum.flat_map(& &1["events"])
           |> Enum.map(& &1["command_success_factor"])
           |> Enum.sort() == [0.2, 0.55]

    assert get_in(artifact, ["operational_feedback", "command_success_rate", "cmd_live_review"]) ==
             0.2

    assert Enum.any?(
             artifact["operational_feedback_provenance"]["sources"],
             &(&1["source"] == "mission_state.operator_review_package.rows" and
                 &1["source_report_contract"] == "operator_review_package.v1" and
                 &1["trust_boundaries"] == ["live_ops_review_queue"])
           )

    assert Enum.any?(
             artifact["operational_feedback_provenance"]["sources"],
             &(&1["source"] == "mission_state.cadence_import_manifest.rows.source_review_row" and
                 &1["source_report_contract"] == "cadence_import_manifest.v1" and
                 &1["trust_boundaries"] == ["live_cadence_import_queue"])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp command(id, scenario_id, starts_at_s, ends_at_s) do
    %{
      "id" => id,
      "type" => "command",
      "scenario_id" => scenario_id,
      "direction" => "uplink",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => 1.0
    }
  end
end
