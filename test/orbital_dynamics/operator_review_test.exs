defmodule OrbitalDynamics.OperatorReviewTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Policy, Schema, Timeline}

  test "declares artifact-only operator review capabilities" do
    assert %{
             artifact_contract: "operator_review_package.v1",
             validation_level: :artifact_contract,
             review_types: review_types,
             source_artifact_types: source_artifact_types,
             provider_result_map_value_keys: provider_result_map_value_keys,
             handoff_row_semantics: handoff_row_semantics,
             known_limits: known_limits
           } = OperatorReview.capabilities()

    assert "result_artifact.v1" in source_artifact_types
    assert "operator_review_package.v1" in source_artifact_types
    assert "campaign_repair.v2" in source_artifact_types
    assert "contact_contention_recommendation" in review_types
    assert "contact_contention_review" in review_types
    assert "operational_timeline_review" in review_types
    assert "command_window_review" in review_types
    assert "station_calendar_review" in review_types
    assert "station_reservation_review" in review_types
    assert "link_capacity_review" in review_types
    assert "contact_intent_review" in review_types
    assert "candidate_rejection_review" in review_types
    assert "candidate_diff_review" in review_types
    assert "freshness_review" in review_types
    assert "refresh_budget_review" in review_types
    assert "model_acceptance_review" in review_types
    assert "validation_safety_case_review" in review_types
    assert "realized_feedback" in review_types
    assert "plan_delta_review" in review_types
    assert "approval_requirement" in review_types
    assert "policy_escalation" in review_types
    assert "resource_projection_review" in review_types
    assert "contact_suppression" in review_types
    assert "resource_suppression" in review_types
    assert "timeline_diff_review" in review_types
    assert "timeline_dependency_impact_review" in review_types
    assert "timeline_publication_review" in review_types
    assert "timeline_activity_precondition_review" in review_types
    assert "timeline_lifecycle_state_review" in review_types
    assert "timeline_activity_state.v1" in source_artifact_types
    assert "maneuver_review" in review_types
    assert "risk_explanation" in review_types
    assert "strategy_tradeoff" in review_types
    assert "score_term_review" in review_types
    assert "objective_tradeoff_review" in review_types
    assert "ranking_comparison_review" in review_types
    assert "pareto_frontier_review" in review_types
    assert "constraint_review" in review_types
    assert "objective_satisfaction_review" in review_types
    assert "schema_validation_review" in review_types
    assert "execution_review" in review_types
    assert "operational_readiness_review" in review_types
    assert "quality_gate_review" in review_types
    assert "resource_projection_flow_summary.v1" in source_artifact_types
    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys
    assert :schema_validation_review_rows in handoff_row_semantics
    assert :schema_validation_issue_context in handoff_row_semantics
    assert :schema_validation_batch_nested_report_context in handoff_row_semantics
    assert :operational_readiness_summary_rows in handoff_row_semantics
    assert :operational_readiness_gate_rows in handoff_row_semantics
    assert :operational_readiness_resource_summary_context in handoff_row_semantics
    assert :operational_readiness_resource_gate_context in handoff_row_semantics
    assert :operational_readiness_adapter_boundary_context in handoff_row_semantics
    assert :operational_readiness_cadence_import_gate_context in handoff_row_semantics
    assert :quality_gate_review_rows in handoff_row_semantics
    assert :quality_gate_resource_row_context in handoff_row_semantics
    assert :link_capacity_count_handoff_consistency in handoff_row_semantics
    assert :contact_allocation_handoff_consistency in handoff_row_semantics
    assert :command_window_source_handoff_consistency in handoff_row_semantics
    assert :provider_counteroffer_source_handoff_consistency in handoff_row_semantics
    assert :contact_intent_source_handoff_consistency in handoff_row_semantics
    assert :station_calendar_source_handoff_consistency in handoff_row_semantics
    assert :provider_calendar_contention_source_handoff_consistency in handoff_row_semantics
    assert :link_capacity_source_handoff_consistency in handoff_row_semantics
    assert :contact_allocation_source_handoff_consistency in handoff_row_semantics
    assert :contact_allocation_capacity_pack_source_handoff_consistency in handoff_row_semantics
    assert :contact_contention_source_handoff_consistency in handoff_row_semantics
    assert :suppression_source_handoff_consistency in handoff_row_semantics
    assert "candidate_rejection_report.v1" in source_artifact_types
    assert "station_reservation_report.v1" in source_artifact_types
    assert "operational_readiness_report.v1" in source_artifact_types
    assert "quality_gate_report.v1" in source_artifact_types
    assert "timeline_diff_summary.v1" in source_artifact_types
    assert "timeline_dependency_impact_summary.v1" in source_artifact_types
    assert "timeline_publication_summary.v1" in source_artifact_types
    assert "timeline_activity_precondition_summary.v1" in source_artifact_types
    assert "timeline_activity_status_state.v1" in source_artifact_types
    assert "timeline_activity_approval_state.v1" in source_artifact_types
    assert "timeline_activity_lifecycle_state.v1" in source_artifact_types
    assert "timeline_lifecycle_state_summary.v1" in source_artifact_types
    assert "timeline_preservation_report.v1" in source_artifact_types
    assert "timeline_preservation_status.v1" in source_artifact_types
    assert "timeline_integrity_report.v1" in source_artifact_types
    assert "timeline_transition_application_summary.v1" in source_artifact_types
    assert "timeline_integrity_review" in review_types
    assert :timeline_diff_summary_review_rows in handoff_row_semantics
    assert :timeline_diff_summary_source_handoff_consistency in handoff_row_semantics
    assert :timeline_dependency_impact_review_rows in handoff_row_semantics
    assert :timeline_dependency_impact_source_handoff_consistency in handoff_row_semantics
    assert :timeline_publication_review_rows in handoff_row_semantics
    assert :timeline_publication_source_handoff_consistency in handoff_row_semantics
    assert :timeline_activity_precondition_review_rows in handoff_row_semantics
    assert :timeline_activity_precondition_source_handoff_consistency in handoff_row_semantics
    assert :timeline_lifecycle_state_review_rows in handoff_row_semantics
    assert :timeline_lifecycle_state_source_handoff_consistency in handoff_row_semantics
    assert :timeline_preservation_review_rows in handoff_row_semantics
    assert :timeline_preservation_source_handoff_consistency in handoff_row_semantics
    assert :timeline_integrity_review_rows in handoff_row_semantics
    assert :timeline_integrity_source_handoff_consistency in handoff_row_semantics
    assert :timeline_transition_application_summary_review_rows in handoff_row_semantics

    assert :timeline_transition_application_summary_source_handoff_consistency in handoff_row_semantics

    assert :no_command_execution in known_limits
    assert :no_external_import in known_limits

    assert {:ok, schema} = Schema.json_schema("operator_review_package.v1")

    schema_review_types =
      get_in(schema, ["properties", "rows", "items", "properties", "review_type", "enum"])

    assert MapSet.new(review_types) == MapSet.new(schema_review_types)

    schema_source_artifact_types =
      get_in(schema, ["properties", "source_artifact_type", "enum"])

    assert MapSet.new(source_artifact_types) == MapSet.new(schema_source_artifact_types)

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_operator_review_package"
  end

  test "rejects unsupported review package source artifact types" do
    package =
      OperatorReview.from_constraint_report(constraint_report())
      |> Map.put("source_artifact_type", "provider_custom.v1")

    assert {:error, report} = Schema.validate_artifact(package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.source_artifact_type" and &1["message"] =~ "must be one of")
           )
  end

  test "rejects stale operator review package model identifiers" do
    package =
      OperatorReview.from_constraint_report(constraint_report())
      |> Map.put("model", "stale_operator_review_model")

    assert {:error, report} = Schema.validate_artifact(package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"artifact_only_operator_review_package\"")
           )
  end

  test "public facade rejects unsupported operator review inputs with boundary errors" do
    package = OperatorReview.from_constraint_report(constraint_report())

    assert OrbitalDynamics.operator_review_package(package) == package

    assert OrbitalDynamics.operator_review_package(%{
             schema_contract: "operator_review_package.v1",
             source_artifact_type: "constraint_report.v1",
             source_artifact_id: "constraint_report:test",
             rows: []
           }) == %{
             "schema_contract" => "operator_review_package.v1",
             "source_artifact_type" => "constraint_report.v1",
             "source_artifact_id" => "constraint_report:test",
             "rows" => []
           }

    assert_raise ArgumentError,
                 ~r/unsupported operator review artifact contract "unknown_contract.v1"/,
                 fn ->
                   OrbitalDynamics.operator_review_package(%{
                     "schema_contract" => "unknown_contract.v1"
                   })
                 end

    assert_raise ArgumentError,
                 ~r/supported contracts: .*campaign_plan\.v1.*execution_report\.v1/s,
                 fn ->
                   OrbitalDynamics.operator_review_package(%{schema_contract: :unknown_contract})
                 end

    assert_raise ArgumentError, ~r/operator review artifact must be a map/, fn ->
      OrbitalDynamics.operator_review_package(:not_an_artifact)
    end
  end

  test "builds operational readiness summary rows with top-level resource reason context" do
    report = operational_readiness_resource_report()
    package = OperatorReview.from_operational_readiness_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "operational_readiness_report.v1",
             "source_artifact_id" => "operational_readiness:resource_pressure",
             "review_count" => 2,
             "operational_readiness_review_count" => 2,
             "source_readiness_report_id" => "operational_readiness:resource_pressure",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "gate_count" => 1,
             "passed_gate_count" => 0,
             "review_gate_count" => 1,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0
           } = package

    summary_row =
      Enum.find(
        package["rows"],
        &(&1["subject_id"] == "operational_readiness:resource_pressure")
      )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "operational_readiness_report",
             "required_operator_action" => "review_operational_readiness",
             "resource_availability_pressure_count" => 3,
             "resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "ground_station_reserved" => 1,
               "payload_unavailable" => 1
             },
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "ground_station_reserved",
               "payload_unavailable"
             ],
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "resource_blocking_dimension_counts" => %{"communications" => 2},
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_report.v1",
               "report_id" => "operational_readiness:resource_pressure"
             }
           } = summary_row

    assert %{
             "readiness_gate_id" => "resource_availability",
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ]
           } =
             Enum.find(
               package["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_operational_readiness_report" => source_report} = row ->
            Map.put(
              row,
              "source_operational_readiness_report",
              Map.put(source_report, "report_id", "operational readiness with spaces")
            )

          row ->
            row
        end)
      end)

    assert {:error, invalid_source_evidence_report} =
             Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             invalid_source_evidence_report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_readiness_report.report_id")
           )

    stale_source_report =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{
            "subject_id" => "operational_readiness:resource_pressure",
            "source_operational_readiness_report" => %{} = source_report
          } = row ->
            Map.put(
              row,
              "source_operational_readiness_report",
              Map.put(source_report, "status", "passed")
            )

          row ->
            row
        end)
      end)

    assert {:error, stale_source_report_result} = Schema.validate_artifact(stale_source_report)

    assert Enum.any?(
             stale_source_report_result["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_operational_readiness_report.status" and
                 &1["message"] ==
                   "must match operational_readiness_status on handoff row")
           )
  end

  test "operational readiness analysis-only rows preserve not-for-execution context" do
    report = analysis_only_operational_readiness_report()
    package = OperatorReview.from_operational_readiness_report(report)

    assert %{
             "source_artifact_type" => "operational_readiness_report.v1",
             "source_artifact_id" => "operational_readiness:resource_pressure",
             "review_count" => 2,
             "operational_readiness_review_count" => 2,
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "analysis_gate_count" => 1,
             "review_gate_count" => 0
           } = package

    summary_row =
      Enum.find(
        package["rows"],
        &(&1["subject_id"] == "operational_readiness:resource_pressure")
      )

    assert %{
             "required_operator_action" => "record_operational_readiness_analysis_only",
             "approval_status" => "not_required",
             "cadence_import_status" => "not_applicable",
             "operational_readiness_status" => "analysis_only",
             "source_operational_readiness_report" => %{
               "assumptions" => %{"not_for_execution" => true},
               "model_limits" => ["artifact_only", "does_not_write_cadence"]
             }
           } = summary_row

    assert %{
             "required_operator_action" => "record_operational_readiness_analysis_only",
             "approval_status" => "not_required",
             "cadence_import_status" => "not_applicable",
             "readiness_gate_status" => "analysis_only",
             "readiness_gate_classification" => "analysis_only",
             "analysis_mode" => "not_for_execution",
             "source_operational_readiness_gate" => %{
               "analysis_mode" => "not_for_execution"
             },
             "source_operational_readiness_report" => %{
               "assumptions" => %{"not_for_execution" => true}
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds quality gate review rows with resource reason context" do
    report =
      operational_readiness_resource_report()
      |> OrbitalDynamics.operational_quality_gate_report()

    package = OperatorReview.from_quality_gate_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "quality_gate_report.v1",
             "source_artifact_id" =>
               "quality_gate:planned_activity.v1:activity_resource_pressure",
             "review_count" => 1,
             "quality_gate_review_count" => 1,
             "review_type_counts" => %{"quality_gate_review" => 1},
             "source_readiness_report_id" => "operational_readiness:resource_pressure",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "gate_count" => 1,
             "passed_gate_count" => 0,
             "review_gate_count" => 1,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "gate_status_counts" => %{"review_required" => 1},
             "gate_classification_counts" => %{"review_only" => 1}
           } = package

    assert package["gate_ids_by_status"] == report["gate_ids_by_status"]
    assert package["gate_ids_by_classification"] == report["gate_ids_by_classification"]
    assert package["quality_gate_row_ids_by_status"] == report["quality_gate_row_ids_by_status"]

    assert package["quality_gate_row_ids_by_classification"] ==
             report["quality_gate_row_ids_by_classification"]

    assert package["review_required_gate_ids"] == report["review_required_gate_ids"]

    assert [
             %{
               "review_type" => "quality_gate_review",
               "source" => "quality_gate_report.rows",
               "required_operator_action" => "review_quality_gate",
               "quality_gate_id" => "resource_availability",
               "quality_gate_status" => "review_required",
               "quality_gate_classification" => "review_only",
               "readiness_gate_id" => "resource_availability",
               "resource_availability_pressure_count" => 3,
               "resource_availability_reason_counts" => %{
                 "antenna_unavailable" => 1,
                 "ground_station_reserved" => 1,
                 "payload_unavailable" => 1
               },
               "resource_availability_reason_ids" => [
                 "antenna_unavailable",
                 "ground_station_reserved",
                 "payload_unavailable"
               ],
               "station_availability_reason_ids" => ["ground_station_reserved"],
               "unavailable_resource_reason_ids" => [
                 "antenna_unavailable",
                 "payload_unavailable"
               ],
               "source_quality_gate_row" => %{
                 "gate_id" => "resource_availability",
                 "resource_availability_reason_ids" => [
                   "antenna_unavailable",
                   "ground_station_reserved",
                   "payload_unavailable"
                 ]
               },
               "source_quality_gate_report" => %{
                 "schema_contract" => "quality_gate_report.v1",
                 "source_artifact_type" => "planned_activity.v1"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_quality_gate_report" => source_report} = row ->
            Map.put(
              row,
              "source_quality_gate_report",
              Map.put(source_report, "report_id", "quality gate with spaces")
            )

          row ->
            row
        end)
      end)

    assert {:error, invalid_source_evidence_report} =
             Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             invalid_source_evidence_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.report_id")
           )

    stale_source_report =
      update_in(package, ["rows", Access.at(0), "source_quality_gate_report"], fn report ->
        Map.put(report, "readiness_level", "blocked")
      end)

    assert {:error, stale_source_report_result} = Schema.validate_artifact(stale_source_report)

    assert Enum.any?(
             stale_source_report_result["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.readiness_level" and
                 &1["message"] == "must match readiness_level on handoff row")
           )

    stale_source_quality_gate =
      update_in(package, ["rows", Access.at(0), "source_quality_gate_row"], fn row ->
        Map.put(row, "classification", "blocked")
      end)

    assert {:error, stale_source_quality_gate_report} =
             Schema.validate_artifact(stale_source_quality_gate)

    assert Enum.any?(
             stale_source_quality_gate_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_row.classification" and
                 &1["message"] == "must match quality_gate_classification on handoff row")
           )

    stale_source_quality_gate_resource_context =
      update_in(package, ["rows", Access.at(0), "source_quality_gate_row"], fn row ->
        row
        |> Map.put("resource_availability_reason_counts", %{"ground_station_unavailable" => 1})
        |> Map.put("station_availability_reason_ids", ["ground_station_unavailable"])
        |> Map.put("unavailable_resource_reason_ids", [])
      end)

    assert {:error, stale_source_quality_gate_resource_context_report} =
             Schema.validate_artifact(stale_source_quality_gate_resource_context)

    assert Enum.any?(
             stale_source_quality_gate_resource_context_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_quality_gate_row.resource_availability_reason_counts" and
                 &1["message"] ==
                   "must match resource_availability_reason_counts on handoff row")
           )

    assert Enum.any?(
             stale_source_quality_gate_resource_context_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_quality_gate_row.station_availability_reason_ids" and
                 &1["message"] == "must match station_availability_reason_ids on handoff row")
           )
  end

  test "quality gate review rows preserve import readiness context" do
    report = stale_import_readiness_quality_gate_report()
    source_row = Enum.find(report["rows"], &(&1["gate_id"] == "cadence_import"))

    package = OperatorReview.from_quality_gate_report(report)

    assert [
             %{
               "review_type" => "quality_gate_review",
               "required_operator_action" => "review_quality_gate",
               "approval_status" => "operator_review_required",
               "cadence_import_status" => "present",
               "quality_gate_id" => "cadence_import",
               "quality_gate_status" => "review_required",
               "quality_gate_classification" => "review_only",
               "ready_for_import_count" => 1,
               "manifest_review_required_count" => 0,
               "blocked_import_count" => 0,
               "missing_import_count" => 0,
               "invalid_cadence_import_count" => 0,
               "current_freshness_count" => 0,
               "stale_freshness_count" => 1,
               "unknown_freshness_count" => 0,
               "freshness_status_counts" => %{"stale" => 1},
               "schema_validation_pass_count" => 1,
               "schema_validation_fail_count" => 0,
               "schema_validation_status_counts" => %{"pass" => 1},
               "import_status_counts" => %{"ready_for_import" => 1},
               "cadence_import_status_counts" => %{"present" => 1},
               "source_quality_gate_row" => ^source_row
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "quality gate analysis-only rows remain not-required handoffs" do
    report = analysis_only_quality_gate_report()
    package = OperatorReview.from_quality_gate_report(report)

    assert %{
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "analysis_gate_count" => 1,
             "review_gate_count" => 0,
             "quality_gate_review_count" => 1,
             "review_type_counts" => %{"quality_gate_review" => 1}
           } = package

    assert [
             %{
               "review_type" => "quality_gate_review",
               "required_operator_action" => "record_quality_gate_analysis_only",
               "action" => "record_quality_gate_analysis_only",
               "approval_status" => "not_required",
               "cadence_import_status" => "not_applicable",
               "quality_gate_id" => "resource_availability",
               "quality_gate_status" => "analysis_only",
               "quality_gate_classification" => "analysis_only",
               "source_quality_gate_row" => %{
                 "status" => "analysis_only",
                 "classification" => "analysis_only"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from failing and warning constraint report rows" do
    report = constraint_report()

    package = OperatorReview.from_constraint_report(report)

    assert OrbitalDynamics.operator_review_package(
             %{schema_contract: "constraint_report.v1"}
             |> Map.merge(report)
           ) ==
             package

    assert %{
             "source_artifact_type" => "constraint_report.v1",
             "source_artifact_id" => "constraint_report:study_metadata.constraints",
             "review_count" => 2,
             "constraint_review_count" => 2,
             "review_type_counts" => %{"constraint_review" => 2},
             "review_queue_counts" => %{
               "constraint_review|review_constraint|operator_review_required" => 2
             }
           } = package

    assert Enum.map(package["rows"], & &1["constraint_status"]) == ["fail", "warning"]

    assert %{
             "review_type" => "constraint_review",
             "source" => "constraint_report.rows",
             "subject_id" => "dispersion_2",
             "scenario_id" => "dispersion_2",
             "constraint_id" => "minimum_operational_altitude",
             "metric" => "min_altitude_km",
             "operator" => ">=",
             "threshold" => 621.5,
             "value" => 621.19,
             "score" => -0.31,
             "constraint_status" => "fail",
             "required_operator_action" => "review_constraint",
             "action" => "review_constraint",
             "review_queue" => "review_constraint",
             "review_queue_key" => "constraint_review|review_constraint|operator_review_required",
             "reason" =>
               "review fail constraint minimum_operational_altitude for dispersion_2: min_altitude_km >= 621.5",
             "source_constraint_row" => %{"status" => "fail"}
           } = List.first(package["rows"])

    refute Enum.any?(package["rows"], &(&1["constraint_status"] == "pass"))

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      put_in(package, ["rows", Access.at(0), "source_constraint_row", "status"], "warning")

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].constraint_status" and
                 &1["message"] == "must match source_constraint_row.status")
           )
  end

  test "builds review package from unmet objective satisfaction rows" do
    report = objective_satisfaction_report()

    package = OperatorReview.from_objective_satisfaction_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "objective_satisfaction_report.v1",
             "source_artifact_id" => "campaign_plan.activities",
             "review_count" => 3,
             "objective_satisfaction_review_count" => 3,
             "review_type_counts" => %{"objective_satisfaction_review" => 3}
           } = package

    assert Enum.map(package["rows"], & &1["objective_status"]) == [
             "partial",
             "unmet",
             "no_candidate_window"
           ]

    assert %{
             "review_type" => "objective_satisfaction_review",
             "subject_id" => "objective:target_coverage",
             "objective" => "target_coverage",
             "objective_status" => "partial",
             "required_count" => 2,
             "candidate_count" => 1,
             "selected_count" => 1,
             "satisfied_count" => 1,
             "candidate_target_ids" => ["target_a"],
             "selected_target_ids" => ["target_a"],
             "required_operator_action" => "review_objective_satisfaction",
             "reason" => "review partial objective target_coverage for objective:target_coverage",
             "source_objective_satisfaction" => %{"status" => "partial"}
           } = List.first(package["rows"])

    refute Enum.any?(package["rows"], &(&1["objective_status"] == "selected"))

    assert {:ok, %{"schema_contract" => "objective_satisfaction_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      put_in(
        package,
        ["rows", Access.at(0), "source_objective_satisfaction", "status"],
        "unmet"
      )

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].objective_status" and
                 &1["message"] == "must match source_objective_satisfaction.status")
           )
  end

  test "builds review package from score term report rows" do
    report = score_term_report()

    package = OperatorReview.from_score_term_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "score_term_report.v1",
             "source_artifact_id" => "campaign_plan.score_terms",
             "review_count" => 2,
             "score_term_review_count" => 2,
             "review_type_counts" => %{"score_term_review" => 2}
           } = package

    assert %{
             "review_type" => "score_term_review",
             "source" => "score_term_report.rows",
             "subject_id" => "score_term:leo_1:1:target_value",
             "scenario_id" => "leo_1",
             "term_key" => "target_value",
             "value" => 120.0,
             "timeline_score" => 140.0,
             "selected" => true,
             "required_operator_action" => "review_score_term",
             "reason" => "review score term target_value for leo_1: value 120.0",
             "source_score_term" => %{"term_key" => "target_value"}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "score_term_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      put_in(package, ["rows", Access.at(0), "source_score_term", "value"], 121.0)

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].value" and
                 &1["message"] == "must match source_score_term.value")
           )
  end

  test "builds review package from objective tradeoff report rows" do
    report = objective_tradeoff_report()

    package = OperatorReview.from_objective_tradeoff_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "objective_tradeoff_report.v1",
             "source_artifact_id" => "objective_tradeoff_report",
             "review_count" => 2,
             "objective_tradeoff_review_count" => 2,
             "review_type_counts" => %{"objective_tradeoff_review" => 2}
           } = package

    assert %{
             "review_type" => "objective_tradeoff_review",
             "source" => "objective_tradeoff_report.tradeoffs",
             "subject_id" => "leo_2",
             "scenario_id" => "leo_2",
             "score" => 95.0,
             "score_delta_from_selected" => -45.0,
             "activity_count" => 1,
             "score_terms" => %{"target_value" => 100.0, "activity_count_penalty" => -5.0},
             "activity_ids" => ["leo_2_observe_target_b_1"],
             "required_operator_action" => "review_objective_tradeoff",
             "reason" => "review objective tradeoff for leo_2: score delta -45.0",
             "source_objective_tradeoff" => %{"scenario_id" => "leo_2"}
           } = List.last(package["rows"])

    assert {:ok, %{"schema_contract" => "objective_tradeoff_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      put_in(
        package,
        ["rows", Access.at(1), "source_objective_tradeoff", "score"],
        96.0
      )

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[1].score" and
                 &1["message"] == "must match source_objective_tradeoff.score")
           )
  end

  test "builds review package from schema validation report failures" do
    report = schema_validation_report()

    package = OperatorReview.from_schema_validation_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "schema_validation_report.v1",
             "source_artifact_id" => "schema_validation:campaign_plan.v1:artifact_file:fail",
             "review_count" => 1,
             "schema_validation_review_count" => 1
           } = package

    assert [
             %{
               "id" => id,
               "review_type" => "schema_validation_review",
               "source" => "schema_validation_report.errors",
               "subject_id" => "campaign_plan.v1",
               "required_operator_action" => "review_schema_validation",
               "action" => "review_schema_validation_failure",
               "validation_status" => "fail",
               "validation_mode" => "artifact_file",
               "validated_contract" => "campaign_plan.v1",
               "artifact_path" => "study_results/bad_campaign.json",
               "issue_severity" => "error",
               "issue_path" => "$.plan_id",
               "issue_message" => "is required",
               "remediation_category" => "missing_required_field",
               "remediation_action" => "Populate this required field",
               "source_validation_issue" => %{"path" => "$.plan_id", "message" => "is required"},
               "source_validation_remediation" => %{
                 "path" => "$.plan_id",
                 "action" => "Populate this required field"
               },
               "source_schema_validation_report" => ^report
             }
           ] = package["rows"]

    assert String.starts_with?(
             id,
             "schema_validation:campaign_plan.v1:artifact_file:path:.plan_id:"
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_status =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "validation_status", "pass")]
      end)

    assert {:error, invalid_source_status_report} =
             Schema.validate_artifact(invalid_source_status)

    assert Enum.any?(
             invalid_source_status_report["errors"],
             &(&1["path"] == "$.rows[0].source_schema_validation_report.status" and
                 &1["message"] == "must match validation_status")
           )
  end

  test "builds review package from schema validation batch report failures" do
    failing_report = schema_validation_report()

    passing_report = %{
      failing_report
      | "validated_contract" => "candidate_refresh.v1",
        "validated_artifact_family" => "candidate_refresh",
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 0,
        "errors" => [],
        "warnings" => [],
        "artifact_path" => "study_results/candidate_refresh_v1.json",
        "remediation_count" => 0,
        "remediation" => []
    }

    batch = %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "validation_mode" => "artifact_directory",
      "input_dir" => "study_results",
      "file_count" => 2,
      "artifact_count" => 2,
      "skipped_count" => 0,
      "skipped_artifacts" => [],
      "status" => "fail",
      "error_count" => 1,
      "warning_count" => 0,
      "reports" => [
        %{"path" => "study_results/bad_campaign.json", "report" => failing_report},
        %{"path" => "study_results/candidate_refresh_v1.json", "report" => passing_report}
      ]
    }

    package = OperatorReview.from_schema_validation_batch_report(batch)

    assert OrbitalDynamics.operator_review_package(batch) == package

    assert %{
             "source_artifact_type" => "schema_validation_batch_report.v1",
             "source_artifact_id" =>
               "schema_validation_batch:artifact_directory:study_results:fail",
             "review_count" => 1,
             "schema_validation_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "schema_validation_review",
                 "source" => "schema_validation_batch_report.reports.report.errors",
                 "validated_contract" => "campaign_plan.v1",
                 "artifact_path" => "study_results/bad_campaign.json",
                 "issue_path" => "$.plan_id",
                 "source_schema_validation_report" => %{
                   "batch_entry_path" => "study_results/bad_campaign.json"
                 }
               }
             ]
           } = package

    assert {:ok, %{"schema_contract" => "schema_validation_batch_report.v1"}} =
             Schema.validate_artifact(batch)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from execution report failed scenarios" do
    report = read_json!("study_results/execution_report_v1.json")

    package = OperatorReview.from_execution_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "execution_report.v1",
             "source_artifact_id" =>
               "execution:large_monte_carlo:large_monte_carlo-2026-05-14T00:00:00Z",
             "review_count" => 1,
             "execution_review_count" => 1,
             "review_type_counts" => %{"execution_review" => 1}
           } = package

    assert [
             %{
               "id" => "execution:trial_1842:propagation:1",
               "review_type" => "execution_review",
               "source" => "execution_report.failed_scenarios",
               "subject_id" => "trial_1842",
               "scenario_id" => "trial_1842",
               "scenario_index" => 1841,
               "required_operator_action" => "review_execution_failure",
               "action" => "review_execution_failure",
               "approval_status" => "operator_review_required",
               "execution_status" => "completed_with_errors",
               "execution_mode" => "distributed_task_supervisors",
               "execution_stage" => "propagation",
               "execution_error" => ["task_timeout", 30000],
               "resumability" => "manual_rerun_only",
               "retry_recommendation" => "rerun_failed_scenario_from_source_manifest",
               "failed_scenario_count" => 1,
               "source_execution_failure" => %{"scenario_id" => "trial_1842"},
               "source_execution_report" => %{"schema_contract" => "execution_report.v1"}
             }
           ] = package["rows"]

    completed_report =
      report
      |> Map.put("status", "completed")
      |> Map.put("failed_scenario_count", 0)
      |> Map.put("failed_scenarios", [])

    assert %{"review_count" => 0, "execution_review_count" => 0, "rows" => []} =
             OperatorReview.from_execution_report(completed_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_status =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "execution_status", "completed")]
      end)

    assert {:error, invalid_source_status_report} =
             Schema.validate_artifact(invalid_source_status)

    assert Enum.any?(
             invalid_source_status_report["errors"],
             &(&1["path"] == "$.rows[0].source_execution_report.status" and
                 &1["message"] == "must match execution_status")
           )
  end

  test "builds review package from result artifact execution failures" do
    artifact =
      "study_results/ground_track_crossings.json"
      |> read_json!()
      |> put_in(["execution_report"], result_artifact_failed_execution_report())

    package = OperatorReview.from_result_artifact(artifact)

    assert OrbitalDynamics.operator_review_package(artifact) == package

    assert %{
             "source_artifact_type" => "result_artifact.v1",
             "source_artifact_id" =>
               "result_artifact:ground_track_crossings:ground_track_crossings-20260514",
             "review_count" => 1,
             "execution_review_count" => 1,
             "review_type_counts" => %{"execution_review" => 1}
           } = package

    assert [
             %{
               "id" => "execution:ground_track_1:propagation:1",
               "review_type" => "execution_review",
               "source" => "result_artifact.execution_report.failed_scenarios",
               "subject_id" => "ground_track_1",
               "scenario_id" => "ground_track_1",
               "required_operator_action" => "review_execution_failure",
               "execution_status" => "completed_with_errors",
               "source_execution_report" => %{"schema_contract" => "execution_report.v1"}
             }
           ] = package["rows"]

    completed_artifact = read_json!("study_results/ground_track_crossings.json")

    assert %{"review_count" => 0, "execution_review_count" => 0, "rows" => []} =
             OperatorReview.from_result_artifact(completed_artifact)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "lifts result artifact nested constraint and maneuver review rows" do
    artifact =
      "study_results/ground_track_crossings.json"
      |> read_json!()
      |> Map.put("constraint_report", constraint_report())
      |> Map.put(
        "maneuver_review_report",
        read_json!("study_results/maneuver_review_report_v1.json")
      )

    package = OperatorReview.from_result_artifact(artifact)

    assert %{
             "source_artifact_type" => "result_artifact.v1",
             "review_count" => 3,
             "constraint_review_count" => 2,
             "maneuver_review_count" => 1,
             "review_type_counts" => %{"constraint_review" => 2, "maneuver_review" => 1}
           } = package

    assert %{
             "review_type" => "constraint_review",
             "source" => "result_artifact.constraint_report.rows",
             "constraint_id" => "minimum_operational_altitude",
             "constraint_status" => "fail"
           } =
             Enum.find(package["rows"], &(&1["constraint_status"] == "fail"))

    assert %{
             "review_type" => "maneuver_review",
             "source" => "result_artifact.maneuver_review_report.rows",
             "maneuver_id" => "trim_burn",
             "scenario_id" => "ops_checkout"
           } =
             Enum.find(package["rows"], &(&1["review_type"] == "maneuver_review"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "deduplicates result artifact maneuver recommendations when review report is embedded" do
    maneuver_review_report = read_json!("study_results/maneuver_review_report_v1.json")

    recommendation =
      maneuver_review_report["rows"] |> List.first() |> Map.fetch!("source_recommendation")

    artifact =
      "study_results/ground_track_crossings.json"
      |> read_json!()
      |> Map.put("maneuver_review_report", maneuver_review_report)
      |> Map.put("maneuver_recommendations", [recommendation])

    package = OperatorReview.from_result_artifact(artifact)

    assert %{
             "source_artifact_type" => "result_artifact.v1",
             "review_count" => 1,
             "maneuver_review_count" => 1,
             "review_type_counts" => %{"maneuver_review" => 1},
             "rows" => [
               %{
                 "review_type" => "maneuver_review",
                 "source" => "result_artifact.maneuver_review_report.rows",
                 "maneuver_id" => "trim_burn",
                 "scenario_id" => "ops_checkout"
               }
             ]
           } = package

    refute Enum.any?(
             package["rows"],
             &(&1["source"] == "result_artifact.maneuver_recommendations")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds candidate refresh review package from contact and filter handoff rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "schema_version" => 1,
      "refresh_id" => "candidate_refresh:ops_state:001",
      "contact_intents" => [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "refresh_downlink",
          "activity_id" => "refresh_downlink",
          "activity_type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "approval_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "schema_contract" => "approval_requirement.v1",
              "id" => "approval:refresh_downlink",
              "activity_id" => "refresh_downlink",
              "activity_type" => "downlink",
              "action" => "review_contact_intent",
              "requirement_type" => "contact_schedule_change",
              "reason" => "contact intent requires schedule authority"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "downlink_schedule_authority_review",
              "required_authority" => "contact_schedule_authority"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "policy_bundle_id" => "command_contact_authority_v1",
            "classification" => "operator_review_required",
            "escalations" => [
              %{"rule_id" => "unmatched_contact_rule", "escalation_queue" => "ignore_queue"},
              %{
                "rule_id" => "downlink_schedule_authority_review",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "contact_intent_review",
                "escalation_role" => "contact_scheduler",
                "required_authority" => "contact_schedule_authority",
                "sla_s" => 600
              }
            ]
          }
        }
      ],
      "contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => [
          %{
            "contact_id" => "refresh_downlink_deferred",
            "type" => "downlink",
            "scenario_id" => "leo_2",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "starts_at_s" => 110.0,
            "ends_at_s" => 170.0,
            "allocation_status" => "deferred",
            "allocation_reason" => "same_station_contention",
            "selected_contact_id" => "refresh_downlink",
            "review_status" => "operator_review_required",
            "approval_requirements" => [
              %{
                "activity_id" => "refresh_downlink_deferred",
                "activity_type" => "downlink",
                "action" => "review_contact_allocation",
                "requirement_type" => "contact_schedule_change"
              }
            ],
            "approval_rule_matches" => [
              %{
                "rule_id" => "contact_allocation_review",
                "classification" => "operator_review_required"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "ground_network_allocation_v1",
              "classification" => "operator_review_required",
              "escalations" => [
                %{"rule_id" => "unmatched_allocation_rule", "escalation_queue" => "ignore_queue"},
                %{
                  "rule_id" => "contact_allocation_review",
                  "required_authority" => "contact_schedule_authority",
                  "escalation_level" => "ops_lead",
                  "escalation_queue" => "ground_network",
                  "escalation_role" => "network_scheduler",
                  "sla_s" => 600
                }
              ]
            }
          }
        ]
      },
      "contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "refresh_contact_suppressed",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 200.0,
            "ends_at_s" => 260.0,
            "suppressed_reason" => "ground_station_unavailable"
          }
        ]
      },
      "candidate_diff_report" => %{
        "schema_contract" => "candidate_diff_report.v1",
        "invalidated_candidates" => [
          %{
            "id" => "old_refresh_observe",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "source_target_id" => "target_a",
            "source_target" => %{
              "id" => "target_a",
              "name" => "Target A",
              "latitude_deg" => 12.5,
              "longitude_deg" => -45.25,
              "minimum_elevation_deg" => 17.5
            },
            "target_latitude_deg" => 12.5,
            "target_longitude_deg" => -45.25,
            "target_minimum_elevation_deg" => 17.5,
            "target_priority" => 4.5,
            "target_priority_source" => "candidate_refresh.objectives.observation_priority",
            "target_priority_objective_ids" => ["urgent:target_a"],
            "target_priority_objective_type" => "urgent_target",
            "collection_id" => "collection_alpha",
            "product_ids" => ["image_l0", "image_l1"],
            "payload_id" => "camera_a",
            "instrument_id" => "imager",
            "source_activity_ids" => ["refresh_observe"],
            "objective_id" => "latency:collection_alpha",
            "objective_type" => "collection_latency",
            "latency_objective" => true,
            "max_latency_s" => 900.0,
            "planned_latency_s" => 540.0,
            "required_downlink_mb" => 300.0,
            "candidate_downlink_mb" => 360.0,
            "downlink_completion_ratio" => 1.0,
            "selected_downlink_shortfall_mb" => +0.0,
            "downlink_requirement_status" => "satisfied",
            "downlink_completion_source" =>
              "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
            "downlink_completion_sources" => [
              "candidate_refresh.objectives.collection_latency",
              "operational_feedback.downlink_demand_mb.station"
            ],
            "source_window_id" => "window:leo_1:target_visibility:target_a:old",
            "starts_at_s" => 90.0,
            "ends_at_s" => 150.0,
            "replacement_candidate_id" => "refresh_observe",
            "invalidated_reason" => "replaced_by_semantically_similar_candidate",
            "semantic_change_reasons" => ["starts_at_s_changed", "source_window_id_changed"],
            "semantic_change_details" => [
              %{
                "field" => "target_priority",
                "reason" => "target_priority_changed",
                "prior_path" => "target_priority",
                "refreshed_path" => "target_priority",
                "prior_value" => 2.0,
                "refreshed_value" => 4.5
              }
            ]
          }
        ]
      },
      "source_window_lineage" => [
        %{
          "schema_contract" => "source_window_lineage.v1",
          "candidate_activity_id" => "refresh_observe",
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "source_window_type" => "target_visibility",
          "scenario_id" => "leo_1",
          "source_window" => %{
            "schema_contract" => "refreshed_window.v1",
            "id" => "window:leo_1:target_visibility:target_a:1",
            "type" => "target_visibility",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "duration_s" => 60.0,
            "boundary_refinement" => "target_visibility_linear_margin_interpolation"
          }
        }
      ],
      "candidate_rejection_report" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "model" => "artifact_only_candidate_rejection_explanation",
        "source" => "candidate_refresh.candidate_filter",
        "candidate_count" => 1,
        "row_count" => 1,
        "rejected_count" => 1,
        "not_rejected_count" => 0,
        "invalid_candidate_input_count" => 0,
        "reviewable_count" => 1,
        "rejection_reason_counts" => %{"station_reserved" => 1},
        "required_operator_action_counts" => %{"review_candidate_rejection" => 1},
        "rows" => [
          %{
            "id" => "candidate_rejection:1:refresh_downlink_reserved",
            "candidate_id" => "refresh_downlink_reserved",
            "activity_id" => "refresh_downlink_reserved",
            "timeline_id" => "candidate_timeline",
            "activity_type" => "downlink",
            "operational_kind" => "contact",
            "rejection_status" => "rejected",
            "primary_rejection_reason" => "station_reserved",
            "rejection_reasons" => ["station_reserved"],
            "reason_count" => 1,
            "reviewable" => true,
            "required_operator_action" => "review_candidate_rejection",
            "violated_constraint" => "station_calendar",
            "required_margin" => 10.0,
            "actual_margin" => 5.0,
            "activity_context" => %{"ground_station_id" => "dss_14"}
          }
        ],
        "assumptions" => %{"scope" => "test fixture"}
      },
      "freshness_report" => %{
        "schema_contract" => "freshness_report.v1",
        "model" => "accepted_snapshot_horizon_and_quality_freshness",
        "generated_at" => "2026-05-14T00:00:00Z",
        "accepted_at" => "2026-05-12T00:00:00Z",
        "accepted_state_quality_level" => "planning_accepted",
        "allowed_state_quality_levels" => ["accepted"],
        "state_quality_status" => "not_accepted",
        "current_epoch_s" => 0.0,
        "horizon_starts_at_s" => 30.0,
        "accepted_snapshot_age_s" => 172_800.0,
        "horizon_start_offset_s" => 30.0,
        "max_snapshot_age_s" => 86_400.0,
        "max_horizon_start_offset_s" => 1.0,
        "status" => "stale",
        "stale_reasons" => [
          "accepted_snapshot_older_than_policy",
          "remaining_horizon_does_not_start_at_current_epoch",
          "accepted_state_quality_below_policy"
        ],
        "unknown_reasons" => []
      },
      "refresh_budget_report" => %{
        "schema_contract" => "refresh_budget_report.v1",
        "model" => "deterministic_candidate_limit_after_filters",
        "input_candidate_count" => 3,
        "kept_candidate_count" => 2,
        "dropped_candidate_count" => 1,
        "max_candidate_activities" => 2,
        "selection_order" => "score_descending_then_start_then_id",
        "kept_candidate_ids" => ["refresh_downlink", "refresh_observe"],
        "dropped_candidate_ids" => ["old_refresh_downlink"]
      },
      "resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "refresh_observe_suppressed",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "starts_at_s" => 300.0,
            "ends_at_s" => 360.0,
            "suppressed_reason" => "payload_unavailable"
          }
        ]
      },
      "warnings" => ["candidate refresh produced reviewable contact changes"],
      "provenance" => %{
        "source" => "candidate_refresh_test",
        "run_input_sources" => %{
          "accepted_planning_state" => ["candidate_refresh.mission_state.spacecraft_states"],
          "targets" => ["candidate_refresh.mission_state.objectives"],
          "ground_stations" => ["candidate_refresh.mission_state.ground_network"]
        },
        "source_reports" => %{
          "operational_readiness_report" => %{
            "paths" => ["mission_state.source_operational_readiness_report"],
            "contract" => "operational_readiness_report.v1",
            "count" => 1,
            "row_count" => 1,
            "readiness_level_counts" => %{"operator_review" => 1},
            "import_classification_counts" => %{"review_only" => 1},
            "status_counts" => %{"review_required" => 1},
            "gate_count" => 4,
            "passed_gate_count" => 2,
            "review_gate_count" => 2,
            "analysis_gate_count" => 0,
            "blocked_gate_count" => 0,
            "review_required_count" => 1,
            "schema_validation_fail_count" => 1,
            "resource_availability_pressure_count" => 3,
            "resource_availability_reason_counts" => %{
              "antenna_unavailable" => 1,
              "ground_station_reserved" => 1,
              "payload_unavailable" => 1
            },
            "resource_availability_reason_ids" => [
              "antenna_unavailable",
              "ground_station_reserved",
              "payload_unavailable"
            ],
            "station_availability_reason_ids" => ["ground_station_reserved"],
            "unavailable_resource_reason_ids" => [
              "antenna_unavailable",
              "payload_unavailable"
            ],
            "resource_blocking_dimension_counts" => %{"communications" => 1},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["mission_state_operational_readiness_report"]
          }
        },
        "operational_feedback" => %{
          "trust_boundary_status" => "missing",
          "input_keys" => ["observation_success_rate"]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert OrbitalDynamics.operator_review_package(artifact) == package

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:ops_state:001",
             "review_count" => 10,
             "contact_intent_review_count" => 1,
             "contact_allocation_review_count" => 1,
             "candidate_rejection_review_count" => 1,
             "candidate_diff_review_count" => 1,
             "freshness_review_count" => 1,
             "refresh_budget_review_count" => 1,
             "operational_readiness_review_count" => 1,
             "contact_suppression_count" => 1,
             "resource_suppression_count" => 1,
             "warning_count" => 1
           } = package

    assert get_in(package, ["provenance", "run_input_sources"]) == %{
             "accepted_planning_state" => ["candidate_refresh.mission_state.spacecraft_states"],
             "targets" => ["candidate_refresh.mission_state.objectives"],
             "ground_stations" => ["candidate_refresh.mission_state.ground_network"]
           }

    assert %{
             "review_type" => "contact_intent_review",
             "source" => "candidate_refresh.contact_intents",
             "activity_id" => "refresh_downlink",
             "required_operator_action" => "review_contact_intent",
             "source_policy_decision" => %{"policy_bundle_id" => "command_contact_authority_v1"},
             "source_policy_escalation" => %{
               "rule_id" => "downlink_schedule_authority_review",
               "escalation_queue" => "contact_intent_review"
             },
             "escalation_level" => "ops_lead",
             "escalation_queue" => "contact_intent_review",
             "escalation_role" => "contact_scheduler",
             "sla_s" => 600,
             "source_contact_intent" => %{"schema_contract" => "contact_intent.v1"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_intent_review"))

    assert %{
             "review_type" => "contact_allocation_review",
             "source" => "candidate_refresh.contact_allocation_report.rows",
             "contact_id" => "refresh_downlink_deferred",
             "allocation_status" => "deferred",
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "contact_allocation_review",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "network_scheduler",
             "sla_s" => 600,
             "source_policy_decision" => %{"policy_bundle_id" => "ground_network_allocation_v1"},
             "source_policy_escalation" => %{
               "rule_id" => "contact_allocation_review",
               "escalation_queue" => "ground_network"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_allocation_review"))

    assert %{
             "review_type" => "candidate_diff_review",
             "source" => "candidate_refresh.candidate_diff_report.invalidated_candidates",
             "activity_id" => "old_refresh_observe",
             "target_id" => "target_a",
             "source_target_id" => "target_a",
             "source_target" => %{
               "id" => "target_a",
               "name" => "Target A",
               "latitude_deg" => 12.5,
               "longitude_deg" => -45.25,
               "minimum_elevation_deg" => 17.5
             },
             "target_latitude_deg" => 12.5,
             "target_longitude_deg" => -45.25,
             "target_minimum_elevation_deg" => 17.5,
             "target_priority" => 4.5,
             "target_priority_source" => "candidate_refresh.objectives.observation_priority",
             "target_priority_objective_ids" => ["urgent:target_a"],
             "target_priority_objective_type" => "urgent_target",
             "collection_id" => "collection_alpha",
             "product_ids" => ["image_l0", "image_l1"],
             "payload_id" => "camera_a",
             "instrument_id" => "imager",
             "source_activity_ids" => ["refresh_observe"],
             "objective_id" => "latency:collection_alpha",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "max_latency_s" => 900.0,
             "planned_latency_s" => 540.0,
             "required_downlink_mb" => 300.0,
             "candidate_downlink_mb" => 360.0,
             "downlink_completion_ratio" => 1.0,
             "downlink_requirement_status" => "satisfied",
             "downlink_completion_source" =>
               "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
             "downlink_completion_sources" => [
               "candidate_refresh.objectives.collection_latency",
               "operational_feedback.downlink_demand_mb.station"
             ],
             "required_operator_action" => "review_candidate_diff",
             "replacement_candidate_id" => "refresh_observe",
             "replacement_source_window_id" => "window:leo_1:target_visibility:target_a:1",
             "replacement_source_window_type" => "target_visibility",
             "replacement_source_window" => %{
               "id" => "window:leo_1:target_visibility:target_a:1",
               "boundary_refinement" => "target_visibility_linear_margin_interpolation"
             },
             "replacement_source_window_lineage" => %{
               "schema_contract" => "source_window_lineage.v1",
               "candidate_activity_id" => "refresh_observe"
             },
             "semantic_change_reasons" => ["target_priority_changed"],
             "changed_fields" => ["target_priority"],
             "candidate_diff_changed_fields" => ["target_priority"],
             "candidate_diff_changed_field_count" => 1,
             "semantic_change_details" => [
               %{
                 "field" => "target_priority",
                 "reason" => "target_priority_changed",
                 "prior_value" => 2.0,
                 "refreshed_value" => 4.5
               }
             ],
             "run_input_sources" => %{
               "accepted_planning_state" => [
                 "candidate_refresh.mission_state.spacecraft_states"
               ],
               "targets" => ["candidate_refresh.mission_state.objectives"],
               "ground_stations" => ["candidate_refresh.mission_state.ground_network"]
             },
             "source_candidate_diff" => %{"id" => "old_refresh_observe"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "candidate_diff_review"))

    assert %{
             "review_type" => "candidate_rejection_review",
             "source" => "candidate_refresh.candidate_rejection_report.rows",
             "subject_id" => "refresh_downlink_reserved",
             "required_operator_action" => "review_candidate_rejection",
             "primary_rejection_reason" => "station_reserved",
             "source_candidate_rejection" => %{
               "candidate_id" => "refresh_downlink_reserved"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "candidate_rejection_review"))

    assert %{
             "review_type" => "freshness_review",
             "source" => "candidate_refresh.freshness_report",
             "subject_id" => "freshness:stale",
             "required_operator_action" => "review_refresh_freshness",
             "freshness_status" => "stale",
             "stale_reasons" => [
               "accepted_snapshot_older_than_policy",
               "remaining_horizon_does_not_start_at_current_epoch",
               "accepted_state_quality_below_policy"
             ],
             "source_freshness_report" => %{"status" => "stale"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "freshness_review"))

    assert %{
             "review_type" => "refresh_budget_review",
             "source" => "candidate_refresh.refresh_budget_report",
             "required_operator_action" => "review_refresh_budget",
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["old_refresh_downlink"],
             "run_input_sources" => %{
               "targets" => ["candidate_refresh.mission_state.objectives"]
             },
             "source_refresh_budget_report" => %{"schema_contract" => "refresh_budget_report.v1"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "refresh_budget_review"))

    assert %{
             "review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.provenance.source_reports.operational_readiness_report",
             "subject_id" => "candidate_refresh.operational_readiness_source_reports",
             "required_operator_action" => "review_operational_readiness",
             "approval_status" => "operator_review_required",
             "source_artifact_type" => "operational_readiness_report.v1",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "operational_readiness_status" => "review_required",
             "gate_count" => 4,
             "review_gate_count" => 2,
             "resource_availability_pressure_count" => 3,
             "resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "ground_station_reserved" => 1,
               "payload_unavailable" => 1
             },
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "ground_station_reserved",
               "payload_unavailable"
             ],
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "resource_blocking_dimension_counts" => %{"communications" => 1},
             "evidence" => %{
               "review_required_count" => 1,
               "schema_validation_fail_count" => 1,
               "resource_availability_pressure_count" => 3,
               "resource_availability_reason_counts" => %{
                 "antenna_unavailable" => 1,
                 "ground_station_reserved" => 1,
                 "payload_unavailable" => 1
               },
               "resource_availability_reason_ids" => [
                 "antenna_unavailable",
                 "ground_station_reserved",
                 "payload_unavailable"
               ],
               "station_availability_reason_ids" => ["ground_station_reserved"],
               "unavailable_resource_reason_ids" => [
                 "antenna_unavailable",
                 "payload_unavailable"
               ],
               "resource_blocking_dimension_counts" => %{"communications" => 1}
             },
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_report.v1",
               "paths" => ["mission_state.source_operational_readiness_report"],
               "trust_boundary_status" => "declared"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["review_type"] == "operational_readiness_review")
             )

    assert %{
             "review_type" => "warning",
             "source" => "candidate_refresh.warnings",
             "reason" => "candidate refresh produced reviewable contact changes",
             "operational_feedback_trust_boundary_status" => "missing",
             "operational_feedback_input_keys" => ["observation_success_rate"],
             "source_operational_feedback_provenance" => %{
               "trust_boundary_status" => "missing"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "warning"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    candidate_diff_index =
      Enum.find_index(package["rows"], &(&1["review_type"] == "candidate_diff_review"))

    invalid_replacement_window =
      put_in(
        package,
        ["rows", Access.at(candidate_diff_index), "replacement_source_window", "id"],
        "window:leo_1:target_visibility:target_a:mismatch"
      )

    assert {:error, invalid_replacement_window_report} =
             Schema.validate_artifact(invalid_replacement_window)

    assert Enum.any?(
             invalid_replacement_window_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{candidate_diff_index}].replacement_source_window.id" and
                 &1["message"] == "must match replacement_source_window_id")
           )
  end

  test "candidate refresh source candidate diff reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_candidate_diff_review:001",
      "source_candidate_diff_report" => [
        %{
          "schema_contract" => "candidate_diff_report.v1",
          "model" => "candidate_id_set_diff_with_semantic_change_reasons",
          "invalidated_candidates" => [
            %{
              "id" => "old_refresh_observe",
              "type" => "observe",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "source_window_id" => "window:leo_1:target_visibility:target_a:old",
              "starts_at_s" => 90.0,
              "ends_at_s" => 150.0,
              "replacement_candidate_id" => "refresh_observe",
              "invalidated_reason" => "replaced_by_semantically_similar_candidate",
              "semantic_change_reasons" => [
                "starts_at_s_changed",
                "source_window_id_changed"
              ],
              "semantic_change_details" => [
                %{
                  "field" => "starts_at_s",
                  "reason" => "starts_at_s_changed",
                  "prior_value" => 90.0,
                  "refreshed_value" => 100.0
                }
              ]
            }
          ],
          "source_window_lineage" => [
            %{
              "schema_contract" => "source_window_lineage.v1",
              "candidate_activity_id" => "refresh_observe",
              "source_window_id" => "window:leo_1:target_visibility:target_a:1",
              "source_window_type" => "target_visibility",
              "scenario_id" => "leo_1",
              "source_window" => %{
                "schema_contract" => "refreshed_window.v1",
                "id" => "window:leo_1:target_visibility:target_a:1",
                "type" => "target_visibility",
                "scenario_id" => "leo_1",
                "target_id" => "target_a",
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "duration_s" => 60.0
              }
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_candidate_diff_review:001",
             "review_count" => 1,
             "candidate_diff_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "candidate_diff_review",
               "source" =>
                 "candidate_refresh.source_candidate_diff_report[0].invalidated_candidates",
               "activity_id" => "old_refresh_observe",
               "target_id" => "target_a",
               "required_operator_action" => "review_candidate_diff",
               "replacement_candidate_id" => "refresh_observe",
               "replacement_source_window_id" => "window:leo_1:target_visibility:target_a:1",
               "replacement_source_window_type" => "target_visibility",
               "replacement_source_window" => %{
                 "id" => "window:leo_1:target_visibility:target_a:1"
               },
               "replacement_source_window_lineage" => %{
                 "candidate_activity_id" => "refresh_observe"
               },
               "semantic_change_reasons" => ["starts_at_s_changed"],
               "changed_fields" => ["starts_at_s"],
               "candidate_diff_changed_fields" => ["starts_at_s"],
               "source_candidate_diff" => %{"id" => "old_refresh_observe"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh state and wrapped candidate diff reports become review and import rows" do
    report = candidate_diff_report()

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:state_candidate_diff_review:001",
      "accepted_planning_state" => %{"source_candidate_diff_report" => report},
      "mission_state" => %{"candidate_diff_report" => report},
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_candidate_diff_report" => report
        }
      ],
      "result_artifact" => [
        report
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_candidate_diff_review:001",
             "review_count" => 4,
             "candidate_diff_review_count" => 4
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_candidate_diff_report.invalidated_candidates",
             "candidate_refresh.mission_state.candidate_diff_report.invalidated_candidates",
             "candidate_refresh.source_result_artifact[0].source_candidate_diff_report.invalidated_candidates",
             "candidate_refresh.result_artifact[0].invalidated_candidates"
           ]

    assert %{
             "review_type" => "candidate_diff_review",
             "activity_id" => "old_refresh_observe",
             "target_id" => "target_a",
             "required_operator_action" => "review_candidate_diff",
             "replacement_candidate_id" => "refresh_observe",
             "replacement_source_window_id" => "window:leo_1:target_visibility:target_a:1",
             "replacement_source_window" => %{
               "id" => "window:leo_1:target_visibility:target_a:1"
             },
             "source_candidate_diff" => %{"id" => "old_refresh_observe"}
           } = List.first(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_candidate_diff_review:001",
             "row_count" => 4,
             "source_review_type_counts" => %{"candidate_diff_review" => 4}
           } = manifest

    assert Enum.map(manifest["rows"], &get_in(&1, ["source_review_row", "source"])) == [
             "candidate_refresh.accepted_planning_state.source_candidate_diff_report.invalidated_candidates",
             "candidate_refresh.mission_state.candidate_diff_report.invalidated_candidates",
             "candidate_refresh.source_result_artifact[0].source_candidate_diff_report.invalidated_candidates",
             "candidate_refresh.result_artifact[0].invalidated_candidates"
           ]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh source command window reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_command_window_review:001",
      "source_command_window_report" => [
        %{
          "schema_contract" => "command_window_report.v1",
          "source" => "mission_state.source_command_window_report",
          "rows" => [
            %{
              "id" => "command_window:cmd_live",
              "activity_id" => "cmd_live",
              "timeline_id" => "timeline:cmd_live",
              "scenario_id" => "leo_1",
              "activity_type" => "command",
              "window_type" => "command_window",
              "direction" => "command",
              "ground_station_id" => "dss_14",
              "starts_at_s" => 30.0,
              "ends_at_s" => 40.0,
              "status" => "planned",
              "approval_status" => "pending",
              "locked" => false,
              "command_success" => false,
              "contact_result" => ["accepted", "dropped"],
              "command_result" => ["accepted", "rejected"],
              "command_success_factor" => 0.25,
              "command_success_factor_source" =>
                "source_command_window_report.operational_feedback",
              "required_operator_action" => "review_command_contact",
              "operator_action_reason" => "command_boundary_requires_review",
              "approval_requirements" => [
                %{
                  "activity_id" => "cmd_live",
                  "activity_type" => "command",
                  "action" => "review_command_contact",
                  "requirement_type" => "command_review"
                }
              ],
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "classification" => "operator_review_required",
                "policy_bundle_id" => "contact_command_review_v1",
                "escalations" => [
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
              "cadence_import_status" => "missing",
              "activity_context" => %{
                "command_result" => ["accepted", "rejected"],
                "command_success_factor" => 0.25
              }
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_command_window_review:001",
             "review_count" => 1,
             "command_window_count" => 1
           } = package

    assert [
             %{
               "review_type" => "command_window_review",
               "source" => "candidate_refresh.source_command_window_report[0].rows",
               "activity_id" => "cmd_live",
               "timeline_id" => "timeline:cmd_live",
               "window_type" => "command_window",
               "required_operator_action" => "review_command_contact",
               "reason" => "command_boundary_requires_review",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.25,
               "requirement_type" => "command_review",
               "policy_bundle_id" => "contact_command_review_v1",
               "required_authority" => "command_authority",
               "escalation_queue" => "command_review",
               "source_command_window" => %{"activity_id" => "cmd_live"},
               "source_activity_context" => %{"command_result" => "accepted,rejected"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact command window reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_command_window_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "command_window_report" => %{
          "schema_contract" => "command_window_report.v1",
          "source" => "wrapped.command_window_report",
          "rows" => [
            %{
              "id" => "command_window:cmd_wrapped",
              "activity_id" => "cmd_wrapped",
              "timeline_id" => "timeline:cmd_wrapped",
              "scenario_id" => "leo_1",
              "activity_type" => "command",
              "window_type" => "command_window",
              "direction" => "command",
              "ground_station_id" => "dss_14",
              "starts_at_s" => 30.0,
              "ends_at_s" => 40.0,
              "status" => "planned",
              "approval_status" => "pending",
              "locked" => false,
              "command_success" => false,
              "contact_result" => ["accepted", "dropped"],
              "command_result" => ["accepted", "rejected"],
              "command_success_factor" => 0.25,
              "command_success_factor_source" =>
                "source_command_window_report.operational_feedback",
              "required_operator_action" => "review_command_contact",
              "operator_action_reason" => "command_boundary_requires_review",
              "approval_requirements" => [
                %{
                  "activity_id" => "cmd_wrapped",
                  "activity_type" => "command",
                  "action" => "review_command_contact",
                  "requirement_type" => "command_review"
                }
              ],
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "classification" => "operator_review_required",
                "policy_bundle_id" => "contact_command_review_v1",
                "escalations" => [
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
              "cadence_import_status" => "missing",
              "activity_context" => %{
                "command_result" => ["accepted", "rejected"],
                "command_success_factor" => 0.25
              }
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_command_window_review:001",
             "review_count" => 1,
             "command_window_count" => 1
           } = package

    assert [
             %{
               "review_type" => "command_window_review",
               "source" => "candidate_refresh.source_result_artifact.command_window_report.rows",
               "activity_id" => "cmd_wrapped",
               "timeline_id" => "timeline:cmd_wrapped",
               "window_type" => "command_window",
               "required_operator_action" => "review_command_contact",
               "reason" => "command_boundary_requires_review",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.25,
               "requirement_type" => "command_review",
               "policy_bundle_id" => "contact_command_review_v1",
               "required_authority" => "command_authority",
               "escalation_queue" => "command_review",
               "source_command_window" => %{"activity_id" => "cmd_wrapped"},
               "source_activity_context" => %{"command_result" => "accepted,rejected"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source maneuver review reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_maneuver_review:001",
      "source_maneuver_review_report" => [
        %{
          "schema_contract" => "maneuver_review_report.v1",
          "model" => "artifact_only_maneuver_review_report",
          "source" => "mission_state.source_maneuver_review_report",
          "rows" => [
            %{
              "id" => "maneuver_review:leo_1:trim_burn",
              "rank" => 1,
              "maneuver_id" => "trim_burn",
              "scenario_id" => "leo_1",
              "maneuver_type" => "impulsive_burn",
              "epoch_s" => 120.0,
              "epoch_scale" => "tdb",
              "frame" => "eci_j2000",
              "delta_v_km_s" => [0.0, 0.01, 0.0],
              "delta_v_magnitude_km_s" => 0.01,
              "maneuver_model" => "impulsive_burns",
              "maneuver_success_factor" => 0.4,
              "maneuver_success_factor_source" =>
                "source_maneuver_review_report.operational_feedback",
              "approval_status" => "operator_review_required",
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "classification" => "operator_review_required",
                "policy_bundle_id" => "maneuver_authority_v1",
                "escalations" => [
                  %{
                    "rule_id" => "maneuver_timing_authority_review",
                    "escalation_level" => "flight_director",
                    "escalation_queue" => "maneuver_authority",
                    "escalation_role" => "flight_dynamics_lead",
                    "required_authority" => "maneuver_authority",
                    "sla_s" => 1200
                  }
                ]
              },
              "required_operator_action" => "review_maneuver_recommendation",
              "reason" => "review impulsive_burn maneuver at 120.0s with 0.01 km/s delta-v",
              "execution_boundary" => "recommendation_only_no_command_execution",
              "source_recommendation" => %{
                "schema_contract" => "maneuver_recommendation.v1",
                "id" => "trim_burn"
              }
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_maneuver_review:001",
             "review_count" => 1,
             "maneuver_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "maneuver_review",
               "source" => "candidate_refresh.source_maneuver_review_report[0].rows",
               "subject_id" => "trim_burn",
               "maneuver_id" => "trim_burn",
               "scenario_id" => "leo_1",
               "maneuver_type" => "impulsive_burn",
               "delta_v_magnitude_km_s" => 0.01,
               "maneuver_success_factor" => 0.4,
               "required_operator_action" => "review_maneuver_recommendation",
               "execution_boundary" => "recommendation_only_no_command_execution",
               "policy_bundle_id" => "maneuver_authority_v1",
               "escalation_queue" => "maneuver_authority",
               "source_maneuver_review" => %{
                 "maneuver_id" => "trim_burn",
                 "maneuver_success_factor" => 0.4
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact maneuver review reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_maneuver_review:001",
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "maneuver_review_report" => %{
            "schema_contract" => "maneuver_review_report.v1",
            "model" => "artifact_only_maneuver_review_report",
            "source" => "wrapped.maneuver_review_report",
            "rows" => [
              %{
                "id" => "maneuver_review:leo_1:wrapped_trim_burn",
                "rank" => 1,
                "maneuver_id" => "wrapped_trim_burn",
                "scenario_id" => "leo_1",
                "maneuver_type" => "impulsive_burn",
                "epoch_s" => 120.0,
                "epoch_scale" => "tdb",
                "frame" => "eci_j2000",
                "delta_v_km_s" => [0.0, 0.01, 0.0],
                "delta_v_magnitude_km_s" => 0.01,
                "maneuver_model" => "impulsive_burns",
                "maneuver_success_factor" => 0.4,
                "maneuver_success_factor_source" =>
                  "source_maneuver_review_report.operational_feedback",
                "approval_status" => "operator_review_required",
                "policy_decision" => %{
                  "schema_contract" => "policy_decision.v1",
                  "classification" => "operator_review_required",
                  "policy_bundle_id" => "maneuver_authority_v1",
                  "escalations" => [
                    %{
                      "rule_id" => "maneuver_timing_authority_review",
                      "escalation_level" => "flight_director",
                      "escalation_queue" => "maneuver_authority",
                      "escalation_role" => "flight_dynamics_lead",
                      "required_authority" => "maneuver_authority",
                      "sla_s" => 1200
                    }
                  ]
                },
                "required_operator_action" => "review_maneuver_recommendation",
                "reason" => "review impulsive_burn maneuver at 120.0s with 0.01 km/s delta-v",
                "execution_boundary" => "recommendation_only_no_command_execution",
                "source_recommendation" => %{
                  "schema_contract" => "maneuver_recommendation.v1",
                  "id" => "wrapped_trim_burn"
                }
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_maneuver_review:001",
             "review_count" => 1,
             "maneuver_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "maneuver_review",
               "source" => "candidate_refresh.result_artifact[0].maneuver_review_report.rows",
               "subject_id" => "wrapped_trim_burn",
               "maneuver_id" => "wrapped_trim_burn",
               "scenario_id" => "leo_1",
               "maneuver_type" => "impulsive_burn",
               "delta_v_magnitude_km_s" => 0.01,
               "maneuver_success_factor" => 0.4,
               "required_operator_action" => "review_maneuver_recommendation",
               "execution_boundary" => "recommendation_only_no_command_execution",
               "policy_bundle_id" => "maneuver_authority_v1",
               "escalation_queue" => "maneuver_authority",
               "source_maneuver_review" => %{
                 "maneuver_id" => "wrapped_trim_burn",
                 "maneuver_success_factor" => 0.4
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source timeline diff reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_timeline_diff_review:001",
      "source_timeline_diff_report" => [
        %{
          "schema_contract" => "timeline_diff_report.v1",
          "source" => "mission_state.source_timeline_diff_report",
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_1",
              "rank" => 1,
              "timeline_id" => "timeline:obs_1",
              "diff_status" => "changed",
              "source_activity_id" => "obs_1",
              "replacement_activity_id" => "obs_1b",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "scenario_id" => "leo_1",
              "source_starts_at_s" => 10.0,
              "source_ends_at_s" => 20.0,
              "replacement_starts_at_s" => 12.0,
              "replacement_ends_at_s" => 22.0,
              "start_delta_s" => 2.0,
              "end_delta_s" => 2.0,
              "source_status" => "approved",
              "replacement_status" => "planned",
              "changed_fields" => ["starts_at_s", "ends_at_s"],
              "requires_operator_review" => true,
              "required_operator_action" => "review_timeline_change",
              "reason" => "replacement timeline changes activity obs_1",
              "source_timeline_identity" => %{"timeline_id" => "timeline:obs_1"},
              "replacement_timeline_identity" => %{"timeline_id" => "timeline:obs_1"}
            },
            %{
              "id" => "timeline_diff:timeline:health_1",
              "timeline_id" => "timeline:health_1",
              "diff_status" => "unchanged",
              "requires_operator_review" => false,
              "required_operator_action" => "none"
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_timeline_diff_review:001",
             "review_count" => 1,
             "timeline_diff_count" => 1
           } = package

    assert [
             %{
               "review_type" => "timeline_diff_review",
               "source" => "candidate_refresh.source_timeline_diff_report[0].rows",
               "subject_id" => "timeline:obs_1",
               "timeline_id" => "timeline:obs_1",
               "diff_status" => "changed",
               "activity_id" => "obs_1b",
               "source_activity_id" => "obs_1",
               "replacement_activity_id" => "obs_1b",
               "required_operator_action" => "review_timeline_change",
               "operator_action_reason" => "replacement timeline changes activity obs_1",
               "changed_fields" => ["starts_at_s", "ends_at_s"],
               "source_timeline_diff" => %{"timeline_id" => "timeline:obs_1"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "timeline dependency impact summaries become operator review rows" do
    source = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 10.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    replacement = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 5.0,
        ends_at_s: 15.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    summary = Timeline.dependency_impact_summary(source, replacement)
    package = OperatorReview.from_timeline_dependency_impact_summary(summary)

    atom_key_summary =
      summary |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_dependency_impact_summary.v1",
             "source_artifact_id" => "timeline_diff_report.v1",
             "review_count" => 2,
             "timeline_dependency_impact_review_count" => 2,
             "required_operator_action_counts" => %{"review_timeline_integrity" => 2}
           } = package

    assert [
             %{
               "review_type" => "timeline_dependency_impact_review",
               "source" => "timeline_dependency_impact_summary.rows",
               "subject_id" => "timeline:command:20.0",
               "timeline_id" => "timeline:command:20.0",
               "activity_id" => "cmd_combo",
               "dependency_impact_scope" => "source",
               "dependency_impact_status" => "review_required",
               "required_operator_action" => "review_timeline_integrity",
               "operator_action_reason" =>
                 "dependency_and_exclusivity_changed_or_removed_source_activity",
               "impacted_source_activity_ids" => ["health_gate"],
               "impacted_source_timeline_ids" => ["timeline:health_check:0.0"],
               "dependent_activity_ids" => ["cmd_combo"],
               "dependent_timeline_ids" => ["timeline:command:20.0"],
               "source_dependent_activity_ids" => ["cmd_combo"],
               "source_dependent_timeline_ids" => ["timeline:command:20.0"],
               "replacement_dependent_activity_ids" => ["cmd_combo"],
               "replacement_dependent_timeline_ids" => ["timeline:command:20.0"],
               "source_dependency_impact_impacted_dependency_activity_ids" => [],
               "source_dependency_impact_impacted_dependency_timeline_ids" => [
                 "timeline:health_check:0.0"
               ],
               "source_dependency_impact_impacted_exclusive_with_activity_ids" => [
                 "health_gate"
               ],
               "source_dependency_impact_impacted_exclusive_with_timeline_ids" => [],
               "dependency_timeline_ids" => ["timeline:health_check:0.0"],
               "exclusive_with_activity_ids" => ["health_gate"],
               "impacted_dependency_timeline_ids" => ["timeline:health_check:0.0"],
               "impacted_exclusive_with_activity_ids" => ["health_gate"],
               "source_timeline_dependency_impact" => %{
                 "scope" => "source",
                 "activity_id" => "cmd_combo"
               }
             },
             %{
               "review_type" => "timeline_dependency_impact_review",
               "dependency_impact_scope" => "replacement",
               "source_timeline_dependency_impact" => %{
                 "scope" => "replacement",
                 "activity_id" => "cmd_combo"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert OrbitalDynamics.operator_review_package(summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(summary, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_summary, :schema_contract)) ==
             package
  end

  test "timeline publication summaries become operator review rows" do
    source = [
      %{id: :health_gate, type: :health_check, starts_at_s: 0.0, ends_at_s: 10.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    replacement = [
      %{id: :health_gate, type: :health_check, starts_at_s: 5.0, ends_at_s: 15.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    dependency_impact = Timeline.dependency_impact_summary(source, replacement)
    timeline_diff_summary = Timeline.diff_summary(source, replacement)

    summary =
      Timeline.publication_summary(
        %{
          "schema_contract" => "operational_timeline_report.v1",
          "id" => "timeline:published_plan:v2"
        },
        publication_sequence: 7,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:published_plan:v1"],
        downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
        dependency_impact_summary: dependency_impact,
        timeline_diff_summary: timeline_diff_summary
      )

    package = OperatorReview.from_timeline_publication_summary(summary)

    atom_key_summary =
      summary |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_publication_summary.v1",
             "source_artifact_id" =>
               "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
             "review_count" => 1,
             "timeline_publication_review_count" => 1,
             "required_operator_action_counts" => %{"review_timeline_publication" => 1},
             "review_type_counts" => %{"timeline_publication_review" => 1}
           } = package

    assert [
             %{
               "review_type" => "timeline_publication_review",
               "source" => "timeline_publication_summary",
               "subject_id" =>
                 "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
               "publication_id" =>
                 "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
               "publication_sequence" => 7,
               "publication_status" => "published_with_downstream_invalidations",
               "downstream_invalidation_status" => "invalidated",
               "publication_authority" => "mission_operations",
               "source_artifact_id" => "timeline:published_plan:v2",
               "source_artifact_type" => "operational_timeline_report.v1",
               "supersedes_artifact_ids" => ["timeline:published_plan:v1"],
               "downstream_product_ids" => [
                 "cadence_import:plan:v1",
                 "operator_review:plan:v1"
               ],
               "invalidated_downstream_product_ids" => [
                 "cadence_import:plan:v1",
                 "operator_review:plan:v1"
               ],
               "downstream_invalidation_reason_counts" => %{
                 "dependency_impact_review_required" => 2
               },
               "invalidated_downstream_product_ids_by_reason" => %{
                 "dependency_impact_review_required" => [
                   "cadence_import:plan:v1",
                   "operator_review:plan:v1"
                 ]
               },
               "dependency_impact_status" => "review_required",
               "dependency_impact_row_count" => 2,
               "impacted_source_activity_ids" => ["health_gate"],
               "impacted_source_timeline_ids" => ["timeline:health_check:0.0"],
               "dependent_activity_ids" => ["cmd_main"],
               "dependent_timeline_ids" => ["timeline:command:20.0"],
               "source_dependent_activity_ids" => ["cmd_main"],
               "source_dependent_timeline_ids" => ["timeline:command:20.0"],
               "replacement_dependent_activity_ids" => ["cmd_main"],
               "replacement_dependent_timeline_ids" => ["timeline:command:20.0"],
               "timeline_diff_row_count" => 3,
               "timeline_diff_review_required_count" => 2,
               "changed_field_counts" => %{"timeline_presence" => 2},
               "changed_timeline_ids" => [],
               "review_timeline_ids" => ["timeline:health_check:0.0", "timeline:health_check:5.0"],
               "timeline_ids_by_changed_field" => %{
                 "timeline_presence" => ["timeline:health_check:0.0", "timeline:health_check:5.0"]
               },
               "required_operator_action" => "review_timeline_publication",
               "operator_action_reason" => "publication_invalidates_downstream_products",
               "source_timeline_publication_summary" => ^summary
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_publication_status =
      put_in(package, ["rows", Access.at(0), "publication_status"], "published")

    assert {:error, stale_publication_status_report} =
             Schema.validate_artifact(stale_publication_status)

    assert Enum.any?(
             stale_publication_status_report["errors"],
             &(&1["path"] == "$.rows[0].publication_status" and
                 &1["message"] ==
                   "must equal source_timeline_publication_summary.publication_status")
           )

    assert OrbitalDynamics.operator_review_package(summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(summary, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_summary, :schema_contract)) ==
             package
  end

  test "CandidateRefresh lifts publication summaries from direct and result artifacts" do
    summary =
      Timeline.publication_summary(
        %{
          "schema_contract" => "operational_timeline_report.v1",
          "id" => "timeline:published_plan:v2"
        },
        publication_sequence: 7,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:published_plan:v1"],
        downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"]
      )

    artifact = %{
      "refresh_id" => "refresh:publication_summary_result_handoff",
      "timeline_publication_summary" => summary,
      "source_result_artifact" => [summary],
      "result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "timeline_publication_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    publication_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_timeline_publication_summary"]["schema_contract"] ==
            "timeline_publication_summary.v1")
      )

    assert length(publication_rows) == 3

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:publication_summary_result_handoff",
             "review_count" => 3,
             "timeline_publication_review_count" => 3,
             "required_operator_action_counts" => %{"review_timeline_publication" => 3}
           } = review

    assert Enum.sort(Enum.map(publication_rows, & &1["source"])) == [
             "candidate_refresh.result_artifact.timeline_publication_summary",
             "candidate_refresh.source_result_artifact[0]",
             "candidate_refresh.timeline_publication_summary"
           ]

    assert Enum.all?(
             publication_rows,
             &(&1["publication_id"] == summary["publication_id"] and
                 &1["publication_status"] == "published_with_downstream_invalidations" and
                 &1["invalidated_downstream_product_ids"] == [
                   "cadence_import:plan:v1",
                   "operator_review:plan:v1"
                 ])
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(get_in(&1, [
            "source_review_row",
            "source_timeline_publication_summary",
            "schema_contract"
          ]) == "timeline_publication_summary.v1")
      )

    assert length(import_rows) == 3

    assert Enum.all?(
             import_rows,
             &(get_in(&1, [
                 "source_review_row",
                 "source_timeline_publication_summary",
                 "publication_id"
               ]) == summary["publication_id"])
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline lifecycle-state summaries become operator review rows" do
    planned = [
      %{
        id: :cmd_provider,
        type: :command,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:done_keep"}
      }
    ]

    realized = [
      %{
        id: :cmd_provider,
        type: :command,
        status: :executed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:done_keep"}
      }
    ]

    summary = Timeline.lifecycle_state_summary(planned, realized)
    package = OperatorReview.from_timeline_lifecycle_state_summary(summary)

    atom_key_summary =
      summary
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_lifecycle_state_summary.v1",
             "source_artifact_id" => "timeline.lifecycle_state",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_approval" => 1},
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = package

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" => "timeline_lifecycle_state_summary.review_rows",
               "subject_id" => "timeline:cmd_provider",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "planned_activity_id" => "cmd_provider",
               "realized_activity_id" => "cmd_provider",
               "timeline_lifecycle_state_status" => "review_required",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "approval_status" => "operator_review_required",
               "operator_action_reason" => "activity_execution_recorded",
               "operator_action_reasons" => [
                 "activity_execution_recorded",
                 "approval_grant_requires_operator_authority"
               ],
               "import_action" => "review_timeline_diff",
               "status_transition" => %{
                 "transition_category" => "execution_recorded"
               },
               "approval_transition" => %{
                 "transition_category" => "approval_granted"
               },
               "source_planned_activity_count" => 2,
               "source_realized_activity_count" => 2,
               "source_lifecycle_state_review_required_count" => 1,
               "source_lifecycle_state_operator_action_reason_counts" => %{
                 "activity_execution_recorded" => 1,
                 "approval_grant_requires_operator_authority" => 1
               },
               "source_lifecycle_state_review_timeline_ids_by_operator_action_reason" => %{
                 "activity_execution_recorded" => ["timeline:cmd_provider"],
                 "approval_grant_requires_operator_authority" => ["timeline:cmd_provider"]
               },
               "source_timeline_lifecycle_state" => %{
                 "timeline_id" => "timeline:cmd_provider",
                 "transition_decision" => "review"
               }
             }
           ] = package["rows"]

    assert OrbitalDynamics.operator_review_package(summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(summary, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_summary, :schema_contract)) ==
             package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_lifecycle_state =
      put_in(
        package,
        ["rows", Access.at(0), "source_timeline_lifecycle_state", "timeline_id"],
        "bad timeline id"
      )

    assert {:error, invalid_source_lifecycle_state_report} =
             Schema.validate_artifact(invalid_source_lifecycle_state)

    assert Enum.any?(
             invalid_source_lifecycle_state_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_lifecycle_state.timeline_id" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "CandidateRefresh lifts accepted planning state lifecycle summaries" do
    planned = [
      %{
        id: :cmd_provider,
        type: :command,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      }
    ]

    realized = [
      %{
        id: :cmd_provider,
        type: :command,
        status: :executed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      }
    ]

    summary =
      planned
      |> Timeline.lifecycle_state_summary(realized)
      |> Map.put("source", "accepted_state.timeline_lifecycle_state_summary")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_lifecycle_state_handoff",
      "accepted_planning_state" => %{
        "timeline_lifecycle_state_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_lifecycle_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 1},
             "required_operator_action_counts" => %{"review_activity_approval" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.timeline_lifecycle_state_summary.review_rows",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "status_transition" => %{"transition_category" => "execution_recorded"},
               "approval_transition" => %{"transition_category" => "approval_granted"},
               "source_lifecycle_state_review_required_count" => 1,
               "source_timeline_lifecycle_state" => %{
                 "timeline_id" => "timeline:cmd_provider",
                 "transition_decision" => "review"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_provider",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.accepted_planning_state.timeline_lifecycle_state_summary.review_rows",
                 "source_timeline_lifecycle_state" => %{
                   "timeline_id" => "timeline:cmd_provider"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state lifecycle summaries" do
    planned = [
      %{
        id: :cmd_mission,
        type: :command,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:cmd_mission"}
      }
    ]

    realized = [
      %{
        id: :cmd_mission,
        type: :command,
        status: :executed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:cmd_mission"}
      }
    ]

    summary =
      planned
      |> Timeline.lifecycle_state_summary(realized)
      |> Map.put("source", "mission_state.timeline_lifecycle_state_summary")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_lifecycle_state_handoff",
      "mission_state" => %{
        "source_timeline_lifecycle_state_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_lifecycle_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.mission_state.source_timeline_lifecycle_state_summary.review_rows",
               "timeline_id" => "timeline:cmd_mission",
               "activity_id" => "cmd_mission",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "source_lifecycle_state_review_required_count" => 1,
               "source_timeline_lifecycle_state" => %{
                 "timeline_id" => "timeline:cmd_mission",
                 "transition_decision" => "review"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_mission",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.source_timeline_lifecycle_state_summary.review_rows",
                 "source_timeline_lifecycle_state" => %{
                   "timeline_id" => "timeline:cmd_mission"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline activity precondition summaries become operator review rows" do
    activity = %{
      id: :cmd_preflight,
      type: :command,
      payload_available: false,
      degraded: true,
      resource_blocking_dimension: :power,
      dependency_activity_ids: [:health_check_1, :obs_1, :obs_1],
      dependency_timeline_ids: [:"timeline:health_check_1", :"timeline:health_check_1"],
      exclusive_with_activity_ids: [:dl_conflict, :dl_conflict],
      exclusive_with_timeline_ids: [:"timeline:dl_conflict", :"timeline:dl_conflict"],
      allow_overlap: true,
      metadata: %{timeline_id: :"timeline:cmd_preflight"}
    }

    summary = Timeline.activity_precondition_summary(activity)
    package = OperatorReview.from_timeline_activity_precondition_summary(summary)

    atom_key_summary =
      summary |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_activity_precondition_summary.v1",
             "source_artifact_id" => "timeline:cmd_preflight",
             "review_count" => 1,
             "timeline_activity_precondition_review_count" => 1,
             "required_operator_action_counts" => %{
               "review_blocked_activity_precondition" => 1
             },
             "review_type_counts" => %{"timeline_activity_precondition_review" => 1}
           } = package

    assert [
             %{
               "review_type" => "timeline_activity_precondition_review",
               "source" => "timeline_activity_precondition_summary.summary",
               "subject_id" => "timeline:cmd_preflight",
               "timeline_id" => "timeline:cmd_preflight",
               "activity_id" => "cmd_preflight",
               "activity_type" => "command",
               "precondition_status" => "blocked",
               "blocked_precondition_count" => 2,
               "review_precondition_count" => 1,
               "blocked_precondition_types" => [
                 "payload_unavailable",
                 "resource_block_declared"
               ],
               "review_precondition_types" => ["degraded_mode"],
               "dependency_activity_ids" => ["health_check_1", "obs_1"],
               "dependency_timeline_ids" => ["timeline:health_check_1"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
               "duplicate_dependency_activity_ids" => ["obs_1"],
               "duplicate_dependency_timeline_ids" => ["timeline:health_check_1"],
               "duplicate_exclusivity_activity_ids" => ["dl_conflict"],
               "duplicate_exclusivity_timeline_ids" => ["timeline:dl_conflict"],
               "allow_overlap" => true,
               "required_operator_action" => "review_blocked_activity_precondition",
               "approval_status" => "operator_review_required",
               "operator_action_reason" => "blocked_activity_precondition",
               "source_timeline_activity_precondition_summary" => %{
                 "schema_contract" => "timeline_activity_precondition_summary.v1",
                 "precondition_status" => "blocked",
                 "duplicate_dependency_activity_ids" => ["obs_1"],
                 "duplicate_exclusivity_activity_ids" => ["dl_conflict"],
                 "allow_overlap" => true
               }
             }
           ] = package["rows"]

    assert OrbitalDynamics.operator_review_package(summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(summary, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_summary, :schema_contract)) ==
             package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source =
      put_in(
        package,
        [
          "rows",
          Access.at(0),
          "source_timeline_activity_precondition_summary",
          "timeline_id"
        ],
        "bad timeline id"
      )

    assert {:error, invalid_source_report} = Schema.validate_artifact(invalid_source)

    assert Enum.any?(
             invalid_source_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_activity_precondition_summary.timeline_id")
           )
  end

  test "candidate refresh artifacts surface timeline activity precondition summaries" do
    summary =
      Timeline.activity_precondition_summary(%{
        id: :cmd_preflight,
        type: :command,
        payload_available: false,
        dependency_activity_ids: [:health_check_1],
        dependency_timeline_ids: [:"timeline:health_check_1"],
        exclusive_with_activity_ids: [:dl_conflict],
        exclusive_with_timeline_ids: [:"timeline:dl_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: :"timeline:cmd_preflight"}
      })

    invalid_summary = Timeline.activity_precondition_summary(%{id: :bad_missing_type})

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:precondition_handoff",
      "source_timeline_activity_precondition_summary" => [summary],
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_activity_precondition_summary" => invalid_summary
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:precondition_handoff",
             "review_count" => 2,
             "timeline_activity_precondition_review_count" => 2,
             "required_operator_action_counts" => %{
               "review_blocked_activity_precondition" => 1,
               "review_invalid_activity_input" => 1
             }
           } = package

    assert [
             %{
               "source" =>
                 "candidate_refresh.source_timeline_activity_precondition_summary[0].summary",
               "required_operator_action" => "review_blocked_activity_precondition",
               "dependency_activity_ids" => ["health_check_1"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "allow_overlap" => true
             },
             %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].timeline_activity_precondition_summary.summary",
               "required_operator_action" => "review_invalid_activity_input",
               "invalid_activity_input" => true,
               "source_timeline_activity_precondition_summary" => %{
                 "invalid_activity_input" => true,
                 "invalid_activity_input_reason" => "missing_activity_type"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "CandidateRefresh lifts accepted planning state precondition summaries" do
    summary =
      Timeline.activity_precondition_summary(%{
        id: :cmd_accepted_preflight,
        type: :command,
        payload_available: false,
        dependency_activity_ids: [:health_check_1],
        dependency_timeline_ids: [:"timeline:health_check_1"],
        exclusive_with_activity_ids: [:dl_conflict],
        exclusive_with_timeline_ids: [:"timeline:dl_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: :"timeline:cmd_accepted_preflight"}
      })

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_precondition_handoff",
      "accepted_planning_state" => %{
        "source_timeline_activity_precondition_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_precondition_handoff",
             "review_count" => 1,
             "timeline_activity_precondition_review_count" => 1,
             "review_type_counts" => %{"timeline_activity_precondition_review" => 1},
             "required_operator_action_counts" => %{
               "review_blocked_activity_precondition" => 1
             }
           } = review

    assert [
             %{
               "review_type" => "timeline_activity_precondition_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_timeline_activity_precondition_summary.summary",
               "timeline_id" => "timeline:cmd_accepted_preflight",
               "activity_id" => "cmd_accepted_preflight",
               "precondition_status" => "blocked",
               "required_operator_action" => "review_blocked_activity_precondition",
               "dependency_activity_ids" => ["health_check_1"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "allow_overlap" => true,
               "source_timeline_activity_precondition_summary" => %{
                 "schema_contract" => "timeline_activity_precondition_summary.v1",
                 "timeline_id" => "timeline:cmd_accepted_preflight",
                 "precondition_status" => "blocked"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_precondition" => 1},
             "source_review_type_counts" => %{"timeline_activity_precondition_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_precondition",
               "source_review_type" => "timeline_activity_precondition_review",
               "timeline_id" => "timeline:cmd_accepted_preflight",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.accepted_planning_state.source_timeline_activity_precondition_summary.summary",
                 "source_timeline_activity_precondition_summary" => %{
                   "timeline_id" => "timeline:cmd_accepted_preflight"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state precondition summaries" do
    summary =
      Timeline.activity_precondition_summary(%{
        id: :cmd_mission_preflight,
        type: :command,
        degraded: true,
        dependency_activity_ids: [:mission_health_check],
        dependency_timeline_ids: [:"timeline:mission_health_check"],
        metadata: %{timeline_id: :"timeline:cmd_mission_preflight"}
      })

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_precondition_handoff",
      "mission_state" => %{
        "timeline_activity_precondition_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_precondition_handoff",
             "review_count" => 1,
             "timeline_activity_precondition_review_count" => 1
           } = review

    assert [
             %{
               "review_type" => "timeline_activity_precondition_review",
               "source" =>
                 "candidate_refresh.mission_state.timeline_activity_precondition_summary.summary",
               "timeline_id" => "timeline:cmd_mission_preflight",
               "activity_id" => "cmd_mission_preflight",
               "precondition_status" => "review_required",
               "required_operator_action" => "review_activity_precondition",
               "dependency_activity_ids" => ["mission_health_check"],
               "source_timeline_activity_precondition_summary" => %{
                 "schema_contract" => "timeline_activity_precondition_summary.v1",
                 "timeline_id" => "timeline:cmd_mission_preflight",
                 "precondition_status" => "review_required"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_precondition" => 1},
             "source_review_type_counts" => %{"timeline_activity_precondition_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_precondition",
               "source_review_type" => "timeline_activity_precondition_review",
               "timeline_id" => "timeline:cmd_mission_preflight",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.timeline_activity_precondition_summary.summary",
                 "source_timeline_activity_precondition_summary" => %{
                   "timeline_id" => "timeline:cmd_mission_preflight"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "single activity timeline states become operator review rows" do
    planned = %{
      id: :cmd_provider,
      type: :command,
      status: "In Progress",
      approval_status: "Review Required",
      metadata: %{
        timeline_id: :"timeline:cmd_provider",
        source_window_id: :"command:cmd_provider"
      }
    }

    realized = %{
      id: :cmd_provider,
      type: :command,
      status: "succeeded",
      approval_status: :approved,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    status_state = Timeline.activity_status_state(planned, realized)
    approval_state = Timeline.activity_approval_state(planned, realized)
    lifecycle_state = Timeline.activity_lifecycle_state(planned, realized)
    activity_state = OrbitalDynamics.timeline_activity_state(planned, realized)

    atom_key_lifecycle_state =
      lifecycle_state
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    status_package = OperatorReview.from_timeline_activity_status_state(status_state)

    assert %{
             "source_artifact_type" => "timeline_activity_status_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1
           } = status_package

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" => "timeline_activity_status_state.state",
               "subject_id" => "timeline:cmd_provider",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "timeline_lifecycle_state_status" => "review_required",
               "transition_decision" => "record",
               "required_operator_action" => "record_timeline_change",
               "approval_status" => "not_required",
               "operator_action_reason" => "activity_execution_recorded",
               "import_action" => "import_replacement_activity",
               "source_lifecycle_state_review_required_count" => 0,
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_status_state.v1",
                 "timeline_id" => "timeline:cmd_provider"
               }
             }
           ] = status_package["rows"]

    activity_state_package = OperatorReview.from_timeline_activity_state(activity_state)

    assert %{
             "source_artifact_type" => "timeline_activity_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1
           } = activity_state_package

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" => "timeline_activity_state.state",
               "subject_id" => "timeline:cmd_provider",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "timeline_lifecycle_state_status" => "review_required",
               "approval_status" => "not_required",
               "source_lifecycle_state_review_required_count" => 0,
               "source_timeline_activity_state" => %{
                 "schema_contract" => "timeline_activity_state.v1",
                 "timeline_id" => "timeline:cmd_provider",
                 "state_status" => "matched",
                 "row_count" => 1
               }
             }
           ] = activity_state_package["rows"]

    refute Map.has_key?(
             hd(activity_state_package["rows"]),
             "source_timeline_lifecycle_state"
           )

    approval_package = OperatorReview.from_timeline_activity_approval_state(approval_state)

    assert %{
             "source_artifact_type" => "timeline_activity_approval_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_approval" => 1}
           } = approval_package

    assert [
             %{
               "source" => "timeline_activity_approval_state.state",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "approval_status" => "operator_review_required",
               "approval_transition" => %{"transition_category" => "approval_granted"}
             }
           ] = approval_package["rows"]

    lifecycle_package = OperatorReview.from_timeline_activity_lifecycle_state(lifecycle_state)

    assert %{
             "source_artifact_type" => "timeline_activity_lifecycle_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_approval" => 1}
           } = lifecycle_package

    assert [
             %{
               "source" => "timeline_activity_lifecycle_state.state",
               "transition_decision" => "review",
               "required_operator_actions" => [
                 "record_timeline_change",
                 "review_activity_approval"
               ],
               "operator_action_reasons" => [
                 "activity_execution_recorded",
                 "approval_grant_requires_operator_authority"
               ],
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_lifecycle_state.v1"
               }
             }
           ] = lifecycle_package["rows"]

    assert OrbitalDynamics.operator_review_package(status_state) == status_package

    assert OrbitalDynamics.operator_review_package(Map.delete(status_state, "schema_contract")) ==
             status_package

    assert OrbitalDynamics.operator_review_package(activity_state) == activity_state_package

    assert OrbitalDynamics.operator_review_package(Map.delete(activity_state, "schema_contract")) ==
             activity_state_package

    assert OrbitalDynamics.operator_review_package(approval_state) == approval_package
    assert OrbitalDynamics.operator_review_package(lifecycle_state) == lifecycle_package
    assert OrbitalDynamics.operator_review_package(atom_key_lifecycle_state) == lifecycle_package

    assert OrbitalDynamics.operator_review_package(
             Map.delete(atom_key_lifecycle_state, :schema_contract)
           ) == lifecycle_package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(lifecycle_package)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(activity_state_package)

    invalid_activity_state_source =
      put_in(
        activity_state_package,
        ["rows", Access.at(0), "source_timeline_activity_state", "timeline_id"],
        "bad timeline id"
      )

    assert {:error, invalid_activity_state_source_report} =
             Schema.validate_artifact(invalid_activity_state_source)

    assert Enum.any?(
             invalid_activity_state_source_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_activity_state.timeline_id" and
                 &1["message"] =~ "stable ID")
           )

    invalid_status_state =
      Timeline.activity_status_state(
        %{id: :obs_missing_type, status: :planned},
        %{id: :obs_missing_type, type: :observe, status: :completed}
      )

    invalid_status_package =
      OperatorReview.from_timeline_activity_status_state(invalid_status_state)

    assert %{
             "source_artifact_type" => "timeline_activity_status_state.v1",
             "source_artifact_id" => "timeline:invalid_activity_input:obs_missing_type",
             "review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_transition" => 1}
           } = invalid_status_package

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "activity_id" => "obs_missing_type",
               "timeline_id" => "timeline:invalid_activity_input:obs_missing_type",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_transition",
               "operator_action_reason" => "invalid_activity_input",
               "invalid_activity_input" => true,
               "invalid_activity_input_count" => 1,
               "invalid_activity_input_reasons" => ["missing_activity_type"],
               "status_transition" => %{"transition_category" => "invalid_activity_input"},
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_status_state.v1",
                 "invalid_activity_input" => true,
                 "invalid_activity_input_count" => 1,
                 "invalid_activity_input_reasons" => ["missing_activity_type"]
               }
             }
           ] = invalid_status_package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(invalid_status_package)

    invalid_approval_state =
      Timeline.activity_approval_state(
        %{id: :cmd_missing_type, type: :command, approval_status: :pending},
        %{id: :cmd_missing_type, approval_status: :approved}
      )

    invalid_approval_package =
      OperatorReview.from_timeline_activity_approval_state(invalid_approval_state)

    assert [
             %{
               "required_operator_action" => "review_activity_approval",
               "invalid_activity_input" => true,
               "invalid_activity_input_count" => 1,
               "invalid_activity_input_reasons" => ["missing_activity_type"],
               "approval_transition" => %{"transition_category" => "invalid_activity_input"},
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_approval_state.v1",
                 "invalid_activity_input" => true
               }
             }
           ] = invalid_approval_package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(invalid_approval_package)

    invalid_lifecycle_state =
      Timeline.activity_lifecycle_state(
        %{id: :cmd_lifecycle_missing_type, status: :planned, approval_status: :pending},
        nil
      )

    invalid_lifecycle_package =
      OperatorReview.from_timeline_activity_lifecycle_state(invalid_lifecycle_state)

    assert [
             %{
               "required_operator_action" => "review_activity_transition",
               "required_operator_actions" => [
                 "review_activity_approval",
                 "review_activity_transition",
                 "review_timeline_change"
               ],
               "invalid_activity_input" => true,
               "invalid_activity_input_count" => 1,
               "invalid_activity_input_reasons" => ["missing_activity_type"],
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_lifecycle_state.v1",
                 "invalid_activity_input" => true,
                 "invalid_activity_input_count" => 1
               }
             }
           ] = invalid_lifecycle_package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(invalid_lifecycle_package)
  end

  test "CandidateRefresh lifts accepted planning state activity status states" do
    planned = %{
      id: :cmd_accepted_state,
      type: :command,
      status: "In Progress",
      approval_status: "Approved",
      metadata: %{timeline_id: :"timeline:cmd_accepted_state"}
    }

    realized = %{
      id: :cmd_accepted_state,
      type: :command,
      status: "succeeded",
      approval_status: "Approved",
      metadata: %{timeline_id: :"timeline:cmd_accepted_state"}
    }

    state = Timeline.activity_status_state(planned, realized)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_activity_status_state_handoff",
      "accepted_planning_state" => %{
        "source_timeline_activity_status_state" => state
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_activity_status_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_timeline_activity_status_state.state",
               "timeline_id" => "timeline:cmd_accepted_state",
               "activity_id" => "cmd_accepted_state",
               "transition_decision" => "record",
               "required_operator_action" => "record_timeline_change",
               "approval_status" => "not_required",
               "import_action" => "import_replacement_activity",
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_status_state.v1",
                 "timeline_id" => "timeline:cmd_accepted_state"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_accepted_state",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.accepted_planning_state.source_timeline_activity_status_state.state",
                 "source_timeline_lifecycle_state" => %{
                   "schema_contract" => "timeline_activity_status_state.v1"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts accepted planning state aggregate activity states" do
    planned = %{
      id: :cmd_accepted_activity_state,
      type: :command,
      status: "In Progress",
      approval_status: "Approved",
      metadata: %{timeline_id: :"timeline:cmd_accepted_activity_state"}
    }

    realized = %{
      id: :cmd_accepted_activity_state,
      type: :command,
      status: "succeeded",
      approval_status: "Approved",
      metadata: %{timeline_id: :"timeline:cmd_accepted_activity_state"}
    }

    state = OrbitalDynamics.timeline_activity_state(planned, realized)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_activity_state_handoff",
      "accepted_planning_state" => %{
        "timeline_activity_state" => state
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_activity_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.timeline_activity_state.state",
               "timeline_id" => "timeline:cmd_accepted_activity_state",
               "activity_id" => "cmd_accepted_activity_state",
               "required_operator_action" => "record_timeline_change",
               "approval_status" => "not_required",
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_state.v1",
                 "timeline_id" => "timeline:cmd_accepted_activity_state"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_accepted_activity_state",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.accepted_planning_state.timeline_activity_state.state",
                 "source_timeline_lifecycle_state" => %{
                   "schema_contract" => "timeline_activity_state.v1"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state activity approval states" do
    planned = %{
      id: :cmd_mission_approval,
      type: :command,
      status: "planned",
      approval_status: "pending",
      metadata: %{timeline_id: :"timeline:cmd_mission_approval"}
    }

    realized = %{
      id: :cmd_mission_approval,
      type: :command,
      status: "planned",
      approval_status: "approved",
      metadata: %{timeline_id: :"timeline:cmd_mission_approval"}
    }

    state = Timeline.activity_approval_state(planned, realized)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_activity_approval_state_handoff",
      "mission_state" => %{
        "timeline_activity_approval_state" => state
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_activity_approval_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_approval" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.mission_state.timeline_activity_approval_state.state",
               "timeline_id" => "timeline:cmd_mission_approval",
               "activity_id" => "cmd_mission_approval",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "approval_status" => "operator_review_required",
               "approval_transition" => %{"transition_category" => "approval_granted"},
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_approval_state.v1",
                 "timeline_id" => "timeline:cmd_mission_approval"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_mission_approval",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.timeline_activity_approval_state.state",
                 "source_timeline_lifecycle_state" => %{
                   "schema_contract" => "timeline_activity_approval_state.v1"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state activity lifecycle states" do
    planned = %{
      id: :cmd_mission_lifecycle,
      type: :command,
      status: "planned",
      approval_status: "pending",
      locked: true,
      metadata: %{timeline_id: :"timeline:cmd_mission_lifecycle"}
    }

    realized = %{
      id: :cmd_mission_lifecycle,
      type: :command,
      status: "executed",
      approval_status: "approved",
      metadata: %{timeline_id: :"timeline:cmd_mission_lifecycle"}
    }

    state = Timeline.activity_lifecycle_state(planned, realized)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_activity_lifecycle_state_handoff",
      "mission_state" => %{
        "source_timeline_activity_lifecycle_state" => state
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_activity_lifecycle_state_handoff",
             "review_count" => 1,
             "timeline_lifecycle_state_review_count" => 1,
             "required_operator_action_counts" => %{"review_activity_approval" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_lifecycle_state_review",
               "source" =>
                 "candidate_refresh.mission_state.source_timeline_activity_lifecycle_state.state",
               "timeline_id" => "timeline:cmd_mission_lifecycle",
               "activity_id" => "cmd_mission_lifecycle",
               "transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "approval_status" => "operator_review_required",
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_lifecycle_state.v1",
                 "timeline_id" => "timeline:cmd_mission_lifecycle",
                 "planned_locked" => true
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_mission_lifecycle",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.source_timeline_activity_lifecycle_state.state",
                 "source_timeline_lifecycle_state" => %{
                   "schema_contract" => "timeline_activity_lifecycle_state.v1",
                   "planned_locked" => true
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline preservation artifacts become operator review rows" do
    activities = [
      %{id: :cmd_mutable, type: :command, status: :planned, approval_status: :pending},
      %{id: :contact_locked, type: :planned_contact, locked: true, approval_status: :pending},
      %{id: :obs_done, type: :observe, status: :completed},
      %{id: :bad_missing_type, status: :planned}
    ]

    report = Timeline.preservation_report(activities, source: "selected_activities")
    package = OperatorReview.from_timeline_preservation_report(report)

    atom_key_report =
      report
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    status = Timeline.preservation_status(%{id: :bad_missing_type, status: :planned})

    atom_key_status =
      status
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_preservation_report.v1",
             "source_artifact_id" => "selected_activities",
             "review_count" => 3,
             "timeline_preservation_review_count" => 3,
             "required_operator_action_counts" => %{
               "record_timeline_preservation" => 2,
               "review_timeline_preservation" => 1
             },
             "review_type_counts" => %{"timeline_preservation_review" => 3}
           } = package

    assert [
             %{
               "review_type" => "timeline_preservation_review",
               "source" => "timeline_preservation_report.rows",
               "subject_id" => "timeline:planned_contact",
               "timeline_id" => "timeline:planned_contact",
               "activity_id" => "contact_locked",
               "timeline_preservation_status" => "preservation_required",
               "requires_preservation" => true,
               "requires_operator_review" => false,
               "required_operator_action" => "record_timeline_preservation",
               "approval_status" => "not_required",
               "timeline_preservation_protection_decision" => "preserve",
               "timeline_preservation_protection_category" => "locked_or_approved",
               "timeline_preservation_protection_reason" => "activity_locked_or_approved",
               "preserve_activity_count" => 2,
               "review_change_activity_count" => 1,
               "preservation_sensitive_activity_count" => 3,
               "source_timeline_preservation" => %{
                 "activity_id" => "contact_locked",
                 "protection_decision" => "preserve"
               }
             },
             %{
               "activity_id" => "obs_done",
               "timeline_id" => "timeline:observe",
               "timeline_preservation_status" => "preservation_required",
               "required_operator_action" => "record_timeline_preservation",
               "approval_status" => "not_required",
               "timeline_preservation_protection_category" => "executed"
             },
             %{
               "activity_id" => "bad_missing_type",
               "timeline_id" => "timeline:invalid_activity_input:bad_missing_type",
               "timeline_preservation_status" => "review_required",
               "requires_operator_review" => true,
               "required_operator_action" => "review_timeline_preservation",
               "approval_status" => "operator_review_required",
               "timeline_preservation_protection_decision" => "review_change",
               "invalid_activity_input" => true
             }
           ] = package["rows"]

    assert OrbitalDynamics.operator_review_package(report) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(report, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_report) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_report, :schema_contract)) ==
             package

    status_package = OrbitalDynamics.operator_review_package(atom_key_status)

    assert OrbitalDynamics.operator_review_package(status) == status_package

    assert OrbitalDynamics.operator_review_package(Map.delete(status, "schema_contract")) ==
             status_package

    assert %{
             "source_artifact_type" => "timeline_preservation_status.v1",
             "source_artifact_id" => "timeline:invalid_activity_input:bad_missing_type",
             "review_count" => 1,
             "timeline_preservation_review_count" => 1
           } = status_package

    assert [
             %{
               "timeline_preservation_status" => "review_required",
               "required_operator_action" => "review_timeline_preservation",
               "source_timeline_preservation" => %{
                 "schema_contract" => "timeline_preservation_status.v1"
               }
             }
           ] = status_package["rows"]

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_status, :schema_contract)) ==
             status_package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_preservation =
      put_in(
        package,
        ["rows", Access.at(0), "source_timeline_preservation", "activity_id"],
        "bad activity id"
      )

    assert {:error, invalid_source_preservation_report} =
             Schema.validate_artifact(invalid_source_preservation)

    assert Enum.any?(
             invalid_source_preservation_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_preservation.activity_id" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "CandidateRefresh lifts accepted planning state preservation reports" do
    report =
      Timeline.preservation_report(
        [
          %{
            id: :cmd_accepted_preserve,
            type: :command,
            status: :planned,
            approval_status: :approved,
            metadata: %{timeline_id: :"timeline:cmd_accepted_preserve"}
          }
        ],
        source: "accepted_state.timeline_preservation_report"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_preservation_handoff",
      "accepted_planning_state" => %{
        "source_timeline_preservation_report" => report
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_preservation_handoff",
             "review_count" => 1,
             "timeline_preservation_review_count" => 1,
             "review_type_counts" => %{"timeline_preservation_review" => 1},
             "required_operator_action_counts" => %{"record_timeline_preservation" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_preservation_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_timeline_preservation_report.rows",
               "timeline_id" => "timeline:cmd_accepted_preserve",
               "activity_id" => "cmd_accepted_preserve",
               "timeline_preservation_status" => "preservation_required",
               "required_operator_action" => "record_timeline_preservation",
               "approval_status" => "not_required",
               "source_timeline_preservation" => %{
                 "activity_id" => "cmd_accepted_preserve",
                 "protection_decision" => "preserve"
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_preservation" => 1},
             "source_review_type_counts" => %{"timeline_preservation_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_preservation",
               "source_review_type" => "timeline_preservation_review",
               "timeline_id" => "timeline:cmd_accepted_preserve",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.accepted_planning_state.source_timeline_preservation_report.rows",
                 "source_timeline_preservation" => %{
                   "activity_id" => "cmd_accepted_preserve",
                   "protection_decision" => "preserve"
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state preservation statuses" do
    status =
      Timeline.preservation_status(%{
        id: :cmd_mission_preservation_review,
        status: :planned
      })

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_preservation_status_handoff",
      "mission_state" => %{
        "timeline_preservation_status" => status
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_preservation_status_handoff",
             "review_count" => 1,
             "timeline_preservation_review_count" => 1,
             "review_type_counts" => %{"timeline_preservation_review" => 1},
             "required_operator_action_counts" => %{"review_timeline_preservation" => 1}
           } = review

    assert [
             %{
               "review_type" => "timeline_preservation_review",
               "source" => "candidate_refresh.mission_state.timeline_preservation_status.status",
               "timeline_id" => "timeline:invalid_activity_input:cmd_mission_preservation_review",
               "activity_id" => "cmd_mission_preservation_review",
               "timeline_preservation_status" => "review_required",
               "required_operator_action" => "review_timeline_preservation",
               "approval_status" => "operator_review_required",
               "invalid_activity_input" => true,
               "source_timeline_preservation" => %{
                 "schema_contract" => "timeline_preservation_status.v1",
                 "invalid_activity_input" => true
               }
             }
           ] = review["rows"]

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_timeline_preservation" => 1},
             "source_review_type_counts" => %{"timeline_preservation_review" => 1}
           } = import

    assert [
             %{
               "import_action" => "review_timeline_preservation",
               "source_review_type" => "timeline_preservation_review",
               "timeline_id" => "timeline:invalid_activity_input:cmd_mission_preservation_review",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.timeline_preservation_status.status",
                 "source_timeline_preservation" => %{
                   "schema_contract" => "timeline_preservation_status.v1",
                   "invalid_activity_input" => true
                 }
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts all nested preservation source paths" do
    report =
      Timeline.preservation_report(
        [
          %{
            id: :cmd_nested_preserve,
            type: :command,
            status: :planned,
            approval_status: :approved,
            metadata: %{timeline_id: :"timeline:cmd_nested_preserve"}
          }
        ],
        source: "nested.timeline_preservation_report"
      )

    status =
      Timeline.preservation_status(%{
        id: :cmd_nested_preservation_review,
        status: :planned
      })

    cases = [
      {"accepted_planning_state", "source_timeline_preservation_report", report, ".rows",
       %{
         "activity_id" => "cmd_nested_preserve",
         "timeline_id" => "timeline:cmd_nested_preserve",
         "operator_action" => "record_timeline_preservation",
         "evidence" => %{"activity_id" => "cmd_nested_preserve"}
       }},
      {"accepted_planning_state", "timeline_preservation_report", report, ".rows",
       %{
         "activity_id" => "cmd_nested_preserve",
         "timeline_id" => "timeline:cmd_nested_preserve",
         "operator_action" => "record_timeline_preservation",
         "evidence" => %{"activity_id" => "cmd_nested_preserve"}
       }},
      {"accepted_planning_state", "source_timeline_preservation_status", status, ".status",
       %{
         "activity_id" => "cmd_nested_preservation_review",
         "timeline_id" => "timeline:invalid_activity_input:cmd_nested_preservation_review",
         "operator_action" => "review_timeline_preservation",
         "evidence" => %{
           "schema_contract" => "timeline_preservation_status.v1",
           "invalid_activity_input" => true
         }
       }},
      {"accepted_planning_state", "timeline_preservation_status", status, ".status",
       %{
         "activity_id" => "cmd_nested_preservation_review",
         "timeline_id" => "timeline:invalid_activity_input:cmd_nested_preservation_review",
         "operator_action" => "review_timeline_preservation",
         "evidence" => %{
           "schema_contract" => "timeline_preservation_status.v1",
           "invalid_activity_input" => true
         }
       }},
      {"mission_state", "source_timeline_preservation_report", report, ".rows",
       %{
         "activity_id" => "cmd_nested_preserve",
         "timeline_id" => "timeline:cmd_nested_preserve",
         "operator_action" => "record_timeline_preservation",
         "evidence" => %{"activity_id" => "cmd_nested_preserve"}
       }},
      {"mission_state", "timeline_preservation_report", report, ".rows",
       %{
         "activity_id" => "cmd_nested_preserve",
         "timeline_id" => "timeline:cmd_nested_preserve",
         "operator_action" => "record_timeline_preservation",
         "evidence" => %{"activity_id" => "cmd_nested_preserve"}
       }},
      {"mission_state", "source_timeline_preservation_status", status, ".status",
       %{
         "activity_id" => "cmd_nested_preservation_review",
         "timeline_id" => "timeline:invalid_activity_input:cmd_nested_preservation_review",
         "operator_action" => "review_timeline_preservation",
         "evidence" => %{
           "schema_contract" => "timeline_preservation_status.v1",
           "invalid_activity_input" => true
         }
       }},
      {"mission_state", "timeline_preservation_status", status, ".status",
       %{
         "activity_id" => "cmd_nested_preservation_review",
         "timeline_id" => "timeline:invalid_activity_input:cmd_nested_preservation_review",
         "operator_action" => "review_timeline_preservation",
         "evidence" => %{
           "schema_contract" => "timeline_preservation_status.v1",
           "invalid_activity_input" => true
         }
       }}
    ]

    Enum.each(cases, fn {state_key, field, payload, source_suffix, expected} ->
      source = "candidate_refresh.#{state_key}.#{field}#{source_suffix}"

      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "refresh_id" => "refresh:#{state_key}:#{field}",
        state_key => %{field => payload}
      }

      review = OperatorReview.from_candidate_refresh_artifact(artifact)
      import = CadenceImport.from_candidate_refresh_artifact(artifact)

      assert %{
               "review_count" => 1,
               "timeline_preservation_review_count" => 1,
               "review_type_counts" => %{"timeline_preservation_review" => 1}
             } = review

      assert [
               %{
                 "review_type" => "timeline_preservation_review",
                 "source" => ^source,
                 "timeline_id" => expected_timeline_id,
                 "activity_id" => expected_activity_id,
                 "required_operator_action" => expected_operator_action,
                 "source_timeline_preservation" => source_evidence
               }
             ] = review["rows"]

      assert expected_timeline_id == expected["timeline_id"]
      assert expected_activity_id == expected["activity_id"]
      assert expected_operator_action == expected["operator_action"]
      assert Map.take(source_evidence, Map.keys(expected["evidence"])) == expected["evidence"]

      assert %{
               "row_count" => 1,
               "import_action_counts" => %{"review_timeline_preservation" => 1},
               "source_review_type_counts" => %{"timeline_preservation_review" => 1}
             } = import

      assert [
               %{
                 "import_action" => "review_timeline_preservation",
                 "source_review_type" => "timeline_preservation_review",
                 "timeline_id" => ^expected_timeline_id,
                 "source_review_row" => %{
                   "source" => ^source,
                   "source_timeline_preservation" => import_source_evidence
                 }
               }
             ] = import["rows"]

      assert Map.take(import_source_evidence, Map.keys(expected["evidence"])) ==
               expected["evidence"]
    end)
  end

  test "timeline integrity reports become operator review rows" do
    report = timeline_integrity_report()
    package = OperatorReview.from_timeline_integrity_report(report)

    atom_key_report =
      report
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_integrity_report.v1",
             "source_artifact_id" => "selected_activities",
             "review_count" => 2,
             "timeline_integrity_review_count" => 2,
             "required_operator_action_counts" => %{"review_timeline_integrity" => 2},
             "review_type_counts" => %{"timeline_integrity_review" => 2}
           } = package

    assert [
             %{
               "review_type" => "timeline_integrity_review",
               "source" => "timeline_integrity_report.rows",
               "activity_id" => "dl_conflict",
               "timeline_id" => "timeline:downlink:12.0",
               "timeline_integrity_status" => "review_required",
               "timeline_integrity_issue_types" => [
                 "duplicate_exclusivity_timeline",
                 "exclusivity_overlap"
               ],
               "exclusivity_violation_activity_ids" => ["cmd_main"],
               "exclusivity_violation_timeline_ids" => ["timeline:command:dss_14:10.0"],
               "duplicate_exclusivity_timeline_ids" => ["timeline:command:dss_14:10.0"],
               "source_timeline_integrity_issue_count" => 11,
               "source_exclusivity_issue_count" => 5,
               "source_timeline_integrity" => %{
                 "activity_id" => "dl_conflict",
                 "timeline_integrity_status" => "review_required",
                 "exclusivity_violation_timeline_ids" => ["timeline:command:dss_14:10.0"],
                 "duplicate_exclusivity_timeline_ids" => ["timeline:command:dss_14:10.0"]
               }
             },
             %{
               "activity_id" => "cmd_main",
               "timeline_id" => "timeline:command:dss_14:10.0",
               "required_operator_action" => "review_timeline_integrity",
               "approval_status" => "operator_review_required",
               "timeline_integrity_issue_count" => 8,
               "missing_dependency_activity_ids" => ["missing_gate"],
               "missing_dependency_timeline_ids" => [
                 "timeline:health_gate",
                 "timeline:missing_gate"
               ],
               "duplicate_dependency_activity_ids" => ["health_gate"],
               "duplicate_dependency_timeline_ids" => ["timeline:health_gate"],
               "dependency_order_violation_activity_ids" => ["health_gate"],
               "exclusivity_violation_activity_ids" => ["dl_conflict"],
               "exclusivity_violation_timeline_ids" => ["timeline:downlink:12.0"],
               "dependency_review_activity_ids" => ["cmd_main"],
               "dependency_review_timeline_ids" => ["timeline:command:dss_14:10.0"],
               "exclusivity_review_activity_ids" => ["cmd_main", "dl_conflict"],
               "exclusivity_review_timeline_ids" => [
                 "timeline:command:dss_14:10.0",
                 "timeline:downlink:12.0"
               ],
               "review_activity_ids" => ["cmd_main", "dl_conflict"],
               "review_timeline_ids" => [
                 "timeline:command:dss_14:10.0",
                 "timeline:downlink:12.0"
               ],
               "source_timeline_integrity" => %{
                 "activity_template" => %{
                   "schema_contract" => "activity_template.v1",
                   "id" => "template:command:basic",
                   "activity_type" => "command"
                 },
                 "activity_context" => %{
                   "activity_template" => %{
                     "id" => "template:command:basic",
                     "activity_type" => "command"
                   }
                 }
               }
             }
           ] = package["rows"]

    assert "missing_dependency_activity" in hd(tl(package["rows"]))[
             "timeline_integrity_issue_types"
           ]

    assert "dependency_order_violation" in hd(tl(package["rows"]))[
             "timeline_integrity_issue_types"
           ]

    assert "exclusivity_overlap" in hd(tl(package["rows"]))["timeline_integrity_issue_types"]

    assert OrbitalDynamics.operator_review_package(report) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(report, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_report) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_report, :schema_contract)) ==
             package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_integrity =
      put_in(
        package,
        ["rows", Access.at(0), "source_timeline_integrity", "timeline_integrity_issue_types"],
        []
      )

    assert {:error, invalid_source_integrity_report} =
             Schema.validate_artifact(invalid_source_integrity)

    assert Enum.any?(
             invalid_source_integrity_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_integrity.timeline_integrity_issue_types")
           )
  end

  test "CandidateRefresh lifts accepted planning state timeline integrity reports" do
    report =
      timeline_integrity_report()
      |> Map.put("source", "accepted_state.timeline_integrity_report")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_timeline_integrity_handoff",
      "accepted_planning_state" => %{
        "timeline_integrity_report" => report
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_timeline_integrity_handoff",
             "review_count" => 2,
             "timeline_integrity_review_count" => 2,
             "review_type_counts" => %{"timeline_integrity_review" => 2},
             "required_operator_action_counts" => %{"review_timeline_integrity" => 2}
           } = review

    assert Enum.map(review["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.timeline_integrity_report.rows",
             "candidate_refresh.accepted_planning_state.timeline_integrity_report.rows"
           ]

    assert %{
             "review_type" => "timeline_integrity_review",
             "source" =>
               "candidate_refresh.accepted_planning_state.timeline_integrity_report.rows",
             "activity_id" => "cmd_main",
             "timeline_id" => "timeline:command:dss_14:10.0",
             "source_timeline_integrity_issue_count" => 11,
             "source_dependency_issue_count" => 6,
             "missing_dependency_activity_ids" => ["missing_gate"],
             "duplicate_dependency_activity_ids" => ["health_gate"],
             "source_timeline_integrity" => %{
               "activity_id" => "cmd_main",
               "timeline_integrity_status" => "review_required",
               "activity_template" => %{
                 "schema_contract" => "activity_template.v1",
                 "id" => "template:command:basic"
               }
             }
           } = Enum.find(review["rows"], &(&1["activity_id"] == "cmd_main"))

    assert %{
             "row_count" => 2,
             "import_action_counts" => %{"review_timeline_integrity" => 2},
             "source_review_type_counts" => %{"timeline_integrity_review" => 2}
           } = import

    assert %{
             "import_action" => "review_timeline_integrity",
             "source_review_type" => "timeline_integrity_review",
             "activity_id" => "cmd_main",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.timeline_integrity_report.rows",
               "source_timeline_integrity" => %{
                 "activity_id" => "cmd_main",
                 "timeline_integrity_status" => "review_required"
               }
             }
           } = Enum.find(import["rows"], &(&1["activity_id"] == "cmd_main"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state timeline integrity reports" do
    report =
      timeline_integrity_report()
      |> Map.put("source", "mission_state.timeline_integrity_report")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_timeline_integrity_handoff",
      "mission_state" => %{
        "source_timeline_integrity_report" => report
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_timeline_integrity_handoff",
             "review_count" => 2,
             "timeline_integrity_review_count" => 2
           } = review

    assert Enum.map(review["rows"], & &1["source"]) == [
             "candidate_refresh.mission_state.source_timeline_integrity_report.rows",
             "candidate_refresh.mission_state.source_timeline_integrity_report.rows"
           ]

    assert %{
             "review_type" => "timeline_integrity_review",
             "source" => "candidate_refresh.mission_state.source_timeline_integrity_report.rows",
             "activity_id" => "dl_conflict",
             "timeline_id" => "timeline:downlink:12.0",
             "timeline_integrity_issue_types" => [
               "duplicate_exclusivity_timeline",
               "exclusivity_overlap"
             ],
             "source_exclusivity_issue_count" => 5,
             "exclusivity_violation_activity_ids" => ["cmd_main"],
             "source_timeline_integrity" => %{
               "activity_id" => "dl_conflict",
               "exclusivity_violation_timeline_ids" => ["timeline:command:dss_14:10.0"]
             }
           } = Enum.find(review["rows"], &(&1["activity_id"] == "dl_conflict"))

    assert %{
             "row_count" => 2,
             "import_action_counts" => %{"review_timeline_integrity" => 2},
             "source_review_type_counts" => %{"timeline_integrity_review" => 2}
           } = import

    assert %{
             "import_action" => "review_timeline_integrity",
             "source_review_type" => "timeline_integrity_review",
             "activity_id" => "dl_conflict",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.mission_state.source_timeline_integrity_report.rows",
               "source_timeline_integrity" => %{
                 "activity_id" => "dl_conflict"
               }
             }
           } = Enum.find(import["rows"], &(&1["activity_id"] == "dl_conflict"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "candidate refresh result artifact timeline diff reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_timeline_diff_review:001",
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_diff_report" => %{
            "schema_contract" => "timeline_diff_report.v1",
            "source" => "wrapped.timeline_diff_report",
            "rows" => [
              %{
                "id" => "timeline_diff:timeline:obs_wrapped",
                "rank" => 1,
                "timeline_id" => "timeline:obs_wrapped",
                "diff_status" => "changed",
                "source_activity_id" => "obs_wrapped",
                "replacement_activity_id" => "obs_wrapped_b",
                "source_activity_type" => "observe",
                "replacement_activity_type" => "observe",
                "scenario_id" => "leo_1",
                "source_starts_at_s" => 10.0,
                "source_ends_at_s" => 20.0,
                "replacement_starts_at_s" => 12.0,
                "replacement_ends_at_s" => 22.0,
                "start_delta_s" => 2.0,
                "end_delta_s" => 2.0,
                "source_status" => "approved",
                "replacement_status" => "planned",
                "changed_fields" => ["starts_at_s", "ends_at_s"],
                "requires_operator_review" => true,
                "required_operator_action" => "review_timeline_change",
                "reason" => "replacement timeline changes activity obs_wrapped",
                "source_timeline_identity" => %{"timeline_id" => "timeline:obs_wrapped"},
                "replacement_timeline_identity" => %{
                  "timeline_id" => "timeline:obs_wrapped"
                }
              },
              %{
                "id" => "timeline_diff:timeline:health_wrapped",
                "timeline_id" => "timeline:health_wrapped",
                "diff_status" => "unchanged",
                "requires_operator_review" => false,
                "required_operator_action" => "none"
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_timeline_diff_review:001",
             "review_count" => 1,
             "timeline_diff_count" => 1
           } = package

    assert [
             %{
               "review_type" => "timeline_diff_review",
               "source" => "candidate_refresh.result_artifact[0].timeline_diff_report.rows",
               "subject_id" => "timeline:obs_wrapped",
               "timeline_id" => "timeline:obs_wrapped",
               "diff_status" => "changed",
               "activity_id" => "obs_wrapped_b",
               "source_activity_id" => "obs_wrapped",
               "replacement_activity_id" => "obs_wrapped_b",
               "required_operator_action" => "review_timeline_change",
               "operator_action_reason" => "replacement timeline changes activity obs_wrapped",
               "changed_fields" => ["starts_at_s", "ends_at_s"],
               "source_timeline_diff" => %{"timeline_id" => "timeline:obs_wrapped"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source timeline transition application reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_timeline_transition_review:001",
      "source_timeline_transition_application_report" => [
        %{
          "schema_contract" => "timeline_transition_application_report.v1",
          "source" => "mission_state.source_timeline_transition_application_report",
          "applications" => [
            %{
              "id" => "timeline_transition_application:timeline:cmd_added",
              "rank" => 1,
              "timeline_id" => "timeline:cmd_added",
              "diff_status" => "added",
              "changed_fields" => ["activity_added"],
              "transition_decision" => "review",
              "application_status" => "operator_review_required",
              "selected_activity_source" => "replacement",
              "selected_activity" => %{
                "activity_id" => "cmd_added",
                "starts_at_s" => 40.0,
                "ends_at_s" => 50.0
              },
              "requires_operator_review" => true,
              "required_operator_action" => "review_timeline_change",
              "reason" => "replacement timeline adds command activity cmd_added",
              "source_timeline_diff" => %{
                "id" => "timeline_diff:timeline:cmd_added",
                "rank" => 1,
                "timeline_id" => "timeline:cmd_added",
                "diff_status" => "added",
                "replacement_activity_id" => "cmd_added",
                "replacement_activity_type" => "command",
                "scenario_id" => "leo_1",
                "replacement_starts_at_s" => 40.0,
                "replacement_ends_at_s" => 50.0,
                "changed_fields" => ["activity_added"],
                "requires_operator_review" => true,
                "required_operator_action" => "review_timeline_change",
                "reason" => "replacement timeline adds command activity cmd_added",
                "status_transition" => %{
                  "field" => "status",
                  "transition_type" => "added",
                  "transition_category" => "status_added"
                },
                "approval_transition" => %{
                  "field" => "approval_status",
                  "transition_type" => "added",
                  "transition_category" => "approval_review_required"
                }
              }
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_timeline_transition_review:001",
             "review_count" => 1,
             "timeline_diff_count" => 1
           } = package

    assert [
             %{
               "review_type" => "timeline_diff_review",
               "source" =>
                 "candidate_refresh.source_timeline_transition_application_report[0].applications",
               "timeline_id" => "timeline:cmd_added",
               "diff_status" => "added",
               "activity_id" => "cmd_added",
               "replacement_activity_id" => "cmd_added",
               "required_operator_action" => "review_timeline_change",
               "application_status" => "operator_review_required",
               "selected_activity_source" => "replacement",
               "selected_activity" => %{"activity_id" => "cmd_added"},
               "source_timeline_application" => %{
                 "application_status" => "operator_review_required"
               },
               "source_timeline_diff" => %{
                 "timeline_id" => "timeline:cmd_added",
                 "application_status" => "operator_review_required"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source constraint reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_constraint_review:001",
      "source_constraint_report" => [
        %{
          "schema_contract" => "constraint_report.v1",
          "source" => "mission_state.source_constraint_report",
          "rows" => [
            %{
              "constraint_id" => "minimum_operational_altitude",
              "metric" => "min_altitude_km",
              "operator" => ">=",
              "scenario_id" => "dispersion_1",
              "score" => 0.42,
              "status" => "pass",
              "threshold" => 621.5,
              "value" => 621.92
            },
            %{
              "constraint_id" => "downlink_margin",
              "metric" => "estimated_throughput_mb",
              "operator" => ">=",
              "scenario_id" => "dispersion_2",
              "status" => "warning",
              "threshold" => 120.0,
              "value" => 96.0
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_constraint_review:001",
             "review_count" => 1,
             "constraint_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "constraint_review",
               "source" => "candidate_refresh.source_constraint_report[0].rows",
               "subject_id" => "dispersion_2",
               "scenario_id" => "dispersion_2",
               "constraint_id" => "downlink_margin",
               "metric" => "estimated_throughput_mb",
               "constraint_status" => "warning",
               "required_operator_action" => "review_constraint",
               "source_constraint_row" => %{
                 "constraint_id" => "downlink_margin",
                 "status" => "warning"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact constraint reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_constraint_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "constraint_report" => %{
          "schema_contract" => "constraint_report.v1",
          "source" => "wrapped.constraint_report",
          "rows" => [
            %{
              "constraint_id" => "minimum_operational_altitude",
              "metric" => "min_altitude_km",
              "operator" => ">=",
              "scenario_id" => "dispersion_1",
              "score" => 0.42,
              "status" => "pass",
              "threshold" => 621.5,
              "value" => 621.92
            },
            %{
              "constraint_id" => "downlink_margin",
              "metric" => "estimated_throughput_mb",
              "operator" => ">=",
              "scenario_id" => "dispersion_2",
              "status" => "warning",
              "threshold" => 120.0,
              "value" => 96.0
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_constraint_review:001",
             "review_count" => 1,
             "constraint_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "constraint_review",
               "source" => "candidate_refresh.source_result_artifact.constraint_report.rows",
               "subject_id" => "dispersion_2",
               "scenario_id" => "dispersion_2",
               "constraint_id" => "downlink_margin",
               "metric" => "estimated_throughput_mb",
               "constraint_status" => "warning",
               "required_operator_action" => "review_constraint",
               "source_constraint_row" => %{
                 "constraint_id" => "downlink_margin",
                 "status" => "warning"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source objective satisfaction reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_objective_satisfaction_review:001",
      "source_objective_satisfaction_report" => [
        %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "source" => "mission_state.source_objective_satisfaction_report",
          "rows" => [
            %{
              "id" => "objective:target_coverage",
              "objective" => "target_coverage",
              "status" => "selected",
              "required_count" => 1,
              "candidate_count" => 1,
              "selected_count" => 1,
              "satisfied_count" => 1,
              "selected_activity_ids" => ["obs_target_a"]
            },
            %{
              "id" => "objective:downlink_completion",
              "objective" => "downlink_completion",
              "status" => "unmet",
              "required_downlink_mb" => 150.0,
              "candidate_downlink_mb" => 160.0,
              "candidate_count" => 1,
              "selected_count" => 0,
              "satisfied_count" => 0,
              "selected_downlink_mb" => 0.0,
              "satisfied_downlink_mb" => 0.0,
              "selected_contact_ids" => []
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_objective_satisfaction_review:001",
             "review_count" => 1,
             "objective_satisfaction_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "objective_satisfaction_review",
               "source" => "candidate_refresh.source_objective_satisfaction_report[0].rows",
               "subject_id" => "objective:downlink_completion",
               "objective" => "downlink_completion",
               "objective_status" => "unmet",
               "required_downlink_mb" => 150.0,
               "candidate_downlink_mb" => 160.0,
               "required_operator_action" => "review_objective_satisfaction",
               "source_objective_satisfaction" => %{
                 "objective" => "downlink_completion",
                 "status" => "unmet"
               }
             } = row
           ] = package["rows"]

    assert row["selected_downlink_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact objective satisfaction reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_objective_satisfaction_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "source" => "wrapped.objective_satisfaction_report",
          "rows" => [
            %{
              "id" => "objective:target_coverage",
              "objective" => "target_coverage",
              "status" => "selected",
              "required_count" => 1,
              "candidate_count" => 1,
              "selected_count" => 1,
              "satisfied_count" => 1,
              "selected_activity_ids" => ["obs_target_a"]
            },
            %{
              "id" => "objective:downlink_completion",
              "objective" => "downlink_completion",
              "status" => "unmet",
              "required_downlink_mb" => 150.0,
              "candidate_downlink_mb" => 160.0,
              "candidate_count" => 1,
              "selected_count" => 0,
              "satisfied_count" => 0,
              "selected_downlink_mb" => 0.0,
              "satisfied_downlink_mb" => 0.0,
              "selected_contact_ids" => []
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_objective_satisfaction_review:001",
             "review_count" => 1,
             "objective_satisfaction_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "objective_satisfaction_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.objective_satisfaction_report.rows",
               "subject_id" => "objective:downlink_completion",
               "objective" => "downlink_completion",
               "objective_status" => "unmet",
               "required_downlink_mb" => 150.0,
               "candidate_downlink_mb" => 160.0,
               "required_operator_action" => "review_objective_satisfaction",
               "source_objective_satisfaction" => %{
                 "objective" => "downlink_completion",
                 "status" => "unmet"
               }
             } = row
           ] = package["rows"]

    assert row["selected_downlink_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source score term reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_score_term_review:001",
      "source_score_term_report" => [
        %{
          "schema_contract" => "score_term_report.v1",
          "source" => "mission_state.source_score_term_report",
          "rows" => [
            %{
              "id" => "score_term:leo_1:1:target_value",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "target_value",
              "value" => 120.0,
              "timeline_score" => 140.0,
              "selected" => true
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_score_term_review:001",
             "review_count" => 1,
             "score_term_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "score_term_review",
               "source" => "candidate_refresh.source_score_term_report[0].rows",
               "subject_id" => "score_term:leo_1:1:target_value",
               "scenario_id" => "leo_1",
               "term_key" => "target_value",
               "value" => 120.0,
               "timeline_score" => 140.0,
               "selected" => true,
               "required_operator_action" => "review_score_term",
               "source_score_term" => %{"term_key" => "target_value"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact score term reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_score_term_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "source" => "wrapped.score_term_report",
          "rows" => [
            %{
              "id" => "score_term:leo_1:1:target_value",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "target_value",
              "value" => 120.0,
              "timeline_score" => 140.0,
              "selected" => true
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_score_term_review:001",
             "review_count" => 1,
             "score_term_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "score_term_review",
               "source" => "candidate_refresh.source_result_artifact.score_term_report.rows",
               "subject_id" => "score_term:leo_1:1:target_value",
               "scenario_id" => "leo_1",
               "term_key" => "target_value",
               "value" => 120.0,
               "timeline_score" => 140.0,
               "selected" => true,
               "required_operator_action" => "review_score_term",
               "source_score_term" => %{"term_key" => "target_value"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source objective tradeoff reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_objective_tradeoff_review:001",
      "source_objective_tradeoff_report" => [
        %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "source" => "mission_state.source_objective_tradeoff_report",
          "tradeoffs" => [
            %{
              "rank" => 1,
              "scenario_id" => "leo_1",
              "score" => 140.0,
              "score_delta_from_selected" => 0.0,
              "activity_count" => 2,
              "selected_observation_count" => 1,
              "selected_contact_count" => 1,
              "score_terms" => %{"target_value" => 150.0},
              "activity_ids" => ["leo_1_observe_target_a_1", "leo_1_downlink_1"]
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_objective_tradeoff_review:001",
             "review_count" => 1,
             "objective_tradeoff_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "objective_tradeoff_review",
               "source" => "candidate_refresh.source_objective_tradeoff_report[0].tradeoffs",
               "subject_id" => "leo_1",
               "scenario_id" => "leo_1",
               "score" => 140.0,
               "activity_count" => 2,
               "selected_observation_count" => 1,
               "selected_contact_count" => 1,
               "score_terms" => %{"target_value" => 150.0},
               "activity_ids" => ["leo_1_observe_target_a_1", "leo_1_downlink_1"],
               "required_operator_action" => "review_objective_tradeoff",
               "source_objective_tradeoff" => %{"scenario_id" => "leo_1"}
             } = row
           ] = package["rows"]

    assert row["score_delta_from_selected"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact objective tradeoff reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_objective_tradeoff_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "source" => "wrapped.objective_tradeoff_report",
          "tradeoffs" => [
            %{
              "rank" => 1,
              "scenario_id" => "leo_1",
              "score" => 140.0,
              "score_delta_from_selected" => 0.0,
              "activity_count" => 2,
              "selected_observation_count" => 1,
              "selected_contact_count" => 1,
              "score_terms" => %{"target_value" => 150.0},
              "activity_ids" => ["leo_1_observe_target_a_1", "leo_1_downlink_1"]
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_objective_tradeoff_review:001",
             "review_count" => 1,
             "objective_tradeoff_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "objective_tradeoff_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.objective_tradeoff_report.tradeoffs",
               "subject_id" => "leo_1",
               "scenario_id" => "leo_1",
               "score" => 140.0,
               "activity_count" => 2,
               "selected_observation_count" => 1,
               "selected_contact_count" => 1,
               "score_terms" => %{"target_value" => 150.0},
               "activity_ids" => ["leo_1_observe_target_a_1", "leo_1_downlink_1"],
               "required_operator_action" => "review_objective_tradeoff",
               "source_objective_tradeoff" => %{"scenario_id" => "leo_1"}
             } = row
           ] = package["rows"]

    assert row["score_delta_from_selected"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source contact contention reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_contact_contention_review:001",
      "source_contact_contention_report" => [
        %{
          "schema_contract" => "contact_contention_report.v1",
          "source" => "mission_state.source_contact_contention_report",
          "invalid_contact_inputs" => [
            %{
              "id" => "invalid_contact:malformed_contact",
              "contact_id" => "malformed_contact",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 90.0,
              "ends_at_s" => 120.0,
              "direction" => "downlink",
              "required_operator_action" => "review_invalid_contact_contention_input",
              "approval_status" => "operator_review_required",
              "operator_action_reason" => "invalid_contact_shape",
              "invalid_contact_input_reason" => "invalid_contact_shape"
            }
          ],
          "conflict_groups" => [
            %{
              "id" => "station:equator_prime:contention:1",
              "ground_station_id" => "equator_prime",
              "contact_count" => 2,
              "starts_at_s" => 100.0,
              "ends_at_s" => 220.0,
              "direction" => "downlink",
              "required_operator_action" => "review_contact_contention",
              "approval_status" => "operator_review_required",
              "operator_action_reason" => "same_station_overlapping_contact_windows",
              "contact_ids" => ["dl_1", "dl_2"],
              "source_window_ids" => [
                "window:leo_1:ground_station_access:equator_prime:1",
                "window:leo_2:ground_station_access:equator_prime:1"
              ],
              "scenario_ids" => ["leo_1", "leo_2"]
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_contact_contention_review:001",
             "review_count" => 2,
             "contention_review_count" => 2
           } = package

    assert [invalid_row, group_row] = package["rows"]

    assert %{
             "review_type" => "contact_contention_review",
             "source" =>
               "candidate_refresh.source_contact_contention_report[0].invalid_contact_inputs",
             "subject_id" => "invalid_contact:malformed_contact",
             "contact_id" => "malformed_contact",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "required_operator_action" => "review_invalid_contact_contention_input",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_invalid_contact_input" => %{
               "contact_id" => "malformed_contact",
               "invalid_contact_input_reason" => "invalid_contact_shape"
             }
           } = invalid_row

    assert invalid_row["starts_at_s"] == 90.0

    assert %{
             "review_type" => "contact_contention_review",
             "source" => "candidate_refresh.source_contact_contention_report[0].conflict_groups",
             "subject_id" => "station:equator_prime:contention:1",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "contact_count" => 2,
             "contact_ids" => ["dl_1", "dl_2"],
             "source_window_ids" => [
               "window:leo_1:ground_station_access:equator_prime:1",
               "window:leo_2:ground_station_access:equator_prime:1"
             ],
             "scenario_ids" => ["leo_1", "leo_2"],
             "required_operator_action" => "review_contact_contention",
             "approval_status" => "operator_review_required",
             "source_contention_group" => %{"contact_ids" => ["dl_1", "dl_2"]}
           } = group_row

    assert group_row["starts_at_s"] == 100.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact contact contention reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_contact_contention_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "contact_allocation_report" => %{
          "schema_contract" => "contact_allocation_report.v1",
          "contact_contention_report" => %{
            "schema_contract" => "contact_contention_report.v1",
            "invalid_contact_inputs" => [
              %{
                "id" => "invalid_contact:wrapped_malformed_contact",
                "contact_id" => "wrapped_malformed_contact",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 90.0,
                "ends_at_s" => 120.0,
                "direction" => "downlink",
                "required_operator_action" => "review_invalid_contact_contention_input",
                "approval_status" => "operator_review_required",
                "operator_action_reason" => "invalid_contact_shape",
                "invalid_contact_input_reason" => "invalid_contact_shape"
              }
            ],
            "conflict_groups" => [
              %{
                "id" => "station:equator_prime:wrapped_contention:1",
                "ground_station_id" => "equator_prime",
                "contact_count" => 2,
                "starts_at_s" => 100.0,
                "ends_at_s" => 220.0,
                "direction" => "downlink",
                "required_operator_action" => "review_contact_contention",
                "approval_status" => "operator_review_required",
                "operator_action_reason" => "same_station_overlapping_contact_windows",
                "contact_ids" => ["dl_wrapped_1", "dl_wrapped_2"],
                "source_window_ids" => [
                  "window:leo_1:ground_station_access:equator_prime:1",
                  "window:leo_2:ground_station_access:equator_prime:1"
                ],
                "scenario_ids" => ["leo_1", "leo_2"]
              }
            ]
          }
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_contact_contention_review:001",
             "review_count" => 2,
             "contention_review_count" => 2
           } = package

    assert [invalid_row, group_row] = package["rows"]

    assert %{
             "review_type" => "contact_contention_review",
             "source" =>
               "candidate_refresh.source_result_artifact.contact_allocation_report.contact_contention_report.invalid_contact_inputs",
             "subject_id" => "invalid_contact:wrapped_malformed_contact",
             "contact_id" => "wrapped_malformed_contact",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "required_operator_action" => "review_invalid_contact_contention_input",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_invalid_contact_input" => %{
               "contact_id" => "wrapped_malformed_contact",
               "invalid_contact_input_reason" => "invalid_contact_shape"
             }
           } = invalid_row

    assert invalid_row["starts_at_s"] == 90.0

    assert %{
             "review_type" => "contact_contention_review",
             "source" =>
               "candidate_refresh.source_result_artifact.contact_allocation_report.contact_contention_report.conflict_groups",
             "subject_id" => "station:equator_prime:wrapped_contention:1",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "contact_count" => 2,
             "contact_ids" => ["dl_wrapped_1", "dl_wrapped_2"],
             "scenario_ids" => ["leo_1", "leo_2"],
             "required_operator_action" => "review_contact_contention",
             "approval_status" => "operator_review_required",
             "source_contention_group" => %{
               "contact_ids" => ["dl_wrapped_1", "dl_wrapped_2"]
             }
           } = group_row

    assert group_row["starts_at_s"] == 100.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source contact contention resolution reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_contact_contention_resolution_review:001",
      "source_contact_contention_resolution_report" => [
        %{
          "schema_contract" => "contact_contention_resolution_report.v1",
          "source" => "mission_state.source_contact_contention_resolution_report",
          "recommendations" => [
            %{
              "group_id" => "station:equator_prime:contention:1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 100.0,
              "ends_at_s" => 220.0,
              "selected_contact_id" => "dl_1",
              "deferred_contact_ids" => ["dl_2"],
              "candidate_count" => 2,
              "selection_reason" => "highest_score_earliest_start",
              "action" => "recommend_preferred_contact_for_operator_review",
              "review_status" => "operator_review_required"
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:source_contact_contention_resolution_review:001",
             "review_count" => 1,
             "contention_recommendation_count" => 1
           } = package

    assert [
             %{
               "review_type" => "contact_contention_recommendation",
               "source" =>
                 "candidate_refresh.source_contact_contention_resolution_report[0].recommendations",
               "subject_id" => "station:equator_prime:contention:1",
               "ground_station_id" => "equator_prime",
               "selected_contact_id" => "dl_1",
               "deferred_contact_ids" => ["dl_2"],
               "candidate_count" => 2,
               "selection_reason" => "highest_score_earliest_start",
               "required_operator_action" => "recommend_preferred_contact_for_operator_review",
               "approval_status" => "operator_review_required",
               "source_recommendation" => %{"selected_contact_id" => "dl_1"}
             } = row
           ] = package["rows"]

    assert row["starts_at_s"] == 100.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact contact contention resolution reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_contact_contention_resolution_review:001",
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_contention_resolution_report" => %{
            "schema_contract" => "contact_contention_resolution_report.v1",
            "source" => "wrapped.contact_contention_resolution_report",
            "recommendations" => [
              %{
                "group_id" => "station:equator_prime:wrapped_contention:1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 100.0,
                "ends_at_s" => 220.0,
                "selected_contact_id" => "dl_wrapped_1",
                "deferred_contact_ids" => ["dl_wrapped_2"],
                "candidate_count" => 2,
                "selection_reason" => "highest_score_earliest_start",
                "action" => "recommend_preferred_contact_for_operator_review",
                "review_status" => "operator_review_required"
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_contact_contention_resolution_review:001",
             "review_count" => 1,
             "contention_recommendation_count" => 1
           } = package

    assert [
             %{
               "review_type" => "contact_contention_recommendation",
               "source" =>
                 "candidate_refresh.result_artifact[0].contact_contention_resolution_report.recommendations",
               "subject_id" => "station:equator_prime:wrapped_contention:1",
               "ground_station_id" => "equator_prime",
               "selected_contact_id" => "dl_wrapped_1",
               "deferred_contact_ids" => ["dl_wrapped_2"],
               "candidate_count" => 2,
               "selection_reason" => "highest_score_earliest_start",
               "required_operator_action" => "recommend_preferred_contact_for_operator_review",
               "approval_status" => "operator_review_required",
               "source_recommendation" => %{"selected_contact_id" => "dl_wrapped_1"}
             } = row
           ] = package["rows"]

    assert row["starts_at_s"] == 100.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source freshness and refresh budget reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_freshness_budget_review:001",
      "source_freshness_report" => [
        %{
          "schema_contract" => "freshness_report.v1",
          "model" => "candidate_refresh_state_freshness",
          "status" => "stale",
          "generated_at" => "2026-05-31T00:00:00Z",
          "accepted_at" => "2026-05-30T00:00:00Z",
          "current_epoch_s" => 1200.0,
          "accepted_snapshot_age_s" => 900.0,
          "max_snapshot_age_s" => 600.0,
          "stale_reasons" => ["accepted_snapshot_age_exceeded"]
        },
        %{
          "schema_contract" => "freshness_report.v1",
          "model" => "candidate_refresh_state_freshness",
          "status" => "current"
        }
      ],
      "source_refresh_budget_report" => [
        %{
          "schema_contract" => "refresh_budget_report.v1",
          "model" => "deterministic_candidate_limit_after_filters",
          "input_candidate_count" => 3,
          "kept_candidate_count" => 2,
          "dropped_candidate_count" => 1,
          "max_candidate_activities" => 2,
          "selection_order" => "score_descending_then_start_then_id",
          "kept_candidate_ids" => ["refresh_downlink", "refresh_observe"],
          "dropped_candidate_ids" => ["old_refresh_downlink"]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_freshness_budget_review:001",
             "review_count" => 2,
             "freshness_review_count" => 1,
             "refresh_budget_review_count" => 1
           } = package

    assert [freshness_row, budget_row] = package["rows"]

    assert %{
             "review_type" => "freshness_review",
             "source" => "candidate_refresh.source_freshness_report[0]",
             "subject_id" => "freshness:stale",
             "required_operator_action" => "review_refresh_freshness",
             "freshness_status" => "stale",
             "stale_reasons" => ["accepted_snapshot_age_exceeded"],
             "source_freshness_report" => %{
               "status" => "stale",
               "stale_reasons" => ["accepted_snapshot_age_exceeded"]
             }
           } = freshness_row

    assert freshness_row["accepted_snapshot_age_s"] == 900.0

    assert %{
             "review_type" => "refresh_budget_review",
             "source" => "candidate_refresh.source_refresh_budget_report[0]",
             "subject_id" => "refresh_budget",
             "required_operator_action" => "review_refresh_budget",
             "input_candidate_count" => 3,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["old_refresh_downlink"],
             "source_refresh_budget_report" => %{
               "schema_contract" => "refresh_budget_report.v1",
               "dropped_candidate_count" => 1
             }
           } = budget_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact freshness and refresh budget reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_freshness_budget_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "freshness_report" => %{
          "schema_contract" => "freshness_report.v1",
          "model" => "candidate_refresh_state_freshness",
          "status" => "stale",
          "generated_at" => "2026-05-31T00:00:00Z",
          "accepted_at" => "2026-05-30T00:00:00Z",
          "current_epoch_s" => 1200.0,
          "accepted_snapshot_age_s" => 900.0,
          "max_snapshot_age_s" => 600.0,
          "stale_reasons" => ["accepted_snapshot_age_exceeded"]
        },
        "refresh_budget_report" => %{
          "schema_contract" => "refresh_budget_report.v1",
          "model" => "deterministic_candidate_limit_after_filters",
          "input_candidate_count" => 3,
          "kept_candidate_count" => 2,
          "dropped_candidate_count" => 1,
          "max_candidate_activities" => 2,
          "selection_order" => "score_descending_then_start_then_id",
          "kept_candidate_ids" => ["refresh_downlink", "refresh_observe"],
          "dropped_candidate_ids" => ["old_refresh_downlink"]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_freshness_budget_review:001",
             "review_count" => 2,
             "freshness_review_count" => 1,
             "refresh_budget_review_count" => 1
           } = package

    assert [freshness_row, budget_row] = package["rows"]

    assert %{
             "review_type" => "freshness_review",
             "source" => "candidate_refresh.source_result_artifact.freshness_report",
             "subject_id" => "freshness:stale",
             "required_operator_action" => "review_refresh_freshness",
             "freshness_status" => "stale",
             "stale_reasons" => ["accepted_snapshot_age_exceeded"],
             "source_freshness_report" => %{
               "status" => "stale",
               "stale_reasons" => ["accepted_snapshot_age_exceeded"]
             }
           } = freshness_row

    assert freshness_row["accepted_snapshot_age_s"] == 900.0

    assert %{
             "review_type" => "refresh_budget_review",
             "source" => "candidate_refresh.source_result_artifact.refresh_budget_report",
             "subject_id" => "refresh_budget",
             "required_operator_action" => "review_refresh_budget",
             "input_candidate_count" => 3,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["old_refresh_downlink"],
             "source_refresh_budget_report" => %{
               "schema_contract" => "refresh_budget_report.v1",
               "dropped_candidate_count" => 1
             }
           } = budget_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh state-scoped freshness and refresh budget reports become review and import rows" do
    freshness_report = %{
      "schema_contract" => "freshness_report.v1",
      "model" => "candidate_refresh_state_freshness",
      "status" => "stale",
      "generated_at" => "2026-05-31T00:00:00Z",
      "accepted_at" => "2026-05-30T00:00:00Z",
      "current_epoch_s" => 1200.0,
      "accepted_snapshot_age_s" => 900.0,
      "max_snapshot_age_s" => 600.0,
      "stale_reasons" => ["accepted_snapshot_age_exceeded"]
    }

    budget_report = %{
      "schema_contract" => "refresh_budget_report.v1",
      "model" => "deterministic_candidate_limit_after_filters",
      "input_candidate_count" => 3,
      "kept_candidate_count" => 2,
      "dropped_candidate_count" => 1,
      "max_candidate_activities" => 2,
      "selection_order" => "score_descending_then_start_then_id",
      "kept_candidate_ids" => ["refresh_downlink", "refresh_observe"],
      "dropped_candidate_ids" => ["old_refresh_downlink"]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:state_freshness_budget_review:001",
      "accepted_planning_state" => %{
        "source_freshness_report" => freshness_report,
        "source_refresh_budget_report" => budget_report
      },
      "mission_state" => %{
        "freshness_report" => freshness_report,
        "refresh_budget_report" => budget_report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_freshness_budget_review:001",
             "review_count" => 4,
             "freshness_review_count" => 2,
             "refresh_budget_review_count" => 2
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_freshness_report",
             "candidate_refresh.mission_state.freshness_report",
             "candidate_refresh.accepted_planning_state.source_refresh_budget_report",
             "candidate_refresh.mission_state.refresh_budget_report"
           ]

    assert %{
             "review_type" => "freshness_review",
             "freshness_status" => "stale",
             "stale_reasons" => ["accepted_snapshot_age_exceeded"],
             "source_freshness_report" => %{"status" => "stale"}
           } = List.first(package["rows"])

    assert %{
             "review_type" => "refresh_budget_review",
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["old_refresh_downlink"],
             "source_refresh_budget_report" => %{
               "schema_contract" => "refresh_budget_report.v1"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "refresh_budget_review"))

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_freshness_budget_review:001",
             "row_count" => 4,
             "source_review_type_counts" => %{
               "freshness_review" => 2,
               "refresh_budget_review" => 2
             }
           } = manifest

    assert Enum.map(manifest["rows"], &get_in(&1, ["source_review_row", "source"])) ==
             Enum.map(package["rows"], & &1["source"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh source model acceptance reports become operator review rows" do
    report =
      OrbitalDynamics.validation_model_acceptance_report(
        ["orbit_data.simple_json", "event.access_windows", "propagator.two_body"],
        intended_use: :operational_import
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_model_acceptance_review:001",
      "source_model_acceptance_report" => [report]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_model_acceptance_review:001",
             "review_count" => 2,
             "model_acceptance_review_count" => 2
           } = package

    assert [
             %{
               "review_type" => "model_acceptance_review",
               "source" => "candidate_refresh.source_model_acceptance_report[0].rows",
               "subject_id" => "event.access_windows",
               "required_operator_action" => "review_model_acceptance",
               "approval_status" => "operator_review_required",
               "model_acceptance_status" => "review_required",
               "model_acceptance_intended_use" => "operational_import",
               "model_acceptance_validation_level" => "analysis",
               "source_model_acceptance_row" => %{
                 "model_id" => "event.access_windows",
                 "status" => "review_required"
               },
               "source_model_acceptance_report" => %{
                 "schema_contract" => "model_acceptance_report.v1",
                 "status" => "blocked",
                 "review_required_count" => 1,
                 "blocked_count" => 1
               }
             },
             %{
               "review_type" => "model_acceptance_review",
               "source" => "candidate_refresh.source_model_acceptance_report[0].rows",
               "subject_id" => "propagator.two_body",
               "required_operator_action" => "review_blocked_model_acceptance",
               "approval_status" => "blocked_by_policy",
               "model_acceptance_status" => "blocked",
               "model_acceptance_validation_level" => "educational"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact model acceptance reports become operator review rows" do
    report =
      OrbitalDynamics.validation_model_acceptance_report(
        ["orbit_data.simple_json", "event.access_windows", "propagator.two_body"],
        intended_use: :operational_import
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_model_acceptance_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "model_acceptance_report" => report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_model_acceptance_review:001",
             "review_count" => 2,
             "model_acceptance_review_count" => 2
           } = package

    assert [
             %{
               "review_type" => "model_acceptance_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.model_acceptance_report.rows",
               "subject_id" => "event.access_windows",
               "required_operator_action" => "review_model_acceptance",
               "approval_status" => "operator_review_required",
               "model_acceptance_status" => "review_required",
               "source_model_acceptance_report" => %{
                 "schema_contract" => "model_acceptance_report.v1",
                 "status" => "blocked"
               }
             },
             %{
               "review_type" => "model_acceptance_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.model_acceptance_report.rows",
               "subject_id" => "propagator.two_body",
               "required_operator_action" => "review_blocked_model_acceptance",
               "approval_status" => "blocked_by_policy",
               "model_acceptance_status" => "blocked"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh state-scoped model acceptance reports become operator review rows" do
    report =
      OrbitalDynamics.validation_model_acceptance_report(
        ["orbit_data.simple_json", "event.access_windows", "propagator.two_body"],
        intended_use: :operational_import
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:state_model_acceptance_review:001",
      "accepted_planning_state" => %{"source_model_acceptance_report" => report},
      "mission_state" => %{"model_acceptance_report" => report}
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_model_acceptance_review:001",
             "review_count" => 4,
             "model_acceptance_review_count" => 4
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_model_acceptance_report.rows",
             "candidate_refresh.accepted_planning_state.source_model_acceptance_report.rows",
             "candidate_refresh.mission_state.model_acceptance_report.rows",
             "candidate_refresh.mission_state.model_acceptance_report.rows"
           ]

    assert %{
             "review_type" => "model_acceptance_review",
             "subject_id" => "event.access_windows",
             "required_operator_action" => "review_model_acceptance",
             "approval_status" => "operator_review_required",
             "model_acceptance_status" => "review_required",
             "source_model_acceptance_report" => %{
               "schema_contract" => "model_acceptance_report.v1",
               "status" => "blocked"
             }
           } = List.first(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert manifest["row_count"] == 0
    assert manifest["rows"] == []

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source validation safety-case summaries become operator review rows" do
    model_acceptance_report =
      OrbitalDynamics.validation_model_acceptance_report(["missing.model"],
        intended_use: :operational_import
      )

    quality_gate_report = %{
      "schema_contract" => "quality_gate_report.v1",
      "status" => "review_required",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "review_gate_count" => 1,
      "blocked_gate_count" => 0
    }

    summary =
      OrbitalDynamics.validation_safety_case_summary(
        [model_acceptance_report, quality_gate_report],
        case_id: "case:branch-refresh"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_validation_safety_review:001",
      "source_validation_safety_case_summary" => [summary]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_validation_safety_review:001",
             "review_count" => 2,
             "validation_safety_case_review_count" => 2
           } = package

    assert [
             %{
               "review_type" => "validation_safety_case_review",
               "source" => "candidate_refresh.source_validation_safety_case_summary[0].evidence",
               "required_operator_action" => "review_blocked_validation_safety_case",
               "approval_status" => "blocked_by_policy",
               "validation_safety_case_evidence_status" => "blocked",
               "validation_safety_case_input_contract" => "model_acceptance_report.v1",
               "validation_safety_case_blocked_evidence_count" => 1,
               "source_validation_safety_case_evidence" => %{
                 "schema_contract" => "model_acceptance_report.v1",
                 "status" => "blocked"
               },
               "source_validation_safety_case_summary" => %{
                 "schema_contract" => "validation_safety_case_summary.v1",
                 "case_id" => "case:branch-refresh",
                 "status" => "blocked"
               }
             },
             %{
               "review_type" => "validation_safety_case_review",
               "source" => "candidate_refresh.source_validation_safety_case_summary[0].evidence",
               "required_operator_action" => "review_validation_safety_case",
               "approval_status" => "operator_review_required",
               "validation_safety_case_evidence_status" => "review_required",
               "validation_safety_case_input_contract" => "quality_gate_report.v1"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact validation safety-case summaries become operator review rows" do
    model_acceptance_report =
      OrbitalDynamics.validation_model_acceptance_report(["missing.model"],
        intended_use: :operational_import
      )

    quality_gate_report = %{
      "schema_contract" => "quality_gate_report.v1",
      "status" => "review_required",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "review_gate_count" => 1,
      "blocked_gate_count" => 0
    }

    summary =
      OrbitalDynamics.validation_safety_case_summary(
        [model_acceptance_report, quality_gate_report],
        case_id: "case:wrapped-refresh"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_validation_safety_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "validation_safety_case_summary" => summary
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_validation_safety_review:001",
             "review_count" => 2,
             "validation_safety_case_review_count" => 2
           } = package

    assert [
             %{
               "review_type" => "validation_safety_case_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.validation_safety_case_summary.evidence",
               "required_operator_action" => "review_blocked_validation_safety_case",
               "approval_status" => "blocked_by_policy",
               "validation_safety_case_evidence_status" => "blocked",
               "validation_safety_case_input_contract" => "model_acceptance_report.v1",
               "source_validation_safety_case_summary" => %{
                 "schema_contract" => "validation_safety_case_summary.v1",
                 "case_id" => "case:wrapped-refresh",
                 "status" => "blocked"
               }
             },
             %{
               "review_type" => "validation_safety_case_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.validation_safety_case_summary.evidence",
               "required_operator_action" => "review_validation_safety_case",
               "approval_status" => "operator_review_required",
               "validation_safety_case_evidence_status" => "review_required",
               "validation_safety_case_input_contract" => "quality_gate_report.v1"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh state-scoped validation safety-case summaries become operator review rows" do
    model_acceptance_report =
      OrbitalDynamics.validation_model_acceptance_report(["missing.model"],
        intended_use: :operational_import
      )

    quality_gate_report = %{
      "schema_contract" => "quality_gate_report.v1",
      "status" => "review_required",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "review_gate_count" => 1,
      "blocked_gate_count" => 0
    }

    summary =
      OrbitalDynamics.validation_safety_case_summary(
        [model_acceptance_report, quality_gate_report],
        case_id: "case:state-refresh"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:state_validation_safety_review:001",
      "accepted_planning_state" => %{"source_validation_safety_case_summary" => summary},
      "mission_state" => %{"validation_safety_case_summary" => summary}
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_validation_safety_review:001",
             "review_count" => 4,
             "validation_safety_case_review_count" => 4
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_validation_safety_case_summary.evidence",
             "candidate_refresh.accepted_planning_state.source_validation_safety_case_summary.evidence",
             "candidate_refresh.mission_state.validation_safety_case_summary.evidence",
             "candidate_refresh.mission_state.validation_safety_case_summary.evidence"
           ]

    assert %{
             "review_type" => "validation_safety_case_review",
             "required_operator_action" => "review_blocked_validation_safety_case",
             "approval_status" => "blocked_by_policy",
             "validation_safety_case_evidence_status" => "blocked",
             "validation_safety_case_input_contract" => "model_acceptance_report.v1",
             "source_validation_safety_case_summary" => %{
               "schema_contract" => "validation_safety_case_summary.v1",
               "case_id" => "case:state-refresh",
               "status" => "blocked"
             }
           } = List.first(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert manifest["row_count"] == 0
    assert manifest["rows"] == []

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source candidate rejection reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_candidate_rejection_review:001",
      "source_candidate_rejection_report" => [
        %{
          "schema_contract" => "candidate_rejection_report.v1",
          "source" => "mission_state.source_candidate_rejection_report",
          "rows" => [
            %{
              "candidate_id" => "refresh_downlink_reserved",
              "activity_id" => "refresh_downlink_reserved",
              "timeline_id" => "timeline:leo_1:contact:refresh_downlink_reserved",
              "activity_type" => "contact",
              "operational_kind" => "downlink",
              "source_window_id" => "window:leo_1:equator_prime:1",
              "source_window_type" => "ground_station_access",
              "rejection_status" => "rejected",
              "reviewable" => true,
              "primary_rejection_reason" => "station_reserved",
              "rejection_reasons" => ["station_reserved"],
              "reason_count" => 1,
              "required_operator_action" => "review_candidate_rejection"
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_candidate_rejection_review:001",
             "review_count" => 1,
             "candidate_rejection_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "candidate_rejection_review",
               "source" => "candidate_refresh.source_candidate_rejection_report[0].rows",
               "subject_id" => "refresh_downlink_reserved",
               "candidate_id" => "refresh_downlink_reserved",
               "activity_id" => "refresh_downlink_reserved",
               "activity_type" => "contact",
               "operational_kind" => "downlink",
               "source_window_id" => "window:leo_1:equator_prime:1",
               "source_window_type" => "ground_station_access",
               "candidate_rejection_status" => "rejected",
               "candidate_rejection_reasons" => ["station_reserved"],
               "primary_rejection_reason" => "station_reserved",
               "candidate_rejection_reason_count" => 1,
               "reviewable" => true,
               "required_operator_action" => "review_candidate_rejection",
               "source_candidate_rejection" => %{
                 "candidate_id" => "refresh_downlink_reserved",
                 "primary_rejection_reason" => "station_reserved"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact candidate rejection reports become operator review rows" do
    report = %{
      "schema_contract" => "candidate_rejection_report.v1",
      "source" => "mission_state.source_result_artifact.candidate_rejection_report",
      "rows" => [
        %{
          "candidate_id" => "wrapped_downlink_rejected",
          "activity_id" => "wrapped_downlink_rejected",
          "timeline_id" => "timeline:leo_1:contact:wrapped_downlink_rejected",
          "activity_type" => "contact",
          "operational_kind" => "downlink",
          "source_window_id" => "window:leo_1:equator_prime:wrapped",
          "source_window_type" => "ground_station_access",
          "rejection_status" => "rejected",
          "reviewable" => true,
          "primary_rejection_reason" => "station_reserved",
          "rejection_reasons" => ["station_reserved"],
          "reason_count" => 1,
          "required_operator_action" => "review_candidate_rejection"
        }
      ]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_candidate_rejection_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "candidate_rejection_report" => report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_candidate_rejection_review:001",
             "review_count" => 1,
             "candidate_rejection_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "candidate_rejection_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.candidate_rejection_report.rows",
               "subject_id" => "wrapped_downlink_rejected",
               "candidate_id" => "wrapped_downlink_rejected",
               "activity_id" => "wrapped_downlink_rejected",
               "primary_rejection_reason" => "station_reserved",
               "required_operator_action" => "review_candidate_rejection",
               "source_candidate_rejection" => %{
                 "candidate_id" => "wrapped_downlink_rejected"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source operational timeline reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:ops_timeline_review:001",
      "source_operational_timeline_report" => %{
        "schema_contract" => "operational_timeline_report.v1",
        "source" => "mission_state.source_operational_timeline_report",
        "rows" => [
          %{
            "activity_id" => "cmd_live_timeline",
            "timeline_id" => "timeline:leo_1:command:cmd_live_timeline",
            "scenario_id" => "leo_1",
            "activity_type" => "command",
            "operational_kind" => "command",
            "starts_at_s" => 100.0,
            "ends_at_s" => 130.0,
            "status" => "planned",
            "approval_status" => "review_required",
            "required_operator_action" => "review_command_feedback",
            "operator_action_reason" => "live command result requires operator review",
            "cadence_import_status" => "present",
            "command_success_factor" => 0.3,
            "command_result" => ["accepted", "failed"],
            "trust_boundary" => "cadence_live_timeline_export"
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:ops_timeline_review:001",
             "review_count" => 1,
             "operational_timeline_count" => 1,
             "cadence_import_status_counts" => %{"present" => 1}
           } = package

    assert %{
             "review_type" => "operational_timeline_review",
             "source" => "candidate_refresh.source_operational_timeline_report.rows",
             "subject_id" => "timeline:leo_1:command:cmd_live_timeline",
             "activity_id" => "cmd_live_timeline",
             "timeline_id" => "timeline:leo_1:command:cmd_live_timeline",
             "operational_kind" => "command",
             "required_operator_action" => "review_command_feedback",
             "approval_status" => "review_required",
             "source_approval_status" => "review_required",
             "cadence_import_status" => "present",
             "command_success_factor" => 0.3,
             "command_result" => "accepted,failed",
             "trust_boundary" => "cadence_live_timeline_export",
             "source_operational_timeline" => %{
               "activity_id" => "cmd_live_timeline",
               "timeline_id" => "timeline:leo_1:command:cmd_live_timeline"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact operational timeline reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_ops_timeline_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "operational_timeline_report" => %{
          "schema_contract" => "operational_timeline_report.v1",
          "source" => "wrapped.operational_timeline_report",
          "rows" => [
            %{
              "activity_id" => "cmd_wrapped_timeline",
              "timeline_id" => "timeline:leo_1:command:cmd_wrapped_timeline",
              "scenario_id" => "leo_1",
              "activity_type" => "command",
              "operational_kind" => "command",
              "starts_at_s" => 100.0,
              "ends_at_s" => 130.0,
              "status" => "planned",
              "approval_status" => "review_required",
              "required_operator_action" => "review_command_feedback",
              "operator_action_reason" => "live command result requires operator review",
              "cadence_import_status" => "present",
              "command_success_factor" => 0.3,
              "command_result" => ["accepted", "failed"],
              "trust_boundary" => "cadence_live_timeline_export"
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_ops_timeline_review:001",
             "review_count" => 1,
             "operational_timeline_count" => 1,
             "cadence_import_status_counts" => %{"present" => 1}
           } = package

    assert %{
             "review_type" => "operational_timeline_review",
             "source" =>
               "candidate_refresh.source_result_artifact.operational_timeline_report.rows",
             "subject_id" => "timeline:leo_1:command:cmd_wrapped_timeline",
             "activity_id" => "cmd_wrapped_timeline",
             "timeline_id" => "timeline:leo_1:command:cmd_wrapped_timeline",
             "operational_kind" => "command",
             "required_operator_action" => "review_command_feedback",
             "approval_status" => "review_required",
             "source_approval_status" => "review_required",
             "cadence_import_status" => "present",
             "command_success_factor" => 0.3,
             "command_result" => "accepted,failed",
             "trust_boundary" => "cadence_live_timeline_export",
             "source_operational_timeline" => %{
               "activity_id" => "cmd_wrapped_timeline",
               "timeline_id" => "timeline:leo_1:command:cmd_wrapped_timeline"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source timeline feedback reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:timeline_feedback_review:001",
      "source_timeline_feedback_report" => %{
        "schema_contract" => "timeline_feedback_report.v1",
        "rows" => [
          %{
            "activity_id" => "dl_live_feedback",
            "status" => "matched",
            "feedback_kind" => "contact",
            "match_strategy" => "timeline_activity_id",
            "planned_type" => "downlink",
            "planned_status" => "approved",
            "planned_timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
            "timeline_identity" => %{
              "timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
              "activity_id" => "dl_live_feedback"
            },
            "realized_timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
            "realized_activity_id" => "provider_contact_42",
            "realized_status" => "failed",
            "realized_source" => %{"adapter" => "cadence_feedback_adapter"},
            "realized_provider" => "cadence",
            "realized_source_quality" => "declared",
            "realized_adapter" => "cadence_feedback_adapter",
            "realized_adapter_version" => "2026.05.31",
            "realized_external_id" => "cadence:contact:42",
            "realized_schema_contract" => "cadence_contact_feedback.v1",
            "realized_trust_boundary" => "cadence_feedback_adapter",
            "realized_received_at" => "2026-05-31T00:00:00Z",
            "realized_ingested_at" => "2026-05-31T00:01:00Z",
            "realized_provenance" => %{"source" => "cadence"},
            "station_reservation_id" => "reservation:equator_prime:dl_live_feedback",
            "station_reservation_status" => "held",
            "station_reservation_match_status" => "matched"
          },
          %{
            "activity_id" => "dl_missing_feedback",
            "status" => "planned_only",
            "feedback_kind" => "contact",
            "planned_type" => "downlink"
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:timeline_feedback_review:001",
             "review_count" => 1,
             "realized_feedback_count" => 1,
             "required_operator_action_counts" => %{"review_contact_exception" => 1}
           } = package

    assert [
             %{
               "review_type" => "realized_feedback",
               "source" => "candidate_refresh.source_timeline_feedback_report.rows",
               "subject_id" => "dl_live_feedback",
               "activity_id" => "dl_live_feedback",
               "activity_type" => "downlink",
               "required_operator_action" => "review_contact_exception",
               "approval_status" => "operator_review_required",
               "feedback_status" => "matched",
               "feedback_kind" => "contact",
               "match_strategy" => "timeline_activity_id",
               "planned_timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
                 "activity_id" => "dl_live_feedback"
               },
               "realized_timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
               "realized_activity_id" => "provider_contact_42",
               "realized_status" => "failed",
               "realized_source" => %{"adapter" => "cadence_feedback_adapter"},
               "realized_provider" => "cadence",
               "realized_source_quality" => "declared",
               "realized_adapter" => "cadence_feedback_adapter",
               "realized_adapter_version" => "2026.05.31",
               "realized_external_id" => "cadence:contact:42",
               "realized_schema_contract" => "cadence_contact_feedback.v1",
               "realized_trust_boundary" => "cadence_feedback_adapter",
               "realized_received_at" => "2026-05-31T00:00:00Z",
               "realized_ingested_at" => "2026-05-31T00:01:00Z",
               "realized_provenance" => %{"source" => "cadence"},
               "station_reservation_id" => "reservation:equator_prime:dl_live_feedback",
               "station_reservation_status" => "held",
               "station_reservation_match_status" => "matched",
               "source_feedback" => %{
                 "activity_id" => "dl_live_feedback",
                 "realized_activity_id" => "provider_contact_42"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact timeline feedback reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_timeline_feedback_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "timeline_feedback_report" => %{
          "schema_contract" => "timeline_feedback_report.v1",
          "rows" => [
            %{
              "activity_id" => "dl_wrapped_feedback",
              "status" => "matched",
              "feedback_kind" => "contact",
              "match_strategy" => "timeline_activity_id",
              "planned_type" => "downlink",
              "planned_status" => "approved",
              "planned_timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
              "timeline_identity" => %{
                "timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
                "activity_id" => "dl_wrapped_feedback"
              },
              "realized_timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
              "realized_activity_id" => "provider_contact_42",
              "realized_status" => "failed",
              "realized_source" => %{"adapter" => "cadence_feedback_adapter"},
              "realized_provider" => "cadence",
              "realized_source_quality" => "declared",
              "realized_adapter" => "cadence_feedback_adapter",
              "realized_adapter_version" => "2026.05.31",
              "realized_external_id" => "cadence:contact:42",
              "realized_schema_contract" => "cadence_contact_feedback.v1",
              "realized_trust_boundary" => "cadence_feedback_adapter",
              "realized_received_at" => "2026-05-31T00:00:00Z",
              "realized_ingested_at" => "2026-05-31T00:01:00Z",
              "realized_provenance" => %{"source" => "cadence"},
              "station_reservation_id" => "reservation:equator_prime:dl_wrapped_feedback",
              "station_reservation_status" => "held",
              "station_reservation_match_status" => "matched"
            },
            %{
              "activity_id" => "dl_missing_feedback",
              "status" => "planned_only",
              "feedback_kind" => "contact",
              "planned_type" => "downlink"
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_timeline_feedback_review:001",
             "review_count" => 1,
             "realized_feedback_count" => 1,
             "required_operator_action_counts" => %{"review_contact_exception" => 1}
           } = package

    assert [
             %{
               "review_type" => "realized_feedback",
               "source" =>
                 "candidate_refresh.source_result_artifact.timeline_feedback_report.rows",
               "subject_id" => "dl_wrapped_feedback",
               "activity_id" => "dl_wrapped_feedback",
               "activity_type" => "downlink",
               "required_operator_action" => "review_contact_exception",
               "approval_status" => "operator_review_required",
               "feedback_status" => "matched",
               "feedback_kind" => "contact",
               "match_strategy" => "timeline_activity_id",
               "planned_timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
                 "activity_id" => "dl_wrapped_feedback"
               },
               "realized_timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
               "realized_activity_id" => "provider_contact_42",
               "realized_status" => "failed",
               "realized_source" => %{"adapter" => "cadence_feedback_adapter"},
               "realized_provider" => "cadence",
               "realized_source_quality" => "declared",
               "realized_adapter" => "cadence_feedback_adapter",
               "realized_adapter_version" => "2026.05.31",
               "realized_external_id" => "cadence:contact:42",
               "realized_schema_contract" => "cadence_contact_feedback.v1",
               "realized_trust_boundary" => "cadence_feedback_adapter",
               "realized_received_at" => "2026-05-31T00:00:00Z",
               "realized_ingested_at" => "2026-05-31T00:01:00Z",
               "realized_provenance" => %{"source" => "cadence"},
               "station_reservation_id" => "reservation:equator_prime:dl_wrapped_feedback",
               "station_reservation_status" => "held",
               "station_reservation_match_status" => "matched",
               "source_feedback" => %{
                 "activity_id" => "dl_wrapped_feedback",
                 "realized_activity_id" => "provider_contact_42"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh accepted planning state contact contention resolution summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:accepted_contact_contention_resolution:001",
      "accepted_planning_state" => %{
        "source_contact_contention_resolution_summary" =>
          study_result_fixture("contact_contention_resolution_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:accepted_contact_contention_resolution:001",
             "review_count" => 2,
             "review_type_counts" => %{"contact_contention_recommendation" => 2},
             "required_operator_action_counts" => %{
               "recommend_preferred_contact_for_operator_review" => 2
             }
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_contact_contention_resolution_summary.summary_recommendations",
             "candidate_refresh.accepted_planning_state.source_contact_contention_resolution_summary.summary_recommendations"
           ]

    assert %{
             "review_type" => "contact_contention_recommendation",
             "subject_id" => "spacecraft:sat_1:contention:1",
             "required_operator_action" => "recommend_preferred_contact_for_operator_review",
             "selected_contact_ids" => ["dl_3"],
             "deferred_contact_ids" => ["dl_4"],
             "review_contact_ids" => ["dl_3", "dl_4"],
             "source_summary_schema_contract" => "contact_contention_resolution_summary.v1",
             "source_summary_model" => "artifact_only_contact_contention_resolution_summary",
             "source_contact_contention_resolution_summary" => %{
               "schema_contract" => "contact_contention_resolution_summary.v1",
               "model" => "artifact_only_contact_contention_resolution_summary",
               "assumptions" => %{
                 "execution_boundary" =>
                   "artifact_only_no_provider_reservation_or_schedule_mutation",
                 "operator_authority" => "not_granted_by_summary"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["subject_id"] == "spacecraft:sat_1:contention:1")
             )

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:accepted_contact_contention_resolution:001",
             "row_count" => 2,
             "source_review_type_counts" => %{"contact_contention_recommendation" => 2},
             "import_action_counts" => %{"review_contact_contention_resolution" => 2}
           } = manifest

    assert %{
             "import_action" => "review_contact_contention_resolution",
             "source_review_type" => "contact_contention_recommendation",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_contact_contention_resolution_summary.summary_recommendations",
               "source_contact_contention_resolution_summary" => %{
                 "schema_contract" => "contact_contention_resolution_summary.v1"
               }
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh mission state contact contention resolution summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:mission_contact_contention_resolution:001",
      "mission_state" => %{
        "contact_contention_resolution_summary" =>
          study_result_fixture("contact_contention_resolution_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:mission_contact_contention_resolution:001",
             "review_count" => 2,
             "review_type_counts" => %{"contact_contention_recommendation" => 2}
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.mission_state.contact_contention_resolution_summary.summary_recommendations",
             "candidate_refresh.mission_state.contact_contention_resolution_summary.summary_recommendations"
           ]

    assert %{
             "review_type" => "contact_contention_recommendation",
             "subject_id" => "station:equator_prime:contention:1",
             "selected_contact_ids" => ["dl_1"],
             "deferred_contact_ids" => ["dl_2"],
             "review_contact_ids" => ["dl_1", "dl_2"],
             "source_contact_contention_resolution_summary" => %{
               "schema_contract" => "contact_contention_resolution_summary.v1",
               "review_recommendation_count" => 2
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["subject_id"] == "station:equator_prime:contention:1")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source contact allocation reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_allocation_review:001",
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "id" => "source_contact_allocation:mission_state",
        "calendar_entry_trust_boundary_status_counts" => %{"declared" => 1},
        "station_reservation_match_status_counts" => %{"matched" => 1},
        "station_reservation_expiration_status_counts" => %{"declared" => 1},
        "station_reservation_declared_expiration_contact_count" => 1,
        "station_reservation_missing_expiration_contact_count" => 0,
        "earliest_station_reservation_expires_at_s" => 360.0,
        "station_reservation_ids" => ["reservation:equator_prime:dl_source_deferred"],
        "station_reservation_expires_at_s" => [360.0],
        "station_reserved_bys" => ["ops"],
        "station_reservation_statuses" => ["held"],
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "capacity_pack_required_capacity_fraction" => 0.65,
        "capacity_pack_selected_required_capacity_fraction" => 0.35,
        "capacity_pack_deferred_required_capacity_fraction" => 0.3,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => 0.35,
          "deferred_by_reduced_station_capacity_pack" => 0.3
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "equator_prime" => 0.65
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
          "equator_prime" => 0.35
        },
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
          "equator_prime" => 0.3
        },
        "capacity_pack_contact_ids_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => ["dl_source_primary"],
          "deferred_by_reduced_station_capacity_pack" => ["dl_source_deferred"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_source_primary", "dl_source_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_source_primary"]
        },
        "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_source_deferred"]
        },
        "reduced_capacity_packed_contact_ids" => ["dl_source_primary"],
        "reduced_capacity_deferred_contact_ids" => ["dl_source_deferred"],
        "rows" => [
          %{
            "id" => "allocation:dl_source_deferred",
            "contact_id" => "dl_source_deferred",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "sat_1",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "starts_at_s" => 120.0,
            "ends_at_s" => 180.0,
            "allocation_status" => "deferred",
            "allocation_reason" => "reduced_station_capacity",
            "selected" => false,
            "capacity_pack_group_id" => "station:equator_prime:capacity_pack:1",
            "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
            "required_capacity_fraction" => 0.3,
            "required_capacity_fraction_source" => "source_contact_allocation_report.rows",
            "station_availability" => "available",
            "station_reservation_id" => "reservation:equator_prime:dl_source_deferred",
            "station_reservation_expires_at_s" => 360.0,
            "station_reserved_by" => "ops",
            "station_reservation_status" => "held",
            "station_reservation_match_status" => "matched",
            "resource_blocking_dimension" => "antenna",
            "source_contact_candidate" => %{"id" => "dl_source_deferred"},
            "source_resource_suppression" => %{"suppressed_reason" => "antenna_unavailable"}
          }
        ],
        "reduced_capacity_pack_groups" => [
          %{
            "contention_group_id" => "station:equator_prime:capacity_pack:1",
            "ground_station_id" => "equator_prime",
            "capacity_fraction" => 0.5,
            "used_capacity_fraction" => 0.5,
            "default_required_capacity_fraction" => 0.25,
            "input_contact_ids" => ["dl_source_primary", "dl_source_deferred"],
            "selected_contact_ids" => ["dl_source_primary"],
            "capacity_packed_contact_ids" => ["dl_source_primary"],
            "deferred_contact_ids" => ["dl_source_deferred"],
            "pack_status" => "packed_with_deferred_contacts"
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_allocation_review:001",
             "review_count" => 2,
             "contact_allocation_review_count" => 1,
             "contact_allocation_capacity_pack_review_count" => 1,
             "calendar_entry_trust_boundary_status_counts" => %{"declared" => 1},
             "station_reservation_match_status_counts" => %{"matched" => 1},
             "station_reservation_expiration_status_counts" => %{"declared" => 1},
             "station_reservation_declared_expiration_contact_count" => 1,
             "resource_blocking_dimension_counts" => %{"antenna" => 1},
             "capacity_pack_required_capacity_fraction" => 0.65,
             "capacity_pack_selected_required_capacity_fraction" => 0.35,
             "capacity_pack_deferred_required_capacity_fraction" => 0.3
           } = package

    assert %{
             "review_type" => "contact_allocation_review",
             "source" => "candidate_refresh.source_contact_allocation_report.rows",
             "subject_id" => "dl_source_deferred",
             "contact_id" => "dl_source_deferred",
             "allocation_status" => "deferred",
             "allocation_reason" => "reduced_station_capacity",
             "required_operator_action" => "review_contact_allocation",
             "ground_station_id" => "equator_prime",
             "capacity_pack_group_id" => "station:equator_prime:capacity_pack:1",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "station_reservation_id" => "reservation:equator_prime:dl_source_deferred",
             "station_reservation_match_status" => "matched",
             "resource_blocking_dimension" => "antenna",
             "source_contact_allocation" => %{
               "contact_id" => "dl_source_deferred",
               "allocation_reason" => "reduced_station_capacity"
             },
             "source_resource_suppression" => %{"suppressed_reason" => "antenna_unavailable"}
           } =
             Enum.find(package["rows"], &(&1["review_type"] == "contact_allocation_review"))

    assert %{
             "review_type" => "contact_allocation_capacity_pack_review",
             "source" =>
               "candidate_refresh.source_contact_allocation_report.reduced_capacity_pack_groups",
             "contention_group_id" => "station:equator_prime:capacity_pack:1",
             "ground_station_id" => "equator_prime",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "default_required_capacity_fraction" => 0.25,
             "selected_contact_ids" => ["dl_source_primary"],
             "deferred_contact_ids" => ["dl_source_deferred"],
             "source_contact_allocation_capacity_pack" => %{
               "contention_group_id" => "station:equator_prime:capacity_pack:1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["review_type"] == "contact_allocation_capacity_pack_review")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh accepted planning state contact allocation summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:accepted_contact_allocation_summary:001",
      "accepted_planning_state" => %{
        "source_contact_allocation_summary" =>
          study_result_fixture("contact_allocation_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_contact_allocation_summary:001",
             "review_count" => 3,
             "contact_allocation_review_count" => 3
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_contact_allocation_summary.review_rows",
             "candidate_refresh.accepted_planning_state.source_contact_allocation_summary.review_rows",
             "candidate_refresh.accepted_planning_state.source_contact_allocation_summary.review_rows"
           ]

    assert %{
             "review_type" => "contact_allocation_review",
             "source" =>
               "candidate_refresh.accepted_planning_state.source_contact_allocation_summary.review_rows",
             "required_operator_action" => "review_contact_allocation",
             "source_contact_allocation" => %{
               "source_summary_schema_contract" => "contact_allocation_summary.v1",
               "source_summary_model" => "artifact_only_contact_allocation_summary",
               "source_contact_allocation_summary" => %{
                 "schema_contract" => "contact_allocation_summary.v1",
                 "model" => "artifact_only_contact_allocation_summary"
               }
             }
           } = List.first(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_contact_allocation_summary:001",
             "row_count" => 3,
             "source_review_type_counts" => %{"contact_allocation_review" => 3},
             "import_action_counts" => %{"review_contact_allocation" => 3}
           } = manifest

    assert %{
             "import_action" => "review_contact_allocation",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_contact_allocation_summary.review_rows",
               "source_contact_allocation" => %{
                 "source_contact_allocation_summary" => %{
                   "schema_contract" => "contact_allocation_summary.v1",
                   "model" => "artifact_only_contact_allocation_summary"
                 }
               }
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh mission state contact allocation summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:mission_contact_allocation_summary:001",
      "mission_state" => %{
        "contact_allocation_reservation_conflict_summary" =>
          study_result_fixture("contact_allocation_reservation_conflict_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:mission_contact_allocation_summary:001",
             "review_count" => 1,
             "contact_allocation_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "contact_allocation_review",
               "source" =>
                 "candidate_refresh.mission_state.contact_allocation_reservation_conflict_summary.reservation_review_rows",
               "required_operator_action" => "review_contact_allocation",
               "source_contact_allocation" => %{
                 "source_summary_schema_contract" =>
                   "contact_allocation_reservation_conflict_summary.v1",
                 "source_contact_allocation_summary" => %{
                   "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
                   "model" => "artifact_only_contact_allocation_reservation_conflict_summary"
                 }
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact contact allocation reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_contact_allocation_review:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_allocation_report" => %{
            "schema_contract" => "contact_allocation_report.v1",
            "rows" => [
              %{
                "id" => "allocation:dl_wrapped_deferred",
                "contact_id" => "dl_wrapped_deferred",
                "type" => "downlink",
                "spacecraft_id" => "sat_1",
                "ground_station_id" => "equator_prime",
                "direction" => "downlink",
                "allocation_status" => "deferred",
                "allocation_reason" => "reduced_station_capacity",
                "selected" => false,
                "capacity_pack_group_id" => "station:equator_prime:capacity_pack:1",
                "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
                "required_capacity_fraction" => 0.3,
                "required_capacity_fraction_source" => "wrapped_contact_allocation_report.rows",
                "station_availability" => "available",
                "station_reservation_id" => "reservation:equator_prime:dl_wrapped_deferred",
                "station_reservation_expires_at_s" => 360.0,
                "station_reserved_by" => "ops",
                "station_reservation_status" => "held",
                "station_reservation_match_status" => "matched",
                "resource_blocking_dimension" => "antenna",
                "source_contact_candidate" => %{"id" => "dl_wrapped_deferred"},
                "source_resource_suppression" => %{"suppressed_reason" => "antenna_unavailable"}
              }
            ],
            "reduced_capacity_pack_groups" => [
              %{
                "contention_group_id" => "station:equator_prime:capacity_pack:1",
                "ground_station_id" => "equator_prime",
                "capacity_fraction" => 0.5,
                "used_capacity_fraction" => 0.5,
                "default_required_capacity_fraction" => 0.25,
                "input_contact_ids" => ["dl_wrapped_primary", "dl_wrapped_deferred"],
                "selected_contact_ids" => ["dl_wrapped_primary"],
                "capacity_packed_contact_ids" => ["dl_wrapped_primary"],
                "deferred_contact_ids" => ["dl_wrapped_deferred"],
                "pack_status" => "packed_with_deferred_contacts"
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_contact_allocation_review:001",
             "review_count" => 2,
             "contact_allocation_review_count" => 1,
             "contact_allocation_capacity_pack_review_count" => 1
           } = package

    assert %{
             "review_type" => "contact_allocation_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].contact_allocation_report.rows",
             "subject_id" => "dl_wrapped_deferred",
             "contact_id" => "dl_wrapped_deferred",
             "allocation_status" => "deferred",
             "allocation_reason" => "reduced_station_capacity",
             "required_operator_action" => "review_contact_allocation",
             "ground_station_id" => "equator_prime",
             "capacity_pack_group_id" => "station:equator_prime:capacity_pack:1",
             "station_reservation_id" => "reservation:equator_prime:dl_wrapped_deferred",
             "station_reservation_match_status" => "matched",
             "resource_blocking_dimension" => "antenna",
             "source_contact_allocation" => %{
               "contact_id" => "dl_wrapped_deferred",
               "allocation_reason" => "reduced_station_capacity"
             },
             "source_resource_suppression" => %{"suppressed_reason" => "antenna_unavailable"}
           } =
             Enum.find(package["rows"], &(&1["review_type"] == "contact_allocation_review"))

    assert %{
             "review_type" => "contact_allocation_capacity_pack_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].contact_allocation_report.reduced_capacity_pack_groups",
             "contention_group_id" => "station:equator_prime:capacity_pack:1",
             "ground_station_id" => "equator_prime",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "selected_contact_ids" => ["dl_wrapped_primary"],
             "deferred_contact_ids" => ["dl_wrapped_deferred"],
             "source_contact_allocation_capacity_pack" => %{
               "contention_group_id" => "station:equator_prime:capacity_pack:1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["review_type"] == "contact_allocation_capacity_pack_review")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source link capacity reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:link_capacity_review:001",
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "model" => "fixed_rate_downlink_capacity_summary",
        "source" => "mission_state.source_link_capacity_report",
        "rows" => [
          %{
            "ground_station_id" => "equator_prime",
            "contact_count" => 2,
            "ignored_contact_count" => 1,
            "ignored_contact_ids" => ["dl_rejected"],
            "ignored_contact_reason_counts" => %{"approval_status_rejected" => 1},
            "selected_contact_count" => 1,
            "ignored_selected_contact_count" => 0,
            "ignored_selected_contact_ids" => [],
            "estimated_throughput_mb" => 160.0,
            "selected_estimated_throughput_mb" => 100.0,
            "capacity_adjusted_throughput_mb" => 128.0,
            "selected_capacity_adjusted_throughput_mb" => 80.0,
            "unused_capacity_adjusted_throughput_mb" => 48.0,
            "selected_capacity_utilization_fraction" => 0.625,
            "selection_utilization_status" => "under_utilized",
            "required_downlink_mb" => 120.0,
            "required_downlink_contact_count" => 1,
            "required_downlink_contact_ids" => ["dl_selected"],
            "selected_downlink_shortfall_mb" => 40.0,
            "downlink_requirement_status" => "shortfall",
            "downlink_completion_source" => "source_link_capacity_report",
            "actual_throughput_mb" => 72.0,
            "actual_throughput_contact_count" => 1,
            "actual_throughput_contact_ids" => ["dl_selected"],
            "actual_downlink_shortfall_mb" => 48.0,
            "actual_downlink_requirement_status" => "shortfall",
            "capacity_fraction_min" => 0.5,
            "capacity_fraction_max" => 0.8,
            "contact_ids" => ["dl_selected", "dl_rejected"],
            "selected_contact_ids" => ["dl_selected"],
            "approval_status" => "operator_review_required",
            "approval_requirements" => [
              %{
                "activity_id" => "link_capacity:equator_prime",
                "activity_type" => "link_capacity_summary",
                "action" => "review_link_capacity_summary",
                "requirement_type" => "contact_schedule_change",
                "policy_classification" => "operator_review_required"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "classification" => "operator_review_required",
              "policy_bundle_id" => "ground_network_allocation_v1"
            }
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:link_capacity_review:001",
             "review_count" => 1,
             "link_capacity_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "link_capacity_review",
               "source" => "candidate_refresh.source_link_capacity_report.rows",
               "subject_id" => "equator_prime",
               "ground_station_id" => "equator_prime",
               "required_operator_action" => "review_link_capacity_summary",
               "contact_count" => 2,
               "ignored_contact_count" => 1,
               "ignored_contact_ids" => ["dl_rejected"],
               "selected_contact_count" => 1,
               "selected_contact_ids" => ["dl_selected"],
               "selected_capacity_adjusted_throughput_mb" => 80.0,
               "unused_capacity_adjusted_throughput_mb" => 48.0,
               "selected_downlink_shortfall_mb" => 40.0,
               "downlink_requirement_status" => "shortfall",
               "actual_throughput_mb" => 72.0,
               "actual_downlink_shortfall_mb" => 48.0,
               "actual_downlink_requirement_status" => "shortfall",
               "capacity_fraction_min" => 0.5,
               "capacity_fraction_max" => 0.8,
               "requirement_type" => "contact_schedule_change",
               "policy_bundle_id" => "ground_network_allocation_v1",
               "source_policy_decision" => %{
                 "policy_bundle_id" => "ground_network_allocation_v1"
               },
               "source_link_capacity" => %{
                 "ground_station_id" => "equator_prime",
                 "selected_downlink_shortfall_mb" => 40.0
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact link capacity reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_link_capacity_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "link_capacity_report" => %{
          "schema_contract" => "link_capacity_report.v1",
          "model" => "fixed_rate_downlink_capacity_summary",
          "rows" => [
            %{
              "ground_station_id" => "equator_prime",
              "contact_count" => 2,
              "ignored_contact_count" => 1,
              "ignored_contact_ids" => ["dl_rejected"],
              "selected_contact_count" => 1,
              "selected_contact_ids" => ["dl_selected"],
              "estimated_throughput_mb" => 160.0,
              "selected_estimated_throughput_mb" => 100.0,
              "capacity_adjusted_throughput_mb" => 128.0,
              "selected_capacity_adjusted_throughput_mb" => 80.0,
              "unused_capacity_adjusted_throughput_mb" => 48.0,
              "selected_downlink_shortfall_mb" => 40.0,
              "downlink_requirement_status" => "shortfall",
              "actual_throughput_mb" => 72.0,
              "actual_downlink_shortfall_mb" => 48.0,
              "actual_downlink_requirement_status" => "shortfall",
              "capacity_fraction_min" => 0.5,
              "capacity_fraction_max" => 0.8,
              "contact_ids" => ["dl_selected", "dl_rejected"],
              "approval_status" => "operator_review_required",
              "approval_requirements" => [
                %{
                  "activity_id" => "link_capacity:equator_prime",
                  "activity_type" => "link_capacity_summary",
                  "action" => "review_link_capacity_summary",
                  "requirement_type" => "contact_schedule_change"
                }
              ],
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "policy_bundle_id" => "ground_network_allocation_v1"
              }
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_link_capacity_review:001",
             "review_count" => 1,
             "link_capacity_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "link_capacity_review",
               "source" => "candidate_refresh.source_result_artifact.link_capacity_report.rows",
               "subject_id" => "equator_prime",
               "ground_station_id" => "equator_prime",
               "required_operator_action" => "review_link_capacity_summary",
               "contact_count" => 2,
               "ignored_contact_count" => 1,
               "ignored_contact_ids" => ["dl_rejected"],
               "selected_contact_count" => 1,
               "selected_contact_ids" => ["dl_selected"],
               "selected_capacity_adjusted_throughput_mb" => 80.0,
               "unused_capacity_adjusted_throughput_mb" => 48.0,
               "selected_downlink_shortfall_mb" => 40.0,
               "downlink_requirement_status" => "shortfall",
               "actual_throughput_mb" => 72.0,
               "actual_downlink_shortfall_mb" => 48.0,
               "actual_downlink_requirement_status" => "shortfall",
               "capacity_fraction_min" => 0.5,
               "capacity_fraction_max" => 0.8,
               "requirement_type" => "contact_schedule_change",
               "policy_bundle_id" => "ground_network_allocation_v1",
               "source_link_capacity" => %{
                 "ground_station_id" => "equator_prime",
                 "selected_downlink_shortfall_mb" => 40.0
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh accepted planning state link capacity summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:accepted_link_capacity_summary:001",
      "accepted_planning_state" => %{
        "source_link_capacity_summary" => study_result_fixture("link_capacity_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_link_capacity_summary:001",
             "review_count" => 1,
             "link_capacity_review_count" => 1,
             "review_type_counts" => %{"link_capacity_review" => 1},
             "required_operator_action_counts" => %{"review_link_capacity_summary" => 1}
           } = package

    assert [
             %{
               "review_type" => "link_capacity_review",
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_link_capacity_summary.rows",
               "subject_id" => "equator_prime",
               "ground_station_id" => "equator_prime",
               "required_operator_action" => "review_link_capacity_summary",
               "selected_downlink_shortfall_mb" => +0.0,
               "actual_downlink_shortfall_mb" => 10.0,
               "selected_contact_ids" => ["science_downlink"],
               "actual_throughput_contact_ids" => ["science_downlink"],
               "source_link_capacity" => %{
                 "source_summary_schema_contract" => "link_capacity_summary.v1",
                 "source_summary_model" => "artifact_only_link_capacity_summary",
                 "source_link_capacity_summary" => %{
                   "schema_contract" => "link_capacity_summary.v1",
                   "model" => "artifact_only_link_capacity_summary",
                   "assumptions" => %{
                     "execution_boundary" =>
                       "artifact_only_no_provider_reservation_or_schedule_mutation",
                     "operator_authority" => "not_granted_by_summary"
                   }
                 }
               }
             }
           ] = package["rows"]

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_link_capacity_summary:001",
             "row_count" => 1,
             "source_review_type_counts" => %{"link_capacity_review" => 1},
             "import_action_counts" => %{"review_link_capacity" => 1}
           } = manifest

    assert %{
             "import_action" => "review_link_capacity",
             "source_review_type" => "link_capacity_review",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_link_capacity_summary.rows",
               "source_link_capacity" => %{
                 "source_link_capacity_summary" => %{
                   "schema_contract" => "link_capacity_summary.v1"
                 }
               }
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh mission state relay data path summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:mission_relay_data_path_summary:001",
      "mission_state" => %{
        "relay_data_path_summary" => study_result_fixture("relay_data_path_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:mission_relay_data_path_summary:001",
             "review_count" => 2,
             "link_capacity_review_count" => 2,
             "review_type_counts" => %{"link_capacity_review" => 2}
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.mission_state.relay_data_path_summary.rows",
             "candidate_refresh.mission_state.relay_data_path_summary.rows"
           ]

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "candidate_refresh.mission_state.relay_data_path_summary.rows",
             "subject_id" => "dss_14",
             "ground_station_id" => "dss_14",
             "source_link_capacity" => %{
               "route_id" => "relay_data_path:sat_a:downlink_1:54b7e7ff594c",
               "source_summary_schema_contract" => "relay_data_path_summary.v1",
               "source_link_capacity_summary" => %{
                 "schema_contract" => "relay_data_path_summary.v1",
                 "route_count" => 2,
                 "relay_route_count" => 1
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source_link_capacity"]["route_id"] ==
                   "relay_data_path:sat_a:downlink_1:54b7e7ff594c")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh relay data path summaries become link capacity review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:relay_data_path_review:001",
      "source_relay_data_path_summary" => study_result_fixture("relay_data_path_summary_v1.json")
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:relay_data_path_review:001",
             "review_count" => 2,
             "link_capacity_review_count" => 2
           } = package

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "candidate_refresh.source_relay_data_path_summary.rows",
             "subject_id" => "dss_14",
             "ground_station_id" => "dss_14",
             "required_operator_action" => "review_link_capacity_summary",
             "source_link_capacity" => %{
               "route_id" => "relay_data_path:sat_a:downlink_1:54b7e7ff594c",
               "source_spacecraft_id" => "sat_a",
               "source_summary_schema_contract" => "relay_data_path_summary.v1",
               "source_link_capacity_summary" => %{
                 "route_count" => 2,
                 "relay_route_count" => 1,
                 "route_ids_by_ground_station_id" => %{
                   "dss_14" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
                 }
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source_link_capacity"]["route_id"] ==
                   "relay_data_path:sat_a:downlink_1:54b7e7ff594c")
             )

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "candidate_refresh.source_relay_data_path_summary.rows",
             "subject_id" => "dss_35",
             "ground_station_id" => "dss_35",
             "source_link_capacity" => %{
               "route_id" => "route_direct",
               "latency_status" => "exceeds_limit",
               "risk_status" => "high",
               "source_link_capacity_summary" => %{
                 "risk_status_counts" => %{"high" => 1, "nominal" => 1}
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source_link_capacity"]["route_id"] == "route_direct")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact relay data path summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_relay_data_path_review:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_relay_data_path_summary" =>
            study_result_fixture("relay_data_path_summary_v1.json")
        },
        %{
          "schema_contract" => "result_artifact.v1",
          "relay_data_path_summary" => study_result_fixture("relay_data_path_summary_v1.json")
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_relay_data_path_review:001",
             "review_count" => 4,
             "link_capacity_review_count" => 4
           } = package

    assert %{
             "review_type" => "link_capacity_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_relay_data_path_summary.rows",
             "source_link_capacity" => %{
               "source_summary_schema_contract" => "relay_data_path_summary.v1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_relay_data_path_summary.rows")
             )

    assert %{
             "review_type" => "link_capacity_review",
             "source" =>
               "candidate_refresh.source_result_artifact[1].relay_data_path_summary.rows",
             "source_link_capacity" => %{
               "source_summary_model" => "artifact_only_relay_data_path_summary"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[1].relay_data_path_summary.rows")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source contact filter reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_filter_review:001",
      "source_contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "id" => "source_contact_filter:mission_state",
        "model" => "thin_ground_network_availability_filter",
        "suppressed_candidates" => [
          %{
            "id" => "dl_source_suppressed",
            "base_candidate_id" => "dl_source",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "station_availability" => "unavailable",
            "station_contention_status" => "reserved_overlap",
            "station_reservation_id" => "reservation:equator_prime:dl_source_suppressed",
            "station_reserved_by" => "network_partner",
            "station_reservation_status" => "confirmed",
            "station_reservation_match_status" => "overlap",
            "approval_status" => "blocked_by_policy",
            "approval_requirements" => [
              %{
                "activity_id" => "dl_source_suppressed",
                "activity_type" => "downlink",
                "action" => "review_suppressed_contact",
                "requirement_type" => "contact_schedule_change",
                "reason" => "ground_station_unavailable"
              }
            ],
            "approval_rule_matches" => [
              %{"rule_id" => "unavailable_station_contact_block"}
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "ground_network_allocation_v1",
              "escalations" => [
                %{
                  "rule_id" => "unavailable_station_contact_block",
                  "required_authority" => "contact_schedule_authority",
                  "escalation_level" => "ops_lead",
                  "escalation_queue" => "ground_network",
                  "escalation_role" => "network_scheduler",
                  "sla_s" => 600
                }
              ]
            },
            "suppressed_reason" => "ground_station_unavailable",
            "duplicate_suppressed_candidate_id_collision" => true,
            "duplicate_suppressed_candidate_index" => 1,
            "duplicate_suppressed_candidate_count" => 1,
            "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
            "source_contact_candidate" => %{"id" => "dl_source_suppressed"}
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_filter_review:001",
             "review_count" => 1,
             "contact_suppression_count" => 1
           } = package

    assert [
             %{
               "review_type" => "contact_suppression",
               "source" => "candidate_refresh.source_contact_filter_report.suppressed_candidates",
               "subject_id" => "dl_source_suppressed",
               "activity_id" => "dl_source_suppressed",
               "base_candidate_id" => "dl_source",
               "activity_type" => "downlink",
               "required_operator_action" => "review_suppressed_contact",
               "approval_status" => "blocked_by_policy",
               "reason" => "contact filter suppressed candidate: ground_station_unavailable",
               "ground_station_id" => "equator_prime",
               "direction" => "downlink",
               "station_availability" => "unavailable",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "reservation:equator_prime:dl_source_suppressed",
               "station_reserved_by" => "network_partner",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "overlap",
               "requirement_type" => "contact_schedule_change",
               "required_authority" => "contact_schedule_authority",
               "policy_bundle_id" => "ground_network_allocation_v1",
               "rule_id" => "unavailable_station_contact_block",
               "escalation_level" => "ops_lead",
               "escalation_queue" => "ground_network",
               "escalation_role" => "network_scheduler",
               "sla_s" => 600,
               "duplicate_suppressed_candidate_id_collision" => true,
               "duplicate_suppressed_candidate_index" => 1,
               "duplicate_suppressed_candidate_count" => 1,
               "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
               "source_contact_candidate" => %{"id" => "dl_source_suppressed"},
               "source_contact_suppression" => %{
                 "id" => "dl_source_suppressed",
                 "suppressed_reason" => "ground_station_unavailable"
               },
               "source_policy_decision" => %{
                 "policy_bundle_id" => "ground_network_allocation_v1"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact contact filter reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_contact_filter_review:001",
      "result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "source_contact_filter_report" => %{
          "schema_contract" => "contact_filter_report.v1",
          "suppressed_candidates" => [
            %{
              "id" => "dl_wrapped_suppressed",
              "base_candidate_id" => "dl_wrapped",
              "type" => "downlink",
              "ground_station_id" => "equator_prime",
              "direction" => "downlink",
              "station_availability" => "unavailable",
              "station_contention_status" => "reserved_overlap",
              "station_reservation_id" => "reservation:equator_prime:dl_wrapped_suppressed",
              "station_reserved_by" => "network_partner",
              "station_reservation_status" => "confirmed",
              "station_reservation_match_status" => "overlap",
              "approval_status" => "blocked_by_policy",
              "approval_requirements" => [
                %{
                  "activity_id" => "dl_wrapped_suppressed",
                  "activity_type" => "downlink",
                  "action" => "review_suppressed_contact",
                  "requirement_type" => "contact_schedule_change"
                }
              ],
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "policy_bundle_id" => "ground_network_allocation_v1"
              },
              "suppressed_reason" => "ground_station_unavailable",
              "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
              "source_contact_candidate" => %{"id" => "dl_wrapped_suppressed"}
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_contact_filter_review:001",
             "review_count" => 1,
             "contact_suppression_count" => 1
           } = package

    assert [
             %{
               "review_type" => "contact_suppression",
               "source" =>
                 "candidate_refresh.result_artifact.source_contact_filter_report.suppressed_candidates",
               "subject_id" => "dl_wrapped_suppressed",
               "activity_id" => "dl_wrapped_suppressed",
               "base_candidate_id" => "dl_wrapped",
               "activity_type" => "downlink",
               "required_operator_action" => "review_suppressed_contact",
               "approval_status" => "blocked_by_policy",
               "ground_station_id" => "equator_prime",
               "direction" => "downlink",
               "station_availability" => "unavailable",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "reservation:equator_prime:dl_wrapped_suppressed",
               "station_reserved_by" => "network_partner",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "overlap",
               "requirement_type" => "contact_schedule_change",
               "policy_bundle_id" => "ground_network_allocation_v1",
               "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
               "source_contact_candidate" => %{"id" => "dl_wrapped_suppressed"},
               "source_contact_suppression" => %{
                 "id" => "dl_wrapped_suppressed",
                 "suppressed_reason" => "ground_station_unavailable"
               },
               "source_policy_decision" => %{
                 "policy_bundle_id" => "ground_network_allocation_v1"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source resource filter reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:resource_filter_review:001",
      "source_resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "id" => "source_resource_filter:mission_state",
        "model" => "resource_summary_availability_and_margin_filter",
        "invalid_resource_summary_inputs" => [
          %{
            "resource_summary_id" => "resource_summary:stale_sat",
            "spacecraft_id" => "sat_1",
            "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
            "approval_status" => "operator_review_required",
            "approval_requirements" => [
              %{
                "activity_id" => "resource_summary:stale_sat",
                "activity_type" => "resource_summary",
                "action" => "review_invalid_resource_filter_summary",
                "requirement_type" => "resource_filter_input_validation"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "resource_filter_input_guard_v1"
            },
            "source_resource_summary" => %{"resource_summary_id" => "resource_summary:stale_sat"}
          }
        ],
        "suppressed_candidates" => [
          %{
            "id" => "obs_payload_blocked",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "sat_1",
            "target_id" => "target_a",
            "starts_at_s" => 60.0,
            "ends_at_s" => 180.0,
            "suppressed_reason" => "payload_unavailable",
            "source_window_id" => "window:leo_1:target_visibility:target_a:1",
            "payload_available" => false,
            "resource_blocking_dimension" => "payload",
            "resource_trust_boundary_status" => "declared",
            "resource_trust_boundary" => "mission_state_resource_summary",
            "approval_status" => "blocked_by_policy",
            "approval_requirements" => [
              %{
                "activity_id" => "obs_payload_blocked",
                "activity_type" => "observe",
                "action" => "review_suppressed_observation",
                "requirement_type" => "observation_reassignment",
                "reason" => "payload_unavailable"
              }
            ],
            "approval_rule_matches" => [
              %{"rule_id" => "payload_unavailable_observation_block"}
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "degraded_payload_guard_v1",
              "escalations" => [
                %{
                  "rule_id" => "payload_unavailable_observation_block",
                  "required_authority" => "payload_operations_authority",
                  "escalation_level" => "payload_lead",
                  "escalation_queue" => "payload_ops",
                  "escalation_role" => "payload_scheduler",
                  "sla_s" => 900
                }
              ]
            },
            "source_resource_summary" => %{"spacecraft_id" => "sat_1"}
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:resource_filter_review:001",
             "review_count" => 2,
             "resource_suppression_count" => 2
           } = package

    assert %{
             "review_type" => "resource_suppression",
             "source" =>
               "candidate_refresh.source_resource_filter_report.invalid_resource_summary_inputs",
             "subject_id" => "resource_summary:stale_sat",
             "spacecraft_id" => "sat_1",
             "required_operator_action" => "review_invalid_resource_filter_summary",
             "invalid_resource_summary_input" => true,
             "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
             "policy_bundle_id" => "resource_filter_input_guard_v1",
             "source_resource_summary" => %{
               "resource_summary_id" => "resource_summary:stale_sat"
             },
             "source_resource_suppression" => %{
               "resource_summary_id" => "resource_summary:stale_sat"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_filter_summary")
             )

    assert %{
             "review_type" => "resource_suppression",
             "source" => "candidate_refresh.source_resource_filter_report.suppressed_candidates",
             "subject_id" => "obs_payload_blocked",
             "activity_id" => "obs_payload_blocked",
             "activity_type" => "observe",
             "required_operator_action" => "review_suppressed_observation",
             "approval_status" => "blocked_by_policy",
             "spacecraft_id" => "sat_1",
             "target_id" => "target_a",
             "payload_available" => false,
             "resource_blocking_dimension" => "payload",
             "resource_trust_boundary_status" => "declared",
             "resource_trust_boundary" => "mission_state_resource_summary",
             "requirement_type" => "observation_reassignment",
             "required_authority" => "payload_operations_authority",
             "policy_bundle_id" => "degraded_payload_guard_v1",
             "rule_id" => "payload_unavailable_observation_block",
             "escalation_level" => "payload_lead",
             "escalation_queue" => "payload_ops",
             "escalation_role" => "payload_scheduler",
             "sla_s" => 900,
             "source_resource_summary" => %{"spacecraft_id" => "sat_1"},
             "source_resource_suppression" => %{
               "id" => "obs_payload_blocked",
               "suppressed_reason" => "payload_unavailable"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_resource_filter_report.suppressed_candidates")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact resource filter reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_resource_filter_review:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "resource_filter_report" => %{
            "schema_contract" => "resource_filter_report.v1",
            "invalid_resource_summary_inputs" => [
              %{
                "resource_summary_id" => "resource_summary:wrapped_stale_sat",
                "spacecraft_id" => "sat_1",
                "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
                "source_resource_summary" => %{
                  "resource_summary_id" => "resource_summary:wrapped_stale_sat"
                }
              }
            ],
            "suppressed_candidates" => [
              %{
                "id" => "obs_wrapped_payload_blocked",
                "type" => "observe",
                "spacecraft_id" => "sat_1",
                "target_id" => "target_a",
                "suppressed_reason" => "payload_unavailable",
                "payload_available" => false,
                "resource_blocking_dimension" => "payload",
                "resource_trust_boundary_status" => "declared",
                "approval_status" => "blocked_by_policy",
                "source_resource_summary" => %{"spacecraft_id" => "sat_1"}
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_resource_filter_review:001",
             "review_count" => 2,
             "resource_suppression_count" => 2
           } = package

    assert %{
             "review_type" => "resource_suppression",
             "source" =>
               "candidate_refresh.source_result_artifact[0].resource_filter_report.invalid_resource_summary_inputs",
             "subject_id" => "resource_summary:wrapped_stale_sat",
             "source_resource_summary" => %{
               "resource_summary_id" => "resource_summary:wrapped_stale_sat"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_filter_summary")
             )

    assert %{
             "review_type" => "resource_suppression",
             "source" =>
               "candidate_refresh.source_result_artifact[0].resource_filter_report.suppressed_candidates",
             "subject_id" => "obs_wrapped_payload_blocked",
             "activity_id" => "obs_wrapped_payload_blocked",
             "activity_type" => "observe",
             "required_operator_action" => "review_suppressed_observation",
             "approval_status" => "blocked_by_policy",
             "spacecraft_id" => "sat_1",
             "target_id" => "target_a",
             "payload_available" => false,
             "resource_blocking_dimension" => "payload",
             "resource_trust_boundary_status" => "declared",
             "source_resource_summary" => %{"spacecraft_id" => "sat_1"},
             "source_resource_suppression" => %{
               "id" => "obs_wrapped_payload_blocked",
               "suppressed_reason" => "payload_unavailable"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].resource_filter_report.suppressed_candidates")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source resource projection reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:resource_projection_review:001",
      "source_resource_projection_report" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_campaign_selected_activity_resource_projection",
        "invalid_activity_inputs" => [
          %{
            "activity_id" => "bad_projection_activity",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "sat_1",
            "invalid_activity_input_reason" => "missing_activity_duration",
            "approval_status" => "operator_review_required",
            "approval_requirements" => [
              %{
                "activity_id" => "bad_projection_activity",
                "activity_type" => "observe",
                "action" => "review_invalid_resource_projection_input",
                "requirement_type" => "resource_projection_input_validation"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "resource_projection_input_guard_v1"
            },
            "source_activity" => %{"id" => "bad_projection_activity"}
          }
        ],
        "invalid_resource_summary_inputs" => [
          %{
            "resource_summary_id" => "resource_summary:stale_sat",
            "spacecraft_id" => "sat_1",
            "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
            "approval_status" => "operator_review_required",
            "approval_requirements" => [
              %{
                "activity_id" => "resource_summary:stale_sat",
                "activity_type" => "resource_summary",
                "action" => "review_invalid_resource_projection_summary",
                "requirement_type" => "resource_projection_summary_validation"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "resource_projection_summary_guard_v1"
            },
            "source_resource_summary" => %{"resource_summary_id" => "resource_summary:stale_sat"}
          }
        ],
        "projected_resources" => [
          %{
            "spacecraft_id" => "sat_1",
            "activity_count" => 1,
            "effective_activity_count" => 1,
            "ignored_activity_count" => 0,
            "ignored_activity_ids" => [],
            "observation_count" => 1,
            "downlink_count" => 0,
            "estimated_storage_produced_mb" => 20.0,
            "estimated_downlink_mb" => 4.0,
            "storage_limited_downlinked_mb" => 4.0,
            "unused_downlink_capacity_mb" => 0.0,
            "starting_storage_used_mb" => 950.0,
            "projected_storage_used_mb" => 1_020.0,
            "storage_capacity_mb" => 1_000.0,
            "starting_storage_margin" => 0.05,
            "projected_storage_margin" => -0.02,
            "downlink_capacity_mb" => 40.0,
            "starting_downlink_margin" => 0.2,
            "projected_downlink_margin" => 0.0,
            "activity_resource_flow" => [
              %{
                "activity_id" => "obs_overflow",
                "activity_type" => "observe",
                "starts_at_s" => 10.0,
                "storage_overflow_mb" => 12.0,
                "downlink_shortfall_mb" => 0.0,
                "battery_energy_consumed_wh" => 10.0,
                "battery_energy_generated_wh" => 0.0,
                "battery_energy_delta_wh" => 10.0,
                "battery_overuse_wh" => 2.0
              }
            ],
            "resource_source_quality" => "operator_supplied",
            "resource_trust_boundary_status" => "declared",
            "payload_available" => true,
            "antenna_available" => true,
            "approval_requirements" => [
              %{
                "schema_contract" => "approval_requirement.v1",
                "id" => "approval:resource_projection:sat_1:storage_overflow",
                "activity_id" => "resource_projection:sat_1",
                "activity_type" => "resource_projection",
                "action" => "review_resource_projection",
                "requirement_type" => "operator_review",
                "reason" => "storage_overflow 12.0 MB for sat_1"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "classification" => "blocked_by_policy",
              "policy_bundle_id" => "resource_projection_authority_v1",
              "escalations" => [
                %{
                  "rule_id" => "resource_pressure_block",
                  "required_authority" => "resource_authority",
                  "escalation_level" => "mission_planner",
                  "escalation_queue" => "resource_planning",
                  "escalation_role" => "resource_planner",
                  "sla_s" => 1200
                }
              ]
            }
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:resource_projection_review:001",
             "review_count" => 3,
             "resource_projection_review_count" => 3
           } = package

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_resource_projection_report.invalid_activity_inputs",
             "subject_id" => "bad_projection_activity",
             "activity_id" => "bad_projection_activity",
             "required_operator_action" => "review_invalid_resource_projection_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_duration",
             "policy_bundle_id" => "resource_projection_input_guard_v1",
             "source_activity" => %{"id" => "bad_projection_activity"},
             "source_resource_projection" => %{"activity_id" => "bad_projection_activity"}
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_projection_input")
             )

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_resource_projection_report.invalid_resource_summary_inputs",
             "subject_id" => "resource_summary:stale_sat",
             "spacecraft_id" => "sat_1",
             "required_operator_action" => "review_invalid_resource_projection_summary",
             "invalid_resource_summary_input" => true,
             "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
             "policy_bundle_id" => "resource_projection_summary_guard_v1",
             "source_resource_summary" => %{
               "resource_summary_id" => "resource_summary:stale_sat"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_projection_summary")
             )

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_resource_projection_report.projected_resources",
             "subject_id" => "sat_1",
             "spacecraft_id" => "sat_1",
             "required_operator_action" => "review_resource_projection",
             "activity_count" => 1,
             "projected_storage_margin" => -0.02,
             "resource_flow_count" => 1,
             "peak_storage_overflow_mb" => 12.0,
             "peak_battery_overuse_wh" => 2.0,
             "first_resource_pressure_activity_id" => "obs_overflow",
             "first_resource_pressure_kind" => "storage_overflow",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "policy_bundle_id" => "resource_projection_authority_v1",
             "source_resource_projection" => %{
               "spacecraft_id" => "sat_1",
               "resource_trust_boundary_status" => "declared"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_resource_projection_report.projected_resources")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source resource projection flow summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:resource_projection_flow_review:001",
      "source_resource_projection_flow_summary" => [
        resource_projection_flow_summary()
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:resource_projection_flow_review:001",
             "review_count" => 1,
             "resource_projection_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "resource_projection_review",
               "source" =>
                 "candidate_refresh.source_resource_projection_flow_summary[0].projected_resources",
               "subject_id" => "leo_1",
               "spacecraft_id" => "leo_1",
               "required_operator_action" => "review_resource_projection",
               "activity_count" => 2,
               "effective_activity_count" => 2,
               "ignored_activity_count" => 0,
               "resource_flow_count" => 2,
               "total_battery_energy_consumed_wh" => 20.0,
               "total_battery_energy_generated_wh" => 5.0,
               "peak_storage_overflow_mb" => 10.0,
               "peak_downlink_shortfall_mb" => 5.0,
               "first_resource_pressure_activity_id" => "obs_early",
               "first_resource_pressure_kind" => "storage_overflow",
               "source_resource_projection_flow_summary" => %{
                 "schema_contract" => "resource_projection_flow_summary.v1",
                 "resource_flow_status" => "review_required",
                 "source" => "flow_handoff"
               },
               "source_resource_projection" => %{
                 "spacecraft_id" => "leo_1",
                 "source_resource_projection_flow_summary" => %{
                   "schema_contract" => "resource_projection_flow_summary.v1"
                 }
               }
             } = row
           ] = package["rows"]

    assert length(row["source_resource_projection"]["activity_resource_flow"]) == 2

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact resource projection reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_resource_projection_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "source_resource_projection_report" => %{
          "schema_contract" => "resource_projection_report.v1",
          "invalid_activity_inputs" => [
            %{
              "activity_id" => "bad_wrapped_projection_activity",
              "type" => "observe",
              "spacecraft_id" => "sat_1",
              "invalid_activity_input_reason" => "missing_activity_duration",
              "source_activity" => %{"id" => "bad_wrapped_projection_activity"}
            }
          ],
          "invalid_resource_summary_inputs" => [
            %{
              "resource_summary_id" => "resource_summary:wrapped_stale_sat",
              "spacecraft_id" => "sat_1",
              "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
              "source_resource_summary" => %{
                "resource_summary_id" => "resource_summary:wrapped_stale_sat"
              }
            }
          ],
          "projected_resources" => [
            %{
              "spacecraft_id" => "sat_1",
              "activity_count" => 1,
              "effective_activity_count" => 1,
              "ignored_activity_count" => 0,
              "ignored_activity_ids" => [],
              "starting_storage_used_mb" => 950.0,
              "projected_storage_used_mb" => 1_020.0,
              "storage_capacity_mb" => 1_000.0,
              "projected_storage_margin" => -0.02,
              "activity_resource_flow" => [
                %{
                  "activity_id" => "obs_wrapped_overflow",
                  "activity_type" => "observe",
                  "storage_overflow_mb" => 12.0,
                  "downlink_shortfall_mb" => 0.0
                }
              ],
              "resource_trust_boundary_status" => "declared"
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_resource_projection_review:001",
             "review_count" => 3,
             "resource_projection_review_count" => 3
           } = package

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_result_artifact.source_resource_projection_report.invalid_activity_inputs",
             "subject_id" => "bad_wrapped_projection_activity",
             "source_resource_projection" => %{
               "activity_id" => "bad_wrapped_projection_activity"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_projection_input")
             )

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_result_artifact.source_resource_projection_report.invalid_resource_summary_inputs",
             "subject_id" => "resource_summary:wrapped_stale_sat",
             "source_resource_summary" => %{
               "resource_summary_id" => "resource_summary:wrapped_stale_sat"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] ==
                   "review_invalid_resource_projection_summary")
             )

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_result_artifact.source_resource_projection_report.projected_resources",
             "subject_id" => "sat_1",
             "spacecraft_id" => "sat_1",
             "peak_storage_overflow_mb" => 12.0,
             "first_resource_pressure_activity_id" => "obs_wrapped_overflow",
             "source_resource_projection" => %{
               "spacecraft_id" => "sat_1",
               "resource_trust_boundary_status" => "declared"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact.source_resource_projection_report.projected_resources")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact resource projection flow summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_resource_projection_flow_review:001",
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "resource_projection_flow_summary" => resource_projection_flow_summary()
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_resource_projection_flow_review:001",
             "review_count" => 1,
             "resource_projection_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "resource_projection_review",
               "source" =>
                 "candidate_refresh.result_artifact[0].resource_projection_flow_summary.projected_resources",
               "subject_id" => "leo_1",
               "resource_flow_count" => 2,
               "source_resource_projection_flow_summary" => %{
                 "schema_contract" => "resource_projection_flow_summary.v1",
                 "source" => "flow_handoff"
               }
             } = row
           ] = package["rows"]

    assert length(row["source_resource_projection"]["activity_resource_flow"]) == 2

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source provider counteroffer reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:provider_counteroffer_review:001",
      "source_provider_counteroffer_report" => provider_counteroffer_report()
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:provider_counteroffer_review:001",
             "review_count" => 1,
             "provider_counteroffer_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "provider_counteroffer_review",
               "source" => "candidate_refresh.source_provider_counteroffer_report.rows",
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_status" => "proposed",
               "provider_counteroffer_negotiation_state" => "proposed",
               "provider_counteroffer_cost_delta" => 125.5,
               "provider_counteroffer_lock_deadline_s" => 150.0,
               "provider_counteroffer_start_delta_s" => 30.0,
               "provider_counteroffer_end_delta_s" => 40.0,
               "provider_counteroffer_duration_delta_s" => 10.0,
               "required_operator_action" => "review_provider_counteroffer",
               "source_provider_counteroffer" => %{
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_status" => "proposed"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact provider counteroffer reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_provider_counteroffer_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "provider_counteroffer_report" => provider_counteroffer_report()
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_provider_counteroffer_review:001",
             "review_count" => 1,
             "provider_counteroffer_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "provider_counteroffer_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.provider_counteroffer_report.rows",
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_status" => "proposed",
               "required_operator_action" => "review_provider_counteroffer",
               "source_provider_counteroffer" => %{
                 "provider_counteroffer_id" => "provider_offer_1"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh provider counteroffer review and import summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:provider_counteroffer_summaries:001",
      "source_provider_counteroffer_review_summary" =>
        study_result_fixture("provider_counteroffer_review_summary_v1.json"),
      "source_provider_counteroffer_import_readiness_summary" =>
        study_result_fixture("provider_counteroffer_import_readiness_summary_v1.json")
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:provider_counteroffer_summaries:001",
             "review_count" => 2,
             "provider_counteroffer_review_count" => 2
           } = package

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "candidate_refresh.source_provider_counteroffer_review_summary.review_rows",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "source_provider_counteroffer" => %{
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_review_summary.v1",
                 "counteroffer_review_status" => "review_required"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_provider_counteroffer_review_summary.review_rows")
             )

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "candidate_refresh.source_provider_counteroffer_import_readiness_summary.import_readiness_rows",
             "provider_counteroffer_id" => "provider_offer_1",
             "source_provider_counteroffer" => %{
               "provider_counteroffer_import_status" => "review_required_before_import",
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_import_readiness_summary.v1",
                 "import_readiness_status" => "review_required",
                 "provider_counteroffer_import_status_counts" => %{
                   "review_required_before_import" => 1
                 }
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_provider_counteroffer_import_readiness_summary.import_readiness_rows")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact provider counteroffer summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_provider_counteroffer_summaries:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_provider_counteroffer_review_summary" =>
            study_result_fixture("provider_counteroffer_review_summary_v1.json"),
          "provider_counteroffer_import_readiness_summary" =>
            study_result_fixture("provider_counteroffer_import_readiness_summary_v1.json")
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_provider_counteroffer_summaries:001",
             "review_count" => 2,
             "provider_counteroffer_review_count" => 2
           } = package

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_provider_counteroffer_review_summary.review_rows",
             "source_provider_counteroffer" => %{
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_review_summary.v1"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_provider_counteroffer_review_summary.review_rows")
             )

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].provider_counteroffer_import_readiness_summary.import_readiness_rows",
             "source_provider_counteroffer" => %{
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_import_readiness_summary.v1"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].provider_counteroffer_import_readiness_summary.import_readiness_rows")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source provider counteroffer plan-impact summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:provider_counteroffer_plan_impact_review:001",
      "source_provider_counteroffer_plan_impact_summary" => [
        %{
          "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
          "plan_impact_status" => "review_required",
          "affected_station_calendar_entry_ids" => ["contact_original"],
          "affected_provider_entry_ids" => ["provider_offer_2"],
          "impact_counteroffer_ids" => ["offer_2"],
          "impact_rows" => [
            %{
              "id" => "provider_counteroffer:offer_2",
              "provider_counteroffer_id" => "offer_2",
              "provider_counteroffer_status" => "proposed",
              "provider_counteroffer_cost_delta" => 60.0,
              "provider_counteroffer_lock_deadline_s" => 120.0,
              "provider_counteroffer_start_delta_s" => 30.0,
              "provider_counteroffer_end_delta_s" => 30.0,
              "provider_counteroffer_duration_delta_s" => 0.0,
              "reviewable" => true,
              "required_operator_action" => "review_provider_counteroffer",
              "trust_boundary" => "provider_calendar_feed"
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:provider_counteroffer_plan_impact_review:001",
             "review_count" => 1,
             "provider_counteroffer_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "provider_counteroffer_review",
               "source" =>
                 "candidate_refresh.source_provider_counteroffer_plan_impact_summary[0].impact_rows",
               "provider_counteroffer_id" => "offer_2",
               "provider_counteroffer_status" => "proposed",
               "provider_counteroffer_cost_delta" => 60.0,
               "provider_counteroffer_lock_deadline_s" => 120.0,
               "provider_counteroffer_start_delta_s" => 30.0,
               "provider_counteroffer_end_delta_s" => 30.0,
               "required_operator_action" => "review_provider_counteroffer",
               "source_provider_counteroffer" => %{
                 "provider_counteroffer_id" => "offer_2",
                 "trust_boundary" => "provider_calendar_feed"
               }
             } = row
           ] = package["rows"]

    assert row["provider_counteroffer_duration_delta_s"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact provider counteroffer plan-impact summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_provider_counteroffer_plan_impact_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "provider_counteroffer_plan_impact_summary" => %{
          "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
          "plan_impact_status" => "review_required",
          "impact_rows" => [
            %{
              "id" => "provider_counteroffer:offer_2",
              "provider_counteroffer_id" => "offer_2",
              "provider_counteroffer_status" => "proposed",
              "provider_counteroffer_cost_delta" => 60.0,
              "provider_counteroffer_lock_deadline_s" => 120.0,
              "provider_counteroffer_start_delta_s" => 30.0,
              "provider_counteroffer_end_delta_s" => 30.0,
              "provider_counteroffer_duration_delta_s" => 0.0,
              "reviewable" => true,
              "required_operator_action" => "review_provider_counteroffer",
              "trust_boundary" => "provider_calendar_feed"
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_provider_counteroffer_plan_impact_review:001",
             "review_count" => 1,
             "provider_counteroffer_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "provider_counteroffer_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.provider_counteroffer_plan_impact_summary.impact_rows",
               "provider_counteroffer_id" => "offer_2",
               "provider_counteroffer_status" => "proposed",
               "required_operator_action" => "review_provider_counteroffer",
               "source_provider_counteroffer" => %{
                 "provider_counteroffer_id" => "offer_2",
                 "trust_boundary" => "provider_calendar_feed"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source station calendar reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:station_calendar_review:001",
      "source_station_calendar_report" => %{
        "schema_contract" => "station_calendar_report.v1",
        "affected_contacts" => [
          %{
            "contact_id" => "dl_station_unavailable",
            "scenario_id" => "leo_1",
            "contact_type" => "planned_contact",
            "direction" => "downlink",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "station_calendar_entry_id" => "calendar_unavailable_1",
            "station_calendar_provider_id" => "ops_calendar",
            "station_calendar_provider_entry_id" => "provider_unavailable_1",
            "station_calendar_directions" => ["downlink"],
            "station_availability" => "unavailable",
            "station_contention_status" => "station_unavailable",
            "station_calendar_trust_boundary_status" => "declared",
            "trust_boundary" => "mission_state_station_calendar_report",
            "required_operator_action" => "review_station_calendar_contact",
            "approval_status" => "operator_review_required",
            "source_station_calendar_entry" => %{
              "id" => "calendar_unavailable_1",
              "availability" => "unavailable"
            }
          }
        ],
        "provider_calendar_contention_groups" => [
          %{
            "id" => "station_calendar_provider_contention:equator_prime:1",
            "provider_calendar_contention_status" => "provider_calendar_overlap",
            "required_operator_action" => "review_station_provider_contention",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 95.0,
            "ends_at_s" => 165.0,
            "entry_count" => 2,
            "entry_ids" => ["calendar_unavailable_1", "calendar_reserved_1"],
            "provider_ids" => ["ops_calendar"],
            "provider_entry_ids" => ["provider_unavailable_1", "provider_reserved_1"],
            "availabilities" => ["unavailable", "reserved"],
            "directions" => ["downlink"]
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:station_calendar_review:001",
             "review_count" => 2,
             "station_calendar_review_count" => 2
           } = package

    assert %{
             "review_type" => "station_calendar_review",
             "source" => "candidate_refresh.source_station_calendar_report.affected_contacts",
             "contact_id" => "dl_station_unavailable",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "calendar_unavailable_1",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_unavailable_1",
             "station_availability" => "unavailable",
             "station_contention_status" => "station_unavailable",
             "station_calendar_trust_boundary_status" => "declared",
             "trust_boundary" => "mission_state_station_calendar_report",
             "required_operator_action" => "review_station_calendar_contact",
             "source_station_calendar_entry" => %{
               "id" => "calendar_unavailable_1",
               "availability" => "unavailable"
             },
             "source_station_calendar_review" => %{
               "contact_id" => "dl_station_unavailable",
               "station_contention_status" => "station_unavailable"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_calendar_report.affected_contacts")
             )

    assert %{
             "review_type" => "station_calendar_review",
             "source" =>
               "candidate_refresh.source_station_calendar_report.provider_calendar_contention_groups",
             "ground_station_id" => "equator_prime",
             "provider_calendar_contention_status" => "provider_calendar_overlap",
             "provider_calendar_contention_entry_count" => 2,
             "provider_calendar_contention_entry_ids" => [
               "calendar_unavailable_1",
               "calendar_reserved_1"
             ],
             "provider_calendar_contention_provider_ids" => ["ops_calendar"],
             "required_operator_action" => "review_station_provider_contention",
             "source_station_calendar_provider_contention" => %{
               "id" => "station_calendar_provider_contention:equator_prime:1",
               "entry_count" => 2
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_calendar_report.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh station calendar precedence summaries become operator review rows" do
    summary = study_result_fixture("station_calendar_precedence_summary_v1.json")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:station_calendar_precedence_summary:001",
      "source_station_calendar_precedence_summary" => summary
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:station_calendar_precedence_summary:001",
             "review_count" => 1,
             "station_calendar_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "station_calendar_review",
               "source" => "candidate_refresh.source_station_calendar_precedence_summary",
               "subject_id" => "ops_calendar",
               "required_operator_action" => "review_station_calendar",
               "station_calendar_precedence_review_status" => "review_required",
               "station_calendar_precedence_affected_contact_count" => 1,
               "station_calendar_precedence_applied_availability_counts" => %{
                 "unavailable" => 1
               },
               "station_calendar_precedence_overlap_availability_counts" => %{
                 "reduced_capacity" => 1,
                 "reserved" => 1,
                 "unavailable" => 1
               },
               "station_calendar_precedence_reserved_under_higher_precedence_contact_ids" => [
                 "dl_1"
               ],
               "station_calendar_precedence_model_limits" => [
                 "declared_data_only",
                 "no_network_calls",
                 "no_provider_reservation",
                 "no_schedule_mutation",
                 "no_conflict_resolution"
               ],
               "source_station_calendar_precedence_summary" => %{
                 "schema_contract" => "station_calendar_precedence_summary.v1",
                 "source_summary_schema_contract" => "station_calendar_precedence_summary.v1",
                 "source_summary_model" => "artifact_only_station_calendar_precedence_summary",
                 "assumptions" => %{
                   "execution_boundary" => "artifact_only_no_provider_reservation",
                   "operator_authority" => "not_granted_by_summary"
                 }
               }
             }
           ] = package["rows"]

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:station_calendar_precedence_summary:001",
             "row_count" => 1,
             "source_review_type_counts" => %{"station_calendar_review" => 1},
             "import_action_counts" => %{"review_station_calendar" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_station_calendar",
               "source_review_type" => "station_calendar_review",
               "source_review_row" => %{
                 "source" => "candidate_refresh.source_station_calendar_precedence_summary",
                 "station_calendar_precedence_review_status" => "review_required",
                 "source_station_calendar_precedence_summary" => %{
                   "schema_contract" => "station_calendar_precedence_summary.v1"
                 }
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh result artifact station calendar precedence summaries become review rows" do
    summary = study_result_fixture("station_calendar_precedence_summary_v1.json")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_station_calendar_precedence_summary:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_station_calendar_precedence_summary" => summary,
          "station_calendar_precedence_summary" => summary
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_station_calendar_precedence_summary:001",
             "review_count" => 2,
             "station_calendar_review_count" => 2
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.source_result_artifact[0].source_station_calendar_precedence_summary",
             "candidate_refresh.source_result_artifact[0].station_calendar_precedence_summary"
           ]

    assert %{
             "review_type" => "station_calendar_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].station_calendar_precedence_summary",
             "station_calendar_precedence_reserved_under_higher_precedence_contact_count" => 1,
             "source_station_calendar_precedence_summary" => %{
               "source_summary_schema_contract" => "station_calendar_precedence_summary.v1",
               "model_limits" => [
                 "declared_data_only",
                 "no_network_calls",
                 "no_provider_reservation",
                 "no_schedule_mutation",
                 "no_conflict_resolution"
               ]
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].station_calendar_precedence_summary")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact station calendar reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_station_calendar_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "station_calendar_report" => %{
          "schema_contract" => "station_calendar_report.v1",
          "affected_contacts" => [
            %{
              "contact_id" => "dl_wrapped_station_unavailable",
              "scenario_id" => "leo_1",
              "contact_type" => "planned_contact",
              "direction" => "downlink",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 100.0,
              "ends_at_s" => 160.0,
              "station_calendar_entry_id" => "calendar_unavailable_wrapped",
              "station_calendar_provider_id" => "ops_calendar",
              "station_calendar_provider_entry_id" => "provider_unavailable_wrapped",
              "station_calendar_directions" => ["downlink"],
              "station_availability" => "unavailable",
              "station_contention_status" => "station_unavailable",
              "station_calendar_trust_boundary_status" => "declared",
              "trust_boundary" => "mission_state_station_calendar_report",
              "required_operator_action" => "review_station_calendar_contact",
              "approval_status" => "operator_review_required",
              "source_station_calendar_entry" => %{
                "id" => "calendar_unavailable_wrapped",
                "availability" => "unavailable"
              }
            }
          ],
          "provider_calendar_contention_groups" => [
            %{
              "id" => "station_calendar_provider_contention:equator_prime:wrapped",
              "provider_calendar_contention_status" => "provider_calendar_overlap",
              "required_operator_action" => "review_station_provider_contention",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 95.0,
              "ends_at_s" => 165.0,
              "entry_count" => 2,
              "entry_ids" => ["calendar_unavailable_wrapped", "calendar_reserved_wrapped"],
              "provider_ids" => ["ops_calendar"],
              "provider_entry_ids" => [
                "provider_unavailable_wrapped",
                "provider_reserved_wrapped"
              ],
              "availabilities" => ["unavailable", "reserved"],
              "directions" => ["downlink"]
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_station_calendar_review:001",
             "review_count" => 2,
             "station_calendar_review_count" => 2
           } = package

    assert %{
             "review_type" => "station_calendar_review",
             "source" =>
               "candidate_refresh.source_result_artifact.station_calendar_report.affected_contacts",
             "contact_id" => "dl_wrapped_station_unavailable",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "calendar_unavailable_wrapped",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_unavailable_wrapped",
             "station_availability" => "unavailable",
             "station_contention_status" => "station_unavailable",
             "source_station_calendar_entry" => %{
               "id" => "calendar_unavailable_wrapped",
               "availability" => "unavailable"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact.station_calendar_report.affected_contacts")
             )

    assert %{
             "review_type" => "station_calendar_review",
             "source" =>
               "candidate_refresh.source_result_artifact.station_calendar_report.provider_calendar_contention_groups",
             "ground_station_id" => "equator_prime",
             "provider_calendar_contention_status" => "provider_calendar_overlap",
             "provider_calendar_contention_entry_count" => 2,
             "provider_calendar_contention_entry_ids" => [
               "calendar_unavailable_wrapped",
               "calendar_reserved_wrapped"
             ],
             "provider_calendar_contention_provider_ids" => ["ops_calendar"],
             "required_operator_action" => "review_station_provider_contention",
             "source_station_calendar_provider_contention" => %{
               "id" => "station_calendar_provider_contention:equator_prime:wrapped",
               "entry_count" => 2
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact.station_calendar_report.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source station reservation reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:station_reservation_review:001",
      "source_station_reservation_report" => %{
        "schema_contract" => "station_reservation_report.v1",
        "source" => "ops_calendar",
        "affected_contacts" => [
          %{
            "contact_id" => "dl_reserved",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "station_calendar_entry_id" => "calendar_reserved_1",
            "station_calendar_provider_id" => "ops_calendar",
            "station_calendar_provider_entry_id" => "provider_reserved_1",
            "station_contention_status" => "reserved_overlap",
            "station_reservation_match_status" => "owned",
            "station_reservation_id" => "reservation_1",
            "station_reserved_by" => "network_partner",
            "station_reservation_status" => "held",
            "station_calendar_reservation_overlap_count" => 1,
            "station_calendar_reservation_ids" => ["reservation_1"],
            "station_calendar_reserved_by" => ["network_partner"],
            "station_calendar_reservation_statuses" => ["held"],
            "station_calendar_reservation_expires_at_s" => [240.0],
            "required_operator_action" => "review_station_reservation_overlap"
          }
        ],
        "provider_calendar_contention_groups" => [
          %{
            "id" => "station_calendar_provider_contention:equator_prime:1",
            "provider_calendar_contention_status" => "provider_calendar_overlap",
            "required_operator_action" => "review_station_provider_contention",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 95.0,
            "ends_at_s" => 165.0,
            "entry_count" => 2,
            "entry_ids" => ["calendar_reserved_1", "calendar_reserved_2"],
            "reservation_ids" => ["reservation_1", "reservation_2"],
            "reservation_statuses" => ["held", "confirmed"]
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:station_reservation_review:001",
             "review_count" => 2,
             "station_reservation_review_count" => 2
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" => "candidate_refresh.source_station_reservation_report.affected_contacts",
             "contact_id" => "dl_reserved",
             "ground_station_id" => "equator_prime",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_reserved_1",
             "station_reservation_id" => "reservation_1",
             "station_reserved_by" => "network_partner",
             "station_reservation_status" => "held",
             "station_reservation_match_status" => "owned",
             "required_operator_action" => "review_station_reservation_overlap",
             "source_station_reservation" => %{
               "contact_id" => "dl_reserved",
               "station_reservation_id" => "reservation_1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_report.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_report.provider_calendar_contention_groups",
             "provider_calendar_contention_group_id" =>
               "station_calendar_provider_contention:equator_prime:1",
             "provider_calendar_contention_reservation_ids" => [
               "reservation_1",
               "reservation_2"
             ],
             "required_operator_action" => "review_station_provider_contention",
             "source_station_reservation" => %{
               "id" => "station_calendar_provider_contention:equator_prime:1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_report.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh station reservation summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:station_reservation_summaries:001",
      "source_station_reservation_review_summary" =>
        station_reservation_summary_fixture("station_reservation_review_summary_v1.json"),
      "source_station_reservation_hold_summary" =>
        station_reservation_summary_fixture("station_reservation_hold_summary_v1.json")
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:station_reservation_summaries:001",
             "review_count" => 5,
             "station_reservation_review_count" => 5
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_review_summary.review_rows.affected_contacts",
             "contact_id" => "dl_source_reserved",
             "station_reservation_id" => "reservation_expired",
             "source_station_reservation" => %{
               "station_reservation_summary_model" =>
                 "artifact_only_station_reservation_review_summary",
               "station_reservation_summary_schema_contract" =>
                 "station_reservation_review_summary.v1",
               "source_station_reservation_summary" => %{
                 "reservation_review_status" => "review_required"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_review_summary.review_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_hold_summary.review_rows.affected_contacts",
             "contact_id" => "dl_source_reserved",
             "station_reservation_hold_count" => 2,
             "station_reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
             "source_station_reservation" => %{
               "station_reservation_summary_model" =>
                 "artifact_only_station_reservation_hold_summary",
               "source_station_reservation_summary" => %{
                 "reservation_hold_review_status" => "review_required",
                 "reservation_hold_count" => 2
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_hold_summary.review_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_hold_summary.review_rows.provider_calendar_contention_groups",
             "provider_calendar_contention_group_id" =>
               "station_reservation_summary:provider_calendar_contention_group:polar_prime:reservation_missing",
             "station_reservation_hold_count" => 2,
             "required_operator_action" => "review_station_provider_contention",
             "source_station_reservation" => %{
               "reservation_review_row_type" => "provider_calendar_contention_group",
               "station_reservation_id" => "reservation_missing"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_hold_summary.review_rows.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh hold import-readiness summaries become station reservation review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:hold_import_readiness_review:001",
      "source_station_reservation_hold_import_readiness_summary" =>
        station_reservation_hold_import_readiness_summary()
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:hold_import_readiness_review:001",
             "review_count" => 2,
             "station_reservation_review_count" => 2,
             "required_operator_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             }
           } = package

    affected_row = Enum.find(package["rows"], &(&1["contact_id"] == "dl_source_reserved"))

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.affected_contacts",
             "contact_id" => "dl_source_reserved",
             "ground_station_id" => "equator_prime",
             "station_reservation_id" => "reservation_expired",
             "station_calendar_reservation_overlap_count" => 1,
             "station_calendar_reservation_ids" => ["reservation_expired"],
             "station_calendar_reserved_by" => ["ops_calendar"],
             "station_calendar_reservation_statuses" => ["held"],
             "station_reservation_hold_import_status" => "review_required_before_import",
             "station_reservation_hold_import_readiness_status" => "review_required",
             "station_reservation_hold_import_classification" => "review_only",
             "station_reservation_hold_import_execution_boundary" =>
               "artifact_only_no_provider_or_cadence_writes",
             "station_reservation_hold_provider_write" => "not_performed_by_summary",
             "station_reservation_hold_cadence_write" => "not_performed_by_summary",
             "station_reservation_hold_reservation_acceptance" => "not_performed_by_summary",
             "required_operator_action" => "review_station_reservation_overlap",
             "source_station_reservation_hold_import_readiness_summary" => %{
               "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
               "import_readiness_status" => "review_required",
               "reservation_hold_count" => 2
             },
             "source_station_reservation" => %{
               "station_reservation_hold_import_status" => "review_required_before_import",
               "source_station_reservation_hold_import_readiness_summary" => %{
                 "import_readiness_status" => "review_required"
               }
             }
           } = affected_row

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.provider_calendar_contention_groups",
             "provider_calendar_contention_reservation_ids" => ["reservation_missing"],
             "provider_calendar_contention_reserved_by" => ["partner_calendar"],
             "provider_calendar_contention_reservation_statuses" => ["held"],
             "station_reservation_hold_import_status" => "review_required_before_import",
             "station_reservation_hold_ids_by_required_import_action" => %{
               "review_station_provider_contention" => ["reservation_missing"],
               "review_station_reservation_overlap" => ["reservation_expired"]
             },
             "required_operator_action" => "review_station_provider_contention",
             "source_station_reservation" => %{
               "reservation_review_row_type" => "provider_calendar_contention_group",
               "station_reservation_hold_import_status" => "review_required_before_import"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact station reservation reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_station_reservation_review:001",
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "station_reservation_report" => %{
            "schema_contract" => "station_reservation_report.v1",
            "source" => "ops_calendar",
            "affected_contacts" => [
              %{
                "contact_id" => "dl_wrapped_reserved",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "station_calendar_entry_id" => "calendar_wrapped_reserved_1",
                "station_calendar_provider_id" => "ops_calendar",
                "station_calendar_provider_entry_id" => "provider_wrapped_reserved_1",
                "station_contention_status" => "reserved_overlap",
                "station_reservation_match_status" => "owned",
                "station_reservation_id" => "reservation_wrapped_1",
                "station_reserved_by" => "network_partner",
                "station_reservation_status" => "held",
                "station_calendar_reservation_overlap_count" => 1,
                "station_calendar_reservation_ids" => ["reservation_wrapped_1"],
                "station_calendar_reserved_by" => ["network_partner"],
                "station_calendar_reservation_statuses" => ["held"],
                "station_calendar_reservation_expires_at_s" => [240.0],
                "required_operator_action" => "review_station_reservation_overlap"
              }
            ],
            "provider_calendar_contention_groups" => [
              %{
                "id" => "station_calendar_provider_contention:equator_prime:wrapped",
                "provider_calendar_contention_status" => "provider_calendar_overlap",
                "required_operator_action" => "review_station_provider_contention",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 95.0,
                "ends_at_s" => 165.0,
                "entry_count" => 2,
                "entry_ids" => ["calendar_wrapped_reserved_1", "calendar_wrapped_reserved_2"],
                "reservation_ids" => ["reservation_wrapped_1", "reservation_wrapped_2"],
                "reservation_statuses" => ["held", "confirmed"]
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_station_reservation_review:001",
             "review_count" => 2,
             "station_reservation_review_count" => 2
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.result_artifact[0].station_reservation_report.affected_contacts",
             "contact_id" => "dl_wrapped_reserved",
             "ground_station_id" => "equator_prime",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_wrapped_reserved_1",
             "station_reservation_id" => "reservation_wrapped_1",
             "station_reserved_by" => "network_partner",
             "station_reservation_status" => "held",
             "station_reservation_match_status" => "owned",
             "required_operator_action" => "review_station_reservation_overlap",
             "source_station_reservation" => %{
               "contact_id" => "dl_wrapped_reserved",
               "station_reservation_id" => "reservation_wrapped_1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.result_artifact[0].station_reservation_report.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.result_artifact[0].station_reservation_report.provider_calendar_contention_groups",
             "provider_calendar_contention_group_id" =>
               "station_calendar_provider_contention:equator_prime:wrapped",
             "provider_calendar_contention_reservation_ids" => [
               "reservation_wrapped_1",
               "reservation_wrapped_2"
             ],
             "required_operator_action" => "review_station_provider_contention",
             "source_station_reservation" => %{
               "id" => "station_calendar_provider_contention:equator_prime:wrapped"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.result_artifact[0].station_reservation_report.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact hold import-readiness summaries become station reservation review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_hold_import_readiness_review:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_station_reservation_hold_import_readiness_summary" =>
            station_reservation_hold_import_readiness_summary()
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_hold_import_readiness_review:001",
             "review_count" => 2,
             "station_reservation_review_count" => 2
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_station_reservation_hold_import_readiness_summary.import_readiness_rows.affected_contacts",
             "contact_id" => "dl_source_reserved",
             "station_reservation_id" => "reservation_expired",
             "station_reservation_hold_import_status" => "review_required_before_import",
             "station_reservation_hold_import_readiness_status" => "review_required",
             "station_reservation_hold_import_execution_boundary" =>
               "artifact_only_no_provider_or_cadence_writes",
             "source_station_reservation_hold_import_readiness_summary" => %{
               "reservation_hold_count" => 2,
               "import_readiness_status" => "review_required"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_station_reservation_hold_import_readiness_summary.import_readiness_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_station_reservation_hold_import_readiness_summary.import_readiness_rows.provider_calendar_contention_groups",
             "provider_calendar_contention_reservation_ids" => ["reservation_missing"],
             "station_reservation_hold_provider_write" => "not_performed_by_summary",
             "station_reservation_hold_cadence_write" => "not_performed_by_summary",
             "station_reservation_hold_reservation_acceptance" => "not_performed_by_summary",
             "required_operator_action" => "review_station_provider_contention"
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_station_reservation_hold_import_readiness_summary.import_readiness_rows.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact station reservation summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_station_reservation_summaries:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_station_reservation_review_summary" =>
            station_reservation_summary_fixture("station_reservation_review_summary_v1.json"),
          "station_reservation_hold_summary" =>
            station_reservation_summary_fixture("station_reservation_hold_summary_v1.json")
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_station_reservation_summaries:001",
             "review_count" => 5,
             "station_reservation_review_count" => 5
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_station_reservation_review_summary.review_rows.affected_contacts",
             "station_reservation_id" => "reservation_expired",
             "source_station_reservation" => %{
               "source_station_reservation_summary" => %{
                 "schema_contract" => "station_reservation_review_summary.v1"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_station_reservation_review_summary.review_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].station_reservation_hold_summary.review_rows.provider_calendar_contention_groups",
             "station_reservation_hold_count" => 2,
             "source_station_reservation" => %{
               "source_station_reservation_summary" => %{
                 "schema_contract" => "station_reservation_hold_summary.v1"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].station_reservation_hold_summary.review_rows.provider_calendar_contention_groups")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact operational readiness reports become operator review rows" do
    report =
      operational_readiness_resource_report()
      |> Map.put("report_id", "operational_readiness:wrapped_resource_pressure")
      |> Map.put("source_artifact_id", "candidate_refresh:wrapped_operational_readiness:001")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_operational_readiness:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "operational_readiness_report" => report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_operational_readiness:001",
             "review_count" => 2,
             "operational_readiness_review_count" => 2
           } = package

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "candidate_refresh.source_result_artifact.operational_readiness_report",
             "subject_id" => "operational_readiness:wrapped_resource_pressure",
             "required_operator_action" => "review_operational_readiness",
             "operational_readiness_status" => "review_required",
             "resource_availability_pressure_count" => 3,
             "source_operational_readiness_report" => %{
               "report_id" => "operational_readiness:wrapped_resource_pressure"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["subject_id"] == "operational_readiness:wrapped_resource_pressure")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.source_result_artifact.operational_readiness_report.gates",
             "readiness_gate_id" => "resource_availability",
             "required_operator_action" => "review_operational_readiness",
             "resource_availability_pressure_count" => 3
           } = Enum.find(package["rows"], &(&1["readiness_gate_id"] == "resource_availability"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh operational readiness summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:operational_readiness_summaries:001",
      "source_operational_import_eligibility_summary" =>
        study_result_fixture("operational_import_eligibility_summary_v1.json"),
      "source_operational_readiness_gate_summary" =>
        study_result_fixture("operational_readiness_gate_summary_v1.json"),
      "source_operational_execution_boundary_summary" =>
        study_result_fixture("operational_execution_boundary_summary_v1.json")
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:operational_readiness_summaries:001",
             "review_count" => 3,
             "operational_readiness_review_count" => 3
           } = package

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "candidate_refresh.source_operational_import_eligibility_summary",
             "subject_id" => "activity_1",
             "required_operator_action" => "record_operational_readiness_importable",
             "cadence_import_status" => "present",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_import_eligibility_summary.v1",
               "source_summary_schema_contract" => "operational_import_eligibility_summary.v1",
               "source_summary_model" => "artifact_only_import_eligibility_summary"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] == "candidate_refresh.source_operational_import_eligibility_summary")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "candidate_refresh.source_operational_readiness_gate_summary",
             "gate_count" => 5,
             "passed_gate_count" => 5,
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_gate_summary.v1",
               "source_summary_schema_contract" => "operational_readiness_gate_summary.v1",
               "gates" => [%{"id" => "source_contract"} | _]
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] == "candidate_refresh.source_operational_readiness_gate_summary")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "candidate_refresh.source_operational_execution_boundary_summary",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_execution_boundary_summary.v1",
               "source_summary_schema_contract" => "operational_execution_boundary_summary.v1",
               "assumptions" => %{
                 "command_execution" => "not_performed_by_summary"
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_operational_execution_boundary_summary")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact operational readiness summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_operational_readiness_summaries:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_operational_readiness_gate_summary" =>
            study_result_fixture("operational_readiness_gate_summary_v1.json"),
          "operational_execution_boundary_summary" =>
            study_result_fixture("operational_execution_boundary_summary_v1.json")
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_operational_readiness_summaries:001",
             "review_count" => 2,
             "operational_readiness_review_count" => 2
           } = package

    assert %{
             "review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary",
             "source_operational_readiness_report" => %{
               "source_summary_schema_contract" => "operational_readiness_gate_summary.v1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].operational_execution_boundary_summary",
             "source_operational_readiness_report" => %{
               "source_summary_schema_contract" => "operational_execution_boundary_summary.v1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].operational_execution_boundary_summary")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

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

  test "candidate refresh source schema validation reports become operator review rows" do
    source_schema_validation_report = %{
      "schema_contract" => "schema_validation_report.v1",
      "status" => "fail",
      "validation_mode" => "artifact_file",
      "validated_contract" => "campaign_plan.v1",
      "validated_artifact_family" => "campaign_plan",
      "artifact_path" => "study_results/bad_campaign.json",
      "error_count" => 1,
      "warning_count" => 0,
      "remediation_count" => 1,
      "errors" => [
        %{
          "path" => "$.plan_id",
          "message" => "is required",
          "severity" => "error"
        }
      ],
      "remediation" => [
        %{
          "path" => "$.plan_id",
          "category" => "missing_required_field",
          "action" => "Populate this required field"
        }
      ]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:schema_validation_review:001",
      "source_schema_validation_report" => source_schema_validation_report
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:schema_validation_review:001",
             "review_count" => 1,
             "schema_validation_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "schema_validation_review",
               "source" => "candidate_refresh.source_schema_validation_report.errors",
               "subject_id" => "campaign_plan.v1",
               "required_operator_action" => "review_schema_validation",
               "action" => "review_schema_validation_failure",
               "validation_status" => "fail",
               "validation_mode" => "artifact_file",
               "validated_contract" => "campaign_plan.v1",
               "artifact_path" => "study_results/bad_campaign.json",
               "issue_severity" => "error",
               "issue_path" => "$.plan_id",
               "issue_message" => "is required",
               "remediation_category" => "missing_required_field",
               "remediation_action" => "Populate this required field",
               "source_validation_issue" => %{
                 "path" => "$.plan_id",
                 "message" => "is required"
               },
               "source_schema_validation_report" => ^source_schema_validation_report
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source schema validation batch reports become operator review rows" do
    failing_report = schema_validation_report()

    passing_report = %{
      failing_report
      | "validated_contract" => "candidate_refresh.v1",
        "validated_artifact_family" => "candidate_refresh",
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 0,
        "errors" => [],
        "warnings" => [],
        "artifact_path" => "study_results/candidate_refresh_v1.json",
        "remediation_count" => 0,
        "remediation" => []
    }

    batch = %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "validation_mode" => "artifact_directory",
      "input_dir" => "study_results",
      "file_count" => 2,
      "artifact_count" => 2,
      "status" => "fail",
      "error_count" => 1,
      "warning_count" => 0,
      "reports" => [
        %{"path" => "study_results/bad_campaign.json", "report" => failing_report},
        %{"path" => "study_results/candidate_refresh_v1.json", "report" => passing_report}
      ]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:schema_validation_batch_review:001",
      "source_schema_validation_batch_report" => [batch]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:schema_validation_batch_review:001",
             "review_count" => 1,
             "schema_validation_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "schema_validation_review",
               "source" =>
                 "candidate_refresh.source_schema_validation_batch_report[0].reports[0].report.errors",
               "validated_contract" => "campaign_plan.v1",
               "artifact_path" => "study_results/bad_campaign.json",
               "issue_path" => "$.plan_id",
               "source_schema_validation_report" => %{
                 "batch_entry_path" => "study_results/bad_campaign.json"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh state-scoped schema validation reports become review and import rows" do
    report = schema_validation_report()

    batch = %{
      "schema_contract" => "schema_validation_batch_report.v1",
      "validation_mode" => "artifact_directory",
      "input_dir" => "study_results",
      "status" => "fail",
      "reports" => [
        %{"path" => "study_results/bad_campaign.json", "report" => report}
      ]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:state_schema_validation:001",
      "accepted_planning_state" => %{"source_schema_validation_report" => report},
      "mission_state" => %{"source_schema_validation_batch_report" => batch}
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_schema_validation:001",
             "review_count" => 2,
             "schema_validation_review_count" => 2
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_schema_validation_report.errors",
             "candidate_refresh.mission_state.source_schema_validation_batch_report.reports[0].report.errors"
           ]

    assert %{
             "review_type" => "schema_validation_review",
             "validated_contract" => "campaign_plan.v1",
             "issue_path" => "$.plan_id",
             "source_schema_validation_report" => %{
               "schema_contract" => "schema_validation_report.v1"
             }
           } = List.first(package["rows"])

    assert %{
             "source_schema_validation_report" => %{
               "batch_entry_path" => "study_results/bad_campaign.json"
             }
           } = List.last(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_schema_validation:001",
             "row_count" => 2,
             "source_review_type_counts" => %{"schema_validation_review" => 2}
           } = manifest

    assert Enum.map(manifest["rows"], &get_in(&1, ["source_review_row", "source"])) == [
             "candidate_refresh.accepted_planning_state.source_schema_validation_report.errors",
             "candidate_refresh.mission_state.source_schema_validation_batch_report.reports[0].report.errors"
           ]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh schema validation containers become operator review rows" do
    operator_report = schema_validation_report()

    import_report =
      schema_validation_report()
      |> Map.put("validated_contract", "candidate_refresh.v1")
      |> Map.put("validated_artifact_family", "candidate_refresh")
      |> Map.put("artifact_path", "study_results/bad_candidate_refresh.json")

    wrapped_report =
      schema_validation_report()
      |> Map.put("validated_contract", "campaign_strategy.v3")
      |> Map.put("validated_artifact_family", "campaign_strategy")
      |> Map.put("artifact_path", "study_results/bad_strategy.json")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:schema_validation_container_review:001",
      "source_operator_review_package" =>
        OperatorReview.from_schema_validation_report(operator_report),
      "source_cadence_import_manifest" =>
        CadenceImport.from_schema_validation_report(import_report),
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "schema_validation_report" => wrapped_report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:schema_validation_container_review:001",
             "review_count" => 3,
             "schema_validation_review_count" => 3
           } = package

    assert [
             %{
               "review_type" => "schema_validation_review",
               "source" =>
                 "candidate_refresh.source_operator_review_package.rows.source_schema_validation_report.errors",
               "validated_contract" => "campaign_plan.v1",
               "artifact_path" => "study_results/bad_campaign.json",
               "issue_path" => "$.plan_id",
               "source_schema_validation_report" => %{
                 "source" => "preserved_schema_validation_review_rows"
               }
             },
             %{
               "review_type" => "schema_validation_review",
               "source" =>
                 "candidate_refresh.source_cadence_import_manifest.rows.source_schema_validation_report.errors",
               "validated_contract" => "candidate_refresh.v1",
               "artifact_path" => "study_results/bad_candidate_refresh.json",
               "issue_path" => "$.plan_id",
               "source_schema_validation_report" => %{
                 "source" => "preserved_schema_validation_review_rows"
               }
             },
             %{
               "review_type" => "schema_validation_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.schema_validation_report.errors",
               "validated_contract" => "campaign_strategy.v3",
               "artifact_path" => "study_results/bad_strategy.json",
               "issue_path" => "$.plan_id",
               "source_schema_validation_report" => ^wrapped_report
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source contact intents become operator review rows" do
    source_intent = %{
      "schema_contract" => "contact_intent.v1",
      "id" => "review_source_downlink",
      "activity_id" => "review_source_downlink",
      "activity_type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "starts_at_s" => 120.0,
      "ends_at_s" => 180.0,
      "approval_status" => "operator_review_required",
      "approval_requirements" => [
        %{
          "schema_contract" => "approval_requirement.v1",
          "action" => "review_contact_intent",
          "requirement_type" => "contact_schedule_change",
          "required_authority" => "contact_schedule_authority",
          "reason" => "source contact intent requires schedule review"
        }
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "policy_bundle_id" => "command_contact_authority_v1",
        "classification" => "operator_review_required"
      }
    }

    singular_intent = %{
      source_intent
      | "id" => "blocked_source_command",
        "activity_id" => "blocked_source_command",
        "direction" => "command",
        "approval_status" => "blocked_by_policy",
        "approval_requirements" => []
    }

    ignored_import_ready_intent = %{
      source_intent
      | "id" => "ready_source_downlink",
        "activity_id" => "ready_source_downlink",
        "approval_status" => "approved",
        "approval_requirements" => [],
        "policy_decision" => nil
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_contact_intent_review:001",
      "source_contact_intents" => [source_intent, ignored_import_ready_intent],
      "contact_intent" => singular_intent
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_contact_intent_review:001",
             "review_count" => 2,
             "contact_intent_review_count" => 2
           } = package

    assert [
             %{
               "review_type" => "contact_intent_review",
               "source" => "candidate_refresh.source_contact_intents[0]",
               "activity_id" => "review_source_downlink",
               "contact_id" => "review_source_downlink",
               "required_operator_action" => "review_contact_intent",
               "approval_status" => "operator_review_required",
               "required_authority" => "contact_schedule_authority",
               "policy_bundle_id" => "command_contact_authority_v1",
               "source_policy_decision" => %{
                 "policy_bundle_id" => "command_contact_authority_v1"
               },
               "source_contact_intent" => %{
                 "schema_contract" => "contact_intent.v1",
                 "activity_id" => "review_source_downlink"
               }
             },
             %{
               "review_type" => "contact_intent_review",
               "source" => "candidate_refresh.contact_intent",
               "activity_id" => "blocked_source_command",
               "required_operator_action" => "review_contact_intent",
               "approval_status" => "blocked_by_policy",
               "source_contact_intent" => %{
                 "schema_contract" => "contact_intent.v1",
                 "activity_id" => "blocked_source_command"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source contact intent containers become operator review rows" do
    reviewed_intent = %{
      "schema_contract" => "contact_intent.v1",
      "id" => "reviewed_source_downlink",
      "activity_id" => "reviewed_source_downlink",
      "activity_type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "starts_at_s" => 300.0,
      "ends_at_s" => 360.0,
      "approval_status" => "operator_review_required",
      "approval_requirements" => [
        %{
          "schema_contract" => "approval_requirement.v1",
          "action" => "review_contact_intent",
          "requirement_type" => "contact_schedule_change",
          "required_authority" => "contact_schedule_authority",
          "reason" => "reviewed source contact intent requires schedule review"
        }
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "policy_bundle_id" => "command_contact_authority_v1",
        "classification" => "operator_review_required"
      }
    }

    imported_intent = %{
      reviewed_intent
      | "id" => "imported_source_command",
        "activity_id" => "imported_source_command",
        "direction" => "command",
        "approval_status" => "blocked_by_policy"
    }

    wrapper_intent = %{
      reviewed_intent
      | "id" => "wrapped_source_tracking",
        "activity_id" => "wrapped_source_tracking",
        "direction" => "tracking"
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_intent_container_review:001",
      "source_operator_review_package" => OperatorReview.from_contact_intent(reviewed_intent),
      "source_cadence_import_manifest" =>
        imported_intent
        |> OperatorReview.from_contact_intent()
        |> CadenceImport.from_operator_review_package(),
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "contact_intents" => [wrapper_intent]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_intent_container_review:001",
             "review_count" => 3,
             "contact_intent_review_count" => 3
           } = package

    assert [
             %{
               "review_type" => "contact_intent_review",
               "source" =>
                 "candidate_refresh.source_operator_review_package.rows.source_contact_intent[0]",
               "activity_id" => "reviewed_source_downlink",
               "required_operator_action" => "review_contact_intent",
               "source_contact_intent" => %{"activity_id" => "reviewed_source_downlink"}
             },
             %{
               "review_type" => "contact_intent_review",
               "source" =>
                 "candidate_refresh.source_cadence_import_manifest.rows.source_contact_intent[0]",
               "activity_id" => "imported_source_command",
               "required_operator_action" => "review_contact_intent",
               "source_contact_intent" => %{"activity_id" => "imported_source_command"}
             },
             %{
               "review_type" => "contact_intent_review",
               "source" => "candidate_refresh.source_result_artifact.contact_intents[0]",
               "activity_id" => "wrapped_source_tracking",
               "required_operator_action" => "review_contact_intent",
               "source_contact_intent" => %{"activity_id" => "wrapped_source_tracking"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh contact intent summaries become direction-scoped review rows" do
    summary = %{
      "schema_contract" => "contact_intent_summary.v1",
      "model" => "artifact_only_contact_intent_summary",
      "source_artifact_type" => "contact_intent.v1",
      "source" => "operator_review_test.compact_contact_intent_summary",
      "contact_intent_count" => 3,
      "capacity_pack_required_contact_count" => 2,
      "capacity_pack_required_capacity_fraction" => 0.65,
      "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
        "dss_43" => 0.4,
        "equator_prime" => 0.25
      },
      "capacity_pack_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.25,
        "tracking" => 0.4
      },
      "contact_ids_by_ground_station_id" => %{
        "dss_43" => ["intent_nested_capacity", "intent_station_only"],
        "equator_prime" => ["intent_direct_capacity"]
      },
      "contact_ids_by_direction" => %{
        "command" => ["intent_station_only"],
        "downlink" => ["intent_direct_capacity"],
        "tracking" => ["intent_nested_capacity"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "downlink" => ["intent_direct_capacity"],
        "tracking" => ["intent_nested_capacity"]
      },
      "directions" => ["command", "downlink", "tracking"],
      "direction_routing" => %{
        "command" => %{
          "contact_count" => 1,
          "contact_ids" => ["intent_station_only"],
          "capacity_pack_contact_ids" => []
        },
        "downlink" => %{
          "contact_count" => 1,
          "contact_ids" => ["intent_direct_capacity"],
          "capacity_pack_required_capacity_fraction" => 0.25,
          "capacity_pack_contact_ids" => ["intent_direct_capacity"]
        },
        "tracking" => %{
          "contact_count" => 1,
          "contact_ids" => ["intent_nested_capacity"],
          "capacity_pack_required_capacity_fraction" => 0.4,
          "capacity_pack_contact_ids" => ["intent_nested_capacity"]
        }
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation"
      }
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:compact_contact_intent_summary_review",
      "source_contact_intent_summary" => summary
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:compact_contact_intent_summary_review",
             "review_count" => 3,
             "contact_intent_review_count" => 3
           } = package

    assert Enum.map(package["rows"], & &1["direction"]) == ["command", "downlink", "tracking"]

    assert %{
             "source" => "candidate_refresh.source_contact_intent_summary.summary_contacts",
             "activity_id" =>
               "contact_intent_summary:candidate_refresh.source_contact_intent_summary:downlink",
             "contact_id" => "intent_direct_capacity",
             "contact_ids" => ["intent_direct_capacity"],
             "capacity_pack_contact_ids" => ["intent_direct_capacity"],
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "contact_intent_summary.direction_routing",
             "source_summary_model" => "artifact_only_contact_intent_summary",
             "source_summary_schema_contract" => "contact_intent_summary.v1",
             "source_summary_source" => "operator_review_test.compact_contact_intent_summary",
             "source_contact_intent_summary" => %{
               "direction_routing" => %{
                 "downlink" => %{
                   "contact_ids" => ["intent_direct_capacity"],
                   "capacity_pack_contact_ids" => ["intent_direct_capacity"],
                   "capacity_pack_required_capacity_fraction" => 0.25
                 }
               }
             },
             "source_contact_intent" => %{
               "direction" => "downlink",
               "source_contact_intent_summary" => %{
                 "contact_ids_by_direction" => %{
                   "downlink" => ["intent_direct_capacity"]
                 }
               }
             }
           } = Enum.find(package["rows"], &(&1["direction"] == "downlink"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh accepted planning state contact intent summaries become review rows" do
    summary = %{
      "schema_contract" => "contact_intent_summary.v1",
      "model" => "artifact_only_contact_intent_summary",
      "source_artifact_type" => "contact_intent.v1",
      "source" => "operator_review_test.accepted_contact_intent_summary",
      "contact_intent_count" => 2,
      "capacity_pack_required_contact_count" => 1,
      "contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["accepted_downlink_intent"],
        "dss_43" => ["accepted_command_intent"]
      },
      "contact_ids_by_direction" => %{
        "command" => ["accepted_command_intent"],
        "downlink" => ["accepted_downlink_intent"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "downlink" => ["accepted_downlink_intent"]
      },
      "direction_routing" => %{
        "command" => %{
          "contact_count" => 1,
          "contact_ids" => ["accepted_command_intent"],
          "capacity_pack_contact_ids" => []
        },
        "downlink" => %{
          "contact_count" => 1,
          "contact_ids" => ["accepted_downlink_intent"],
          "capacity_pack_required_capacity_fraction" => 0.35,
          "capacity_pack_contact_ids" => ["accepted_downlink_intent"]
        }
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_contact_generation_or_schedule_mutation"
      }
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:accepted_contact_intent_summary_review",
      "accepted_planning_state" => %{
        "source_contact_intent_summary" => summary
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_contact_intent_summary_review",
             "review_count" => 2,
             "contact_intent_review_count" => 2,
             "review_type_counts" => %{"contact_intent_review" => 2}
           } = package

    assert Enum.map(package["rows"], & &1["direction"]) == ["command", "downlink"]

    assert %{
             "source" =>
               "candidate_refresh.accepted_planning_state.source_contact_intent_summary.summary_contacts",
             "activity_id" =>
               "contact_intent_summary:candidate_refresh.accepted_planning_state.source_contact_intent_summary:downlink",
             "contact_id" => "accepted_downlink_intent",
             "contact_ids" => ["accepted_downlink_intent"],
             "capacity_pack_contact_ids" => ["accepted_downlink_intent"],
             "required_capacity_fraction" => 0.35,
             "source_summary_schema_contract" => "contact_intent_summary.v1",
             "source_summary_source" => "operator_review_test.accepted_contact_intent_summary",
             "source_contact_intent_summary" => %{
               "schema_contract" => "contact_intent_summary.v1",
               "source" => "operator_review_test.accepted_contact_intent_summary",
               "direction_routing" => %{
                 "downlink" => %{
                   "contact_ids" => ["accepted_downlink_intent"],
                   "capacity_pack_contact_ids" => ["accepted_downlink_intent"]
                 }
               }
             },
             "source_contact_intent" => %{
               "direction" => "downlink",
               "source_contact_intent_summary" => %{
                 "schema_contract" => "contact_intent_summary.v1"
               }
             }
           } = Enum.find(package["rows"], &(&1["direction"] == "downlink"))

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_contact_intent_summary_review",
             "row_count" => 2,
             "import_action_counts" => %{"review_contact_intent" => 2},
             "source_review_type_counts" => %{"contact_intent_review" => 2}
           } = manifest

    assert %{
             "import_action" => "review_contact_intent",
             "source_review_type" => "contact_intent_review",
             "activity_id" =>
               "contact_intent_summary:candidate_refresh.accepted_planning_state.source_contact_intent_summary:downlink",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_contact_intent_summary.summary_contacts",
               "source_contact_intent_summary" => %{
                 "schema_contract" => "contact_intent_summary.v1"
               }
             }
           } = Enum.find(manifest["rows"], &(&1["direction"] == "downlink"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh mission state contact intent summaries become review rows" do
    summary = %{
      "schema_contract" => "contact_intent_summary.v1",
      "model" => "artifact_only_contact_intent_summary",
      "source_artifact_type" => "contact_intent.v1",
      "source" => "operator_review_test.mission_contact_intent_summary",
      "contact_intent_count" => 1,
      "capacity_pack_required_contact_count" => 1,
      "contact_ids_by_ground_station_id" => %{
        "dss_14" => ["mission_tracking_intent"]
      },
      "contact_ids_by_direction" => %{
        "tracking" => ["mission_tracking_intent"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "tracking" => ["mission_tracking_intent"]
      },
      "direction_routing" => %{
        "tracking" => %{
          "contact_count" => 1,
          "contact_ids" => ["mission_tracking_intent"],
          "capacity_pack_required_capacity_fraction" => 0.55,
          "capacity_pack_contact_ids" => ["mission_tracking_intent"]
        }
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_contact_generation_or_schedule_mutation"
      }
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:mission_contact_intent_summary_review",
      "mission_state" => %{
        "contact_intent_summary" => summary
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:mission_contact_intent_summary_review",
             "review_count" => 1,
             "contact_intent_review_count" => 1,
             "review_type_counts" => %{"contact_intent_review" => 1}
           } = package

    assert [
             %{
               "source" =>
                 "candidate_refresh.mission_state.contact_intent_summary.summary_contacts",
               "activity_id" =>
                 "contact_intent_summary:candidate_refresh.mission_state.contact_intent_summary:tracking",
               "direction" => "tracking",
               "contact_id" => "mission_tracking_intent",
               "contact_ids" => ["mission_tracking_intent"],
               "capacity_pack_contact_ids" => ["mission_tracking_intent"],
               "required_capacity_fraction" => 0.55,
               "source_summary_schema_contract" => "contact_intent_summary.v1",
               "source_summary_source" => "operator_review_test.mission_contact_intent_summary",
               "source_contact_intent_summary" => %{
                 "schema_contract" => "contact_intent_summary.v1",
                 "direction_routing" => %{
                   "tracking" => %{
                     "contact_ids" => ["mission_tracking_intent"],
                     "capacity_pack_contact_ids" => ["mission_tracking_intent"]
                   }
                 }
               }
             }
           ] = package["rows"]

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:mission_contact_intent_summary_review",
             "row_count" => 1,
             "import_action_counts" => %{"review_contact_intent" => 1},
             "source_review_type_counts" => %{"contact_intent_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_contact_intent",
               "source_review_type" => "contact_intent_review",
               "activity_id" =>
                 "contact_intent_summary:candidate_refresh.mission_state.contact_intent_summary:tracking",
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.mission_state.contact_intent_summary.summary_contacts",
                 "source_contact_intent_summary" => %{
                   "schema_contract" => "contact_intent_summary.v1"
                 }
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh result-artifact contact intent summaries become review rows" do
    summary = %{
      "schema_contract" => "contact_intent_summary.v1",
      "model" => "artifact_only_contact_intent_summary",
      "source_artifact_type" => "contact_intent.v1",
      "source" => "operator_review_test.result_contact_intent_summary",
      "contact_intent_count" => 2,
      "capacity_pack_required_contact_count" => 1,
      "contact_ids_by_ground_station_id" => %{
        "dss_43" => ["result_downlink_intent", "result_command_intent"]
      },
      "contact_ids_by_direction" => %{
        "command" => ["result_command_intent"],
        "downlink" => ["result_downlink_intent"]
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "downlink" => ["result_downlink_intent"]
      },
      "direction_routing" => %{
        "command" => %{
          "contact_count" => 1,
          "contact_ids" => ["result_command_intent"],
          "capacity_pack_contact_ids" => []
        },
        "downlink" => %{
          "contact_count" => 1,
          "contact_ids" => ["result_downlink_intent"],
          "capacity_pack_required_capacity_fraction" => 0.45,
          "capacity_pack_contact_ids" => ["result_downlink_intent"]
        }
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_contact_generation_or_schedule_mutation"
      }
    }

    cases = [
      {%{"source_result_artifact" => [summary]},
       "candidate_refresh.source_result_artifact[0].summary_contacts",
       "candidate_refresh.source_result_artifact_0"},
      {%{
         "result_artifact" => %{
           "schema_contract" => "result_artifact.v1",
           "contact_intent_summary" => summary
         }
       }, "candidate_refresh.result_artifact.contact_intent_summary.summary_contacts",
       "candidate_refresh.result_artifact.contact_intent_summary"}
    ]

    expected_rows = %{
      "command" => %{
        contact_id: "result_command_intent",
        contact_ids: ["result_command_intent"],
        capacity_pack_contact_ids: []
      },
      "downlink" => %{
        contact_id: "result_downlink_intent",
        contact_ids: ["result_downlink_intent"],
        capacity_pack_contact_ids: ["result_downlink_intent"],
        required_capacity_fraction: 0.45
      }
    }

    Enum.each(cases, fn {artifact_fields, source, activity_source} ->
      artifact =
        Map.merge(
          %{
            "schema_contract" => "candidate_refresh.v1",
            "refresh_id" => "candidate_refresh:result_contact_intent_summary_review"
          },
          artifact_fields
        )

      package = OperatorReview.from_candidate_refresh_artifact(artifact)
      manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

      assert %{
               "review_count" => 2,
               "contact_intent_review_count" => 2,
               "review_type_counts" => %{"contact_intent_review" => 2}
             } = package

      assert %{
               "row_count" => 2,
               "import_action_counts" => %{"review_contact_intent" => 2},
               "source_review_type_counts" => %{"contact_intent_review" => 2}
             } = manifest

      package_rows_by_direction = Map.new(package["rows"], &{&1["direction"], &1})
      manifest_rows_by_direction = Map.new(manifest["rows"], &{&1["direction"], &1})

      assert Map.keys(package_rows_by_direction) |> Enum.sort() == ["command", "downlink"]
      assert Map.keys(manifest_rows_by_direction) |> Enum.sort() == ["command", "downlink"]

      Enum.each(expected_rows, fn {direction, expected} ->
        contact_id = expected.contact_id
        contact_ids = expected.contact_ids
        capacity_pack_contact_ids = expected.capacity_pack_contact_ids
        activity_id = "contact_intent_summary:#{activity_source}:#{direction}"

        assert %{
                 "source" => ^source,
                 "activity_id" => ^activity_id,
                 "direction" => ^direction,
                 "contact_id" => ^contact_id,
                 "contact_ids" => ^contact_ids,
                 "capacity_pack_contact_ids" => ^capacity_pack_contact_ids,
                 "required_operator_action" => "review_contact_intent",
                 "source_contact_intent_summary" => %{
                   "schema_contract" => "contact_intent_summary.v1",
                   "direction_routing" => %{
                     ^direction => %{
                       "contact_ids" => ^contact_ids,
                       "capacity_pack_contact_ids" => ^capacity_pack_contact_ids
                     }
                   }
                 },
                 "source_contact_intent" => %{
                   "direction" => ^direction,
                   "source_contact_intent_summary" => %{
                     "schema_contract" => "contact_intent_summary.v1"
                   }
                 }
               } = package_rows_by_direction[direction]

        assert %{
                 "import_action" => "review_contact_intent",
                 "source_review_type" => "contact_intent_review",
                 "activity_id" => ^activity_id,
                 "direction" => ^direction,
                 "contact_id" => ^contact_id,
                 "contact_ids" => ^contact_ids,
                 "capacity_pack_contact_ids" => ^capacity_pack_contact_ids,
                 "source_contact_intent_summary" => %{
                   "schema_contract" => "contact_intent_summary.v1",
                   "direction_routing" => %{
                     ^direction => %{
                       "contact_ids" => ^contact_ids,
                       "capacity_pack_contact_ids" => ^capacity_pack_contact_ids
                     }
                   }
                 },
                 "source_contact_intent" => %{
                   "direction" => ^direction,
                   "source_contact_intent_summary" => %{
                     "schema_contract" => "contact_intent_summary.v1"
                   }
                 },
                 "source_review_row" => %{
                   "source" => ^source,
                   "activity_id" => ^activity_id,
                   "direction" => ^direction,
                   "contact_id" => ^contact_id,
                   "contact_ids" => ^contact_ids,
                   "capacity_pack_contact_ids" => ^capacity_pack_contact_ids,
                   "source_contact_intent_summary" => %{
                     "schema_contract" => "contact_intent_summary.v1",
                     "direction_routing" => %{
                       ^direction => %{
                         "contact_ids" => ^contact_ids,
                         "capacity_pack_contact_ids" => ^capacity_pack_contact_ids
                       }
                     }
                   }
                 }
               } = manifest_rows_by_direction[direction]

        case expected do
          %{required_capacity_fraction: required_capacity_fraction} ->
            assert package_rows_by_direction[direction]["required_capacity_fraction"] ==
                     required_capacity_fraction

            assert manifest_rows_by_direction[direction]["required_capacity_fraction"] ==
                     required_capacity_fraction

            assert manifest_rows_by_direction[direction]["source_review_row"][
                     "required_capacity_fraction"
                   ] == required_capacity_fraction

          _ ->
            refute Map.has_key?(
                     package_rows_by_direction[direction],
                     "required_capacity_fraction"
                   )

            refute Map.has_key?(
                     manifest_rows_by_direction[direction],
                     "required_capacity_fraction"
                   )

            refute Map.has_key?(
                     manifest_rows_by_direction[direction]["source_review_row"],
                     "required_capacity_fraction"
                   )
        end
      end)

      assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
               Schema.validate_artifact(package)

      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end)
  end

  test "builds standalone freshness and refresh-budget review packages" do
    stale_freshness = %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "generated_at" => "2026-05-14T00:00:00Z",
      "accepted_at" => "2026-05-12T00:00:00Z",
      "accepted_state_quality_level" => "planning_accepted",
      "allowed_state_quality_levels" => ["accepted"],
      "state_quality_status" => "not_accepted",
      "current_epoch_s" => 0.0,
      "horizon_starts_at_s" => 30.0,
      "accepted_snapshot_age_s" => 172_800.0,
      "horizon_start_offset_s" => 30.0,
      "max_snapshot_age_s" => 86_400.0,
      "max_horizon_start_offset_s" => 1.0,
      "status" => "stale",
      "stale_reasons" => ["accepted_snapshot_older_than_policy"],
      "unknown_reasons" => []
    }

    current_freshness = %{
      stale_freshness
      | "status" => "current",
        "stale_reasons" => [],
        "state_quality_status" => "accepted"
    }

    budget = %{
      "schema_contract" => "refresh_budget_report.v1",
      "model" => "deterministic_candidate_limit_after_filters",
      "input_candidate_count" => 3,
      "kept_candidate_count" => 2,
      "dropped_candidate_count" => 1,
      "max_candidate_activities" => 2,
      "selection_order" => "score_descending_then_start_then_id",
      "kept_candidate_ids" => ["refresh_downlink", "refresh_observe"],
      "dropped_candidate_ids" => ["old_refresh_downlink"]
    }

    empty_budget = %{budget | "dropped_candidate_count" => 0, "dropped_candidate_ids" => []}

    freshness_package = OperatorReview.from_freshness_report(stale_freshness)
    assert OrbitalDynamics.operator_review_package(stale_freshness) == freshness_package

    assert %{
             "source_artifact_type" => "freshness_report.v1",
             "review_count" => 1,
             "freshness_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "freshness_review",
                 "required_operator_action" => "review_refresh_freshness",
                 "freshness_status" => "stale",
                 "source_freshness_report" => %{"status" => "stale"}
               }
             ]
           } = freshness_package

    assert %{"review_count" => 0, "rows" => []} =
             OperatorReview.from_freshness_report(current_freshness)

    budget_package = OperatorReview.from_refresh_budget_report(budget)
    assert OrbitalDynamics.operator_review_package(budget) == budget_package

    assert %{
             "source_artifact_type" => "refresh_budget_report.v1",
             "review_count" => 1,
             "refresh_budget_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "refresh_budget_review",
                 "required_operator_action" => "review_refresh_budget",
                 "dropped_candidate_ids" => ["old_refresh_downlink"],
                 "source_refresh_budget_report" => %{
                   "schema_contract" => "refresh_budget_report.v1"
                 }
               }
             ]
           } = budget_package

    assert %{"review_count" => 0, "rows" => []} =
             OperatorReview.from_refresh_budget_report(empty_budget)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(freshness_package)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(budget_package)

    invalid_freshness_source_status_value =
      update_in(freshness_package, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_freshness_report", "status"],
            "freshness status with spaces"
          )
        ]
      end)

    assert {:error, invalid_freshness_source_status_value_report} =
             Schema.validate_artifact(invalid_freshness_source_status_value)

    assert Enum.any?(
             invalid_freshness_source_status_value_report["errors"],
             &(&1["path"] == "$.rows[0].source_freshness_report.status")
           )

    invalid_freshness_source_status =
      update_in(freshness_package, ["rows"], fn [row] ->
        [Map.put(row, "freshness_status", "current")]
      end)

    assert {:error, invalid_freshness_source_status_report} =
             Schema.validate_artifact(invalid_freshness_source_status)

    assert Enum.any?(
             invalid_freshness_source_status_report["errors"],
             &(&1["path"] == "$.rows[0].source_freshness_report.status" and
                 &1["message"] == "must match freshness_status")
           )

    invalid_budget_source_evidence =
      update_in(budget_package, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_refresh_budget_report", "dropped_candidate_ids"],
            ["old refresh downlink"]
          )
        ]
      end)

    assert {:error, invalid_budget_source_evidence_report} =
             Schema.validate_artifact(invalid_budget_source_evidence)

    assert Enum.any?(
             invalid_budget_source_evidence_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_refresh_budget_report.dropped_candidate_ids[0]")
           )

    stale_budget_source =
      update_in(
        budget_package,
        ["rows", Access.at(0), "source_refresh_budget_report"],
        fn report ->
          Map.put(report, "dropped_candidate_count", 2)
        end
      )

    assert {:error, stale_budget_source_report} = Schema.validate_artifact(stale_budget_source)

    assert Enum.any?(
             stale_budget_source_report["errors"],
             &(&1["path"] == "$.rows[0].dropped_candidate_count" and
                 &1["message"] ==
                   "must match source_refresh_budget_report.dropped_candidate_count")
           )
  end

  test "builds standalone model acceptance review packages" do
    report =
      OrbitalDynamics.validation_model_acceptance_report(
        ["orbit_data.simple_json", "event.access_windows", "missing.model"],
        intended_use: :operational_import
      )

    package = OperatorReview.from_model_acceptance_report(report)
    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "model_acceptance_report.v1",
             "source_artifact_id" => report_id,
             "review_count" => 2,
             "model_acceptance_review_count" => 2,
             "review_type_counts" => %{"model_acceptance_review" => 2},
             "rows" => [
               %{
                 "review_type" => "model_acceptance_review",
                 "source" => "model_acceptance_report.rows",
                 "subject_id" => "event.access_windows",
                 "required_operator_action" => "review_model_acceptance",
                 "approval_status" => "operator_review_required",
                 "model_acceptance_status" => "review_required",
                 "model_acceptance_validation_level" => "analysis"
               },
               %{
                 "review_type" => "model_acceptance_review",
                 "source" => "model_acceptance_report.rows",
                 "subject_id" => "missing.model",
                 "required_operator_action" => "review_blocked_model_acceptance",
                 "approval_status" => "blocked_by_policy",
                 "model_acceptance_status" => "blocked",
                 "model_acceptance_validation_level" => "unknown"
               }
             ]
           } = package

    assert report_id == report["report_id"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds standalone validation safety-case review packages" do
    model_acceptance_report =
      OrbitalDynamics.validation_model_acceptance_report(["missing.model"],
        intended_use: :operational_import
      )

    schema_validation_report = %{
      "schema_contract" => "schema_validation_report.v1",
      "status" => "fail",
      "validated_contract" => "candidate_refresh.v1",
      "error_count" => 1,
      "warning_count" => 0
    }

    summary =
      OrbitalDynamics.validation_safety_case_summary(
        [model_acceptance_report, schema_validation_report],
        case_id: "case:standalone-import"
      )

    package = OperatorReview.from_validation_safety_case_summary(summary)
    assert OrbitalDynamics.operator_review_package(summary) == package

    assert %{
             "source_artifact_type" => "validation_safety_case_summary.v1",
             "source_artifact_id" => summary_id,
             "review_count" => 2,
             "validation_safety_case_review_count" => 2,
             "review_type_counts" => %{"validation_safety_case_review" => 2},
             "rows" => [
               %{
                 "review_type" => "validation_safety_case_review",
                 "source" => "validation_safety_case_summary.evidence",
                 "required_operator_action" => "review_blocked_validation_safety_case",
                 "approval_status" => "blocked_by_policy",
                 "validation_safety_case_evidence_status" => "blocked",
                 "validation_safety_case_input_contract" => "model_acceptance_report.v1"
               },
               %{
                 "review_type" => "validation_safety_case_review",
                 "source" => "validation_safety_case_summary.evidence",
                 "required_operator_action" => "review_blocked_validation_safety_case",
                 "approval_status" => "blocked_by_policy",
                 "validation_safety_case_evidence_status" => "blocked",
                 "validation_safety_case_input_contract" => "schema_validation_report.v1"
               }
             ]
           } = package

    assert summary_id == summary["summary_id"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds standalone candidate diff review package" do
    report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 1,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 1,
      "invalidated_candidate_count" => 1,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "refresh_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "diff_reason" => "semantically_similar_prior_candidate_changed"
        }
      ],
      "invalidated_candidates" => [
        %{
          "id" => "old_refresh_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "source_window_id" => "window:leo_1:target_visibility:target_a:old",
          "starts_at_s" => 90.0,
          "ends_at_s" => 150.0,
          "replacement_candidate_id" => "refresh_observe",
          "invalidated_reason" => "replaced_by_semantically_similar_candidate",
          "semantic_change_reasons" => ["starts_at_s_changed", "source_window_id_changed"]
        }
      ],
      "source_window_lineage" => [
        %{
          "schema_contract" => "source_window_lineage.v1",
          "candidate_activity_id" => "refresh_observe",
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "source_window_type" => "target_visibility",
          "scenario_id" => "leo_1",
          "source_window" => %{
            "schema_contract" => "refreshed_window.v1",
            "id" => "window:leo_1:target_visibility:target_a:1",
            "type" => "target_visibility",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "duration_s" => 60.0,
            "boundary_refinement" => "target_visibility_linear_margin_interpolation"
          }
        }
      ]
    }

    ordinary_new_report = %{
      report
      | "invalidated_candidate_count" => 0,
        "invalidated_candidates" => [],
        "new_candidates" => [
          %{
            "id" => "refresh_observe",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "source_window_id" => "window:leo_1:target_visibility:target_a:1",
            "diff_reason" => "not_present_in_prior_candidate_set"
          }
        ]
    }

    package = OperatorReview.from_candidate_diff_report(report)
    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "candidate_diff_report.v1",
             "review_count" => 1,
             "candidate_diff_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_diff_review",
                 "source" => "candidate_diff_report.invalidated_candidates",
                 "activity_id" => "old_refresh_observe",
                 "target_id" => "target_a",
                 "required_operator_action" => "review_candidate_diff",
                 "replacement_candidate_id" => "refresh_observe",
                 "replacement_source_window_id" => "window:leo_1:target_visibility:target_a:1",
                 "replacement_source_window" => %{
                   "id" => "window:leo_1:target_visibility:target_a:1"
                 },
                 "replacement_source_window_lineage" => %{
                   "candidate_activity_id" => "refresh_observe"
                 },
                 "source_candidate_diff" => %{"id" => "old_refresh_observe"}
               }
             ]
           } = package

    assert %{"review_count" => 0, "rows" => []} =
             OperatorReview.from_candidate_diff_report(ordinary_new_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(row, ["source_candidate_diff", "id"], "candidate diff with spaces")
        ]
      end)

    assert {:error, invalid_source_evidence_report} =
             Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             invalid_source_evidence_report["errors"],
             &(&1["path"] == "$.rows[0].source_candidate_diff.id")
           )

    stale_source_evidence =
      put_in(
        package,
        ["rows", Access.at(0), "source_candidate_diff", "invalidated_reason"],
        "replacement_candidate_lost_station_access"
      )

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].invalidated_reason" and
                 &1["message"] == "must match source_candidate_diff.invalidated_reason")
           )

    assert {:ok, %{"schema_contract" => "candidate_diff_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_lineage_report =
      put_in(
        report,
        ["source_window_lineage", Access.at(0), "source_window_id"],
        "window:leo_1:target_visibility:target_a:mismatch"
      )

    assert {:error, invalid_lineage_validation} = Schema.validate_artifact(invalid_lineage_report)

    assert Enum.any?(
             invalid_lineage_validation["errors"],
             &(&1["path"] == "$.source_window_lineage[0].source_window_id" and
                 &1["message"] == "must match candidate activity source_window_id")
           )
  end

  test "builds candidate diff review rows for unpaired semantic new candidates" do
    report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 1,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 1,
      "invalidated_candidate_count" => 0,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "refresh_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "diff_reason" => "semantically_similar_prior_candidate_changed",
          "matched_prior_candidate_id" => "old_refresh_observe",
          "semantic_change_reasons" => ["starts_at_s_changed", "source_window_id_changed"]
        }
      ],
      "invalidated_candidates" => []
    }

    package = OperatorReview.from_candidate_diff_report(report)

    assert %{
             "review_count" => 1,
             "candidate_diff_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_diff_review",
                 "source" => "candidate_diff_report.new_candidates",
                 "activity_id" => "refresh_observe",
                 "target_id" => "target_a",
                 "reason" =>
                   "candidate diff requires review: semantically_similar_prior_candidate_changed",
                 "semantic_change_reasons" => [
                   "starts_at_s_changed",
                   "source_window_id_changed"
                 ],
                 "source_candidate_diff" => %{
                   "matched_prior_candidate_id" => "old_refresh_observe"
                 }
               } = row
             ]
           } = package

    refute Map.has_key?(row, "invalidated_candidate_id")

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds candidate diff review rows for ambiguous semantic new candidates" do
    report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 2,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 1,
      "invalidated_candidate_count" => 0,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "refresh_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "diff_reason" => "ambiguous_semantic_prior_candidate_match",
          "semantic_match_status" => "ambiguous_prior_candidate",
          "semantic_match_candidate_count" => 2,
          "semantic_match_candidate_ids" => [
            "old_refresh_observe_1",
            "old_refresh_observe_2"
          ]
        }
      ],
      "invalidated_candidates" => []
    }

    package = OperatorReview.from_candidate_diff_report(report)

    assert %{
             "review_count" => 1,
             "candidate_diff_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_diff_review",
                 "source" => "candidate_diff_report.new_candidates",
                 "activity_id" => "refresh_observe",
                 "semantic_match_status" => "ambiguous_prior_candidate",
                 "semantic_match_candidate_count" => 2,
                 "semantic_match_candidate_ids" => [
                   "old_refresh_observe_1",
                   "old_refresh_observe_2"
                 ]
               }
             ]
           } = package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds candidate diff review rows for retained semantic changes" do
    report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 1,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 1,
      "new_candidate_count" => 0,
      "invalidated_candidate_count" => 0,
      "retained_candidates" => [
        %{
          "id" => "leo_1_downlink_equator_prime_1",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
          "semantic_change_reasons" => [
            "estimated_throughput_mb_changed",
            "contact_success_factor_changed"
          ]
        }
      ],
      "new_candidates" => [],
      "invalidated_candidates" => []
    }

    package = OperatorReview.from_candidate_diff_report(report)

    assert %{
             "review_count" => 1,
             "candidate_diff_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_diff_review",
                 "source" => "candidate_diff_report.retained_candidates",
                 "activity_id" => "leo_1_downlink_equator_prime_1",
                 "ground_station_id" => "equator_prime",
                 "semantic_change_reasons" => [
                   "estimated_throughput_mb_changed",
                   "contact_success_factor_changed"
                 ],
                 "source_candidate_diff" => %{
                   "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes"
                 }
               } = row
             ]
           } = package

    refute Map.has_key?(row, "invalidated_candidate_id")

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds standalone invalidated candidate review package" do
    candidate = %{
      "schema_contract" => "invalidated_candidate.v1",
      "id" => "old_refresh_observe",
      "type" => "observe",
      "scenario_id" => "leo_1",
      "target_id" => "target_a",
      "source_window_id" => "window:leo_1:target_visibility:target_a:old",
      "starts_at_s" => 90.0,
      "ends_at_s" => 150.0,
      "replacement_candidate_id" => "refresh_observe",
      "invalidated_reason" => "replaced_by_semantically_similar_candidate",
      "semantic_change_reasons" => ["starts_at_s_changed", "source_window_id_changed"]
    }

    package = OperatorReview.from_invalidated_candidate(candidate)
    assert OrbitalDynamics.operator_review_package(candidate) == package

    assert %{
             "source_artifact_type" => "invalidated_candidate.v1",
             "source_artifact_id" => "old_refresh_observe",
             "review_count" => 1,
             "candidate_diff_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_diff_review",
                 "source" => "invalidated_candidate",
                 "activity_id" => "old_refresh_observe",
                 "target_id" => "target_a",
                 "required_operator_action" => "review_candidate_diff",
                 "replacement_candidate_id" => "refresh_observe",
                 "source_candidate_diff" => %{"schema_contract" => "invalidated_candidate.v1"}
               }
             ]
           } = package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds candidate rejection review package from reviewable rejected candidates" do
    report =
      OrbitalDynamics.candidate_rejection_report(
        [
          %{
            id: :dl_reserved,
            type: :downlink,
            timeline_id: :candidate_timeline,
            ground_station_id: :dss_14,
            station_availability: "Reservation Hold",
            starts_at_s: 30.0,
            ends_at_s: 35.0,
            min_duration_s: 10.0,
            violated_constraint: :station_calendar,
            required_margin: 10.0,
            actual_margin: 5.0
          },
          %{id: :cmd_ready, type: :command, reviewable: false},
          %{
            id: :obs_blocked_by_policy,
            type: :observe,
            rejection_reasons: [:policy_blocked],
            reviewable: false
          }
        ],
        source: :candidate_refresh
      )

    package = OperatorReview.from_candidate_rejection_report(report)
    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "candidate_rejection_report.v1",
             "source_artifact_id" => "candidate_refresh",
             "review_count" => 1,
             "candidate_rejection_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_rejection_review",
                 "source" => "candidate_rejection_report.rows",
                 "subject_id" => "dl_reserved",
                 "candidate_id" => "dl_reserved",
                 "activity_id" => "dl_reserved",
                 "timeline_id" => "candidate_timeline",
                 "activity_type" => "downlink",
                 "required_operator_action" => "review_candidate_rejection",
                 "approval_status" => "operator_review_required",
                 "candidate_rejection_status" => "rejected",
                 "primary_rejection_reason" => "contact_too_short",
                 "candidate_rejection_reason_count" => 2,
                 "violated_constraint" => "station_calendar",
                 "required_margin" => 10.0,
                 "actual_margin" => 5.0,
                 "activity_context" => %{"ground_station_id" => "dss_14"},
                 "source_candidate_rejection" => %{"candidate_id" => "dl_reserved"}
               }
             ]
           } = package

    [row] = package["rows"]
    assert "contact_too_short" in row["candidate_rejection_reasons"]
    assert "station_reserved" in row["candidate_rejection_reasons"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_candidate_rejection", "candidate_id"],
            "candidate rejection with spaces"
          )
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_candidate_rejection.candidate_id")
           )

    stale_source_evidence =
      put_in(
        package,
        ["rows", Access.at(0), "source_candidate_rejection", "primary_rejection_reason"],
        "station_reserved"
      )

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].primary_rejection_reason" and
                 &1["message"] ==
                   "must match source_candidate_rejection.primary_rejection_reason")
           )
  end

  test "builds standalone contact intent review package" do
    intent = %{
      "schema_contract" => "contact_intent.v1",
      "id" => "refresh_downlink",
      "activity_id" => "refresh_downlink",
      "activity_type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "starts_at_s" => 100.0,
      "ends_at_s" => 160.0,
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
      "cadence_import" => %{
        "external_id" => "refresh_downlink",
        "activity_type" => "contact",
        "schema_contract" => "proposed_contact.v1"
      },
      "approval_status" => "operator_review_required",
      "approval_requirements" => [
        %{
          "schema_contract" => "approval_requirement.v1",
          "id" => "approval:refresh_downlink",
          "activity_id" => "refresh_downlink",
          "activity_type" => "downlink",
          "action" => "review_contact_intent",
          "requirement_type" => "contact_schedule_change",
          "reason" => "contact intent requires schedule authority"
        }
      ],
      "approval_rule_matches" => [
        %{
          "rule_id" => "downlink_schedule_authority_review"
        }
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "policy_bundle_id" => "command_contact_authority_v1",
        "classification" => "operator_review_required",
        "escalations" => [
          %{
            "rule_id" => "downlink_schedule_authority_review",
            "required_authority" => "contact_schedule_authority"
          }
        ]
      }
    }

    package = OperatorReview.from_contact_intent(intent)
    assert OrbitalDynamics.operator_review_package(intent) == package

    assert %{
             "source_artifact_type" => "contact_intent.v1",
             "source_artifact_id" => "refresh_downlink",
             "review_count" => 1,
             "contact_intent_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "contact_intent_review",
                 "source" => "contact_intent",
                 "activity_id" => "refresh_downlink",
                 "required_operator_action" => "review_contact_intent",
                 "cadence_import_status" => "present",
                 "cadence_import_type" => "contact",
                 "cadence_import_id" => "refresh_downlink",
                 "cadence_import_contract" => "proposed_contact.v1",
                 "requirement_type" => "contact_schedule_change",
                 "required_authority" => "contact_schedule_authority",
                 "policy_bundle_id" => "command_contact_authority_v1",
                 "rule_id" => "downlink_schedule_authority_review",
                 "source_contact_intent" => %{"schema_contract" => "contact_intent.v1"}
               }
             ]
           } = package

    assert %{"review_count" => 0, "rows" => []} =
             OperatorReview.from_contact_intent(%{
               intent
               | "approval_status" => "auto_approvable",
                 "approval_requirements" => [],
                 "approval_rule_matches" => [],
                 "policy_decision" => nil
             })

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(row, ["source_contact_intent", "source_window_id"], "source window with spaces")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_contact_intent.source_window_id")
           )

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> Map.put("source_window_id", "stale_source_window")
          |> Map.put("starts_at_s", 101.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_window_id" and
                 &1["message"] == "must match source_contact_intent.source_window_id")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].starts_at_s" and
                 &1["message"] == "must match source_contact_intent.starts_at_s")
           )
  end

  test "builds standalone planned activity review package" do
    activity = %{
      "schema_contract" => "planned_activity.v1",
      "id" => "cmd_repoint",
      "type" => "command",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "command",
      "starts_at_s" => 180.0,
      "ends_at_s" => 200.0,
      "source_window_id" => "window:leo_1:command:equator_prime:1",
      "cadence_import" => %{
        "external_id" => "cadence_cmd_repoint",
        "activity_type" => "command",
        "schema_contract" => "planned_activity.v1"
      }
    }

    package = OperatorReview.from_planned_activity(activity)
    assert OrbitalDynamics.operator_review_package(activity) == package

    alias_package =
      activity
      |> Map.delete("type")
      |> Map.put("activity_type", "command")
      |> OperatorReview.from_planned_activity()

    assert [
             %{
               "activity_id" => "cmd_repoint",
               "activity_type" => "command",
               "required_operator_action" => "review_command_contact"
             }
           ] = alias_package["rows"]

    assert %{
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "cmd_repoint",
             "review_count" => 1,
             "operational_timeline_count" => 1,
             "rows" => [
               %{
                 "review_type" => "operational_timeline_review",
                 "source" => "planned_activity",
                 "activity_id" => "cmd_repoint",
                 "required_operator_action" => "review_command_contact",
                 "cadence_import_status" => "present",
                 "cadence_import_type" => "command",
                 "cadence_import_id" => "cadence_cmd_repoint",
                 "cadence_import_contract" => "planned_activity.v1",
                 "source_operational_timeline" => %{"activity_id" => "cmd_repoint"}
               }
             ]
           } = package

    assert %{"review_count" => 0, "rows" => []} =
             OperatorReview.from_planned_activity(%{
               "schema_contract" => "planned_activity.v1",
               "id" => "observe_target",
               "type" => "observe",
               "scenario_id" => "leo_1",
               "target_id" => "target_a",
               "starts_at_s" => 210.0,
               "ends_at_s" => 240.0,
               "approval_status" => "approved"
             })

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(row, ["source_operational_timeline", "activity_id"], "activity id with spaces")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_timeline.activity_id")
           )
  end

  test "builds standalone realized activity review package" do
    activity = %{
      "schema_contract" => "realized_activity.v1",
      "id" => "downlink_equator",
      "planned_activity_id" => "downlink_equator",
      "timeline_id" => "timeline:downlink:equator_prime:access:leo_1:equator_prime:1",
      "status" => "partial",
      "actual_starts_at_s" => 102.0,
      "actual_ends_at_s" => 150.0,
      "completed_fraction" => 0.6,
      "reason" => "provider reported reduced throughput",
      "type" => "downlink",
      "direction" => "downlink",
      "ground_station_id" => "equator_prime",
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
      "actual_throughput_mb" => 72.0,
      "contact_success" => false,
      "provider" => "cadence",
      "source_quality" => "operator_verified",
      "adapter" => "cadence_feedback_adapter",
      "external_id" => "provider_feedback_1",
      "provenance" => %{"trust_boundary" => "operator_supplied"}
    }

    package = OperatorReview.from_realized_activity(activity)
    assert OrbitalDynamics.operator_review_package(activity) == package

    alias_package =
      activity
      |> Map.delete("type")
      |> Map.put("activity_type", "downlink")
      |> OperatorReview.from_realized_activity()

    assert [
             %{
               "activity_id" => "downlink_equator",
               "activity_type" => "downlink",
               "realized_activity_context" => %{"activity_type" => "downlink"}
             }
           ] = alias_package["rows"]

    assert %{
             "source_artifact_type" => "realized_activity.v1",
             "source_artifact_id" => "downlink_equator",
             "review_count" => 1,
             "realized_feedback_count" => 1,
             "rows" => [
               %{
                 "review_type" => "realized_feedback",
                 "source" => "realized_activity",
                 "activity_id" => "downlink_equator",
                 "feedback_status" => "realized_only",
                 "realized_status" => "partial",
                 "realized_source_quality" => "operator_verified",
                 "required_operator_action" => "review_unplanned_realization",
                 "approval_status" => "operator_review_required",
                 "realized_activity" => %{"schema_contract" => "realized_activity.v1"},
                 "realized_activity_context" => %{
                   "provider" => "cadence",
                   "source_quality" => "operator_verified",
                   "adapter" => "cadence_feedback_adapter",
                   "external_id" => "provider_feedback_1"
                 }
               }
             ]
           } = package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "realized feedback review rows reject stale source feedback evidence" do
    activity = %{
      "schema_contract" => "realized_activity.v1",
      "id" => "downlink_equator",
      "status" => "matched",
      "realized_status" => "failed",
      "type" => "downlink",
      "direction" => "downlink",
      "ground_station_id" => "equator_prime",
      "provider" => "cadence",
      "source_quality" => "operator_verified",
      "adapter" => "cadence_feedback_adapter",
      "external_id" => "provider_feedback_1",
      "provenance" => %{"trust_boundary" => "operator_supplied"}
    }

    package =
      activity
      |> OperatorReview.from_realized_activity()
      |> put_in(["rows", Access.at(0), "source_feedback", "realized_status"], "completed")

    assert {:error, report} = Schema.validate_artifact(package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].realized_status" and
                 &1["message"] == "must match source_feedback.realized_status")
           )
  end

  test "builds realized state snapshot review package from activity rows" do
    snapshot = read_json!("study_results/realized_state_snapshot_v1.json")

    package = OperatorReview.from_realized_state_snapshot(snapshot)
    assert OrbitalDynamics.operator_review_package(snapshot) == package

    assert %{
             "source_artifact_type" => "realized_state_snapshot.v1",
             "source_artifact_id" => "realized-state-demo-2026-05-14T00:00:00Z",
             "review_count" => 2,
             "realized_feedback_count" => 2,
             "review_type_counts" => %{"realized_feedback" => 2}
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "realized_state_snapshot.activities",
             "realized_state_snapshot.activities"
           ]

    assert Enum.map(package["rows"], & &1["activity_id"]) == [
             "cmd_repoint",
             "downlink_equator"
           ]

    assert Enum.all?(
             package["rows"],
             &match?(
               %{
                 "review_type" => "realized_feedback",
                 "feedback_status" => "realized_only",
                 "required_operator_action" => "review_unplanned_realization"
               },
               &1
             )
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

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
             &(&1["path"] == "$.contention_recommendation_count")
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

  test "builds review package from contact contention report groups" do
    report = %{
      "schema_contract" => "contact_contention_report.v1",
      "model" => "single_station_interval_overlap",
      "input_contact_count" => 2,
      "conflicted_contact_count" => 2,
      "conflict_group_count" => 1,
      "conflict_groups" => [
        %{
          "id" => "station:equator_prime:contention:1",
          "ground_station_id" => "equator_prime",
          "contact_count" => 2,
          "starts_at_s" => 100.0,
          "ends_at_s" => 220.0,
          "direction" => "downlink",
          "required_operator_action" => "review_contact_contention",
          "approval_status" => "operator_review_required",
          "operator_action_reason" => "same_station_overlapping_contact_windows",
          "approval_requirements" => [
            %{
              "activity_id" => "station:equator_prime:contention:1",
              "activity_type" => "contact_contention",
              "action" => "review_contact_contention",
              "requirement_type" => "contact_schedule_change",
              "policy_classification" => "operator_review_required"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "contact_schedule_review",
              "classification" => "operator_review_required",
              "requirement_type" => "contact_schedule_change"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "contact_command_review_v1",
            "rule_matches" => [
              %{
                "rule_id" => "contact_schedule_review",
                "classification" => "operator_review_required"
              }
            ],
            "escalations" => [
              %{
                "rule_id" => "unmatched_contention_rule",
                "escalation_queue" => "ignore_queue"
              },
              %{
                "rule_id" => "contact_schedule_review",
                "required_authority" => "contact_schedule_authority",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "ground_network",
                "escalation_role" => "network_scheduler",
                "sla_s" => 600
              }
            ],
            "approval_requirement_count" => 1,
            "risk_count" => 0
          },
          "contact_ids" => ["dl_1", "dl_2"],
          "source_window_ids" => [
            "window:leo_1:ground_station_access:equator_prime:1",
            "window:leo_2:ground_station_access:equator_prime:1"
          ],
          "scenario_ids" => ["leo_1", "leo_2"]
        }
      ],
      "assumptions" => %{"resolution" => "report_only_no_candidate_suppression"}
    }

    package = OperatorReview.from_contact_contention_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "contact_contention_report.v1",
             "source_artifact_id" => "contact_contention_report",
             "review_count" => 1,
             "contention_review_count" => 1
           } = package

    assert %{
             "review_type" => "contact_contention_review",
             "subject_id" => "station:equator_prime:contention:1",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "contact_count" => 2,
             "contact_ids" => ["dl_1", "dl_2"],
             "source_window_ids" => [
               "window:leo_1:ground_station_access:equator_prime:1",
               "window:leo_2:ground_station_access:equator_prime:1"
             ],
             "scenario_ids" => ["leo_1", "leo_2"],
             "required_operator_action" => "review_contact_contention",
             "approval_status" => "operator_review_required",
             "operator_action_reason" => "same_station_overlapping_contact_windows",
             "reason" => "review 2 overlapping contacts at equator_prime",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "contact_command_review_v1",
             "rule_id" => "contact_schedule_review",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "network_scheduler",
             "sla_s" => 600,
             "approval_rule_matches" => [
               %{"rule_id" => "contact_schedule_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "contact_command_review_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "contact_schedule_review",
               "escalation_queue" => "ground_network"
             },
             "source_contention_group" => %{"contact_ids" => ["dl_1", "dl_2"]}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "ground_station_id", "stale_station")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ground_station_id" and
                 &1["message"] == "must match source_contention_group.ground_station_id")
           )
  end

  test "validates contact contention invalid input source handoff rows" do
    report = %{
      "schema_contract" => "contact_contention_report.v1",
      "model" => "single_station_interval_overlap",
      "input_contact_count" => 1,
      "conflicted_contact_count" => 0,
      "conflict_group_count" => 0,
      "conflict_groups" => [],
      "invalid_contact_input_count" => 1,
      "invalid_contact_input_ids" => ["malformed_contact"],
      "invalid_contact_inputs" => [
        %{
          "id" => "invalid_contact:malformed_contact",
          "contact_id" => "malformed_contact",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 180.0,
          "direction" => "downlink",
          "required_operator_action" => "review_invalid_contact_contention_input",
          "approval_status" => "operator_review_required",
          "operator_action_reason" => "invalid_contact_shape",
          "invalid_contact_input" => true,
          "invalid_contact_input_reason" => "invalid_contact_shape"
        }
      ]
    }

    package = OperatorReview.from_contact_contention_report(report)

    assert %{
             "review_type" => "contact_contention_review",
             "subject_id" => "invalid_contact:malformed_contact",
             "contact_id" => "malformed_contact",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_invalid_contact_input" => %{
               "ground_station_id" => "equator_prime",
               "invalid_contact_input_reason" => "invalid_contact_shape"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "invalid_contact_input_reason", "stale_reason")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].invalid_contact_input_reason" and
                 &1["message"] ==
                   "must match source_invalid_contact_input.invalid_contact_input_reason")
           )
  end

  test "builds review package from standalone contact contention resolution report" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "model" => "deterministic_contact_contention_recommendation",
      "policy" => %{
        "selection_rule" => "highest_score_earliest_start",
        "tie_breakers" => ["starts_at_s", "id"],
        "action" => "recommend_preferred_contact_for_operator_review"
      },
      "conflict_group_count" => 1,
      "recommendation_count" => 1,
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 220.0,
          "selected_contact_id" => "dl_1",
          "deferred_contact_ids" => ["dl_2"],
          "candidate_count" => 2,
          "selection_reason" => "highest_score_earliest_start",
          "action" => "recommend_preferred_contact_for_operator_review",
          "review_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "activity_id" => "station:equator_prime:contention:1",
              "activity_type" => "contact_contention_resolution",
              "action" => "recommend_preferred_contact_for_operator_review",
              "requirement_type" => "contact_schedule_change",
              "policy_classification" => "operator_review_required"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "contact_schedule_review",
              "classification" => "operator_review_required",
              "requirement_type" => "contact_schedule_change"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "contact_command_review_v1",
            "rule_matches" => [
              %{
                "rule_id" => "contact_schedule_review",
                "classification" => "operator_review_required"
              }
            ],
            "escalations" => [
              %{
                "rule_id" => "unmatched_contention_rule",
                "escalation_queue" => "ignore_queue"
              },
              %{
                "rule_id" => "contact_schedule_review",
                "required_authority" => "contact_schedule_authority",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "ground_network",
                "escalation_role" => "network_scheduler",
                "sla_s" => 600
              }
            ],
            "approval_requirement_count" => 1,
            "risk_count" => 0
          }
        }
      ],
      "assumptions" => %{"boundary" => "recommendation_only_no_station_reservation"}
    }

    package = OperatorReview.from_contact_contention_resolution_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "contact_contention_resolution_report.v1",
             "source_artifact_id" => "contact_contention_resolution_report",
             "review_count" => 1,
             "contention_recommendation_count" => 1
           } = package

    assert %{
             "review_type" => "contact_contention_recommendation",
             "source" => "contact_contention_resolution_report.recommendations",
             "subject_id" => "station:equator_prime:contention:1",
             "selected_contact_id" => "dl_1",
             "deferred_contact_ids" => ["dl_2"],
             "required_operator_action" => "recommend_preferred_contact_for_operator_review",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "contact_command_review_v1",
             "rule_id" => "contact_schedule_review",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "network_scheduler",
             "sla_s" => 600,
             "approval_rule_matches" => [
               %{"rule_id" => "contact_schedule_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "contact_command_review_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "contact_schedule_review",
               "escalation_queue" => "ground_network"
             },
             "source_recommendation" => %{"selected_contact_id" => "dl_1"}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_recommendation", "selected_contact_id"],
            "selected contact with spaces"
          )
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_recommendation.selected_contact_id")
           )

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "selected_contact_id", "stale_contact")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].selected_contact_id" and
                 &1["message"] == "must match source_recommendation.selected_contact_id")
           )
  end

  test "builds review package from standalone branch comparison report rows" do
    report = %{
      "schema_contract" => "branch_comparison_report.v1",
      "model" => "deterministic_strategy_branch_score_comparison",
      "source" => "campaign_strategy.branches",
      "branch_count" => 2,
      "recommended_branch_id" => "urgent",
      "rows" => [
        %{
          "id" => "branch_comparison:urgent",
          "rank" => 1,
          "branch_id" => "urgent",
          "score" => 80.0,
          "score_delta_from_recommended" => 0.0,
          "selected" => true,
          "approval_status" => "operator_review_required",
          "risk_count" => 1,
          "risk_types" => [
            "activity_type_suppressed_by_resource_summary",
            "activity_type_incompatible_with_resource_summary"
          ],
          "high_risk_types" => ["activity_type_incompatible_with_resource_summary"],
          "approval_requirement_count" => 1,
          "repair_delta_count" => 0,
          "score_terms" => %{"expected_score" => 80.0},
          "repair_score" => 70.0,
          "repair_activity_score" => 90.0,
          "repair_schedule_churn_penalty" => -20.0,
          "repair_schedule_move_penalty" => 0.0,
          "repair_score_term_keys" => [
            "activity_score",
            "schedule_churn_penalty",
            "schedule_move_penalty"
          ],
          "repair_link_selected_estimated_throughput_mb" => 120.0,
          "repair_link_selected_capacity_adjusted_throughput_mb" => 80.0,
          "repair_link_required_downlink_mb" => 100.0,
          "repair_link_selected_downlink_shortfall_mb" => 20.0,
          "repair_link_downlink_requirement_status" => "shortfall",
          "repair_link_actual_throughput_mb" => 65.0,
          "repair_link_actual_downlink_completion_ratio" => 0.65,
          "repair_link_actual_downlink_shortfall_mb" => 35.0,
          "repair_link_actual_downlink_requirement_status" => "shortfall",
          "repair_constraint_count" => 2,
          "repair_constraint_row_count" => 3,
          "repair_constraint_status" => "fail",
          "repair_constraint_pass_count" => 1,
          "repair_constraint_warning_count" => 1,
          "repair_constraint_fail_count" => 1,
          "repair_constraint_failed_ids" => ["campaign:max_timeline_activities"],
          "repair_constraint_warning_ids" => ["campaign:avoid_eclipse"],
          "contact_success_factor" => 0.4,
          "contact_success_factor_source" => "operational_feedback.contact_success_rate",
          "observation_success_factor" => 0.6,
          "observation_success_factor_source" => "operational_feedback.observation_success_rate",
          "maneuver_success_factor" => 0.8,
          "maneuver_success_factor_source" => "operational_feedback.maneuver_success_rate",
          "command_success_factor" => 0.5,
          "command_success_factor_source" => "operational_feedback.command_success_rate",
          "station_throughput_factor" => 0.75,
          "station_throughput_factor_source" => "operational_feedback.station_throughput_factor",
          "branch_scenario_ids" => ["leo_1"],
          "branch_target_ids" => ["target_hot"],
          "branch_collection_ids" => ["collection_hot"],
          "branch_product_ids" => ["product_hot"],
          "branch_payload_ids" => ["payload_hot"],
          "branch_instrument_ids" => ["instrument_hot"],
          "branch_objective_ids" => ["objective:latency_hot"],
          "branch_objective_types" => ["collection_latency"],
          "branch_feedback_sources" => ["prior_plan.source_objective_satisfaction_report"],
          "branch_feedback_scopes" => ["objective_satisfaction"],
          "branch_source_activity_ids" => ["obs_hot"],
          "branch_max_latency_s" => 180.0,
          "branch_planned_latency_s" => 420.0,
          "branch_required_downlink_mb" => 30.0,
          "branch_planned_downlink_mb" => 0.0,
          "branch_actual_downlink_completion_ratio" => 0.65,
          "capacity_pack_group_ids" => ["station:equator_prime:pack:review"],
          "capacity_pack_statuses" => ["deferred_by_reduced_station_capacity_pack"],
          "capacity_pack_min_capacity_fraction" => 0.5,
          "capacity_pack_max_used_fraction" => 0.5,
          "capacity_pack_max_required_capacity_fraction" => 0.25,
          "capacity_pack_total_required_capacity_fraction" => 0.25,
          "capacity_pack_required_capacity_sources" => ["contact_required_capacity_fraction"],
          "resource_pressure_statuses" => ["downlink_shortfall"],
          "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
          "first_resource_pressure_kinds" => ["downlink_shortfall"],
          "first_resource_pressure_activity_id" => "urgent_downlink",
          "first_resource_pressure_activity_type" => "downlink",
          "first_resource_pressure_kind" => "downlink_shortfall",
          "first_resource_pressure_starts_at_s" => 600.0,
          "first_resource_pressure_direction" => "downlink",
          "first_resource_pressure_ground_station_id" => "equator_prime",
          "first_resource_pressure_station_calendar_entry_id" => "station_calendar_entry_1",
          "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
          "first_resource_pressure_station_calendar_provider_entry_id" => "ops_calendar_window_1",
          "first_resource_pressure_station_calendar_directions" => ["downlink"],
          "first_resource_pressure_source_window_id" =>
            "window:leo_1:ground_station_access:equator_prime:1",
          "first_resource_pressure_source_window_type" => "ground_station_access",
          "first_resource_pressure_source_window" => %{
            "id" => "window:leo_1:ground_station_access:equator_prime:1",
            "type" => "ground_station_access",
            "ground_station_id" => "equator_prime"
          }
        },
        %{
          "id" => "branch_comparison:baseline",
          "rank" => 2,
          "branch_id" => "baseline",
          "score" => 50.0,
          "score_delta_from_recommended" => -30.0,
          "selected" => false,
          "approval_status" => "auto_approvable",
          "risk_count" => 0,
          "approval_requirement_count" => 0,
          "repair_delta_count" => 0,
          "score_terms" => %{"expected_score" => 50.0}
        }
      ],
      "assumptions" => %{"score_delta_from_recommended" => "row_minus_recommended"}
    }

    package = OperatorReview.from_branch_comparison_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "branch_comparison_report.v1",
             "source_artifact_id" => "campaign_strategy.branches",
             "review_count" => 2,
             "tradeoff_count" => 2
           } = package

    first_row = List.first(package["rows"])

    assert %{
             "review_type" => "strategy_tradeoff",
             "source" => "branch_comparison_report.rows",
             "subject_id" => "urgent",
             "branch_id" => "urgent",
             "required_operator_action" => "review_branch_comparison",
             "dimension" => "branch_score",
             "baseline" => 80.0,
             "recommended" => 80.0,
             "risk_count" => 1,
             "risk_types" => [
               "activity_type_suppressed_by_resource_summary",
               "activity_type_incompatible_with_resource_summary"
             ],
             "high_risk_types" => ["activity_type_incompatible_with_resource_summary"],
             "repair_score" => 70.0,
             "repair_activity_score" => 90.0,
             "repair_schedule_churn_penalty" => -20.0,
             "repair_score_term_keys" => [
               "activity_score",
               "schedule_churn_penalty",
               "schedule_move_penalty"
             ],
             "repair_link_selected_capacity_adjusted_throughput_mb" => 80.0,
             "repair_link_required_downlink_mb" => 100.0,
             "repair_link_selected_downlink_shortfall_mb" => 20.0,
             "repair_link_downlink_requirement_status" => "shortfall",
             "repair_link_actual_throughput_mb" => 65.0,
             "repair_link_actual_downlink_completion_ratio" => 0.65,
             "repair_link_actual_downlink_shortfall_mb" => 35.0,
             "repair_link_actual_downlink_requirement_status" => "shortfall",
             "repair_constraint_count" => 2,
             "repair_constraint_row_count" => 3,
             "repair_constraint_status" => "fail",
             "repair_constraint_warning_count" => 1,
             "repair_constraint_fail_count" => 1,
             "repair_constraint_failed_ids" => ["campaign:max_timeline_activities"],
             "repair_constraint_warning_ids" => ["campaign:avoid_eclipse"],
             "contact_success_factor_source" => "operational_feedback.contact_success_rate",
             "observation_success_factor_source" =>
               "operational_feedback.observation_success_rate",
             "maneuver_success_factor_source" => "operational_feedback.maneuver_success_rate",
             "command_success_factor_source" => "operational_feedback.command_success_rate",
             "station_throughput_factor_source" =>
               "operational_feedback.station_throughput_factor",
             "branch_target_ids" => ["target_hot"],
             "branch_collection_ids" => ["collection_hot"],
             "branch_product_ids" => ["product_hot"],
             "branch_payload_ids" => ["payload_hot"],
             "branch_instrument_ids" => ["instrument_hot"],
             "branch_objective_ids" => ["objective:latency_hot"],
             "branch_objective_types" => ["collection_latency"],
             "branch_feedback_sources" => ["prior_plan.source_objective_satisfaction_report"],
             "branch_feedback_scopes" => ["objective_satisfaction"],
             "branch_source_activity_ids" => ["obs_hot"],
             "branch_max_latency_s" => 180.0,
             "branch_planned_latency_s" => 420.0,
             "branch_required_downlink_mb" => 30.0,
             "branch_actual_downlink_completion_ratio" => 0.65,
             "capacity_pack_group_ids" => ["station:equator_prime:pack:review"],
             "capacity_pack_statuses" => ["deferred_by_reduced_station_capacity_pack"],
             "capacity_pack_min_capacity_fraction" => 0.5,
             "capacity_pack_max_used_fraction" => 0.5,
             "capacity_pack_max_required_capacity_fraction" => 0.25,
             "capacity_pack_total_required_capacity_fraction" => 0.25,
             "capacity_pack_required_capacity_sources" => ["contact_required_capacity_fraction"],
             "resource_pressure_statuses" => ["downlink_shortfall"],
             "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
             "first_resource_pressure_kinds" => ["downlink_shortfall"],
             "first_resource_pressure_activity_id" => "urgent_downlink",
             "first_resource_pressure_activity_type" => "downlink",
             "first_resource_pressure_kind" => "downlink_shortfall",
             "first_resource_pressure_starts_at_s" => 600.0,
             "first_resource_pressure_direction" => "downlink",
             "first_resource_pressure_ground_station_id" => "equator_prime",
             "first_resource_pressure_station_calendar_entry_id" => "station_calendar_entry_1",
             "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
             "first_resource_pressure_station_calendar_provider_entry_id" =>
               "ops_calendar_window_1",
             "first_resource_pressure_station_calendar_directions" => ["downlink"],
             "first_resource_pressure_source_window_id" =>
               "window:leo_1:ground_station_access:equator_prime:1",
             "first_resource_pressure_source_window_type" => "ground_station_access",
             "first_resource_pressure_source_window" => %{
               "id" => "window:leo_1:ground_station_access:equator_prime:1",
               "type" => "ground_station_access",
               "ground_station_id" => "equator_prime"
             },
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
             "source_branch_comparison" => %{
               "branch_id" => "urgent",
               "branch_collection_ids" => ["collection_hot"],
               "branch_actual_downlink_completion_ratio" => 0.65,
               "capacity_pack_max_required_capacity_fraction" => 0.25,
               "capacity_pack_total_required_capacity_fraction" => 0.25,
               "capacity_pack_required_capacity_sources" => ["contact_required_capacity_fraction"],
               "repair_link_actual_downlink_completion_ratio" => 0.65,
               "first_resource_pressure_activity_id" => "urgent_downlink",
               "first_resource_pressure_ground_station_id" => "equator_prime",
               "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
               "first_resource_pressure_station_calendar_provider_entry_id" =>
                 "ops_calendar_window_1",
               "first_resource_pressure_source_window_id" =>
                 "window:leo_1:ground_station_access:equator_prime:1"
             }
           } = first_row

    assert first_row["delta"] == 0.0
    assert first_row["branch_planned_downlink_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"branch_id" => "urgent", "source_branch_comparison" => %{}} = row ->
            put_in(row, ["source_branch_comparison", "risk_count"], 2)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.risk_count$/ and
                 &1["message"] == "must match source_branch_comparison.risk_count")
           )
  end

  test "builds review package from standalone ranking comparison report rows" do
    report = %{
      "schema_contract" => "ranking_comparison_report.v1",
      "model" => "deterministic_pairwise_ranked_scenario_comparison",
      "source" => "optimizer.compare_rankings",
      "objective" => "expected_score",
      "objective_direction" => "maximize",
      "left_label" => "baseline",
      "right_label" => "repair",
      "left_count" => 2,
      "right_count" => 2,
      "matched_count" => 2,
      "left_only_count" => 0,
      "right_only_count" => 0,
      "row_count" => 2,
      "winner_changed" => true,
      "winner" => %{
        "left_scenario_id" => "burn_a",
        "right_scenario_id" => "burn_b",
        "changed" => true
      },
      "rows" => [
        %{
          "scenario_id" => "burn_a",
          "status" => "matched",
          "left_rank" => 1,
          "right_rank" => 2,
          "rank_delta" => -1,
          "left_value" => 92.0,
          "right_value" => 89.0,
          "value_delta" => -3.0
        },
        %{
          "scenario_id" => "burn_b",
          "status" => "matched",
          "left_rank" => 2,
          "right_rank" => 1,
          "rank_delta" => 1,
          "left_value" => 84.0,
          "right_value" => 99.0,
          "value_delta" => 15.0
        }
      ],
      "assumptions" => %{"rank_delta" => "left_rank_minus_right_rank"}
    }

    package = OperatorReview.from_ranking_comparison_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "ranking_comparison_report.v1",
             "source_artifact_id" => "optimizer.compare_rankings",
             "review_count" => 2,
             "ranking_comparison_count" => 2,
             "tradeoff_count" => 0
           } = package

    row = Enum.find(package["rows"], &(&1["scenario_id"] == "burn_b"))

    assert %{
             "review_type" => "ranking_comparison_review",
             "source" => "ranking_comparison_report.rows",
             "subject_id" => "burn_b",
             "scenario_id" => "burn_b",
             "required_operator_action" => "review_ranking_comparison",
             "approval_status" => "operator_review_required",
             "status" => "matched",
             "left_rank" => 2,
             "right_rank" => 1,
             "rank_delta" => 1,
             "left_value" => 84.0,
             "right_value" => 99.0,
             "value_delta" => 15.0,
             "source_ranking_comparison" => %{"scenario_id" => "burn_b"}
           } = row

    assert row["reason"] ==
             "review ranking comparison for burn_b: matched, rank delta 1, value delta 15.0"

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"scenario_id" => "burn_b", "source_ranking_comparison" => %{}} = row ->
            put_in(row, ["source_ranking_comparison", "value_delta"], 12.0)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.value_delta$/ and
                 &1["message"] == "must match source_ranking_comparison.value_delta")
           )
  end

  test "builds review package from standalone Pareto frontier report rows" do
    report = %{
      "schema_contract" => "pareto_frontier_report.v1",
      "model" => "objective_vector_pareto_frontier",
      "source" => "campaign_strategy.branch_comparison_report",
      "alternative_count" => 2,
      "objective_count" => 2,
      "frontier_count" => 1,
      "dominated_count" => 1,
      "frontier_ids" => ["baseline"],
      "dominated_ids" => ["risky"],
      "objective_directions" => %{"score" => "maximize", "risk_count" => "minimize"},
      "rows" => [
        %{
          "id" => "baseline",
          "scenario_id" => "baseline",
          "objective_values" => %{"score" => 95.0, "risk_count" => 0},
          "objective_keys" => ["risk_count", "score"],
          "frontier" => true,
          "dominated_by_ids" => [],
          "dominates_ids" => ["risky"]
        },
        %{
          "id" => "risky",
          "scenario_id" => "risky",
          "objective_values" => %{"score" => 80.0, "risk_count" => 1},
          "objective_keys" => ["risk_count", "score"],
          "frontier" => false,
          "dominated_by_ids" => ["baseline"],
          "dominates_ids" => []
        }
      ],
      "assumptions" => %{"external_solver" => false}
    }

    package = OperatorReview.from_pareto_frontier_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "pareto_frontier_report.v1",
             "source_artifact_id" => "campaign_strategy.branch_comparison_report",
             "review_count" => 2,
             "pareto_frontier_count" => 2
           } = package

    assert %{
             "review_type" => "pareto_frontier_review",
             "source" => "pareto_frontier_report.rows",
             "subject_id" => "risky",
             "scenario_id" => "risky",
             "branch_id" => "risky",
             "required_operator_action" => "review_pareto_frontier",
             "frontier" => false,
             "dominated_by_ids" => ["baseline"],
             "source_pareto_frontier" => %{"scenario_id" => "risky"}
           } = Enum.find(package["rows"], &(&1["scenario_id"] == "risky"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"scenario_id" => "risky", "source_pareto_frontier" => %{}} = row ->
            put_in(row, ["source_pareto_frontier", "dominated_by_ids"], [])

          row ->
            row
        end)
      end)

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.dominated_by_ids$/ and
                 &1["message"] == "must match source_pareto_frontier.dominated_by_ids")
           )
  end

  test "builds campaign review package from contact and resource filter suppressions" do
    artifact = %{
      "schema_version" => 1,
      "plan_id" => "campaign_plan:resource_filter",
      "contact_contention_resolution_report" => %{"recommendations" => []},
      "contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "ground_station_availability_filter",
        "input_contact_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "leo_1_downlink_equator_prime_1",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "station_availability" => "unavailable",
            "suppressed_reason" => "ground_station_unavailable",
            "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
          }
        ]
      },
      "resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "leo_1_observe_target_a_1",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 60.0,
            "ends_at_s" => 180.0,
            "suppressed_reason" => "payload_unavailable",
            "resource_trust_boundary_status" => "missing",
            "source_window_id" => "window:leo_1:target_visibility:target_a:1"
          }
        ]
      },
      "warnings" => [],
      "provenance" => %{"source" => "campaign_test"}
    }

    package = OperatorReview.from_campaign_artifact(artifact)

    assert %{
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => "campaign_plan:resource_filter",
             "review_count" => 2,
             "contact_suppression_count" => 1,
             "resource_suppression_count" => 1
           } = package

    assert %{
             "review_type" => "contact_suppression",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "activity_type" => "downlink",
             "required_operator_action" => "review_suppressed_contact",
             "reason" => "contact filter suppressed candidate: ground_station_unavailable",
             "ground_station_id" => "equator_prime",
             "station_availability" => "unavailable",
             "source" => "campaign_plan.contact_filter_report.suppressed_candidates",
             "source_contact_suppression" => %{
               "suppressed_reason" => "ground_station_unavailable"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_suppression"))

    assert %{
             "review_type" => "resource_suppression",
             "activity_id" => "leo_1_observe_target_a_1",
             "activity_type" => "observe",
             "required_operator_action" => "review_suppressed_observation",
             "reason" => "resource filter suppressed candidate: payload_unavailable",
             "resource_trust_boundary_status" => "missing",
             "source_window_id" => "window:leo_1:target_visibility:target_a:1",
             "source_resource_suppression" => %{
               "suppressed_reason" => "payload_unavailable",
               "resource_trust_boundary_status" => "missing"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "resource_suppression"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "schema validation rejects stale duplicate suppression handoff rows" do
    report = %{
      "schema_contract" => "contact_filter_report.v1",
      "id" => "contact_filter:duplicate_handoff",
      "model" => "thin_ground_network_availability_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 2,
      "duplicate_suppressed_candidate_row_count" => 2,
      "duplicate_suppressed_candidate_id_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "dup_contact:1",
          "base_candidate_id" => "dup_contact",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "suppressed_reason" => "ground_station_unavailable",
          "duplicate_suppressed_candidate_id_collision" => true,
          "duplicate_suppressed_candidate_index" => 1,
          "duplicate_suppressed_candidate_count" => 2
        },
        %{
          "id" => "dup_contact:2",
          "base_candidate_id" => "dup_contact",
          "type" => "downlink",
          "scenario_id" => "leo_2",
          "suppressed_reason" => "ground_station_unavailable",
          "duplicate_suppressed_candidate_id_collision" => true,
          "duplicate_suppressed_candidate_index" => 2,
          "duplicate_suppressed_candidate_count" => 2
        }
      ]
    }

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report)

    package = OperatorReview.from_contact_filter_report(report)
    manifest = CadenceImport.from_contact_filter_report(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_package_count =
      update_in(package, ["rows", Access.at(0)], fn row ->
        Map.put(row, "duplicate_suppressed_candidate_count", 1)
      end)

    assert {:error, count_report} = Schema.validate_artifact(invalid_package_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.rows[0].duplicate_suppressed_candidate_count" and
                 &1["message"] == "must equal 2")
           )

    invalid_package_index =
      update_in(package, ["rows", Access.at(1)], fn row ->
        Map.put(row, "duplicate_suppressed_candidate_index", 1)
      end)

    assert {:error, index_report} = Schema.validate_artifact(invalid_package_index)

    assert Enum.any?(
             index_report["errors"],
             &(&1["path"] == "$.rows" and
                 String.starts_with?(
                   &1["message"],
                   "duplicate_suppressed_candidate_index values must cover 1..2"
                 ))
           )

    invalid_manifest =
      update_in(manifest, ["rows", Access.at(0)], fn row ->
        row
        |> Map.put("duplicate_suppressed_candidate_count", 1)
        |> put_in(["source_review_row", "duplicate_suppressed_candidate_count"], 1)
      end)

    assert {:error, manifest_report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             manifest_report["errors"],
             &(&1["path"] == "$.rows[0].duplicate_suppressed_candidate_count" and
                 &1["message"] == "must equal 2")
           )

    mismatched_source_review =
      update_in(manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        Map.put(row, "duplicate_suppressed_candidate_count", 1)
      end)

    assert {:error, mismatch_report} = Schema.validate_artifact(mismatched_source_review)

    assert Enum.any?(
             mismatch_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.duplicate_suppressed_candidate_count" and
                 &1["message"] ==
                   "must match duplicate_suppressed_candidate_count on Cadence import row")
           )
  end

  test "builds review package from standalone contact filter report suppressions" do
    report = %{
      "schema_contract" => "contact_filter_report.v1",
      "id" => "contact_filter:ground_network",
      "model" => "thin_ground_network_availability_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "leo_1_downlink_equator_prime_1",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "station_availability" => "unavailable",
          "station_contention_status" => "reserved_overlap",
          "station_reservation_id" => "reservation_1",
          "station_reserved_by" => "network_partner",
          "station_reservation_status" => "confirmed",
          "station_reservation_match_status" => "overlap",
          "approval_status" => "blocked_by_policy",
          "approval_requirements" => [
            %{
              "activity_id" => "leo_1_downlink_equator_prime_1",
              "activity_type" => "downlink",
              "action" => "review_suppressed_contact",
              "requirement_type" => "contact_schedule_change",
              "reason" => "ground_station_unavailable"
            }
          ],
          "approval_rule_matches" => [
            %{"rule_id" => "unavailable_station_contact_block"}
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "policy_bundle_id" => "ground_network_allocation_v1",
            "escalations" => [
              %{"rule_id" => "unmatched_contact_rule", "escalation_queue" => "ignore_queue"},
              %{
                "rule_id" => "unavailable_station_contact_block",
                "required_authority" => "contact_schedule_authority",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "ground_network",
                "escalation_role" => "network_scheduler",
                "sla_s" => 600
              }
            ]
          },
          "suppressed_reason" => "ground_station_unavailable",
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
        }
      ],
      "provenance" => %{"source" => "test"}
    }

    package = OperatorReview.from_contact_filter_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "contact_filter_report.v1",
             "source_artifact_id" => "contact_filter:ground_network",
             "review_count" => 1,
             "contact_suppression_count" => 1
           } = package

    assert %{
             "review_type" => "contact_suppression",
             "source" => "contact_filter_report.suppressed_candidates",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "required_operator_action" => "review_suppressed_contact",
             "approval_status" => "blocked_by_policy",
             "direction" => "downlink",
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "unavailable_station_contact_block",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "network_scheduler",
             "sla_s" => 600,
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_1",
             "station_reserved_by" => "network_partner",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "overlap",
             "approval_rule_matches" => [
               %{"rule_id" => "unavailable_station_contact_block"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "unavailable_station_contact_block",
               "escalation_queue" => "ground_network"
             },
             "source_contact_suppression" => %{
               "suppressed_reason" => "ground_station_unavailable"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    manifest = CadenceImport.from_operator_review_package(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert %{
             "source_review_type" => "contact_suppression",
             "station_reservation_id" => "reservation_1",
             "source_review_row" => %{
               "review_type" => "contact_suppression",
               "station_reservation_id" => "reservation_1"
             }
           } = List.first(manifest["rows"])

    invalid_source_review_manifest =
      update_in(manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        Map.put(row, "station_reservation_id", "stale_reservation")
      end)

    assert {:error, source_review_report} =
             Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.station_reservation_id" and
                 &1["message"] == "must match station_reservation_id on Cadence import row")
           )

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "station_reservation_id", "stale_reservation")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].station_reservation_id" and
                 &1["message"] ==
                   "must match source_contact_suppression.station_reservation_id")
           )
  end

  test "routes planned-contact downlink suppressions through contact review actions" do
    report = %{
      "schema_contract" => "contact_filter_report.v1",
      "id" => "contact_filter:planned_contacts",
      "model" => "thin_ground_network_availability_filter",
      "input_candidate_count" => 1,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "planned_downlink_1",
          "type" => "planned_contact",
          "direction" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "suppressed_reason" => "ground_station_unavailable"
        }
      ]
    }

    package = OperatorReview.from_contact_filter_report(report)

    assert [
             %{
               "review_type" => "contact_suppression",
               "activity_id" => "planned_downlink_1",
               "activity_type" => "planned_contact",
               "direction" => "downlink",
               "action" => "review_suppressed_contact",
               "required_operator_action" => "review_suppressed_contact"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from standalone resource filter report suppressions" do
    report = %{
      "schema_contract" => "resource_filter_report.v1",
      "id" => "resource_filter:mission_state",
      "model" => "resource_summary_availability_and_margin_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "leo_1_observe_target_a_1",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "sat_payload",
          "starts_at_s" => 60.0,
          "ends_at_s" => 180.0,
          "suppressed_reason" => "payload_unavailable",
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "payload_available" => false,
          "approval_status" => "blocked_by_policy",
          "approval_requirements" => [
            %{
              "activity_id" => "leo_1_observe_target_a_1",
              "activity_type" => "observe",
              "action" => "review_suppressed_observation",
              "requirement_type" => "observation_reassignment",
              "reason" => "payload_unavailable"
            }
          ],
          "approval_rule_matches" => [
            %{"rule_id" => "payload_unavailable_observation_block"}
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "policy_bundle_id" => "degraded_payload_guard_v1",
            "escalations" => [
              %{"rule_id" => "unmatched_resource_rule", "escalation_queue" => "ignore_queue"},
              %{
                "rule_id" => "payload_unavailable_observation_block",
                "required_authority" => "payload_operations_authority",
                "escalation_level" => "payload_lead",
                "escalation_queue" => "payload_ops",
                "escalation_role" => "payload_scheduler",
                "sla_s" => 900
              }
            ]
          }
        }
      ],
      "provenance" => %{"source" => "test"}
    }

    package = OperatorReview.from_resource_filter_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "resource_filter_report.v1",
             "source_artifact_id" => "resource_filter:mission_state",
             "review_count" => 1,
             "resource_suppression_count" => 1
           } = package

    assert %{
             "review_type" => "resource_suppression",
             "source" => "resource_filter_report.suppressed_candidates",
             "activity_id" => "leo_1_observe_target_a_1",
             "required_operator_action" => "review_suppressed_observation",
             "approval_status" => "blocked_by_policy",
             "spacecraft_id" => "sat_payload",
             "payload_available" => false,
             "requirement_type" => "observation_reassignment",
             "required_authority" => "payload_operations_authority",
             "policy_bundle_id" => "degraded_payload_guard_v1",
             "rule_id" => "payload_unavailable_observation_block",
             "escalation_level" => "payload_lead",
             "escalation_queue" => "payload_ops",
             "escalation_role" => "payload_scheduler",
             "sla_s" => 900,
             "approval_rule_matches" => [
               %{"rule_id" => "payload_unavailable_observation_block"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "degraded_payload_guard_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "payload_unavailable_observation_block",
               "escalation_queue" => "payload_ops"
             },
             "source_resource_suppression" => %{"suppressed_reason" => "payload_unavailable"}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "payload_available", true)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].payload_available" and
                 &1["message"] == "must match source_resource_suppression.payload_available")
           )
  end

  test "routes planned-contact downlink resource suppressions through contact review actions" do
    report = %{
      "schema_contract" => "resource_filter_report.v1",
      "id" => "resource_filter:planned_contacts",
      "model" => "resource_summary_availability_and_margin_filter",
      "input_candidate_count" => 1,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "planned_downlink_1",
          "type" => "planned_contact",
          "direction" => "downlink",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "sat_1",
          "ground_station_id" => "equator_prime",
          "suppressed_reason" => "antenna_unavailable",
          "antenna_available" => false
        }
      ]
    }

    package = OperatorReview.from_resource_filter_report(report)

    assert [
             %{
               "review_type" => "resource_suppression",
               "activity_id" => "planned_downlink_1",
               "activity_type" => "planned_contact",
               "direction" => "downlink",
               "action" => "review_suppressed_contact",
               "required_operator_action" => "review_suppressed_contact",
               "antenna_available" => false
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from standalone resource projection report rows" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "model" => "thin_campaign_selected_activity_resource_projection",
      "input_resource_summary_count" => 1,
      "activity_count" => 2,
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "activity_count" => 2,
          "effective_activity_count" => 2,
          "ignored_activity_count" => 0,
          "ignored_activity_ids" => [],
          "observation_count" => 1,
          "downlink_count" => 1,
          "estimated_storage_produced_mb" => 0.0,
          "estimated_downlink_mb" => 0.0,
          "storage_limited_downlinked_mb" => 0.0,
          "unused_downlink_capacity_mb" => 0.0,
          "starting_storage_used_mb" => 250.0,
          "projected_storage_used_mb" => 250.0,
          "storage_capacity_mb" => 1000.0,
          "starting_storage_margin" => 0.75,
          "projected_storage_margin" => 0.75,
          "downlink_capacity_mb" => 600.0,
          "starting_downlink_margin" => 0.65,
          "projected_downlink_margin" => 1.0,
          "activity_resource_flow" => [
            %{
              "activity_id" => "obs_1",
              "activity_type" => "observe",
              "starts_at_s" => 10.0,
              "storage_overflow_mb" => 12.0,
              "downlink_shortfall_mb" => 0.0,
              "battery_energy_consumed_wh" => 20.0,
              "battery_energy_generated_wh" => 0.0,
              "battery_energy_delta_wh" => 20.0,
              "battery_overuse_wh" => 4.0
            },
            %{
              "activity_id" => "dl_1",
              "activity_type" => "downlink",
              "starts_at_s" => 20.0,
              "storage_overflow_mb" => 0.0,
              "downlink_shortfall_mb" => 3.0,
              "unused_downlink_capacity_mb" => 8.0,
              "battery_energy_consumed_wh" => 3.0,
              "battery_energy_generated_wh" => 8.0,
              "battery_energy_delta_wh" => -5.0,
              "battery_overuse_wh" => 0.0
            }
          ],
          "fuel_margin" => 0.82,
          "power_margin" => 0.74,
          "resource_source_quality" => "operator_supplied",
          "resource_trust_boundary_status" => "declared",
          "payload_available" => true,
          "antenna_available" => true,
          "approval_requirements" => [
            %{
              "schema_contract" => "approval_requirement.v1",
              "id" => "approval:resource_projection:leo_1:storage_overflow",
              "activity_id" => "resource_projection:leo_1",
              "activity_type" => "resource_projection",
              "action" => "review_resource_projection",
              "requirement_type" => "operator_review",
              "reason" => "storage_overflow 12.0 MB for leo_1",
              "activity_context" => %{
                "spacecraft_id" => "leo_1",
                "risk_type" => "storage_overflow"
              }
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "resource_pressure_block",
              "classification" => "blocked_by_policy",
              "risk_type" => "storage_overflow"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "blocked_by_policy",
            "policy_bundle_id" => "resource_projection_authority_v1",
            "approval_requirement_count" => 1,
            "risk_count" => 1,
            "rule_matches" => [],
            "escalations" => [
              %{
                "rule_id" => "unmatched_resource_rule",
                "escalation_queue" => "ignore_queue"
              },
              %{
                "rule_id" => "resource_pressure_block",
                "required_authority" => "resource_authority",
                "escalation_level" => "mission_planner",
                "escalation_queue" => "resource_planning",
                "escalation_role" => "resource_planner",
                "sla_s" => 1200
              }
            ]
          },
          "warnings" => []
        }
      ],
      "assumptions" => %{"source" => "campaign.resource_summaries"}
    }

    package = OperatorReview.from_resource_projection_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "campaign.resource_summaries",
             "review_count" => 1,
             "resource_projection_review_count" => 1
           } = package

    first_row = List.first(package["rows"])

    assert %{
             "review_type" => "resource_projection_review",
             "source" => "resource_projection_report.projected_resources",
             "subject_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "required_operator_action" => "review_resource_projection",
             "activity_count" => 2,
             "effective_activity_count" => 2,
             "ignored_activity_count" => 0,
             "ignored_activity_ids" => [],
             "observation_count" => 1,
             "downlink_count" => 1,
             "projected_storage_margin" => 0.75,
             "projected_downlink_margin" => 1.0,
             "resource_flow_count" => 2,
             "total_battery_energy_consumed_wh" => 23.0,
             "total_battery_energy_generated_wh" => 8.0,
             "net_battery_energy_delta_wh" => 15.0,
             "peak_storage_overflow_mb" => 12.0,
             "peak_downlink_shortfall_mb" => 3.0,
             "peak_battery_overuse_wh" => 4.0,
             "peak_unused_downlink_capacity_mb" => 8.0,
             "first_resource_pressure_activity_id" => "obs_1",
             "first_resource_pressure_activity_type" => "observe",
             "first_resource_pressure_kind" => "storage_overflow",
             "first_resource_pressure_starts_at_s" => 10.0,
             "reason" => "review leo_1 resource pressure at obs_1: storage_overflow",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "payload_available" => true,
             "antenna_available" => true,
             "approval_requirements" => [
               %{
                 "id" => "approval:resource_projection:leo_1:storage_overflow",
                 "action" => "review_resource_projection"
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "resource_pressure_block",
                 "classification" => "blocked_by_policy",
                 "risk_type" => "storage_overflow"
               }
             ],
             "requirement_type" => "operator_review",
             "required_authority" => "resource_authority",
             "policy_bundle_id" => "resource_projection_authority_v1",
             "rule_id" => "resource_pressure_block",
             "escalation_level" => "mission_planner",
             "escalation_queue" => "resource_planning",
             "escalation_role" => "resource_planner",
             "sla_s" => 1200,
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "policy_bundle_id" => "resource_projection_authority_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "resource_pressure_block",
               "escalation_queue" => "resource_planning"
             },
             "source_resource_projection" => %{
               "spacecraft_id" => "leo_1",
               "resource_trust_boundary_status" => "declared"
             }
           } = first_row

    assert first_row["estimated_storage_produced_mb"] == 0.0
    assert first_row["estimated_downlink_mb"] == 0.0
    assert first_row["storage_limited_downlinked_mb"] == 0.0
    assert first_row["unused_downlink_capacity_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid =
      update_in(package, ["rows"], fn [row | rows] ->
        stale_row =
          row
          |> Map.put("activity_count", 99)
          |> Map.put("effective_activity_count", 99)
          |> Map.put("observation_count", 99)
          |> Map.put("downlink_count", 99)
          |> Map.put("ignored_activity_count", 1)
          |> Map.put("ignored_activity_ids", ["stale_ignored"])

        [stale_row | rows]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].activity_count" and
                 &1["message"] == "must equal source_resource_projection flow row count")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].effective_activity_count" and
                 &1["message"] ==
                   "must equal source_resource_projection projected flow row count")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ignored_activity_ids" and
                 &1["message"] ==
                   "must match source_resource_projection ignored activity flow row IDs")
           )
  end

  test "builds review package from resource projection flow summary rows" do
    flow_summary = resource_projection_flow_summary()

    package = OperatorReview.from_resource_projection_flow_summary(flow_summary)

    assert OrbitalDynamics.operator_review_package(flow_summary) == package

    assert %{
             "source_artifact_type" => "resource_projection_flow_summary.v1",
             "source_artifact_id" => "flow_handoff",
             "review_count" => 1,
             "resource_projection_review_count" => 1
           } = package

    first_row = List.first(package["rows"])

    assert %{
             "review_type" => "resource_projection_review",
             "source" => "resource_projection_flow_summary.projected_resources",
             "subject_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "required_operator_action" => "review_resource_projection",
             "activity_count" => 2,
             "effective_activity_count" => 2,
             "ignored_activity_count" => 0,
             "ignored_activity_ids" => [],
             "resource_flow_count" => 2,
             "total_battery_energy_consumed_wh" => 20.0,
             "total_battery_energy_generated_wh" => 5.0,
             "net_battery_energy_delta_wh" => 15.0,
             "peak_storage_overflow_mb" => 10.0,
             "peak_downlink_shortfall_mb" => 5.0,
             "first_resource_pressure_activity_id" => "obs_early",
             "first_resource_pressure_activity_type" => "observe",
             "first_resource_pressure_kind" => "storage_overflow",
             "source_resource_projection_flow_summary" => %{
               "schema_contract" => "resource_projection_flow_summary.v1",
               "resource_flow_status" => "review_required",
               "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
               "total_downlink_shortfall_mb" => 5.0
             },
             "source_resource_projection" => %{
               "spacecraft_id" => "leo_1",
               "source_resource_projection_flow_summary" => %{
                 "schema_contract" => "resource_projection_flow_summary.v1"
               }
             }
           } = first_row

    assert length(first_row["source_resource_projection"]["activity_resource_flow"]) == 2
    assert first_row["projected_storage_remaining_mb"] == 0.0
    assert first_row["projected_downlink_remaining_mb"] == 0.0

    flow_context = first_row["source_resource_projection_flow_summary"]
    assert flow_context["total_projected_storage_remaining_mb"] == 0.0
    assert flow_context["minimum_projected_storage_remaining_mb"] == 0.0
    assert flow_context["total_projected_downlink_remaining_mb"] == 0.0
    assert flow_context["minimum_projected_downlink_remaining_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_summary =
      update_in(package, ["rows"], fn [row | rows] ->
        stale_row =
          put_in(
            row,
            [
              "source_resource_projection",
              "source_resource_projection_flow_summary",
              "total_downlink_shortfall_mb"
            ],
            6.0
          )

        [stale_row | rows]
      end)

    assert {:error, report} = Schema.validate_artifact(stale_source_summary)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_resource_projection_flow_summary" and
                 &1["message"] ==
                   "must match source_resource_projection.source_resource_projection_flow_summary")
           )

    invalid_source_evidence_id =
      update_in(package, ["rows"], fn [row | rows] ->
        invalid_row =
          row
          |> put_in(["source_resource_projection_flow_summary", "id"], "summary with spaces")
          |> put_in(
            ["source_resource_projection", "source_resource_projection_flow_summary", "id"],
            "summary with spaces"
          )

        [invalid_row | rows]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence_id)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_resource_projection_flow_summary.id")
           )

    invalid =
      update_in(package, ["rows"], fn [row | rows] ->
        stale_row =
          row
          |> Map.put("activity_count", 99)
          |> Map.put("ignored_activity_count", 1)
          |> Map.put("ignored_activity_ids", ["stale_ignored"])

        [stale_row | rows]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].activity_count" and
                 &1["message"] == "must equal source_resource_projection flow row count")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ignored_activity_ids" and
                 &1["message"] ==
                   "must match source_resource_projection ignored activity flow row IDs")
           )
  end

  test "preserves source-row first resource pressure fields without nested flow rows" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "model" => "thin_selected_activity_resource_projection",
      "input_resource_summary_count" => 1,
      "activity_count" => 1,
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "activity_count" => 1,
          "observation_count" => 0,
          "downlink_count" => 1,
          "estimated_storage_produced_mb" => 0.0,
          "estimated_downlink_mb" => 50.0,
          "projected_downlink_shortfall_mb" => 20.0,
          "resource_pressure_status" => "downlink_shortfall",
          "resource_pressure_types" => ["downlink_shortfall"],
          "first_resource_pressure_activity_id" => "dl_flattened",
          "first_resource_pressure_activity_type" => "downlink",
          "first_resource_pressure_kind" => "downlink_shortfall",
          "first_resource_pressure_starts_at_s" => 120.0,
          "first_resource_pressure_source_window_id" =>
            "window:leo_1:ground_station_access:equator_prime:2",
          "first_resource_pressure_source_window_type" => "ground_station_access",
          "first_resource_pressure_source_window" => %{
            "id" => "window:leo_1:ground_station_access:equator_prime:2",
            "type" => "ground_station_access",
            "ground_station_id" => "equator_prime"
          }
        }
      ],
      "warnings" => [],
      "assumptions" => %{"source" => "flattened.resource_projection"}
    }

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    package = OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "review_type" => "resource_projection_review",
               "resource_flow_count" => 0,
               "first_resource_pressure_activity_id" => "dl_flattened",
               "first_resource_pressure_activity_type" => "downlink",
               "first_resource_pressure_kind" => "downlink_shortfall",
               "first_resource_pressure_starts_at_s" => 120.0,
               "first_resource_pressure_source_window_id" =>
                 "window:leo_1:ground_station_access:equator_prime:2",
               "source_window_id" => "window:leo_1:ground_station_access:equator_prime:2",
               "source_window_type" => "ground_station_access",
               "reason" => "review leo_1 resource pressure at dl_flattened: downlink_shortfall"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from standalone policy decision escalations" do
    decision = %{
      "schema_contract" => "policy_decision.v1",
      "classification" => "operator_review_required",
      "model_limits" => Policy.capabilities().known_limits |> Enum.map(&to_string/1),
      "policy_bundle_id" => "mission_ops_escalation_v1",
      "policy_bundle_provenance" => %{
        "source" => "organization_policy_adapter",
        "adapter" => "example_policy_adapter",
        "organization_id" => "mission_ops",
        "policy_source" => "operator_config",
        "trust_boundary" => "organization_policy_adapter"
      },
      "approval_requirement_count" => 1,
      "risk_count" => 0,
      "rule_matches" => [],
      "escalations" => [
        %{
          "rule_id" => "contact_execution_coordination",
          "classification" => "operator_review_required",
          "escalation_level" => "ops_lead",
          "escalation_queue" => "ground_network",
          "escalation_role" => "contact_scheduler",
          "required_authority" => "contact_schedule_authority",
          "sla_s" => 1800
        }
      ],
      "provenance" => %{"source" => "test"}
    }

    package = OperatorReview.from_policy_decision(decision)

    assert OrbitalDynamics.operator_review_package(decision) == package

    assert %{
             "source_artifact_type" => "policy_decision.v1",
             "source_artifact_id" => "mission_ops_escalation_v1",
             "review_count" => 1,
             "policy_escalation_count" => 1
           } = package

    assert %{
             "review_type" => "policy_escalation",
             "source" => "policy_decision.escalations",
             "subject_id" => "contact_execution_coordination",
             "required_operator_action" => "review_policy_escalation",
             "approval_status" => "operator_review_required",
             "policy_bundle_id" => "mission_ops_escalation_v1",
             "policy_bundle_provenance" => %{
               "source" => "organization_policy_adapter",
               "adapter" => "example_policy_adapter",
               "organization_id" => "mission_ops",
               "policy_source" => "operator_config",
               "trust_boundary" => "organization_policy_adapter"
             },
             "policy_bundle_provenance_source" => "organization_policy_adapter",
             "policy_bundle_adapter" => "example_policy_adapter",
             "policy_bundle_organization_id" => "mission_ops",
             "policy_bundle_policy_source" => "operator_config",
             "required_authority" => "contact_schedule_authority",
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "model_limits" => [
                 "artifact_classification_only",
                 "no_command_execution",
                 "no_schedule_mutation",
                 "no_external_authority_lookup",
                 "no_multi_step_workflow_execution"
               ],
               "policy_bundle_provenance" => %{
                 "source" => "organization_policy_adapter",
                 "adapter" => "example_policy_adapter",
                 "trust_boundary" => "organization_policy_adapter"
               }
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from standalone approval requirement" do
    requirement = %{
      "schema_contract" => "approval_requirement.v1",
      "activity_id" => "dl_2",
      "activity_type" => "downlink",
      "action" => "approve_moved_contact",
      "requirement_type" => "contact_schedule_change",
      "required_authority" => "contact_schedule_authority",
      "policy_bundle_id" => "ground_network_allocation_v1",
      "approval_rule_matches" => [
        %{"rule_id" => "moved_contact_schedule_review"}
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "classification" => "operator_review_required",
        "policy_bundle_id" => "ground_network_allocation_v1",
        "escalations" => [
          %{"rule_id" => "unmatched_rule", "escalation_queue" => "ignore_queue"},
          %{
            "rule_id" => "moved_contact_schedule_review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "network_scheduler",
            "required_authority" => "network_ops_lead",
            "sla_s" => 900
          }
        ]
      },
      "reason" => "missed_contact_rescheduled",
      "policy_classification" => "operator_review_required",
      "provenance" => %{"source" => "test"}
    }

    package = OperatorReview.from_approval_requirement(requirement)

    assert OrbitalDynamics.operator_review_package(requirement) == package

    assert %{
             "source_artifact_type" => "approval_requirement.v1",
             "source_artifact_id" => "dl_2",
             "review_count" => 1,
             "approval_requirement_count" => 1
           } = package

    assert %{
             "review_type" => "approval_requirement",
             "source" => "approval_requirement",
             "subject_id" => "dl_2",
             "required_operator_action" => "approve_moved_contact",
             "approval_status" => "operator_review_required",
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "moved_contact_schedule_review",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "network_scheduler",
             "sla_s" => 900,
             "approval_rule_matches" => [
               %{"rule_id" => "moved_contact_schedule_review"}
             ],
             "source_policy_escalation" => %{
               "rule_id" => "moved_contact_schedule_review",
               "escalation_queue" => "ground_network"
             },
             "source_requirement" => %{"schema_contract" => "approval_requirement.v1"}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_requirement =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> put_in(["source_requirement", "activity_id"], "stale_dl")
          |> put_in(["source_requirement", "action"], "stale_action")
        ]
      end)

    assert {:error, stale_source_requirement_report} =
             Schema.validate_artifact(stale_source_requirement)

    assert Enum.any?(
             stale_source_requirement_report["errors"],
             &(&1["path"] == "$.rows[0].activity_id" and
                 &1["message"] == "must match source_requirement.activity_id")
           )

    assert Enum.any?(
             stale_source_requirement_report["errors"],
             &(&1["path"] == "$.rows[0].required_operator_action" and
                 &1["message"] == "must match source_requirement.action")
           )
  end

  test "builds repair review package from approval requirements and warnings" do
    artifact = %{
      "schema_version" => 2,
      "repair_metadata" => %{
        "repair_id" => "repair:1",
        "timeline_protection" => %{
          "preserved_locked_or_approved_count" => 1,
          "preserved_executed_count" => 0,
          "changed_locked_or_approved_count" => 0,
          "changed_executed_count" => 0,
          "preserved_locked_or_approved_activity_ids" => ["locked_dl"],
          "preserved_executed_activity_ids" => [],
          "changed_locked_or_approved_activity_ids" => [],
          "changed_executed_activity_ids" => []
        }
      },
      "approval_requirements" => [
        %{
          "schema_contract" => "approval_requirement.v1",
          "activity_id" => "dl_2",
          "activity_type" => "downlink",
          "action" => "approve_moved_contact",
          "requirement_type" => "contact_schedule_change",
          "reason" => "missed_contact_rescheduled"
        }
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "classification" => "operator_review_required",
        "policy_bundle_id" => "mission_ops_escalation_v1",
        "approval_requirement_count" => 1,
        "risk_count" => 0,
        "rule_matches" => [],
        "escalations" => [
          %{
            "rule_id" => "contact_execution_coordination",
            "classification" => "operator_review_required",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 1800
          }
        ],
        "assumptions" => %{"boundary" => "artifact_only_no_authority_lookup"}
      },
      "deltas" => [
        %{
          "schema_contract" => "plan_delta.v1",
          "activity_id" => "dl_1",
          "activity_type" => "downlink",
          "status" => "missed",
          "repair_action" => "moved",
          "reason" => "missed_contact_rescheduled",
          "replacement_activity_id" => "dl_2",
          "source_timeline_id" => "timeline:dl_1",
          "replacement_timeline_id" => "timeline:dl_2",
          "timeline_link" => %{
            "source_activity_id" => "dl_1",
            "replacement_activity_id" => "dl_2",
            "source_timeline_id" => "timeline:dl_1",
            "replacement_timeline_id" => "timeline:dl_2"
          },
          "source_activity_context" => %{
            "cadence_import" => %{
              "activity_type" => "contact",
              "external_id" => "dl_1",
              "schema_contract" => "proposed_contact.v1"
            },
            "timeline_identity" => %{
              "timeline_id" => "timeline:dl_1",
              "activity_id" => "dl_1",
              "activity_type" => "downlink"
            }
          },
          "replacement_activity_context" => %{
            "cadence_import" => %{
              "activity_type" => "contact",
              "external_id" => "dl_2",
              "schema_contract" => "proposed_contact.v1"
            },
            "timeline_identity" => %{
              "timeline_id" => "timeline:dl_2",
              "activity_id" => "dl_2",
              "activity_type" => "downlink"
            }
          },
          "requires_approval" => true
        }
      ],
      "operational_timeline_report" => %{
        "schema_contract" => "operational_timeline_report.v1",
        "rows" => [
          %{
            "id" => "timeline_row:1:cmd_repair",
            "activity_id" => "cmd_repair",
            "timeline_id" => "timeline:cmd_repair",
            "scenario_id" => "leo_1",
            "activity_type" => "command",
            "operational_kind" => "command",
            "direction" => "command",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 410.0,
            "ends_at_s" => 430.0,
            "status" => "planned",
            "approval_status" => "pending",
            "locked" => false,
            "required_operator_action" => "review_command_contact",
            "operator_action_reason" => "command_boundary_requires_review",
            "execution_boundary" => "planned_not_commanded",
            "cadence_import_status" => "present",
            "has_cadence_import" => true,
            "has_source_window" => false,
            "timeline_identity" => %{
              "timeline_id" => "timeline:cmd_repair",
              "activity_id" => "cmd_repair",
              "activity_type" => "command",
              "scenario_id" => "leo_1"
            }
          }
        ]
      },
      "source_resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "obs_resource_blocked",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 320.0,
            "ends_at_s" => 420.0,
            "suppressed_reason" => "storage_margin_below_observe_policy",
            "source_window_id" => "window:leo_1:target_visibility:target_b:1"
          }
        ]
      },
      "source_contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "ground_station_availability_filter",
        "input_contact_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "dl_contact_reserved",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "starts_at_s" => 220.0,
            "ends_at_s" => 280.0,
            "ground_station_id" => "equator_prime",
            "station_availability" => "reserved",
            "station_contention_status" => "reserved_overlap",
            "station_reservation_id" => "reservation_equator_prime_1",
            "station_reserved_by" => "mission_partner",
            "station_reservation_status" => "confirmed",
            "suppressed_reason" => "ground_station_reserved",
            "source_window_id" => "window:leo_1:ground_station_access:equator_prime:2"
          }
        ]
      },
      "warnings" => ["missed downlink repaired"],
      "provenance" => %{"source_plan_id" => "campaign_plan:test"}
    }

    package = OperatorReview.from_repair_artifact(artifact)

    assert OrbitalDynamics.operator_review_package(artifact) == package

    assert %{
             "schema_contract" => "operator_review_package.v1",
             "source_artifact_type" => "campaign_repair.v2",
             "source_artifact_id" => "repair:1",
             "review_count" => 8,
             "approval_requirement_count" => 1,
             "policy_escalation_count" => 1,
             "operational_timeline_count" => 1,
             "contact_suppression_count" => 1,
             "resource_suppression_count" => 1,
             "contention_recommendation_count" => 0,
             "realized_feedback_count" => 0,
             "plan_delta_count" => 1,
             "timeline_protection_count" => 1,
             "warning_count" => 1,
             "risk_count" => 0,
             "recommendation_count" => 0
           } = package

    assert %{
             "review_type" => "approval_requirement",
             "subject_id" => "dl_2",
             "required_operator_action" => "approve_moved_contact",
             "source_requirement" => %{"schema_contract" => "approval_requirement.v1"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "approval_requirement"))

    assert %{
             "review_type" => "policy_escalation",
             "subject_id" => "contact_execution_coordination",
             "required_operator_action" => "review_policy_escalation",
             "approval_status" => "operator_review_required",
             "policy_bundle_id" => "mission_ops_escalation_v1",
             "required_authority" => "contact_schedule_authority",
             "sla_s" => 1800,
             "source_policy_decision" => %{"schema_contract" => "policy_decision.v1"},
             "source_policy_escalation" => %{"rule_id" => "contact_execution_coordination"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "policy_escalation"))

    assert %{
             "review_type" => "operational_timeline_review",
             "activity_id" => "cmd_repair",
             "timeline_id" => "timeline:cmd_repair",
             "required_operator_action" => "review_command_contact",
             "approval_status" => "operator_review_required",
             "source_approval_status" => "pending",
             "source_operational_timeline" => %{"activity_id" => "cmd_repair"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "operational_timeline_review"))

    assert %{
             "review_type" => "plan_delta_review",
             "activity_id" => "dl_1",
             "replacement_activity_id" => "dl_2",
             "required_operator_action" => "review_moved_timeline_item",
             "approval_status" => "operator_review_required",
             "repair_action" => "moved",
             "timeline_link" => %{
               "source_activity_id" => "dl_1",
               "replacement_activity_id" => "dl_2"
             },
             "source_timeline_identity" => %{"timeline_id" => "timeline:dl_1"},
             "replacement_timeline_identity" => %{"timeline_id" => "timeline:dl_2"},
             "source_cadence_import_status" => "present",
             "source_cadence_import_type" => "contact",
             "source_cadence_import_id" => "dl_1",
             "source_cadence_import_contract" => "proposed_contact.v1",
             "source_has_cadence_import" => true,
             "replacement_cadence_import_status" => "present",
             "replacement_cadence_import_type" => "contact",
             "replacement_cadence_import_id" => "dl_2",
             "replacement_cadence_import_contract" => "proposed_contact.v1",
             "replacement_has_cadence_import" => true,
             "source_delta" => %{"schema_contract" => "plan_delta.v1"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "plan_delta_review"))

    assert %{
             "review_type" => "timeline_protection",
             "activity_id" => "locked_dl",
             "required_operator_action" => "record_protected_timeline_preservation",
             "approval_status" => "not_required",
             "protection_category" => "preserved_locked_or_approved",
             "protection_decision" => "preserved",
             "source_timeline_protection" => %{
               "preserved_locked_or_approved_activity_ids" => ["locked_dl"]
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "timeline_protection"))

    assert %{
             "review_type" => "contact_suppression",
             "source" => "campaign_repair.source_contact_filter_report.suppressed_candidates",
             "activity_id" => "dl_contact_reserved",
             "activity_type" => "downlink",
             "required_operator_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_equator_prime_1",
             "station_reserved_by" => "mission_partner",
             "station_reservation_status" => "confirmed",
             "source_contact_suppression" => %{
               "suppressed_reason" => "ground_station_reserved"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_suppression"))

    assert %{
             "review_type" => "resource_suppression",
             "source" => "campaign_repair.source_resource_filter_report.suppressed_candidates",
             "activity_id" => "obs_resource_blocked",
             "activity_type" => "observe",
             "required_operator_action" => "review_suppressed_observation",
             "source_window_id" => "window:leo_1:target_visibility:target_b:1",
             "source_resource_suppression" => %{
               "suppressed_reason" => "storage_margin_below_observe_policy"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "resource_suppression"))

    assert %{
             "review_type" => "warning",
             "required_operator_action" => "review_warning",
             "reason" => "missed downlink repaired"
           } = Enum.find(package["rows"], &(&1["review_type"] == "warning"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_delta =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "plan_delta_review", "source_delta" => %{}} = row ->
            row
            |> put_in(["source_delta", "activity_id"], "stale_dl")
            |> put_in(["source_delta", "repair_action"], "suppressed")

          row ->
            row
        end)
      end)

    assert {:error, stale_source_delta_report} = Schema.validate_artifact(stale_source_delta)

    assert Enum.any?(
             stale_source_delta_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.activity_id$/ and
                 &1["message"] == "must match source_delta.activity_id")
           )

    assert Enum.any?(
             stale_source_delta_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.repair_action$/ and
                 &1["message"] == "must match source_delta.repair_action")
           )
  end

  test "preserves malformed plan-delta cadence import contexts for review" do
    artifact = %{
      "schema_contract" => "campaign_repair.v2",
      "repair_metadata" => %{"repair_id" => "repair_bad_delta_import"},
      "deltas" => [
        %{
          "schema_contract" => "plan_delta.v1",
          "activity_id" => "dl_1",
          "activity_type" => "downlink",
          "repair_action" => "moved",
          "replacement_activity_id" => "dl_2",
          "source_activity_context" => %{
            "cadence_import" => :bad_source_import,
            "timeline_identity" => %{
              "timeline_id" => "timeline:dl_1",
              "activity_type" => "downlink"
            }
          },
          "replacement_activity_context" => %{
            "cadence_import" => :bad_replacement_import,
            "timeline_identity" => %{
              "timeline_id" => "timeline:dl_2",
              "activity_type" => "downlink"
            }
          }
        }
      ]
    }

    package = OperatorReview.from_repair_artifact(artifact)
    row = List.first(package["rows"])

    assert %{
             "review_type" => "plan_delta_review",
             "activity_id" => "dl_1",
             "source_cadence_import_status" => "invalid",
             "replacement_cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{
               "source" => %{"invalid_import_shape" => "bad_source_import"},
               "replacement" => %{"invalid_import_shape" => "bad_replacement_import"}
             },
             "source_activity_context" => %{
               "invalid_cadence_import" => true,
               "source_cadence_import" => %{"invalid_import_shape" => "bad_source_import"}
             },
             "replacement_activity_context" => %{
               "invalid_cadence_import" => true,
               "source_cadence_import" => %{
                 "invalid_import_shape" => "bad_replacement_import"
               }
             }
           } = row

    refute Map.has_key?(row["source_activity_context"], "cadence_import")
    refute Map.has_key?(row["replacement_activity_context"], "cadence_import")

    manifest = CadenceImport.from_operator_review_package(package)
    import_row = List.first(manifest["rows"])

    assert %{
             "import_status" => "review_required_before_import",
             "cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{
               "source" => %{"invalid_import_shape" => "bad_source_import"},
               "replacement" => %{"invalid_import_shape" => "bad_replacement_import"}
             },
             "import_activity_context" => %{
               "invalid_cadence_import" => true,
               "source_cadence_import" => %{
                 "invalid_import_shape" => "bad_replacement_import"
               }
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds strategy review package from recommendation risks approvals and branch warnings" do
    package =
      OperatorReview.from_strategy_artifact(%{
        "strategy_metadata" => %{"strategy_id" => "strategy:1"},
        "operational_feedback_provenance" => %{
          "model" => "deterministic_merge_explicit_overrides_mission_state_overrides_prior_plan",
          "input_keys" => ["contact_success_rate", "station_throughput_factor"],
          "source_count" => 1,
          "sources" => [
            %{
              "source" => "request.operational_feedback",
              "input_keys" => ["contact_success_rate", "station_throughput_factor"],
              "trust_boundary_status" => "declared",
              "trust_boundary" => "cadence_feedback_adapter"
            }
          ]
        },
        "recommendation" => %{
          "recommended_branch_id" => "urgent",
          "approval_status" => "operator_review_required",
          "reason" => "best_expected_score_requiring_operator_review",
          "ranked_branch_ids" => ["urgent", "baseline"],
          "requires_approval" => [
            %{
              "schema_contract" => "approval_requirement.v1",
              "activity_id" => "obs_urgent",
              "activity_type" => "observe",
              "action" => "approve_strategic_addition",
              "requirement_type" => "strategic_addition",
              "reason" => "urgent_high_priority_target_inserted",
              "activity_context" => %{
                "target_id" => "target_hot",
                "source_window_id" => "window:target_hot",
                "target_priority" => 4.0,
                "observation_success_factor" => 0.5,
                "contact_success_factor" => 0.4,
                "contact_success_factor_source" =>
                  "operational_feedback.contact_success_rate.station"
              },
              "candidate_diff" => %{
                "invalidated_candidate_id" => "obs_old",
                "invalidated_candidate_ids" => ["obs_old", "obs_old_copy"],
                "replacement_candidate_id" => "obs_urgent",
                "invalidated_reason" => "ambiguous_candidate_diff_match",
                "candidate_diff_match_status" => "ambiguous_replacement_candidate_diff",
                "candidate_diff_match_count" => 2,
                "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
                "candidate_budget_match_count" => 1,
                "budget_dropped_candidate_ids" => ["obs_urgent"],
                "semantic_change_reasons" => ["source_window_id_changed"]
              }
            }
          ],
          "risks_remaining" => [
            %{
              "type" => "urgent_target",
              "severity" => "medium",
              "reason" => "urgent target",
              "activity_id" => "obs_urgent",
              "scenario_id" => "leo_1",
              "target_id" => "target_hot",
              "collection_id" => "collection_hot",
              "product_id" => "product_hot",
              "payload_id" => "payload_hot",
              "instrument_id" => "instrument_hot",
              "objective_id" => "objective:latency_hot",
              "objective_type" => "collection_latency",
              "latency_objective" => true,
              "max_latency_s" => 180.0,
              "planned_latency_s" => 420.0,
              "required_downlink_mb" => 30.0,
              "planned_downlink_mb" => 0.0,
              "source_activity_ids" => ["obs_hot"],
              "maneuver_id" => "burn_uncertain",
              "execution_uncertainty_status" => "declared",
              "execution_uncertainty_source" => "provider_execution_covariance",
              "timing_3sigma_s" => 75.0,
              "delta_v_3sigma_magnitude_km_s" => 0.002,
              "feedback_source" => "prior_plan.source_objective_satisfaction_report",
              "feedback_scope" => "objective_satisfaction",
              "direction" => "downlink",
              "source_window_id" => "window:leo_1:ground_station_access:equator_prime:risk",
              "source_window_type" => "ground_station_access",
              "ground_station_id" => "equator_prime",
              "station_calendar_entry_id" => "station_calendar_entry_1",
              "station_calendar_directions" => ["command"]
            }
          ],
          "tradeoffs" => [
            %{
              "dimension" => "expected_score",
              "baseline" => 50.0,
              "recommended" => 75.0,
              "delta" => 25.0
            },
            %{"dimension" => "risk_count", "baseline" => 0, "recommended" => 1, "delta" => 1}
          ],
          "explanation" => [
            %{
              "type" => "branch_event_summary",
              "branch_event_count" => 2,
              "branch_event_types" => ["downlink_completion_gap"],
              "branch_event_trust_boundary_status_counts" => %{"declared" => 1, "missing" => 1},
              "capacity_pack_group_ids" => ["station:equator_prime:pack:review"],
              "capacity_pack_statuses" => ["deferred_by_reduced_station_capacity_pack"],
              "capacity_pack_min_capacity_fraction" => 0.5,
              "capacity_pack_max_used_fraction" => 0.5,
              "capacity_pack_max_required_capacity_fraction" => 0.25,
              "capacity_pack_total_required_capacity_fraction" => 0.35,
              "capacity_pack_required_capacity_sources" => [
                "contact_required_capacity_fraction",
                "default_reduced_capacity_policy"
              ]
            }
          ]
        },
        "ranking_comparison_report" => %{
          "schema_contract" => "ranking_comparison_report.v1",
          "model" => "scenario_ranking_pairwise_delta",
          "source" => "campaign_strategy.branch_comparison_report",
          "objective" => "strategy_branch_score",
          "objective_direction" => "maximize",
          "left_label" => "normalized_branch_order",
          "right_label" => "score_ranked_branches",
          "left_count" => 2,
          "right_count" => 2,
          "matched_count" => 2,
          "left_only_count" => 0,
          "right_only_count" => 0,
          "row_count" => 2,
          "winner" => %{
            "left_scenario_id" => "urgent",
            "right_scenario_id" => "baseline",
            "changed" => true
          },
          "rows" => [
            %{
              "scenario_id" => "baseline",
              "status" => "matched",
              "left_rank" => 2,
              "right_rank" => 1,
              "rank_delta" => 1,
              "left_value" => 50.0,
              "right_value" => 75.0,
              "value_delta" => 25.0
            },
            %{
              "scenario_id" => "urgent",
              "status" => "matched",
              "left_rank" => 1,
              "right_rank" => 2,
              "rank_delta" => -1,
              "left_value" => 75.0,
              "right_value" => 50.0,
              "value_delta" => -25.0
            }
          ],
          "assumptions" => %{"rank_source" => "input_order"}
        },
        "branches" => [
          %{
            "branch_id" => "urgent",
            "warnings" => ["resource margin low"],
            "resource_projection_report" => %{
              "schema_contract" => "resource_projection_report.v1",
              "model" => "thin_strategy_branch_activity_resource_projection",
              "projected_resources" => [
                %{
                  "spacecraft_id" => "leo_1",
                  "activity_count" => 1,
                  "downlink_count" => 1,
                  "estimated_downlink_mb" => 60.0,
                  "downlink_capacity_mb" => 10.0,
                  "projected_downlink_margin" => 0.0,
                  "projected_downlink_shortfall_mb" => 50.0,
                  "approval_status" => "blocked_by_policy",
                  "activity_resource_flow" => [
                    %{
                      "activity_id" => "urgent_downlink_allocated",
                      "activity_type" => "downlink",
                      "starts_at_s" => 620.0,
                      "downlink_shortfall_mb" => 50.0
                    }
                  ]
                }
              ]
            },
            "repair_result" => %{
              "source_resource_filter_report" => %{
                "schema_contract" => "resource_filter_report.v1",
                "model" => "resource_summary_availability_and_margin_filter",
                "input_candidate_count" => 2,
                "kept_candidate_count" => 1,
                "suppressed_candidate_count" => 1,
                "suppressed_candidates" => [
                  %{
                    "id" => "urgent_downlink_suppressed",
                    "type" => "downlink",
                    "scenario_id" => "leo_1",
                    "starts_at_s" => 500.0,
                    "ends_at_s" => 620.0,
                    "ground_station_id" => "equator_prime",
                    "station_availability" => "available",
                    "suppressed_reason" => "downlink_margin_below_policy",
                    "source_window_id" => "window:leo_1:ground_station_access:equator_prime:3"
                  }
                ]
              },
              "source_contact_filter_report" => %{
                "schema_contract" => "contact_filter_report.v1",
                "model" => "ground_station_availability_filter",
                "input_contact_count" => 2,
                "kept_candidate_count" => 1,
                "suppressed_candidate_count" => 1,
                "suppressed_candidates" => [
                  %{
                    "id" => "urgent_downlink_contact_suppressed",
                    "type" => "downlink",
                    "scenario_id" => "leo_1",
                    "starts_at_s" => 450.0,
                    "ends_at_s" => 510.0,
                    "ground_station_id" => "equator_prime",
                    "station_availability" => "unavailable",
                    "suppressed_reason" => "ground_station_unavailable",
                    "source_window_id" => "window:leo_1:ground_station_access:equator_prime:2"
                  }
                ]
              },
              "source_contact_allocation_report" => %{
                "schema_contract" => "contact_allocation_report.v1",
                "model" => "deterministic_station_contact_allocation",
                "source" => "candidate_refresh.candidate_activities",
                "input_contact_count" => 2,
                "allocated_contact_count" => 1,
                "deferred_contact_count" => 1,
                "blocked_contact_count" => 0,
                "rows" => [
                  %{
                    "id" => "contact_allocation:urgent_downlink_allocated",
                    "contact_id" => "urgent_downlink_allocated",
                    "type" => "downlink",
                    "scenario_id" => "leo_1",
                    "ground_station_id" => "equator_prime",
                    "direction" => "downlink",
                    "starts_at_s" => 620.0,
                    "ends_at_s" => 700.0,
                    "source_window_id" => "window:leo_1:ground_station_access:equator_prime:4",
                    "allocation_status" => "allocated",
                    "allocation_reason" => "selected_by_contention_resolution",
                    "selected" => true,
                    "contention_group_id" => "station:equator_prime:contention:4",
                    "deferred_contact_ids" => ["urgent_downlink_deferred"],
                    "review_status" => "operator_review_required"
                  },
                  %{
                    "id" => "contact_allocation:urgent_downlink_deferred",
                    "contact_id" => "urgent_downlink_deferred",
                    "type" => "downlink",
                    "scenario_id" => "leo_2",
                    "ground_station_id" => "equator_prime",
                    "direction" => "downlink",
                    "starts_at_s" => 630.0,
                    "ends_at_s" => 710.0,
                    "source_window_id" => "window:leo_2:ground_station_access:equator_prime:4",
                    "allocation_status" => "deferred",
                    "allocation_reason" => "same_station_contention",
                    "selected" => false,
                    "contention_group_id" => "station:equator_prime:contention:4",
                    "selected_contact_id" => "urgent_downlink_allocated",
                    "review_status" => "operator_review_required"
                  }
                ]
              },
              "source_contact_intents" => [
                %{
                  "schema_contract" => "contact_intent.v1",
                  "id" => "urgent_downlink_allocated",
                  "activity_id" => "urgent_downlink_allocated",
                  "activity_type" => "downlink",
                  "scenario_id" => "leo_1",
                  "ground_station_id" => "equator_prime",
                  "direction" => "downlink",
                  "starts_at_s" => 620.0,
                  "ends_at_s" => 700.0,
                  "approval_status" => "operator_review_required",
                  "approval_requirements" => [
                    %{
                      "schema_contract" => "approval_requirement.v1",
                      "id" => "approval:urgent_downlink_allocated",
                      "activity_id" => "urgent_downlink_allocated",
                      "activity_type" => "downlink",
                      "action" => "review_contact_intent",
                      "requirement_type" => "contact_schedule_change",
                      "reason" => "contact intent requires schedule authority"
                    }
                  ],
                  "approval_rule_matches" => [
                    %{
                      "rule_id" => "downlink_schedule_authority_review",
                      "required_authority" => "contact_schedule_authority"
                    }
                  ],
                  "policy_decision" => %{
                    "schema_contract" => "policy_decision.v1",
                    "policy_bundle_id" => "command_contact_authority_v1",
                    "classification" => "operator_review_required"
                  }
                }
              ]
            }
          }
        ],
        "provenance" => %{"source_plan_id" => "campaign_plan:test"}
      })

    assert package["review_count"] == 14
    assert package["approval_requirement_count"] == 1
    assert package["contact_allocation_review_count"] == 2
    assert package["contact_intent_review_count"] == 1
    assert package["contact_suppression_count"] == 1
    assert package["contention_recommendation_count"] == 0
    assert package["realized_feedback_count"] == 0
    assert package["resource_projection_review_count"] == 1
    assert package["resource_suppression_count"] == 1
    assert package["risk_count"] == 1
    assert package["recommendation_count"] == 1
    assert package["ranking_comparison_count"] == 2
    assert package["tradeoff_count"] == 2
    assert package["warning_count"] == 1

    assert %{
             "review_type" => "strategy_recommendation",
             "branch_id" => "urgent",
             "recommended_branch_id" => "urgent",
             "ranked_branch_ids" => ["urgent", "baseline"],
             "tradeoff_count" => 2,
             "risk_count" => 1,
             "risk_types" => ["urgent_target"],
             "activity_ids" => ["obs_urgent"],
             "scenario_ids" => ["leo_1"],
             "ground_station_ids" => ["equator_prime"],
             "target_ids" => ["target_hot"],
             "collection_ids" => ["collection_hot"],
             "product_ids" => ["product_hot"],
             "payload_ids" => ["payload_hot"],
             "instrument_ids" => ["instrument_hot"],
             "objective_ids" => ["objective:latency_hot"],
             "objective_types" => ["collection_latency"],
             "feedback_sources" => ["prior_plan.source_objective_satisfaction_report"],
             "feedback_scopes" => ["objective_satisfaction"],
             "source_activity_ids" => ["obs_hot"],
             "source_window_ids" => ["window:leo_1:ground_station_access:equator_prime:risk"],
             "source_window_types" => ["ground_station_access"],
             "maneuver_ids" => ["burn_uncertain"],
             "maneuver_execution_uncertainty_statuses" => ["declared"],
             "maneuver_execution_uncertainty_sources" => ["provider_execution_covariance"],
             "maneuver_execution_uncertainty_timing_3sigma_s" => [75.0],
             "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_km_s" => [0.002],
             "directions" => ["downlink"],
             "station_calendar_entry_ids" => ["station_calendar_entry_1"],
             "station_calendar_directions" => ["command"],
             "branch_event_count" => 2,
             "branch_event_types" => ["downlink_completion_gap"],
             "branch_event_trust_boundary_status_counts" => %{
               "declared" => 1,
               "missing" => 1
             },
             "capacity_pack_group_ids" => ["station:equator_prime:pack:review"],
             "capacity_pack_statuses" => ["deferred_by_reduced_station_capacity_pack"],
             "capacity_pack_min_capacity_fraction" => 0.5,
             "capacity_pack_max_used_fraction" => 0.5,
             "capacity_pack_max_required_capacity_fraction" => 0.25,
             "capacity_pack_total_required_capacity_fraction" => 0.35,
             "capacity_pack_required_capacity_sources" => [
               "contact_required_capacity_fraction",
               "default_reduced_capacity_policy"
             ],
             "approval_requirement_count" => 1,
             "required_operator_action" => "review_strategy_recommendation",
             "operational_feedback_trust_boundary_status" => "declared",
             "operational_feedback_trust_boundary" => "cadence_feedback_adapter",
             "operational_feedback_input_keys" => [
               "contact_success_rate",
               "station_throughput_factor"
             ],
             "source_operational_feedback_provenance" => %{
               "source_count" => 1
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "strategy_recommendation"))

    assert %{
             "risk_type" => "urgent_target",
             "activity_id" => "obs_urgent",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "target_id" => "target_hot",
             "collection_id" => "collection_hot",
             "product_id" => "product_hot",
             "payload_id" => "payload_hot",
             "instrument_id" => "instrument_hot",
             "objective_id" => "objective:latency_hot",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "max_latency_s" => 180.0,
             "planned_latency_s" => 420.0,
             "required_downlink_mb" => 30.0,
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:risk",
             "source_window_type" => "ground_station_access",
             "direction" => "downlink",
             "station_calendar_entry_id" => "station_calendar_entry_1",
             "station_calendar_directions" => ["command"]
           } =
             Enum.find(package["rows"], &(&1["review_type"] == "risk_explanation"))

    assert %{
             "review_type" => "strategy_tradeoff",
             "subject_id" => "expected_score",
             "branch_id" => "urgent",
             "required_operator_action" => "review_strategy_tradeoff",
             "baseline" => 50.0,
             "recommended" => 75.0,
             "delta" => 25.0,
             "source_tradeoff" => %{"dimension" => "expected_score"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "strategy_tradeoff"))

    assert %{
             "review_type" => "ranking_comparison_review",
             "source" => "campaign_strategy.ranking_comparison_report.rows",
             "subject_id" => "baseline",
             "scenario_id" => "baseline",
             "required_operator_action" => "review_ranking_comparison",
             "left_rank" => 2,
             "right_rank" => 1,
             "rank_delta" => 1,
             "source_ranking_comparison" => %{"scenario_id" => "baseline"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "ranking_comparison_review"))

    assert %{
             "review_type" => "approval_requirement",
             "activity_id" => "obs_urgent",
             "candidate_diff" => %{
               "invalidated_candidate_id" => "obs_old",
               "invalidated_candidate_ids" => ["obs_old", "obs_old_copy"],
               "replacement_candidate_id" => "obs_urgent",
               "invalidated_reason" => "ambiguous_candidate_diff_match",
               "candidate_diff_match_status" => "ambiguous_replacement_candidate_diff",
               "candidate_diff_match_count" => 2,
               "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
               "candidate_budget_match_count" => 1,
               "budget_dropped_candidate_ids" => ["obs_urgent"],
               "semantic_change_reasons" => ["source_window_id_changed"]
             },
             "invalidated_candidate_id" => "obs_old",
             "invalidated_candidate_ids" => ["obs_old", "obs_old_copy"],
             "replacement_candidate_id" => "obs_urgent",
             "invalidated_reason" => "ambiguous_candidate_diff_match",
             "candidate_diff_match_status" => "ambiguous_replacement_candidate_diff",
             "candidate_diff_match_count" => 2,
             "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
             "candidate_budget_match_count" => 1,
             "budget_dropped_candidate_ids" => ["obs_urgent"],
             "activity_context" => %{
               "target_id" => "target_hot",
               "source_window_id" => "window:target_hot",
               "target_priority" => 4.0,
               "observation_success_factor" => 0.5,
               "contact_success_factor" => 0.4,
               "contact_success_factor_source" =>
                 "operational_feedback.contact_success_rate.station"
             },
             "source_requirement" => %{
               "activity_context" => %{
                 "target_id" => "target_hot",
                 "source_window_id" => "window:target_hot"
               },
               "candidate_diff" => %{
                 "invalidated_reason" => "ambiguous_candidate_diff_match"
               }
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "approval_requirement"))

    assert %{
             "review_type" => "contact_suppression",
             "branch_id" => "urgent",
             "activity_id" => "urgent_downlink_contact_suppressed",
             "activity_type" => "downlink",
             "required_operator_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "station_availability" => "unavailable",
             "source" =>
               "campaign_strategy.branches.repair_result.source_contact_filter_report.suppressed_candidates",
             "source_contact_suppression" => %{
               "suppressed_reason" => "ground_station_unavailable"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_suppression"))

    assert %{
             "review_type" => "contact_allocation_review",
             "branch_id" => "urgent",
             "contact_id" => "urgent_downlink_deferred",
             "allocation_status" => "deferred",
             "required_operator_action" => "review_contact_allocation",
             "source" =>
               "campaign_strategy.branches.repair_result.source_contact_allocation_report.rows",
             "source_contact_allocation" => %{
               "allocation_reason" => "same_station_contention"
             }
           } = Enum.find(package["rows"], &(&1["contact_id"] == "urgent_downlink_deferred"))

    assert %{
             "review_type" => "contact_intent_review",
             "branch_id" => "urgent",
             "activity_id" => "urgent_downlink_allocated",
             "contact_id" => "urgent_downlink_allocated",
             "required_operator_action" => "review_contact_intent",
             "approval_status" => "operator_review_required",
             "source" => "campaign_strategy.branches.repair_result.source_contact_intents",
             "source_policy_decision" => %{
               "policy_bundle_id" => "command_contact_authority_v1",
               "classification" => "operator_review_required"
             },
             "source_contact_intent" => %{
               "schema_contract" => "contact_intent.v1",
               "activity_id" => "urgent_downlink_allocated"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_intent_review"))

    assert %{
             "review_type" => "resource_suppression",
             "branch_id" => "urgent",
             "activity_id" => "urgent_downlink_suppressed",
             "activity_type" => "downlink",
             "required_operator_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "station_availability" => "available",
             "source" =>
               "campaign_strategy.branches.repair_result.source_resource_filter_report.suppressed_candidates",
             "source_resource_suppression" => %{
               "suppressed_reason" => "downlink_margin_below_policy"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "resource_suppression"))

    assert %{
             "review_type" => "resource_projection_review",
             "branch_id" => "urgent",
             "spacecraft_id" => "leo_1",
             "approval_status" => "blocked_by_policy",
             "projected_downlink_shortfall_mb" => 50.0,
             "first_resource_pressure_activity_id" => "urgent_downlink_allocated",
             "first_resource_pressure_kind" => "downlink_shortfall",
             "source" =>
               "campaign_strategy.branches.resource_projection_report.projected_resources",
             "source_resource_projection" => %{
               "projected_downlink_shortfall_mb" => 50.0
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "resource_projection_review"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_risk =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "risk_explanation", "source_risk" => %{}} = row ->
            row
            |> put_in(["source_risk", "type"], "stale_risk_type")
            |> put_in(["source_risk", "severity"], "critical")

          row ->
            row
        end)
      end)

    assert {:error, stale_source_risk_report} = Schema.validate_artifact(stale_source_risk)

    assert Enum.any?(
             stale_source_risk_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.risk_type$/ and
                 &1["message"] == "must match source_risk.type")
           )

    assert Enum.any?(
             stale_source_risk_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.severity$/ and
                 &1["message"] == "must match source_risk.severity")
           )

    stale_source_recommendation =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "strategy_recommendation", "source_recommendation" => %{}} = row ->
            row
            |> put_in(["source_recommendation", "recommended_branch_id"], "baseline")
            |> put_in(["source_recommendation", "risks_remaining"], [])

          row ->
            row
        end)
      end)

    assert {:error, stale_source_recommendation_report} =
             Schema.validate_artifact(stale_source_recommendation)

    assert Enum.any?(
             stale_source_recommendation_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.branch_id$/ and
                 &1["message"] == "must match source_recommendation.recommended_branch_id")
           )

    assert Enum.any?(
             stale_source_recommendation_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.risk_count$/ and
                 &1["message"] == "must match source_recommendation.risks_remaining count")
           )

    stale_source_tradeoff =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "strategy_tradeoff", "source_tradeoff" => %{}} = row ->
            put_in(row, ["source_tradeoff", "delta"], 12.0)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_tradeoff_report} =
             Schema.validate_artifact(stale_source_tradeoff)

    assert Enum.any?(
             stale_source_tradeoff_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.delta$/ and
                 &1["message"] == "must match source_tradeoff.delta")
           )
  end

  test "builds review package from realized timeline feedback rows" do
    report = %{
      schema_contract: "timeline_feedback_report.v1",
      rows: [
        %{
          activity_id: "obs_1",
          status: "matched",
          planned_type: "observe",
          planned_status: "approved",
          realized_status: "completed",
          planned_starts_at_s: 10.0,
          planned_ends_at_s: 20.0,
          actual_starts_at_s: 11.0,
          actual_ends_at_s: 22.0,
          start_delta_s: 1.0,
          end_delta_s: 2.0,
          completed_fraction: 1.0,
          thermal_zone_id: "payload_deck",
          temperature_c: 21.5,
          planned_temperature_c: 18.0,
          actual_temperature_c: 21.5,
          temperature_delta_c: 3.5,
          min_operating_temperature_c: -5.0,
          max_operating_temperature_c: 45.0,
          thermal_margin_c: 23.5,
          thermal_status: "warm",
          thermal_model: "thermal_model:v1",
          thermal_source: "realized_activity",
          thermal_confidence: 0.8
        },
        %{
          activity_id: "obs_2",
          status: "matched",
          planned_type: "observe",
          planned_status: "approved",
          realized_status: "failed",
          contact_result: ["accepted", "dropped"],
          observation_result: [:started, :timeout],
          reason: "payload timeout"
        },
        %{
          activity_id: "dl_1",
          status: "planned_only",
          planned_type: "downlink",
          planned_status: "approved"
        },
        %{activity_id: "unplanned_1", status: "realized_only", realized_status: "partial"}
      ],
      provenance: %{"source" => "timeline_feedback_test"}
    }

    string_key_report =
      report
      |> Enum.map(fn {key, value} -> {to_string(key), value} end)
      |> Map.new()

    package = OperatorReview.from_timeline_feedback_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package
    assert OrbitalDynamics.operator_review_package(string_key_report) == package

    assert %{
             "source_artifact_type" => "timeline_feedback_report.v1",
             "source_artifact_id" => "timeline_feedback_report",
             "review_count" => 4,
             "realized_feedback_count" => 4
           } = package

    assert %{
             "review_type" => "realized_feedback",
             "activity_id" => "obs_1",
             "activity_type" => "observe",
             "approval_status" => "not_required",
             "required_operator_action" => "record_realized_completion",
             "start_delta_s" => 1.0,
             "completed_fraction" => 1.0,
             "thermal_zone_id" => "payload_deck",
             "temperature_c" => 21.5,
             "planned_temperature_c" => 18.0,
             "actual_temperature_c" => 21.5,
             "temperature_delta_c" => 3.5,
             "min_operating_temperature_c" => -5.0,
             "max_operating_temperature_c" => 45.0,
             "thermal_margin_c" => 23.5,
             "thermal_status" => "warm",
             "thermal_model" => "thermal_model:v1",
             "thermal_source" => "realized_activity",
             "thermal_confidence" => 0.8,
             "source_feedback" => %{"activity_id" => "obs_1"}
           } = Enum.find(package["rows"], &(&1["activity_id"] == "obs_1"))

    assert %{
             "activity_id" => "obs_2",
             "required_operator_action" => "review_realized_exception",
             "contact_result" => "accepted,dropped",
             "observation_result" => "started,timeout",
             "reason" => "payload timeout"
           } = Enum.find(package["rows"], &(&1["activity_id"] == "obs_2"))

    assert %{
             "activity_id" => "dl_1",
             "required_operator_action" => "review_missing_realization"
           } = Enum.find(package["rows"], &(&1["activity_id"] == "dl_1"))

    assert %{
             "activity_id" => "unplanned_1",
             "required_operator_action" => "review_unplanned_realization"
           } = Enum.find(package["rows"], &(&1["activity_id"] == "unplanned_1"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from operator-relevant timeline diff rows" do
    report = %{
      "schema_contract" => "timeline_diff_report.v1",
      "model" => "timeline_identity_activity_diff",
      "source" => "repair.activities",
      "source_activity_count" => 2,
      "replacement_activity_count" => 2,
      "row_count" => 2,
      "added_count" => 1,
      "removed_count" => 0,
      "changed_count" => 1,
      "unchanged_count" => 0,
      "review_required_count" => 2,
      "rows" => [
        %{
          "id" => "timeline_diff:timeline:obs_1",
          "rank" => 1,
          "timeline_id" => "timeline:obs_1",
          "diff_status" => "changed",
          "source_activity_id" => "obs_1",
          "replacement_activity_id" => "obs_1b",
          "source_activity_type" => "observe",
          "replacement_activity_type" => "observe",
          "scenario_id" => "leo_1",
          "source_starts_at_s" => 10.0,
          "source_ends_at_s" => 20.0,
          "replacement_starts_at_s" => 12.0,
          "replacement_ends_at_s" => 22.0,
          "start_delta_s" => 2.0,
          "end_delta_s" => 2.0,
          "source_status" => "approved",
          "replacement_status" => "planned",
          "source_approval_status" => "approved",
          "replacement_approval_status" => "pending",
          "source_protection_decision" => %{
            "activity_id" => "obs_1",
            "timeline_id" => "timeline:obs_1",
            "protection_decision" => "preserve",
            "protection_category" => "locked_or_approved",
            "reason" => "activity_locked_or_approved"
          },
          "source_protection_category" => "locked_or_approved",
          "source_protection_reason" => "activity_locked_or_approved",
          "replacement_protection_decision" => %{
            "activity_id" => "obs_1b",
            "timeline_id" => "timeline:obs_1",
            "protection_decision" => "mutable",
            "protection_category" => "none",
            "reason" => "no_timeline_protection"
          },
          "replacement_protection_category" => "none",
          "replacement_protection_reason" => "no_timeline_protection",
          "status_transition" => %{
            "field" => "status",
            "transition_type" => "changed",
            "from" => "approved",
            "to" => "planned"
          },
          "approval_transition" => %{
            "field" => "approval_status",
            "transition_type" => "changed",
            "from" => "approved",
            "to" => "pending"
          },
          "changed_fields" => ["starts_at_s", "ends_at_s", "approval_status"],
          "requires_operator_review" => true,
          "required_operator_action" => "review_timeline_change",
          "reason" => "replacement timeline changes activity obs_1",
          "source_timeline_identity" => %{"timeline_id" => "timeline:obs_1"},
          "replacement_timeline_identity" => %{"timeline_id" => "timeline:obs_1"}
        },
        %{
          "id" => "timeline_diff:timeline:health_1",
          "rank" => 2,
          "timeline_id" => "timeline:health_1",
          "diff_status" => "unchanged",
          "changed_fields" => [],
          "requires_operator_review" => false,
          "required_operator_action" => "none",
          "reason" => "timeline activity unchanged"
        }
      ],
      "assumptions" => %{"execution_boundary" => "artifact_only_no_schedule_mutation"}
    }

    atom_key_report =
      report
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    package = OperatorReview.from_timeline_diff_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package
    assert OrbitalDynamics.operator_review_package(atom_key_report) == package

    assert %{
             "source_artifact_type" => "timeline_diff_report.v1",
             "source_artifact_id" => "repair.activities",
             "review_count" => 1,
             "timeline_diff_count" => 1
           } = package

    assert %{
             "review_type" => "timeline_diff_review",
             "subject_id" => "timeline:obs_1",
             "timeline_id" => "timeline:obs_1",
             "diff_status" => "changed",
             "activity_id" => "obs_1b",
             "source_activity_id" => "obs_1",
             "replacement_activity_id" => "obs_1b",
             "required_operator_action" => "review_timeline_change",
             "operator_action_reason" => "replacement timeline changes activity obs_1",
             "approval_status" => "operator_review_required",
             "changed_fields" => ["starts_at_s", "ends_at_s", "approval_status"],
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "approved",
               "to" => "planned"
             },
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "changed",
               "from" => "approved",
               "to" => "pending"
             },
             "source_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "locked_or_approved"
             },
             "source_protection_category" => "locked_or_approved",
             "source_protection_reason" => "activity_locked_or_approved",
             "replacement_protection_decision" => %{
               "protection_decision" => "mutable",
               "protection_category" => "none"
             },
             "replacement_protection_category" => "none",
             "replacement_protection_reason" => "no_timeline_protection",
             "source_timeline_diff" => %{
               "requires_operator_review" => true
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_timeline_diff =
      update_in(package, ["rows", Access.at(0), "source_timeline_diff"], fn row ->
        row
        |> Map.put("changed_fields", ["stale_changed_field"])
        |> Map.put("requires_operator_review", false)
      end)

    assert {:error, stale_source_timeline_diff_report} =
             Schema.validate_artifact(stale_source_timeline_diff)

    assert Enum.any?(
             stale_source_timeline_diff_report["errors"],
             &(&1["path"] == "$.rows[0].changed_fields" and
                 &1["message"] == "must match source_timeline_diff.changed_fields")
           )

    assert Enum.any?(
             stale_source_timeline_diff_report["errors"],
             &(&1["path"] == "$.rows[0].requires_operator_review" and
                 &1["message"] == "must match source_timeline_diff.requires_operator_review")
           )
  end

  test "builds review package from transition application report review rows" do
    source = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :obs_self_dependency,
        type: :observe,
        target_id: :target_a,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        depends_on: [:obs_self_dependency],
        metadata: %{timeline_id: :"timeline:obs_self_dependency"}
      }
    ]

    replacement = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 15.0,
        ends_at_s: 25.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :cmd_added,
        type: :command,
        starts_at_s: 40.0,
        ends_at_s: 50.0,
        metadata: %{timeline_id: :"timeline:cmd_added"}
      },
      %{
        id: :obs_self_dependency,
        type: :observe,
        target_id: :target_a,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        depends_on: [:obs_self_dependency],
        metadata: %{timeline_id: :"timeline:obs_self_dependency"}
      }
    ]

    report =
      OrbitalDynamics.Timeline.transition_application_report(source, replacement,
        source: "timeline_transition_application_report"
      )

    approval_policy = %{
      action_rules: [
        %{
          id: "transition_application_preserve_review",
          application_status: "source_preserved_pending_review",
          classification: "operator_review_required",
          reason: "source-preserved transition application requires mission planning review",
          escalation_queue: "mission_planning",
          required_authority: "mission_planning_authority",
          sla_s: 900
        }
      ]
    }

    package =
      OrbitalDynamics.operator_review_package(report, approval_policy: approval_policy)

    assert %{
             "source_artifact_type" => "timeline_transition_application_report.v1",
             "source_artifact_id" => "timeline_transition_application_report",
             "review_count" => 3,
             "timeline_diff_count" => 3
           } = package

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "timeline_transition_application_report.applications",
             "timeline_id" => "timeline:cmd_lock",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{
               "activity_id" => "cmd_lock",
               "starts_at_s" => 10.0
             },
             "policy_classification" => "operator_review_required",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "transition_application_preserve_review",
                 "classification" => "operator_review_required",
                 "application_status" => "source_preserved_pending_review",
                 "escalation_queue" => "mission_planning",
                 "required_authority" => "mission_planning_authority"
               }
             ],
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "classification" => "operator_review_required"
             },
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review"
             },
             "source_timeline_diff" => %{
               "requires_operator_review" => true,
               "application_status" => "source_preserved_pending_review"
             }
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert %{
             "timeline_id" => "timeline:cmd_added",
             "application_status" => "operator_review_required",
             "replacement_activity_type" => "command",
             "status_transition" => %{
               "transition_type" => "added",
               "transition_category" => "status_added"
             },
             "approval_transition" => %{
               "transition_type" => "added",
               "transition_category" => "approval_review_required"
             },
             "source_timeline_application" => %{
               "status_transition" => %{"transition_category" => "status_added"},
               "approval_transition" => %{"transition_category" => "approval_review_required"}
             },
             "source_timeline_diff" => %{
               "status_transition" => %{"transition_type" => "added"},
               "approval_transition" => %{"transition_type" => "added"}
             }
           } = added = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:cmd_added"))

    refute Map.has_key?(added, "selected_activity")

    assert %{
             "timeline_id" => "timeline:obs_self_dependency",
             "application_status" => "operator_review_required",
             "required_operator_action" => "review_timeline_integrity",
             "source_timeline_integrity_issue_types" => ["self_dependency_activity"],
             "source_self_dependency_activity_ids" => ["obs_self_dependency"],
             "replacement_timeline_integrity_issue_types" => ["self_dependency_activity"],
             "replacement_self_dependency_activity_ids" => ["obs_self_dependency"],
             "source_timeline_application" => %{
               "source_timeline_diff" => %{
                 "source_self_dependency_activity_ids" => ["obs_self_dependency"],
                 "replacement_self_dependency_activity_ids" => ["obs_self_dependency"]
               }
             },
             "source_timeline_diff" => %{
               "source_self_dependency_activity_ids" => ["obs_self_dependency"],
               "replacement_self_dependency_activity_ids" => ["obs_self_dependency"]
             }
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:obs_self_dependency"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "lifecycle transition application provenance survives review and import handoff" do
    source_activity = %{
      id: :cmd_lifecycle_complete,
      type: :command,
      status: "In Progress",
      approval_status: :pending,
      dependencies: [:missing_gate],
      metadata: %{timeline_id: :"timeline:cmd_lifecycle_complete"}
    }

    {:ok, replacement_activity} =
      Timeline.apply_lifecycle_event(source_activity, "record completion")

    report =
      Timeline.transition_application_report([source_activity], [replacement_activity],
        source: "timeline_transition_application_report"
      )

    assert [
             %{
               "application_status" => "selected_timeline_integrity_review_required",
               "requires_operator_review" => true,
               "transition_application_provenance" => provenance,
               "selected_activity" => %{
                 "transition_application_provenance" => selected_provenance,
                 "activity_context" => %{
                   "transition_application_provenance" => context_provenance
                 }
               }
             }
           ] = report["applications"]

    assert selected_provenance == provenance
    assert context_provenance == provenance

    assert %{
             "helper" => "apply_lifecycle_event",
             "operator_action_reason" => "activity_execution_recorded",
             "transition_category" => "execution_recorded",
             "transition_type" => "changed",
             "requires_operator_review" => false
           } = provenance

    package = OperatorReview.from_timeline_transition_application_report(report)

    assert %{
             "review_count" => 1,
             "rows" => [
               %{
                 "application_status" => "selected_timeline_integrity_review_required",
                 "required_operator_action" => "review_timeline_integrity",
                 "transition_application_provenance" => ^provenance,
                 "selected_activity" => %{
                   "activity_context" => %{
                     "transition_application_provenance" => ^provenance
                   }
                 },
                 "source_timeline_application" => %{
                   "transition_application_provenance" => ^provenance,
                   "selected_activity" => %{
                     "transition_application_provenance" => ^provenance
                   }
                 },
                 "source_timeline_diff" => %{
                   "transition_application_provenance" => ^provenance
                 }
               }
             ]
           } = package

    manifest = CadenceImport.from_timeline_transition_application_report(report)

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "review_required_count" => 1,
             "rows" => [
               %{
                 "application_status" => "selected_timeline_integrity_review_required",
                 "import_status" => "review_required_before_import",
                 "transition_application_provenance" => ^provenance,
                 "source_review_row" => %{
                   "transition_application_provenance" => ^provenance
                 },
                 "source_timeline_application" => %{
                   "transition_application_provenance" => ^provenance
                 }
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "timeline transition application summaries become operator review rows" do
    summary = timeline_transition_application_summary()
    package = OperatorReview.from_timeline_transition_application_summary(summary)

    atom_key_summary =
      summary
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_transition_application_summary.v1",
             "source_artifact_id" => "transition_summary_source",
             "review_count" => 3,
             "timeline_diff_count" => 3,
             "required_operator_action_counts" => %{
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1,
               "review_timeline_integrity" => 1
             }
           } = package

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "timeline_transition_application_summary.review_applications",
             "timeline_id" => "timeline:cmd_lock",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "source_transition_application_count" => 3,
             "source_transition_application_review_required_count" => 3,
             "source_transition_application_selected_activity_ids" => ["cmd_lock"],
             "source_transition_application_review_activity_ids" => [
               "cmd_added",
               "cmd_lock",
               "obs_self_dependency"
             ],
             "source_transition_application_review_timeline_ids" => [
               "timeline:cmd_added",
               "timeline:cmd_lock",
               "timeline:obs_self_dependency"
             ],
             "source_transition_application_preserved_source_timeline_ids" => [
               "timeline:cmd_lock"
             ],
             "source_timeline_transition_application_summary" => %{
               "model" => "artifact_only_timeline_transition_application_summary",
               "review_required_count" => 3,
               "review_activity_ids" => ["cmd_added", "cmd_lock", "obs_self_dependency"],
               "selected_activity_ids" => ["cmd_lock"]
             },
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review"
             }
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert %{
             "timeline_id" => "timeline:obs_self_dependency",
             "required_operator_action" => "review_timeline_integrity",
             "source_self_dependency_activity_ids" => ["obs_self_dependency"],
             "replacement_self_dependency_activity_ids" => ["obs_self_dependency"],
             "source_timeline_application" => %{
               "source_timeline_diff" => %{
                 "source_self_dependency_activity_ids" => ["obs_self_dependency"]
               }
             }
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:obs_self_dependency"))

    assert OrbitalDynamics.operator_review_package(summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(summary, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_summary, :schema_contract)) ==
             package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_summary_ids =
      put_in(
        package,
        [
          "rows",
          Access.at(0),
          "source_timeline_transition_application_summary",
          "selected_activity_ids"
        ],
        ["bad activity id"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_source_summary_ids)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_transition_application_summary.selected_activity_ids[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "CandidateRefresh lifts transition application summaries from direct and result artifacts" do
    direct_summary =
      timeline_transition_application_summary()
      |> Map.put("source", "transition_summary_direct")

    source_result_summary =
      timeline_transition_application_summary()
      |> Map.put("source", "transition_summary_source_result")

    nested_summary =
      timeline_transition_application_summary()
      |> Map.put("source", "transition_summary_nested_result")

    artifact = %{
      "refresh_id" => "refresh:transition_summary_result_handoff",
      "timeline_transition_application_summary" => direct_summary,
      "source_result_artifact" => [source_result_summary],
      "result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "timeline_transition_application_summary" => nested_summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    transition_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_timeline_transition_application_summary"]["schema_contract"] ==
            "timeline_transition_application_summary.v1")
      )

    assert length(transition_rows) == 9

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:transition_summary_result_handoff",
             "review_count" => 9,
             "timeline_diff_count" => 9,
             "required_operator_action_counts" => %{
               "review_added_activity" => 3,
               "review_changed_protected_activity" => 3,
               "review_timeline_integrity" => 3
             }
           } = review

    assert Enum.sort(Enum.map(transition_rows, & &1["source"])) == [
             "candidate_refresh.result_artifact.timeline_transition_application_summary.review_applications",
             "candidate_refresh.result_artifact.timeline_transition_application_summary.review_applications",
             "candidate_refresh.result_artifact.timeline_transition_application_summary.review_applications",
             "candidate_refresh.source_result_artifact[0].review_applications",
             "candidate_refresh.source_result_artifact[0].review_applications",
             "candidate_refresh.source_result_artifact[0].review_applications",
             "candidate_refresh.timeline_transition_application_summary.review_applications",
             "candidate_refresh.timeline_transition_application_summary.review_applications",
             "candidate_refresh.timeline_transition_application_summary.review_applications"
           ]

    assert Enum.all?(
             transition_rows,
             &(&1["source_transition_application_count"] == 3 and
                 &1["source_timeline_transition_application_summary"]["model"] ==
                   "artifact_only_timeline_transition_application_summary")
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(get_in(&1, [
            "source_review_row",
            "source_timeline_transition_application_summary",
            "schema_contract"
          ]) == "timeline_transition_application_summary.v1")
      )

    assert length(import_rows) == 9

    assert Enum.all?(
             import_rows,
             &(get_in(&1, [
                 "source_review_row",
                 "source_timeline_transition_application_summary",
                 "schema_contract"
               ]) == "timeline_transition_application_summary.v1" and
                 is_map(&1["source_review_row"]["source_timeline_application"]))
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts all nested transition application source paths" do
    report = %{
      "schema_contract" => "timeline_transition_application_report.v1",
      "source" => "nested.timeline_transition_application_report",
      "applications" => [
        %{
          "id" => "timeline_transition_application:timeline:cmd_nested_transition",
          "rank" => 1,
          "timeline_id" => "timeline:cmd_nested_transition",
          "diff_status" => "added",
          "changed_fields" => ["activity_added"],
          "transition_decision" => "review",
          "application_status" => "operator_review_required",
          "selected_activity_source" => "replacement",
          "selected_activity" => %{
            "activity_id" => "cmd_nested_transition",
            "starts_at_s" => 40.0,
            "ends_at_s" => 50.0
          },
          "requires_operator_review" => true,
          "required_operator_action" => "review_timeline_change",
          "reason" => "replacement timeline adds command activity cmd_nested_transition",
          "source_timeline_diff" => %{
            "id" => "timeline_diff:timeline:cmd_nested_transition",
            "rank" => 1,
            "timeline_id" => "timeline:cmd_nested_transition",
            "diff_status" => "added",
            "replacement_activity_id" => "cmd_nested_transition",
            "replacement_activity_type" => "command",
            "changed_fields" => ["activity_added"],
            "requires_operator_review" => true,
            "required_operator_action" => "review_timeline_change",
            "reason" => "replacement timeline adds command activity cmd_nested_transition"
          }
        }
      ]
    }

    summary =
      timeline_transition_application_summary()
      |> Map.put("source", "nested.timeline_transition_application_summary")

    cases = [
      {"accepted_planning_state", "source_timeline_transition_application_report", report,
       ".applications", 1, "source_timeline_application"},
      {"accepted_planning_state", "timeline_transition_application_report", report,
       ".applications", 1, "source_timeline_application"},
      {"mission_state", "source_timeline_transition_application_report", report, ".applications",
       1, "source_timeline_application"},
      {"mission_state", "timeline_transition_application_report", report, ".applications", 1,
       "source_timeline_application"},
      {"accepted_planning_state", "source_timeline_transition_application_summary", summary,
       ".review_applications", 3, "source_timeline_transition_application_summary"},
      {"accepted_planning_state", "timeline_transition_application_summary", summary,
       ".review_applications", 3, "source_timeline_transition_application_summary"},
      {"mission_state", "source_timeline_transition_application_summary", summary,
       ".review_applications", 3, "source_timeline_transition_application_summary"},
      {"mission_state", "timeline_transition_application_summary", summary,
       ".review_applications", 3, "source_timeline_transition_application_summary"}
    ]

    Enum.each(cases, fn {state_key, field, payload, source_suffix, expected_count,
                         source_payload_key} ->
      source = "candidate_refresh.#{state_key}.#{field}#{source_suffix}"

      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "refresh_id" => "refresh:#{state_key}:#{field}",
        state_key => %{field => payload}
      }

      review = OperatorReview.from_candidate_refresh_artifact(artifact)
      import = CadenceImport.from_candidate_refresh_artifact(artifact)

      rows = Enum.filter(review["rows"], &(&1["source"] == source))

      import_rows =
        Enum.filter(import["rows"], &(get_in(&1, ["source_review_row", "source"]) == source))

      assert length(rows) == expected_count
      assert length(import_rows) == expected_count

      assert %{
               "review_count" => ^expected_count,
               "timeline_diff_count" => ^expected_count
             } = review

      assert %{"row_count" => ^expected_count} = import

      assert Enum.all?(rows, &(&1["review_type"] == "timeline_diff_review"))
      assert Enum.all?(rows, &is_map(&1[source_payload_key]))
      assert Enum.all?(import_rows, &(&1["source_review_type"] == "timeline_diff_review"))

      assert Enum.all?(
               import_rows,
               &is_map(get_in(&1, ["source_review_row", source_payload_key]))
             )
    end)

    wrapped_cases = [
      {%{"source_result_artifact" => [report]},
       "candidate_refresh.source_result_artifact[0].applications"},
      {%{
         "result_artifact" => %{
           "schema_contract" => "result_artifact.v1",
           "timeline_transition_application_report" => report
         }
       }, "candidate_refresh.result_artifact.timeline_transition_application_report.applications"}
    ]

    Enum.each(wrapped_cases, fn {artifact_fields, source} ->
      artifact =
        Map.merge(
          %{
            "schema_contract" => "candidate_refresh.v1",
            "refresh_id" => "refresh:wrapped_transition_application_report"
          },
          artifact_fields
        )

      review = OperatorReview.from_candidate_refresh_artifact(artifact)
      import = CadenceImport.from_candidate_refresh_artifact(artifact)

      assert [
               %{
                 "review_type" => "timeline_diff_review",
                 "source" => ^source,
                 "timeline_id" => "timeline:cmd_nested_transition",
                 "source_timeline_application" => %{
                   "application_status" => "operator_review_required"
                 }
               }
             ] = review["rows"]

      assert [
               %{
                 "source_review_type" => "timeline_diff_review",
                 "source_review_row" => %{
                   "source" => ^source,
                   "source_timeline_application" => %{
                     "application_status" => "operator_review_required"
                   }
                 }
               }
             ] = import["rows"]
    end)
  end

  test "timeline diff summaries become operator review rows" do
    summary = timeline_diff_summary()
    package = OperatorReview.from_timeline_diff_summary(summary)

    atom_key_summary =
      summary
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_diff_summary.v1",
             "source_artifact_id" => "diff_summary_source",
             "review_count" => 3,
             "timeline_diff_count" => 3,
             "required_operator_action_counts" => %{
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1,
               "review_removed_activity" => 1
             }
           } = package

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "timeline_diff_summary.review_rows",
             "timeline_id" => "timeline:cmd_lock",
             "diff_status" => "changed",
             "transition_decision" => "preserve_source",
             "source_timeline_diff_summary_row_count" => 3,
             "source_timeline_diff_summary_review_required_count" => 3,
             "source_timeline_diff_summary_changed_count" => 1,
             "source_timeline_diff_summary_changed_field_counts" => %{
               "ends_at_s" => 1,
               "starts_at_s" => 1
             },
             "source_timeline_diff_summary_review_timeline_ids" => [
               "timeline:cmd_added",
               "timeline:cmd_lock",
               "timeline:dl_removed"
             ],
             "source_timeline_diff_summary_timeline_ids_by_changed_field" => %{
               "ends_at_s" => ["timeline:cmd_lock"],
               "starts_at_s" => ["timeline:cmd_lock"]
             },
             "source_timeline_diff_summary" => %{
               "model" => "artifact_only_timeline_diff_summary",
               "review_required_count" => 3
             },
             "source_timeline_diff" => %{
               "requires_operator_review" => true
             }
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert %{
             "timeline_id" => "timeline:cmd_added",
             "diff_status" => "added",
             "required_operator_action" => "review_added_activity"
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:cmd_added"))

    assert OrbitalDynamics.operator_review_package(summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(summary, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_summary, :schema_contract)) ==
             package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_summary_ids =
      put_in(
        package,
        [
          "rows",
          Access.at(0),
          "source_timeline_diff_summary",
          "review_timeline_ids"
        ],
        ["bad timeline id"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_source_summary_ids)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_diff_summary.review_timeline_ids[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "CandidateRefresh lifts timeline diff summaries from direct and result artifacts" do
    direct_summary =
      timeline_diff_summary()
      |> Map.put("source", "diff_summary_direct")

    source_result_summary =
      timeline_diff_summary()
      |> Map.put("source", "diff_summary_source_result")

    nested_summary =
      timeline_diff_summary()
      |> Map.put("source", "diff_summary_nested_result")

    artifact = %{
      "refresh_id" => "refresh:diff_summary_result_handoff",
      "timeline_diff_summary" => direct_summary,
      "source_result_artifact" => [source_result_summary],
      "result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "timeline_diff_summary" => nested_summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    diff_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_timeline_diff_summary"]["schema_contract"] == "timeline_diff_summary.v1")
      )

    assert length(diff_rows) == 9

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:diff_summary_result_handoff",
             "review_count" => 9,
             "timeline_diff_count" => 9,
             "required_operator_action_counts" => %{
               "review_added_activity" => 3,
               "review_changed_protected_activity" => 3,
               "review_removed_activity" => 3
             }
           } = review

    assert Enum.sort(Enum.map(diff_rows, & &1["source"])) == [
             "candidate_refresh.result_artifact.timeline_diff_summary.review_rows",
             "candidate_refresh.result_artifact.timeline_diff_summary.review_rows",
             "candidate_refresh.result_artifact.timeline_diff_summary.review_rows",
             "candidate_refresh.source_result_artifact[0].review_rows",
             "candidate_refresh.source_result_artifact[0].review_rows",
             "candidate_refresh.source_result_artifact[0].review_rows",
             "candidate_refresh.timeline_diff_summary.review_rows",
             "candidate_refresh.timeline_diff_summary.review_rows",
             "candidate_refresh.timeline_diff_summary.review_rows"
           ]

    assert Enum.all?(
             diff_rows,
             &(&1["source_timeline_diff_summary_review_required_count"] == 3 and
                 &1["source_timeline_diff_summary"]["model"] ==
                   "artifact_only_timeline_diff_summary")
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(get_in(&1, [
            "source_review_row",
            "source_timeline_diff_summary",
            "schema_contract"
          ]) == "timeline_diff_summary.v1")
      )

    assert length(import_rows) == 9

    assert Enum.all?(
             import_rows,
             &(get_in(&1, [
                 "source_review_row",
                 "source_timeline_diff_summary",
                 "review_required_count"
               ]) == 3)
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts accepted planning state timeline diff summaries" do
    summary =
      timeline_diff_summary()
      |> Map.put("source", "diff_summary_accepted_state")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_timeline_diff_summary_handoff",
      "accepted_planning_state" => %{
        "source_timeline_diff_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    diff_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_timeline_diff_summary"]["schema_contract"] == "timeline_diff_summary.v1")
      )

    assert length(diff_rows) == 3

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_timeline_diff_summary_handoff",
             "review_count" => 3,
             "timeline_diff_count" => 3,
             "required_operator_action_counts" => %{
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1,
               "review_removed_activity" => 1
             }
           } = review

    assert Enum.map(diff_rows, & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_timeline_diff_summary.review_rows",
             "candidate_refresh.accepted_planning_state.source_timeline_diff_summary.review_rows",
             "candidate_refresh.accepted_planning_state.source_timeline_diff_summary.review_rows"
           ]

    assert %{
             "review_type" => "timeline_diff_review",
             "source" =>
               "candidate_refresh.accepted_planning_state.source_timeline_diff_summary.review_rows",
             "timeline_id" => "timeline:cmd_lock",
             "diff_status" => "changed",
             "transition_decision" => "preserve_source",
             "source_timeline_diff_summary_review_required_count" => 3,
             "source_timeline_diff_summary_changed_count" => 1,
             "source_timeline_diff_summary" => %{
               "schema_contract" => "timeline_diff_summary.v1",
               "model" => "artifact_only_timeline_diff_summary",
               "source" => "diff_summary_accepted_state",
               "review_required_count" => 3
             },
             "source_timeline_diff" => %{
               "requires_operator_review" => true
             }
           } = Enum.find(diff_rows, &(&1["timeline_id"] == "timeline:cmd_lock"))

    import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "timeline_diff_review"))

    assert length(import_rows) == 3

    assert %{
             "row_count" => 3,
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "source_review_type_counts" => %{"timeline_diff_review" => 3}
           } = import

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_type" => "timeline_diff_review",
             "timeline_id" => "timeline:cmd_lock",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_timeline_diff_summary.review_rows",
               "source_timeline_diff_summary" => %{
                 "schema_contract" => "timeline_diff_summary.v1",
                 "source" => "diff_summary_accepted_state"
               }
             }
           } = Enum.find(import_rows, &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state timeline diff summaries" do
    summary =
      timeline_diff_summary()
      |> Map.put("source", "diff_summary_mission_state")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_timeline_diff_summary_handoff",
      "mission_state" => %{
        "timeline_diff_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    diff_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_timeline_diff_summary"]["schema_contract"] == "timeline_diff_summary.v1")
      )

    assert length(diff_rows) == 3

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_timeline_diff_summary_handoff",
             "review_count" => 3,
             "timeline_diff_count" => 3
           } = review

    assert Enum.map(diff_rows, & &1["source"]) == [
             "candidate_refresh.mission_state.timeline_diff_summary.review_rows",
             "candidate_refresh.mission_state.timeline_diff_summary.review_rows",
             "candidate_refresh.mission_state.timeline_diff_summary.review_rows"
           ]

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "candidate_refresh.mission_state.timeline_diff_summary.review_rows",
             "timeline_id" => "timeline:dl_removed",
             "diff_status" => "removed",
             "required_operator_action" => "review_removed_activity",
             "source_timeline_diff_summary_row_count" => 3,
             "source_timeline_diff_summary" => %{
               "schema_contract" => "timeline_diff_summary.v1",
               "source" => "diff_summary_mission_state",
               "removed_count" => 1
             }
           } = Enum.find(diff_rows, &(&1["timeline_id"] == "timeline:dl_removed"))

    assert %{
             "row_count" => 3,
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "source_review_type_counts" => %{"timeline_diff_review" => 3}
           } = import

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_type" => "timeline_diff_review",
             "timeline_id" => "timeline:dl_removed",
             "source_review_row" => %{
               "source" => "candidate_refresh.mission_state.timeline_diff_summary.review_rows",
               "source_timeline_diff_summary" => %{
                 "schema_contract" => "timeline_diff_summary.v1",
                 "source" => "diff_summary_mission_state"
               }
             }
           } = Enum.find(import["rows"], &(&1["timeline_id"] == "timeline:dl_removed"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline transition packages reject stale source application evidence" do
    source = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      }
    ]

    replacement = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 15.0,
        ends_at_s: 25.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      }
    ]

    package =
      source
      |> OrbitalDynamics.Timeline.transition_application_report(replacement,
        source: "timeline_transition_application_report"
      )
      |> OperatorReview.from_timeline_transition_application_report()
      |> update_in(["rows", Access.at(0), "source_timeline_application"], fn source_row ->
        Map.put(source_row, "application_status", "operator_review_required")
      end)

    assert {:error, stale_source_report} = Schema.validate_artifact(package)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].application_status" and
                 &1["message"] ==
                   "must match source_timeline_application.application_status")
           )
  end

  test "builds review package from operator-relevant operational timeline rows" do
    report =
      OrbitalDynamics.operational_timeline_report(
        [
          %{
            "id" => "cmd_1",
            "timeline_id" => "timeline:cmd_1",
            "type" => "command",
            "scenario_id" => "leo_1",
            "starts_at_s" => 30.0,
            "ends_at_s" => 40.0,
            "status" => "planned",
            "approval_status" => "pending",
            "direction" => "command",
            "ground_station_id" => "dss_14",
            "source_window_id" => "cmd_window_1",
            "activity_template" => %{
              "schema_contract" => "activity_template.v1",
              "id" => "template:command:ops",
              "activity_type" => "command",
              "operational_hints" => %{
                "setup_duration_s" => 15.0,
                "cooldown_duration_s" => 5.0,
                "telemetry_confirmation_required" => true,
                "telemetry_confirmation_status" => "required"
              }
            },
            "dependencies" => ["health_1"],
            "dependency_timeline_ids" => ["timeline:health_1"],
            "exclusive_with_activity_ids" => ["command_chain"],
            "exclusive_with_timeline_ids" => ["timeline:command_chain"],
            "pointing_mode" => "target_track",
            "pointing_target_id" => "target_a",
            "boresight_axis" => "+Z",
            "off_nadir_angle_deg" => 12.0,
            "slew_angle_deg" => 4.0,
            "slew_rate_deg_s" => 0.2,
            "pointing_error_deg" => 0.05,
            "pointing_status" => "within_tolerance",
            "pointing_model" => "attitude_solver:v2",
            "pointing_source" => "mission_plan",
            "pointing_confidence" => 0.92,
            "attitude_mode" => "nadir_track",
            "attitude_target_id" => "target_a",
            "roll_deg" => 1.0,
            "pitch_deg" => -2.0,
            "yaw_deg" => 3.0,
            "attitude_error_deg" => 0.08,
            "attitude_status" => "stable",
            "attitude_model" => "attitude_solver:v2",
            "attitude_source" => "mission_plan",
            "attitude_confidence" => 0.91,
            "link_protocol" => "ccsds",
            "frequency_band" => "x_band",
            "modulation" => "qpsk",
            "coding_scheme" => "ldpc",
            "polarization" => "rhcp",
            "data_rate_mbps" => 12.0,
            "downlink_rate_mbps" => 10.0,
            "data_rate_mb_s" => 1.5,
            "downlink_rate_mb_s" => 1.25,
            "actual_data_rate_mbps" => 9.6,
            "actual_downlink_rate_mbps" => 9.2,
            "actual_data_rate_mb_s" => 1.2,
            "actual_downlink_rate_mb_s" => 1.15,
            "delivered_rate_mbps" => 9.0,
            "received_rate_mbps" => 8.8,
            "delivered_rate_mb_s" => 1.125,
            "received_rate_mb_s" => 1.1,
            "actual_duration_s" => 9.5,
            "actual_contact_duration_s" => 9.0,
            "contact_duration_s" => 10.0,
            "link_margin_db" => 4.5,
            "snr_db" => 12.0,
            "eb_no_db" => 8.5,
            "bit_error_rate" => 1.0e-6,
            "packet_loss_rate" => 0.01,
            "frame_loss_rate" => 0.02,
            "carrier_lock" => true,
            "symbol_lock" => true,
            "link_quality_status" => "nominal",
            "eclipse_overlap_fraction" => 0.4,
            "eclipse_overlap_s" => 24.0,
            "lighting_condition" => "partial_eclipse",
            "lighting_condition_detail" => "mixed_lighting",
            "lighting_condition_model" => "sampled_eclipse_overlap_tag",
            "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
            "lighting_confidence" => 0.82,
            "image_quality_score" => 0.87,
            "image_quality_status" => "usable",
            "image_quality_source" => "payload_processor",
            "cloud_cover_fraction" => 0.12,
            "blur_score" => 0.05,
            "feedback_weight" => 0.7,
            "feedback_weight_source" => "operator_tuning",
            "maneuver_success" => true,
            "maneuver_result" => ["completed", "within_tolerance"],
            "thermal_zone_id" => "payload_deck",
            "temperature_c" => 21.5,
            "planned_temperature_c" => 18.0,
            "actual_temperature_c" => 21.5,
            "temperature_delta_c" => 3.5,
            "min_operating_temperature_c" => -5.0,
            "max_operating_temperature_c" => 45.0,
            "thermal_margin_c" => 23.5,
            "thermal_status" => "warm",
            "thermal_model" => "thermal_model:v1",
            "thermal_source" => "mission_plan",
            "thermal_confidence" => 0.8,
            "cadence_import" => %{
              "external_id" => "cadence_cmd_1",
              "activity_type" => "command_window",
              "schema_contract" => "command_window.v1"
            }
          },
          %{
            "id" => "dl_1",
            "timeline_id" => "timeline:dl_1",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "starts_at_s" => 50.0,
            "ends_at_s" => 60.0,
            "status" => "planned",
            "approval_status" => "approved",
            "direction" => "downlink",
            "ground_station_id" => "dss_14"
          },
          %{
            "id" => "obs_1",
            "timeline_id" => "timeline:obs_1",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 70.0,
            "ends_at_s" => 80.0,
            "status" => "planned",
            "approval_status" => "approved",
            "target_id" => "target_a"
          }
        ],
        source: "mission_plan.activities"
      )
      |> update_in(["rows", Access.at(0)], fn row ->
        row
        |> Map.put("contact_result", ["accepted", "DROPPED"])
        |> Map.put("command_result", [:accepted, :rejected])
        |> Map.update("activity_context", %{}, fn context ->
          Map.merge(context, %{
            "contact_result" => ["accepted", "DROPPED"],
            "command_result" => [:accepted, :rejected]
          })
        end)
      end)

    package = OperatorReview.from_operational_timeline_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "operational_timeline_report.v1",
             "source_artifact_id" => "mission_plan.activities",
             "review_count" => 2,
             "operational_timeline_count" => 2,
             "cadence_import_status_counts" => %{"missing" => 1, "present" => 1}
           } = package

    assert %{
             "review_type" => "operational_timeline_review",
             "source" => "operational_timeline_report.rows",
             "subject_id" => "timeline:cmd_1",
             "activity_id" => "cmd_1",
             "timeline_id" => "timeline:cmd_1",
             "operational_kind" => "command",
             "required_operator_action" => "review_command_contact",
             "approval_status" => "operator_review_required",
             "source_approval_status" => "pending",
             "cadence_import_status" => "present",
             "cadence_import_type" => "command_window",
             "cadence_import_id" => "cadence_cmd_1",
             "cadence_import_contract" => "command_window.v1",
             "contact_result" => "accepted,DROPPED",
             "command_result" => "accepted,rejected",
             "dependency_activity_ids" => ["health_1"],
             "dependency_timeline_ids" => ["timeline:health_1"],
             "exclusive_with_activity_ids" => ["command_chain"],
             "exclusive_with_timeline_ids" => ["timeline:command_chain"],
             "pointing_mode" => "target_track",
             "pointing_target_id" => "target_a",
             "boresight_axis" => "+Z",
             "off_nadir_angle_deg" => 12.0,
             "slew_angle_deg" => 4.0,
             "slew_rate_deg_s" => 0.2,
             "pointing_error_deg" => 0.05,
             "pointing_status" => "within_tolerance",
             "pointing_model" => "attitude_solver:v2",
             "pointing_source" => "mission_plan",
             "pointing_confidence" => 0.92,
             "attitude_mode" => "nadir_track",
             "attitude_target_id" => "target_a",
             "roll_deg" => 1.0,
             "pitch_deg" => -2.0,
             "yaw_deg" => 3.0,
             "attitude_error_deg" => 0.08,
             "attitude_status" => "stable",
             "attitude_model" => "attitude_solver:v2",
             "attitude_source" => "mission_plan",
             "attitude_confidence" => 0.91,
             "setup_duration_s" => 15.0,
             "cooldown_duration_s" => 5.0,
             "telemetry_confirmation_required" => true,
             "telemetry_confirmation_status" => "required",
             "link_protocol" => "ccsds",
             "frequency_band" => "x_band",
             "modulation" => "qpsk",
             "coding_scheme" => "ldpc",
             "polarization" => "rhcp",
             "data_rate_mbps" => 12.0,
             "downlink_rate_mbps" => 10.0,
             "data_rate_mb_s" => 1.5,
             "downlink_rate_mb_s" => 1.25,
             "actual_data_rate_mbps" => 9.6,
             "actual_downlink_rate_mbps" => 9.2,
             "actual_data_rate_mb_s" => 1.2,
             "actual_downlink_rate_mb_s" => 1.15,
             "delivered_rate_mbps" => 9.0,
             "received_rate_mbps" => 8.8,
             "delivered_rate_mb_s" => 1.125,
             "received_rate_mb_s" => 1.1,
             "actual_duration_s" => 9.5,
             "actual_contact_duration_s" => 9.0,
             "contact_duration_s" => 10.0,
             "link_margin_db" => 4.5,
             "snr_db" => 12.0,
             "eb_no_db" => 8.5,
             "bit_error_rate" => 1.0e-6,
             "packet_loss_rate" => 0.01,
             "frame_loss_rate" => 0.02,
             "carrier_lock" => true,
             "symbol_lock" => true,
             "link_quality_status" => "nominal",
             "eclipse_overlap_fraction" => 0.4,
             "eclipse_overlap_s" => 24.0,
             "lighting_condition" => "partial_eclipse",
             "lighting_condition_detail" => "mixed_lighting",
             "lighting_condition_model" => "sampled_eclipse_overlap_tag",
             "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
             "lighting_confidence" => 0.82,
             "image_quality_score" => 0.87,
             "image_quality_status" => "usable",
             "image_quality_source" => "payload_processor",
             "cloud_cover_fraction" => 0.12,
             "blur_score" => 0.05,
             "feedback_weight" => 0.7,
             "feedback_weight_source" => "operator_tuning",
             "maneuver_success" => true,
             "maneuver_result" => "completed,within_tolerance",
             "thermal_zone_id" => "payload_deck",
             "temperature_c" => 21.5,
             "planned_temperature_c" => 18.0,
             "actual_temperature_c" => 21.5,
             "temperature_delta_c" => 3.5,
             "min_operating_temperature_c" => -5.0,
             "max_operating_temperature_c" => 45.0,
             "thermal_margin_c" => 23.5,
             "thermal_status" => "warm",
             "thermal_model" => "thermal_model:v1",
             "thermal_source" => "mission_plan",
             "thermal_confidence" => 0.8,
             "source_activity_context" => %{
               "contact_result" => "accepted,DROPPED",
               "command_result" => "accepted,rejected",
               "setup_duration_s" => 15.0,
               "cooldown_duration_s" => 5.0,
               "telemetry_confirmation_required" => true,
               "telemetry_confirmation_status" => "required",
               "lighting_condition" => "partial_eclipse",
               "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
               "lighting_confidence" => 0.82
             },
             "source_operational_timeline" => %{"activity_id" => "cmd_1"}
           } = List.first(package["rows"])

    assert %{
             "review_type" => "operational_timeline_review",
             "activity_id" => "dl_1",
             "required_operator_action" => "prepare_cadence_import",
             "cadence_import_status" => "missing"
           } = Enum.find(package["rows"], &(&1["activity_id"] == "dl_1"))

    refute Enum.any?(package["rows"], &(&1["activity_id"] == "obs_1"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_operational_timeline =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "operational_timeline_review", "source_operational_timeline" => %{}} =
              row ->
            row
            |> put_in(["source_operational_timeline", "activity_id"], "stale_cmd")
            |> put_in(["source_operational_timeline", "timeline_id"], "timeline:stale_cmd")

          row ->
            row
        end)
      end)

    assert {:error, stale_source_operational_timeline_report} =
             Schema.validate_artifact(stale_source_operational_timeline)

    assert Enum.any?(
             stale_source_operational_timeline_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.activity_id$/ and
                 &1["message"] == "must match source_operational_timeline.activity_id")
           )

    assert Enum.any?(
             stale_source_operational_timeline_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.timeline_id$/ and
                 &1["message"] == "must match source_operational_timeline.timeline_id")
           )
  end

  test "normalizes map-valued provider results in operational timeline review rows" do
    report =
      OrbitalDynamics.operational_timeline_report(
        [
          %{
            "id" => "cmd_provider_map",
            "timeline_id" => "timeline:cmd_provider_map",
            "type" => "command",
            "scenario_id" => "leo_1",
            "starts_at_s" => 30.0,
            "ends_at_s" => 40.0,
            "status" => "planned",
            "approval_status" => "pending",
            "direction" => "command",
            "ground_station_id" => "dss_14",
            "cadence_import" => %{
              "external_id" => "cadence_cmd_provider_map",
              "activity_type" => "command_window",
              "schema_contract" => "command_window.v1"
            }
          }
        ],
        source: "mission_plan.activities"
      )
      |> update_in(["rows", Access.at(0)], fn row ->
        row
        |> Map.put("contact_result", %{
          "outcome" => "accepted",
          "provider_status" => "NO-CONTACT"
        })
        |> Map.put("command_result", %{
          "status" => "rejected",
          "details" => %{"message" => "timed out"}
        })
        |> Map.update("activity_context", %{}, fn context ->
          Map.merge(context, %{
            "contact_result" => %{
              "outcome" => "accepted",
              "provider_status" => "NO-CONTACT"
            },
            "command_result" => %{
              "status" => "rejected",
              "details" => %{"message" => "timed out"}
            }
          })
        end)
      end)

    package = OperatorReview.from_operational_timeline_report(report)

    assert %{
             "review_type" => "operational_timeline_review",
             "activity_id" => "cmd_provider_map",
             "contact_result" => "accepted,NO-CONTACT",
             "command_result" => "rejected,timed out",
             "source_activity_context" => %{
               "contact_result" => "accepted,NO-CONTACT",
               "command_result" => "rejected,timed out"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "preserves malformed operational activity-context cadence import for review" do
    report = %{
      "schema_contract" => "operational_timeline_report.v1",
      "source" => "bad_context",
      "rows" => [
        %{
          "activity_id" => "cmd_1",
          "timeline_id" => "timeline_cmd_1",
          "activity_type" => "command",
          "operational_kind" => "command",
          "required_operator_action" => "review_command_contact",
          "operator_action_reason" => "command_boundary_requires_review",
          "activity_context" => %{"cadence_import" => :bad_context}
        }
      ]
    }

    package = OperatorReview.from_operational_timeline_report(report)
    row = List.first(package["rows"])

    assert %{
             "review_type" => "operational_timeline_review",
             "activity_id" => "cmd_1",
             "cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{"invalid_import_shape" => "bad_context"},
             "source_activity_context" => %{
               "invalid_cadence_import" => true,
               "source_cadence_import" => %{"invalid_import_shape" => "bad_context"}
             }
           } = row

    refute Map.has_key?(row["source_activity_context"], "cadence_import")

    manifest = CadenceImport.from_operator_review_package(package)

    assert %{
             "import_status" => "review_required_before_import",
             "cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "source_cadence_import" => %{"invalid_import_shape" => "bad_context"}
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "normalizes unsupported operational cadence import statuses for review" do
    report = %{
      "schema_contract" => "operational_timeline_report.v1",
      "source" => "custom_import_status",
      "rows" => [
        %{
          "activity_id" => "cmd_1",
          "timeline_id" => "timeline_cmd_1",
          "activity_type" => "command",
          "operational_kind" => "command",
          "required_operator_action" => "review_command_contact",
          "operator_action_reason" => "command_boundary_requires_review",
          "cadence_import_status" => "provider_custom",
          "has_cadence_import" => true,
          "source_cadence_import_status" => "source_custom",
          "source_has_cadence_import" => true,
          "replacement_cadence_import_status" => "replacement_custom",
          "replacement_has_cadence_import" => true
        }
      ]
    }

    package = OperatorReview.from_operational_timeline_report(report)
    row = List.first(package["rows"])

    assert row["cadence_import_status"] == "invalid"
    assert row["source_cadence_import_status"] == "invalid"
    assert row["replacement_cadence_import_status"] == "invalid"
    assert row["unsupported_cadence_import_status"] == "provider_custom"
    assert row["unsupported_source_cadence_import_status"] == "source_custom"
    assert row["unsupported_replacement_cadence_import_status"] == "replacement_custom"
    assert row["invalid_cadence_import"] == true
    assert row["invalid_cadence_import_reason"] == "unsupported_cadence_import_status"
    assert row["has_cadence_import"] == false
    assert row["source_has_cadence_import"] == false
    assert row["replacement_has_cadence_import"] == false
    assert package["cadence_import_status_counts"] == %{"invalid" => 1}
    assert package["source_cadence_import_status_counts"] == %{"invalid" => 1}
    assert package["replacement_cadence_import_status_counts"] == %{"invalid" => 1}

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from operator-relevant command window rows" do
    report = %{
      "schema_contract" => "command_window_report.v1",
      "model" => "artifact_only_command_window_report",
      "source" => "mission_plan.activities",
      "window_count" => 2,
      "command_count" => 1,
      "tracking_count" => 1,
      "uplink_count" => 0,
      "health_check_count" => 0,
      "review_required_count" => 1,
      "source_window_lineage_count" => 1,
      "rows" => [
        %{
          "id" => "command_window:cmd_1",
          "rank" => 1,
          "activity_id" => "cmd_1",
          "timeline_id" => "timeline:cmd_1",
          "scenario_id" => "leo_1",
          "activity_type" => "command",
          "window_type" => "command_window",
          "direction" => "command",
          "ground_station_id" => "dss_14",
          "starts_at_s" => 30.0,
          "ends_at_s" => 40.0,
          "status" => "planned",
          "approval_status" => "pending",
          "locked" => false,
          "command_success" => false,
          "contact_result" => ["accepted", "dropped"],
          "command_result" => [:accepted, :rejected],
          "command_success_factor" => 0.25,
          "command_success_factor_source" => "operational_feedback.command_success_rate.activity",
          "required_operator_action" => "review_command_contact",
          "operator_action_reason" => "command_boundary_requires_review",
          "approval_requirements" => [
            %{
              "activity_id" => "cmd_1",
              "activity_type" => "command",
              "action" => "review_command_contact",
              "requirement_type" => "command_review",
              "policy_classification" => "operator_review_required"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "command_health_review",
              "classification" => "operator_review_required",
              "requirement_type" => "command_review"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "contact_command_review_v1",
            "rule_matches" => [
              %{
                "rule_id" => "command_health_review",
                "classification" => "operator_review_required"
              }
            ],
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
            ],
            "approval_requirement_count" => 1,
            "risk_count" => 0
          },
          "execution_boundary" => "planned_not_commanded",
          "cadence_import_status" => "missing",
          "source_window_id" => "cmd_window_1",
          "has_source_window" => true,
          "has_cadence_import" => false,
          "timeline_identity" => %{
            "timeline_id" => "timeline:cmd_1",
            "activity_id" => "cmd_1"
          },
          "activity_context" => %{
            "starts_at_s" => 30.0,
            "ends_at_s" => 40.0,
            "source_window_id" => "cmd_window_1",
            "command_success" => false,
            "contact_result" => ["accepted", "dropped"],
            "command_result" => [:accepted, :rejected],
            "command_success_factor" => 0.25,
            "timeline_identity" => %{
              "timeline_id" => "timeline:cmd_1",
              "activity_id" => "cmd_1",
              "source_window_id" => "cmd_window_1"
            }
          }
        },
        %{
          "id" => "command_window:track_1",
          "rank" => 2,
          "activity_id" => "track_1",
          "timeline_id" => "timeline:track_1",
          "activity_type" => "tracking",
          "window_type" => "tracking_window",
          "starts_at_s" => 50.0,
          "ends_at_s" => 60.0,
          "status" => "planned",
          "approval_status" => "approved",
          "locked" => false,
          "required_operator_action" => "monitor_activity",
          "execution_boundary" => "planned_not_commanded",
          "cadence_import_status" => "present",
          "has_source_window" => false,
          "has_cadence_import" => true,
          "timeline_identity" => %{"timeline_id" => "timeline:track_1"}
        }
      ],
      "assumptions" => %{"boundary" => "artifact_only_no_schedule_mutation_or_command_execution"}
    }

    package = OperatorReview.from_command_window_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "command_window_report.v1",
             "source_artifact_id" => "mission_plan.activities",
             "review_count" => 1,
             "command_window_count" => 1
           } = package

    assert %{
             "review_type" => "command_window_review",
             "activity_id" => "cmd_1",
             "timeline_id" => "timeline:cmd_1",
             "window_type" => "command_window",
             "required_operator_action" => "review_command_contact",
             "reason" => "command_boundary_requires_review",
             "cadence_import_status" => "missing",
             "command_success" => false,
             "contact_result" => "accepted,dropped",
             "command_result" => "accepted,rejected",
             "command_success_factor" => 0.25,
             "approval_rule_matches" => [
               %{"rule_id" => "command_health_review"}
             ],
             "requirement_type" => "command_review",
             "required_authority" => "command_authority",
             "policy_bundle_id" => "contact_command_review_v1",
             "rule_id" => "command_health_review",
             "escalation_level" => "flight_director",
             "escalation_queue" => "command_review",
             "escalation_role" => "command_authorizer",
             "sla_s" => 300,
             "source_policy_decision" => %{
               "policy_bundle_id" => "contact_command_review_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "command_health_review",
               "escalation_queue" => "command_review"
             },
             "source_activity_context" => %{
               "source_window_id" => "cmd_window_1",
               "contact_result" => "accepted,dropped",
               "command_result" => "accepted,rejected",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:cmd_1",
                 "activity_id" => "cmd_1",
                 "source_window_id" => "cmd_window_1"
               }
             },
             "source_command_window" => %{"activity_id" => "cmd_1"}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> Map.put("source_window_id", "stale_source_window")
          |> Map.put("execution_boundary", "stale_execution_boundary")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_window_id" and
                 &1["message"] == "must match source_command_window.source_window_id")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].execution_boundary" and
                 &1["message"] == "must match source_command_window.execution_boundary")
           )
  end

  test "builds review package from maneuver review rows" do
    report = %{
      "schema_contract" => "maneuver_review_report.v1",
      "model" => "artifact_only_maneuver_review_report",
      "source" => "maneuver_recommendations",
      "source_artifact_id" => "result:leo_1",
      "maneuver_count" => 1,
      "review_required_count" => 1,
      "total_delta_v_km_s" => 0.01,
      "rows" => [
        %{
          "id" => "maneuver_review:leo_1:trim_burn",
          "rank" => 1,
          "maneuver_id" => "trim_burn",
          "scenario_id" => "leo_1",
          "maneuver_type" => "impulsive_burn",
          "epoch_s" => 120.0,
          "epoch_scale" => "tdb",
          "frame" => "eci_j2000",
          "delta_v_km_s" => [0.0, 0.01, 0.0],
          "delta_v_magnitude_km_s" => 0.01,
          "maneuver_model" => "impulsive_burns",
          "maneuver_success_factor" => 0.4,
          "maneuver_success_factor_source" => "realized_activity.completed_fraction",
          "approval_status" => "operator_review_required",
          "approval_rule_matches" => [
            %{
              "rule_id" => "maneuver_timing_authority_review",
              "classification" => "operator_review_required"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "maneuver_authority_v1",
            "escalations" => [
              %{"rule_id" => "unmatched_maneuver_rule", "escalation_queue" => "ignore_queue"},
              %{
                "rule_id" => "maneuver_timing_authority_review",
                "escalation_level" => "flight_director",
                "escalation_queue" => "maneuver_authority",
                "escalation_role" => "flight_dynamics_lead",
                "required_authority" => "maneuver_authority",
                "sla_s" => 1200
              }
            ]
          },
          "required_operator_action" => "review_maneuver_recommendation",
          "reason" => "review impulsive_burn maneuver at 120.0s with 0.01 km/s delta-v",
          "execution_boundary" => "recommendation_only_no_command_execution",
          "source_recommendation" => %{
            "schema_contract" => "maneuver_recommendation.v1",
            "id" => "trim_burn"
          }
        }
      ],
      "assumptions" => %{"boundary" => "review_only_no_command_execution"}
    }

    package = OperatorReview.from_maneuver_review_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "maneuver_review_report.v1",
             "source_artifact_id" => "result:leo_1",
             "review_count" => 1,
             "maneuver_review_count" => 1
           } = package

    assert %{
             "review_type" => "maneuver_review",
             "subject_id" => "trim_burn",
             "maneuver_id" => "trim_burn",
             "scenario_id" => "leo_1",
             "maneuver_type" => "impulsive_burn",
             "delta_v_magnitude_km_s" => 0.01,
             "maneuver_success_factor" => 0.4,
             "maneuver_success_factor_source" => "realized_activity.completed_fraction",
             "required_operator_action" => "review_maneuver_recommendation",
             "execution_boundary" => "recommendation_only_no_command_execution",
             "approval_rule_matches" => [
               %{"rule_id" => "maneuver_timing_authority_review"}
             ],
             "escalation_level" => "flight_director",
             "escalation_queue" => "maneuver_authority",
             "escalation_role" => "flight_dynamics_lead",
             "required_authority" => "maneuver_authority",
             "sla_s" => 1200,
             "source_policy_decision" => %{
               "policy_bundle_id" => "maneuver_authority_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "maneuver_timing_authority_review",
               "escalation_queue" => "maneuver_authority"
             },
             "source_maneuver_review" => %{
               "maneuver_id" => "trim_burn",
               "maneuver_success_factor" => 0.4
             }
           } = List.first(package["rows"])

    assert List.first(package["rows"])["delta_v_km_s"] == [0.0, 0.01, 0.0]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "maneuver review packages reject stale source maneuver evidence" do
    report =
      OrbitalDynamics.maneuver_review_report([
        %{
          "id" => "trim_burn",
          "scenario_id" => "leo_1",
          "type" => "impulsive_burn",
          "epoch_s" => 120.0,
          "frame" => "eci_j2000",
          "delta_v_km_s" => [0.0, 0.01, 0.0],
          "delta_v_magnitude_km_s" => 0.01,
          "maneuver_model" => "impulsive_burns"
        }
      ])

    package =
      report
      |> OperatorReview.from_maneuver_review_report()
      |> update_in(["rows", Access.at(0), "source_maneuver_review"], fn source ->
        Map.put(source, "maneuver_id", "trim_burn_stale")
      end)

    assert {:error, stale_source_report} = Schema.validate_artifact(package)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].maneuver_id" and
                 &1["message"] == "must match source_maneuver_review.maneuver_id")
           )
  end

  test "builds standalone maneuver recommendation review package" do
    recommendation = %{
      "schema_contract" => "maneuver_recommendation.v1",
      "id" => "trim_burn",
      "scenario_id" => "ops_checkout",
      "type" => "impulsive_burn",
      "epoch_s" => 180.0,
      "epoch_scale" => "tdb",
      "frame" => "eci_j2000",
      "delta_v_km_s" => [0.0, 0.01, 0.0],
      "delta_v_magnitude_km_s" => 0.01,
      "maneuver_model" => "impulsive_burns",
      "assumptions" => %{
        "execution_boundary" => "recommendation_only_no_command_execution",
        "source" => "trajectory_assumptions"
      }
    }

    package = OperatorReview.from_maneuver_recommendation(recommendation)
    assert OrbitalDynamics.operator_review_package(recommendation) == package

    assert %{
             "source_artifact_type" => "maneuver_recommendation.v1",
             "source_artifact_id" => "trim_burn",
             "review_count" => 1,
             "maneuver_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "maneuver_review",
                 "source" => "maneuver_recommendation",
                 "maneuver_id" => "trim_burn",
                 "scenario_id" => "ops_checkout",
                 "maneuver_type" => "impulsive_burn",
                 "delta_v_magnitude_km_s" => 0.01,
                 "required_operator_action" => "review_maneuver_recommendation",
                 "execution_boundary" => "recommendation_only_no_command_execution",
                 "source_recommendation" => %{
                   "schema_contract" => "maneuver_recommendation.v1"
                 },
                 "source_maneuver_review" => %{"maneuver_id" => "trim_burn"}
               }
             ]
           } = package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "standalone realized activity review uses provider realized_status from match-state rows" do
    activity = %{
      "schema_contract" => "realized_activity.v1",
      "id" => "downlink_equator",
      "status" => "matched",
      "realized_status" => "failed",
      "type" => "downlink",
      "direction" => "downlink",
      "ground_station_id" => "equator_prime",
      "provider" => "cadence",
      "adapter" => "cadence_feedback_adapter",
      "external_id" => "provider_feedback_2",
      "provenance" => %{"trust_boundary" => "operator_supplied"}
    }

    package = OperatorReview.from_realized_activity(activity)

    assert %{
             "review_type" => "realized_feedback",
             "activity_id" => "downlink_equator",
             "feedback_status" => "realized_only",
             "realized_status" => "failed",
             "required_operator_action" => "review_unplanned_realization",
             "contact_success" => false,
             "status_transition" => %{
               "to" => "failed",
               "transition_type" => "added"
             },
             "realized_activity_context" => %{
               "status" => "failed",
               "feedback_status" => "matched"
             },
             "realized_activity" => %{
               "status" => "matched",
               "realized_status" => "failed"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds standalone maneuver execution delta review package" do
    delta = %{
      "schema_contract" => "maneuver_execution_delta.v1",
      "activity_id" => "trim_burn_1",
      "status" => "completed",
      "epoch_s" => 180.0,
      "delta_v_km_s" => [0.0, 0.01, 0.0],
      "source" => %{"system" => "ops_log", "source_id" => "maneuver_log_1"},
      "quality" => %{"level" => "operator_reported"},
      "provenance" => %{"trust_boundary" => "operator_supplied"}
    }

    package = OperatorReview.from_maneuver_execution_delta(delta)
    assert OrbitalDynamics.operator_review_package(delta) == package

    assert %{
             "source_artifact_type" => "maneuver_execution_delta.v1",
             "source_artifact_id" => "trim_burn_1",
             "review_count" => 1,
             "realized_feedback_count" => 1,
             "rows" => [
               %{
                 "review_type" => "realized_feedback",
                 "source" => "maneuver_execution_delta",
                 "activity_id" => "trim_burn_1",
                 "feedback_status" => "realized_only",
                 "realized_status" => "completed",
                 "realized_type" => "impulsive_burn",
                 "realized_trust_boundary" => "operator_supplied",
                 "realized_provenance" => %{"trust_boundary" => "operator_supplied"},
                 "required_operator_action" => "review_unplanned_realization",
                 "source_feedback" => %{
                   "realized_activity" => %{
                     "schema_contract" => "maneuver_execution_delta.v1"
                   }
                 }
               }
             ]
           } = package

    [row] = package["rows"]

    assert get_in(row, ["source_feedback", "realized_activity", "delta_v_km_s"]) == [
             0.0,
             0.01,
             0.0
           ]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from station calendar affected contacts" do
    report = %{
      "schema_contract" => "station_calendar_report.v1",
      "model" => "campaign_ground_network_interval_overlay",
      "input_contact_count" => 1,
      "calendar_entry_count" => 1,
      "affected_contact_count" => 1,
      "affected_contacts" => [
        %{
          "id" => "station_calendar:cmd_1:equator_reserved",
          "contact_id" => "cmd_1",
          "scenario_id" => "leo_1",
          "contact_type" => "planned_contact",
          "direction" => "command",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0,
          "station_calendar_entry_id" => "equator_reserved",
          "station_calendar_provider_id" => "ops_calendar",
          "station_calendar_provider_entry_id" => "provider_reserved_1",
          "station_calendar_directions" => ["command"],
          "status" => "Reserved",
          "station_availability" => "Reserved",
          "station_calendar_overlap_count" => 2,
          "station_calendar_overlap_entry_ids" => ["equator_reserved", "equator_capacity"],
          "station_calendar_overlap_availabilities" => ["Reserved", "Reduced Capacity"],
          "station_calendar_entry_ambiguous" => true,
          "station_calendar_ambiguous_entry_count" => 2,
          "station_calendar_ambiguous_entry_ids" => [
            "equator_reserved",
            "equator_backup_reserved"
          ],
          "station_calendar_trust_boundary_status" => "declared",
          "trust_boundary" => "operator_declared_station_calendar",
          "station_contention_status" => "Reserved Overlap",
          "station_reservation_id" => "provider_reservation_42",
          "station_reserved_by" => "cadence_ops",
          "station_reservation_status" => "Confirmed",
          "source_station_calendar_entry" => %{
            "id" => "equator_reserved",
            "availability" => "Reserved"
          },
          "source_station_calendar_overlaps" => [
            %{"id" => "equator_reserved", "availability" => "Reserved"},
            %{"id" => "equator_capacity", "availability" => "Reduced Capacity"}
          ],
          "approval_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "activity_id" => "cmd_1",
              "activity_type" => "planned_contact",
              "action" => "review_station_reservation_overlap",
              "requirement_type" => "contact_schedule_change",
              "policy_classification" => "operator_review_required"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "reserved_station_contact_review",
              "classification" => "operator_review_required",
              "station_contention_status" => "reserved_overlap"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "ground_network_allocation_v1",
            "rule_matches" => [
              %{
                "rule_id" => "reserved_station_contact_review",
                "classification" => "operator_review_required"
              }
            ],
            "escalations" => [
              %{
                "rule_id" => "reserved_station_contact_review",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "ground_network",
                "escalation_role" => "contact_scheduler",
                "required_authority" => "contact_schedule_authority",
                "sla_s" => 600
              }
            ],
            "approval_requirement_count" => 1,
            "risk_count" => 0
          }
        }
      ],
      "assumptions" => %{
        "source" => "ops_calendar",
        "execution_boundary" => "artifact_only_no_provider_reservation"
      }
    }

    package = OperatorReview.from_station_calendar_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "station_calendar_report.v1",
             "source_artifact_id" => "ops_calendar",
             "review_count" => 1,
             "station_calendar_review_count" => 1
           } = package

    assert %{
             "review_type" => "station_calendar_review",
             "subject_id" => "cmd_1",
             "contact_id" => "cmd_1",
             "activity_type" => "planned_contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "equator_reserved",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_reserved_1",
             "station_calendar_directions" => ["command"],
             "station_availability" => "reserved",
             "station_calendar_overlap_count" => 2,
             "station_calendar_overlap_entry_ids" => ["equator_reserved", "equator_capacity"],
             "station_calendar_overlap_availabilities" => ["reserved", "reduced_capacity"],
             "station_calendar_entry_ambiguous" => true,
             "station_calendar_ambiguous_entry_count" => 2,
             "station_calendar_ambiguous_entry_ids" => [
               "equator_reserved",
               "equator_backup_reserved"
             ],
             "station_calendar_trust_boundary_status" => "declared",
             "trust_boundary" => "operator_declared_station_calendar",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "provider_reservation_42",
             "required_operator_action" => "review_station_reservation_overlap",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "contact_scheduler",
             "required_authority" => "contact_schedule_authority",
             "sla_s" => 600,
             "approval_rule_matches" => [
               %{"rule_id" => "reserved_station_contact_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "reserved_station_contact_review",
               "required_authority" => "contact_schedule_authority"
             },
             "source_station_calendar_entry" => %{
               "id" => "equator_reserved",
               "availability" => "reserved"
             },
             "source_station_calendar_overlaps" => [
               %{"id" => "equator_reserved", "availability" => "reserved"},
               %{"id" => "equator_capacity", "availability" => "reduced_capacity"}
             ],
             "source_station_calendar_review" => %{"contact_id" => "cmd_1"}
           } = List.first(package["rows"])

    assert get_in(List.first(package["rows"]), [
             "source_station_calendar_review",
             "station_contention_status"
           ]) == "reserved_overlap"

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(row, ["source_station_calendar_entry", "id"], "calendar entry with spaces")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_station_calendar_entry.id")
           )

    invalid_overlap_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_station_calendar_overlaps", Access.at(1), "id"],
            "calendar overlap with spaces"
          )
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_overlap_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_station_calendar_overlaps[1].id")
           )

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> Map.put("station_contention_status", "stale_contention_status")
          |> Map.put("starts_at_s", 11.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].station_contention_status" and
                 &1["message"] == "must match station calendar source station_contention_status")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].starts_at_s" and
                 &1["message"] == "must match station calendar source starts_at_s")
           )
  end

  test "builds review package from station reservation reports" do
    report = %{
      "schema_contract" => "station_reservation_report.v1",
      "source" => "ops_calendar",
      "affected_contacts" => [
        %{
          "contact_id" => "dl_reserved",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "station_calendar_entry_id" => "calendar_reserved_1",
          "station_calendar_provider_id" => "ops_calendar",
          "station_calendar_provider_entry_id" => "provider_reserved_1",
          "station_contention_status" => "reserved_overlap",
          "station_reservation_match_status" => "owned",
          "station_reservation_id" => "reservation_1",
          "station_reserved_by" => "network_partner",
          "station_reservation_status" => "held",
          "station_calendar_reservation_overlap_count" => 1,
          "station_calendar_reservation_ids" => ["reservation_1"],
          "station_calendar_reserved_by" => ["network_partner"],
          "station_calendar_reservation_statuses" => ["held"],
          "station_calendar_reservation_expires_at_s" => [240.0],
          "required_operator_action" => "review_station_reservation_overlap"
        }
      ],
      "provider_calendar_contention_groups" => [
        %{
          "id" => "station_calendar_provider_contention:equator_prime:1",
          "provider_calendar_contention_status" => "provider_calendar_overlap",
          "required_operator_action" => "review_station_provider_contention",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 95.0,
          "ends_at_s" => 165.0,
          "entry_count" => 2,
          "entry_ids" => ["calendar_reserved_1", "calendar_reserved_2"],
          "reservation_ids" => ["reservation_1", "reservation_2"],
          "reservation_statuses" => ["held", "confirmed"]
        }
      ]
    }

    package = OperatorReview.from_station_reservation_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "station_reservation_report.v1",
             "source_artifact_id" => "ops_calendar",
             "review_count" => 2,
             "station_reservation_review_count" => 2,
             "review_type_counts" => %{"station_reservation_review" => 2}
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" => "station_reservation_report.affected_contacts",
             "contact_id" => "dl_reserved",
             "ground_station_id" => "equator_prime",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_reserved_1",
             "station_reservation_id" => "reservation_1",
             "station_reserved_by" => "network_partner",
             "station_reservation_status" => "held",
             "station_reservation_match_status" => "owned",
             "required_operator_action" => "review_station_reservation_overlap",
             "source_station_reservation" => %{
               "contact_id" => "dl_reserved",
               "station_reservation_id" => "reservation_1"
             }
           } = List.first(package["rows"])

    assert %{
             "review_type" => "station_reservation_review",
             "source" => "station_reservation_report.provider_calendar_contention_groups",
             "provider_calendar_contention_group_id" =>
               "station_calendar_provider_contention:equator_prime:1",
             "provider_calendar_contention_reservation_ids" => [
               "reservation_1",
               "reservation_2"
             ],
             "required_operator_action" => "review_station_provider_contention",
             "source_station_reservation" => %{
               "id" => "station_calendar_provider_contention:equator_prime:1"
             }
           } = Enum.at(package["rows"], 1)

    manifest = CadenceImport.from_operator_review_package(package)

    assert CadenceImport.from_station_reservation_report(report) == manifest
    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "station_reservation_report.v1",
             "row_count" => 2,
             "review_required_count" => 2,
             "source_review_type_counts" => %{"station_reservation_review" => 2}
           } = manifest

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "contact_id" => "dl_reserved",
             "station_reservation_id" => "reservation_1",
             "source_station_reservation" => %{
               "contact_id" => "dl_reserved"
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence_package =
      update_in(package, ["rows"], fn [reservation_row, provider_row] ->
        [
          put_in(
            reservation_row,
            ["source_station_reservation", "station_reservation_id"],
            "bad reservation id"
          ),
          provider_row
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_station_reservation.station_reservation_id")
           )

    invalid_source_evidence_manifest =
      update_in(manifest, ["rows"], fn [reservation_row, provider_row] ->
        [
          put_in(
            reservation_row,
            ["source_station_reservation", "station_reservation_id"],
            "bad reservation id"
          ),
          provider_row
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_station_reservation.station_reservation_id")
           )

    invalid_package =
      update_in(package, ["rows"], fn [reservation_row, provider_row] ->
        [
          Map.put(reservation_row, "station_calendar_reservation_overlap_count", 2),
          provider_row
          |> Map.put("provider_calendar_contention_entry_count", 1)
          |> Map.put("starts_at_s", 96.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_reservation_overlap_count" and
                 &1["message"] == "must equal length of station_calendar_reservation_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[1].provider_calendar_contention_entry_count" and
                 &1["message"] == "must equal length of provider_calendar_contention_entry_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[1].starts_at_s" and
                 &1["message"] == "must match provider calendar contention source starts_at_s")
           )

    invalid_manifest =
      update_in(manifest, ["rows"], fn [reservation_row, provider_row] ->
        [
          Map.put(reservation_row, "station_calendar_reservation_overlap_count", 2),
          provider_row
          |> Map.put("provider_calendar_contention_entry_count", 1)
          |> Map.put("starts_at_s", 96.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_reservation_overlap_count" and
                 &1["message"] == "must equal length of station_calendar_reservation_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[1].provider_calendar_contention_entry_count" and
                 &1["message"] == "must equal length of provider_calendar_contention_entry_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[1].starts_at_s" and
                 &1["message"] == "must match provider calendar contention source starts_at_s")
           )

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn [reservation_row, provider_row] ->
        reservation_source_review_row =
          reservation_row["source_review_row"]
          |> Map.put("station_reservation_id", "stale_reservation")
          |> Map.put("import_status", "ready_for_import")

        provider_source_review_row =
          provider_row["source_review_row"]
          |> Map.put("provider_calendar_contention_entry_count", 1)
          |> Map.put("source_review_action", "stale_provider_action")

        [
          Map.put(reservation_row, "source_review_row", reservation_source_review_row),
          Map.put(provider_row, "source_review_row", provider_source_review_row)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.station_reservation_id" and
                 &1["message"] == "must match station_reservation_id on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.import_status" and
                 &1["message"] == "must match import_status on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.rows[1].source_review_row.provider_calendar_contention_entry_count" and
                 &1["message"] ==
                   "must match provider_calendar_contention_entry_count on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[1].source_review_row.source_review_action" and
                 &1["message"] == "must match source_review_action on Cadence import row")
           )
  end

  test "builds review package from standalone provider counteroffer reports" do
    report = provider_counteroffer_report()

    package = OperatorReview.from_provider_counteroffer_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "source_artifact_id" => "cadence_supported_source_fixture",
             "review_count" => 1,
             "provider_counteroffer_review_count" => 1,
             "rows" => [row]
           } = package

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" => "provider_counteroffer_report.rows",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 40.0,
             "provider_counteroffer_duration_delta_s" => 10.0,
             "required_operator_action" => "review_provider_counteroffer",
             "source_provider_counteroffer" => %{
               "provider_counteroffer_id" => "provider_offer_1"
             }
           } = row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [put_in(row, ["source_provider_counteroffer", "id"], "provider source with spaces")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_provider_counteroffer.id")
           )

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> Map.put("provider_counteroffer_status", "accepted")
          |> Map.put("provider_counteroffer_lock_deadline_s", 151.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].provider_counteroffer_status" and
                 &1["message"] ==
                   "must match source_provider_counteroffer.provider_counteroffer_status")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].provider_counteroffer_lock_deadline_s" and
                 &1["message"] ==
                   "must match source_provider_counteroffer.provider_counteroffer_lock_deadline_s")
           )
  end

  test "builds review package from standalone link capacity report rows" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "model" => "fixed_rate_downlink_capacity_summary",
      "source" => "campaign_plan.candidate_activities",
      "contact_count" => 1,
      "selected_contact_count" => 0,
      "estimated_throughput_mb" => 345.4,
      "selected_estimated_throughput_mb" => 0.0,
      "capacity_adjusted_throughput_mb" => 172.7,
      "selected_capacity_adjusted_throughput_mb" => 0.0,
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "contact_count" => 2,
          "ignored_contact_count" => 1,
          "ignored_contact_ids" => ["leo_1_rejected_downlink"],
          "ignored_contact_reason_counts" => %{"approval_status_rejected" => 1},
          "selected_contact_count" => 0,
          "ignored_selected_contact_count" => 1,
          "ignored_selected_contact_ids" => ["leo_1_rejected_downlink"],
          "ignored_selected_contact_reason_counts" => %{"approval_status_rejected" => 1},
          "estimated_throughput_mb" => 345.4,
          "selected_estimated_throughput_mb" => 0.0,
          "capacity_adjusted_throughput_mb" => 172.7,
          "selected_capacity_adjusted_throughput_mb" => 0.0,
          "capacity_fraction_min" => 0.5,
          "capacity_fraction_max" => 0.5,
          "approval_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "activity_id" => "link_capacity:equator_prime",
              "activity_type" => "link_capacity_summary",
              "action" => "review_link_capacity_summary",
              "requirement_type" => "contact_schedule_change",
              "policy_classification" => "operator_review_required"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "severe_capacity_reduction_review",
              "classification" => "operator_review_required",
              "station_availability" => "reduced_capacity",
              "capacity_fraction" => 0.5
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "ground_network_allocation_v1",
            "rule_matches" => [
              %{
                "rule_id" => "severe_capacity_reduction_review",
                "classification" => "operator_review_required"
              }
            ],
            "escalations" => [
              %{
                "rule_id" => "unmatched_link_rule",
                "escalation_queue" => "ignore_queue"
              },
              %{
                "rule_id" => "severe_capacity_reduction_review",
                "required_authority" => "ground_network_authority",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "link_capacity",
                "escalation_role" => "link_budget_analyst",
                "sla_s" => 900
              }
            ],
            "approval_requirement_count" => 1,
            "risk_count" => 0
          },
          "contact_ids" => ["leo_1_downlink_equator_prime_1", "leo_1_rejected_downlink"],
          "selected_contact_ids" => []
        }
      ],
      "assumptions" => %{"link_budget_model" => "none"}
    }

    package = OperatorReview.from_link_capacity_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "link_capacity_report.v1",
             "source_artifact_id" => "campaign_plan.candidate_activities",
             "review_count" => 1,
             "link_capacity_review_count" => 1
           } = package

    first_row = List.first(package["rows"])

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "link_capacity_report.rows",
             "subject_id" => "equator_prime",
             "ground_station_id" => "equator_prime",
             "required_operator_action" => "review_link_capacity_summary",
             "contact_count" => 2,
             "ignored_contact_count" => 1,
             "ignored_contact_ids" => ["leo_1_rejected_downlink"],
             "ignored_contact_reason_counts" => %{"approval_status_rejected" => 1},
             "selected_contact_count" => 0,
             "ignored_selected_contact_count" => 1,
             "ignored_selected_contact_ids" => ["leo_1_rejected_downlink"],
             "ignored_selected_contact_reason_counts" => %{"approval_status_rejected" => 1},
             "capacity_fraction_min" => 0.5,
             "capacity_fraction_max" => 0.5,
             "contact_ids" => ["leo_1_downlink_equator_prime_1", "leo_1_rejected_downlink"],
             "selected_contact_ids" => [],
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "ground_network_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "severe_capacity_reduction_review",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "link_capacity",
             "escalation_role" => "link_budget_analyst",
             "sla_s" => 900,
             "approval_rule_matches" => [
               %{"rule_id" => "severe_capacity_reduction_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "severe_capacity_reduction_review",
               "escalation_queue" => "link_capacity"
             },
             "source_link_capacity" => %{"ground_station_id" => "equator_prime"}
           } = first_row

    assert first_row["selected_estimated_throughput_mb"] == 0.0
    assert first_row["selected_capacity_adjusted_throughput_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> Map.put("ignored_selected_contact_count", 2)
          |> Map.put("ground_station_id", "stale_station")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ignored_selected_contact_count" and
                 &1["message"] == "must equal length of ignored_selected_contact_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ground_station_id" and
                 &1["message"] == "must match source_link_capacity.ground_station_id")
           )
  end

  test "builds review package from standalone contact allocation report rows" do
    report =
      "study_results/contact_allocation_report_v1.json"
      |> File.read!()
      |> :json.decode()

    package = OperatorReview.from_contact_allocation_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source_artifact_id" => "fixture.contact_allocation",
             "review_count" => 5,
             "contact_allocation_review_count" => 5,
             "calendar_entry_trust_boundary_status_counts" => %{"missing" => 2}
           } = package

    assert %{
             "review_type" => "contact_allocation_review",
             "source" => "contact_allocation_report.rows",
             "subject_id" => "dl_1",
             "contact_id" => "dl_1",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_contention_resolution",
             "required_operator_action" => "review_contact_allocation",
             "source_contact_allocation" => %{"contact_id" => "dl_1"},
             "source_contention_recommendation" => %{"selected_contact_id" => "dl_1"}
           } = List.first(package["rows"])

    assert %{
             "contact_id" => "dl_3",
             "allocation_status" => "blocked",
             "suppressed_reason" => "ground_station_reserved",
             "source_contact_suppression" => %{"suppressed_reason" => "ground_station_reserved"}
           } = Enum.find(package["rows"], &(&1["contact_id"] == "dl_3"))

    assert %{
             "contact_id" => "cmd_unavailable",
             "activity_type" => "command",
             "direction" => "command",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable",
             "approval_status" => "blocked_by_policy",
             "source_contact_allocation" => %{
               "source_station_calendar_contact" => %{
                 "id" => "cmd_unavailable",
                 "station_availability" => "unavailable"
               }
             }
           } = Enum.find(package["rows"], &(&1["contact_id"] == "cmd_unavailable"))

    assert %{
             "contact_id" => "dl_resource_blocked",
             "allocation_status" => "blocked",
             "allocation_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "source_resource_suppression" => %{
               "suppressed_reason" => "antenna_unavailable"
             }
           } = Enum.find(package["rows"], &(&1["contact_id"] == "dl_resource_blocked"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "contact_allocation_review", "source_contact_allocation" => %{}} =
              row ->
            put_in(row, ["source_contact_allocation", "id"], "allocation source with spaces")

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_contact_allocation\.id$/)
           )

    invalid_contention_recommendation_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{
            "review_type" => "contact_allocation_review",
            "source_contention_recommendation" => %{}
          } = row ->
            put_in(
              row,
              ["source_contention_recommendation", "selected_contact_id"],
              "selected contact with spaces"
            )

          row ->
            row
        end)
      end)

    assert {:error, report} =
             Schema.validate_artifact(invalid_contention_recommendation_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_contention_recommendation\.selected_contact_id$/)
           )

    invalid_package =
      update_in(package, ["rows"], fn [row | rest] ->
        invalid_row =
          Map.merge(row, %{
            "allocation_reason" => "duplicate_contact_id",
            "duplicate_contact_candidate_count" => 2,
            "duplicate_contact_candidate_ids" => [row["contact_id"]],
            "resolution_priority_override_count" => 2,
            "resolution_priority_override_contact_ids" => [row["contact_id"]]
          })

        [invalid_row | rest]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].duplicate_contact_candidate_count" and
                 &1["message"] == "must equal 1")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].resolution_priority_override_count" and
                 &1["message"] == "must equal length of resolution_priority_override_contact_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].allocation_reason" and
                 &1["message"] == "must match source_contact_allocation.allocation_reason")
           )
  end

  test "lifts CandidateRefresh provider-reservation request summaries into contact allocation review rows" do
    artifact = %{
      "refresh_id" => "refresh:provider_reservation_handoff",
      "source_contact_allocation_provider_reservation_request_summary" =>
        provider_reservation_request_summary()
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:provider_reservation_handoff",
             "review_count" => 2,
             "contact_allocation_review_count" => 2,
             "required_operator_action_counts" => %{
               "review_contact_allocation" => 1,
               "review_provider_reservation_request" => 1
             },
             "provider_reservation_candidate_contact_count" => 2,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 1,
             "provider_reservation_no_request_contact_count" => 1,
             "provider_reservation_request_status_counts" => %{"review_required" => 1},
             "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
             "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
             "provider_reservation_no_request_contact_ids" => ["dl_unreserved"]
           } = package

    assert package["provider_reservation_request_contact_ids_by_ground_station_id"] == %{
             "equator_prime" => ["dl_reserved_owner"]
           }

    assert package["provider_reservation_review_contact_ids_by_ground_station_id"] == %{
             "equator_prime" => ["dl_review_overlap"]
           }

    assert package["provider_reservation_no_request_contact_ids_by_direction"] == %{
             "uplink" => ["dl_unreserved"]
           }

    assert package["provider_reservation_request_contact_ids_by_direction"] == %{
             "downlink" => ["dl_reserved_owner"]
           }

    assert package["provider_reservation_review_contact_ids_by_direction"] == %{
             "command" => ["dl_review_overlap"]
           }

    assert package[
             "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
           ] == %{
             "uplink" => %{"equator_prime" => ["dl_unreserved"]}
           }

    assert package[
             "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
           ] == %{
             "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
           }

    assert package[
             "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
           ] == %{
             "command" => %{"equator_prime" => ["dl_review_overlap"]}
           }

    assert package["provider_reservation_request_contact_ids_by_match_status"] == %{
             "matched" => ["dl_reserved_owner"]
           }

    assert package["provider_reservation_review_contact_ids_by_match_status"] == %{
             "overlap" => ["dl_review_overlap"]
           }

    assert package["provider_reservation_request_ids_by_match_status"] == %{
             "matched" => ["reservation_1"]
           }

    assert package["provider_reservation_review_ids_by_match_status"] == %{
             "overlap" => ["reservation_review"]
           }

    request_row = Enum.find(package["rows"], &(&1["contact_id"] == "dl_reserved_owner"))
    review_row = Enum.find(package["rows"], &(&1["contact_id"] == "dl_review_overlap"))

    assert %{
             "action" => "review_provider_reservation_request",
             "required_operator_action" => "review_provider_reservation_request",
             "review_type" => "contact_allocation_review",
             "source" =>
               "candidate_refresh.source_contact_allocation_provider_reservation_request_summary.provider_reservation_request_rows",
             "contact_id" => "dl_reserved_owner",
             "ground_station_id" => "equator_prime",
             "station_reservation_id" => "reservation_1",
             "station_reservation_match_status" => "matched",
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_request_summary_model" =>
               "artifact_only_contact_allocation_provider_reservation_request_summary",
             "provider_reservation_request_summary_schema_contract" =>
               "contact_allocation_provider_reservation_request_summary.v1",
             "provider_reservation_request_execution_boundary" =>
               "artifact_only_no_provider_reservation_or_schedule_mutation",
             "provider_reservation_execution" => "not_performed_by_summary",
             "source_provider_reservation_request_summary" => %{
               "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
               "provider_reservation_request_status" => "review_required"
             },
             "source_contact_allocation" => %{
               "provider_reservation_request_status" => "request_ready",
               "station_reservation_id" => "reservation_1",
               "station_reservation_match_status" => "matched"
             }
           } = request_row

    assert %{
             "action" => "review_contact_allocation",
             "required_operator_action" => "review_contact_allocation",
             "review_type" => "contact_allocation_review",
             "contact_id" => "dl_review_overlap",
             "station_reservation_id" => "reservation_review",
             "station_reservation_match_status" => "overlap",
             "provider_reservation_request_status" => "review_required",
             "source_contact_allocation" => %{
               "provider_reservation_request_status" => "review_required",
               "station_reservation_id" => "reservation_review",
               "station_reservation_match_status" => "overlap"
             }
           } = review_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "lifts standalone provider-reservation request summaries from CandidateRefresh result artifacts" do
    source_result_summary =
      provider_reservation_request_summary()
      |> Map.put("source", "unit_test.provider_reservation.source_result")

    nested_summary =
      provider_reservation_request_summary()
      |> Map.put("source", "unit_test.provider_reservation.nested_result")

    result_summary =
      provider_reservation_request_summary()
      |> Map.put("source", "unit_test.provider_reservation.result")

    artifact = %{
      "refresh_id" => "refresh:provider_reservation_result_artifact_handoff",
      "source_result_artifact" => [
        source_result_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_allocation_provider_reservation_request_summary" => nested_summary
        }
      ],
      "result_artifact" => result_summary
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    provider_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_provider_reservation_request_summary"]["schema_contract"] ==
            "contact_allocation_provider_reservation_request_summary.v1")
      )

    assert length(provider_rows) == 6

    assert Enum.sort(Enum.map(provider_rows, & &1["source"])) == [
             "candidate_refresh.result_artifact.provider_reservation_request_rows",
             "candidate_refresh.result_artifact.provider_reservation_request_rows",
             "candidate_refresh.source_result_artifact[0].provider_reservation_request_rows",
             "candidate_refresh.source_result_artifact[0].provider_reservation_request_rows",
             "candidate_refresh.source_result_artifact[1].contact_allocation_provider_reservation_request_summary.provider_reservation_request_rows",
             "candidate_refresh.source_result_artifact[1].contact_allocation_provider_reservation_request_summary.provider_reservation_request_rows"
           ]

    assert %{
             "contact_allocation_review_count" => 6,
             "provider_reservation_candidate_contact_count" => 6,
             "provider_reservation_request_contact_count" => 3,
             "provider_reservation_review_contact_count" => 3,
             "provider_reservation_no_request_contact_count" => 3,
             "provider_reservation_request_status_counts" => %{"review_required" => 3},
             "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
             "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
             "provider_reservation_no_request_contact_ids" => ["dl_unreserved"]
           } = review

    assert Enum.frequencies_by(provider_rows, & &1["required_operator_action"]) == %{
             "review_contact_allocation" => 3,
             "review_provider_reservation_request" => 3
           }

    import_rows =
      Enum.filter(
        import["rows"],
        &(get_in(&1, [
            "source_review_row",
            "source_provider_reservation_request_summary",
            "schema_contract"
          ]) == "contact_allocation_provider_reservation_request_summary.v1")
      )

    assert length(import_rows) == 6

    assert Enum.all?(
             import_rows,
             &(&1["source_review_row"]["provider_reservation_execution"] ==
                 "not_performed_by_summary")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "builds review package from standalone reduced-capacity contact allocation pack fixture" do
    report =
      "study_results/contact_allocation_capacity_pack_report_v1.json"
      |> File.read!()
      |> :json.decode()
      |> put_in(
        ["reduced_capacity_pack_groups", Access.at(0), "default_required_capacity_fraction"],
        0.25
      )

    package = OperatorReview.from_contact_allocation_report(report)

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source_artifact_id" => "fixture.contact_allocation.capacity_pack",
             "review_count" => 4,
             "contact_allocation_review_count" => 3,
             "contact_allocation_capacity_pack_review_count" => 1,
             "calendar_entry_trust_boundary_status_counts" => %{"declared" => 1}
           } = package

    assert %{
             "review_type" => "contact_allocation_capacity_pack_review",
             "action" => "review_contact_allocation_capacity_pack",
             "required_operator_action" => "review_contact_allocation_capacity_pack",
             "contention_group_id" => "station:equator_prime:contention:1",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "default_required_capacity_fraction" => 0.25,
             "selected_contact_ids" => ["dl_capacity_primary"],
             "capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "deferred_contact_ids" => ["dl_capacity_overflow"],
             "source_contact_allocation_capacity_pack" => %{
               "contention_group_id" => "station:equator_prime:contention:1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["review_type"] == "contact_allocation_capacity_pack_review")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "contact_allocation_capacity_pack_review"} = row ->
            put_in(
              row,
              ["source_contact_allocation_capacity_pack", "id"],
              "capacity pack with spaces"
            )

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_contact_allocation_capacity_pack\.id$/)
           )

    invalid_package =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "contact_allocation_capacity_pack_review"} = row ->
            Map.put(row, "capacity_fraction", 0.4)

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.capacity_fraction$/ and
                 &1["message"] ==
                   "must match source_contact_allocation_capacity_pack.capacity_fraction")
           )
  end

  test "lifts embedded contact-allocation summary fields from wrapper artifacts" do
    campaign_summary =
      contact_allocation_summary(%{"declared" => 1}, %{
        "station_reservation_ids" => ["reservation_campaign"],
        "station_reserved_bys" => ["ops_campaign"],
        "station_reservation_statuses" => ["confirmed"],
        "station_reservation_match_status_counts" => %{"matched" => 1},
        "station_reservation_expiration_status_counts" => %{"declared" => 1},
        "station_reservation_declared_expiration_contact_count" => 1,
        "station_reservation_missing_expiration_contact_count" => 0,
        "earliest_station_reservation_expires_at_s" => 410.0,
        "station_reservation_contact_ids_by_expiration_status" => %{
          "declared" => ["dl_campaign"]
        },
        "station_reservation_ids_by_expiration_status" => %{
          "declared" => ["reservation_campaign"]
        },
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "antenna" => ["dl_campaign_resource"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_campaign" => ["dl_campaign_resource"]
        },
        "station_pressure_contact_count" => 1,
        "station_pressure_review_contact_count" => 1,
        "station_pressure_review_contact_ids" => ["dl_campaign_station"],
        "station_pressure_contact_counts_by_ground_station_id" => %{"gs_campaign" => 1},
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "gs_campaign" => ["dl_campaign_station"]
        },
        "station_pressure_contact_counts_by_availability" => %{"unavailable" => 1},
        "station_pressure_contact_ids_by_availability" => %{
          "unavailable" => ["dl_campaign_station"]
        },
        "station_pressure_contact_counts_by_precedence_availability" => %{"unavailable" => 1},
        "station_pressure_contact_ids_by_precedence_availability" => %{
          "unavailable" => ["dl_campaign_station"]
        },
        "station_pressure_contact_counts_by_precedence_rank" => %{"0" => 1},
        "station_pressure_contact_ids_by_precedence_rank" => %{
          "0" => ["dl_campaign_station"]
        },
        "station_pressure_contact_counts_by_status" => %{"maintenance_window" => 1},
        "station_pressure_contact_ids_by_status" => %{
          "maintenance_window" => ["dl_campaign_station"]
        },
        "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"gs_campaign" => ["dl_campaign_station"]}
        },
        "capacity_pack_required_capacity_fraction" => 0.25,
        "capacity_pack_selected_required_capacity_fraction" => 0.25,
        "capacity_pack_deferred_required_capacity_fraction" => 0.0,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => 0.25
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "gs_campaign" => 0.25
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
          "gs_campaign" => 0.25
        },
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{},
        "capacity_pack_contact_ids_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => ["dl_campaign_pack"]
        },
        "required_capacity_fraction_source_counts" => %{"contact_required_capacity_fraction" => 1},
        "required_capacity_fraction_contact_ids_by_source" => %{
          "contact_required_capacity_fraction" => ["dl_campaign_pack"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "gs_campaign" => ["dl_campaign_pack"]
        },
        "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
          "gs_campaign" => ["dl_campaign_pack"]
        },
        "reduced_capacity_pack_group_count" => 1,
        "reduced_capacity_pack_status_counts" => %{"all_fit" => 1},
        "capacity_pack_group_ids" => ["pack_campaign"],
        "capacity_pack_group_ids_by_status" => %{"all_fit" => ["pack_campaign"]},
        "reduced_capacity_packed_contact_ids" => ["dl_campaign_pack"],
        "reduced_capacity_deferred_contact_ids" => []
      })

    refresh_summary =
      contact_allocation_summary(%{"missing" => 2}, %{
        "station_reservation_ids" => ["reservation_refresh"],
        "station_reserved_bys" => ["ops_refresh"],
        "station_reservation_statuses" => ["tentative"],
        "station_reservation_match_status_counts" => %{"overlap" => 2},
        "station_reservation_expiration_status_counts" => %{"missing" => 2},
        "station_reservation_declared_expiration_contact_count" => 0,
        "station_reservation_missing_expiration_contact_count" => 2,
        "station_reservation_contact_ids_by_expiration_status" => %{
          "missing" => ["dl_refresh_a", "dl_refresh_b"]
        },
        "station_reservation_ids_by_expiration_status" => %{
          "missing" => ["reservation_refresh"]
        },
        "resource_blocking_dimension_counts" => %{"thermal" => 2},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "thermal" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_refresh" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
        },
        "station_pressure_contact_count" => 2,
        "station_pressure_review_contact_count" => 1,
        "station_pressure_review_contact_ids" => ["dl_refresh_station_a"],
        "station_pressure_contact_counts_by_ground_station_id" => %{"gs_refresh" => 2},
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "gs_refresh" => ["dl_refresh_station_a", "dl_refresh_station_b"]
        },
        "station_pressure_contact_counts_by_availability" => %{"reserved" => 2},
        "station_pressure_contact_ids_by_availability" => %{
          "reserved" => ["dl_refresh_station_a", "dl_refresh_station_b"]
        },
        "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 1},
        "station_pressure_contact_ids_by_precedence_availability" => %{
          "reserved" => ["dl_refresh_station_a"]
        },
        "station_pressure_contact_counts_by_precedence_rank" => %{"1" => 1},
        "station_pressure_contact_ids_by_precedence_rank" => %{
          "1" => ["dl_refresh_station_a"]
        },
        "station_pressure_contact_counts_by_status" => %{"reservation_hold" => 2},
        "station_pressure_contact_ids_by_status" => %{
          "reservation_hold" => ["dl_refresh_station_a", "dl_refresh_station_b"]
        },
        "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"gs_refresh" => ["dl_refresh_station_a", "dl_refresh_station_b"]}
        },
        "capacity_pack_required_capacity_fraction" => 0.5,
        "capacity_pack_selected_required_capacity_fraction" => 0.25,
        "capacity_pack_deferred_required_capacity_fraction" => 0.25,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => 0.25,
          "deferred_by_reduced_station_capacity_pack" => 0.25
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "gs_refresh" => 0.5
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
          "gs_refresh" => 0.25
        },
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
          "gs_refresh" => 0.25
        },
        "capacity_pack_contact_ids_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => ["dl_refresh_pack"],
          "deferred_by_reduced_station_capacity_pack" => ["dl_refresh_deferred"]
        },
        "required_capacity_fraction_source_counts" => %{
          "contact_required_capacity_fraction" => 1,
          "default_reduced_capacity_policy" => 1
        },
        "required_capacity_fraction_contact_ids_by_source" => %{
          "contact_required_capacity_fraction" => ["dl_refresh_pack"],
          "default_reduced_capacity_policy" => ["dl_refresh_deferred"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "gs_refresh" => ["dl_refresh_pack", "dl_refresh_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
          "gs_refresh" => ["dl_refresh_pack"]
        },
        "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
          "gs_refresh" => ["dl_refresh_deferred"]
        },
        "reduced_capacity_pack_group_count" => 2,
        "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 2},
        "capacity_pack_group_ids" => ["pack_refresh_a", "pack_refresh_b"],
        "capacity_pack_group_ids_by_status" => %{
          "capacity_limited" => ["pack_refresh_a", "pack_refresh_b"]
        },
        "reduced_capacity_packed_contact_ids" => ["dl_refresh_pack"],
        "reduced_capacity_deferred_contact_ids" => ["dl_refresh_deferred"]
      })

    source_summary =
      contact_allocation_summary(%{"missing" => 1}, %{
        "station_reservation_ids" => ["reservation_source"],
        "station_reserved_bys" => ["ops_source"],
        "station_reservation_statuses" => ["confirmed"],
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "station_reservation_expiration_status_counts" => %{"missing" => 1},
        "station_reservation_declared_expiration_contact_count" => 0,
        "station_reservation_missing_expiration_contact_count" => 1,
        "station_reservation_contact_ids_by_expiration_status" => %{
          "missing" => ["dl_source"]
        },
        "station_reservation_ids_by_expiration_status" => %{
          "missing" => ["reservation_source"]
        },
        "station_reservation_contact_ids_by_match_status" => %{
          "overlap" => ["dl_source"]
        },
        "station_reservation_contact_ids_by_status" => %{
          "confirmed" => ["dl_source"]
        },
        "station_reservation_contact_ids_by_reserved_by" => %{
          "ops_source" => ["dl_source"]
        },
        "station_reservation_ids_by_match_status" => %{
          "overlap" => ["reservation_source"]
        },
        "station_reservation_ids_by_status" => %{
          "confirmed" => ["reservation_source"]
        },
        "station_reservation_ids_by_reserved_by" => %{
          "ops_source" => ["reservation_source"]
        },
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "antenna" => ["dl_source_resource"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_source" => ["dl_source_resource"]
        },
        "station_pressure_contact_count" => 1,
        "station_pressure_review_contact_count" => 1,
        "station_pressure_review_contact_ids" => ["dl_source_station"],
        "station_pressure_contact_counts_by_ground_station_id" => %{"gs_source" => 1},
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "gs_source" => ["dl_source_station"]
        },
        "station_pressure_contact_counts_by_availability" => %{"unavailable" => 1},
        "station_pressure_contact_ids_by_availability" => %{
          "unavailable" => ["dl_source_station"]
        },
        "station_pressure_contact_counts_by_precedence_availability" => %{},
        "station_pressure_contact_ids_by_precedence_availability" => %{},
        "station_pressure_contact_counts_by_precedence_rank" => %{},
        "station_pressure_contact_ids_by_precedence_rank" => %{},
        "capacity_pack_required_capacity_fraction" => 0.35,
        "capacity_pack_selected_required_capacity_fraction" => 0.0,
        "capacity_pack_deferred_required_capacity_fraction" => 0.35,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "deferred_by_reduced_station_capacity_pack" => 0.35
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "gs_source" => 0.35
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{},
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
          "gs_source" => 0.35
        },
        "capacity_pack_contact_ids_by_status" => %{
          "deferred_by_reduced_station_capacity_pack" => ["dl_source_deferred"]
        },
        "required_capacity_fraction_source_counts" => %{"capacity_model" => 1},
        "required_capacity_fraction_contact_ids_by_source" => %{
          "capacity_model" => ["dl_source_deferred"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "gs_source" => ["dl_source_deferred"]
        },
        "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
          "gs_source" => ["dl_source_deferred"]
        },
        "reduced_capacity_pack_group_count" => 1,
        "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
        "capacity_pack_group_ids" => ["pack_source"],
        "capacity_pack_group_ids_by_status" => %{"capacity_limited" => ["pack_source"]},
        "reduced_capacity_packed_contact_ids" => [],
        "reduced_capacity_deferred_contact_ids" => ["dl_source_deferred"]
      })

    result_summary =
      contact_allocation_summary(%{"declared" => 2}, %{
        "station_reservation_ids" => ["reservation_result"],
        "station_reserved_bys" => ["ops_result"],
        "station_reservation_statuses" => ["released"],
        "station_reservation_match_status_counts" => %{"matched" => 2},
        "station_reservation_expiration_status_counts" => %{"declared" => 2},
        "station_reservation_declared_expiration_contact_count" => 2,
        "station_reservation_missing_expiration_contact_count" => 0,
        "earliest_station_reservation_expires_at_s" => 520.0,
        "station_reservation_contact_ids_by_expiration_status" => %{
          "declared" => ["dl_result_a", "dl_result_b"]
        },
        "station_reservation_ids_by_expiration_status" => %{
          "declared" => ["reservation_result"]
        },
        "station_reservation_contact_ids_by_match_status" => %{
          "matched" => ["dl_result_a", "dl_result_b"]
        },
        "station_reservation_contact_ids_by_status" => %{
          "released" => ["dl_result_a", "dl_result_b"]
        },
        "station_reservation_contact_ids_by_reserved_by" => %{
          "ops_result" => ["dl_result_a", "dl_result_b"]
        },
        "station_reservation_ids_by_match_status" => %{
          "matched" => ["reservation_result"]
        },
        "station_reservation_ids_by_status" => %{
          "released" => ["reservation_result"]
        },
        "station_reservation_ids_by_reserved_by" => %{
          "ops_result" => ["reservation_result"]
        },
        "resource_blocking_dimension_counts" => %{"activity_type" => 2},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "activity_type" => ["dl_result_resource_a", "dl_result_resource_b"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_result" => ["dl_result_resource_a", "dl_result_resource_b"]
        },
        "station_pressure_contact_count" => 2,
        "station_pressure_review_contact_count" => 0,
        "station_pressure_review_contact_ids" => [],
        "station_pressure_contact_counts_by_ground_station_id" => %{"gs_result" => 2},
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "gs_result" => ["dl_result_station_a", "dl_result_station_b"]
        },
        "station_pressure_contact_counts_by_availability" => %{"reserved" => 2},
        "station_pressure_contact_ids_by_availability" => %{
          "reserved" => ["dl_result_station_a", "dl_result_station_b"]
        },
        "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 2},
        "station_pressure_contact_ids_by_precedence_availability" => %{
          "reserved" => ["dl_result_station_a", "dl_result_station_b"]
        },
        "station_pressure_contact_counts_by_precedence_rank" => %{"2" => 2},
        "station_pressure_contact_ids_by_precedence_rank" => %{
          "2" => ["dl_result_station_a", "dl_result_station_b"]
        },
        "capacity_pack_required_capacity_fraction" => 0.6,
        "capacity_pack_selected_required_capacity_fraction" => 0.4,
        "capacity_pack_deferred_required_capacity_fraction" => 0.2,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => 0.4,
          "deferred_by_reduced_station_capacity_pack" => 0.2
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "gs_result" => 0.6
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
          "gs_result" => 0.4
        },
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
          "gs_result" => 0.2
        },
        "capacity_pack_contact_ids_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => ["dl_result_pack"],
          "deferred_by_reduced_station_capacity_pack" => ["dl_result_deferred"]
        },
        "required_capacity_fraction_source_counts" => %{
          "activity_context" => 1,
          "throughput_model" => 1
        },
        "required_capacity_fraction_contact_ids_by_source" => %{
          "activity_context" => ["dl_result_deferred"],
          "throughput_model" => ["dl_result_pack"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "gs_result" => ["dl_result_pack", "dl_result_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
          "gs_result" => ["dl_result_pack"]
        },
        "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
          "gs_result" => ["dl_result_deferred"]
        },
        "reduced_capacity_pack_group_count" => 2,
        "reduced_capacity_pack_status_counts" => %{"all_fit" => 2},
        "capacity_pack_group_ids" => ["pack_result_a", "pack_result_b"],
        "capacity_pack_group_ids_by_status" => %{
          "all_fit" => ["pack_result_a", "pack_result_b"]
        },
        "reduced_capacity_packed_contact_ids" => ["dl_result_pack"],
        "reduced_capacity_deferred_contact_ids" => ["dl_result_deferred"]
      })

    campaign =
      OperatorReview.from_campaign_artifact(%{
        "plan_id" => "plan:calendar_counts",
        "contact_allocation_report" => campaign_summary
      })

    refresh =
      OperatorReview.from_candidate_refresh_artifact(%{
        "refresh_id" => "refresh:calendar_counts",
        "contact_allocation_report" => refresh_summary
      })

    repair =
      OperatorReview.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:calendar_counts"},
        "source_contact_allocation_report" => source_summary,
        "contact_allocation_report" => result_summary
      })

    strategy =
      OperatorReview.from_strategy_artifact(%{
        "strategy_metadata" => %{"strategy_id" => "strategy:calendar_counts"},
        "branches" => [
          %{
            "branch_id" => "branch_calendar_counts",
            "repair_result" => %{
              "source_contact_allocation_report" => source_summary,
              "contact_allocation_report" => result_summary
            }
          }
        ]
      })

    assert campaign["calendar_entry_trust_boundary_status_counts"] == %{"declared" => 1}
    assert refresh["calendar_entry_trust_boundary_status_counts"] == %{"missing" => 2}

    assert repair["calendar_entry_trust_boundary_status_counts"] == %{
             "declared" => 2,
             "missing" => 1
           }

    assert strategy["calendar_entry_trust_boundary_status_counts"] == %{
             "declared" => 2,
             "missing" => 1
           }

    assert campaign["station_reservation_ids"] == ["reservation_campaign"]
    assert campaign["station_reserved_bys"] == ["ops_campaign"]
    assert campaign["station_reservation_statuses"] == ["confirmed"]
    assert campaign["station_reservation_match_status_counts"] == %{"matched" => 1}
    assert campaign["station_reservation_expiration_status_counts"] == %{"declared" => 1}
    assert campaign["station_reservation_declared_expiration_contact_count"] == 1
    assert campaign["station_reservation_missing_expiration_contact_count"] == 0
    assert campaign["earliest_station_reservation_expires_at_s"] == 410.0

    assert campaign["station_reservation_contact_ids_by_expiration_status"] == %{
             "declared" => ["dl_campaign"]
           }

    assert campaign["station_reservation_ids_by_expiration_status"] == %{
             "declared" => ["reservation_campaign"]
           }

    assert campaign["resource_blocking_dimension_counts"] == %{"antenna" => 1}

    assert campaign["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "antenna" => ["dl_campaign_resource"]
           }

    assert campaign["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_campaign" => ["dl_campaign_resource"]
           }

    assert campaign["station_pressure_contact_count"] == 1
    assert campaign["station_pressure_review_contact_count"] == 1
    assert campaign["station_pressure_review_contact_ids"] == ["dl_campaign_station"]

    assert campaign["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_campaign" => 1
           }

    assert campaign["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_campaign" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_counts_by_availability"] == %{
             "unavailable" => 1
           }

    assert campaign["station_pressure_contact_ids_by_availability"] == %{
             "unavailable" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_counts_by_precedence_availability"] == %{
             "unavailable" => 1
           }

    assert campaign["station_pressure_contact_ids_by_precedence_availability"] == %{
             "unavailable" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_counts_by_precedence_rank"] == %{"0" => 1}

    assert campaign["station_pressure_contact_ids_by_precedence_rank"] == %{
             "0" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_counts_by_status"] == %{
             "maintenance_window" => 1
           }

    assert campaign["station_pressure_contact_ids_by_status"] == %{
             "maintenance_window" => ["dl_campaign_station"]
           }

    assert campaign["station_pressure_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{"gs_campaign" => ["dl_campaign_station"]}
           }

    assert campaign["capacity_pack_required_capacity_fraction"] == 0.25
    assert campaign["capacity_pack_selected_required_capacity_fraction"] == 0.25
    assert campaign["capacity_pack_deferred_required_capacity_fraction"] == 0.0

    assert campaign["capacity_pack_required_capacity_fraction_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => 0.25
           }

    assert campaign["capacity_pack_required_capacity_fraction_by_ground_station_id"] == %{
             "gs_campaign" => 0.25
           }

    assert campaign["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"] ==
             %{
               "gs_campaign" => 0.25
             }

    refute Map.has_key?(
             campaign,
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
           )

    assert campaign["capacity_pack_contact_ids_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => ["dl_campaign_pack"]
           }

    assert campaign["required_capacity_fraction_source_counts"] == %{
             "contact_required_capacity_fraction" => 1
           }

    assert campaign["required_capacity_fraction_contact_ids_by_source"] == %{
             "contact_required_capacity_fraction" => ["dl_campaign_pack"]
           }

    assert campaign["capacity_pack_contact_ids_by_ground_station_id"] == %{
             "gs_campaign" => ["dl_campaign_pack"]
           }

    assert campaign["capacity_pack_selected_contact_ids_by_ground_station_id"] == %{
             "gs_campaign" => ["dl_campaign_pack"]
           }

    refute Map.has_key?(campaign, "capacity_pack_deferred_contact_ids_by_ground_station_id")

    assert campaign["reduced_capacity_pack_group_count"] == 1
    assert campaign["reduced_capacity_pack_status_counts"] == %{"all_fit" => 1}
    assert campaign["capacity_pack_group_ids"] == ["pack_campaign"]
    assert campaign["capacity_pack_group_ids_by_status"] == %{"all_fit" => ["pack_campaign"]}

    assert campaign["reduced_capacity_packed_contact_ids"] == ["dl_campaign_pack"]
    refute Map.has_key?(campaign, "reduced_capacity_deferred_contact_ids")

    assert refresh["station_reservation_ids"] == ["reservation_refresh"]
    assert refresh["station_reserved_bys"] == ["ops_refresh"]
    assert refresh["station_reservation_statuses"] == ["tentative"]
    assert refresh["station_reservation_match_status_counts"] == %{"overlap" => 2}
    assert refresh["station_reservation_expiration_status_counts"] == %{"missing" => 2}
    assert refresh["station_reservation_declared_expiration_contact_count"] == 0
    assert refresh["station_reservation_missing_expiration_contact_count"] == 2
    assert refresh["resource_blocking_dimension_counts"] == %{"thermal" => 2}

    assert refresh["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "thermal" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
           }

    assert refresh["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_refresh" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
           }

    assert refresh["station_pressure_contact_count"] == 2
    assert refresh["station_pressure_review_contact_count"] == 1
    assert refresh["station_pressure_review_contact_ids"] == ["dl_refresh_station_a"]

    assert refresh["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_refresh" => 2
           }

    assert refresh["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_refresh" => ["dl_refresh_station_a", "dl_refresh_station_b"]
           }

    assert refresh["station_pressure_contact_counts_by_availability"] == %{"reserved" => 2}

    assert refresh["station_pressure_contact_ids_by_availability"] == %{
             "reserved" => ["dl_refresh_station_a", "dl_refresh_station_b"]
           }

    assert refresh["station_pressure_contact_counts_by_precedence_availability"] == %{
             "reserved" => 1
           }

    assert refresh["station_pressure_contact_ids_by_precedence_availability"] == %{
             "reserved" => ["dl_refresh_station_a"]
           }

    assert refresh["station_pressure_contact_counts_by_precedence_rank"] == %{"1" => 1}

    assert refresh["station_pressure_contact_ids_by_precedence_rank"] == %{
             "1" => ["dl_refresh_station_a"]
           }

    assert refresh["station_pressure_contact_counts_by_status"] == %{
             "reservation_hold" => 2
           }

    assert refresh["station_pressure_contact_ids_by_status"] == %{
             "reservation_hold" => ["dl_refresh_station_a", "dl_refresh_station_b"]
           }

    assert refresh["station_pressure_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{
               "gs_refresh" => ["dl_refresh_station_a", "dl_refresh_station_b"]
             }
           }

    assert refresh["capacity_pack_required_capacity_fraction"] == 0.5
    assert refresh["capacity_pack_selected_required_capacity_fraction"] == 0.25
    assert refresh["capacity_pack_deferred_required_capacity_fraction"] == 0.25

    assert refresh["capacity_pack_required_capacity_fraction_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => 0.25,
             "deferred_by_reduced_station_capacity_pack" => 0.25
           }

    assert refresh["capacity_pack_required_capacity_fraction_by_ground_station_id"] == %{
             "gs_refresh" => 0.5
           }

    assert refresh["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"] == %{
             "gs_refresh" => 0.25
           }

    assert refresh["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"] == %{
             "gs_refresh" => 0.25
           }

    assert refresh["capacity_pack_contact_ids_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => ["dl_refresh_pack"],
             "deferred_by_reduced_station_capacity_pack" => ["dl_refresh_deferred"]
           }

    assert refresh["required_capacity_fraction_source_counts"] == %{
             "contact_required_capacity_fraction" => 1,
             "default_reduced_capacity_policy" => 1
           }

    assert refresh["required_capacity_fraction_contact_ids_by_source"] == %{
             "contact_required_capacity_fraction" => ["dl_refresh_pack"],
             "default_reduced_capacity_policy" => ["dl_refresh_deferred"]
           }

    assert refresh["capacity_pack_contact_ids_by_ground_station_id"] == %{
             "gs_refresh" => ["dl_refresh_pack", "dl_refresh_deferred"]
           }

    assert refresh["capacity_pack_selected_contact_ids_by_ground_station_id"] == %{
             "gs_refresh" => ["dl_refresh_pack"]
           }

    assert refresh["capacity_pack_deferred_contact_ids_by_ground_station_id"] == %{
             "gs_refresh" => ["dl_refresh_deferred"]
           }

    assert refresh["reduced_capacity_pack_group_count"] == 2
    assert refresh["reduced_capacity_pack_status_counts"] == %{"capacity_limited" => 2}
    assert refresh["capacity_pack_group_ids"] == ["pack_refresh_a", "pack_refresh_b"]

    assert refresh["capacity_pack_group_ids_by_status"] == %{
             "capacity_limited" => ["pack_refresh_a", "pack_refresh_b"]
           }

    assert refresh["reduced_capacity_packed_contact_ids"] == ["dl_refresh_pack"]
    assert refresh["reduced_capacity_deferred_contact_ids"] == ["dl_refresh_deferred"]

    assert repair["station_reservation_ids"] == ["reservation_source", "reservation_result"]
    assert repair["station_reserved_bys"] == ["ops_source", "ops_result"]
    assert repair["station_reservation_statuses"] == ["confirmed", "released"]
    assert repair["station_reservation_match_status_counts"] == %{"matched" => 2, "overlap" => 1}

    assert repair["station_reservation_expiration_status_counts"] == %{
             "declared" => 2,
             "missing" => 1
           }

    assert repair["station_reservation_declared_expiration_contact_count"] == 2
    assert repair["station_reservation_missing_expiration_contact_count"] == 1
    assert repair["earliest_station_reservation_expires_at_s"] == 520.0

    assert repair["station_reservation_contact_ids_by_expiration_status"] == %{
             "declared" => ["dl_result_a", "dl_result_b"],
             "missing" => ["dl_source"]
           }

    assert repair["station_reservation_ids_by_expiration_status"] == %{
             "declared" => ["reservation_result"],
             "missing" => ["reservation_source"]
           }

    assert repair["station_reservation_contact_ids_by_match_status"] == %{
             "matched" => ["dl_result_a", "dl_result_b"],
             "overlap" => ["dl_source"]
           }

    assert repair["station_reservation_contact_ids_by_status"] == %{
             "confirmed" => ["dl_source"],
             "released" => ["dl_result_a", "dl_result_b"]
           }

    assert repair["station_reservation_contact_ids_by_reserved_by"] == %{
             "ops_result" => ["dl_result_a", "dl_result_b"],
             "ops_source" => ["dl_source"]
           }

    assert repair["station_reservation_ids_by_match_status"] == %{
             "matched" => ["reservation_result"],
             "overlap" => ["reservation_source"]
           }

    assert repair["station_reservation_ids_by_status"] == %{
             "confirmed" => ["reservation_source"],
             "released" => ["reservation_result"]
           }

    assert repair["station_reservation_ids_by_reserved_by"] == %{
             "ops_result" => ["reservation_result"],
             "ops_source" => ["reservation_source"]
           }

    assert repair["resource_blocking_dimension_counts"] == %{"activity_type" => 2, "antenna" => 1}

    assert repair["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "activity_type" => ["dl_result_resource_a", "dl_result_resource_b"],
             "antenna" => ["dl_source_resource"]
           }

    assert repair["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_result" => ["dl_result_resource_a", "dl_result_resource_b"],
             "sat_source" => ["dl_source_resource"]
           }

    assert repair["station_pressure_contact_count"] == 3
    assert repair["station_pressure_review_contact_count"] == 1
    assert repair["station_pressure_review_contact_ids"] == ["dl_source_station"]

    assert repair["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_result" => 2,
             "gs_source" => 1
           }

    assert repair["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_station_a", "dl_result_station_b"],
             "gs_source" => ["dl_source_station"]
           }

    assert repair["station_pressure_contact_counts_by_availability"] == %{
             "reserved" => 2,
             "unavailable" => 1
           }

    assert repair["station_pressure_contact_ids_by_availability"] == %{
             "reserved" => ["dl_result_station_a", "dl_result_station_b"],
             "unavailable" => ["dl_source_station"]
           }

    assert repair["station_pressure_contact_counts_by_precedence_availability"] == %{
             "reserved" => 2
           }

    assert repair["station_pressure_contact_ids_by_precedence_availability"] == %{
             "reserved" => ["dl_result_station_a", "dl_result_station_b"]
           }

    assert repair["station_pressure_contact_counts_by_precedence_rank"] == %{"2" => 2}

    assert repair["station_pressure_contact_ids_by_precedence_rank"] == %{
             "2" => ["dl_result_station_a", "dl_result_station_b"]
           }

    assert_in_delta repair["capacity_pack_required_capacity_fraction"], 0.95, 1.0e-9
    assert repair["capacity_pack_selected_required_capacity_fraction"] == 0.4
    assert_in_delta repair["capacity_pack_deferred_required_capacity_fraction"], 0.55, 1.0e-9

    assert repair["capacity_pack_required_capacity_fraction_by_status"][
             "selected_by_reduced_station_capacity_pack"
           ] == 0.4

    assert_in_delta repair["capacity_pack_required_capacity_fraction_by_status"][
                      "deferred_by_reduced_station_capacity_pack"
                    ],
                    0.55,
                    1.0e-9

    assert repair["capacity_pack_required_capacity_fraction_by_ground_station_id"][
             "gs_result"
           ] == 0.6

    assert repair["capacity_pack_required_capacity_fraction_by_ground_station_id"][
             "gs_source"
           ] == 0.35

    assert repair["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"] == %{
             "gs_result" => 0.4
           }

    assert repair["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"][
             "gs_result"
           ] == 0.2

    assert repair["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"][
             "gs_source"
           ] == 0.35

    assert repair["capacity_pack_contact_ids_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => ["dl_result_pack"],
             "deferred_by_reduced_station_capacity_pack" => [
               "dl_result_deferred",
               "dl_source_deferred"
             ]
           }

    assert repair["required_capacity_fraction_source_counts"] == %{
             "activity_context" => 1,
             "capacity_model" => 1,
             "throughput_model" => 1
           }

    assert repair["required_capacity_fraction_contact_ids_by_source"] == %{
             "activity_context" => ["dl_result_deferred"],
             "capacity_model" => ["dl_source_deferred"],
             "throughput_model" => ["dl_result_pack"]
           }

    assert repair["capacity_pack_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_pack", "dl_result_deferred"],
             "gs_source" => ["dl_source_deferred"]
           }

    assert repair["capacity_pack_selected_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_pack"]
           }

    assert repair["capacity_pack_deferred_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_deferred"],
             "gs_source" => ["dl_source_deferred"]
           }

    assert repair["reduced_capacity_pack_group_count"] == 3

    assert repair["reduced_capacity_pack_status_counts"] == %{
             "all_fit" => 2,
             "capacity_limited" => 1
           }

    assert repair["capacity_pack_group_ids"] == [
             "pack_source",
             "pack_result_a",
             "pack_result_b"
           ]

    assert repair["capacity_pack_group_ids_by_status"] == %{
             "all_fit" => ["pack_result_a", "pack_result_b"],
             "capacity_limited" => ["pack_source"]
           }

    assert repair["reduced_capacity_packed_contact_ids"] == ["dl_result_pack"]

    assert repair["reduced_capacity_deferred_contact_ids"] == [
             "dl_source_deferred",
             "dl_result_deferred"
           ]

    assert strategy["station_reservation_ids"] == ["reservation_source", "reservation_result"]
    assert strategy["station_reserved_bys"] == ["ops_source", "ops_result"]
    assert strategy["station_reservation_statuses"] == ["confirmed", "released"]

    assert strategy["station_reservation_match_status_counts"] == %{
             "matched" => 2,
             "overlap" => 1
           }

    assert strategy["station_reservation_expiration_status_counts"] == %{
             "declared" => 2,
             "missing" => 1
           }

    assert strategy["station_reservation_declared_expiration_contact_count"] == 2
    assert strategy["station_reservation_missing_expiration_contact_count"] == 1
    assert strategy["earliest_station_reservation_expires_at_s"] == 520.0

    assert strategy["station_reservation_contact_ids_by_match_status"] == %{
             "matched" => ["dl_result_a", "dl_result_b"],
             "overlap" => ["dl_source"]
           }

    assert strategy["station_reservation_contact_ids_by_status"] == %{
             "confirmed" => ["dl_source"],
             "released" => ["dl_result_a", "dl_result_b"]
           }

    assert strategy["station_reservation_contact_ids_by_reserved_by"] == %{
             "ops_result" => ["dl_result_a", "dl_result_b"],
             "ops_source" => ["dl_source"]
           }

    assert strategy["station_reservation_ids_by_match_status"] == %{
             "matched" => ["reservation_result"],
             "overlap" => ["reservation_source"]
           }

    assert strategy["station_reservation_ids_by_status"] == %{
             "confirmed" => ["reservation_source"],
             "released" => ["reservation_result"]
           }

    assert strategy["station_reservation_ids_by_reserved_by"] == %{
             "ops_result" => ["reservation_result"],
             "ops_source" => ["reservation_source"]
           }

    assert strategy["resource_blocking_dimension_counts"] == %{
             "activity_type" => 2,
             "antenna" => 1
           }

    assert strategy["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "activity_type" => ["dl_result_resource_a", "dl_result_resource_b"],
             "antenna" => ["dl_source_resource"]
           }

    assert strategy["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_result" => ["dl_result_resource_a", "dl_result_resource_b"],
             "sat_source" => ["dl_source_resource"]
           }

    assert strategy["station_pressure_contact_count"] == 3
    assert strategy["station_pressure_review_contact_count"] == 1
    assert strategy["station_pressure_review_contact_ids"] == ["dl_source_station"]

    assert strategy["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_result" => 2,
             "gs_source" => 1
           }

    assert strategy["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_station_a", "dl_result_station_b"],
             "gs_source" => ["dl_source_station"]
           }

    assert strategy["station_pressure_contact_counts_by_availability"] == %{
             "reserved" => 2,
             "unavailable" => 1
           }

    assert strategy["station_pressure_contact_ids_by_availability"] == %{
             "reserved" => ["dl_result_station_a", "dl_result_station_b"],
             "unavailable" => ["dl_source_station"]
           }

    assert strategy["station_pressure_contact_counts_by_precedence_availability"] ==
             %{"reserved" => 2}

    assert strategy["station_pressure_contact_ids_by_precedence_availability"] == %{
             "reserved" => ["dl_result_station_a", "dl_result_station_b"]
           }

    assert strategy["station_pressure_contact_counts_by_precedence_rank"] == %{"2" => 2}

    assert strategy["station_pressure_contact_ids_by_precedence_rank"] == %{
             "2" => ["dl_result_station_a", "dl_result_station_b"]
           }

    assert_in_delta strategy["capacity_pack_required_capacity_fraction"], 0.95, 1.0e-9
    assert strategy["capacity_pack_selected_required_capacity_fraction"] == 0.4
    assert_in_delta strategy["capacity_pack_deferred_required_capacity_fraction"], 0.55, 1.0e-9

    assert strategy["capacity_pack_required_capacity_fraction_by_status"][
             "selected_by_reduced_station_capacity_pack"
           ] == 0.4

    assert_in_delta strategy["capacity_pack_required_capacity_fraction_by_status"][
                      "deferred_by_reduced_station_capacity_pack"
                    ],
                    0.55,
                    1.0e-9

    assert strategy["capacity_pack_required_capacity_fraction_by_ground_station_id"][
             "gs_result"
           ] == 0.6

    assert strategy["capacity_pack_required_capacity_fraction_by_ground_station_id"][
             "gs_source"
           ] == 0.35

    assert strategy["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"] ==
             %{"gs_result" => 0.4}

    assert strategy["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"][
             "gs_result"
           ] == 0.2

    assert strategy["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"][
             "gs_source"
           ] == 0.35

    assert strategy["capacity_pack_contact_ids_by_status"] == %{
             "selected_by_reduced_station_capacity_pack" => ["dl_result_pack"],
             "deferred_by_reduced_station_capacity_pack" => [
               "dl_result_deferred",
               "dl_source_deferred"
             ]
           }

    assert strategy["required_capacity_fraction_source_counts"] == %{
             "activity_context" => 1,
             "capacity_model" => 1,
             "throughput_model" => 1
           }

    assert strategy["required_capacity_fraction_contact_ids_by_source"] == %{
             "activity_context" => ["dl_result_deferred"],
             "capacity_model" => ["dl_source_deferred"],
             "throughput_model" => ["dl_result_pack"]
           }

    assert strategy["capacity_pack_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_pack", "dl_result_deferred"],
             "gs_source" => ["dl_source_deferred"]
           }

    assert strategy["capacity_pack_selected_contact_ids_by_ground_station_id"] ==
             %{"gs_result" => ["dl_result_pack"]}

    assert strategy["capacity_pack_deferred_contact_ids_by_ground_station_id"] == %{
             "gs_result" => ["dl_result_deferred"],
             "gs_source" => ["dl_source_deferred"]
           }

    assert strategy["reduced_capacity_pack_group_count"] == 3

    assert strategy["reduced_capacity_pack_status_counts"] == %{
             "all_fit" => 2,
             "capacity_limited" => 1
           }

    assert strategy["capacity_pack_group_ids"] == [
             "pack_source",
             "pack_result_a",
             "pack_result_b"
           ]

    assert strategy["capacity_pack_group_ids_by_status"] == %{
             "all_fit" => ["pack_result_a", "pack_result_b"],
             "capacity_limited" => ["pack_source"]
           }

    assert strategy["reduced_capacity_packed_contact_ids"] == ["dl_result_pack"]

    assert strategy["reduced_capacity_deferred_contact_ids"] == [
             "dl_source_deferred",
             "dl_result_deferred"
           ]

    for package <- [campaign, refresh, repair, strategy] do
      assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
               Schema.validate_artifact(package)
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

  defp provider_counteroffer_report do
    OrbitalDynamics.provider_counteroffer_report(
      [
        %{
          id: :provider_counteroffer_window,
          provider_id: :ops_calendar,
          ground_station_id: :dss_14,
          starts_at_s: 130.0,
          ends_at_s: 170.0,
          counteroffer_id: :provider_offer_1,
          counteroffer_status: :proposed,
          counteroffer_reason_code: :provider_shifted_window,
          counteroffer_cost_delta: 125.5,
          counteroffer_lock_deadline_s: 150.0,
          counteroffer_starts_at_s: 160.0,
          counteroffer_ends_at_s: 210.0
        }
      ],
      source: :cadence_supported_source_fixture
    )
  end

  defp contact_allocation_summary(counts, summary) do
    %{
      "schema_contract" => "contact_allocation_report.v1",
      "calendar_entry_trust_boundary_status_counts" => counts,
      "rows" => []
    }
    |> Map.merge(summary)
  end

  defp score_term_report do
    %{
      "schema_contract" => "score_term_report.v1",
      "model" => "ranked_timeline_score_terms",
      "source" => "campaign_plan.score_terms",
      "row_count" => 2,
      "score_term_keys" => ["activity_count_penalty", "target_value"],
      "rows" => [
        %{
          "id" => "score_term:leo_1:1:target_value",
          "rank" => 1,
          "scenario_id" => "leo_1",
          "term_key" => "target_value",
          "value" => 120.0,
          "timeline_score" => 140.0,
          "selected" => true
        },
        %{
          "id" => "score_term:leo_1:1:activity_count_penalty",
          "rank" => 1,
          "scenario_id" => "leo_1",
          "term_key" => "activity_count_penalty",
          "value" => -10.0,
          "timeline_score" => 140.0,
          "selected" => true
        }
      ],
      "assumptions" => %{"score_model" => "transparent_term_sum"}
    }
  end

  defp objective_tradeoff_report do
    %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "model" => "ranked_timeline_score_term_tradeoffs",
      "objective" => "campaign_timeline_score",
      "ranking_count" => 2,
      "score_term_keys" => ["activity_count_penalty", "target_value"],
      "tradeoffs" => [
        %{
          "rank" => 1,
          "scenario_id" => "leo_1",
          "score" => 140.0,
          "score_delta_from_selected" => 0.0,
          "activity_count" => 2,
          "selected_observation_count" => 1,
          "selected_contact_count" => 1,
          "score_terms" => %{"target_value" => 150.0, "activity_count_penalty" => -10.0},
          "activity_ids" => ["leo_1_observe_target_a_1", "leo_1_downlink_1"]
        },
        %{
          "rank" => 2,
          "scenario_id" => "leo_2",
          "score" => 95.0,
          "score_delta_from_selected" => -45.0,
          "activity_count" => 1,
          "selected_observation_count" => 1,
          "selected_contact_count" => 0,
          "score_terms" => %{"target_value" => 100.0, "activity_count_penalty" => -5.0},
          "activity_ids" => ["leo_2_observe_target_b_1"]
        }
      ],
      "assumptions" => %{"selected_rank" => 1}
    }
  end

  defp constraint_report do
    %{
      "schema_contract" => "constraint_report.v1",
      "model" => "artifact_metric_threshold",
      "status" => "fail",
      "constraint_count" => 2,
      "row_count" => 3,
      "status_counts" => %{"fail" => 1, "pass" => 1, "warning" => 1},
      "assumptions" => %{
        "constraint_model" => "artifact_level_metric_thresholds",
        "missing_or_nil_values" => "fail",
        "source" => "study_metadata.constraints"
      },
      "rows" => [
        %{
          "constraint_id" => "minimum_operational_altitude",
          "metric" => "min_altitude_km",
          "operator" => ">=",
          "scenario_id" => "dispersion_1",
          "score" => 0.42,
          "status" => "pass",
          "threshold" => 621.5,
          "value" => 621.92
        },
        %{
          "constraint_id" => "minimum_operational_altitude",
          "metric" => "min_altitude_km",
          "operator" => ">=",
          "scenario_id" => "dispersion_2",
          "score" => -0.31,
          "status" => "fail",
          "threshold" => 621.5,
          "value" => 621.19
        },
        %{
          "constraint_id" => "downlink_margin",
          "metric" => "estimated_throughput_mb",
          "operator" => ">=",
          "scenario_id" => "dispersion_3",
          "status" => "warning",
          "threshold" => 120.0
        }
      ]
    }
  end

  defp operational_readiness_resource_report do
    %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => "operational_readiness:resource_pressure",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_resource_pressure",
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
          "id" => "resource_availability",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "resource availability evidence requires operator review before import",
          "resource_availability_pressure_count" => 3,
          "resource_availability_reason_counts" => %{
            "antenna_unavailable" => 1,
            "ground_station_reserved" => 1,
            "payload_unavailable" => 1
          },
          "resource_blocking_dimension_counts" => %{"communications" => 2}
        }
      ],
      "evidence" => %{
        "review_required_count" => 1,
        "resource_availability_pressure_count" => 3,
        "resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "ground_station_reserved" => 1,
          "payload_unavailable" => 1
        },
        "resource_blocking_dimension_counts" => %{"communications" => 2}
      }
    }
  end

  defp analysis_only_operational_readiness_report do
    operational_readiness_resource_report()
    |> Map.merge(%{
      "readiness_level" => "analysis_only",
      "import_classification" => "analysis_only",
      "status" => "analysis_only",
      "review_gate_count" => 0,
      "analysis_gate_count" => 1,
      "assumptions" => %{"not_for_execution" => true},
      "model_limits" => ["artifact_only", "does_not_write_cadence"]
    })
    |> update_in(["gates", Access.at(0)], fn gate ->
      Map.merge(gate, %{
        "status" => "analysis_only",
        "classification" => "analysis_only",
        "reason" => "resource availability gate is analysis-only before execution",
        "analysis_mode" => "not_for_execution",
        "analysis_mode_source" => "operator_review_fixture"
      })
    end)
  end

  defp stale_import_readiness_quality_gate_report do
    operational_readiness_resource_report()
    |> Map.merge(%{
      "report_id" => "operational_readiness:stale_import_readiness",
      "source_artifact_id" => "activity_stale_import_readiness",
      "gates" => [
        %{
          "id" => "cadence_import",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "source freshness evidence is stale or unknown",
          "ready_for_import_count" => 1,
          "manifest_review_required_count" => 0,
          "blocked_import_count" => 0,
          "missing_import_count" => 0,
          "invalid_cadence_import_count" => 0,
          "current_freshness_count" => 0,
          "stale_freshness_count" => 1,
          "unknown_freshness_count" => 0,
          "freshness_status_counts" => %{"stale" => 1},
          "schema_validation_pass_count" => 1,
          "schema_validation_fail_count" => 0,
          "schema_validation_error_count" => 0,
          "schema_validation_warning_count" => 0,
          "schema_validation_remediation_count" => 0,
          "schema_validation_status_counts" => %{"pass" => 1},
          "import_status_counts" => %{"ready_for_import" => 1},
          "cadence_import_status_counts" => %{"present" => 1}
        }
      ],
      "evidence" => %{
        "ready_for_import_count" => 1,
        "stale_freshness_count" => 1,
        "freshness_status_counts" => %{"stale" => 1},
        "schema_validation_pass_count" => 1,
        "schema_validation_status_counts" => %{"pass" => 1},
        "import_status_counts" => %{"ready_for_import" => 1},
        "cadence_import_status_counts" => %{"present" => 1}
      }
    })
    |> OrbitalDynamics.operational_quality_gate_report()
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

  defp candidate_diff_report do
    %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "invalidated_candidates" => [
        %{
          "id" => "old_refresh_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "source_window_id" => "window:leo_1:target_visibility:target_a:old",
          "starts_at_s" => 90.0,
          "ends_at_s" => 150.0,
          "replacement_candidate_id" => "refresh_observe",
          "invalidated_reason" => "replaced_by_semantically_similar_candidate",
          "semantic_change_reasons" => [
            "starts_at_s_changed",
            "source_window_id_changed"
          ],
          "semantic_change_details" => [
            %{
              "field" => "starts_at_s",
              "reason" => "starts_at_s_changed",
              "prior_value" => 90.0,
              "refreshed_value" => 100.0
            }
          ]
        }
      ],
      "source_window_lineage" => [
        %{
          "schema_contract" => "source_window_lineage.v1",
          "candidate_activity_id" => "refresh_observe",
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "source_window_type" => "target_visibility",
          "scenario_id" => "leo_1",
          "source_window" => %{
            "schema_contract" => "refreshed_window.v1",
            "id" => "window:leo_1:target_visibility:target_a:1",
            "type" => "target_visibility",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "duration_s" => 60.0
          }
        }
      ]
    }
  end

  defp analysis_only_quality_gate_report do
    operational_readiness_resource_report()
    |> Map.merge(%{
      "readiness_level" => "analysis_only",
      "import_classification" => "analysis_only",
      "status" => "analysis_only",
      "review_gate_count" => 0,
      "analysis_gate_count" => 1
    })
    |> update_in(["gates", Access.at(0)], fn gate ->
      Map.merge(gate, %{
        "status" => "analysis_only",
        "classification" => "analysis_only",
        "reason" => "resource availability gate is analysis-only before execution"
      })
    end)
    |> OrbitalDynamics.operational_quality_gate_report()
  end

  defp objective_satisfaction_report do
    %{
      "schema_contract" => "objective_satisfaction_report.v1",
      "source" => "campaign_plan.activities",
      "model" => "campaign_v1_selected_activity_objective_summary",
      "objective_count" => 4,
      "rows" => [
        %{
          "id" => "objective:target_coverage",
          "objective" => "target_coverage",
          "status" => "partial",
          "required_count" => 2,
          "candidate_count" => 1,
          "selected_count" => 1,
          "satisfied_count" => 1,
          "candidate_target_ids" => ["target_a"],
          "selected_target_ids" => ["target_a"]
        },
        %{
          "id" => "objective:downlink_completion",
          "objective" => "downlink_completion",
          "status" => "unmet",
          "required_downlink_mb" => 150.0,
          "candidate_downlink_mb" => 160.0,
          "candidate_count" => 1,
          "selected_count" => 0,
          "satisfied_count" => 0,
          "selected_downlink_mb" => 0.0,
          "satisfied_downlink_mb" => 0.0,
          "selected_contact_ids" => []
        },
        %{
          "id" => "objective:target_commitment:target_a",
          "objective" => "target_commitment",
          "target_id" => "target_a",
          "status" => "selected",
          "required_count" => 1,
          "candidate_count" => 1,
          "selected_count" => 1,
          "satisfied_count" => 1,
          "selected_activity_ids" => ["leo_1_observe_target_a_1"]
        },
        %{
          "id" => "objective:target_commitment:target_b",
          "objective" => "target_commitment",
          "target_id" => "target_b",
          "status" => "no_candidate_window",
          "required_count" => 1,
          "candidate_count" => 0,
          "selected_count" => 0,
          "satisfied_count" => 0,
          "selected_activity_ids" => []
        }
      ],
      "assumptions" => %{"selection" => "best_ranked_timeline_is_selected"}
    }
  end

  defp resource_projection_flow_summary do
    activities = [
      %{
        id: :dl_late,
        type: :downlink,
        scenario_id: :leo_1,
        starts_at_s: 20.0,
        estimated_throughput_mb: 10.0,
        estimated_energy_generated_wh: 5.0
      },
      %{
        id: :obs_early,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 10.0,
        collection_ends_at_s: 15.0,
        planned_delivery_at_s: 45.0,
        max_latency_s: 20.0,
        estimated_storage_mb: 30.0,
        estimated_energy_used_wh: 20.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :leo_1,
        storage_capacity_mb: 50.0,
        storage_used_mb: 30.0,
        downlink_capacity_mb: 5.0,
        battery_capacity_wh: 100.0,
        battery_energy_used_wh: 10.0
      }
    ]

    OrbitalDynamics.resource_projection_flow_report(activities, summaries, source: "flow_handoff")
  end

  defp provider_reservation_request_summary do
    %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.provider_reservation_request_summary",
      "provider_reservation_candidate_contact_count" => 2,
      "provider_reservation_request_contact_count" => 1,
      "provider_reservation_review_contact_count" => 1,
      "provider_reservation_no_request_contact_count" => 1,
      "provider_reservation_request_status" => "review_required",
      "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
      "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
      "provider_reservation_no_request_contact_ids" => ["dl_unreserved"],
      "provider_reservation_request_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["dl_review_overlap"]
      },
      "provider_reservation_no_request_contact_ids_by_direction" => %{
        "uplink" => ["dl_unreserved"]
      },
      "provider_reservation_request_contact_ids_by_direction" => %{
        "downlink" => ["dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_direction" => %{
        "command" => ["dl_review_overlap"]
      },
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" => %{
        "uplink" => %{"equator_prime" => ["dl_unreserved"]}
      },
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" => %{
        "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
      },
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" => %{
        "command" => %{"equator_prime" => ["dl_review_overlap"]}
      },
      "provider_reservation_request_contact_ids_by_match_status" => %{
        "matched" => ["dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_match_status" => %{
        "overlap" => ["dl_review_overlap"]
      },
      "provider_reservation_request_ids_by_match_status" => %{
        "matched" => ["reservation_1"]
      },
      "provider_reservation_review_ids_by_match_status" => %{
        "overlap" => ["reservation_review"]
      },
      "provider_reservation_request_rows" => [
        %{
          "contact_id" => "dl_reserved_owner",
          "allocation_status" => "allocated",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "station_reservation_id" => "reservation_1",
          "station_reservation_match_status" => "matched",
          "station_reservation_status" => "confirmed"
        }
      ],
      "provider_reservation_review_rows" => [
        %{
          "contact_id" => "dl_review_overlap",
          "allocation_status" => "allocated",
          "ground_station_id" => "equator_prime",
          "direction" => "command",
          "station_reservation_id" => "reservation_review",
          "station_reservation_match_status" => "overlap",
          "station_reservation_status" => "confirmed"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "provider_reservation_execution" => "not_performed_by_summary"
      }
    }
  end

  defp station_reservation_summary_fixture(filename) do
    study_result_fixture(filename)
  end

  defp study_result_fixture(filename) do
    ["study_results", filename]
    |> Path.join()
    |> File.read!()
    |> :json.decode()
  end

  defp station_reservation_hold_import_readiness_summary do
    %{
      "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_hold_count" => 2,
      "import_readiness_status" => "review_required",
      "import_classification" => "review_only",
      "ready_for_import_count" => 0,
      "review_required_before_import_count" => 2,
      "no_import_required_count" => 0,
      "reservation_hold_import_status_counts" => %{
        "review_required_before_import" => 2
      },
      "required_import_action_counts" => %{
        "review_station_provider_contention" => 1,
        "review_station_reservation_overlap" => 1
      },
      "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
      "reservation_hold_ids_by_import_status" => %{
        "review_required_before_import" => ["reservation_expired", "reservation_missing"]
      },
      "reservation_hold_ids_by_required_import_action" => %{
        "review_station_provider_contention" => ["reservation_missing"],
        "review_station_reservation_overlap" => ["reservation_expired"]
      },
      "reservation_hold_contact_ids_by_import_status" => %{
        "review_required_before_import" => ["dl_source_reserved"]
      },
      "reservation_hold_contact_ids_by_expiration_status" => %{
        "expired" => ["dl_source_reserved"]
      },
      "import_readiness_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "dl_source_reserved",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "reservation_ids" => ["reservation_expired"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_calendar"],
          "station_reservation_expiration_status" => "expired",
          "station_reservation_hold_import_status" => "review_required_before_import",
          "required_operator_action" => "review_station_reservation_overlap"
        },
        %{
          "reservation_review_row_type" => "provider_calendar_contention_group",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 95.0,
          "ends_at_s" => 165.0,
          "reservation_ids" => ["reservation_missing"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_calendar"],
          "station_reservation_expiration_status" => "missing",
          "station_reservation_hold_import_status" => "review_required_before_import",
          "required_operator_action" => "review_station_provider_contention"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
        "provider_write" => "not_performed_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "reservation_acceptance" => "not_performed_by_summary"
      }
    }
  end

  defp timeline_integrity_report do
    Timeline.integrity_report(
      [
        %{id: :health_gate, type: :health_check, starts_at_s: 20.0, ends_at_s: 30.0},
        %{
          id: :dl_conflict,
          type: :downlink,
          timeline_id: :"timeline:downlink:12.0",
          starts_at_s: 12.0,
          ends_at_s: 25.0,
          exclusive_with: [:cmd_main],
          exclusive_with_timeline_ids: [
            :"timeline:command:dss_14:10.0",
            :"timeline:command:dss_14:10.0"
          ]
        },
        %{
          id: :cmd_main,
          type: :command,
          timeline_id: :"timeline:command:dss_14:10.0",
          starts_at_s: 10.0,
          ends_at_s: 15.0,
          ground_station_id: :dss_14,
          dependency_activity_ids: [:missing_gate, :health_gate, :health_gate],
          dependency_timeline_ids: [
            :"timeline:missing_gate",
            :"timeline:health_gate",
            :"timeline:health_gate"
          ],
          exclusive_with: [:dl_conflict],
          exclusive_with_timeline_ids: [:"timeline:downlink:12.0"],
          activity_template: %{
            "schema_contract" => "activity_template.v1",
            "id" => "template:command:basic",
            "activity_type" => "command",
            "template_version" => 1,
            "validation_level" => "artifact_contract"
          }
        }
      ],
      source: "selected_activities"
    )
  end

  defp timeline_transition_application_summary do
    {source, replacement} = timeline_transition_application_pair()

    source
    |> Timeline.transition_application_report(replacement, source: "transition_summary_source")
    |> Timeline.transition_application_summary()
  end

  defp timeline_diff_summary do
    {source, replacement} = timeline_diff_pair()

    source
    |> Timeline.diff_report(replacement, source: "diff_summary_source")
    |> Timeline.diff_summary()
  end

  defp timeline_diff_pair do
    source = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :dl_removed,
        type: :downlink,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:dl_removed"}
      }
    ]

    replacement = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 15.0,
        ends_at_s: 25.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :cmd_added,
        type: :command,
        starts_at_s: 50.0,
        ends_at_s: 60.0,
        metadata: %{timeline_id: :"timeline:cmd_added"}
      }
    ]

    {source, replacement}
  end

  defp timeline_transition_application_pair do
    source = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :obs_self_dependency,
        type: :observe,
        target_id: :target_a,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        depends_on: [:obs_self_dependency],
        metadata: %{timeline_id: :"timeline:obs_self_dependency"}
      }
    ]

    replacement = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 15.0,
        ends_at_s: 25.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :cmd_added,
        type: :command,
        starts_at_s: 40.0,
        ends_at_s: 50.0,
        metadata: %{timeline_id: :"timeline:cmd_added"}
      },
      %{
        id: :obs_self_dependency,
        type: :observe,
        target_id: :target_a,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        depends_on: [:obs_self_dependency],
        metadata: %{timeline_id: :"timeline:obs_self_dependency"}
      }
    ]

    {source, replacement}
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp result_artifact_failed_execution_report do
    "study_results/ground_track_crossings.json"
    |> read_json!()
    |> get_in(["execution_report"])
    |> Map.put("status", "completed_with_errors")
    |> Map.put("failed_scenario_count", 1)
    |> Map.put("failed_scenarios", [
      %{
        "scenario_id" => "ground_track_1",
        "scenario_index" => 0,
        "stage" => "propagation",
        "error" => ["task_timeout", 30_000],
        "resumability" => "manual_rerun_only",
        "retry_recommendation" => "rerun_failed_scenario_from_source_manifest"
      }
    ])
  end
end
