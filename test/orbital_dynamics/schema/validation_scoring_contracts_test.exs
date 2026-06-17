defmodule OrbitalDynamics.Schema.ValidationScoringContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, Epoch, ResultSet, Schema}

  test "builds and validates schema validation report artifacts" do
    artifact = campaign_artifact()

    assert %{
             "schema_contract" => "schema_validation_report.v1",
             "model" => "executable_artifact_contract_validation",
             "validation_mode" => "artifact_map",
             "validated_contract" => "campaign_plan.v1",
             "validated_artifact_family" => "campaign_plan",
             "validated_schema_version" => 1,
             "status" => "pass",
             "model_limits" => [
               "top_level_json_schema_compatibility_export",
               "executable_elixir_validator_is_source_of_truth",
               "semantic_checks_are_not_fully_represented_in_json_schema"
             ],
             "error_count" => 0,
             "warning_count" => 0,
             "errors" => [],
             "warnings" => []
           } = report = Schema.validation_report(artifact)

    assert {:ok, %{"schema_contract" => "schema_validation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, schema_validation_report_schema} =
             Schema.json_schema("schema_validation_report.v1")

    assert get_in(schema_validation_report_schema, ["properties", "model", "const"]) ==
             "executable_artifact_contract_validation"

    failing = Schema.validation_report(Map.delete(artifact, "plan_id"))

    assert %{
             "status" => "fail",
             "error_count" => 1,
             "errors" => [%{"path" => "$.plan_id", "message" => "is required"}],
             "remediation" => [
               %{
                 "path" => "$.plan_id",
                 "category" => "missing_required_field",
                 "action" => "Populate this required field for campaign_plan.v1",
                 "source_message" => "is required"
               }
             ],
             "remediation_count" => 1
           } = failing

    assert {:ok, %{"schema_contract" => "schema_validation_report.v1"}} =
             Schema.validate_artifact(failing)

    type_mismatch = Schema.validation_report(Map.put(artifact, "activities", %{}))

    assert %{
             "status" => "fail",
             "errors" => [%{"path" => "$.activities", "message" => "must be a list"}],
             "remediation" => [
               %{
                 "path" => "$.activities",
                 "category" => "type_mismatch",
                 "source_message" => "must be a list"
               }
             ]
           } = type_mismatch

    assert {:ok, %{"schema_contract" => "schema_validation_report.v1"}} =
             Schema.validate_artifact(type_mismatch)

    constant_mismatch =
      artifact
      |> Map.put("schema_version", 2)
      |> Schema.validation_report(schema_contract: "campaign_plan.v1")

    assert %{
             "status" => "fail",
             "errors" => [%{"path" => "$.schema_version", "message" => "must equal 1"}],
             "remediation" => [
               %{
                 "path" => "$.schema_version",
                 "category" => "constant_mismatch",
                 "source_message" => "must equal 1"
               }
             ]
           } = constant_mismatch

    assert {:ok, %{"schema_contract" => "schema_validation_report.v1"}} =
             Schema.validate_artifact(constant_mismatch)

    unsupported_validation_mode =
      report
      |> Map.put("validation_mode", "surprising")
      |> Schema.validation_report()

    assert %{
             "status" => "fail",
             "errors" => [
               %{"path" => "$.validation_mode", "message" => "must be one of " <> _}
             ],
             "remediation" => [
               %{
                 "path" => "$.validation_mode",
                 "category" => "unsupported_value"
               }
             ]
           } = unsupported_validation_mode

    assert {:ok, %{"schema_contract" => "schema_validation_report.v1"}} =
             Schema.validate_artifact(unsupported_validation_mode)

    unknown_contract = Schema.validation_report(%{"unexpected" => "artifact"})

    assert %{
             "validated_contract" => "unknown",
             "status" => "fail",
             "errors" => [
               %{"path" => "$", "message" => "could not infer schema contract from artifact"}
             ],
             "remediation" => [
               %{
                 "path" => "$",
                 "category" => "contract_inference_failure",
                 "source_message" => "could not infer schema contract from artifact"
               }
             ]
           } = unknown_contract

    assert {:ok, %{"schema_contract" => "schema_validation_report.v1"}} =
             Schema.validate_artifact(unknown_contract)

    unsupported_contract =
      Schema.validation_report(artifact, schema_contract: "future_contract.v1")

    assert %{
             "validated_contract" => "future_contract.v1",
             "status" => "fail",
             "errors" => [
               %{"path" => "$", "message" => "unknown schema contract: future_contract.v1"}
             ],
             "remediation" => [
               %{
                 "path" => "$",
                 "category" => "unsupported_schema_contract",
                 "source_message" => "unknown schema contract: future_contract.v1"
               }
             ]
           } = unsupported_contract

    assert {:ok, %{"schema_contract" => "schema_validation_report.v1"}} =
             Schema.validate_artifact(unsupported_contract)

    stale_status = Map.put(failing, "status", "pass")
    assert {:error, stale_status_report} = Schema.validate_artifact(stale_status)
    assert Enum.any?(stale_status_report["errors"], &(&1["path"] == "$.status"))

    stale_model = Map.put(report, "model", "stale_schema_validation_model")
    assert {:error, stale_model_report} = Schema.validate_artifact(stale_model)
    assert Enum.any?(stale_model_report["errors"], &(&1["path"] == "$.model"))

    invalid_count = Map.put(report, "error_count", 0.5)
    assert {:error, invalid_count_report} = Schema.validate_artifact(invalid_count)
    assert Enum.any?(invalid_count_report["errors"], &(&1["path"] == "$.error_count"))

    stale_limits = Map.put(report, "model_limits", ["stale_schema_validation_boundary"])
    assert {:error, stale_limits_report} = Schema.validate_artifact(stale_limits)
    assert Enum.any?(stale_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    batch = %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "model" => "executable_artifact_contract_batch_validation",
      "model_limits" => Schema.schema_validation_model_limits(),
      "validation_mode" => "artifact_directory",
      "input_dir" => "study_results",
      "file_count" => 1,
      "artifact_count" => 1,
      "skipped_count" => 0,
      "skipped_artifacts" => [],
      "status" => "pass",
      "status_counts" => %{"pass" => 1},
      "error_count" => 0,
      "warning_count" => 0,
      "remediation_count" => 0,
      "reports" => [%{"path" => "study_results/campaign_plan.json", "report" => report}]
    }

    assert {:ok, %{"schema_contract" => "schema_validation_batch_report.v1"}} =
             Schema.validate_artifact(batch)

    invalid_batch = Map.put(batch, "file_count", 1.5)
    assert {:error, invalid_batch_report} = Schema.validate_artifact(invalid_batch)
    assert Enum.any?(invalid_batch_report["errors"], &(&1["path"] == "$.file_count"))

    stale_batch_model = Map.put(batch, "model", "stale_schema_validation_batch_model")
    assert {:error, stale_batch_model_report} = Schema.validate_artifact(stale_batch_model)
    assert Enum.any?(stale_batch_model_report["errors"], &(&1["path"] == "$.model"))
  end

  test "exports nested schema validation issue schemas" do
    assert {:ok, schema} = Schema.json_schema("schema_validation_report.v1")

    error_schema = get_in(schema, ["properties", "errors", "items"])

    assert error_schema["required"] == ["severity", "path", "message"]
    assert get_in(error_schema, ["properties", "severity", "enum"]) == ["error", "warning"]
    assert get_in(error_schema, ["properties", "path", "type"]) == "string"
    assert get_in(error_schema, ["properties", "message", "type"]) == "string"

    assert get_in(schema, ["properties", "warnings", "items"]) == error_schema

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             Schema.schema_validation_model_limits()

    Enum.each(["error_count", "warning_count", "remediation_count"], fn field ->
      assert get_in(schema, ["properties", field, "type"]) == "integer"
      assert get_in(schema, ["properties", field, "minimum"]) == 0
    end)

    remediation_schema = get_in(schema, ["properties", "remediation", "items"])

    assert remediation_schema["required"] == ["path", "category", "action", "source_message"]
    assert get_in(remediation_schema, ["properties", "category", "type"]) == "string"

    assert {:ok, batch_schema} = Schema.json_schema("schema_validation_batch_report.v1")

    assert get_in(batch_schema, ["properties", "input_dir", "type"]) == "string"

    assert get_in(batch_schema, ["properties", "model", "const"]) ==
             "executable_artifact_contract_batch_validation"

    Enum.each(
      [
        "file_count",
        "artifact_count",
        "skipped_count",
        "error_count",
        "warning_count",
        "remediation_count"
      ],
      fn field ->
        assert get_in(batch_schema, ["properties", field, "type"]) == "integer"
        assert get_in(batch_schema, ["properties", field, "minimum"]) == 0
      end
    )

    assert get_in(batch_schema, ["properties", "status_counts", "propertyNames", "enum"]) == [
             "pass",
             "fail"
           ]

    assert get_in(batch_schema, ["properties", "model_limits", "const"]) ==
             Schema.schema_validation_model_limits()

    skipped_schema = get_in(batch_schema, ["properties", "skipped_artifacts", "items"])

    assert skipped_schema["required"] == ["path", "reason"]
    assert get_in(skipped_schema, ["properties", "reason", "type"]) == "string"

    report_entry_schema = get_in(batch_schema, ["properties", "reports", "items"])

    assert report_entry_schema["required"] == ["path", "report"]

    assert get_in(report_entry_schema, [
             "properties",
             "report",
             "properties",
             "model_limits",
             "const"
           ]) == Schema.schema_validation_model_limits()
  end

  test "validates standalone objective tradeoff report contracts" do
    report = %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "model" => "ranked_timeline_score_term_tradeoffs",
      "objective" => "maximize weighted observation value and contact value",
      "ranking_count" => 2,
      "score_term_keys" => ["activity_score", "target_value"],
      "tradeoffs" => [
        %{
          "rank" => 1,
          "scenario_id" => "leo_1",
          "score" => 120.0,
          "score_delta_from_selected" => 0.0,
          "activity_count" => 1,
          "selected_observation_count" => 1,
          "selected_contact_count" => 0,
          "score_terms" => %{"activity_score" => 120.0, "target_value" => 120.0},
          "activity_ids" => ["obs_1"]
        },
        %{
          "rank" => 2,
          "scenario_id" => "leo_2",
          "score" => 80.0,
          "score_delta_from_selected" => -40.0,
          "activity_count" => 1,
          "score_terms" => %{"activity_score" => 80.0, "target_value" => 80.0},
          "activity_ids" => ["obs_2"]
        }
      ],
      "assumptions" => %{"source" => "campaign_plan.ranked_timelines"}
    }

    assert {:ok, %{"schema_contract" => "objective_tradeoff_report.v1"}} =
             Schema.validate_artifact(report)

    invalid = put_in(report, ["tradeoffs", Access.at(1), "activity_ids"], ["bad id"])

    assert {:error, validation_report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.tradeoffs[1].activity_ids[0]")
           )

    invalid_activity_count = put_in(report, ["tradeoffs", Access.at(0), "activity_count"], 1.0)

    assert {:error, activity_count_report} = Schema.validate_artifact(invalid_activity_count)

    assert Enum.any?(
             activity_count_report["errors"],
             &(&1["path"] == "$.tradeoffs[0].activity_count")
           )

    invalid_selected_contact_count =
      put_in(report, ["tradeoffs", Access.at(0), "selected_contact_count"], -1)

    assert {:error, selected_contact_count_report} =
             Schema.validate_artifact(invalid_selected_contact_count)

    assert Enum.any?(
             selected_contact_count_report["errors"],
             &(&1["path"] == "$.tradeoffs[0].selected_contact_count")
           )

    invalid_ranking_count = Map.put(report, "ranking_count", -1)

    assert {:error, ranking_count_report} = Schema.validate_artifact(invalid_ranking_count)
    assert Enum.any?(ranking_count_report["errors"], &(&1["path"] == "$.ranking_count"))
  end

  test "validates standalone ranking comparison report contracts" do
    report = %{
      "schema_contract" => "ranking_comparison_report.v1",
      "model" => "scenario_ranking_pairwise_delta",
      "source" => "optimizer.compare_rankings",
      "objective" => "final_radius_km",
      "objective_direction" => "maximize",
      "left_label" => "grid",
      "right_label" => "monte_carlo",
      "left_count" => 1,
      "right_count" => 1,
      "matched_count" => 1,
      "left_only_count" => 0,
      "right_only_count" => 0,
      "row_count" => 1,
      "winner" => %{
        "left_scenario_id" => "burn_a",
        "right_scenario_id" => "burn_b",
        "changed" => true
      },
      "rows" => [
        %{
          "scenario_id" => "burn_b",
          "status" => "matched",
          "left_rank" => 2,
          "right_rank" => 1,
          "rank_delta" => 1,
          "left_value" => 7005.0,
          "right_value" => 7020.0,
          "value_delta" => 15.0
        }
      ],
      "assumptions" => %{"external_solver" => false}
    }

    assert {:ok, %{"schema_contract" => "ranking_comparison_report.v1"}} =
             Schema.validate_artifact(report)

    invalid = put_in(report, ["rows", Access.at(0), "scenario_id"], "bad id")

    assert {:error, validation_report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].scenario_id")
           )

    invalid_rank = put_in(report, ["rows", Access.at(0), "rank_delta"], 1.5)

    assert {:error, rank_report} = Schema.validate_artifact(invalid_rank)
    assert Enum.any?(rank_report["errors"], &(&1["path"] == "$.rows[0].rank_delta"))

    invalid_left_count_shape = Map.put(report, "left_count", 2.0)

    assert {:error, left_count_shape_report} = Schema.validate_artifact(invalid_left_count_shape)
    assert Enum.any?(left_count_shape_report["errors"], &(&1["path"] == "$.left_count"))
  end

  test "validates standalone score term report contracts" do
    report = %{
      "schema_contract" => "score_term_report.v1",
      "model" => "ranked_timeline_score_terms",
      "source" => "campaign_plan.ranked_timelines",
      "row_count" => 2,
      "score_term_keys" => ["activity_score", "target_value"],
      "rows" => [
        %{
          "id" => "score_term:leo_1:1:activity_score",
          "rank" => 1,
          "scenario_id" => "leo_1",
          "term_key" => "activity_score",
          "value" => 120.0,
          "timeline_score" => 120.0,
          "selected" => true
        },
        %{
          "id" => "score_term:leo_2:2:target_value",
          "rank" => 2,
          "scenario_id" => "leo_2",
          "term_key" => "target_value",
          "value" => 80.0,
          "timeline_score" => 80.0,
          "selected" => false
        }
      ],
      "assumptions" => %{"source" => "campaign_plan.ranked_timelines"}
    }

    assert {:ok, %{"schema_contract" => "score_term_report.v1"}} =
             Schema.validate_artifact(report)

    invalid = put_in(report, ["rows", Access.at(0), "selected"], "yes")

    assert {:error, validation_report} = Schema.validate_artifact(invalid)
    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.rows[0].selected"))

    invalid_row_count = Map.put(report, "row_count", 2.0)

    assert {:error, row_count_report} = Schema.validate_artifact(invalid_row_count)
    assert Enum.any?(row_count_report["errors"], &(&1["path"] == "$.row_count"))
  end

  test "reports contract paths for missing campaign fields" do
    artifact =
      campaign_artifact()
      |> Map.delete("plan_id")
      |> update_in(["proposed_contacts"], fn [contact] -> [Map.delete(contact, "direction")] end)

    assert {:error, report} = Schema.validate_artifact(artifact)

    paths = Enum.map(report["errors"], & &1["path"])

    assert "$.plan_id" in paths
    assert "$.proposed_contacts[0].direction" in paths
  end

  defp campaign_artifact do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          %{
            scenario_id: :leo_1,
            event_type: :ground_station_access,
            events: [
              %{
                type: :ground_station_access,
                starts_at: Epoch.new!(100.0, :tdb),
                ends_at: Epoch.new!(160.0, :tdb),
                metadata: %{
                  max_elevation_deg: 45.0,
                  minimum_elevation_deg: 5.0
                }
              }
            ],
            source: %{ground_station_id: :equator_prime}
          }
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    CampaignPlanner.build(result_set,
      generated_at: ~U[2026-05-14 00:00:00Z],
      campaign: %{
        "planning_horizon" => %{"duration_s" => 600.0},
        "constraints" => %{},
        "scoring_policy" => %{"downlink_rate_mb_s" => 2.0}
      }
    )
  end
end
