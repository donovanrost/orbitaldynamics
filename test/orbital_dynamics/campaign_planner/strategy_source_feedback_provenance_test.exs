Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategySourceFeedbackProvenanceTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives operational feedback from prior operator review source feedback rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [downlink("dl_operator_feedback", 100.0, 160.0)],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "provenance" => %{"trust_boundary" => "operator_review_feedback_archive"},
          "rows" => [
            %{
              "id" => "operator_review:strategy_recommendation:feedback",
              "review_type" => "strategy_recommendation",
              "action" => "review_strategy_recommendation",
              "required_operator_action" => "review_strategy_recommendation",
              "source_operational_feedback" => %{
                "contact_success_rate" => %{"equator_prime" => 0.58}
              },
              "source_operational_feedback_provenance" => %{
                "source_count" => 1,
                "sources" => [
                  %{
                    "source" => "campaign_strategy.operational_feedback",
                    "trust_boundaries" => ["operator_feedback_archive"]
                  }
                ]
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

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.58
           }

    assert %{
             "source" => "prior_plan.operator_review_package.rows.source_operational_feedback",
             "source_report_contract" => "operator_review_package.v1",
             "source_report_row_count" => 1,
             "source_review_type_counts" => %{"strategy_recommendation" => 1},
             "source_review_action_counts" => %{"review_strategy_recommendation" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "operator_feedback_archive",
               "operator_review_feedback_archive"
             ],
             "source_operational_feedback_provenance" => %{"source_count" => 1}
           } =
             Enum.find(
               artifact["operational_feedback_provenance"]["sources"],
               &(&1["source"] ==
                   "prior_plan.operator_review_package.rows.source_operational_feedback")
             )

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.58
           } = List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves malformed prior source feedback as invalid provenance without scoring it" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_malformed_source_feedback", 100.0, 160.0)
          |> Map.put("required_downlink_mb", 120.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "rows" => [
            %{
              "id" => "operator_review:strategy_recommendation:malformed_feedback",
              "review_type" => "strategy_recommendation",
              "action" => "review_strategy_recommendation",
              "required_operator_action" => "review_strategy_recommendation",
              "source_operational_feedback" => %{
                "downlink_demand_mb" => :bad_demand
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "rows" => [
            %{
              "id" => "cadence_import:strategy_branch:malformed_feedback",
              "import_action" => "import_strategy_recommendation",
              "source_review_type" => "strategy_branch_comparison",
              "source_operational_feedback" => :bad_feedback
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{}
    refute branch(artifact, "derived_downlink_demand_feedback")

    operator_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] ==
            "prior_plan.operator_review_package.rows.source_operational_feedback")
      )

    cadence_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] ==
            "prior_plan.cadence_import_manifest.rows.source_operational_feedback")
      )

    assert %{
             "source_report_contract" => "operator_review_package.v1",
             "source_report_row_count" => 1,
             "input_keys" => ["invalid_operational_feedback_input"],
             "invalid_operational_feedback_input" => true,
             "invalid_operational_feedback_input_reason" =>
               "operational_feedback_sections_invalid",
             "source_review_type_counts" => %{"strategy_recommendation" => 1}
           } = operator_source

    assert [
             %{
               "field" => "downlink_demand_mb",
               "reason" => "field_must_be_object",
               "invalid_feedback_shape" => "bad_demand",
               "row_id" => "operator_review:strategy_recommendation:malformed_feedback",
               "review_type" => "strategy_recommendation"
             }
           ] = operator_source["invalid_operational_feedback_sections"]

    assert %{
             "source_report_contract" => "cadence_import_manifest.v1",
             "source_report_row_count" => 1,
             "input_keys" => ["invalid_operational_feedback_input"],
             "invalid_operational_feedback_input" => true,
             "invalid_operational_feedback_input_reason" =>
               "operational_feedback_sections_invalid",
             "source_import_action_counts" => %{"import_strategy_recommendation" => 1},
             "source_review_type_counts" => %{"strategy_branch_comparison" => 1}
           } = cadence_source

    assert [
             %{
               "field" => "source_operational_feedback",
               "reason" => "strategy_operational_feedback_must_be_object",
               "invalid_feedback_shape" => "bad_feedback",
               "row_id" => "cadence_import:strategy_branch:malformed_feedback",
               "source_review_type" => "strategy_branch_comparison"
             }
           ] = cadence_source["invalid_operational_feedback_sections"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves candidate-refresh warning source feedback as invalid provenance" do
    invalid_sections = [
      %{
        "field" => "realized_activities.station.id",
        "key" => "bad station",
        "reason" => "key_must_be_stable_id",
        "row_id" => "realized_bad_station",
        "row_index" => 2
      }
    ]

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_candidate_refresh_warning", 100.0, 160.0)
          |> Map.put("required_downlink_mb", 120.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "candidate_refresh.v1",
          "rows" => [
            %{
              "id" => "operator_review:warning:candidate_refresh_feedback",
              "review_type" => "warning",
              "source" => "candidate_refresh.warnings",
              "action" => "review_warning",
              "required_operator_action" => "review_warning",
              "source_operational_feedback" => %{
                "invalid_feedback_sections" => invalid_sections
              },
              "source_operational_feedback_provenance" => %{
                "invalid_operational_feedback_sections" => invalid_sections
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "rows" => [
            %{
              "id" => "cadence_import:warning:candidate_refresh_feedback",
              "import_action" => "review_warning",
              "source_review_type" => "warning",
              "source_operational_feedback" => %{
                "invalid_feedback_shape" => "feedback_snapshot"
              }
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{}
    refute branch(artifact, "derived_downlink_demand_feedback")

    operator_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] ==
            "prior_plan.operator_review_package.rows.source_operational_feedback")
      )

    cadence_source =
      Enum.find(
        artifact["operational_feedback_provenance"]["sources"],
        &(&1["source"] ==
            "prior_plan.cadence_import_manifest.rows.source_operational_feedback")
      )

    assert %{
             "source_report_contract" => "operator_review_package.v1",
             "source_report_row_count" => 1,
             "input_keys" => ["invalid_operational_feedback_input"],
             "invalid_operational_feedback_input" => true,
             "source_review_type_counts" => %{"warning" => 1}
           } = operator_source

    assert [
             %{
               "field" => "realized_activities.station.id",
               "key" => "bad station",
               "reason" => "key_must_be_stable_id",
               "row_id" => "operator_review:warning:candidate_refresh_feedback",
               "review_type" => "warning",
               "action" => "review_warning"
             }
           ] = operator_source["invalid_operational_feedback_sections"]

    assert %{
             "source_report_contract" => "cadence_import_manifest.v1",
             "source_report_row_count" => 1,
             "input_keys" => ["invalid_operational_feedback_input"],
             "invalid_operational_feedback_input" => true,
             "source_import_action_counts" => %{"review_warning" => 1},
             "source_review_type_counts" => %{"warning" => 1}
           } = cadence_source

    assert [
             %{
               "field" => "source_operational_feedback",
               "reason" => "strategy_operational_feedback_must_be_object",
               "invalid_feedback_shape" => "feedback_snapshot",
               "row_id" => "cadence_import:warning:candidate_refresh_feedback",
               "source_review_type" => "warning",
               "import_action" => "review_warning"
             }
           ] = cadence_source["invalid_operational_feedback_sections"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
