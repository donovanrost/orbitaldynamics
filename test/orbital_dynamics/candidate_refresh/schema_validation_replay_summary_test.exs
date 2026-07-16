defmodule OrbitalDynamics.CandidateRefresh.SchemaValidationReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

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
end
