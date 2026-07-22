Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyReadinessQualityGatePressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.OperationalReadiness.SourceIdentity
  alias OrbitalDynamics.Schema

  test "strategy derives branch refresh from mission-state operational readiness reports" do
    readiness_report =
      %{
        "schema_contract" => "operational_readiness_report.v1",
        "schema_version" => 1,
        "model" => "OrbitalDynamics.OperationalReadiness.V1",
        "report_id" => "operational_readiness:resource_projection_report.v1:live_ops",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "live_ops",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
        "gate_count" => 4,
        "passed_gate_count" => 1,
        "review_gate_count" => 3,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "gates" => [
          %{
            "id" => "resource_availability",
            "status" => "review_required",
            "classification" => "review_only",
            "reason" => "resource availability evidence requires operator review before import",
            "resource_availability_pressure_count" => 2,
            "resource_availability_reason_counts" => %{
              "antenna_unavailable" => 1,
              "payload_unavailable" => 1
            }
          }
        ],
        "evidence" => %{
          "resource_availability_pressure_count" => 2,
          "resource_availability_reason_counts" => %{
            "antenna_unavailable" => 1,
            "payload_unavailable" => 1
          }
        },
        "assumptions" => %{},
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
      branch(artifact, "derived_operational_readiness_pressure_resource_availability")

    assert %{
             "type" => "operational_readiness_pressure",
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "live_ops",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "operational_readiness_status" => "review_required",
             "readiness_gate_id" => "resource_availability",
             "readiness_gate_status" => "review_required",
             "readiness_gate_classification" => "review_only",
             "readiness_gate_reason" =>
               "resource availability evidence requires operator review before import",
             "required_operator_action" => "review_operational_readiness",
             "feedback_source" => "mission_state.source_operational_readiness_report.gates",
             "feedback_scope" => "operational_readiness",
             "trust_boundary" => "mission_state_operational_readiness_report",
             "source_operational_readiness_gate" => %{
               "id" => "resource_availability"
             },
             "source_operational_readiness_report" => %{
               "report_id" => "operational_readiness:resource_projection_report.v1:live_ops"
             }
           } = List.first(readiness_branch["events"])

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = readiness_branch["assumptions"]["candidate_source"]

    assert "mission_state.source_operational_readiness_report" in get_in(
             readiness_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert "mission_state.source_operational_readiness_report" in get_in(
             readiness_branch,
             [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_input_paths"
             ]
           )

    assert %{
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             }
           } = List.first(readiness_branch["events"])

    assert Enum.any?(
             readiness_branch["risk_indicators"],
             &(&1["type"] == "operational_readiness_pressure" and
                 &1["readiness_gate_id"] == "resource_availability" and
                 &1["resource_availability_pressure_count"] == 2)
           )

    assert_resource_availability_pressure_score_terms(readiness_branch, artifact)
    assert readiness_branch["score_terms"]["operational_readiness_pressure_penalty"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state operational readiness gate summaries" do
    gate_summary = fn prefix, trust_boundary ->
      readiness_report = %{
        "schema_contract" => "operational_readiness_report.v1",
        "model" => "OrbitalDynamics.OperationalReadiness.V1",
        "report_id" => "operational_readiness:planned_activity.v1:#{prefix}_activity",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "#{prefix}_activity",
        "readiness_level" => "blocked",
        "import_classification" => "blocked",
        "status" => "blocked",
        "gates" => [
          %{
            "id" => "source_contract",
            "status" => "passed",
            "classification" => "importable",
            "reason" => "source contract is valid"
          },
          %{
            "id" => "adapter_boundary",
            "status" => "passed",
            "classification" => "importable",
            "reason" => "adapter boundary is declared"
          },
          %{
            "id" => "operational_mode",
            "status" => "analysis_only",
            "classification" => "analysis_only",
            "reason" => "#{prefix} simulation mode is analysis-only",
            "analysis_mode" => "simulation",
            "analysis_mode_source" => "mission_state"
          },
          %{
            "id" => "operator_review",
            "status" => "review_required",
            "classification" => "review_only",
            "reason" => "#{prefix} requires operator review"
          },
          %{
            "id" => "cadence_import",
            "status" => "blocked",
            "classification" => "blocked",
            "reason" => "#{prefix} import blocked by policy"
          }
        ]
      }

      readiness_report
      |> OrbitalDynamics.OperationalReadiness.gate_summary()
      |> Map.put("provenance", %{"trust_boundary" => trust_boundary})
    end

    direct_summary = gate_summary.("direct_readiness_gate", "direct_readiness_gate_boundary")
    canonical_summary = gate_summary.("canonical_readiness_gate", "canonical_gate_boundary")

    wrapped_summary =
      gate_summary.("wrapped_readiness_gate", "wrapped_gate_source_boundary")
      |> Map.delete("provenance")

    assert {:ok, %{"schema_contract" => "operational_readiness_gate_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_operational_readiness_gate_summary", direct_summary)
      |> Map.put("operational_readiness_gate_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "operational_readiness_gate_summary" => wrapped_summary,
        "provenance" => %{"trust_boundary" => "wrapped_readiness_gate_artifact_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch =
      branch(
        artifact,
        "derived_operational_readiness_pressure_direct_readiness_gate_activity"
      )

    assert %{
             "type" => "operational_readiness_pressure",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "direct_readiness_gate_activity",
             "readiness_level" => "blocked",
             "import_classification" => "blocked",
             "operational_readiness_status" => "blocked",
             "review_required_gate_ids" => ["operator_review"],
             "analysis_only_gate_ids" => ["operational_mode"],
             "blocked_gate_ids" => ["cadence_import"],
             "non_passed_gate_ids" => ["operational_mode", "operator_review", "cadence_import"],
             "required_operator_action" => "review_blocked_operational_readiness",
             "feedback_source" => "mission_state.source_operational_readiness_gate_summary",
             "feedback_scope" => "operational_readiness",
             "trust_boundary" => "direct_readiness_gate_boundary",
             "assumptions" => %{
               "operator_authority" => "not_granted_by_summary"
             }
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "operational_readiness_pressure" and
                 &1["operational_readiness_status"] == "blocked" and
                 &1["trust_boundary"] == "direct_readiness_gate_boundary")
           )

    direct_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_operational_readiness_pressure_direct_readiness_gate_activity")
      )

    assert direct_row["branch_operational_readiness_levels"] == ["blocked"]
    assert direct_row["branch_operational_readiness_import_classifications"] == ["blocked"]
    assert direct_row["branch_operational_readiness_statuses"] == ["blocked"]

    assert direct_row["branch_operational_readiness_review_required_gate_ids"] == [
             "operator_review"
           ]

    assert direct_row["branch_operational_readiness_analysis_only_gate_ids"] == [
             "operational_mode"
           ]

    assert direct_row["branch_operational_readiness_blocked_gate_ids"] == ["cadence_import"]

    canonical_branch =
      branch(
        artifact,
        "derived_operational_readiness_pressure_canonical_readiness_gate_activity"
      )

    assert %{
             "source_artifact_id" => "canonical_readiness_gate_activity",
             "feedback_source" => "mission_state.operational_readiness_gate_summary",
             "trust_boundary" => "canonical_gate_boundary"
           } = List.first(canonical_branch["events"])

    wrapped_branch =
      branch(
        artifact,
        "derived_operational_readiness_pressure_wrapped_readiness_gate_activity"
      )

    assert %{
             "source_artifact_id" => "wrapped_readiness_gate_activity",
             "feedback_source" =>
               "mission_state.source_result_artifact.operational_readiness_gate_summary",
             "trust_boundary" => "wrapped_readiness_gate_artifact_boundary"
           } = List.first(wrapped_branch["events"])

    assert "mission_state.source_operational_readiness_gate_summary" in get_in(
             direct_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state quality gate reports" do
    quality_gate_report =
      passive_quality_gate_report()
      |> Map.merge(%{
        "report_id" => "quality_gate:resource_projection_report.v1:live_ops",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "live_ops",
        "source_readiness_report_id" =>
          "operational_readiness:resource_projection_report.v1:live_ops",
        "readiness_level" => "blocked",
        "import_classification" => "blocked",
        "status" => "blocked",
        "gate_count" => 99,
        "passed_gate_count" => 99,
        "review_gate_count" => 99,
        "analysis_gate_count" => 99,
        "blocked_gate_count" => 99,
        "provenance" => %{"trust_boundary" => "mission_state_quality_gate_report"}
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

    quality_gate_branch = branch(artifact, "derived_quality_gate_pressure_operator_review")

    assert %{
             "type" => "quality_gate_pressure",
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "live_ops",
             "source_readiness_report_id" =>
               "operational_readiness:resource_projection_report.v1:live_ops",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "quality_gate_status" => "review_required",
             "gate_count" => 1,
             "passed_gate_count" => 0,
             "review_gate_count" => 1,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "gate_id" => "operator_review",
             "gate_status" => "review_required",
             "gate_classification" => "review_only",
             "gate_reason" => "operator review required",
             "required_operator_action" => "review_operational_readiness",
             "feedback_source" => "mission_state.source_quality_gate_report.rows",
             "feedback_scope" => "quality_gate",
             "trust_boundary" => "mission_state_quality_gate_report",
             "source_quality_gate_row" => %{
               "gate_id" => "operator_review"
             },
             "source_quality_gate_report" => %{
               "report_id" => "quality_gate:resource_projection_report.v1:live_ops"
             }
           } = List.first(quality_gate_branch["events"])

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = quality_gate_branch["assumptions"]["candidate_source"]

    assert "mission_state.source_quality_gate_report" in get_in(
             quality_gate_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert "mission_state.source_quality_gate_report" in get_in(
             quality_gate_branch,
             [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_input_paths"
             ]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state quality gate summaries" do
    quality_gate_summary = fn prefix, status, classification ->
      gate_row_id = "quality_gate:#{prefix}:resource_availability:1"
      gate_id = "resource_availability"
      source_artifact_type = "resource_projection_report.v1"
      source_artifact_id = "#{prefix}_resource_projection"

      non_passed_row = %{
        "id" => gate_row_id,
        "rank" => 1,
        "gate_id" => gate_id,
        "status" => status,
        "classification" => classification,
        "reason" => "#{prefix} resource availability requires review",
        "resource_availability_pressure_count" => 1,
        "resource_availability_reason_counts" => %{"payload_unavailable" => 1},
        "resource_availability_reason_ids" => ["payload_unavailable"],
        "unavailable_resource_reason_ids" => ["payload_unavailable"],
        "resource_blocking_dimension_counts" => %{"payload" => 1}
      }

      execution_boundary =
        case classification do
          "blocked" -> "blocked_not_for_import_or_execution"
          "analysis_only" -> "analysis_only_not_for_execution"
          "review_only" -> "operator_review_required_before_import"
        end

      %{
        "schema_contract" => "operational_quality_gate_summary.v1",
        "model" => "artifact_only_quality_gate_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => source_artifact_type,
        "source_artifact_id" => source_artifact_id,
        "source_quality_gate_report_id" =>
          SourceIdentity.quality_gate_report_id(source_artifact_type, source_artifact_id),
        "source_readiness_report_id" =>
          SourceIdentity.readiness_report_id(source_artifact_type, source_artifact_id),
        "readiness_level" =>
          case classification do
            "blocked" -> "blocked"
            "analysis_only" -> "analysis_only"
            "review_only" -> "operator_review"
          end,
        "import_classification" => classification,
        "status" => status,
        "handoff_only" => true,
        "gate_count" => 1,
        "passed_gate_count" => 0,
        "review_gate_count" => if(status == "review_required", do: 1, else: 0),
        "analysis_gate_count" => if(status == "analysis_only", do: 1, else: 0),
        "blocked_gate_count" => if(status == "blocked", do: 1, else: 0),
        "non_passed_gate_count" => 1,
        "gate_status_counts" => %{status => 1},
        "gate_classification_counts" => %{classification => 1},
        "gate_ids_by_status" => %{status => [gate_id]},
        "gate_ids_by_classification" => %{classification => [gate_id]},
        "quality_gate_row_ids_by_status" => %{status => [gate_row_id]},
        "quality_gate_row_ids_by_classification" => %{classification => [gate_row_id]},
        "passed_gate_ids" => [],
        "review_required_gate_ids" => if(status == "review_required", do: [gate_id], else: []),
        "analysis_only_gate_ids" => if(status == "analysis_only", do: [gate_id], else: []),
        "blocked_gate_ids" => if(status == "blocked", do: [gate_id], else: []),
        "non_passed_gate_ids" => [gate_id],
        "non_passed_quality_gate_row_ids" => [gate_row_id],
        "non_passed_rows" => [non_passed_row],
        "rows" => [non_passed_row],
        "execution_boundary" => execution_boundary,
        "execution_allowed" => false,
        "cadence_write_allowed" => false,
        "operator_authority_granted" => false,
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_cadence_write",
          "operator_authority" => "not_granted_by_quality_gate_summary",
          "cadence_write" => "not_performed_by_summary",
          "command_execution" => "not_performed_by_summary",
          "source" => "quality_gate_report.v1"
        },
        "model_limits" => [
          "quality_gate_summary_derives_classification_from_gate_rows",
          "quality_gate_summary_does_not_approve_or_import"
        ],
        "provenance" => %{"trust_boundary" => "#{prefix}_quality_gate_summary_boundary"}
      }
    end

    direct_summary = quality_gate_summary.("direct", "review_required", "review_only")
    canonical_summary = quality_gate_summary.("canonical", "blocked", "blocked")
    wrapped_summary = quality_gate_summary.("wrapped", "analysis_only", "analysis_only")

    assert {:ok, %{"schema_contract" => "operational_quality_gate_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    assert {:ok, %{"schema_contract" => "operational_quality_gate_summary.v1"}} =
             Schema.validate_artifact(canonical_summary)

    assert {:ok, %{"schema_contract" => "operational_quality_gate_summary.v1"}} =
             Schema.validate_artifact(wrapped_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_operational_quality_gate_summary", direct_summary)
      |> Map.put("operational_quality_gate_summary", canonical_summary)
      |> Map.put("source_result_artifact", %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_operational_quality_gate_summary" => Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_quality_gate_summary_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch =
      Enum.find(artifact["branches"], fn branch ->
        Enum.any?(
          branch["events"] || [],
          &(&1["type"] == "quality_gate_pressure" and
              &1["source_artifact_id"] == "direct_resource_projection")
        )
      end)

    assert direct_branch

    assert %{
             "type" => "quality_gate_pressure",
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "direct_resource_projection",
             "source_readiness_report_id" =>
               "operational_readiness:resource_projection_report.v1:direct_resource_projection",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "quality_gate_status" => "review_required",
             "gate_count" => 1,
             "review_gate_count" => 1,
             "gate_id" => "resource_availability",
             "gate_status" => "review_required",
             "gate_classification" => "review_only",
             "gate_reason" => "direct resource availability requires review",
             "resource_availability_pressure_count" => 1,
             "resource_availability_reason_counts" => %{"payload_unavailable" => 1},
             "resource_availability_reason_ids" => ["payload_unavailable"],
             "unavailable_resource_reason_ids" => ["payload_unavailable"],
             "resource_blocking_dimension_counts" => %{"payload" => 1},
             "feedback_source" =>
               "mission_state.source_operational_quality_gate_summary.non_passed_rows",
             "feedback_scope" => "quality_gate",
             "trust_boundary" => "direct_quality_gate_summary_boundary",
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_quality_gate_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "source" => "quality_gate_report.v1"
             },
             "source_quality_gate_row" => %{"gate_id" => "resource_availability"},
             "source_quality_gate_report" => %{
               "schema_contract" => "operational_quality_gate_summary.v1"
             }
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "quality_gate_pressure" and
                 &1["source_artifact_id"] == "direct_resource_projection")
           )

    assert_resource_availability_pressure_score_terms(direct_branch, artifact)

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == direct_branch["branch_id"]))

    assert "quality_gate_pressure" in comparison_row["risk_types"]

    assert comparison_row["branch_feedback_sources"] == [
             "mission_state.source_operational_quality_gate_summary.non_passed_rows"
           ]

    assert Enum.any?(artifact["branches"], fn branch ->
             Enum.any?(
               branch["events"] || [],
               &(&1["type"] == "quality_gate_pressure" and
                   &1["source_artifact_id"] == "canonical_resource_projection")
             )
           end)

    assert Enum.any?(artifact["branches"], fn branch ->
             Enum.any?(
               branch["events"] || [],
               &(&1["type"] == "quality_gate_pressure" and
                   &1["source_artifact_id"] == "wrapped_resource_projection")
             )
           end)

    assert "mission_state.source_operational_quality_gate_summary" in get_in(
             direct_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state quality gate unavailable resource summaries" do
    unavailable_resource_summary = fn prefix, status, classification, reason_kind ->
      blocked_contact_id = "#{prefix}_dl_resource_blocked"
      source_artifact_type = "contact_allocation_report.v1"
      source_artifact_id = "#{prefix}_resource_projection"

      reason_id =
        case reason_kind do
          :station -> "ground_station_unavailable"
          :resource -> "antenna_unavailable"
        end

      unavailable_resource_reason_ids =
        case reason_kind do
          :station -> []
          :resource -> [reason_id]
        end

      resource_blocking_dimension_counts =
        case reason_kind do
          :station -> %{}
          :resource -> %{"antenna" => 1}
        end

      contact_ids_by_blocking_dimension =
        case reason_kind do
          :station -> %{}
          :resource -> %{"antenna" => [blocked_contact_id]}
        end

      quality_gate_report = %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" =>
          SourceIdentity.quality_gate_report_id(source_artifact_type, source_artifact_id),
        "source_artifact_type" => source_artifact_type,
        "source_artifact_id" => source_artifact_id,
        "source_readiness_report_id" =>
          SourceIdentity.readiness_report_id(source_artifact_type, source_artifact_id),
        "readiness_level" => if(status == "blocked", do: "blocked", else: "operator_review"),
        "import_classification" => classification,
        "status" => status,
        "gate_count" => 1,
        "passed_gate_count" => 0,
        "review_gate_count" => if(status == "review_required", do: 1, else: 0),
        "analysis_gate_count" => 0,
        "blocked_gate_count" => if(status == "blocked", do: 1, else: 0),
        "gate_status_counts" => %{status => 1},
        "gate_classification_counts" => %{classification => 1},
        "rows" => [
          %{
            "id" => "quality_gate:#{prefix}:resource_availability:1",
            "rank" => 1,
            "gate_id" => "resource_availability",
            "status" => status,
            "classification" => classification,
            "reason" => "#{prefix} unavailable antenna requires review",
            "resource_availability_pressure_count" => 1,
            "resource_availability_reason_counts" => %{reason_id => 1},
            "resource_availability_reason_ids" => [reason_id],
            "unavailable_resource_reason_ids" => unavailable_resource_reason_ids,
            "resource_blocking_dimension_counts" => resource_blocking_dimension_counts,
            "resource_blocked_contact_ids_by_blocking_dimension" =>
              contact_ids_by_blocking_dimension,
            "resource_blocked_contact_ids_by_spacecraft_id" => %{
              "sat_1" => [blocked_contact_id]
            }
          }
        ],
        "assumptions" => %{"source" => "test.quality_gate_report"},
        "model_limits" => ["artifact_only"]
      }

      quality_gate_report
      |> OrbitalDynamics.OperationalReadiness.quality_gate_unavailable_resource_summary()
      |> Map.put("provenance", %{
        "trust_boundary" => "#{prefix}_unavailable_resource_summary_boundary"
      })
    end

    direct_summary =
      unavailable_resource_summary.("direct", "review_required", "review_only", :resource)

    canonical_summary =
      unavailable_resource_summary.("canonical", "blocked", "blocked", :resource)

    wrapped_summary =
      unavailable_resource_summary.("wrapped", "analysis_only", "analysis_only", :station)

    assert {:ok,
            %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    assert {:ok,
            %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"}} =
             Schema.validate_artifact(canonical_summary)

    assert {:ok,
            %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"}} =
             Schema.validate_artifact(wrapped_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_operational_quality_gate_unavailable_resource_summary", direct_summary)
      |> Map.put("operational_quality_gate_unavailable_resource_summary", canonical_summary)
      |> Map.put("source_result_artifact", %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_operational_quality_gate_unavailable_resource_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_unavailable_resource_summary_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch =
      Enum.find(artifact["branches"], fn branch ->
        Enum.any?(
          branch["events"] || [],
          &(&1["type"] == "quality_gate_pressure" and
              &1["source_artifact_id"] == "direct_resource_projection")
        )
      end)

    assert direct_branch

    assert %{
             "type" => "quality_gate_pressure",
             "source_artifact_type" => "contact_allocation_report.v1",
             "source_artifact_id" => "direct_resource_projection",
             "source_readiness_report_id" =>
               "operational_readiness:contact_allocation_report.v1:direct_resource_projection",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "quality_gate_status" => "review_required",
             "gate_count" => 1,
             "review_gate_count" => 1,
             "blocked_gate_count" => 0,
             "gate_id" => "resource_availability",
             "gate_status" => "review_required",
             "gate_classification" => "review_only",
             "gate_reason" => "unavailable resource summary requires review",
             "resource_availability_pressure_count" => 1,
             "resource_availability_reason_counts" => %{"antenna_unavailable" => 1},
             "resource_availability_reason_ids" => ["antenna_unavailable"],
             "unavailable_resource_reason_counts" => %{"antenna_unavailable" => 1},
             "unavailable_resource_reason_ids" => ["antenna_unavailable"],
             "resource_blocking_dimension_counts" => %{"antenna" => 1},
             "blocked_contact_ids_by_blocking_dimension" => %{
               "antenna" => ["direct_dl_resource_blocked"]
             },
             "blocked_contact_ids_by_spacecraft_id" => %{
               "sat_1" => ["direct_dl_resource_blocked"]
             },
             "blocked_contact_ids_by_status" => %{
               "review_required" => ["direct_dl_resource_blocked"]
             },
             "feedback_source" =>
               "mission_state.source_operational_quality_gate_unavailable_resource_summary",
             "feedback_scope" => "quality_gate",
             "trust_boundary" => "direct_unavailable_resource_summary_boundary",
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_unavailable_resource_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "source" => "quality_gate_report.v1"
             },
             "source_quality_gate_row" => %{
               "gate_id" => "resource_availability",
               "review_required_quality_gate_row_ids" => [
                 "quality_gate:direct:resource_availability:1"
               ]
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"
             }
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "quality_gate_pressure" and
                 &1["unavailable_resource_reason_counts"] == %{"antenna_unavailable" => 1})
           )

    assert_resource_availability_pressure_score_terms(direct_branch, artifact)

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == direct_branch["branch_id"]))

    assert "quality_gate_pressure" in comparison_row["risk_types"]

    assert comparison_row["branch_feedback_sources"] == [
             "mission_state.source_operational_quality_gate_unavailable_resource_summary"
           ]

    assert Enum.any?(artifact["branches"], fn branch ->
             Enum.any?(
               branch["events"] || [],
               &(&1["type"] == "quality_gate_pressure" and
                   &1["source_artifact_id"] == "canonical_resource_projection" and
                   &1["gate_status"] == "blocked")
             )
           end)

    assert Enum.any?(artifact["branches"], fn branch ->
             Enum.any?(
               branch["events"] || [],
               &(&1["type"] == "quality_gate_pressure" and
                   &1["source_artifact_id"] == "wrapped_resource_projection" and
                   &1["trust_boundary"] == "wrapped_unavailable_resource_summary_boundary" and
                   &1["gate_status"] == "analysis_only" and
                   &1["analysis_gate_count"] == 1 and
                   &1["resource_availability_pressure_count"] == 1 and
                   &1["resource_availability_reason_counts"] == %{
                     "ground_station_unavailable" => 1
                   } and
                   &1["station_availability_reason_counts"] == %{
                     "ground_station_unavailable" => 1
                   } and
                   &1["unavailable_resource_reason_counts"] == %{})
             )
           end)

    assert "mission_state.source_operational_quality_gate_unavailable_resource_summary" in get_in(
             direct_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    stale_lineage_summary =
      Map.put(
        direct_summary,
        "source_quality_gate_report_id",
        "quality_gate:contact_allocation_report.v1:stale_resource_projection"
      )

    assert {:error, %{"errors" => stale_lineage_errors}} =
             Schema.validate_artifact(stale_lineage_summary)

    assert Enum.any?(
             stale_lineage_errors,
             &(&1["path"] == "$.source_quality_gate_report_id" and
                 &1["message"] == "must match source artifact identity")
           )

    stale_lineage_artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(
            "source_operational_quality_gate_unavailable_resource_summary",
            stale_lineage_summary
          ),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute Enum.any?(stale_lineage_artifact["branches"], fn branch ->
             Enum.any?(
               branch["events"] || [],
               &(&1["type"] == "quality_gate_pressure" and
                   &1["source_artifact_id"] == "direct_resource_projection")
             )
           end)
  end

  test "strategy derives branch refresh from mission-state quality gate operator training summaries" do
    operator_training_summary = fn prefix, status, classification ->
      source_artifact_type = "planned_activity.v1"
      source_artifact_id = "#{prefix}_activity"

      quality_gate_report = %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" =>
          SourceIdentity.quality_gate_report_id(source_artifact_type, source_artifact_id),
        "source_artifact_type" => source_artifact_type,
        "source_artifact_id" => source_artifact_id,
        "source_readiness_report_id" =>
          SourceIdentity.readiness_report_id(source_artifact_type, source_artifact_id),
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
        "gate_status_counts" => %{status => 1},
        "gate_classification_counts" => %{classification => 1},
        "rows" => [
          %{
            "id" => "quality_gate:#{prefix}:operator_training:1",
            "rank" => 1,
            "gate_id" => "operator_training",
            "status" => status,
            "classification" => classification,
            "reason" => "#{prefix} operator training requires review",
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
        "assumptions" => %{"source" => "test.quality_gate_report"},
        "model_limits" => ["artifact_only"]
      }

      quality_gate_report
      |> OrbitalDynamics.OperationalReadiness.quality_gate_operator_training_summary()
      |> Map.put("provenance", %{
        "trust_boundary" => "#{prefix}_operator_training_summary_boundary"
      })
    end

    direct_summary =
      operator_training_summary.("direct", "review_required", "review_only")

    canonical_summary = operator_training_summary.("canonical", "blocked", "blocked")
    wrapped_summary = operator_training_summary.("wrapped", "analysis_only", "analysis_only")

    assert {:ok, %{"schema_contract" => "operational_quality_gate_operator_training_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    assert {:ok, %{"schema_contract" => "operational_quality_gate_operator_training_summary.v1"}} =
             Schema.validate_artifact(canonical_summary)

    assert {:ok, %{"schema_contract" => "operational_quality_gate_operator_training_summary.v1"}} =
             Schema.validate_artifact(wrapped_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_operational_quality_gate_operator_training_summary", direct_summary)
      |> Map.put("operational_quality_gate_operator_training_summary", canonical_summary)
      |> Map.put("source_result_artifact", %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_operational_quality_gate_operator_training_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_operator_training_summary_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "direct_activity")
          )
      end)

    assert direct_branch

    assert %{
             "type" => "quality_gate_pressure",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "direct_activity",
             "source_readiness_report_id" =>
               "operational_readiness:planned_activity.v1:direct_activity",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "quality_gate_status" => "review_required",
             "gate_count" => 1,
             "review_gate_count" => 1,
             "gate_id" => "operator_training",
             "gate_status" => "review_required",
             "gate_classification" => "review_only",
             "gate_reason" => "operator training summary requires review",
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
             "feedback_source" =>
               "mission_state.source_operational_quality_gate_operator_training_summary",
             "feedback_scope" => "quality_gate",
             "trust_boundary" => "direct_operator_training_summary_boundary",
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_operator_training_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "source" => "quality_gate_report.v1"
             },
             "source_quality_gate_row" => %{
               "gate_id" => "operator_training",
               "review_required_quality_gate_row_ids" => [
                 "quality_gate:direct:operator_training:1"
               ]
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "operational_quality_gate_operator_training_summary.v1"
             }
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "quality_gate_pressure" and
                 &1["operator_training_requirement_count"] == 5 and
                 &1["required_operator_roles"] == [
                   "contact_operator",
                   "mission_director"
                 ] and
                 &1["required_training_ids"] == ["contact_replan_drill"] and
                 &1["required_certification_ids"] == ["cadence_import_cert"] and
                 &1["required_qualification_ids"] == ["sat_ops_current"])
           )

    assert_operator_training_pressure_score_terms(direct_branch, artifact)

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == direct_branch["branch_id"]))

    assert "quality_gate_pressure" in comparison_row["risk_types"]

    assert comparison_row["branch_feedback_sources"] == [
             "mission_state.source_operational_quality_gate_operator_training_summary"
           ]

    canonical_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "canonical_activity" and
                &1["gate_status"] == "blocked")
          )
      end)

    wrapped_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "wrapped_activity" and
                &1["trust_boundary"] == "wrapped_operator_training_summary_boundary" and
                &1["gate_status"] == "analysis_only" and
                &1["analysis_gate_count"] == 1)
          )
      end)

    assert canonical_branch
    assert wrapped_branch

    assert MapSet.size(
             MapSet.new([
               direct_branch["branch_id"],
               canonical_branch["branch_id"],
               wrapped_branch["branch_id"]
             ])
           ) == 3

    assert "mission_state.source_operational_quality_gate_operator_training_summary" in get_in(
             direct_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state quality gate schema validation summaries" do
    schema_validation_summary = fn prefix, status, classification, validation_status ->
      source_artifact_type = "planned_activity.v1"
      source_artifact_id = "#{prefix}_schema_payload"

      counts =
        case validation_status do
          "fail" -> %{"fail" => 1}
          "warning" -> %{"warning" => 1}
          "pass" -> %{"pass" => 1}
        end

      quality_gate_report = %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" =>
          SourceIdentity.quality_gate_report_id(source_artifact_type, source_artifact_id),
        "source_artifact_type" => source_artifact_type,
        "source_artifact_id" => source_artifact_id,
        "source_readiness_report_id" =>
          SourceIdentity.readiness_report_id(source_artifact_type, source_artifact_id),
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
        "gate_status_counts" => %{status => 1},
        "gate_classification_counts" => %{classification => 1},
        "rows" => [
          %{
            "id" => "quality_gate:#{prefix}:cadence_import:1",
            "rank" => 1,
            "gate_id" => "cadence_import",
            "status" => status,
            "classification" => classification,
            "reason" => "#{prefix} schema validation requires review",
            "schema_validation_pass_count" => if(validation_status == "pass", do: 1, else: 0),
            "schema_validation_fail_count" => if(validation_status == "fail", do: 1, else: 0),
            "schema_validation_error_count" => if(validation_status == "fail", do: 1, else: 0),
            "schema_validation_warning_count" =>
              if(validation_status == "warning", do: 1, else: 0),
            "schema_validation_remediation_count" =>
              if(validation_status == "fail", do: 1, else: 0),
            "schema_validation_status_counts" => counts
          }
        ],
        "assumptions" => %{"source" => "test.quality_gate_report"},
        "model_limits" => ["artifact_only"]
      }

      quality_gate_report
      |> OrbitalDynamics.OperationalReadiness.quality_gate_schema_validation_summary()
      |> Map.put("provenance", %{
        "trust_boundary" => "#{prefix}_schema_validation_summary_boundary"
      })
    end

    direct_summary =
      schema_validation_summary.("direct", "blocked", "blocked", "fail")

    canonical_summary =
      schema_validation_summary.("canonical", "review_required", "review_only", "warning")

    wrapped_summary =
      schema_validation_summary.("wrapped", "analysis_only", "analysis_only", "pass")

    assert {:ok, %{"schema_contract" => "operational_quality_gate_schema_validation_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    assert {:ok, %{"schema_contract" => "operational_quality_gate_schema_validation_summary.v1"}} =
             Schema.validate_artifact(canonical_summary)

    assert {:ok, %{"schema_contract" => "operational_quality_gate_schema_validation_summary.v1"}} =
             Schema.validate_artifact(wrapped_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_operational_quality_gate_schema_validation_summary", direct_summary)
      |> Map.put("operational_quality_gate_schema_validation_summary", canonical_summary)
      |> Map.put("source_result_artifact", %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_operational_quality_gate_schema_validation_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_schema_validation_summary_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "direct_schema_payload")
          )
      end)

    assert direct_branch

    assert %{
             "type" => "quality_gate_pressure",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "direct_schema_payload",
             "source_readiness_report_id" =>
               "operational_readiness:planned_activity.v1:direct_schema_payload",
             "readiness_level" => "blocked",
             "import_classification" => "blocked",
             "quality_gate_status" => "blocked",
             "gate_count" => 1,
             "blocked_gate_count" => 1,
             "gate_id" => "cadence_import",
             "gate_status" => "blocked",
             "gate_classification" => "blocked",
             "gate_reason" => "schema validation summary blocks import",
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
               "quality_gate:direct:cadence_import:1"
             ],
             "feedback_source" =>
               "mission_state.source_operational_quality_gate_schema_validation_summary",
             "feedback_scope" => "quality_gate",
             "trust_boundary" => "direct_schema_validation_summary_boundary",
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_schema_validation_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "source" => "quality_gate_report.v1"
             },
             "source_quality_gate_row" => %{
               "gate_id" => "cadence_import",
               "blocked_quality_gate_row_ids" => [
                 "quality_gate:direct:cadence_import:1"
               ]
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "operational_quality_gate_schema_validation_summary.v1"
             }
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "quality_gate_pressure" and
                 &1["schema_validation_import_blocked"] == true and
                 &1["schema_validation_status_counts"] == %{"fail" => 1} and
                 &1["failed_schema_validation_quality_gate_row_ids"] == [
                   "quality_gate:direct:cadence_import:1"
                 ])
           )

    assert_schema_validation_quality_gate_pressure_score_terms(direct_branch, artifact)

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == direct_branch["branch_id"]))

    assert "quality_gate_pressure" in comparison_row["risk_types"]

    assert comparison_row["branch_feedback_sources"] == [
             "mission_state.source_operational_quality_gate_schema_validation_summary"
           ]

    canonical_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "canonical_schema_payload" and
                &1["gate_status"] == "review_required" and
                &1["schema_validation_status_counts"] == %{"warning" => 1})
          )
      end)

    wrapped_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "wrapped_schema_payload" and
                &1["trust_boundary"] == "wrapped_schema_validation_summary_boundary" and
                &1["gate_status"] == "analysis_only" and
                &1["analysis_gate_count"] == 1)
          )
      end)

    assert canonical_branch
    assert wrapped_branch

    assert MapSet.size(
             MapSet.new([
               direct_branch["branch_id"],
               canonical_branch["branch_id"],
               wrapped_branch["branch_id"]
             ])
           ) == 3

    assert "mission_state.source_operational_quality_gate_schema_validation_summary" in get_in(
             direct_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state quality gate import readiness summaries" do
    import_readiness_summary = fn prefix,
                                  status,
                                  classification,
                                  freshness_status,
                                  import_status,
                                  cadence_status ->
      source_artifact_type = "planned_activity.v1"
      source_artifact_id = "#{prefix}_import_payload"
      freshness_counts = %{freshness_status => 1}
      import_counts = %{import_status => 1}
      cadence_counts = %{cadence_status => 1}

      quality_gate_report = %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" =>
          SourceIdentity.quality_gate_report_id(source_artifact_type, source_artifact_id),
        "source_artifact_type" => source_artifact_type,
        "source_artifact_id" => source_artifact_id,
        "source_readiness_report_id" =>
          SourceIdentity.readiness_report_id(source_artifact_type, source_artifact_id),
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
        "gate_status_counts" => %{status => 1},
        "gate_classification_counts" => %{classification => 1},
        "rows" => [
          %{
            "id" => "quality_gate:#{prefix}:cadence_import:1",
            "rank" => 1,
            "gate_id" => "cadence_import",
            "status" => status,
            "classification" => classification,
            "reason" => "#{prefix} import readiness requires review",
            "ready_for_import_count" => if(import_status == "ready_for_import", do: 1, else: 0),
            "manifest_review_required_count" =>
              if(import_status == "review_required_before_import", do: 1, else: 0),
            "blocked_import_count" =>
              if(import_status == "blocked_missing_cadence_import", do: 1, else: 0),
            "missing_import_count" => if(cadence_status == "missing", do: 1, else: 0),
            "invalid_cadence_import_count" => if(cadence_status == "invalid", do: 1, else: 0),
            "current_freshness_count" => if(freshness_status == "current", do: 1, else: 0),
            "stale_freshness_count" => if(freshness_status == "stale", do: 1, else: 0),
            "unknown_freshness_count" => if(freshness_status == "unknown", do: 1, else: 0),
            "freshness_status_counts" => freshness_counts,
            "import_status_counts" => import_counts,
            "cadence_import_status_counts" => cadence_counts
          }
        ],
        "assumptions" => %{"source" => "test.quality_gate_report"},
        "model_limits" => ["artifact_only"]
      }

      quality_gate_report
      |> OrbitalDynamics.OperationalReadiness.quality_gate_import_readiness_summary()
      |> Map.put("provenance", %{
        "trust_boundary" => "#{prefix}_import_readiness_summary_boundary"
      })
    end

    direct_summary =
      import_readiness_summary.(
        "direct",
        "blocked",
        "blocked",
        "stale",
        "blocked_missing_cadence_import",
        "invalid"
      )

    canonical_summary =
      import_readiness_summary.(
        "canonical",
        "review_required",
        "review_only",
        "unknown",
        "review_required_before_import",
        "present"
      )

    wrapped_summary =
      import_readiness_summary.(
        "wrapped",
        "analysis_only",
        "analysis_only",
        "current",
        "not_applicable",
        "not_applicable"
      )

    assert {:ok, %{"schema_contract" => "operational_quality_gate_import_readiness_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    assert {:ok, %{"schema_contract" => "operational_quality_gate_import_readiness_summary.v1"}} =
             Schema.validate_artifact(canonical_summary)

    assert {:ok, %{"schema_contract" => "operational_quality_gate_import_readiness_summary.v1"}} =
             Schema.validate_artifact(wrapped_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_operational_quality_gate_import_readiness_summary", direct_summary)
      |> Map.put("operational_quality_gate_import_readiness_summary", canonical_summary)
      |> Map.put("source_result_artifact", %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_operational_quality_gate_import_readiness_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_import_readiness_summary_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "direct_import_payload")
          )
      end)

    assert direct_branch

    assert %{
             "type" => "quality_gate_pressure",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "direct_import_payload",
             "source_readiness_report_id" =>
               "operational_readiness:planned_activity.v1:direct_import_payload",
             "readiness_level" => "blocked",
             "import_classification" => "blocked",
             "quality_gate_status" => "blocked",
             "gate_count" => 1,
             "blocked_gate_count" => 1,
             "gate_id" => "cadence_import",
             "gate_status" => "blocked",
             "gate_classification" => "blocked",
             "gate_reason" => "import readiness summary blocks import",
             "import_readiness_row_count" => 1,
             "ready_for_import_count" => 0,
             "manifest_review_required_count" => 0,
             "blocked_import_count" => 1,
             "missing_import_count" => 0,
             "invalid_cadence_import_count" => 1,
             "current_freshness_count" => 0,
             "stale_freshness_count" => 1,
             "unknown_freshness_count" => 0,
             "freshness_status_counts" => %{"stale" => 1},
             "freshness_status_ids" => ["stale"],
             "import_status_counts" => %{"blocked_missing_cadence_import" => 1},
             "import_status_ids" => ["blocked_missing_cadence_import"],
             "cadence_import_status_counts" => %{"invalid" => 1},
             "cadence_import_status_ids" => ["invalid"],
             "freshness_review_required" => true,
             "import_preparation_required" => false,
             "import_blocked" => true,
             "stale_or_unknown_freshness_quality_gate_row_ids" => [
               "quality_gate:direct:cadence_import:1"
             ],
             "import_preparation_quality_gate_row_ids" => [],
             "blocked_import_quality_gate_row_ids" => [
               "quality_gate:direct:cadence_import:1"
             ],
             "feedback_source" =>
               "mission_state.source_operational_quality_gate_import_readiness_summary",
             "feedback_scope" => "quality_gate",
             "trust_boundary" => "direct_import_readiness_summary_boundary",
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_import_readiness_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "source" => "quality_gate_report.v1"
             },
             "source_quality_gate_row" => %{
               "gate_id" => "cadence_import",
               "blocked_quality_gate_row_ids" => [
                 "quality_gate:direct:cadence_import:1"
               ],
               "blocked_import_quality_gate_row_ids" => [
                 "quality_gate:direct:cadence_import:1"
               ]
             },
             "source_quality_gate_report" => %{
               "schema_contract" => "operational_quality_gate_import_readiness_summary.v1"
             }
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "quality_gate_pressure" and
                 &1["import_blocked"] == true and
                 &1["freshness_review_required"] == true and
                 &1["import_status_counts"] == %{"blocked_missing_cadence_import" => 1} and
                 &1["blocked_import_quality_gate_row_ids"] == [
                   "quality_gate:direct:cadence_import:1"
                 ])
           )

    assert_import_readiness_pressure_score_terms(direct_branch, artifact)

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == direct_branch["branch_id"]))

    assert "quality_gate_pressure" in comparison_row["risk_types"]

    assert comparison_row["branch_feedback_sources"] == [
             "mission_state.source_operational_quality_gate_import_readiness_summary"
           ]

    canonical_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "canonical_import_payload" and
                &1["gate_status"] == "review_required" and
                &1["freshness_status_counts"] == %{"unknown" => 1} and
                &1["import_status_counts"] == %{"review_required_before_import" => 1} and
                &1["import_preparation_required"] == true)
          )
      end)

    wrapped_branch =
      Enum.find(artifact["branches"], fn branch ->
        String.starts_with?(branch["branch_id"], "derived_quality_gate_pressure_") and
          Enum.any?(
            branch["events"] || [],
            &(&1["type"] == "quality_gate_pressure" and
                &1["source_artifact_id"] == "wrapped_import_payload" and
                &1["trust_boundary"] == "wrapped_import_readiness_summary_boundary" and
                &1["gate_status"] == "analysis_only" and
                &1["analysis_gate_count"] == 1 and
                &1["import_status_counts"] == %{"not_applicable" => 1})
          )
      end)

    assert canonical_branch
    assert wrapped_branch

    assert MapSet.size(
             MapSet.new([
               direct_branch["branch_id"],
               canonical_branch["branch_id"],
               wrapped_branch["branch_id"]
             ])
           ) == 3

    assert "mission_state.source_operational_quality_gate_import_readiness_summary" in get_in(
             direct_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

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

  defp assert_schema_validation_quality_gate_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    schema_validation_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "quality_gate_pressure" and
            (&1["schema_validation_import_blocked"] == true or
               is_map(&1["schema_validation_status_counts"])))
      )

    assert schema_validation_pressure_count > 0

    assert branch["score_terms"]["validation_refresh_pressure_penalty"] ==
             -schema_validation_pressure_count * risk_weight

    assert branch["score_terms"]["quality_gate_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - schema_validation_pressure_count) *
               risk_weight

    assert "validation_refresh_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "validation_refresh_pressure_penalty" and &1["value"] < 0.0)
           )
  end

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
end
