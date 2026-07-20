Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyReadinessRowContextPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives import readiness pressure from row-status map before stale top-level arrays" do
    quality_gate_report = %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "artifact_only_operational_quality_gate_report",
      "report_id" => "quality_gate:stale_import",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "stale_import_payload",
      "source_readiness_report_id" => "operational_readiness:stale_import",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 1,
      "passed_gate_count" => 0,
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gate_status_counts" => %{"review_required" => 1},
      "gate_classification_counts" => %{"review_only" => 1},
      "rows" => [
        %{
          "id" => "quality_gate:stale:cadence_import:review",
          "rank" => 1,
          "gate_id" => "cadence_import",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "stale import readiness requires review",
          "ready_for_import_count" => 0,
          "manifest_review_required_count" => 1,
          "blocked_import_count" => 0,
          "missing_import_count" => 0,
          "invalid_cadence_import_count" => 0,
          "current_freshness_count" => 0,
          "stale_freshness_count" => 0,
          "unknown_freshness_count" => 1,
          "freshness_status_counts" => %{"unknown" => 1},
          "import_status_counts" => %{"review_required_before_import" => 1},
          "cadence_import_status_counts" => %{"present" => 1}
        }
      ],
      "assumptions" => %{"source" => "test.quality_gate_report"},
      "model_limits" => ["artifact_only"]
    }

    stale_summary =
      quality_gate_report
      |> OrbitalDynamics.OperationalReadiness.quality_gate_import_readiness_summary()
      |> Map.merge(%{
        "review_required_quality_gate_row_ids" => [],
        "blocked_quality_gate_row_ids" => ["quality_gate:stale:cadence_import:blocked"],
        "blocked_import_quality_gate_row_ids" => [
          "quality_gate:stale:cadence_import:blocked"
        ],
        "stale_or_unknown_freshness_quality_gate_row_ids" => [
          "quality_gate:stale:cadence_import:review"
        ],
        "import_preparation_quality_gate_row_ids" => [
          "quality_gate:stale:cadence_import:review"
        ],
        "import_blocked" => true,
        "freshness_review_required" => true,
        "import_preparation_required" => true,
        "provenance" => %{"trust_boundary" => "stale_import_summary_boundary"}
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_operational_quality_gate_import_readiness_summary", stale_summary)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    stale_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "stale_import_payload")
          )
      end)

    assert stale_branch

    assert %{
             "type" => "quality_gate_pressure",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "stale_import_payload",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "quality_gate_status" => "review_required",
             "review_gate_count" => 1,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "gate_status" => "review_required",
             "gate_classification" => "review_only",
             "gate_reason" => "import readiness summary requires review",
             "freshness_review_required" => true,
             "import_preparation_required" => true,
             "import_blocked" => false,
             "stale_or_unknown_freshness_quality_gate_row_ids" => [
               "quality_gate:stale:cadence_import:review"
             ],
             "import_preparation_quality_gate_row_ids" => [
               "quality_gate:stale:cadence_import:review"
             ],
             "blocked_import_quality_gate_row_ids" => [],
             "feedback_source" =>
               "mission_state.source_operational_quality_gate_import_readiness_summary",
             "trust_boundary" => "stale_import_summary_boundary",
             "source_quality_gate_row" => %{
               "review_required_quality_gate_row_ids" => [
                 "quality_gate:stale:cadence_import:review"
               ],
               "blocked_quality_gate_row_ids" => [],
               "blocked_import_quality_gate_row_ids" => []
             }
           } = List.first(stale_branch["events"])

    refute Enum.any?(
             stale_branch["risk_indicators"],
             &(&1["type"] == "quality_gate_pressure" and &1["import_blocked"] == true)
           )

    assert Enum.any?(
             stale_branch["risk_indicators"],
             &(&1["type"] == "quality_gate_pressure" and
                 &1["import_blocked"] == false and
                 &1["blocked_import_quality_gate_row_ids"] == [] and
                 &1["freshness_review_required"] == true)
           )

    assert_import_readiness_pressure_score_terms(stale_branch, artifact)

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == stale_branch["branch_id"]))

    assert "quality_gate_pressure" in comparison_row["risk_types"]

    assert comparison_row["branch_feedback_sources"] == [
             "mission_state.source_operational_quality_gate_import_readiness_summary"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives prior-plan readiness and quality gates as branch pressure" do
    readiness_report = fn prefix, classification, status, trust_boundary ->
      %{
        "schema_contract" => "operational_readiness_report.v1",
        "schema_version" => 1,
        "model" => "artifact_only_operational_readiness_classifier",
        "report_id" => "operational_readiness:planned_activity.v1:#{prefix}",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "#{prefix}_activity",
        "readiness_level" =>
          case classification do
            "blocked" -> "blocked"
            "analysis_only" -> "analysis_only"
            "review_only" -> "operator_review"
          end,
        "import_classification" => classification,
        "status" => status,
        "gate_count" => 1,
        "passed_gate_count" => 0,
        "review_gate_count" => if(status == "review_required", do: 1, else: 0),
        "analysis_gate_count" => if(status == "analysis_only", do: 1, else: 0),
        "blocked_gate_count" => if(status == "blocked", do: 1, else: 0),
        "gates" => [
          %{
            "id" => "operator_training",
            "status" => status,
            "classification" => classification,
            "reason" => "#{prefix} operator training requires review",
            "operator_training_requirement_count" => 1,
            "operator_training_requirement_counts" => %{"training" => 1},
            "required_training_ids" => ["#{prefix}_training"]
          }
        ],
        "evidence" => %{},
        "assumptions" => %{"execution_boundary" => "artifact_only_no_cadence_write"},
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => trust_boundary}
      }
    end

    quality_gate_report = fn prefix, classification, status, trust_boundary ->
      passive_quality_gate_report()
      |> Map.merge(%{
        "report_id" => "quality_gate:resource_projection_report.v1:#{prefix}",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "#{prefix}_resource_projection",
        "source_readiness_report_id" =>
          "operational_readiness:resource_projection_report.v1:#{prefix}",
        "readiness_level" =>
          case classification do
            "blocked" -> "blocked"
            "analysis_only" -> "analysis_only"
            "review_only" -> "operator_review"
          end,
        "import_classification" => classification,
        "status" => status,
        "gate_count" => 1,
        "passed_gate_count" => 0,
        "review_gate_count" => if(status == "review_required", do: 1, else: 0),
        "analysis_gate_count" => if(status == "analysis_only", do: 1, else: 0),
        "blocked_gate_count" => if(status == "blocked", do: 1, else: 0),
        "provenance" => %{"trust_boundary" => trust_boundary},
        "rows" => [
          %{
            "id" => "quality_gate:#{prefix}:resource_availability:1",
            "rank" => 1,
            "gate_id" => "resource_availability",
            "status" => status,
            "classification" => classification,
            "reason" => "#{prefix} resource availability requires review",
            "resource_availability_pressure_count" => 1,
            "resource_availability_reason_counts" => %{"payload_unavailable" => 1},
            "resource_availability_reason_ids" => ["payload_unavailable"],
            "unavailable_resource_reason_ids" => ["payload_unavailable"]
          }
        ]
      })
    end

    direct_readiness =
      readiness_report.(
        "prior_direct",
        "review_only",
        "review_required",
        "prior_plan_readiness_boundary"
      )

    wrapped_readiness =
      readiness_report.(
        "prior_wrapped",
        "analysis_only",
        "analysis_only",
        "wrapped_readiness_boundary"
      )

    direct_quality_gate =
      quality_gate_report.(
        "prior_direct",
        "blocked",
        "blocked",
        "prior_plan_quality_boundary"
      )

    wrapped_quality_gate =
      quality_gate_report.(
        "prior_wrapped",
        "review_only",
        "review_required",
        "wrapped_quality_boundary"
      )

    prior_plan =
      base_plan(%{})
      |> Map.put("source_operational_readiness_report", direct_readiness)
      |> Map.put("quality_gate_report", direct_quality_gate)
      |> Map.put("result_artifact", %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "prior_plan_readiness_quality_wrapper",
        "source_operational_readiness_report" => Map.delete(wrapped_readiness, "provenance"),
        "source_quality_gate_report" => Map.delete(wrapped_quality_gate, "provenance"),
        "provenance" => %{"trust_boundary" => "prior_plan_result_artifact_boundary"}
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_readiness_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_operational_readiness_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "operational_readiness_pressure" and
                &1["source_artifact_id"] == "prior_direct_activity" and
                &1["feedback_source"] == "prior_plan.source_operational_readiness_report.gates")
          )
      end)

    wrapped_readiness_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_operational_readiness_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "operational_readiness_pressure" and
                &1["source_artifact_id"] == "prior_wrapped_activity" and
                &1["feedback_source"] ==
                  "prior_plan.result_artifact.source_operational_readiness_report.gates")
          )
      end)

    direct_quality_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "prior_direct_resource_projection")
          )
      end)

    wrapped_quality_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "prior_wrapped_resource_projection")
          )
      end)

    assert direct_readiness_branch
    assert wrapped_readiness_branch
    assert direct_quality_branch
    assert wrapped_quality_branch

    assert %{
             "type" => "operational_readiness_pressure",
             "readiness_gate_id" => "operator_training",
             "readiness_gate_status" => "review_required",
             "feedback_source" => "prior_plan.source_operational_readiness_report.gates",
             "trust_boundary" => "prior_plan_readiness_boundary",
             "required_training_ids" => ["prior_direct_training"]
           } = List.first(direct_readiness_branch["events"])

    assert %{
             "type" => "operational_readiness_pressure",
             "readiness_gate_status" => "analysis_only",
             "feedback_source" =>
               "prior_plan.result_artifact.source_operational_readiness_report.gates",
             "trust_boundary" => "prior_plan_result_artifact_boundary"
           } = List.first(wrapped_readiness_branch["events"])

    assert %{
             "type" => "quality_gate_pressure",
             "gate_id" => "resource_availability",
             "gate_status" => "blocked",
             "feedback_source" => "prior_plan.quality_gate_report.rows",
             "trust_boundary" => "prior_plan_quality_boundary",
             "resource_availability_reason_counts" => %{"payload_unavailable" => 1}
           } = List.first(direct_quality_branch["events"])

    assert %{
             "type" => "quality_gate_pressure",
             "gate_id" => "resource_availability",
             "gate_status" => "review_required",
             "feedback_source" => "prior_plan.result_artifact.source_quality_gate_report.rows",
             "trust_boundary" => "prior_plan_result_artifact_boundary"
           } = List.first(wrapped_quality_branch["events"])

    direct_quality_pressure_count =
      Enum.count(
        direct_quality_branch["risk_indicators"],
        &(&1["type"] == "quality_gate_pressure")
      )

    wrapped_quality_pressure_count =
      Enum.count(
        wrapped_quality_branch["risk_indicators"],
        &(&1["type"] == "quality_gate_pressure")
      )

    assert direct_quality_pressure_count == 1
    assert wrapped_quality_pressure_count == 1

    assert_operator_training_pressure_score_terms(direct_readiness_branch, artifact)
    assert_operator_training_pressure_score_terms(wrapped_readiness_branch, artifact)
    assert_resource_availability_pressure_score_terms(direct_quality_branch, artifact)
    assert_resource_availability_pressure_score_terms(wrapped_quality_branch, artifact)

    comparison_rows =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.filter(
        &(Map.get(&1, "branch_id") in [
            direct_readiness_branch["branch_id"],
            wrapped_readiness_branch["branch_id"],
            direct_quality_branch["branch_id"],
            wrapped_quality_branch["branch_id"]
          ])
      )

    assert Enum.any?(
             comparison_rows,
             &("operational_readiness_pressure" in &1["risk_types"])
           )

    assert Enum.any?(comparison_rows, &("quality_gate_pressure" in &1["risk_types"]))

    assert "prior_plan.source_operational_readiness_report" in get_in(
             direct_readiness_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert "prior_plan.quality_gate_report" in get_in(
             direct_quality_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves operator-training readiness gate context in branch events" do
    readiness_report =
      %{
        "schema_contract" => "operational_readiness_report.v1",
        "schema_version" => 1,
        "model" => "artifact_only_operational_readiness_classifier",
        "report_id" => "operational_readiness:planned_activity.v1:live_ops",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "live_ops",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
        "gate_count" => 1,
        "passed_gate_count" => 0,
        "review_gate_count" => 1,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "gates" => [
          %{
            "id" => "operator_training",
            "status" => "review_required",
            "classification" => "review_only",
            "reason" => "operator training requires role-qualified review",
            "operator_training_requirement_count" => 5,
            "operator_training_requirement_counts" => %{
              "operator_role" => 2,
              "training" => 1,
              "certification" => 1,
              "qualification" => 1
            },
            "required_operator_roles" => ["contact_operator", "mission_director"],
            "required_training_ids" => ["contact_replan_drill"],
            "required_certification_ids" => ["cadence_import_cert"],
            "required_qualification_ids" => ["sat_ops_current"]
          }
        ],
        "evidence" => %{},
        "assumptions" => ["artifact_only"],
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => "mission_state_operational_readiness_report"}
      }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_operational_readiness_report, readiness_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    readiness_branch =
      branch(artifact, "derived_operational_readiness_pressure_operator_training")

    assert %{
             "type" => "operational_readiness_pressure",
             "readiness_gate_id" => "operator_training",
             "operator_training_requirement_count" => 5,
             "operator_training_requirement_counts" => %{
               "operator_role" => 2,
               "training" => 1,
               "certification" => 1,
               "qualification" => 1
             },
             "required_operator_roles" => ["contact_operator", "mission_director"],
             "required_training_ids" => ["contact_replan_drill"],
             "required_certification_ids" => ["cadence_import_cert"],
             "required_qualification_ids" => ["sat_ops_current"],
             "feedback_source" => "mission_state.source_operational_readiness_report.gates",
             "source_operational_readiness_gate" => %{
               "id" => "operator_training",
               "operator_training_requirement_count" => 5
             }
           } = List.first(readiness_branch["events"])

    assert_operator_training_pressure_score_terms(readiness_branch, artifact)
    assert readiness_branch["score_terms"]["operational_readiness_pressure_penalty"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves import-readiness readiness gate context in branch events" do
    readiness_report = %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "OrbitalDynamics.OperationalReadiness.V1",
      "report_id" => "operational_readiness:planned_activity.v1:import_payload",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "import_payload",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 2,
      "passed_gate_count" => 1,
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gates" => [
        %{
          "id" => "cadence_import",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "Cadence import manifest requires review before execution",
          "import_readiness_row_count" => 1,
          "ready_for_import_count" => 0,
          "manifest_review_required_count" => 1,
          "blocked_import_count" => 0,
          "missing_import_count" => 0,
          "invalid_cadence_import_count" => 1,
          "current_freshness_count" => 0,
          "stale_freshness_count" => 1,
          "unknown_freshness_count" => 0,
          "freshness_status_counts" => %{"stale" => 1},
          "freshness_status_ids" => ["stale"],
          "import_status_counts" => %{"review_required_before_import" => 1},
          "import_status_ids" => ["review_required_before_import"],
          "cadence_import_status_counts" => %{"invalid" => 1},
          "cadence_import_status_ids" => ["invalid"],
          "freshness_review_required" => true,
          "import_preparation_required" => true,
          "import_blocked" => false,
          "stale_or_unknown_freshness_quality_gate_row_ids" => [
            "quality_gate:import_payload:cadence_import:1"
          ],
          "import_preparation_quality_gate_row_ids" => [
            "quality_gate:import_payload:cadence_import:1"
          ],
          "blocked_import_quality_gate_row_ids" => []
        }
      ],
      "evidence" => %{},
      "assumptions" => %{"execution_boundary" => "artifact_only_no_cadence_write"},
      "model_limits" => ["artifact_only"],
      "provenance" => %{"trust_boundary" => "mission_state_operational_readiness_report"}
    }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_operational_readiness_report, readiness_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    readiness_branch = branch(artifact, "derived_operational_readiness_pressure_cadence_import")

    event = List.first(readiness_branch["events"])

    assert event["type"] == "operational_readiness_pressure"
    assert event["readiness_gate_id"] == "cadence_import"
    assert event["import_readiness_row_count"] == 1
    assert event["manifest_review_required_count"] == 1
    assert event["invalid_cadence_import_count"] == 1
    assert event["freshness_status_counts"] == %{"stale" => 1}
    assert event["import_status_counts"] == %{"review_required_before_import" => 1}
    assert event["cadence_import_status_counts"] == %{"invalid" => 1}
    assert event["freshness_review_required"] == true
    assert event["import_preparation_required"] == true
    assert event["import_blocked"] == false
    assert event["feedback_source"] == "mission_state.source_operational_readiness_report.gates"
    assert get_in(event, ["source_operational_readiness_gate", "id"]) == "cadence_import"
    assert get_in(event, ["source_operational_readiness_gate", "import_readiness_row_count"]) == 1

    assert_import_readiness_pressure_score_terms(readiness_branch, artifact)
    assert readiness_branch["score_terms"]["operational_readiness_pressure_penalty"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves schema-validation readiness gate context in branch events" do
    readiness_report = %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "OrbitalDynamics.OperationalReadiness.V1",
      "report_id" => "operational_readiness:planned_activity.v1:schema_payload",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "schema_payload",
      "readiness_level" => "blocked",
      "import_classification" => "blocked",
      "status" => "blocked",
      "gate_count" => 2,
      "passed_gate_count" => 1,
      "review_gate_count" => 0,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 1,
      "gates" => [
        %{
          "id" => "schema_validation",
          "status" => "blocked",
          "classification" => "blocked",
          "reason" => "candidate refresh schema validation failed before import",
          "schema_validation_row_count" => 1,
          "schema_validation_pass_count" => 0,
          "schema_validation_fail_count" => 1,
          "schema_validation_error_count" => 1,
          "schema_validation_warning_count" => 0,
          "schema_validation_remediation_count" => 1,
          "schema_validation_status_counts" => %{"fail" => 1},
          "schema_validation_status_ids" => ["fail"],
          "schema_validation_import_blocked" => true,
          "failed_schema_validation_quality_gate_row_ids" => [
            "quality_gate:schema_payload:schema_validation:1"
          ]
        }
      ],
      "evidence" => %{},
      "assumptions" => %{"execution_boundary" => "artifact_only_no_cadence_write"},
      "model_limits" => ["artifact_only"],
      "provenance" => %{"trust_boundary" => "mission_state_operational_readiness_report"}
    }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_operational_readiness_report, readiness_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    readiness_branch =
      branch(artifact, "derived_operational_readiness_pressure_schema_validation")

    event = List.first(readiness_branch["events"])

    assert event["type"] == "operational_readiness_pressure"
    assert event["readiness_gate_id"] == "schema_validation"
    assert event["schema_validation_row_count"] == 1
    assert event["schema_validation_fail_count"] == 1
    assert event["schema_validation_error_count"] == 1
    assert event["schema_validation_warning_count"] == 0
    assert event["schema_validation_remediation_count"] == 1
    assert event["schema_validation_status_counts"] == %{"fail" => 1}
    assert event["schema_validation_status_ids"] == ["fail"]
    assert event["schema_validation_import_blocked"] == true

    assert event["failed_schema_validation_quality_gate_row_ids"] == [
             "quality_gate:schema_payload:schema_validation:1"
           ]

    assert event["feedback_source"] == "mission_state.source_operational_readiness_report.gates"
    assert get_in(event, ["source_operational_readiness_gate", "id"]) == "schema_validation"

    assert get_in(event, ["source_operational_readiness_gate", "schema_validation_fail_count"]) ==
             1

    assert_validation_refresh_pressure_score_terms(
      readiness_branch,
      artifact,
      "schema_validation"
    )

    assert readiness_branch["score_terms"]["operational_readiness_pressure_penalty"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives operational readiness gate classification from row status" do
    readiness_report = %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => "operational_readiness:planned_activity.v1:stale_gate_status",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "stale_gate_status",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 2,
      "passed_gate_count" => 0,
      "review_gate_count" => 2,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gates" => [
        %{
          "id" => "blocked_without_classification",
          "status" => "blocked",
          "reason" => "blocked gate status must not be downgraded"
        },
        %{
          "id" => "analysis_stale_classification",
          "status" => "analysis_only",
          "classification" => "review_only",
          "reason" => "analysis-only gate status must win over stale classification"
        }
      ],
      "evidence" => %{},
      "assumptions" => %{"execution_boundary" => "artifact_only_no_cadence_write"},
      "model_limits" => ["artifact_only"],
      "provenance" => %{"trust_boundary" => "stale_readiness_report_boundary"}
    }

    gate_summary = %{
      "schema_contract" => "operational_readiness_gate_summary.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_gate_summary",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "stale_gate_summary",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 1,
      "passed_gate_count" => 0,
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gate_status_counts" => %{"review_required" => 1},
      "gate_classification_counts" => %{"review_only" => 1},
      "review_required_gate_ids" => ["stale_summary_review_gate"],
      "analysis_only_gate_ids" => ["stale_summary_analysis_gate"],
      "blocked_gate_ids" => [],
      "non_passed_gate_ids" => ["stale_summary_review_gate"],
      "non_passed_gates" => [
        %{
          "id" => "summary_blocked_without_classification",
          "status" => "blocked",
          "reason" => "summary blocked status must not be downgraded"
        }
      ],
      "assumptions" => %{"operator_authority" => "not_granted_by_summary"},
      "provenance" => %{"trust_boundary" => "stale_readiness_summary_boundary"}
    }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_operational_readiness_report, readiness_report)
      |> Map.put(:source_operational_readiness_gate_summary, gate_summary)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    blocked_branch =
      branch(artifact, "derived_operational_readiness_pressure_blocked_without_classification")

    assert %{
             "type" => "operational_readiness_pressure",
             "readiness_level" => "blocked",
             "import_classification" => "blocked",
             "operational_readiness_status" => "blocked",
             "readiness_gate_status" => "blocked",
             "readiness_gate_classification" => "blocked",
             "required_operator_action" => "review_blocked_operational_readiness",
             "feedback_source" => "mission_state.source_operational_readiness_report.gates"
           } = List.first(blocked_branch["events"])

    analysis_branch =
      branch(artifact, "derived_operational_readiness_pressure_analysis_stale_classification")

    assert %{
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "operational_readiness_status" => "analysis_only",
             "readiness_gate_status" => "analysis_only",
             "readiness_gate_classification" => "analysis_only",
             "required_operator_action" => "record_operational_readiness_analysis_only"
           } = List.first(analysis_branch["events"])

    summary_branch =
      branch(
        artifact,
        "derived_operational_readiness_pressure_summary_blocked_without_classification"
      )

    assert %{
             "readiness_level" => "blocked",
             "import_classification" => "blocked",
             "operational_readiness_status" => "blocked",
             "readiness_gate_status" => "blocked",
             "readiness_gate_classification" => "blocked",
             "gate_status_counts" => %{"blocked" => 1},
             "gate_classification_counts" => %{"blocked" => 1},
             "review_required_gate_ids" => [],
             "analysis_only_gate_ids" => [],
             "blocked_gate_ids" => ["summary_blocked_without_classification"],
             "non_passed_gate_ids" => ["summary_blocked_without_classification"],
             "required_operator_action" => "review_blocked_operational_readiness",
             "feedback_source" =>
               "mission_state.source_operational_readiness_gate_summary.non_passed_gates"
           } = List.first(summary_branch["events"])

    assert_operational_readiness_pressure_score_terms(blocked_branch, artifact)
    assert_operational_readiness_pressure_score_terms(analysis_branch, artifact)
    assert_operational_readiness_pressure_score_terms(summary_branch, artifact)

    summary_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == summary_branch["branch_id"]))

    assert summary_row["branch_operational_readiness_review_required_gate_ids"] in [nil, []]
    assert summary_row["branch_operational_readiness_analysis_only_gate_ids"] in [nil, []]

    assert summary_row["branch_operational_readiness_blocked_gate_ids"] == [
             "summary_blocked_without_classification"
           ]

    assert summary_row["branch_operational_readiness_non_passed_gate_ids"] == [
             "summary_blocked_without_classification"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy challenge uses readiness rows when top-level readiness fields are stale" do
    readiness_report = %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => "operational_readiness:planned_activity.v1:stale_top_level",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "stale_top_level",
      "readiness_level" => "import_eligible",
      "import_classification" => "importable",
      "status" => "passed",
      "gate_count" => 1,
      "passed_gate_count" => 1,
      "review_gate_count" => 0,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gates" => [
        %{
          "id" => "stale_readiness_gate",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "row evidence requires review despite stale top-level pass"
        }
      ],
      "evidence" => %{},
      "assumptions" => %{"stale_top_level_challenge" => true},
      "model_limits" => ["artifact_only"],
      "provenance" => %{"trust_boundary" => "stale_readiness_challenge_boundary"}
    }

    quality_gate_report =
      passive_quality_gate_report()
      |> Map.merge(%{
        "report_id" => "quality_gate:planned_activity.v1:stale_top_level",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "stale_top_level",
        "source_readiness_report_id" =>
          "operational_readiness:planned_activity.v1:stale_top_level",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "gate_count" => 1,
        "passed_gate_count" => 1,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "rows" => [
          %{
            "id" => "quality_gate:stale_top_level:stale_quality_gate:1",
            "rank" => 1,
            "gate_id" => "stale_quality_gate",
            "status" => "review_required",
            "classification" => "review_only",
            "reason" => "row evidence requires review despite stale top-level pass"
          }
        ],
        "assumptions" => %{"stale_top_level_challenge" => true},
        "provenance" => %{"trust_boundary" => "stale_quality_gate_challenge_boundary"}
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_operational_readiness_report, readiness_report)
      |> Map.put(:source_quality_gate_report, quality_gate_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    readiness_branch =
      branch(artifact, "derived_operational_readiness_pressure_stale_readiness_gate")

    quality_gate_branch = branch(artifact, "derived_quality_gate_pressure_stale_quality_gate")

    assert artifact["recommendation"]["recommended_branch_id"] == "baseline"

    assert %{
             "type" => "operational_readiness_pressure",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "operational_readiness_status" => "review_required",
             "readiness_gate_id" => "stale_readiness_gate",
             "readiness_gate_status" => "review_required",
             "readiness_gate_classification" => "review_only",
             "feedback_source" => "mission_state.source_operational_readiness_report.gates",
             "source_operational_readiness_report" => %{
               "readiness_level" => "import_eligible",
               "import_classification" => "importable",
               "status" => "passed"
             }
           } = List.first(readiness_branch["events"])

    assert %{
             "type" => "quality_gate_pressure",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "quality_gate_status" => "review_required",
             "gate_id" => "stale_quality_gate",
             "gate_status" => "review_required",
             "gate_classification" => "review_only",
             "feedback_source" => "mission_state.source_quality_gate_report.rows",
             "source_quality_gate_report" => %{
               "readiness_level" => "import_eligible",
               "import_classification" => "importable",
               "status" => "passed"
             }
           } = List.first(quality_gate_branch["events"])

    assert_operational_readiness_pressure_score_terms(readiness_branch, artifact, 1)
    assert_quality_gate_pressure_score_terms(quality_gate_branch, artifact, 1)

    readiness_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == readiness_branch["branch_id"]))

    assert readiness_row["branch_operational_readiness_gate_ids"] == ["stale_readiness_gate"]
    assert readiness_row["branch_operational_readiness_gate_statuses"] == ["review_required"]
    assert "operational_readiness_pressure" in readiness_row["risk_types"]

    quality_gate_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == quality_gate_branch["branch_id"]))

    assert quality_gate_row["branch_quality_gate_statuses"] == ["review_required"]
    assert quality_gate_row["branch_quality_gate_gate_classifications"] == ["review_only"]
    assert "quality_gate_pressure" in quality_gate_row["risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "branch_comparison_report.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact["branch_comparison_report"])
  end

  test "strategy preserves resource availability quality-gate row context in branch events" do
    quality_gate_report =
      passive_quality_gate_report()
      |> Map.merge(%{
        "report_id" => "quality_gate:resource_projection_report.v1:live_ops",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "live_ops",
        "source_readiness_report_id" =>
          "operational_readiness:resource_projection_report.v1:live_ops",
        "resource_availability_pressure_count" => 99,
        "resource_availability_reason_counts" => %{"stale_resource_reason" => 99},
        "resource_availability_reason_ids" => ["stale_resource_reason"],
        "unavailable_resource_reason_ids" => ["stale_resource_reason"],
        "resource_blocking_dimension_counts" => %{"stale_dimension" => 99},
        "provenance" => %{"trust_boundary" => "mission_state_quality_gate_report"},
        "rows" => [
          %{
            "id" => "quality_gate:live_ops:resource_availability:1",
            "rank" => 1,
            "gate_id" => "resource_availability",
            "status" => "review_required",
            "classification" => "review_only",
            "reason" => "resource availability evidence requires operator review before import",
            "resource_availability_pressure_count" => 2,
            "resource_availability_reason_counts" => %{
              "antenna_unavailable" => 1,
              "payload_unavailable" => 1
            },
            "resource_availability_reason_ids" => [
              "antenna_unavailable",
              "payload_unavailable"
            ],
            "unavailable_resource_reason_ids" => [
              "antenna_unavailable",
              "payload_unavailable"
            ],
            "resource_blocking_dimension_counts" => %{"communications" => 1}
          }
        ]
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_quality_gate_report, quality_gate_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    quality_gate_branch = branch(artifact, "derived_quality_gate_pressure_resource_availability")

    assert %{
             "type" => "quality_gate_pressure",
             "gate_id" => "resource_availability",
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "resource_blocking_dimension_counts" => %{"communications" => 1},
             "source_quality_gate_row" => %{
               "gate_id" => "resource_availability",
               "resource_availability_pressure_count" => 2
             }
           } = List.first(quality_gate_branch["events"])

    refute "stale_resource_reason" in List.first(quality_gate_branch["events"])[
             "resource_availability_reason_ids"
           ]

    assert Enum.any?(
             quality_gate_branch["risk_indicators"],
             &(&1["type"] == "quality_gate_pressure" and
                 &1["resource_availability_pressure_count"] == 2 and
                 &1["resource_availability_reason_counts"] == %{
                   "antenna_unavailable" => 1,
                   "payload_unavailable" => 1
                 } and
                 &1["resource_blocking_dimension_counts"] == %{"communications" => 1})
           )

    quality_gate_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == quality_gate_branch["branch_id"]))

    assert "quality_gate_pressure" in quality_gate_row["risk_types"]

    assert quality_gate_row["branch_feedback_sources"] == [
             "mission_state.source_quality_gate_report.rows"
           ]

    assert_resource_availability_pressure_score_terms(quality_gate_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "branch_comparison_report.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact["branch_comparison_report"])
  end

  test "strategy preserves operator-training quality-gate row context in branch events" do
    quality_gate_report =
      passive_quality_gate_report()
      |> Map.merge(%{
        "report_id" => "quality_gate:planned_activity.v1:live_ops",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "live_ops",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:live_ops",
        "provenance" => %{"trust_boundary" => "mission_state_quality_gate_report"},
        "rows" => [
          %{
            "id" => "quality_gate:live_ops:operator_training:1",
            "rank" => 1,
            "gate_id" => "operator_training",
            "status" => "review_required",
            "classification" => "review_only",
            "reason" => "operator training requires role-qualified review",
            "operator_training_requirement_count" => 5,
            "operator_training_requirement_counts" => %{
              "operator_role" => 2,
              "training" => 1,
              "certification" => 1,
              "qualification" => 1
            },
            "required_operator_roles" => ["contact_operator", "mission_director"],
            "required_training_ids" => ["contact_replan_drill"],
            "required_certification_ids" => ["cadence_import_cert"],
            "required_qualification_ids" => ["sat_ops_current"]
          }
        ]
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_quality_gate_report, quality_gate_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    quality_gate_branch = branch(artifact, "derived_quality_gate_pressure_operator_training")

    assert %{
             "type" => "quality_gate_pressure",
             "gate_id" => "operator_training",
             "operator_training_requirement_count" => 5,
             "operator_training_requirement_counts" => %{
               "operator_role" => 2,
               "training" => 1,
               "certification" => 1,
               "qualification" => 1
             },
             "required_operator_roles" => ["contact_operator", "mission_director"],
             "required_training_ids" => ["contact_replan_drill"],
             "required_certification_ids" => ["cadence_import_cert"],
             "required_qualification_ids" => ["sat_ops_current"],
             "feedback_source" => "mission_state.source_quality_gate_report.rows",
             "source_quality_gate_row" => %{
               "gate_id" => "operator_training",
               "operator_training_requirement_count" => 5
             }
           } = List.first(quality_gate_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp passive_quality_gate_report do
    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => "artifact_only_operational_quality_gate_report",
      "report_id" => "quality_gate:planned_activity.v1:passive_source",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "passive_source",
      "source_readiness_report_id" => "operational_readiness:planned_activity.v1:passive_source",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 1,
      "passed_gate_count" => 0,
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gate_status_counts" => %{"review_required" => 1},
      "gate_classification_counts" => %{"review_only" => 1},
      "rows" => [
        %{
          "id" => "quality_gate:passive_source:operator_review:1",
          "rank" => 1,
          "gate_id" => "operator_review",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "operator review required"
        }
      ],
      "assumptions" => %{"source" => "test.quality_gate_report"},
      "model_limits" => ["artifact_only"]
    }
  end

  defp assert_quality_gate_pressure_score_terms(
         branch,
         artifact,
         extra_split_pressure_count
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    quality_gate_pressure_count =
      Enum.count(branch["risk_indicators"], &(&1["type"] == "quality_gate_pressure"))

    assert quality_gate_pressure_count > 0

    assert branch["score_terms"]["approval_boundary_pressure_penalty"] == 0.0

    assert branch["score_terms"]["quality_gate_pressure_penalty"] ==
             -quality_gate_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 quality_gate_pressure_count - extra_split_pressure_count) * risk_weight

    assert "quality_gate_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "quality_gate_pressure_penalty" and &1["value"] < 0.0)
           )
  end

  defp assert_operator_training_pressure_score_terms(
         branch,
         artifact,
         extra_split_pressure_count \\ 0
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    operator_training_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &operator_training_source_report_pressure?(&1)
      )

    assert operator_training_pressure_count > 0

    assert branch["score_terms"]["operator_training_pressure_penalty"] ==
             -operator_training_pressure_count * risk_weight

    assert branch["score_terms"]["quality_gate_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 operator_training_pressure_count - extra_split_pressure_count) *
               risk_weight

    assert "operator_training_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "operator_training_pressure_penalty" and &1["value"] < 0.0)
           )
  end

  defp operator_training_source_report_pressure?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["gate_id"] == "operator_training" or
      risk["operator_training_requirement_count"] not in [nil, 0] or
      is_map(risk["operator_training_requirement_counts"])
  end

  defp operator_training_source_report_pressure?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["readiness_gate_id"] == "operator_training" or
      risk["operator_training_requirement_count"] not in [nil, 0] or
      is_map(risk["operator_training_requirement_counts"]) or
      risk["required_operator_roles"] not in [nil, []] or
      risk["required_training_ids"] not in [nil, []] or
      risk["required_certification_ids"] not in [nil, []] or
      risk["required_qualification_ids"] not in [nil, []]
  end

  defp operator_training_source_report_pressure?(_risk), do: false

  defp assert_resource_availability_pressure_score_terms(
         branch,
         artifact,
         extra_split_pressure_count \\ 0
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    resource_availability_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in [
            "resource_unavailable",
            "spacecraft_unavailable",
            "payload_unavailable",
            "spacecraft_degraded_payload_unavailable",
            "activity_type_suppressed_by_resource_summary",
            "activity_type_incompatible_with_resource_summary",
            "antenna_unavailable"
          ] or resource_availability_source_report_pressure?(&1))
      )

    assert resource_availability_pressure_count > 0

    assert branch["score_terms"]["resource_availability_pressure_penalty"] ==
             -resource_availability_pressure_count * risk_weight

    assert branch["score_terms"]["quality_gate_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 resource_availability_pressure_count - extra_split_pressure_count) *
               risk_weight

    assert "resource_availability_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "resource_availability_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp resource_availability_source_report_pressure?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["gate_id"] == "resource_availability" or
      is_map(risk["resource_availability_reason_counts"]) or
      is_map(risk["unavailable_resource_reason_counts"]) or
      is_map(risk["blocked_contact_ids_by_blocking_dimension"])
  end

  defp resource_availability_source_report_pressure?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["readiness_gate_id"] == "resource_availability" or
      is_map(risk["resource_availability_reason_counts"]) or
      is_map(risk["unavailable_resource_reason_counts"]) or
      is_map(risk["blocked_contact_ids_by_blocking_dimension"])
  end

  defp resource_availability_source_report_pressure?(_risk), do: false

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

  defp assert_import_readiness_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    import_readiness_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &import_readiness_source_report_pressure?(&1)
      )

    assert import_readiness_pressure_count > 0

    assert branch["score_terms"]["import_readiness_pressure_penalty"] ==
             -import_readiness_pressure_count * risk_weight

    assert branch["score_terms"]["quality_gate_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - import_readiness_pressure_count) *
               risk_weight

    assert "import_readiness_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "import_readiness_pressure_penalty" and &1["value"] < 0.0)
           )
  end

  defp import_readiness_source_report_pressure?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["import_blocked"] == true or
      risk["freshness_review_required"] == true or
      risk["import_preparation_required"] == true or
      is_map(risk["import_status_counts"]) or
      is_map(risk["cadence_import_status_counts"])
  end

  defp import_readiness_source_report_pressure?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["readiness_gate_id"] in ["cadence_import", "import_readiness"] or
      risk["import_blocked"] == true or
      risk["freshness_review_required"] == true or
      risk["import_preparation_required"] == true or
      risk["import_readiness_row_count"] not in [nil, 0] or
      risk["manifest_review_required_count"] not in [nil, 0] or
      risk["blocked_import_count"] not in [nil, 0] or
      risk["missing_import_count"] not in [nil, 0] or
      risk["invalid_cadence_import_count"] not in [nil, 0] or
      is_map(risk["freshness_status_counts"]) or
      is_map(risk["import_status_counts"]) or
      is_map(risk["cadence_import_status_counts"])
  end

  defp import_readiness_source_report_pressure?(_risk), do: false

  defp assert_operational_readiness_pressure_score_terms(
         branch,
         artifact,
         extra_split_pressure_count \\ 0,
         expected_pressure_count \\ 1
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    readiness_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "operational_readiness_pressure" and
            not operator_training_source_report_pressure?(&1) and
            not import_readiness_source_report_pressure?(&1) and
            not schema_validation_source_report_pressure?(&1) and
            not resource_availability_source_report_pressure?(&1))
      )

    assert readiness_pressure_count == expected_pressure_count

    assert branch["score_terms"]["approval_boundary_pressure_penalty"] == 0.0

    assert branch["score_terms"]["operational_readiness_pressure_penalty"] ==
             -readiness_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 readiness_pressure_count - extra_split_pressure_count) * risk_weight

    assert "operational_readiness_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "operational_readiness_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
