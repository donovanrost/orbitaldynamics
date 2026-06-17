defmodule OrbitalDynamics.CandidateRefresh.SchemaValidationReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "source report summary aggregates schema validation routing maps" do
    refresh = %{
      "source_schema_validation_report" => [
        %{
          "schema_contract" => "schema_validation_report.v1",
          "validation_mode" => "artifact",
          "validated_contract" => "candidate_refresh.v1",
          "status" => "fail",
          "error_count" => 2,
          "warning_count" => 1,
          "remediation" => [
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
          ],
          "provenance" => %{"trust_boundary" => "ops_schema_validation"}
        },
        %{
          "schema_contract" => "schema_validation_report.v1",
          "validation_mode" => "artifact_file",
          "validated_contract" => "campaign_plan.v1",
          "status" => "pass",
          "error_count" => 0,
          "warning_count" => 0,
          "remediation_count" => 0,
          "remediation" => [],
          "provenance" => %{"trust_boundary" => "ops_schema_validation"}
        }
      ]
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_schema_validation_contract" => "schema_validation_report.v1",
             "source_report_schema_validation_count" => 2,
             "source_report_schema_validation_row_count" => 2,
             "source_report_schema_validation_paths" => [
               "source_schema_validation_report[0]",
               "source_schema_validation_report[1]"
             ],
             "source_report_schema_validation_status_counts" => %{
               "fail" => 1,
               "pass" => 1
             },
             "source_report_schema_validation_validated_contract_counts" => %{
               "campaign_plan.v1" => 1,
               "candidate_refresh.v1" => 1
             },
             "source_report_schema_validation_mode_counts" => %{
               "artifact" => 1,
               "artifact_file" => 1
             },
             "source_report_schema_validation_error_count" => 2,
             "source_report_schema_validation_warning_count" => 1,
             "source_report_schema_validation_remediation_count" => 2,
             "source_report_schema_validation_remediation_action_counts" => %{
               "populate_id" => 1,
               "populate_type" => 1
             },
             "source_report_schema_validation_remediation_category_counts" => %{
               "missing_required_field" => 2
             },
             "source_report_schema_validation_remediation_path_counts" => %{
               "$.candidate_activities[0].id" => 1,
               "$.candidate_activities[0].type" => 1
             },
             "source_report_schema_validation_branch_local_validation_pressure" => true,
             "source_report_schema_validation_branch_local_schema_error_pressure" => true,
             "source_report_schema_validation_branch_local_schema_warning_pressure" => true,
             "source_report_schema_validation_branch_local_remediation_pressure" => true,
             "source_reports" => %{
               "schema_validation_report" => %{
                 "count" => 2,
                 "row_count" => 2,
                 "error_count" => 2,
                 "warning_count" => 1,
                 "remediation_count" => 2,
                 "remediation_category_counts" => %{"missing_required_field" => 2}
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "model" => "artifact_only_candidate_refresh_schema_validation_replay_summary",
             "source" => "candidate_refresh.source_report_provenance.schema_validation_report",
             "contract" => "schema_validation_report.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 2,
             "source_report_paths" => [
               "source_schema_validation_report[0]",
               "source_schema_validation_report[1]"
             ],
             "status_counts" => %{
               "fail" => 1,
               "pass" => 1
             },
             "validated_contract_counts" => %{
               "campaign_plan.v1" => 1,
               "candidate_refresh.v1" => 1
             },
             "validation_mode_counts" => %{
               "artifact" => 1,
               "artifact_file" => 1
             },
             "error_count" => 2,
             "warning_count" => 1,
             "remediation_count" => 2,
             "remediation_action_counts" => %{
               "populate_id" => 1,
               "populate_type" => 1
             },
             "remediation_category_counts" => %{
               "missing_required_field" => 2
             },
             "remediation_path_counts" => %{
               "$.candidate_activities[0].id" => 1,
               "$.candidate_activities[0].type" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_schema_validation"],
             "branch_local_validation_pressure" => true,
             "branch_local_schema_error_pressure" => true,
             "branch_local_schema_warning_pressure" => true,
             "branch_local_remediation_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" => "schema_validation_source_report_provenance_only",
               "operator_authority" => "not_granted_by_schema_validation_replay_summary",
               "import_approval" => "not_granted_by_schema_validation_replay_summary",
               "cadence_write" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.schema_validation_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_schema_validation_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" =>
          Map.put(summary["source_reports"], "quality_gate_report", %{
            "contract" => "quality_gate_report.v1",
            "count" => 1,
            "row_count" => 1,
            "status_counts" => %{"fail" => 99},
            "trust_boundary_status" => "declared"
          })
      }
    }

    assert %{
             "source_report_family_count" => 2,
             "source_report_schema_validation_contract" => "schema_validation_report.v1",
             "source_report_schema_validation_count" => 2,
             "source_report_schema_validation_row_count" => 2,
             "source_report_schema_validation_paths" => [
               "source_schema_validation_report[0]",
               "source_schema_validation_report[1]"
             ],
             "source_report_schema_validation_status_counts" => %{
               "fail" => 1,
               "pass" => 1
             },
             "source_report_schema_validation_error_count" => 2,
             "source_report_schema_validation_remediation_path_counts" => %{
               "$.candidate_activities[0].id" => 1,
               "$.candidate_activities[0].type" => 1
             },
             "source_report_schema_validation_branch_local_validation_pressure" => true,
             "source_report_schema_validation_branch_local_schema_error_pressure" => true,
             "source_report_schema_validation_branch_local_schema_warning_pressure" => true,
             "source_report_schema_validation_branch_local_remediation_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.schema_validation_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_schema_validation_replay_summary(artifact) ==
             replay_summary
  end

  test "source report summary flattens schema validation batch entries" do
    refresh = %{
      "source_schema_validation_batch_report" => [
        %{
          "schema_contract" => "schema_validation_batch_report.v1",
          "validation_mode" => "artifact_directory",
          "input_dir" => "study_results",
          "status" => "fail",
          "error_count" => 1,
          "warning_count" => 0,
          "reports" => [
            %{
              "path" => "study_results/bad_campaign.json",
              "report" => %{
                "schema_contract" => "schema_validation_report.v1",
                "validation_mode" => "artifact_file",
                "validated_contract" => "campaign_plan.v1",
                "status" => "fail",
                "error_count" => 1,
                "warning_count" => 0,
                "errors" => [%{"path" => "$.plan_id", "message" => "is required"}],
                "remediation" => [
                  %{
                    "path" => "$.plan_id",
                    "category" => "missing_required_field",
                    "action" => "populate plan id"
                  }
                ]
              }
            }
          ],
          "provenance" => %{"trust_boundary" => "schema_batch"}
        }
      ]
    }

    summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_schema_validation_status_counts" => %{"fail" => 1},
             "source_report_schema_validation_validated_contract_counts" => %{
               "campaign_plan.v1" => 1
             },
             "source_report_schema_validation_error_count" => 1,
             "source_report_schema_validation_remediation_action_counts" => %{
               "populate_plan_id" => 1
             },
             "source_reports" => %{
               "schema_validation_report" => %{
                 "paths" => [
                   "source_schema_validation_batch_report[0].reports[0].report"
                 ],
                 "error_count" => 1
               }
             }
           } = summary

    assert %{
             "contract" => "schema_validation_report.v1",
             "source_report_paths" => [
               "source_schema_validation_batch_report[0].reports[0].report"
             ],
             "error_count" => 1,
             "branch_local_schema_error_pressure" => true
           } = CandidateRefresh.schema_validation_replay_summary(refresh)
  end

  test "schema validation replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.schema_validation_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_schema_validation_contract")
    refute Map.has_key?(source_summary, "source_report_schema_validation_count")
    refute Map.has_key?(source_summary, "source_report_schema_validation_row_count")
    refute Map.has_key?(source_summary, "source_report_schema_validation_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_validation_pressure"]
    refute summary["branch_local_schema_error_pressure"]
    refute summary["branch_local_schema_warning_pressure"]
    refute summary["branch_local_remediation_pressure"]
  end

  test "schema validation source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "schema_validation_report.v1"},
      %{"count" => 2},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.schema_validation_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.schema_validation_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "schema_validation_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_schema_validation_contract"] ==
                 "schema_validation_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_schema_validation_contract")
      end

      refute Map.has_key?(source_summary, "source_report_schema_validation_count")
      refute Map.has_key?(source_summary, "source_report_schema_validation_row_count")
      refute Map.has_key?(source_summary, "source_report_schema_validation_paths")
    end
  end

  test "schema validation source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "schema_validation_report" => %{
            "contract" => "schema_validation_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.schema_validation_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_schema_validation_contract"] ==
             "schema_validation_report.v1"

    assert source_summary["source_report_schema_validation_count"] == 0
    assert source_summary["source_report_schema_validation_row_count"] == 0

    assert source_summary["source_report_schema_validation_paths"] == [
             "provenance.source_reports.schema_validation_report"
           ]
  end

  test "schema validation source summary omits missing identity paths after preserving counts" do
    summaries = [
      {"missing paths",
       %{
         "contract" => "schema_validation_report.v1",
         "count" => 1,
         "row_count" => 2
       }},
      {"nil paths",
       %{
         "contract" => "schema_validation_report.v1",
         "count" => 1,
         "row_count" => 2,
         "paths" => nil
       }}
    ]

    for {label, schema_validation_summary} <- summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "schema_validation_report" => schema_validation_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_schema_validation_contract"] ==
               "schema_validation_report.v1",
             label

      assert source_summary["source_report_schema_validation_count"] == 1, label
      assert source_summary["source_report_schema_validation_row_count"] == 2, label
      refute Map.has_key?(source_summary, "source_report_schema_validation_paths"), label
    end
  end

  test "schema validation source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "schema_validation_report" => %{
            "contract" => "schema_validation_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_schema_validation_contract"] ==
             "schema_validation_report.v1"

    assert source_summary["source_report_schema_validation_count"] == 1
    assert source_summary["source_report_schema_validation_row_count"] == 2
    assert source_summary["source_report_schema_validation_paths"] == []
  end

  test "schema validation replay preserves pressure maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "schema_validation_report" => %{
            "contract" => "schema_validation_report.v1",
            "count" => 1,
            "status_counts" => %{"fail" => 1, "warning" => 1},
            "validated_contract_counts" => %{"candidate_refresh.v1" => 1},
            "validation_mode_counts" => %{"artifact_file" => 1},
            "remediation_action_counts" => %{"populate_id" => 1},
            "remediation_category_counts" => %{"missing_required_field" => 1},
            "remediation_path_counts" => %{"$.candidate_activities[0].id" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_schema_validation_count")
    refute Map.has_key?(source_summary, "source_report_schema_validation_row_count")
    refute Map.has_key?(source_summary, "source_report_schema_validation_paths")

    assert source_summary["source_report_schema_validation_status_counts"] == %{
             "fail" => 1,
             "warning" => 1
           }

    assert source_summary["source_report_schema_validation_validated_contract_counts"] == %{
             "candidate_refresh.v1" => 1
           }

    assert source_summary["source_report_schema_validation_mode_counts"] == %{
             "artifact_file" => 1
           }

    assert source_summary["source_report_schema_validation_remediation_action_counts"] == %{
             "populate_id" => 1
           }

    assert source_summary["source_report_schema_validation_remediation_category_counts"] == %{
             "missing_required_field" => 1
           }

    assert source_summary["source_report_schema_validation_remediation_path_counts"] == %{
             "$.candidate_activities[0].id" => 1
           }

    summary = CandidateRefresh.schema_validation_replay_summary(artifact)

    assert summary["branch_local_validation_pressure"]
    assert summary["branch_local_schema_error_pressure"]
    assert summary["branch_local_schema_warning_pressure"]
    assert summary["branch_local_remediation_pressure"]
  end

  test "schema validation replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "schema_validation_report" => %{
              "contract" => "schema_validation_report.v1",
              "count" => 1,
              "row_count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_schema_validation_report"
              ],
              "status_counts" => %{"fail" => 1, "warning" => 1},
              "validated_contract_counts" => %{"candidate_refresh.v1" => 1},
              "validation_mode_counts" => %{"artifact_file" => 1},
              "error_count" => 0,
              "warning_count" => 0,
              "remediation_count" => 0,
              "remediation_action_counts" => %{"populate_id" => 1},
              "remediation_category_counts" => %{"missing_required_field" => 1},
              "remediation_path_counts" => %{"$.candidate_activities[0].id" => 1},
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_schema_validation"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "schema_validation_report" => %{
            "contract" => "schema_validation_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["source_schema_validation_report"],
            "status_counts" => %{},
            "validated_contract_counts" => %{},
            "validation_mode_counts" => %{},
            "error_count" => 0,
            "warning_count" => 0,
            "remediation_count" => 0,
            "remediation_action_counts" => %{},
            "remediation_category_counts" => %{},
            "remediation_path_counts" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.schema_validation_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.schema_validation_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_schema_validation_report"
           ]

    assert summary["status_counts"] == %{"fail" => 1, "warning" => 1}
    assert summary["validated_contract_counts"] == %{"candidate_refresh.v1" => 1}
    assert summary["validation_mode_counts"] == %{"artifact_file" => 1}
    assert summary["error_count"] == 0
    assert summary["warning_count"] == 0
    assert summary["remediation_count"] == 0
    assert summary["remediation_action_counts"] == %{"populate_id" => 1}
    assert summary["remediation_category_counts"] == %{"missing_required_field" => 1}
    assert summary["remediation_path_counts"] == %{"$.candidate_activities[0].id" => 1}
    assert summary["trust_boundaries"] == ["branch_schema_validation"]
    assert summary["branch_local_validation_pressure"]
    assert summary["branch_local_schema_error_pressure"]
    assert summary["branch_local_schema_warning_pressure"]
    assert summary["branch_local_remediation_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "schema_validation_candidate_source_report_summary_only"

    assert %{
             "source_report_schema_validation_branch_local_validation_pressure" => true,
             "source_report_schema_validation_branch_local_schema_error_pressure" => true,
             "source_report_schema_validation_branch_local_schema_warning_pressure" => true,
             "source_report_schema_validation_branch_local_remediation_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_schema_validation_replay_summary(artifact) ==
             summary
  end

  test "schema validation replay treats status and remediation maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "schema_validation_report" => %{
            "contract" => "schema_validation_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["provenance.source_reports.schema_validation_report"],
            "status_counts" => %{"fail" => 1, "warning" => 1},
            "validated_contract_counts" => %{"candidate_refresh.v1" => 1},
            "validation_mode_counts" => %{"artifact_file" => 1},
            "error_count" => 0,
            "warning_count" => 0,
            "remediation_count" => 0,
            "remediation_action_counts" => %{"populate_id" => 1},
            "remediation_category_counts" => %{"missing_required_field" => 1},
            "remediation_path_counts" => %{"$.candidate_activities[0].id" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.schema_validation_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "provenance.source_reports.schema_validation_report"
           ]

    assert summary["status_counts"] == %{"fail" => 1, "warning" => 1}
    assert summary["validated_contract_counts"] == %{"candidate_refresh.v1" => 1}
    assert summary["validation_mode_counts"] == %{"artifact_file" => 1}
    assert summary["error_count"] == 0
    assert summary["warning_count"] == 0
    assert summary["remediation_count"] == 0
    assert summary["remediation_action_counts"] == %{"populate_id" => 1}
    assert summary["remediation_category_counts"] == %{"missing_required_field" => 1}
    assert summary["remediation_path_counts"] == %{"$.candidate_activities[0].id" => 1}
    assert summary["branch_local_validation_pressure"]
    assert summary["branch_local_schema_error_pressure"]
    assert summary["branch_local_schema_warning_pressure"]
    assert summary["branch_local_remediation_pressure"]
  end

  test "schema validation replay treats validated contract maps as validation pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "schema_validation_report" => %{
            "contract" => "schema_validation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.schema_validation_report"],
            "status_counts" => %{},
            "validated_contract_counts" => %{"candidate_refresh.v1" => 1},
            "validation_mode_counts" => %{},
            "error_count" => 0,
            "warning_count" => 0,
            "remediation_count" => 0,
            "remediation_action_counts" => %{},
            "remediation_category_counts" => %{},
            "remediation_path_counts" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.schema_validation_replay_summary(artifact)

    assert summary["validated_contract_counts"] == %{"candidate_refresh.v1" => 1}
    assert summary["branch_local_validation_pressure"]
    refute summary["branch_local_schema_error_pressure"]
    refute summary["branch_local_schema_warning_pressure"]
    refute summary["branch_local_remediation_pressure"]
  end

  test "replays schema validation source reports from review and import containers" do
    report =
      schema_validation_report()
      |> Map.put("provenance", %{"trust_boundary" => "schema_validation_report"})

    package = OperatorReview.from_schema_validation_report(report)
    manifest = CadenceImport.from_schema_validation_report(report)

    for {source, expected_path, expected_trust_boundary_status, expected_trust_boundaries} <- [
          {%{"source_operator_review_package" => package},
           "source_operator_review_package.rows.source_schema_validation_report", "declared",
           ["schema_validation_report"]},
          {%{"source_cadence_import_manifest" => manifest},
           "source_cadence_import_manifest.rows.source_schema_validation_report", "missing", []}
        ] do
      artifact =
        result_set()
        |> CandidateRefresh.build(
          candidate_refresh: Map.merge(refresh_request(), source),
          generated_at: ~U[2026-05-14 00:00:00Z]
        )

      assert %{
               "paths" => [^expected_path],
               "contract" => "schema_validation_report.v1",
               "count" => 1,
               "row_count" => 1,
               "status_counts" => %{"fail" => 1},
               "validated_contract_counts" => %{"campaign_plan.v1" => 1},
               "validation_mode_counts" => %{"artifact_file" => 1},
               "error_count" => 1,
               "warning_count" => 0,
               "remediation_count" => 1,
               "trust_boundary_status" => ^expected_trust_boundary_status,
               "trust_boundaries" => ^expected_trust_boundaries
             } =
               get_in(artifact, [
                 "provenance",
                 "source_reports",
                 "schema_validation_report"
               ])

      assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
               Schema.validate_artifact(artifact)
    end
  end

  defp schema_validation_report do
    %{
      "schema_contract" => "schema_validation_report.v1",
      "model" => "executable_artifact_contract_validation",
      "validation_mode" => "artifact_file",
      "validated_contract" => "campaign_plan.v1",
      "validated_artifact_family" => "campaign_plan",
      "validated_schema_version" => 1,
      "status" => "fail",
      "error_count" => 1,
      "warning_count" => 0,
      "errors" => [
        %{
          "severity" => "error",
          "path" => "$.plan_id",
          "message" => "is required"
        }
      ],
      "warnings" => [],
      "artifact_path" => "study_results/bad_campaign.json",
      "remediation_count" => 1,
      "remediation" => [
        %{
          "path" => "$.plan_id",
          "category" => "missing_required_field",
          "action" => "Populate this required field",
          "source_message" => "is required"
        }
      ],
      "assumptions" => %{"validator" => "OrbitalDynamics.Schema.validate_artifact"}
    }
  end

  defp result_set do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :target_visibility,
          events: [
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 80.0,
                minimum_elevation_deg: 10.0,
                sample_count: 3,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :target_visibility_linear_margin_interpolation,
                start_boundary: :clipped_start,
                end_boundary: :visibility_end,
                start_boundary_detail: %{
                  boundary: :clipped_start,
                  interpolation: :clipped_to_sample,
                  interpolation_fraction: 0.0,
                  sample_index: 1,
                  elevation_deg: 80.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :visibility_end,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.5,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 10.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :target_visibility,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :aos_los_linear_margin_interpolation,
                start_boundary: :aos,
                end_boundary: :los,
                start_boundary_detail: %{
                  edge: :start,
                  boundary: :aos,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.25,
                  before_sample_index: 2,
                  after_sample_index: 3,
                  before_elevation_deg: 0.0,
                  after_elevation_deg: 20.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :los,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.75,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :access_windows,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :other,
          event_type: :eclipse,
          events: [
            %{
              type: :eclipse,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{sample_count: 3}
            }
          ],
          source: %{shadow_model: :cylindrical_central_body_shadow}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp refresh_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ],
      "prior_candidate_activities" => [
        %{
          "id" => "stale_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }
  end
end
