Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyOperationalReadinessSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state operational-readiness reports into branch refresh requests" do
    readiness_report = fn prefix,
                          readiness_level,
                          import_classification,
                          status,
                          gate_classification ->
      %{
        "schema_contract" => "operational_readiness_report.v1",
        "schema_version" => 1,
        "model" => "OrbitalDynamics.OperationalReadiness.V1",
        "report_id" => "operational_readiness:planned_activity.v1:#{prefix}",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "#{prefix}_activity",
        "readiness_level" => readiness_level,
        "import_classification" => import_classification,
        "status" => status,
        "gate_count" => 1,
        "passed_gate_count" => 0,
        "review_gate_count" => if(gate_classification == "review_only", do: 1, else: 0),
        "analysis_gate_count" => if(gate_classification == "analysis_only", do: 1, else: 0),
        "blocked_gate_count" => if(gate_classification == "blocked", do: 1, else: 0),
        "gates" => [
          %{
            "id" => "#{prefix}_readiness_gate",
            "status" => status,
            "classification" => gate_classification,
            "reason" => "#{prefix} readiness requires branch-local review"
          }
        ],
        "evidence" => %{
          "manifest_review_required_count" => 1,
          "resource_availability_pressure_count" => 2,
          "resource_availability_reason_counts" => %{
            "ground_station_reserved" => 1,
            "payload_unavailable" => 1
          },
          "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
          "resource_blocking_dimension_counts" => %{"communications" => 1}
        },
        "assumptions" => %{},
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => "#{prefix}_operational_readiness_boundary"}
      }
    end

    direct_report =
      readiness_report.(
        "direct",
        "operator_review",
        "review_only",
        "review_required",
        "review_only"
      )

    canonical_report =
      readiness_report.(
        "canonical",
        "operator_review",
        "review_only",
        "review_required",
        "review_only"
      )

    source_wrapped_report =
      readiness_report.("source_wrapped", "blocked", "blocked", "blocked", "blocked")

    result_wrapped_report =
      readiness_report.(
        "result_wrapped",
        "analysis_only",
        "analysis_only",
        "analysis_only",
        "analysis_only"
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_operational_readiness_report", direct_report)
      |> Map.put("operational_readiness_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "operational_readiness_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_operational_readiness_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_operational_readiness_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_operational_readiness_boundary"}
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
          "mission_state.source_operational_readiness_report",
          "mission_state.operational_readiness_report",
          "mission_state.source_result_artifact.operational_readiness_report",
          "mission_state.result_artifact.source_operational_readiness_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_operational_readiness_readiness_level_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "operator_review" => 2
             },
             "source_report_operational_readiness_import_classification_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_only" => 2
             },
             "source_report_operational_readiness_status_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "review_required" => 2
             },
             "source_report_operational_readiness_gate_count" => 4,
             "source_report_operational_readiness_review_gate_count" => 2,
             "source_report_operational_readiness_analysis_gate_count" => 1,
             "source_report_operational_readiness_blocked_gate_count" => 1,
             "source_report_operational_readiness_manifest_review_required_count" => 4,
             "source_report_operational_readiness_resource_availability_reason_counts" => %{
               "ground_station_reserved" => 4,
               "payload_unavailable" => 4
             },
             "source_report_operational_readiness_station_availability_reason_counts" => %{
               "ground_station_reserved" => 4
             },
             "source_report_operational_readiness_resource_blocking_dimension_counts" => %{
               "communications" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "operational_readiness_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "readiness_level_counts" => %{
               "analysis_only" => 1,
               "blocked" => 1,
               "operator_review" => 2
             },
             "manifest_review_required_count" => 4,
             "resource_availability_pressure_count" => 8,
             "resource_availability_reason_counts" => %{
               "ground_station_reserved" => 4,
               "payload_unavailable" => 4
             },
             "station_availability_reason_counts" => %{"ground_station_reserved" => 4},
             "resource_blocking_dimension_counts" => %{"communications" => 4},
             "branch_local_review_pressure" => true,
             "branch_local_import_pressure" => true,
             "branch_local_resource_pressure" => true
           } = CandidateRefresh.operational_readiness_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.operational_readiness_report",
             "mission_state.result_artifact.source_operational_readiness_report",
             "mission_state.source_operational_readiness_report",
             "mission_state.source_result_artifact.operational_readiness_report"
           ]

    assert_operational_readiness_pressure_score_terms(urgent, artifact)

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "operational_readiness_pressure" in urgent_row["risk_types"]

    assert urgent_row["branch_operational_readiness_levels"] == [
             "analysis_only",
             "blocked",
             "operator_review"
           ]

    assert urgent_row["branch_operational_readiness_import_classifications"] == [
             "analysis_only",
             "blocked",
             "review_only"
           ]

    assert urgent_row["branch_operational_readiness_statuses"] == [
             "analysis_only",
             "blocked",
             "review_required"
           ]

    assert urgent_row["branch_operational_readiness_source_report_paths"] == [
             "mission_state.operational_readiness_report",
             "mission_state.result_artifact.source_operational_readiness_report",
             "mission_state.source_operational_readiness_report",
             "mission_state.source_result_artifact.operational_readiness_report"
           ]

    readiness_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(
        &(&1["review_type"] == "strategy_tradeoff" and &1["branch_id"] == "urgent" and
            &1["source"] == "campaign_strategy.branch_comparison_report.rows")
      )

    assert readiness_review_row["branch_operational_readiness_levels"] == [
             "analysis_only",
             "blocked",
             "operator_review"
           ]

    assert readiness_review_row["branch_operational_readiness_source_report_paths"] == [
             "mission_state.operational_readiness_report",
             "mission_state.result_artifact.source_operational_readiness_report",
             "mission_state.source_operational_readiness_report",
             "mission_state.source_result_artifact.operational_readiness_report"
           ]

    assert get_in(readiness_review_row, [
             "source_branch_comparison",
             "branch_operational_readiness_source_report_paths"
           ]) == [
             "mission_state.operational_readiness_report",
             "mission_state.result_artifact.source_operational_readiness_report",
             "mission_state.source_operational_readiness_report",
             "mission_state.source_result_artifact.operational_readiness_report"
           ]

    readiness_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(
        &(&1["source_review_type"] == "strategy_branch_comparison" and
            &1["branch_id"] == "urgent")
      )

    assert readiness_import_row["branch_operational_readiness_import_classifications"] == [
             "analysis_only",
             "blocked",
             "review_only"
           ]

    assert readiness_import_row["branch_operational_readiness_source_report_paths"] == [
             "mission_state.operational_readiness_report",
             "mission_state.result_artifact.source_operational_readiness_report",
             "mission_state.source_operational_readiness_report",
             "mission_state.source_result_artifact.operational_readiness_report"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

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

  defp resource_availability_source_report_pressure?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["readiness_gate_id"] == "resource_availability" or
      is_map(risk["resource_availability_reason_counts"]) or
      is_map(risk["unavailable_resource_reason_counts"]) or
      is_map(risk["blocked_contact_ids_by_blocking_dimension"])
  end

  defp resource_availability_source_report_pressure?(_risk), do: false

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
