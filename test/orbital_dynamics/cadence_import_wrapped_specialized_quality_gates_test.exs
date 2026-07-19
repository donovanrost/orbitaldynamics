defmodule OrbitalDynamics.CadenceImportWrappedSpecializedQualityGatesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, Schema}

  test "candidate refresh import preserves wrapped specialized quality gate summaries" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_specialized_quality_gate_import",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_operational_quality_gate_operator_training_summary" =>
            operational_quality_gate_operator_training_summary(),
          "source_operational_quality_gate_schema_validation_summary" =>
            operational_quality_gate_schema_validation_summary()
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_specialized_quality_gate_import",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_quality_gate" => 2},
             "source_review_type_counts" => %{"quality_gate_review" => 2}
           } = manifest

    assert Enum.map(manifest["rows"], & &1["source"]) == [
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_operator_training_summary",
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_schema_validation_summary"
           ]

    assert Enum.all?(
             manifest["rows"],
             &match?(
               %{
                 "import_action" => "review_quality_gate",
                 "source_review_type" => "quality_gate_review",
                 "import_status" => "review_required_before_import"
               },
               &1
             )
           )

    assert Enum.all?(manifest["rows"], &(Map.get(&1, "has_cadence_import", false) == false))

    assert %{
             "approval_status" => "operator_review_required",
             "quality_gate_id" => "operator_training",
             "quality_gate_status" => "review_required",
             "quality_gate_classification" => "review_only",
             "readiness_level" => "operator_review",
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "source_summary_schema_contract" =>
                 "operational_quality_gate_operator_training_summary.v1",
               "source_summary_model" => "artifact_only_quality_gate_operator_training_summary",
               "quality_gate_row_ids_by_status" => %{
                 "review_required" => ["quality_gate:activity_1:operator_training"]
               },
               "assumptions" => %{
                 "operator_authority" => "not_granted_by_operator_training_summary",
                 "cadence_write" => "not_performed_by_summary",
                 "command_execution" => "not_performed_by_summary"
               }
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_operator_training_summary",
               "operator_training_requirement_count" => 5,
               "operator_training_requirement_counts" => %{
                 "certification" => 1,
                 "operator_role" => 2,
                 "qualification" => 1,
                 "training" => 1
               },
               "required_operator_roles" => ["contact_operator", "mission_director"],
               "required_training_ids" => ["contact_replan_drill"],
               "source_quality_gate_report" => %{
                 "source_summary_schema_contract" =>
                   "operational_quality_gate_operator_training_summary.v1"
               },
               "source_quality_gate_row" => %{
                 "id" => "quality_gate:activity_1:operator_training",
                 "gate_id" => "operator_training",
                 "operator_training_requirement_count" => 5
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["quality_gate_id"] == "operator_training")
             )

    assert %{
             "approval_status" => "blocked_by_policy",
             "quality_gate_id" => "cadence_import",
             "quality_gate_status" => "blocked",
             "quality_gate_classification" => "blocked",
             "readiness_level" => "blocked",
             "schema_validation_pass_count" => 0,
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 1,
             "schema_validation_remediation_count" => 1,
             "schema_validation_status_counts" => %{"fail" => 1},
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "source_summary_schema_contract" =>
                 "operational_quality_gate_schema_validation_summary.v1",
               "source_summary_model" => "artifact_only_quality_gate_schema_validation_summary",
               "quality_gate_row_ids_by_status" => %{
                 "blocked" => ["quality_gate:activity_1:schema_validation"]
               },
               "assumptions" => %{
                 "operator_authority" => "not_granted_by_schema_validation_summary",
                 "cadence_write" => "not_performed_by_summary",
                 "command_execution" => "not_performed_by_summary"
               }
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_schema_validation_summary",
               "source_quality_gate_report" => %{
                 "source_summary_schema_contract" =>
                   "operational_quality_gate_schema_validation_summary.v1"
               },
               "source_quality_gate_row" => %{
                 "id" => "quality_gate:activity_1:schema_validation",
                 "gate_id" => "cadence_import",
                 "schema_validation_status_counts" => %{"fail" => 1}
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["quality_gate_id"] == "cadence_import")
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped import-readiness quality gate summaries" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_import_readiness_quality_gate_import",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_operational_quality_gate_import_readiness_summary" =>
            operational_quality_gate_import_readiness_summary()
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_import_readiness_quality_gate_import",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_quality_gate" => 2},
             "source_review_type_counts" => %{"quality_gate_review" => 2}
           } = manifest

    assert Enum.map(manifest["rows"], & &1["source"]) == [
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_import_readiness_summary",
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_import_readiness_summary"
           ]

    assert Enum.all?(
             manifest["rows"],
             &match?(
               %{
                 "import_action" => "review_quality_gate",
                 "source_review_type" => "quality_gate_review",
                 "import_status" => "review_required_before_import",
                 "quality_gate_id" => "cadence_import"
               },
               &1
             )
           )

    assert Enum.all?(manifest["rows"], &(Map.get(&1, "has_cadence_import", false) == false))

    assert %{
             "approval_status" => "operator_review_required",
             "quality_gate_status" => "review_required",
             "quality_gate_classification" => "review_only",
             "readiness_level" => "blocked",
             "ready_for_import_count" => 1,
             "manifest_review_required_count" => 1,
             "blocked_import_count" => 1,
             "missing_import_count" => 1,
             "invalid_cadence_import_count" => 1,
             "freshness_status_counts" => %{"stale" => 1, "unknown" => 1},
             "import_status_counts" => %{
               "ready_for_import" => 1,
               "review_required_before_import" => 1
             },
             "cadence_import_status_counts" => %{
               "invalid" => 1,
               "missing" => 1,
               "present" => 1
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "source_summary_schema_contract" =>
                 "operational_quality_gate_import_readiness_summary.v1",
               "source_summary_model" => "artifact_only_quality_gate_import_readiness_summary",
               "quality_gate_row_ids_by_status" => %{
                 "blocked" => ["quality_gate:cadence_import:blocked"],
                 "review_required" => ["quality_gate:cadence_import:stale"]
               },
               "assumptions" => %{
                 "operator_authority" => "not_granted_by_quality_gate_import_readiness_summary",
                 "cadence_write" => "not_performed_by_summary",
                 "command_execution" => "not_performed_by_summary"
               }
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_import_readiness_summary",
               "source_quality_gate_row" => %{
                 "id" => "quality_gate:cadence_import:stale",
                 "status" => "review_required",
                 "classification" => "review_only",
                 "source_summary_schema_contract" =>
                   "operational_quality_gate_import_readiness_summary.v1"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["subject_id"] == "quality_gate:cadence_import:stale")
             )

    assert %{
             "source_review_action" => "review_blocked_quality_gate",
             "approval_status" => "blocked_by_policy",
             "quality_gate_status" => "blocked",
             "quality_gate_classification" => "blocked",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_import_readiness_summary",
               "source_quality_gate_row" => %{
                 "id" => "quality_gate:cadence_import:blocked",
                 "status" => "blocked",
                 "classification" => "blocked"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["subject_id"] == "quality_gate:cadence_import:blocked")
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  defp operational_quality_gate_import_readiness_summary do
    %{
      "schema_contract" => "operational_quality_gate_import_readiness_summary.v1",
      "model" => "artifact_only_quality_gate_import_readiness_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "quality_gate_report.v1",
      "source_artifact_id" => "operational_timeline:import_ready",
      "source_quality_gate_report_id" => "quality_gate:ops_import_readiness",
      "source_readiness_report_id" => "operational_readiness:ops_import_readiness",
      "import_readiness_row_count" => 2,
      "ready_for_import_count" => 1,
      "manifest_review_required_count" => 1,
      "blocked_import_count" => 1,
      "missing_import_count" => 1,
      "invalid_cadence_import_count" => 1,
      "current_freshness_count" => 0,
      "stale_freshness_count" => 1,
      "unknown_freshness_count" => 1,
      "freshness_status_counts" => %{"stale" => 1, "unknown" => 1},
      "freshness_status_ids" => ["stale", "unknown"],
      "schema_validation_pass_count" => 0,
      "schema_validation_fail_count" => 1,
      "schema_validation_error_count" => 1,
      "schema_validation_warning_count" => 0,
      "schema_validation_remediation_count" => 1,
      "schema_validation_status_counts" => %{"fail" => 1},
      "import_status_counts" => %{
        "ready_for_import" => 1,
        "review_required_before_import" => 1
      },
      "import_status_ids" => ["ready_for_import", "review_required_before_import"],
      "cadence_import_status_counts" => %{
        "invalid" => 1,
        "missing" => 1,
        "present" => 1
      },
      "cadence_import_status_ids" => ["invalid", "missing", "present"],
      "quality_gate_row_ids_by_status" => %{
        "blocked" => ["quality_gate:cadence_import:blocked"],
        "review_required" => ["quality_gate:cadence_import:stale"]
      },
      "quality_gate_ids_by_status" => %{
        "blocked" => ["cadence_import"],
        "review_required" => ["cadence_import"]
      },
      "review_required_quality_gate_row_ids" => ["quality_gate:cadence_import:stale"],
      "blocked_quality_gate_row_ids" => ["quality_gate:cadence_import:blocked"],
      "ready_quality_gate_row_ids" => [],
      "analysis_only_quality_gate_row_ids" => [],
      "stale_or_unknown_freshness_quality_gate_row_ids" => [
        "quality_gate:cadence_import:stale"
      ],
      "import_preparation_quality_gate_row_ids" => ["quality_gate:cadence_import:stale"],
      "blocked_import_quality_gate_row_ids" => ["quality_gate:cadence_import:blocked"],
      "import_readiness_gate_ids" => ["cadence_import"],
      "assumptions" => %{
        "source" => "quality_gate_report.v1",
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_import_readiness_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "import_readiness_summary_fixture"}
    }
  end

  defp operational_quality_gate_operator_training_summary do
    %{
      "schema_contract" => "operational_quality_gate_operator_training_summary.v1",
      "model" => "artifact_only_quality_gate_operator_training_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
      "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
      "operator_training_row_count" => 1,
      "operator_training_requirement_count" => 5,
      "operator_training_requirement_counts" => %{
        "operator_role" => 2,
        "training" => 1,
        "certification" => 1,
        "qualification" => 1
      },
      "operator_training_requirement_ids" => [
        "certification",
        "operator_role",
        "qualification",
        "training"
      ],
      "required_operator_roles" => ["contact_operator", "mission_director"],
      "required_training_ids" => ["contact_replan_drill"],
      "required_certification_ids" => ["cadence_import_cert"],
      "required_qualification_ids" => ["sat_ops_current"],
      "quality_gate_row_ids_by_status" => %{
        "review_required" => ["quality_gate:activity_1:operator_training"]
      },
      "quality_gate_row_ids_by_classification" => %{
        "review_only" => ["quality_gate:activity_1:operator_training"]
      },
      "quality_gate_ids_by_status" => %{"review_required" => ["operator_training"]},
      "quality_gate_ids_by_classification" => %{"review_only" => ["operator_training"]},
      "review_required_quality_gate_row_ids" => [
        "quality_gate:activity_1:operator_training"
      ],
      "blocked_quality_gate_row_ids" => [],
      "review_only_quality_gate_row_ids" => [
        "quality_gate:activity_1:operator_training"
      ],
      "operator_training_gate_ids" => ["operator_training"],
      "operator_training_review_required" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_operator_training_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "operator_training_summary_fixture"}
    }
  end

  defp operational_quality_gate_schema_validation_summary do
    %{
      "schema_contract" => "operational_quality_gate_schema_validation_summary.v1",
      "model" => "artifact_only_quality_gate_schema_validation_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
      "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
      "schema_validation_row_count" => 1,
      "schema_validation_pass_count" => 0,
      "schema_validation_fail_count" => 1,
      "schema_validation_error_count" => 1,
      "schema_validation_warning_count" => 0,
      "schema_validation_remediation_count" => 1,
      "schema_validation_status_counts" => %{"fail" => 1},
      "schema_validation_status_ids" => ["fail"],
      "schema_validation_import_blocked" => true,
      "quality_gate_row_ids_by_status" => %{
        "blocked" => ["quality_gate:activity_1:schema_validation"]
      },
      "quality_gate_ids_by_status" => %{"blocked" => ["cadence_import"]},
      "blocked_quality_gate_row_ids" => [
        "quality_gate:activity_1:schema_validation"
      ],
      "review_required_quality_gate_row_ids" => [],
      "failed_schema_validation_quality_gate_row_ids" => [
        "quality_gate:activity_1:schema_validation"
      ],
      "schema_validation_gate_ids" => ["cadence_import"],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_schema_validation_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "schema_validation_summary_fixture"}
    }
  end
end
