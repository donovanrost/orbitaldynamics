defmodule OrbitalDynamics.OperatorReview.CandidateRefreshQualityGateTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source quality gate reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:quality_gate_review:001",
      "source_quality_gate_report" => %{
        "schema_contract" => "quality_gate_report.v1",
        "report_id" => "quality_gate:candidate_refresh:resource_pressure",
        "source_artifact_type" => "candidate_refresh.v1",
        "source_artifact_id" => "candidate_refresh:quality_gate_review:001",
        "readiness_level" => "operator_review",
        "rows" => [
          %{
            "id" => "quality_gate:resource_availability",
            "gate_id" => "resource_availability",
            "status" => "review_required",
            "classification" => "review_only",
            "reason" => "resource pressure requires operator review",
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
            ]
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:quality_gate_review:001",
             "review_count" => 1,
             "quality_gate_review_count" => 1,
             "cadence_import_status_counts" => %{"present" => 1}
           } = package

    assert %{
             "review_type" => "quality_gate_review",
             "source" => "candidate_refresh.source_quality_gate_report.rows",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "resource_availability",
             "quality_gate_status" => "review_required",
             "quality_gate_classification" => "review_only",
             "readiness_level" => "operator_review",
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
             "source_quality_gate_row" => %{
               "gate_id" => "resource_availability",
               "classification" => "review_only"
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "report_id" => "quality_gate:candidate_refresh:resource_pressure"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact quality gate reports become operator review rows" do
    report = %{
      "schema_contract" => "quality_gate_report.v1",
      "report_id" => "quality_gate:candidate_refresh:wrapped_resource_pressure",
      "source_artifact_type" => "candidate_refresh.v1",
      "source_artifact_id" => "candidate_refresh:wrapped_quality_gate_review:001",
      "readiness_level" => "operator_review",
      "rows" => [
        %{
          "id" => "quality_gate:resource_availability",
          "gate_id" => "resource_availability",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "wrapped resource pressure requires operator review",
          "resource_availability_pressure_count" => 1,
          "resource_availability_reason_counts" => %{"antenna_unavailable" => 1},
          "resource_availability_reason_ids" => ["antenna_unavailable"],
          "unavailable_resource_reason_ids" => ["antenna_unavailable"]
        }
      ]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_quality_gate_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "quality_gate_report" => report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_quality_gate_review:001",
             "review_count" => 1,
             "quality_gate_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "quality_gate_review",
               "source" => "candidate_refresh.source_result_artifact.quality_gate_report.rows",
               "required_operator_action" => "review_quality_gate",
               "quality_gate_id" => "resource_availability",
               "quality_gate_status" => "review_required",
               "quality_gate_classification" => "review_only",
               "readiness_level" => "operator_review",
               "resource_availability_pressure_count" => 1,
               "resource_availability_reason_counts" => %{"antenna_unavailable" => 1},
               "source_quality_gate_report" => %{
                 "report_id" => "quality_gate:candidate_refresh:wrapped_resource_pressure"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh operational quality gate summaries become operator review rows" do
    summary = study_result_fixture("operational_quality_gate_summary_v1.json")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:operational_quality_gate_summary:001",
      "source_operational_quality_gate_summary" => summary
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:operational_quality_gate_summary:001",
             "review_count" => 3,
             "quality_gate_review_count" => 3
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.source_operational_quality_gate_summary.rows",
             "candidate_refresh.source_operational_quality_gate_summary.rows",
             "candidate_refresh.source_operational_quality_gate_summary.rows"
           ]

    assert %{
             "review_type" => "quality_gate_review",
             "source" => "candidate_refresh.source_operational_quality_gate_summary.rows",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "resource_availability",
             "quality_gate_status" => "review_required",
             "quality_gate_classification" => "review_only",
             "readiness_level" => "operator_review",
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "source_quality_gate_row" => %{
               "gate_id" => "resource_availability",
               "source_summary_schema_contract" => "operational_quality_gate_summary.v1",
               "source_summary_model" => "artifact_only_quality_gate_summary"
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "report_id" => "quality_gate:resource_projection_report.v1:resource_summaries",
               "source_summary_schema_contract" => "operational_quality_gate_summary.v1",
               "source_summary_model" => "artifact_only_quality_gate_summary",
               "quality_gate_row_ids_by_status" => %{
                 "review_required" => [
                   "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6",
                   "quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5",
                   "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
                 ]
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["quality_gate_id"] == "resource_availability")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact operational quality gate summaries become operator review rows" do
    summary = study_result_fixture("operational_quality_gate_summary_v1.json")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_operational_quality_gate_summary:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_operational_quality_gate_summary" => summary,
          "operational_quality_gate_summary" => summary
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_operational_quality_gate_summary:001",
             "review_count" => 6,
             "quality_gate_review_count" => 6
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_summary.rows",
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_summary.rows",
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_summary.rows",
             "candidate_refresh.source_result_artifact[0].operational_quality_gate_summary.rows",
             "candidate_refresh.source_result_artifact[0].operational_quality_gate_summary.rows",
             "candidate_refresh.source_result_artifact[0].operational_quality_gate_summary.rows"
           ]

    assert %{
             "review_type" => "quality_gate_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].operational_quality_gate_summary.rows",
             "quality_gate_id" => "cadence_import",
             "quality_gate_status" => "review_required",
             "source_quality_gate_row" => %{
               "gate_id" => "cadence_import",
               "source_summary_schema_contract" => "operational_quality_gate_summary.v1"
             },
             "source_quality_gate_report" => %{
               "source_summary_schema_contract" => "operational_quality_gate_summary.v1",
               "non_passed_gate_count" => 3
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].operational_quality_gate_summary.rows" and
                   &1["quality_gate_id"] == "cadence_import")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh compact quality gate import-readiness summaries become review and import rows" do
    summary = quality_gate_import_readiness_summary()

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:quality_gate_import_readiness:001",
      "source_operational_quality_gate_import_readiness_summary" =>
        Map.merge(summary, %{
          "import_readiness_row_count" => 99,
          "review_required_quality_gate_row_ids" => ["stale_review"],
          "blocked_quality_gate_row_ids" => ["stale_blocked"]
        }),
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_operational_quality_gate_import_readiness_summary" => summary
        }
      ],
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "operational_quality_gate_import_readiness_summary" => summary
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:quality_gate_import_readiness:001",
             "review_count" => 6,
             "quality_gate_review_count" => 6
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.source_operational_quality_gate_import_readiness_summary",
             "candidate_refresh.source_operational_quality_gate_import_readiness_summary",
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_import_readiness_summary",
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_import_readiness_summary",
             "candidate_refresh.result_artifact[0].operational_quality_gate_import_readiness_summary",
             "candidate_refresh.result_artifact[0].operational_quality_gate_import_readiness_summary"
           ]

    assert %{
             "review_type" => "quality_gate_review",
             "required_operator_action" => "review_quality_gate",
             "approval_status" => "operator_review_required",
             "cadence_import_status" => "present",
             "quality_gate_id" => "cadence_import",
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
             "source_quality_gate_row" => %{
               "id" => "quality_gate:cadence_import:stale",
               "gate_id" => "cadence_import",
               "status" => "review_required",
               "classification" => "review_only",
               "source_summary_schema_contract" =>
                 "operational_quality_gate_import_readiness_summary.v1"
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "report_id" => "quality_gate:ops_import_readiness",
               "quality_gate_row_ids_by_status" => %{
                 "blocked" => ["quality_gate:cadence_import:blocked"],
                 "review_required" => ["quality_gate:cadence_import:stale"]
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["subject_id"] == "quality_gate:cadence_import:stale")
             )

    assert %{
             "required_operator_action" => "review_blocked_quality_gate",
             "approval_status" => "blocked_by_policy",
             "quality_gate_status" => "blocked",
             "quality_gate_classification" => "blocked"
           } =
             Enum.find(
               package["rows"],
               &(&1["subject_id"] == "quality_gate:cadence_import:blocked")
             )

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:quality_gate_import_readiness:001",
             "row_count" => 6,
             "source_review_type_counts" => %{"quality_gate_review" => 6},
             "import_action_counts" => %{"review_quality_gate" => 6}
           } = manifest

    assert %{
             "import_action" => "review_quality_gate",
             "import_status" => "review_required_before_import",
             "source_review_type" => "quality_gate_review",
             "source_review_action" => "review_quality_gate",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_operational_quality_gate_import_readiness_summary",
               "quality_gate_status" => "review_required"
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["subject_id"] == "quality_gate:cadence_import:stale")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh compact unavailable-resource quality gate summaries become review and import rows" do
    summary = quality_gate_unavailable_resource_summary()

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:quality_gate_unavailable_resource:001",
      "source_operational_quality_gate_unavailable_resource_summary" =>
        Map.put(summary, "resource_availability_row_count", 99),
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_operational_quality_gate_unavailable_resource_summary" => summary
        }
      ],
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "operational_quality_gate_unavailable_resource_summary" => summary
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:quality_gate_unavailable_resource:001",
             "review_count" => 3,
             "quality_gate_review_count" => 3
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.source_operational_quality_gate_unavailable_resource_summary",
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_unavailable_resource_summary",
             "candidate_refresh.result_artifact[0].operational_quality_gate_unavailable_resource_summary"
           ]

    assert %{
             "review_type" => "quality_gate_review",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "resource_availability",
             "quality_gate_status" => "review_required",
             "quality_gate_classification" => "review_only",
             "readiness_level" => "operator_review",
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "resource_availability_reason_ids" => [
               "ground_station_unavailable",
               "payload_unavailable"
             ],
             "station_availability_reason_ids" => ["ground_station_unavailable"],
             "unavailable_resource_reason_ids" => ["payload_unavailable"],
             "resource_blocking_dimension_counts" => %{"payload" => 1},
             "resource_blocked_contact_ids_by_blocking_dimension" => %{
               "payload" => ["contact:payload_blocked"]
             },
             "source_quality_gate_row" => %{
               "id" => "quality_gate:activity_1:resource_availability",
               "gate_id" => "resource_availability",
               "status" => "review_required",
               "resource_availability_reason_counts" => %{
                 "ground_station_unavailable" => 1,
                 "payload_unavailable" => 1
               }
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "report_id" => "quality_gate:contact_filter:payload_blocked",
               "quality_gate_row_ids_by_status" => %{
                 "review_required" => ["quality_gate:activity_1:resource_availability"]
               }
             }
           } = List.first(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:quality_gate_unavailable_resource:001",
             "row_count" => 3,
             "source_review_type_counts" => %{"quality_gate_review" => 3},
             "import_action_counts" => %{"review_quality_gate" => 3}
           } = manifest

    assert %{
             "import_action" => "review_quality_gate",
             "import_status" => "review_required_before_import",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_operational_quality_gate_unavailable_resource_summary",
               "resource_availability_reason_counts" => %{
                 "ground_station_unavailable" => 1,
                 "payload_unavailable" => 1
               }
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh compact operator-training quality gate summaries become review and import rows" do
    summary = quality_gate_operator_training_summary()

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:quality_gate_operator_training:001",
      "source_operational_quality_gate_operator_training_summary" =>
        Map.put(summary, "operator_training_row_count", 99),
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_operational_quality_gate_operator_training_summary" => summary
        }
      ],
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "operational_quality_gate_operator_training_summary" => summary
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:quality_gate_operator_training:001",
             "review_count" => 3,
             "quality_gate_review_count" => 3
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.source_operational_quality_gate_operator_training_summary",
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_operator_training_summary",
             "candidate_refresh.result_artifact[0].operational_quality_gate_operator_training_summary"
           ]

    assert %{
             "review_type" => "quality_gate_review",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "operator_training",
             "quality_gate_status" => "review_required",
             "quality_gate_classification" => "review_only",
             "readiness_level" => "operator_review",
             "operator_training_requirement_count" => 5,
             "operator_training_requirement_counts" => %{
               "certification" => 1,
               "operator_role" => 2,
               "qualification" => 1,
               "training" => 1
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
             "source_quality_gate_row" => %{
               "id" => "quality_gate:activity_1:operator_training",
               "gate_id" => "operator_training",
               "operator_training_requirement_count" => 5
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "report_id" => "quality_gate:planned_activity.v1:activity_1",
               "quality_gate_row_ids_by_status" => %{
                 "review_required" => ["quality_gate:activity_1:operator_training"]
               }
             }
           } = List.first(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:quality_gate_operator_training:001",
             "row_count" => 3,
             "source_review_type_counts" => %{"quality_gate_review" => 3},
             "import_action_counts" => %{"review_quality_gate" => 3}
           } = manifest

    assert %{
             "import_action" => "review_quality_gate",
             "import_status" => "review_required_before_import",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_operational_quality_gate_operator_training_summary",
               "operator_training_requirement_count" => 5,
               "required_training_ids" => ["contact_replan_drill"]
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh compact schema-validation quality gate summaries become review and import rows" do
    summary = quality_gate_schema_validation_summary()

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:quality_gate_schema_validation:001",
      "source_operational_quality_gate_schema_validation_summary" =>
        Map.put(summary, "schema_validation_row_count", 99),
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_operational_quality_gate_schema_validation_summary" => summary
        }
      ],
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "operational_quality_gate_schema_validation_summary" => summary
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:quality_gate_schema_validation:001",
             "review_count" => 3,
             "quality_gate_review_count" => 3
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.source_operational_quality_gate_schema_validation_summary",
             "candidate_refresh.source_result_artifact[0].source_operational_quality_gate_schema_validation_summary",
             "candidate_refresh.result_artifact[0].operational_quality_gate_schema_validation_summary"
           ]

    assert %{
             "review_type" => "quality_gate_review",
             "required_operator_action" => "review_blocked_quality_gate",
             "approval_status" => "blocked_by_policy",
             "quality_gate_id" => "cadence_import",
             "quality_gate_status" => "blocked",
             "quality_gate_classification" => "blocked",
             "readiness_level" => "blocked",
             "schema_validation_pass_count" => 0,
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 1,
             "schema_validation_warning_count" => 0,
             "schema_validation_remediation_count" => 1,
             "schema_validation_status_counts" => %{"fail" => 1},
             "source_quality_gate_row" => %{
               "id" => "quality_gate:activity_1:schema_validation",
               "gate_id" => "cadence_import",
               "status" => "blocked",
               "schema_validation_status_counts" => %{"fail" => 1}
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "report_id" => "quality_gate:planned_activity.v1:activity_1",
               "quality_gate_row_ids_by_status" => %{
                 "blocked" => ["quality_gate:activity_1:schema_validation"]
               }
             }
           } = List.first(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:quality_gate_schema_validation:001",
             "row_count" => 3,
             "source_review_type_counts" => %{"quality_gate_review" => 3},
             "import_action_counts" => %{"review_quality_gate" => 3}
           } = manifest

    assert %{
             "import_action" => "review_quality_gate",
             "import_status" => "review_required_before_import",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_operational_quality_gate_schema_validation_summary",
               "schema_validation_status_counts" => %{"fail" => 1}
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  defp quality_gate_import_readiness_summary do
    %{
      "schema_contract" => "operational_quality_gate_import_readiness_summary.v1",
      "model" => "artifact_only_quality_gate_import_readiness_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "quality_gate_report.v1",
      "source_artifact_id" => "operational_timeline:import_ready",
      "source_quality_gate_report_id" => "quality_gate:ops_import_readiness",
      "source_readiness_report_id" => "operational_readiness:ops_import_readiness",
      "ready_for_import_count" => 1,
      "manifest_review_required_count" => 1,
      "blocked_import_count" => 1,
      "missing_import_count" => 1,
      "invalid_cadence_import_count" => 1,
      "current_freshness_count" => 0,
      "stale_freshness_count" => 1,
      "unknown_freshness_count" => 1,
      "freshness_status_counts" => %{"stale" => 1, "unknown" => 1},
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
      "cadence_import_status_counts" => %{
        "invalid" => 1,
        "missing" => 1,
        "present" => 1
      },
      "quality_gate_row_ids_by_status" => %{
        "review_required" => ["quality_gate:cadence_import:stale"],
        "blocked" => ["quality_gate:cadence_import:blocked"]
      },
      "quality_gate_ids_by_status" => %{
        "review_required" => ["cadence_import"],
        "blocked" => ["cadence_import"]
      },
      "stale_or_unknown_freshness_quality_gate_row_ids" => [
        "quality_gate:cadence_import:stale"
      ],
      "import_preparation_quality_gate_row_ids" => ["quality_gate:cadence_import:stale"],
      "blocked_import_quality_gate_row_ids" => ["quality_gate:cadence_import:blocked"],
      "import_readiness_gate_ids" => ["cadence_import"],
      "assumptions" => %{
        "source" => "quality_gate_report.v1",
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_import_readiness_summary"
      }
    }
  end

  defp quality_gate_unavailable_resource_summary do
    %{
      "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
      "model" => "artifact_only_quality_gate_unavailable_resource_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "contact_filter_report.v1",
      "source_artifact_id" => "contact_filter:payload_blocked",
      "source_quality_gate_report_id" => "quality_gate:contact_filter:payload_blocked",
      "source_readiness_report_id" => "operational_readiness:contact_filter:payload_blocked",
      "resource_availability_row_count" => 1,
      "unavailable_resource_row_count" => 1,
      "unavailable_resource_pressure_count" => 1,
      "unavailable_resource_reason_counts" => %{"payload_unavailable" => 1},
      "unavailable_resource_reason_ids" => ["payload_unavailable"],
      "station_availability_reason_counts" => %{"ground_station_unavailable" => 1},
      "station_availability_reason_ids" => ["ground_station_unavailable"],
      "resource_blocking_dimension_counts" => %{"payload" => 1},
      "blocked_contact_ids_by_blocking_dimension" => %{
        "payload" => ["contact:payload_blocked"]
      },
      "blocked_contact_ids_by_spacecraft_id" => %{
        "leo_1" => ["contact:payload_blocked"]
      },
      "blocked_contact_ids_by_status" => %{
        "review_required" => ["contact:payload_blocked"]
      },
      "quality_gate_row_ids_by_status" => %{
        "review_required" => ["quality_gate:activity_1:resource_availability"]
      },
      "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
      "review_required_quality_gate_row_ids" => [
        "quality_gate:activity_1:resource_availability"
      ],
      "blocked_quality_gate_row_ids" => [],
      "resource_availability_gate_ids" => ["resource_availability"],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_unavailable_resource_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "unavailable_resource_summary_fixture"}
    }
  end

  defp quality_gate_operator_training_summary do
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

  defp quality_gate_schema_validation_summary do
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
      "blocked_quality_gate_row_ids" => ["quality_gate:activity_1:schema_validation"],
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

  defp study_result_fixture(filename) do
    ["study_results", filename]
    |> Path.join()
    |> File.read!()
    |> :json.decode()
  end
end
