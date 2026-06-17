Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategySchemaValidationSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state schema-validation reports into branch refresh requests" do
    schema_validation_report = fn prefix,
                                  status,
                                  contract,
                                  mode,
                                  error_count,
                                  warning_count,
                                  remediation ->
      %{
        "schema_contract" => "schema_validation_report.v1",
        "validation_mode" => mode,
        "validated_contract" => contract,
        "status" => status,
        "error_count" => error_count,
        "warning_count" => warning_count,
        "remediation_count" => length(remediation),
        "remediation" => remediation,
        "provenance" => %{"trust_boundary" => "#{prefix}_schema_validation_boundary"}
      }
    end

    direct_report =
      schema_validation_report.(
        "direct",
        "fail",
        "candidate_refresh.v1",
        "artifact",
        2,
        1,
        [
          %{
            "path" => "$.candidate_activities[0].id",
            "category" => "missing_required_field",
            "action" => "populate id"
          },
          %{
            "path" => "$.candidate_activities[0].type",
            "category" => "missing_required_field",
            "action" => "populate type"
          }
        ]
      )

    canonical_report =
      schema_validation_report.(
        "canonical",
        "warning",
        "operator_review_package.v1",
        "artifact",
        0,
        1,
        [
          %{
            "path" => "$.operator_review.rows[0].source",
            "category" => "canonical_schema_warning",
            "action" => "review canonical schema warning"
          }
        ]
      )

    source_wrapped_report =
      schema_validation_report.(
        "source_wrapped",
        "warning",
        "campaign_plan.v1",
        "artifact_file",
        0,
        1,
        [
          %{
            "path" => "$.warnings[0]",
            "category" => "schema_warning",
            "action" => "review warning"
          }
        ]
      )

    result_wrapped_report =
      schema_validation_report.(
        "result_wrapped",
        "pass",
        "campaign_strategy.v3",
        "artifact",
        0,
        0,
        []
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_schema_validation_report", direct_report)
      |> Map.put("schema_validation_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "schema_validation_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_schema_validation_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_schema_validation_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_schema_validation_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    for source_path <- [
          "mission_state.source_schema_validation_report",
          "mission_state.schema_validation_report",
          "mission_state.source_result_artifact.schema_validation_report",
          "mission_state.result_artifact.source_schema_validation_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_schema_validation_status_counts" => %{
               "fail" => 1,
               "pass" => 1,
               "warning" => 2
             },
             "source_report_schema_validation_validated_contract_counts" => %{
               "campaign_plan.v1" => 1,
               "campaign_strategy.v3" => 1,
               "candidate_refresh.v1" => 1,
               "operator_review_package.v1" => 1
             },
             "source_report_schema_validation_mode_counts" => %{
               "artifact" => 3,
               "artifact_file" => 1
             },
             "source_report_schema_validation_error_count" => 2,
             "source_report_schema_validation_warning_count" => 3,
             "source_report_schema_validation_remediation_count" => 4,
             "source_report_schema_validation_remediation_action_counts" => %{
               "populate_id" => 1,
               "populate_type" => 1,
               "review_canonical_schema_warning" => 1,
               "review_warning" => 1
             },
             "source_report_schema_validation_remediation_category_counts" => %{
               "canonical_schema_warning" => 1,
               "missing_required_field" => 2,
               "schema_warning" => 1
             },
             "source_report_schema_validation_remediation_path_counts" => %{
               "$.candidate_activities[0].id" => 1,
               "$.candidate_activities[0].type" => 1,
               "$.operator_review.rows[0].source" => 1,
               "$.warnings[0]" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "schema_validation_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "status_counts" => %{"fail" => 1, "pass" => 1, "warning" => 2},
             "validated_contract_counts" => %{
               "campaign_plan.v1" => 1,
               "campaign_strategy.v3" => 1,
               "candidate_refresh.v1" => 1,
               "operator_review_package.v1" => 1
             },
             "validation_mode_counts" => %{"artifact" => 3, "artifact_file" => 1},
             "error_count" => 2,
             "warning_count" => 3,
             "remediation_count" => 4,
             "remediation_action_counts" => %{
               "populate_id" => 1,
               "populate_type" => 1,
               "review_canonical_schema_warning" => 1,
               "review_warning" => 1
             },
             "remediation_category_counts" => %{
               "canonical_schema_warning" => 1,
               "missing_required_field" => 2,
               "schema_warning" => 1
             },
             "remediation_path_counts" => %{
               "$.candidate_activities[0].id" => 1,
               "$.candidate_activities[0].type" => 1,
               "$.operator_review.rows[0].source" => 1,
               "$.warnings[0]" => 1
             },
             "trust_boundary_status" => "declared",
             "branch_local_validation_pressure" => true,
             "branch_local_schema_error_pressure" => true,
             "branch_local_schema_warning_pressure" => true,
             "branch_local_remediation_pressure" => true
           } = CandidateRefresh.schema_validation_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.result_artifact.source_schema_validation_report",
             "mission_state.schema_validation_report",
             "mission_state.source_result_artifact.schema_validation_report",
             "mission_state.source_schema_validation_report"
           ]

    schema_validation_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "schema_validation_pressure" and
            &1["feedback_source"] == "candidate_source.schema_validation_replay_summary")
      )

    assert schema_validation_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "schema_validation_pressure" and
                 &1["feedback_scope"] == "schema_validation" and
                 &1["severity"] == "high" and
                 &1["source_report_count"] == 4 and
                 &1["source_report_row_count"] == 4 and
                 &1["source_report_paths"] == replay_source_paths and
                 &1["status_counts"] == %{"fail" => 1, "pass" => 1, "warning" => 2} and
                 &1["validated_contract_counts"] == %{
                   "campaign_plan.v1" => 1,
                   "campaign_strategy.v3" => 1,
                   "candidate_refresh.v1" => 1,
                   "operator_review_package.v1" => 1
                 } and
                 &1["validation_mode_counts"] == %{"artifact" => 3, "artifact_file" => 1} and
                 &1["error_count"] == 2 and
                 &1["warning_count"] == 3 and
                 &1["remediation_count"] == 4 and
                 &1["remediation_action_counts"] == %{
                   "populate_id" => 1,
                   "populate_type" => 1,
                   "review_canonical_schema_warning" => 1,
                   "review_warning" => 1
                 } and
                 &1["remediation_category_counts"] == %{
                   "canonical_schema_warning" => 1,
                   "missing_required_field" => 2,
                   "schema_warning" => 1
                 } and
                 &1["remediation_path_counts"] == %{
                   "$.candidate_activities[0].id" => 1,
                   "$.candidate_activities[0].type" => 1,
                   "$.operator_review.rows[0].source" => 1,
                   "$.warnings[0]" => 1
                 } and
                 &1["issue_severity"] == "error" and
                 &1["branch_local_validation_pressure"] == true and
                 &1["branch_local_schema_error_pressure"] == true and
                 &1["branch_local_schema_warning_pressure"] == true and
                 &1["branch_local_remediation_pressure"] == true)
           )

    assert_validation_refresh_pressure_score_terms(urgent, artifact, "schema_validation")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy challenge scores schema-validation replay from evidence when top-level status is stale" do
    stale_report = %{
      "schema_contract" => "schema_validation_report.v1",
      "validation_mode" => "artifact",
      "validated_contract" => "candidate_refresh.v1",
      "status" => "pass",
      "error_count" => 2,
      "warning_count" => 1,
      "remediation_count" => 2,
      "errors" => [
        %{
          "severity" => "error",
          "path" => "$.candidate_activities[0].id",
          "message" => "candidate activity id is required"
        },
        %{
          "severity" => "error",
          "path" => "$.candidate_activities[0].type",
          "message" => "candidate activity type is required"
        }
      ],
      "warnings" => [
        %{
          "severity" => "warning",
          "path" => "$.metadata.generated_by",
          "message" => "generated_by metadata should be reviewed"
        }
      ],
      "remediation" => [
        %{
          "path" => "$.candidate_activities[0].id",
          "category" => "missing_required_field",
          "action" => "populate candidate activity id"
        },
        %{
          "path" => "$.candidate_activities[0].type",
          "category" => "missing_required_field",
          "action" => "populate candidate activity type"
        }
      ],
      "provenance" => %{"trust_boundary" => "stale_schema_validation_boundary"}
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_schema_validation_report, stale_report),
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    assert %{
             "status_counts" => %{"pass" => 1},
             "validated_contract_counts" => %{"candidate_refresh.v1" => 1},
             "validation_mode_counts" => %{"artifact" => 1},
             "error_count" => 2,
             "warning_count" => 1,
             "remediation_count" => 2,
             "remediation_action_counts" => %{
               "populate_candidate_activity_id" => 1,
               "populate_candidate_activity_type" => 1
             },
             "remediation_category_counts" => %{"missing_required_field" => 2},
             "remediation_path_counts" => %{
               "$.candidate_activities[0].id" => 1,
               "$.candidate_activities[0].type" => 1
             },
             "branch_local_validation_pressure" => true,
             "branch_local_schema_error_pressure" => true,
             "branch_local_schema_warning_pressure" => true,
             "branch_local_remediation_pressure" => true
           } = CandidateRefresh.schema_validation_replay_summary(candidate_source)

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "schema_validation_pressure" and
                 &1["feedback_source"] ==
                   "candidate_source.schema_validation_replay_summary" and
                 &1["severity"] == "high" and
                 &1["validation_status"] == "fail" and
                 &1["validation_statuses"] == ["fail", "pass", "warning"] and
                 &1["status_counts"] == %{"pass" => 1} and
                 &1["validated_contract"] == "candidate_refresh.v1" and
                 &1["validation_mode"] == "artifact" and
                 &1["issue_severity"] == "error" and
                 &1["error_count"] == 2 and
                 &1["warning_count"] == 1 and
                 &1["remediation_count"] == 2 and
                 &1["remediation_action"] == "populate_candidate_activity_id" and
                 &1["remediation_category"] == "missing_required_field" and
                 &1["branch_local_validation_pressure"] == true and
                 &1["branch_local_schema_error_pressure"] == true and
                 &1["branch_local_schema_warning_pressure"] == true and
                 &1["branch_local_remediation_pressure"] == true)
           )

    assert_validation_refresh_pressure_score_terms(urgent, artifact, "schema_validation")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state schema validation batch reports into branch refresh requests" do
    schema_validation_batch_report = fn prefix, status, issue_field, issue_severity ->
      issue_path = "$.#{prefix}_candidate_refresh.#{issue_field}"

      report =
        %{
          "schema_contract" => "schema_validation_report.v1",
          "validation_mode" => "artifact_file",
          "validated_contract" => "candidate_refresh.v1",
          "validated_artifact_family" => "candidate_refresh",
          "status" => status,
          "error_count" => if(issue_severity == "error", do: 1, else: 0),
          "warning_count" => if(issue_severity == "warning", do: 1, else: 0),
          "errors" =>
            if(issue_severity == "error",
              do: [
                %{
                  "severity" => "error",
                  "path" => issue_path,
                  "message" => "#{prefix} candidate refresh is missing #{issue_field}"
                }
              ],
              else: []
            ),
          "warnings" =>
            if(issue_severity == "warning",
              do: [
                %{
                  "severity" => "warning",
                  "path" => issue_path,
                  "message" => "#{prefix} candidate refresh should review #{issue_field}"
                }
              ],
              else: []
            ),
          "remediation_count" => 1,
          "remediation" => [
            %{
              "path" => issue_path,
              "category" => "schema_validation_#{issue_severity}",
              "action" => "#{prefix} schema validation remediation"
            }
          ]
        }

      %{
        "schema_contract" => "schema_validation_batch_report.v1",
        "validation_mode" => "artifact_directory",
        "status" => status,
        "reports" => [
          %{
            "path" => "study_results/#{prefix}_candidate_refresh.json",
            "report" => report
          }
        ],
        "provenance" => %{"trust_boundary" => "#{prefix}_schema_batch_boundary"}
      }
    end

    direct_batch =
      schema_validation_batch_report.("direct", "fail", "candidate_activities", "error")

    canonical_batch =
      schema_validation_batch_report.("canonical", "warning", "model_assumptions", "warning")

    wrapped_batch =
      schema_validation_batch_report.("wrapped", "warning", "model_assumptions", "warning")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_schema_validation_batch_report", direct_batch)
      |> Map.put("schema_validation_batch_report", canonical_batch)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "schema_validation_batch_report" => Map.delete(wrapped_batch, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_schema_batch_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    source_report_input_paths = candidate_source["source_report_input_paths"]

    for source_path <- [
          "mission_state.source_schema_validation_batch_report",
          "mission_state.schema_validation_batch_report",
          "mission_state.source_result_artifact.schema_validation_batch_report"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    direct_report_path =
      "mission_state.source_schema_validation_batch_report.reports[0].report"

    canonical_report_path =
      "mission_state.schema_validation_batch_report.reports[0].report"

    wrapped_report_path =
      "mission_state.source_result_artifact.schema_validation_batch_report.reports[0].report"

    assert direct_report_path in source_report_input_paths
    assert canonical_report_path in source_report_input_paths
    assert wrapped_report_path in source_report_input_paths

    assert %{
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_schema_validation_status_counts" => %{
               "fail" => 1,
               "warning" => 2
             },
             "source_report_schema_validation_validated_contract_counts" => %{
               "candidate_refresh.v1" => 3
             },
             "source_report_schema_validation_error_count" => 1,
             "source_report_schema_validation_warning_count" => 2,
             "source_report_schema_validation_remediation_count" => 3,
             "source_reports" => %{
               "schema_validation_report" => %{
                 "count" => 3,
                 "row_count" => 3,
                 "status_counts" => %{"fail" => 1, "warning" => 2},
                 "validated_contract_counts" => %{"candidate_refresh.v1" => 3},
                 "validation_mode_counts" => %{"artifact_file" => 3},
                 "error_count" => 1,
                 "warning_count" => 2,
                 "remediation_count" => 3,
                 "remediation_action_counts" => %{
                   "canonical_schema_validation_remediation" => 1,
                   "direct_schema_validation_remediation" => 1,
                   "wrapped_schema_validation_remediation" => 1
                 },
                 "remediation_category_counts" => %{
                   "schema_validation_error" => 1,
                   "schema_validation_warning" => 2
                 },
                 "remediation_path_counts" => %{
                   "$.canonical_candidate_refresh.model_assumptions" => 1,
                   "$.direct_candidate_refresh.candidate_activities" => 1,
                   "$.wrapped_candidate_refresh.model_assumptions" => 1
                 },
                 "trust_boundary_status" => "declared"
               }
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "schema_validation_report.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => schema_validation_source_paths,
             "status_counts" => %{"fail" => 1, "warning" => 2},
             "validated_contract_counts" => %{"candidate_refresh.v1" => 3},
             "validation_mode_counts" => %{"artifact_file" => 3},
             "error_count" => 1,
             "warning_count" => 2,
             "remediation_count" => 3,
             "remediation_action_counts" => %{
               "canonical_schema_validation_remediation" => 1,
               "direct_schema_validation_remediation" => 1,
               "wrapped_schema_validation_remediation" => 1
             },
             "remediation_category_counts" => %{
               "schema_validation_error" => 1,
               "schema_validation_warning" => 2
             },
             "remediation_path_counts" => %{
               "$.canonical_candidate_refresh.model_assumptions" => 1,
               "$.direct_candidate_refresh.candidate_activities" => 1,
               "$.wrapped_candidate_refresh.model_assumptions" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => schema_validation_trust_boundaries,
             "branch_local_validation_pressure" => true,
             "branch_local_schema_error_pressure" => true,
             "branch_local_schema_warning_pressure" => true,
             "branch_local_remediation_pressure" => true,
             "assumptions" => %{
               "operator_authority" => "not_granted_by_schema_validation_replay_summary",
               "import_approval" => "not_granted_by_schema_validation_replay_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.schema_validation_replay_summary(candidate_source)

    assert Enum.sort(schema_validation_source_paths) ==
             Enum.sort([canonical_report_path, direct_report_path, wrapped_report_path])

    assert Enum.sort(schema_validation_trust_boundaries) == [
             "canonical_schema_batch_boundary",
             "direct_schema_batch_boundary",
             "wrapped_schema_batch_boundary"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_validation_refresh_pressure_score_terms(branch, artifact, feedback_scope) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    source_report_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &validation_refresh_source_report_pressure?(&1, feedback_scope)
      )

    scoped_pressure_count =
      Enum.count(branch["risk_indicators"], &(&1["feedback_scope"] == feedback_scope))

    scored_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &validation_refresh_scored_pressure?(&1, feedback_scope)
      )

    blended_validation_refresh_pressure_count =
      Enum.count(branch["risk_indicators"], &validation_refresh_pressure?/1)

    validation_refresh_family_pressure_count =
      Enum.count(branch["risk_indicators"], &validation_refresh_family_pressure?/1)

    pressure_term =
      if feedback_scope == "schema_validation" and scored_pressure_count == 0 and
           source_report_pressure_count > 0 do
        "validation_refresh_pressure_penalty"
      else
        validation_refresh_pressure_term(feedback_scope)
      end

    validation_refresh_pressure_count =
      if pressure_term == "validation_refresh_pressure_penalty" do
        blended_validation_refresh_pressure_count
      else
        scored_pressure_count
      end

    requested_validation_refresh_pressure_count =
      source_report_pressure_count + scoped_pressure_count

    assert requested_validation_refresh_pressure_count > 0
    assert validation_refresh_pressure_count > 0

    assert branch["score_terms"][pressure_term] ==
             -validation_refresh_pressure_count * risk_weight

    assert branch["score_terms"]["validation_refresh_pressure_penalty"] ==
             -blended_validation_refresh_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - validation_refresh_family_pressure_count) *
               risk_weight

    assert pressure_term in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == pressure_term and
                 &1["value"] < 0.0)
           )
  end

  defp validation_refresh_pressure_term("model_acceptance"),
    do: "model_acceptance_pressure_penalty"

  defp validation_refresh_pressure_term("validation_safety_case"),
    do: "validation_safety_case_pressure_penalty"

  defp validation_refresh_pressure_term("schema_validation"),
    do: "schema_validation_pressure_penalty"

  defp validation_refresh_pressure_term("refresh_budget"),
    do: "refresh_budget_pressure_penalty"

  defp validation_refresh_pressure_term("refresh_freshness"),
    do: "refresh_freshness_pressure_penalty"

  defp validation_refresh_pressure_term(_feedback_scope),
    do: "validation_refresh_pressure_penalty"

  defp validation_refresh_scored_pressure?(risk, "model_acceptance"),
    do:
      risk["feedback_scope"] == "model_acceptance" or risk["type"] == "model_acceptance_pressure"

  defp validation_refresh_scored_pressure?(risk, "validation_safety_case"),
    do:
      risk["feedback_scope"] == "validation_safety_case" or
        risk["type"] == "validation_safety_case_pressure"

  defp validation_refresh_scored_pressure?(risk, "schema_validation"),
    do:
      risk["feedback_scope"] == "schema_validation" or
        risk["type"] == "schema_validation_pressure"

  defp validation_refresh_scored_pressure?(risk, "refresh_budget"),
    do: risk["feedback_scope"] == "refresh_budget" or risk["type"] == "refresh_budget_pressure"

  defp validation_refresh_scored_pressure?(risk, "refresh_freshness"),
    do:
      risk["feedback_scope"] == "refresh_freshness" or
        risk["type"] == "refresh_freshness_pressure"

  defp validation_refresh_scored_pressure?(risk, _feedback_scope),
    do: validation_refresh_pressure?(risk)

  defp validation_refresh_family_pressure?(risk) do
    validation_refresh_pressure?(risk) or
      validation_refresh_scored_pressure?(risk, "model_acceptance") or
      validation_refresh_scored_pressure?(risk, "validation_safety_case") or
      validation_refresh_scored_pressure?(risk, "schema_validation") or
      validation_refresh_scored_pressure?(risk, "refresh_budget") or
      validation_refresh_scored_pressure?(risk, "refresh_freshness")
  end

  defp validation_refresh_pressure?(risk) do
    validation_refresh_source_report_pressure?(risk, "schema_validation")
  end

  defp validation_refresh_source_report_pressure?(risk, "schema_validation"),
    do: schema_validation_source_report_pressure?(risk)

  defp validation_refresh_source_report_pressure?(_risk, _feedback_scope), do: false

  defp schema_validation_source_report_pressure?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["schema_validation_import_blocked"] == true or
      is_map(risk["schema_validation_status_counts"]) or
      risk["failed_schema_validation_quality_gate_row_ids"] not in [nil, []]
  end

  defp schema_validation_source_report_pressure?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["schema_validation_import_blocked"] == true or
      risk["schema_validation_row_count"] not in [nil, 0] or
      risk["schema_validation_fail_count"] not in [nil, 0] or
      risk["schema_validation_error_count"] not in [nil, 0] or
      risk["schema_validation_warning_count"] not in [nil, 0] or
      risk["schema_validation_remediation_count"] not in [nil, 0] or
      is_map(risk["schema_validation_status_counts"]) or
      risk["failed_schema_validation_quality_gate_row_ids"] not in [nil, []]
  end

  defp schema_validation_source_report_pressure?(_risk), do: false
end
