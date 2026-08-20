Code.require_file("../campaign_planner/local_search_support.exs", __DIR__)

defmodule OrbitalDynamics.OperatorReview.CampaignArtifactTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}
  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.CampaignPlanner.LocalSearchSupport, as: LocalSearchSupport

  test "builds campaign review package from contact contention recommendations" do
    artifact = %{
      "schema_version" => 1,
      "plan_id" => "campaign_plan:test",
      "contact_contention_resolution_report" => %{
        "recommendations" => [
          %{
            "group_id" => "station:equator_prime:contention:1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 100.0,
            "ends_at_s" => 200.0,
            "selected_contact_id" => "dl_1",
            "deferred_contact_ids" => ["dl_2"],
            "action" => "recommend_preferred_contact_for_operator_review",
            "review_status" => "operator_review_required"
          }
        ]
      },
      "warnings" => [],
      "provenance" => %{"source" => "campaign_test"}
    }

    package = OperatorReview.from_campaign_artifact(artifact)

    assert OrbitalDynamics.operator_review_package(artifact) == package

    assert %{
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => "campaign_plan:test",
             "review_count" => 1,
             "contention_recommendation_count" => 1,
             "review_type_counts" => %{"contact_contention_recommendation" => 1},
             "approval_status_counts" => %{"operator_review_required" => 1},
             "required_operator_action_counts" => %{
               "recommend_preferred_contact_for_operator_review" => 1
             },
             "model_limits" => model_limits
           } = package

    expected_model_limits =
      OperatorReview.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert model_limits == expected_model_limits

    assert "no_schedule_mutation" in model_limits
    assert "no_command_execution" in model_limits

    assert {:ok, schema} = Schema.json_schema("operator_review_package.v1")

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             expected_model_limits

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             expected_model_limits

    assert %{
             "review_type" => "contact_contention_recommendation",
             "ground_station_id" => "equator_prime",
             "selected_contact_id" => "dl_1",
             "deferred_contact_ids" => ["dl_2"],
             "required_operator_action" => "recommend_preferred_contact_for_operator_review"
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package = Map.put(package, "review_type_counts", %{"contact_contention_review" => 1})

    assert {:error, validation_report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_type_counts")
           )

    invalid_scalar_count = Map.put(package, "contention_recommendation_count", 0)

    assert {:error, scalar_count_report} = Schema.validate_artifact(invalid_scalar_count)

    assert Enum.any?(
             scalar_count_report["errors"],
             &(&1["path"] == "$.contention_recommendation_count" and
                 &1["message"] == "must equal 1")
           )

    stale_model_limits = Map.put(package, "model_limits", ["no_schedule_mutation"])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match operator review package model limits")
           )
  end

  test "campaign review package lifts embedded operational timeline review rows" do
    artifact = %{
      "schema_version" => 1,
      "plan_id" => "campaign_plan:timeline_review",
      "operational_timeline_report" => %{
        "schema_contract" => "operational_timeline_report.v1",
        "rows" => [
          %{
            "id" => "timeline_row:1:cmd_1",
            "activity_id" => "cmd_1",
            "timeline_id" => "timeline:cmd_1",
            "scenario_id" => "leo_1",
            "activity_type" => "command",
            "operational_kind" => "command",
            "direction" => "command",
            "ground_station_id" => "dss_14",
            "starts_at_s" => 10.0,
            "ends_at_s" => 20.0,
            "status" => "planned",
            "approval_status" => "pending",
            "locked" => false,
            "required_operator_action" => "review_command_contact",
            "operator_action_reason" => "command_boundary_requires_review",
            "approval_requirements" => [
              %{
                "activity_id" => "cmd_1",
                "activity_type" => "command",
                "action" => "review_command_contact",
                "requirement_type" => "command_review"
              }
            ],
            "approval_rule_matches" => [
              %{
                "rule_id" => "command_health_review",
                "classification" => "operator_review_required"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "classification" => "operator_review_required",
              "policy_bundle_id" => "contact_command_review_v1",
              "escalations" => [
                %{"rule_id" => "unmatched_command_rule", "escalation_queue" => "ignore_queue"},
                %{
                  "rule_id" => "command_health_review",
                  "required_authority" => "command_authority",
                  "escalation_level" => "flight_director",
                  "escalation_queue" => "command_review",
                  "escalation_role" => "command_authorizer",
                  "sla_s" => 300
                }
              ]
            },
            "execution_boundary" => "planned_not_commanded",
            "cadence_import_status" => "present",
            "has_cadence_import" => true,
            "has_source_window" => false,
            "timeline_identity" => %{
              "timeline_id" => "timeline:cmd_1",
              "activity_id" => "cmd_1",
              "activity_type" => "command",
              "scenario_id" => "leo_1"
            }
          }
        ]
      },
      "warnings" => [],
      "provenance" => %{"source" => "campaign_test"}
    }

    package = OperatorReview.from_campaign_artifact(artifact)

    assert %{
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => "campaign_plan:timeline_review",
             "review_count" => 1,
             "operational_timeline_count" => 1
           } = package

    assert %{
             "review_type" => "operational_timeline_review",
             "source" => "operational_timeline_report.rows",
             "activity_id" => "cmd_1",
             "timeline_id" => "timeline:cmd_1",
             "required_operator_action" => "review_command_contact",
             "approval_status" => "operator_review_required",
             "source_approval_status" => "pending",
             "requirement_type" => "command_review",
             "required_authority" => "command_authority",
             "policy_bundle_id" => "contact_command_review_v1",
             "rule_id" => "command_health_review",
             "escalation_level" => "flight_director",
             "escalation_queue" => "command_review",
             "escalation_role" => "command_authorizer",
             "sla_s" => 300,
             "source_policy_escalation" => %{
               "rule_id" => "command_health_review",
               "escalation_queue" => "command_review"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "campaign review package lifts one exact local-search trace row" do
    plan =
      CampaignPlanner.build_with_local_search(
        LocalSearchSupport.result_set(),
        campaign: LocalSearchSupport.campaign(),
        generated_at: LocalSearchSupport.generated_at(),
        local_search: LocalSearchSupport.local_search()
      )

    trace = plan["optimizer_search_trace"]
    package = plan["operator_review_package"]

    assert [row] =
             Enum.filter(package["rows"], &(&1["review_type"] == "local_search_review"))

    assert row["source_optimizer_search_trace"] == trace
    assert row["subject_id"] == plan["plan_id"]
    assert row["plan_id"] == plan["plan_id"]
    assert row["selection_contract"] == "v1_outer_local_search_inner_greedy"
    assert row["base_scoring_policy"] == trace["base_scoring_policy"]
    assert row["selected_scoring_policy"] == trace["selected_scoring_policy"]
    assert row["selected_alternative_id"] == trace["selected_alternative_id"]
    assert row["selected_timeline_scenario_id"] == trace["selected_timeline_scenario_id"]
    assert row["selected_timeline_score"] == trace["selected_timeline_score"]
    assert row["selected_activity_ids"] == trace["selected_activity_ids"]
    assert row["selected_activity_count"] == trace["selected_activity_count"]
    assert row["required_operator_action"] == "review_local_search"
    assert {:ok, _report} = Schema.validate_artifact(package)
  end
end
