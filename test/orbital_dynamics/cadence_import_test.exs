defmodule OrbitalDynamics.CadenceImportTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.Policy
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Timeline

  test "declares artifact-only import manifest capabilities" do
    assert %{
             artifact_contract: "cadence_import_manifest.v1",
             model: :artifact_only_cadence_import_manifest,
             supported_sources: [
               "campaign_plan.v1",
               "campaign_repair.v2",
               "campaign_strategy.v3",
               "candidate_refresh.v1",
               "proposed_contact.v1",
               "planned_activity.v1",
               "realized_activity.v1",
               "realized_state_snapshot.v1",
               "result_artifact.v1",
               "timeline_feedback_report.v1",
               "operational_timeline_report.v1",
               "contact_contention_report.v1",
               "contact_contention_resolution_report.v1",
               "command_window_report.v1",
               "station_calendar_report.v1",
               "station_reservation_report.v1",
               "link_capacity_report.v1",
               "contact_allocation_report.v1",
               "contact_allocation_capacity_pack_summary.v1",
               "contact_allocation_reservation_conflict_summary.v1",
               "resource_projection_report.v1",
               "resource_projection_flow_summary.v1",
               "contact_intent.v1",
               "contact_filter_report.v1",
               "candidate_rejection_report.v1",
               "provider_counteroffer_report.v1",
               "candidate_diff_report.v1",
               "invalidated_candidate.v1",
               "resource_filter_report.v1",
               "freshness_report.v1",
               "refresh_budget_report.v1",
               "constraint_report.v1",
               "objective_satisfaction_report.v1",
               "maneuver_recommendation.v1",
               "maneuver_execution_delta.v1",
               "maneuver_review_report.v1",
               "timeline_diff_report.v1",
               "timeline_diff_summary.v1",
               "timeline_dependency_impact_summary.v1",
               "timeline_publication_summary.v1",
               "timeline_activity_precondition_summary.v1",
               "timeline_activity_state.v1",
               "timeline_activity_status_state.v1",
               "timeline_activity_approval_state.v1",
               "timeline_activity_lifecycle_state.v1",
               "timeline_lifecycle_state_summary.v1",
               "timeline_preservation_report.v1",
               "timeline_preservation_status.v1",
               "timeline_integrity_report.v1",
               "timeline_transition_application_summary.v1",
               "timeline_transition_application_report.v1",
               "approval_requirement.v1",
               "policy_decision.v1",
               "branch_comparison_report.v1",
               "ranking_comparison_report.v1",
               "score_term_report.v1",
               "objective_tradeoff_report.v1",
               "pareto_frontier_report.v1",
               "schema_validation_report.v1",
               "schema_validation_batch_report.v1",
               "execution_report.v1",
               "operational_readiness_report.v1",
               "quality_gate_report.v1",
               "operator_review_package.v1"
             ],
             import_actions: import_actions,
             source_review_types: source_review_types,
             import_statuses: import_statuses,
             cadence_import_statuses: cadence_import_statuses,
             provider_result_map_value_keys: provider_result_map_value_keys,
             handoff_row_semantics: handoff_row_semantics,
             known_limits: known_limits
           } = CadenceImport.capability()

    assert "import_proposed_contact" in import_actions
    assert "import_strategy_recommendation" in import_actions
    assert "review_strategy_branch_alternative" in import_actions
    assert "record_realized_feedback" in import_actions
    assert "review_realized_feedback" in import_actions
    assert "review_operational_timeline" in import_actions
    assert "review_contact_contention" in import_actions
    assert "review_contact_contention_resolution" in import_actions
    assert "review_command_window" in import_actions
    assert "review_station_calendar" in import_actions
    assert "review_station_reservation" in import_actions
    assert "review_link_capacity" in import_actions
    assert "review_contact_allocation" in import_actions
    assert "review_provider_reservation_request" in import_actions
    assert "review_contact_intent" in import_actions
    assert "review_candidate_rejection" in import_actions
    assert "review_provider_counteroffer" in import_actions
    assert "review_candidate_diff" in import_actions
    assert "review_refresh_freshness" in import_actions
    assert "review_refresh_budget" in import_actions
    assert "review_constraint" in import_actions
    assert "review_objective_satisfaction" in import_actions
    assert "review_resource_projection" in import_actions
    assert "review_contact_suppression" in import_actions
    assert "review_resource_suppression" in import_actions
    assert "review_maneuver" in import_actions
    assert "review_timeline_diff" in import_actions
    assert "review_timeline_dependency_impact" in import_actions
    assert "review_timeline_publication" in import_actions
    assert "review_timeline_precondition" in import_actions
    assert "review_timeline_lifecycle_state" in import_actions
    assert "review_timeline_preservation" in import_actions
    assert "review_timeline_integrity" in import_actions
    assert "review_approval_requirement" in import_actions
    assert "review_policy_escalation" in import_actions
    assert "review_strategy_tradeoff" in import_actions
    assert "review_score_term" in import_actions
    assert "review_objective_tradeoff" in import_actions
    assert "review_ranking_comparison" in import_actions
    assert "review_pareto_frontier" in import_actions
    assert "review_schema_validation" in import_actions
    assert "review_execution" in import_actions
    assert "review_operational_readiness" in import_actions
    assert "review_quality_gate" in import_actions
    assert "import_replacement_activity" in import_actions
    assert "record_preserved_executed_activity" in import_actions
    assert "plan_delta_review" in source_review_types
    assert "timeline_activity_precondition_review" in source_review_types
    assert "timeline_publication_review" in source_review_types
    assert "timeline_lifecycle_state_review" in source_review_types
    assert "timeline_integrity_review" in source_review_types
    assert "station_reservation_review" in source_review_types
    assert "proposed_contact" in source_review_types
    assert "strategy_branch_comparison" in source_review_types
    assert "quality_gate_review" in source_review_types
    assert "ready_for_import" in import_statuses
    assert "review_required_before_import" in import_statuses
    assert "blocked_missing_cadence_import" in import_statuses
    assert "not_applicable" in import_statuses
    assert "present" in cadence_import_statuses
    assert "missing" in cadence_import_statuses
    assert "invalid" in cadence_import_statuses
    assert "not_applicable" in cadence_import_statuses
    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys
    assert :schema_validation_import_rows in handoff_row_semantics
    assert :schema_validation_issue_context in handoff_row_semantics
    assert :schema_validation_batch_nested_report_context in handoff_row_semantics
    assert :operational_readiness_import_rows in handoff_row_semantics
    assert :operational_readiness_gate_rows in handoff_row_semantics
    assert :operational_readiness_resource_summary_context in handoff_row_semantics
    assert :operational_readiness_resource_gate_context in handoff_row_semantics
    assert :operational_readiness_adapter_boundary_context in handoff_row_semantics
    assert :operational_readiness_cadence_import_gate_context in handoff_row_semantics
    assert :quality_gate_import_rows in handoff_row_semantics
    assert :quality_gate_resource_row_context in handoff_row_semantics
    assert :timeline_diff_summary_import_rows in handoff_row_semantics
    assert :timeline_diff_summary_source_handoff_consistency in handoff_row_semantics
    assert :timeline_dependency_impact_import_rows in handoff_row_semantics
    assert :timeline_dependency_impact_source_handoff_consistency in handoff_row_semantics
    assert :timeline_publication_import_rows in handoff_row_semantics
    assert :timeline_publication_source_handoff_consistency in handoff_row_semantics
    assert :timeline_lifecycle_state_import_rows in handoff_row_semantics
    assert :timeline_lifecycle_state_source_handoff_consistency in handoff_row_semantics
    assert :timeline_activity_precondition_import_rows in handoff_row_semantics
    assert :timeline_activity_precondition_source_handoff_consistency in handoff_row_semantics
    assert :timeline_preservation_import_rows in handoff_row_semantics
    assert :timeline_preservation_source_handoff_consistency in handoff_row_semantics
    assert :timeline_integrity_import_rows in handoff_row_semantics
    assert :timeline_integrity_source_handoff_consistency in handoff_row_semantics
    assert :timeline_transition_application_summary_import_rows in handoff_row_semantics

    assert :timeline_transition_application_summary_source_handoff_consistency in handoff_row_semantics

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
    assert :review_package_passthrough_rows in handoff_row_semantics
    assert :does_not_write_cadence in known_limits
    assert :review_rows_are_adapter_handoff_not_operator_approval in known_limits

    assert {:ok, schema} = Schema.json_schema("cadence_import_manifest.v1")
    expected_model_limits = Enum.map(known_limits, &Atom.to_string/1)

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             expected_model_limits

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             expected_model_limits

    supported_sources = CadenceImport.capability().supported_sources

    schema_supported_sources =
      get_in(schema, ["properties", "source_artifact_type", "enum"])

    assert Enum.sort(supported_sources) == Enum.sort(schema_supported_sources)

    schema_actions =
      get_in(schema, ["properties", "rows", "items", "properties", "import_action", "enum"])

    assert Enum.sort(import_actions) == Enum.sort(schema_actions)

    schema_source_review_types =
      get_in(schema, ["properties", "rows", "items", "properties", "source_review_type", "enum"])

    assert Enum.sort(source_review_types) == Enum.sort(schema_source_review_types)

    schema_import_statuses =
      get_in(schema, ["properties", "rows", "items", "properties", "import_status", "enum"])

    assert Enum.sort(import_statuses) == Enum.sort(schema_import_statuses)

    schema_cadence_import_statuses =
      get_in(schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "cadence_import_status",
        "enum"
      ])

    assert Enum.sort(cadence_import_statuses) == Enum.sort(schema_cadence_import_statuses)
  end

  test "advertised supported sources have compatible import fixtures" do
    fixtures = cadence_supported_source_fixtures()
    supported_sources = CadenceImport.capability().supported_sources

    assert Enum.sort(Map.keys(fixtures)) == Enum.sort(supported_sources)

    for source <- supported_sources do
      artifact = cadence_supported_source_fixture!(fixtures, source)
      manifest = CadenceImport.manifest(artifact)

      unless source == "operator_review_package.v1" do
        assert manifest["source_artifact_type"] == source
      end

      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "rejects unsupported import inputs with adapter boundary errors" do
    assert_raise ArgumentError,
                 ~r/unsupported Cadence import artifact contract "unknown_contract.v1"/,
                 fn ->
                   CadenceImport.manifest(%{"schema_contract" => "unknown_contract.v1"})
                 end

    assert_raise ArgumentError,
                 ~r/supported contracts: .*campaign_plan\.v1.*execution_report\.v1/s,
                 fn ->
                   CadenceImport.manifest(%{schema_contract: :unknown_contract})
                 end

    assert_raise ArgumentError, ~r/Cadence import artifact must be a map/, fn ->
      CadenceImport.manifest(:not_an_artifact)
    end
  end

  test "builds operational readiness import rows with top-level resource reason context" do
    report = operational_readiness_resource_report()
    manifest = CadenceImport.from_operational_readiness_report(report)

    assert CadenceImport.manifest(report) == manifest
    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "operational_readiness_report.v1",
             "source_artifact_id" => "operational_readiness:resource_pressure",
             "row_count" => 2,
             "review_required_count" => 2,
             "source_review_type_counts" => %{"operational_readiness_review" => 2},
             "import_action_counts" => %{"review_operational_readiness" => 2},
             "source_readiness_report_id" => "operational_readiness:resource_pressure",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "gate_count" => 1,
             "passed_gate_count" => 0,
             "review_gate_count" => 1,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0
           } = manifest

    summary_row =
      Enum.find(
        manifest["rows"],
        &(&1["subject_id"] == "operational_readiness:resource_pressure")
      )

    assert %{
             "import_action" => "review_operational_readiness",
             "source_review_type" => "operational_readiness_review",
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
             "source_review_row" => %{
               "station_availability_reason_ids" => ["ground_station_reserved"],
               "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
               "unavailable_resource_reason_ids" => [
                 "antenna_unavailable",
                 "payload_unavailable"
               ]
             }
           } = summary_row

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn rows ->
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
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{
            "subject_id" => "operational_readiness:resource_pressure",
            "source_operational_readiness_report" => %{} = source_report
          } = row ->
            Map.put(
              row,
              "source_operational_readiness_report",
              Map.put(source_report, "readiness_level", "blocked")
            )

          row ->
            row
        end)
      end)

    assert {:error, stale_source_report_result} = Schema.validate_artifact(stale_source_report)

    assert Enum.any?(
             stale_source_report_result["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_operational_readiness_report.readiness_level" and
                 &1["message"] == "must match readiness_level on handoff row")
           )

    stale_source_review =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{
            "subject_id" => "operational_readiness:resource_pressure",
            "source_review_row" => %{} = source_review_row
          } = row ->
            source_review_row =
              source_review_row
              |> Map.put("operational_readiness_status", "passed")
              |> Map.put("resource_availability_pressure_count", 1)

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.operational_readiness_status" and
                 &1["message"] ==
                   "must match operational_readiness_status on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.resource_availability_pressure_count" and
                 &1["message"] ==
                   "must match resource_availability_pressure_count on Cadence import row")
           )

    stale_source_gate =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_operational_readiness_gate" => %{} = source_gate} = row ->
            Map.put(
              row,
              "source_operational_readiness_gate",
              Map.put(source_gate, "status", "passed")
            )

          row ->
            row
        end)
      end)

    assert {:error, stale_source_gate_report} = Schema.validate_artifact(stale_source_gate)

    assert Enum.any?(
             stale_source_gate_report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_operational_readiness_gate\.status$/ and
                 &1["message"] == "must match readiness_gate_status on handoff row")
           )
  end

  test "operational readiness analysis-only rows remain not-applicable import handoffs" do
    report = analysis_only_operational_readiness_report()
    manifest = CadenceImport.from_operational_readiness_report(report)

    assert %{
             "source_artifact_type" => "operational_readiness_report.v1",
             "source_artifact_id" => "operational_readiness:resource_pressure",
             "row_count" => 2,
             "ready_count" => 0,
             "review_required_count" => 0,
             "blocked_count" => 0,
             "import_status_counts" => %{"not_applicable" => 2},
             "cadence_import_status_counts" => %{"not_applicable" => 2},
             "source_review_action_counts" => %{
               "record_operational_readiness_analysis_only" => 2
             },
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "analysis_gate_count" => 1,
             "review_gate_count" => 0
           } = manifest

    summary_row =
      Enum.find(
        manifest["rows"],
        &(&1["subject_id"] == "operational_readiness:resource_pressure")
      )

    assert %{
             "import_action" => "review_operational_readiness",
             "import_status" => "not_applicable",
             "source_review_type" => "operational_readiness_review",
             "source_review_action" => "record_operational_readiness_analysis_only",
             "approval_status" => "not_required",
             "required_operator_action" => "record_operational_readiness_analysis_only",
             "cadence_import_status" => "not_applicable",
             "source_review_row" => %{
               "approval_status" => "not_required",
               "cadence_import_status" => "not_applicable",
               "required_operator_action" => "record_operational_readiness_analysis_only"
             },
             "source_operational_readiness_report" => %{
               "assumptions" => %{"not_for_execution" => true},
               "model_limits" => ["artifact_only", "does_not_write_cadence"]
             }
           } = summary_row

    assert %{
             "import_status" => "not_applicable",
             "source_review_action" => "record_operational_readiness_analysis_only",
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
               manifest["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds quality gate import rows with resource reason context" do
    report = quality_gate_report()
    manifest = CadenceImport.from_quality_gate_report(report)

    assert CadenceImport.manifest(report) == manifest
    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "quality_gate_report.v1",
             "source_artifact_id" =>
               "quality_gate:planned_activity.v1:activity_resource_pressure",
             "row_count" => 1,
             "review_required_count" => 1,
             "source_review_type_counts" => %{"quality_gate_review" => 1},
             "import_action_counts" => %{"review_quality_gate" => 1},
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
           } = manifest

    assert manifest["gate_ids_by_status"] == report["gate_ids_by_status"]
    assert manifest["gate_ids_by_classification"] == report["gate_ids_by_classification"]
    assert manifest["quality_gate_row_ids_by_status"] == report["quality_gate_row_ids_by_status"]

    assert manifest["quality_gate_row_ids_by_classification"] ==
             report["quality_gate_row_ids_by_classification"]

    assert manifest["review_required_gate_ids"] == report["review_required_gate_ids"]

    assert [
             %{
               "import_action" => "review_quality_gate",
               "source_review_type" => "quality_gate_review",
               "quality_gate_id" => "resource_availability",
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
                 "gate_id" => "resource_availability"
               },
               "source_quality_gate_report" => %{
                 "schema_contract" => "quality_gate_report.v1"
               },
               "source_review_row" => %{
                 "station_availability_reason_ids" => ["ground_station_reserved"],
                 "unavailable_resource_reason_ids" => [
                   "antenna_unavailable",
                   "payload_unavailable"
                 ]
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn rows ->
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
      update_in(manifest, ["rows", Access.at(0), "source_quality_gate_report"], fn report ->
        Map.put(report, "report_id", "quality_gate:wrong_report")
      end)

    assert {:error, stale_source_report_result} = Schema.validate_artifact(stale_source_report)

    assert Enum.any?(
             stale_source_report_result["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.report_id" and
                 &1["message"] == "must match quality_gate_report_id on handoff row")
           )

    stale_source_review =
      update_in(manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        row
        |> Map.put("quality_gate_status", "blocked")
        |> Map.put("resource_availability_pressure_count", 1)
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.quality_gate_status" and
                 &1["message"] == "must match quality_gate_status on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.resource_availability_pressure_count" and
                 &1["message"] ==
                   "must match resource_availability_pressure_count on Cadence import row")
           )

    stale_source_quality_gate =
      update_in(manifest, ["rows", Access.at(0), "source_quality_gate_row"], fn row ->
        Map.put(row, "status", "passed")
      end)

    assert {:error, stale_source_quality_gate_report} =
             Schema.validate_artifact(stale_source_quality_gate)

    assert Enum.any?(
             stale_source_quality_gate_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_row.status" and
                 &1["message"] == "must match quality_gate_status on handoff row")
           )

    stale_source_quality_gate_resource_context =
      update_in(manifest, ["rows", Access.at(0), "source_quality_gate_row"], fn row ->
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

  test "quality gate import rows preserve import readiness context" do
    report = stale_import_readiness_quality_gate_report()
    source_row = Enum.find(report["rows"], &(&1["gate_id"] == "cadence_import"))

    manifest = CadenceImport.from_quality_gate_report(report)

    assert [
             %{
               "import_action" => "review_quality_gate",
               "import_status" => "review_required_before_import",
               "source_review_type" => "quality_gate_review",
               "source_review_action" => "review_quality_gate",
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
               "source_quality_gate_row" => ^source_row,
               "source_review_row" => %{
                 "ready_for_import_count" => 1,
                 "stale_freshness_count" => 1,
                 "freshness_status_counts" => %{"stale" => 1},
                 "schema_validation_status_counts" => %{"pass" => 1},
                 "import_status_counts" => %{"ready_for_import" => 1},
                 "cadence_import_status_counts" => %{"present" => 1}
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "quality gate analysis-only rows remain not-applicable import handoffs" do
    report = analysis_only_quality_gate_report()
    manifest = CadenceImport.from_quality_gate_report(report)

    assert %{
             "source_artifact_type" => "quality_gate_report.v1",
             "row_count" => 1,
             "ready_count" => 0,
             "review_required_count" => 0,
             "blocked_count" => 0,
             "import_status_counts" => %{"not_applicable" => 1},
             "cadence_import_status_counts" => %{"not_applicable" => 1},
             "source_review_action_counts" => %{"record_quality_gate_analysis_only" => 1},
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "analysis_gate_count" => 1,
             "review_gate_count" => 0
           } = manifest

    assert [
             %{
               "import_action" => "review_quality_gate",
               "import_status" => "not_applicable",
               "source_review_type" => "quality_gate_review",
               "source_review_action" => "record_quality_gate_analysis_only",
               "approval_status" => "not_required",
               "required_operator_action" => "record_quality_gate_analysis_only",
               "cadence_import_status" => "not_applicable",
               "quality_gate_id" => "resource_availability",
               "quality_gate_status" => "analysis_only",
               "quality_gate_classification" => "analysis_only",
               "source_review_row" => %{
                 "approval_status" => "not_required",
                 "cadence_import_status" => "not_applicable",
                 "required_operator_action" => "record_quality_gate_analysis_only"
               },
               "source_quality_gate_row" => %{
                 "status" => "analysis_only",
                 "classification" => "analysis_only"
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "passes through already-built Cadence import manifest artifacts" do
    manifest = read_json!("study_results/cadence_import_manifest_v1.json")

    assert CadenceImport.manifest(manifest) == manifest
    assert OrbitalDynamics.cadence_import_manifest(manifest) == manifest

    atom_key_manifest = %{
      schema_contract: "cadence_import_manifest.v1",
      source_artifact_type: "campaign_repair.v2",
      source_artifact_id: "repair:pass_through",
      rows: []
    }

    assert CadenceImport.manifest(atom_key_manifest) == %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "campaign_repair.v2",
             "source_artifact_id" => "repair:pass_through",
             "rows" => []
           }
  end

  test "builds import manifest from score term report rows" do
    report = score_term_report()

    manifest = CadenceImport.from_score_term_report(report)

    assert CadenceImport.manifest(report) == manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "score_term_report.v1",
             "source_artifact_id" => "campaign_plan.score_terms",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_score_term" => 2},
             "source_review_type_counts" => %{"score_term_review" => 2},
             "source_review_action_counts" => %{"review_score_term" => 2},
             "source_review_queue_counts" => %{
               "score_term_review|review_score_term|operator_review_required" => 2
             }
           } = manifest

    assert %{
             "import_action" => "review_score_term",
             "import_status" => "review_required_before_import",
             "source_review_type" => "score_term_review",
             "source_review_action" => "review_score_term",
             "source_review_queue" => "review_score_term",
             "source_review_queue_key" =>
               "score_term_review|review_score_term|operator_review_required",
             "subject_id" => "score_term:leo_1:1:target_value",
             "scenario_id" => "leo_1",
             "term_key" => "target_value",
             "value" => 120.0,
             "timeline_score" => 140.0,
             "selected" => true,
             "source_score_term" => %{"term_key" => "target_value"}
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_review =
      manifest
      |> put_in(["rows", Access.at(0), "value"], 121.0)
      |> put_in(["rows", Access.at(0), "source_score_term", "value"], 121.0)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.value" and
                 &1["message"] == "must match value on Cadence import row")
           )

    stale_model_limits = Map.put(manifest, "model_limits", ["does_not_write_cadence"])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match Cadence import manifest model limits")
           )
  end

  test "builds import manifest from objective tradeoff report rows" do
    report = objective_tradeoff_report()

    manifest = CadenceImport.from_objective_tradeoff_report(report)

    assert CadenceImport.manifest(report) == manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "objective_tradeoff_report.v1",
             "source_artifact_id" => "objective_tradeoff_report",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_objective_tradeoff" => 2}
           } = manifest

    assert %{
             "import_action" => "review_objective_tradeoff",
             "import_status" => "review_required_before_import",
             "source_review_type" => "objective_tradeoff_review",
             "source_review_action" => "review_objective_tradeoff",
             "subject_id" => "leo_2",
             "scenario_id" => "leo_2",
             "score" => 95.0,
             "score_delta_from_selected" => -45.0,
             "activity_count" => 1,
             "score_terms" => %{"target_value" => 100.0, "activity_count_penalty" => -5.0},
             "activity_ids" => ["leo_2_observe_target_b_1"],
             "source_objective_tradeoff" => %{"scenario_id" => "leo_2"}
           } = List.last(manifest["rows"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_review =
      manifest
      |> put_in(["rows", Access.at(1), "score"], 96.0)
      |> put_in(["rows", Access.at(1), "source_objective_tradeoff", "score"], 96.0)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[1].source_review_row.score" and
                 &1["message"] == "must match score on Cadence import row")
           )
  end

  test "builds import manifest from schema validation report failures" do
    report = schema_validation_report()

    manifest = CadenceImport.from_schema_validation_report(report)

    assert CadenceImport.manifest(
             %{schema_contract: "schema_validation_report.v1"}
             |> Map.merge(report)
           ) ==
             manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "schema_validation_report.v1",
             "source_artifact_id" => "schema_validation:campaign_plan.v1:artifact_file:fail",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_schema_validation" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_schema_validation",
               "import_status" => "review_required_before_import",
               "source_review_type" => "schema_validation_review",
               "source_review_action" => "review_schema_validation_failure",
               "subject_id" => "campaign_plan.v1",
               "schema_validation_gate" => "artifact_contract_validation",
               "schema_validation_gate_status" => "fail",
               "schema_validation_issue_count" => 1,
               "validation_status" => "fail",
               "validated_contract" => "campaign_plan.v1",
               "issue_path" => "$.plan_id",
               "remediation_category" => "missing_required_field",
               "source_schema_validation_report" => %{"status" => "fail"}
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_status =
      update_in(manifest, ["rows"], fn [row] ->
        [Map.put(row, "validation_status", "pass")]
      end)

    assert {:error, invalid_source_status_report} =
             Schema.validate_artifact(invalid_source_status)

    assert Enum.any?(
             invalid_source_status_report["errors"],
             &(&1["path"] == "$.rows[0].source_schema_validation_report.status" and
                 &1["message"] == "must match validation_status")
           )

    stale_source_review =
      update_in(manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        row
        |> Map.put("validation_status", "pass")
        |> Map.put("error_count", 0)
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.validation_status" and
                 &1["message"] == "must match validation_status on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.error_count" and
                 &1["message"] == "must match error_count on Cadence import row")
           )
  end

  test "builds import manifest from execution report failures" do
    report = read_json!("study_results/execution_report_v1.json")

    manifest = CadenceImport.from_execution_report(report)

    assert CadenceImport.manifest(%{schema_contract: "execution_report.v1"} |> Map.merge(report)) ==
             manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "execution_report.v1",
             "source_artifact_id" =>
               "execution:large_monte_carlo:large_monte_carlo-2026-05-14T00:00:00Z",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_execution" => 1}
           } = manifest

    assert [
             %{
               "id" => "cadence_import:execution:execution:trial_1842:propagation:1",
               "import_action" => "review_execution",
               "import_status" => "review_required_before_import",
               "source_review_type" => "execution_review",
               "source_review_action" => "review_execution_failure",
               "subject_id" => "trial_1842",
               "scenario_id" => "trial_1842",
               "scenario_index" => 1841,
               "execution_status" => "completed_with_errors",
               "execution_mode" => "distributed_task_supervisors",
               "execution_stage" => "propagation",
               "execution_error" => ["task_timeout", 30000],
               "resumability" => "manual_rerun_only",
               "retry_recommendation" => "rerun_failed_scenario_from_source_manifest",
               "failed_scenario_count" => 1,
               "source_execution_failure" => %{"scenario_id" => "trial_1842"},
               "source_execution_report" => %{"schema_contract" => "execution_report.v1"},
               "source_review_row" => %{"review_type" => "execution_review"}
             }
           ] = manifest["rows"]

    completed_manifest =
      report
      |> Map.put("status", "completed")
      |> Map.put("failed_scenario_count", 0)
      |> Map.put("failed_scenarios", [])
      |> CadenceImport.from_execution_report()

    assert %{"row_count" => 0, "import_action_counts" => %{}} = completed_manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_status =
      update_in(manifest, ["rows"], fn [row] ->
        [Map.put(row, "execution_status", "completed")]
      end)

    assert {:error, invalid_source_status_report} =
             Schema.validate_artifact(invalid_source_status)

    assert Enum.any?(
             invalid_source_status_report["errors"],
             &(&1["path"] == "$.rows[0].source_execution_report.status" and
                 &1["message"] == "must match execution_status")
           )

    stale_source_review =
      update_in(manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        row
        |> Map.put("execution_status", "completed")
        |> Map.put("retry_recommendation", "ignore_failure")
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.execution_status" and
                 &1["message"] == "must match execution_status on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.retry_recommendation" and
                 &1["message"] == "must match retry_recommendation on Cadence import row")
           )
  end

  test "builds import manifest from result artifact execution failures" do
    artifact =
      "study_results/ground_track_crossings.json"
      |> read_json!()
      |> put_in(["execution_report"], result_artifact_failed_execution_report())

    manifest = CadenceImport.from_result_artifact(artifact)

    assert OrbitalDynamics.cadence_import_manifest(artifact) == manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "result_artifact.v1",
             "source_artifact_id" =>
               "result_artifact:ground_track_crossings:ground_track_crossings-20260514",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_execution" => 1}
           } = manifest

    assert [
             %{
               "id" => "cadence_import:execution:execution:ground_track_1:propagation:1",
               "import_action" => "review_execution",
               "import_status" => "review_required_before_import",
               "source_review_type" => "execution_review",
               "source_review_action" => "review_execution_failure",
               "subject_id" => "ground_track_1",
               "scenario_id" => "ground_track_1",
               "execution_status" => "completed_with_errors",
               "source_review_row" => %{
                 "review_type" => "execution_review",
                 "source" => "result_artifact.execution_report.failed_scenarios"
               }
             }
           ] = manifest["rows"]

    completed_artifact = read_json!("study_results/ground_track_crossings.json")

    assert %{"row_count" => 0, "import_action_counts" => %{}} =
             CadenceImport.from_result_artifact(completed_artifact)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "lifts result artifact nested constraint and maneuver review rows into import manifest" do
    artifact =
      "study_results/ground_track_crossings.json"
      |> read_json!()
      |> Map.put("constraint_report", constraint_report())
      |> Map.put(
        "maneuver_review_report",
        read_json!("study_results/maneuver_review_report_v1.json")
      )

    manifest = CadenceImport.from_result_artifact(artifact)

    assert %{
             "source_artifact_type" => "result_artifact.v1",
             "row_count" => 3,
             "import_action_counts" => %{"review_constraint" => 2, "review_maneuver" => 1},
             "source_review_type_counts" => %{
               "constraint_review" => 2,
               "maneuver_review" => 1
             }
           } = manifest

    assert %{
             "import_action" => "review_constraint",
             "source_review_type" => "constraint_review",
             "source_review_row" => %{
               "source" => "result_artifact.constraint_report.rows",
               "constraint_id" => "minimum_operational_altitude"
             }
           } =
             Enum.find(manifest["rows"], &(&1["source_review_type"] == "constraint_review"))

    assert %{
             "import_action" => "review_maneuver",
             "source_review_type" => "maneuver_review",
             "source_review_row" => %{
               "source" => "result_artifact.maneuver_review_report.rows",
               "maneuver_id" => "trim_burn"
             }
           } =
             Enum.find(manifest["rows"], &(&1["source_review_type"] == "maneuver_review"))

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "deduplicates result artifact maneuver recommendation imports when review report is embedded" do
    maneuver_review_report = read_json!("study_results/maneuver_review_report_v1.json")

    recommendation =
      maneuver_review_report["rows"] |> List.first() |> Map.fetch!("source_recommendation")

    artifact =
      "study_results/ground_track_crossings.json"
      |> read_json!()
      |> Map.put("maneuver_review_report", maneuver_review_report)
      |> Map.put("maneuver_recommendations", [recommendation])

    manifest = CadenceImport.from_result_artifact(artifact)

    assert %{
             "source_artifact_type" => "result_artifact.v1",
             "row_count" => 1,
             "import_action_counts" => %{"review_maneuver" => 1},
             "source_review_type_counts" => %{"maneuver_review" => 1},
             "rows" => [
               %{
                 "import_action" => "review_maneuver",
                 "source_review_type" => "maneuver_review",
                 "source_review_row" => %{
                   "source" => "result_artifact.maneuver_review_report.rows",
                   "maneuver_id" => "trim_burn"
                 }
               }
             ]
           } = manifest

    refute Enum.any?(
             manifest["rows"],
             &(get_in(&1, ["source_review_row", "source"]) ==
                 "result_artifact.maneuver_recommendations")
           )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds import manifest from failing and warning constraint report rows" do
    report = constraint_report()

    manifest = CadenceImport.from_constraint_report(report)

    assert CadenceImport.manifest(%{schema_contract: "constraint_report.v1"} |> Map.merge(report)) ==
             manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "constraint_report.v1",
             "source_artifact_id" => "study_metadata.constraints",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_constraint" => 2}
           } = manifest

    assert Enum.map(manifest["rows"], & &1["constraint_status"]) == ["fail", "warning"]

    assert %{
             "id" =>
               "cadence_import:constraint:constraint:minimum_operational_altitude:dispersion_2:2",
             "import_action" => "review_constraint",
             "import_status" => "review_required_before_import",
             "source_review_type" => "constraint_review",
             "source_review_action" => "review_constraint",
             "subject_id" => "dispersion_2",
             "scenario_id" => "dispersion_2",
             "constraint_id" => "minimum_operational_altitude",
             "metric" => "min_altitude_km",
             "operator" => ">=",
             "threshold" => 621.5,
             "value" => 621.19,
             "score" => -0.31,
             "constraint_status" => "fail",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_constraint",
             "source_constraint_row" => %{"status" => "fail"},
             "source_review_row" => %{"review_type" => "constraint_review"}
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_review =
      manifest
      |> put_in(["rows", Access.at(0), "constraint_status"], "warning")
      |> put_in(["rows", Access.at(0), "source_constraint_row", "status"], "warning")

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.constraint_status" and
                 &1["message"] == "must match constraint_status on Cadence import row")
           )
  end

  test "builds import manifest from unmet objective satisfaction rows" do
    report = objective_satisfaction_report()

    manifest = CadenceImport.from_objective_satisfaction_report(report)

    assert CadenceImport.manifest(report) == manifest

    assert %{
             "source_artifact_type" => "objective_satisfaction_report.v1",
             "source_artifact_id" => "campaign_plan.activities",
             "row_count" => 3,
             "review_required_count" => 3,
             "import_action_counts" => %{"review_objective_satisfaction" => 3}
           } = manifest

    assert Enum.map(manifest["rows"], & &1["objective_status"]) == [
             "partial",
             "unmet",
             "no_candidate_window"
           ]

    assert %{
             "import_action" => "review_objective_satisfaction",
             "import_status" => "review_required_before_import",
             "source_review_type" => "objective_satisfaction_review",
             "subject_id" => "objective:target_coverage",
             "objective" => "target_coverage",
             "objective_status" => "partial",
             "required_count" => 2,
             "candidate_count" => 1,
             "selected_count" => 1,
             "satisfied_count" => 1,
             "candidate_target_ids" => ["target_a"],
             "selected_target_ids" => ["target_a"],
             "source_objective_satisfaction" => %{"status" => "partial"},
             "source_review_row" => %{"review_type" => "objective_satisfaction_review"}
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_review =
      manifest
      |> put_in(["rows", Access.at(0), "objective_status"], "unmet")
      |> put_in(["rows", Access.at(0), "source_objective_satisfaction", "status"], "unmet")

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.objective_status" and
                 &1["message"] == "must match objective_status on Cadence import row")
           )
  end

  test "builds import manifest from schema validation batch report failures" do
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

    manifest = CadenceImport.from_schema_validation_batch_report(batch)

    assert CadenceImport.manifest(
             %{schema_contract: "schema_validation_batch_report.v1"}
             |> Map.merge(batch)
           ) == manifest

    assert %{
             "source_artifact_type" => "schema_validation_batch_report.v1",
             "source_artifact_id" => "schema_validation_batch:artifact_directory:fail",
             "row_count" => 1,
             "import_action_counts" => %{"review_schema_validation" => 1},
             "rows" => [
               %{
                 "import_action" => "review_schema_validation",
                 "source_review_action" => "review_schema_validation_failure",
                 "source_review_row" => %{
                   "action" => "review_schema_validation_failure"
                 },
                 "schema_validation_gate" => "artifact_contract_validation",
                 "schema_validation_gate_status" => "fail",
                 "validated_contract" => "campaign_plan.v1",
                 "artifact_path" => "study_results/bad_campaign.json",
                 "issue_path" => "$.plan_id",
                 "source_schema_validation_report" => %{
                   "batch_entry_path" => "study_results/bad_campaign.json"
                 }
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "schema_validation_batch_report.v1"}} =
             Schema.validate_artifact(batch)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds import manifest from standalone candidate refresh review rows" do
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
            "classification" => "operator_review_required"
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
            "review_status" => "operator_review_required"
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
            "selected_downlink_shortfall_mb" => 0.0,
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
            "suppressed_reason" => "payload_unavailable",
            "payload_available" => false
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

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert OrbitalDynamics.cadence_import_manifest(artifact) == manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:ops_state:001",
             "row_count" => 10,
             "review_required_count" => 10,
             "import_action_counts" => %{
               "review_contact_intent" => 1,
               "review_contact_allocation" => 1,
               "review_candidate_rejection" => 1,
               "review_candidate_diff" => 1,
               "review_refresh_freshness" => 1,
               "review_refresh_budget" => 1,
               "review_operational_readiness" => 1,
               "review_contact_suppression" => 1,
               "review_resource_suppression" => 1,
               "review_warning" => 1
             }
           } = manifest

    assert get_in(manifest, ["provenance", "run_input_sources"]) == %{
             "accepted_planning_state" => ["candidate_refresh.mission_state.spacecraft_states"],
             "targets" => ["candidate_refresh.mission_state.objectives"],
             "ground_stations" => ["candidate_refresh.mission_state.ground_network"]
           }

    assert %{
             "import_action" => "review_contact_intent",
             "source_review_type" => "contact_intent_review",
             "contact_intent_gate" => "contact_intent_policy",
             "contact_intent_gate_status" => "operator_review_required",
             "run_input_sources" => %{
               "accepted_planning_state" => [
                 "candidate_refresh.mission_state.spacecraft_states"
               ]
             },
             "source_review_row" => %{
               "source" => "candidate_refresh.contact_intents",
               "run_input_sources" => %{
                 "targets" => ["candidate_refresh.mission_state.objectives"]
               },
               "source_contact_intent" => %{"schema_contract" => "contact_intent.v1"}
             }
           } = Enum.find(manifest["rows"], &(&1["import_action"] == "review_contact_intent"))

    assert %{
             "import_action" => "review_candidate_diff",
             "source_review_type" => "candidate_diff_review",
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
             "source_candidate_diff" => %{"id" => "old_refresh_observe"},
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
             "source_review_row" => %{
               "run_input_sources" => %{
                 "ground_stations" => ["candidate_refresh.mission_state.ground_network"]
               },
               "replacement_source_window" => %{
                 "id" => "window:leo_1:target_visibility:target_a:1"
               }
             }
           } = Enum.find(manifest["rows"], &(&1["import_action"] == "review_candidate_diff"))

    assert %{
             "import_action" => "review_candidate_rejection",
             "source_review_type" => "candidate_rejection_review",
             "subject_id" => "refresh_downlink_reserved",
             "activity_id" => "refresh_downlink_reserved",
             "primary_rejection_reason" => "station_reserved",
             "source_candidate_rejection" => %{
               "candidate_id" => "refresh_downlink_reserved"
             },
             "source_review_row" => %{
               "source" => "candidate_refresh.candidate_rejection_report.rows"
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["import_action"] == "review_candidate_rejection")
             )

    assert %{
             "import_action" => "review_refresh_freshness",
             "source_review_type" => "freshness_review",
             "subject_id" => "freshness:stale",
             "freshness_status" => "stale",
             "source_freshness_report" => %{"status" => "stale"}
           } = Enum.find(manifest["rows"], &(&1["import_action"] == "review_refresh_freshness"))

    assert %{
             "import_action" => "review_refresh_budget",
             "source_review_type" => "refresh_budget_review",
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["old_refresh_downlink"],
             "source_refresh_budget_report" => %{"schema_contract" => "refresh_budget_report.v1"}
           } = Enum.find(manifest["rows"], &(&1["import_action"] == "review_refresh_budget"))

    assert %{
             "import_action" => "review_operational_readiness",
             "source_review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.provenance.source_reports.operational_readiness_report",
             "subject_id" => "candidate_refresh.operational_readiness_source_reports",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_operational_readiness",
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
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_report.v1",
               "paths" => ["mission_state.source_operational_readiness_report"]
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.provenance.source_reports.operational_readiness_report",
               "source_operational_readiness_report" => %{
                 "trust_boundary_status" => "declared"
               },
               "evidence" => %{
                 "resource_availability_reason_counts" => %{
                   "antenna_unavailable" => 1,
                   "ground_station_reserved" => 1,
                   "payload_unavailable" => 1
                 },
                 "station_availability_reason_ids" => ["ground_station_reserved"],
                 "unavailable_resource_reason_ids" => [
                   "antenna_unavailable",
                   "payload_unavailable"
                 ]
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["import_action"] == "review_operational_readiness")
             )

    assert %{
             "import_action" => "review_resource_suppression",
             "source_review_type" => "resource_suppression",
             "activity_id" => "refresh_observe_suppressed",
             "target_id" => "target_a",
             "payload_available" => false,
             "source_resource_suppression" => %{
               "suppressed_reason" => "payload_unavailable"
             },
             "source_review_row" => %{
               "source" => "candidate_refresh.resource_filter_report.suppressed_candidates"
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["import_action"] == "review_resource_suppression")
             )

    assert %{
             "import_action" => "review_warning",
             "source_review_type" => "warning",
             "source" => "candidate_refresh.warnings",
             "reason" => "candidate refresh produced reviewable contact changes",
             "operational_feedback_trust_boundary_status" => "missing",
             "operational_feedback_input_keys" => ["observation_success_rate"],
             "source_operational_feedback_provenance" => %{
               "trust_boundary_status" => "missing"
             },
             "source_review_row" => %{
               "source_operational_feedback_provenance" => %{
                 "trust_boundary_status" => "missing"
               }
             }
           } = Enum.find(manifest["rows"], &(&1["import_action"] == "review_warning"))

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    candidate_diff_index =
      Enum.find_index(manifest["rows"], &(&1["import_action"] == "review_candidate_diff"))

    invalid_replacement_lineage =
      put_in(
        manifest,
        [
          "rows",
          Access.at(candidate_diff_index),
          "replacement_source_window_lineage",
          "candidate_activity_id"
        ],
        "refresh_observe_mismatch"
      )

    assert {:error, invalid_replacement_lineage_report} =
             Schema.validate_artifact(invalid_replacement_lineage)

    assert Enum.any?(
             invalid_replacement_lineage_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{candidate_diff_index}].replacement_source_window_lineage.candidate_activity_id" and
                 &1["message"] == "must match replacement_candidate_id")
           )
  end

  test "candidate refresh contact intent summaries become direction-scoped import rows" do
    summary = %{
      "schema_contract" => "contact_intent_summary.v1",
      "model" => "artifact_only_contact_intent_summary",
      "source_artifact_type" => "contact_intent.v1",
      "source" => "cadence_import_test.compact_contact_intent_summary",
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
      "refresh_id" => "candidate_refresh:compact_contact_intent_summary_import",
      "source_contact_intent_summary" => summary
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:compact_contact_intent_summary_import",
             "row_count" => 3,
             "review_required_count" => 3,
             "import_action_counts" => %{"review_contact_intent" => 3},
             "source_review_type_counts" => %{"contact_intent_review" => 3}
           } = manifest

    assert Enum.map(manifest["rows"], & &1["direction"]) == ["command", "downlink", "tracking"]

    assert %{
             "import_action" => "review_contact_intent",
             "source_review_type" => "contact_intent_review",
             "source_review_action" => "review_contact_intent",
             "source_review_row_id" =>
               "contact_intent_review:contact_intent_summary:candidate_refresh.source_contact_intent_summary:downlink:2",
             "activity_id" =>
               "contact_intent_summary:candidate_refresh.source_contact_intent_summary:downlink",
             "contact_id" => "intent_direct_capacity",
             "contact_ids" => ["intent_direct_capacity"],
             "capacity_pack_contact_ids" => ["intent_direct_capacity"],
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "contact_intent_summary.direction_routing",
             "source_summary_model" => "artifact_only_contact_intent_summary",
             "source_summary_schema_contract" => "contact_intent_summary.v1",
             "source_summary_source" => "cadence_import_test.compact_contact_intent_summary",
             "source_contact_intent_summary" => %{
               "direction_routing" => %{
                 "downlink" => %{
                   "contact_ids" => ["intent_direct_capacity"],
                   "capacity_pack_contact_ids" => ["intent_direct_capacity"],
                   "capacity_pack_required_capacity_fraction" => 0.25
                 }
               }
             },
             "source_review_row" => %{
               "source" => "candidate_refresh.source_contact_intent_summary.summary_contacts",
               "direction" => "downlink",
               "source_contact_intent" => %{
                 "source_contact_intent_summary" => %{
                   "contact_ids_by_direction" => %{
                     "downlink" => ["intent_direct_capacity"]
                   }
                 }
               }
             }
           } = Enum.find(manifest["rows"], &(&1["direction"] == "downlink"))

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped operational readiness and quality gate summaries" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_readiness_quality_gate_import",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_operational_readiness_gate_summary" => operational_readiness_gate_summary(),
          "operational_execution_boundary_summary" => operational_execution_boundary_summary(),
          "operational_quality_gate_summary" => operational_quality_gate_summary()
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_readiness_quality_gate_import",
             "row_count" => 4,
             "review_required_count" => 4,
             "import_action_counts" => %{
               "review_operational_readiness" => 3,
               "review_quality_gate" => 1
             },
             "source_review_type_counts" => %{
               "operational_readiness_review" => 3,
               "quality_gate_review" => 1
             }
           } = manifest

    assert Enum.map(manifest["rows"], & &1["source"]) == [
             "candidate_refresh.source_result_artifact[0].operational_quality_gate_summary.rows",
             "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary",
             "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary.gates",
             "candidate_refresh.source_result_artifact[0].operational_execution_boundary_summary"
           ]

    assert Enum.all?(
             manifest["rows"],
             &match?(
               %{
                 "import_status" => "review_required_before_import",
                 "approval_status" => "operator_review_required",
                 "has_cadence_import" => false
               },
               &1
             )
           )

    assert %{
             "import_action" => "review_quality_gate",
             "source_review_type" => "quality_gate_review",
             "source_review_action" => "review_quality_gate",
             "quality_gate_id" => "resource_availability",
             "quality_gate_status" => "review_required",
             "quality_gate_classification" => "review_only",
             "readiness_gate_id" => "resource_availability",
             "resource_availability_pressure_count" => 3,
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "source_summary_schema_contract" => "operational_quality_gate_summary.v1",
               "source_summary_model" => "artifact_only_quality_gate_summary",
               "non_passed_gate_count" => 1,
               "assumptions" => %{
                 "operator_authority" => "not_granted_by_quality_gate_summary"
               }
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].operational_quality_gate_summary.rows",
               "source_quality_gate_report" => %{
                 "source_summary_schema_contract" => "operational_quality_gate_summary.v1"
               },
               "source_quality_gate_row" => %{
                 "source_summary_schema_contract" => "operational_quality_gate_summary.v1"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["source_review_type"] == "quality_gate_review")
             )

    assert %{
             "import_action" => "review_operational_readiness",
             "source_review_type" => "operational_readiness_review",
             "source_review_action" => "review_operational_readiness",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary",
             "subject_id" => "activity_resource_pressure",
             "operational_readiness_status" => "review_required",
             "gate_count" => 1,
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_gate_summary.v1",
               "source_summary_schema_contract" => "operational_readiness_gate_summary.v1",
               "gates" => [%{"id" => "resource_availability"}],
               "assumptions" => %{
                 "operator_authority" => "not_granted_by_summary"
               }
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary",
               "source_operational_readiness_report" => %{
                 "source_summary_schema_contract" => "operational_readiness_gate_summary.v1"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary")
             )

    assert %{
             "import_action" => "review_operational_readiness",
             "source_review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary.gates",
             "readiness_gate_id" => "resource_availability",
             "readiness_gate_status" => "review_required",
             "resource_availability_pressure_count" => 3,
             "source_operational_readiness_report" => %{
               "source_summary_schema_contract" => "operational_readiness_gate_summary.v1"
             },
             "source_operational_readiness_gate" => %{
               "id" => "resource_availability",
               "status" => "review_required"
             },
             "source_review_row" => %{
               "source_operational_readiness_gate" => %{
                 "id" => "resource_availability",
                 "status" => "review_required"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].source_operational_readiness_gate_summary.gates")
             )

    assert %{
             "import_action" => "review_operational_readiness",
             "source_review_type" => "operational_readiness_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].operational_execution_boundary_summary",
             "subject_id" => "activity_resource_pressure",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_execution_boundary_summary.v1",
               "source_summary_schema_contract" => "operational_execution_boundary_summary.v1",
               "assumptions" => %{
                 "command_execution" => "not_performed_by_summary",
                 "cadence_write" => "not_performed_by_summary",
                 "operator_authority" => "not_granted_by_execution_boundary_summary"
               }
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].operational_execution_boundary_summary",
               "source_operational_readiness_report" => %{
                 "source_summary_schema_contract" => "operational_execution_boundary_summary.v1"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].operational_execution_boundary_summary")
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped operational import eligibility summaries" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_import_eligibility_import",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "operational_import_eligibility_summary" => operational_import_eligibility_summary()
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_import_eligibility_import",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_operational_readiness" => 1},
             "source_review_type_counts" => %{"operational_readiness_review" => 1}
           } = manifest

    assert [
             %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].operational_import_eligibility_summary",
               "import_action" => "review_operational_readiness",
               "source_review_type" => "operational_readiness_review",
               "source_review_action" => "review_operational_readiness",
               "import_status" => "review_required_before_import",
               "approval_status" => "operator_review_required",
               "required_operator_action" => "review_operational_readiness",
               "subject_id" => "activity_1",
               "cadence_import_status" => "present",
               "has_cadence_import" => false,
               "readiness_level" => "operator_review",
               "import_classification" => "review_only",
               "operational_readiness_status" => "review_required",
               "gate_count" => 5,
               "passed_gate_count" => 2,
               "review_gate_count" => 1,
               "analysis_gate_count" => 1,
               "blocked_gate_count" => 1,
               "source_operational_readiness_report" => %{
                 "schema_contract" => "operational_import_eligibility_summary.v1",
                 "source_summary_schema_contract" => "operational_import_eligibility_summary.v1",
                 "source_summary_model" => "artifact_only_import_eligibility_summary",
                 "assumptions" => %{
                   "operator_authority" => "not_granted_by_summary",
                   "cadence_write" => "not_performed_by_summary",
                   "command_execution" => "not_performed_by_summary"
                 }
               },
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact[0].operational_import_eligibility_summary",
                 "source_operational_readiness_report" => %{
                   "source_summary_schema_contract" => "operational_import_eligibility_summary.v1"
                 }
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds import manifests from standalone freshness and refresh-budget reports" do
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

    freshness_manifest = CadenceImport.from_freshness_report(stale_freshness)
    assert OrbitalDynamics.cadence_import_manifest(stale_freshness) == freshness_manifest

    assert %{
             "source_artifact_type" => "freshness_report.v1",
             "row_count" => 1,
             "import_action_counts" => %{"review_refresh_freshness" => 1},
             "rows" => [
               %{
                 "import_action" => "review_refresh_freshness",
                 "source_review_type" => "freshness_review",
                 "refresh_gate" => "accepted_state_freshness",
                 "refresh_gate_status" => "stale",
                 "freshness_reason_count" => 1,
                 "freshness_status" => "stale",
                 "source_freshness_report" => %{"status" => "stale"}
               }
             ]
           } = freshness_manifest

    budget_manifest = CadenceImport.from_refresh_budget_report(budget)
    assert OrbitalDynamics.cadence_import_manifest(budget) == budget_manifest

    assert %{
             "source_artifact_type" => "refresh_budget_report.v1",
             "row_count" => 1,
             "import_action_counts" => %{"review_refresh_budget" => 1},
             "rows" => [
               %{
                 "import_action" => "review_refresh_budget",
                 "source_review_type" => "refresh_budget_review",
                 "refresh_gate" => "candidate_budget",
                 "refresh_gate_status" => "candidate_budget_exceeded",
                 "refresh_budget_overflow_count" => 1,
                 "dropped_candidate_ids" => ["old_refresh_downlink"],
                 "source_refresh_budget_report" => %{
                   "schema_contract" => "refresh_budget_report.v1"
                 }
               }
             ]
           } = budget_manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(freshness_manifest)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(budget_manifest)

    invalid_freshness_source_status_value =
      update_in(freshness_manifest, ["rows"], fn [row] ->
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
      update_in(freshness_manifest, ["rows"], fn [row] ->
        [Map.put(row, "freshness_status", "current")]
      end)

    assert {:error, invalid_freshness_source_status_report} =
             Schema.validate_artifact(invalid_freshness_source_status)

    assert Enum.any?(
             invalid_freshness_source_status_report["errors"],
             &(&1["path"] == "$.rows[0].source_freshness_report.status" and
                 &1["message"] == "must match freshness_status")
           )

    stale_source_review =
      update_in(freshness_manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        row
        |> Map.put("freshness_status", "current")
        |> Map.put("stale_reasons", ["stale review row"])
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.freshness_status" and
                 &1["message"] == "must match freshness_status on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.stale_reasons" and
                 &1["message"] == "must match stale_reasons on Cadence import row")
           )

    invalid_budget_source_evidence =
      update_in(budget_manifest, ["rows"], fn [row] ->
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
        budget_manifest,
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

    stale_budget_source_review =
      update_in(budget_manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        row
        |> Map.put("dropped_candidate_count", 2)
        |> Map.put("selection_order", "stale_selection")
      end)

    assert {:error, stale_budget_source_review_report} =
             Schema.validate_artifact(stale_budget_source_review)

    assert Enum.any?(
             stale_budget_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.dropped_candidate_count" and
                 &1["message"] == "must match dropped_candidate_count on Cadence import row")
           )

    assert Enum.any?(
             stale_budget_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.selection_order" and
                 &1["message"] == "must match selection_order on Cadence import row")
           )
  end

  test "builds import manifest from standalone contact intent" do
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

    manifest = CadenceImport.from_contact_intent(intent)
    assert OrbitalDynamics.cadence_import_manifest(intent) == manifest

    assert %{
             "source_artifact_type" => "contact_intent.v1",
             "source_artifact_id" => "refresh_downlink",
             "row_count" => 1,
             "import_action_counts" => %{"review_contact_intent" => 1},
             "rows" => [
               %{
                 "import_action" => "review_contact_intent",
                 "source_review_type" => "contact_intent_review",
                 "source_review_action" => "review_contact_intent",
                 "contact_intent_gate" => "contact_intent_policy",
                 "contact_intent_gate_status" => "operator_review_required",
                 "activity_id" => "refresh_downlink",
                 "cadence_import_status" => "present",
                 "cadence_import_type" => "contact",
                 "cadence_import_id" => "refresh_downlink",
                 "cadence_import_contract" => "proposed_contact.v1",
                 "requirement_type" => "contact_schedule_change",
                 "required_authority" => "contact_schedule_authority",
                 "policy_bundle_id" => "command_contact_authority_v1",
                 "rule_id" => "downlink_schedule_authority_review",
                 "source_contact_intent" => %{"schema_contract" => "contact_intent.v1"},
                 "source_review_row" => %{
                   "review_type" => "contact_intent_review",
                   "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
                   "starts_at_s" => 100.0,
                   "required_operator_action" => "review_contact_intent",
                   "requirement_type" => "contact_schedule_change",
                   "policy_bundle_id" => "command_contact_authority_v1"
                 }
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn [row] ->
        [
          put_in(row, ["source_contact_intent", "source_window_id"], "source window with spaces")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_contact_intent.source_window_id")
           )

    invalid_gate_status =
      put_in(
        manifest,
        ["rows", Access.at(0), "contact_intent_gate_status"],
        "ready_without_policy"
      )

    assert {:error, invalid_gate_status_report} = Schema.validate_artifact(invalid_gate_status)

    assert Enum.any?(
             invalid_gate_status_report["errors"],
             &(&1["path"] == "$.rows[0].contact_intent_gate_status")
           )

    invalid_handoff =
      update_in(manifest, ["rows"], fn [row] ->
        [
          row
          |> Map.put("source_window_id", "stale_source_window")
          |> Map.put("starts_at_s", 101.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_handoff)

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

    invalid_source_review_handoff =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("source_window_id", "stale_source_window")
          |> Map.put("requirement_type", "stale_requirement")
          |> Map.put("policy_bundle_id", "stale_policy_bundle")

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_handoff)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_window_id" and
                 &1["message"] == "must match source_window_id on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.requirement_type" and
                 &1["message"] == "must match requirement_type on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.policy_bundle_id" and
                 &1["message"] == "must match policy_bundle_id on Cadence import row")
           )
  end

  test "builds warning and risk import rows with typed review evidence" do
    package = %{
      "schema_contract" => "operator_review_package.v1",
      "model" => "artifact_only_operator_review_package",
      "source_artifact_type" => "campaign_strategy.v3",
      "source_artifact_id" => "strategy:warning_risk_manifest",
      "review_count" => 2,
      "warning_count" => 1,
      "risk_count" => 1,
      "rows" => [
        %{
          "id" => "warning:campaign_strategy.branch:baseline:1",
          "rank" => 1,
          "review_type" => "warning",
          "source" => "campaign_strategy.branches.warnings",
          "subject_id" => "baseline",
          "branch_id" => "baseline",
          "action" => "review_branch_warning",
          "required_operator_action" => "review_branch_warning",
          "approval_status" => "operator_review_required",
          "reason" => "branch still has reduced downlink capacity",
          "severity" => "warning"
        },
        %{
          "id" => "risk:campaign_strategy.recommendation.risks:late_downlink:1",
          "rank" => 2,
          "review_type" => "risk_explanation",
          "source" => "campaign_strategy.recommendation.risks_remaining",
          "subject_id" => "late_downlink",
          "branch_id" => "baseline",
          "action" => "review_risk",
          "required_operator_action" => "review_risk",
          "approval_status" => "operator_review_required",
          "risk_type" => "late_downlink",
          "severity" => "medium",
          "reason" => "selected branch keeps one late downlink risk",
          "value" => 1,
          "scenario_id" => "leo_1",
          "first_resource_pressure_activity_id" => "dl_pressure",
          "first_resource_pressure_activity_type" => "downlink",
          "first_resource_pressure_kind" => "downlink_shortfall",
          "first_resource_pressure_starts_at_s" => 120.0,
          "first_resource_pressure_direction" => "downlink",
          "first_resource_pressure_ground_station_id" => "equator_prime",
          "first_resource_pressure_station_calendar_entry_id" => "station_calendar_entry_1",
          "first_resource_pressure_station_calendar_directions" => ["command"],
          "first_resource_pressure_source_window_id" =>
            "window:leo_1:ground_station_access:equator_prime:late",
          "first_resource_pressure_source_window_type" => "ground_station_access",
          "first_resource_pressure_source_window" => %{
            "id" => "window:leo_1:ground_station_access:equator_prime:late",
            "type" => "ground_station_access",
            "ground_station_id" => "equator_prime"
          },
          "source_risk" => %{
            "type" => "late_downlink",
            "severity" => "medium",
            "reason" => "selected branch keeps one late downlink risk",
            "value" => 1,
            "branch_id" => "baseline",
            "scenario_id" => "leo_1",
            "first_resource_pressure_activity_id" => "dl_pressure",
            "first_resource_pressure_activity_type" => "downlink",
            "first_resource_pressure_kind" => "downlink_shortfall",
            "first_resource_pressure_starts_at_s" => 120.0,
            "first_resource_pressure_direction" => "downlink",
            "first_resource_pressure_ground_station_id" => "equator_prime",
            "first_resource_pressure_station_calendar_entry_id" => "station_calendar_entry_1",
            "first_resource_pressure_station_calendar_directions" => ["command"],
            "first_resource_pressure_source_window_id" =>
              "window:leo_1:ground_station_access:equator_prime:late"
          }
        }
      ],
      "provenance" => %{},
      "assumptions" => %{}
    }

    manifest = CadenceImport.from_operator_review_package(package)

    assert %{
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_risk" => 1, "review_warning" => 1},
             "rows" => rows
           } = manifest

    assert %{
             "import_action" => "review_warning",
             "source_review_type" => "warning",
             "source_review_action" => "review_branch_warning",
             "source" => "campaign_strategy.branches.warnings",
             "subject_id" => "baseline",
             "branch_id" => "baseline",
             "reason" => "branch still has reduced downlink capacity",
             "severity" => "warning",
             "source_review_row" => %{"reason" => "branch still has reduced downlink capacity"}
           } = Enum.find(rows, &(&1["source_review_type"] == "warning"))

    assert %{
             "import_action" => "review_risk",
             "source_review_type" => "risk_explanation",
             "source" => "campaign_strategy.recommendation.risks_remaining",
             "subject_id" => "late_downlink",
             "branch_id" => "baseline",
             "scenario_id" => "leo_1",
             "activity_id" => "dl_pressure",
             "activity_type" => "downlink",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "station_calendar_entry_id" => "station_calendar_entry_1",
             "station_calendar_directions" => ["command"],
             "first_resource_pressure_activity_id" => "dl_pressure",
             "first_resource_pressure_activity_type" => "downlink",
             "first_resource_pressure_kind" => "downlink_shortfall",
             "first_resource_pressure_starts_at_s" => 120.0,
             "first_resource_pressure_direction" => "downlink",
             "first_resource_pressure_ground_station_id" => "equator_prime",
             "first_resource_pressure_station_calendar_entry_id" => "station_calendar_entry_1",
             "first_resource_pressure_station_calendar_directions" => ["command"],
             "first_resource_pressure_source_window_id" =>
               "window:leo_1:ground_station_access:equator_prime:late",
             "first_resource_pressure_source_window_type" => "ground_station_access",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:late",
             "source_window" => %{
               "id" => "window:leo_1:ground_station_access:equator_prime:late",
               "type" => "ground_station_access",
               "ground_station_id" => "equator_prime"
             },
             "reason" => "selected branch keeps one late downlink risk",
             "risk_type" => "late_downlink",
             "severity" => "medium",
             "value" => 1,
             "source_risk" => %{
               "type" => "late_downlink",
               "reason" => "selected branch keeps one late downlink risk"
             }
           } = Enum.find(rows, &(&1["source_review_type"] == "risk_explanation"))

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_review_warning =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "warning", "source_review_row" => %{}} = row ->
            source_review_row =
              row["source_review_row"]
              |> Map.put("reason", "stale warning reason")
              |> Map.put("severity", "critical")

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_review_warning_report} =
             Schema.validate_artifact(stale_source_review_warning)

    assert Enum.any?(
             stale_source_review_warning_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.reason$/ and
                 &1["message"] == "must match reason on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_warning_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.severity$/ and
                 &1["message"] == "must match severity on Cadence import row")
           )

    stale_source_risk =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "risk_explanation", "source_risk" => %{}} = row ->
            row
            |> put_in(["source_risk", "severity"], "critical")
            |> put_in(["source_risk", "first_resource_pressure_kind"], "stale_pressure")

          row ->
            row
        end)
      end)

    assert {:error, stale_source_risk_report} = Schema.validate_artifact(stale_source_risk)

    assert Enum.any?(
             stale_source_risk_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.severity$/ and
                 &1["message"] == "must match source_risk.severity")
           )

    assert Enum.any?(
             stale_source_risk_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.first_resource_pressure_kind$/ and
                 &1["message"] == "must match source_risk.first_resource_pressure_kind")
           )

    stale_source_review_risk =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "risk_explanation", "source_review_row" => %{}} = row ->
            source_review_row =
              row["source_review_row"]
              |> Map.put("reason", "stale risk reason")
              |> Map.put("first_resource_pressure_kind", "stale_pressure")

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_review_risk_report} =
             Schema.validate_artifact(stale_source_review_risk)

    assert Enum.any?(
             stale_source_review_risk_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.reason$/ and
                 &1["message"] == "must match reason on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_risk_report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_review_row\.first_resource_pressure_kind$/ and
                 &1["message"] == "must match first_resource_pressure_kind on Cadence import row")
           )
  end

  test "builds import manifest from standalone approval requirement with routing fields" do
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
      "policy_classification" => "operator_review_required"
    }

    manifest = CadenceImport.from_approval_requirement(requirement)
    assert OrbitalDynamics.cadence_import_manifest(requirement) == manifest

    assert %{
             "source_artifact_type" => "approval_requirement.v1",
             "source_artifact_id" => "dl_2",
             "row_count" => 1,
             "rows" => [
               %{
                 "import_action" => "review_approval_requirement",
                 "source_review_type" => "approval_requirement",
                 "source_review_action" => "approve_moved_contact",
                 "activity_id" => "dl_2",
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
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_review =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("requirement_type", "stale_requirement")
          |> Map.put("reason", "stale_reason")

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.requirement_type" and
                 &1["message"] == "must match requirement_type on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.reason" and
                 &1["message"] == "must match reason on Cadence import row")
           )
  end

  test "derives approval requirement semantic reasons from change details" do
    requirement = %{
      "schema_contract" => "approval_requirement.v1",
      "activity_id" => "obs_diff_replacement",
      "activity_type" => "observe",
      "action" => "approve_strategic_addition",
      "reason" => "candidate diff replacement requires approval",
      "candidate_diff" => %{
        "invalidated_candidate_id" => "obs_old",
        "replacement_candidate_id" => "obs_diff_replacement",
        "semantic_change_reasons" => [],
        "semantic_change_details" => [
          %{
            "field" => "target_priority",
            "reason" => "target_priority_changed",
            "prior_value" => 2.0,
            "refreshed_value" => 6.5
          }
        ]
      }
    }

    manifest = CadenceImport.from_approval_requirement(requirement)

    assert [%{"semantic_change_reasons" => ["target_priority_changed"]}] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "normalizes unsupported source cadence import statuses to invalid review rows" do
    package = %{
      "schema_contract" => "operator_review_package.v1",
      "model" => "artifact_only_operator_review_package",
      "source_artifact_type" => "operational_timeline_report.v1",
      "source_artifact_id" => "timeline:custom_import_status",
      "review_count" => 1,
      "rows" => [
        %{
          "id" => "operational_timeline:cmd_1",
          "rank" => 1,
          "review_type" => "operational_timeline_review",
          "source" => "operational_timeline_report.rows",
          "subject_id" => "cmd_1",
          "activity_id" => "cmd_1",
          "timeline_id" => "timeline:cmd_1",
          "activity_type" => "command",
          "action" => "review_command_contact",
          "required_operator_action" => "review_command_contact",
          "approval_status" => "not_required",
          "cadence_import_status" => "provider_custom",
          "reason" => "provider supplied an unsupported import status"
        }
      ],
      "provenance" => %{},
      "assumptions" => %{}
    }

    manifest = CadenceImport.from_operator_review_package(package)

    assert %{
             "review_required_count" => 1,
             "ready_count" => 0,
             "cadence_import_status_counts" => %{"invalid" => 1},
             "rows" => [
               %{
                 "import_action" => "review_operational_timeline",
                 "import_status" => "review_required_before_import",
                 "cadence_import_status" => "invalid",
                 "has_cadence_import" => false,
                 "invalid_cadence_import" => true,
                 "invalid_cadence_import_reason" => "unsupported_cadence_import_status",
                 "unsupported_cadence_import_status" => "provider_custom"
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "preserves source review row action when required operator action differs" do
    package = %{
      "schema_contract" => "operator_review_package.v1",
      "model" => "artifact_only_operator_review_package",
      "source_artifact_type" => "contact_intent.v1",
      "source_artifact_id" => "contact_intent:source_action",
      "review_count" => 1,
      "rows" => [
        %{
          "id" => "contact_intent:intent_1:policy_exception",
          "rank" => 1,
          "review_type" => "contact_intent_review",
          "source" => "contact_intent.rows",
          "subject_id" => "intent_1",
          "contact_id" => "intent_1",
          "action" => "review_contact_intent_policy_exception",
          "required_operator_action" => "review_contact_intent",
          "approval_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "requirement_type" => "contact_schedule_change",
              "reason" => "contact intent requires policy exception review"
            }
          ],
          "approval_rule_matches" => [
            %{"rule_id" => "downlink_schedule_authority_review"}
          ],
          "source_policy_decision" => %{
            "policy_bundle_id" => "command_contact_authority_v1",
            "escalations" => [
              %{"rule_id" => "unmatched_contact_rule", "escalation_queue" => "ignore_queue"},
              %{
                "rule_id" => "downlink_schedule_authority_review",
                "required_authority" => "contact_schedule_authority",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "contact_intent_review",
                "escalation_role" => "contact_scheduler",
                "sla_s" => 600
              }
            ]
          },
          "reason" => "contact intent requires policy exception review"
        }
      ],
      "provenance" => %{},
      "assumptions" => %{}
    }

    manifest = CadenceImport.from_operator_review_package(package)

    assert [
             %{
               "import_action" => "review_contact_intent",
               "source_review_action" => "review_contact_intent_policy_exception",
               "required_operator_action" => "review_contact_intent",
               "requirement_type" => "contact_schedule_change",
               "required_authority" => "contact_schedule_authority",
               "policy_bundle_id" => "command_contact_authority_v1",
               "rule_id" => "downlink_schedule_authority_review",
               "escalation_level" => "ops_lead",
               "escalation_queue" => "contact_intent_review",
               "escalation_role" => "contact_scheduler",
               "sla_s" => 600,
               "source_policy_escalation" => %{
                 "rule_id" => "downlink_schedule_authority_review",
                 "escalation_queue" => "contact_intent_review"
               },
               "source_review_row" => %{
                 "action" => "review_contact_intent_policy_exception",
                 "required_operator_action" => "review_contact_intent"
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "derives generic review import presence from Cadence import identity" do
    package = %{
      "schema_contract" => "operator_review_package.v1",
      "model" => "artifact_only_operator_review_package",
      "source_artifact_type" => "operator_review_package.v1",
      "source_artifact_id" => "operator_review:generic_import_identity",
      "review_count" => 1,
      "rows" => [
        %{
          "id" => "operator_review:contact_intent_1",
          "rank" => 1,
          "review_type" => "contact_intent_review",
          "source" => "operator_review.rows",
          "subject_id" => "contact_intent_1",
          "action" => "review_contact_intent",
          "required_operator_action" => "review_contact_intent",
          "approval_status" => "operator_review_required",
          "cadence_import_status" => "present",
          "cadence_import_type" => "contact_intent",
          "cadence_import_id" => "cadence_contact_intent_1",
          "cadence_import_contract" => "contact_intent.v1"
        }
      ],
      "provenance" => %{},
      "assumptions" => %{}
    }

    manifest = CadenceImport.from_operator_review_package(package)

    assert [
             %{
               "import_action" => "review_contact_intent",
               "cadence_import_status" => "present",
               "cadence_import_type" => "contact_intent",
               "cadence_import_id" => "cadence_contact_intent_1",
               "cadence_import_contract" => "contact_intent.v1",
               "has_cadence_import" => true,
               "source_review_row" => %{
                 "cadence_import_id" => "cadence_contact_intent_1"
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds strategy recommendation import rows with typed review evidence" do
    package = %{
      "schema_contract" => "operator_review_package.v1",
      "model" => "artifact_only_operator_review_package",
      "source_artifact_type" => "campaign_strategy.v3",
      "source_artifact_id" => "strategy:recommendation_manifest",
      "review_count" => 1,
      "recommendation_count" => 1,
      "rows" => [
        %{
          "id" => "strategy:recommendation:baseline",
          "rank" => 1,
          "review_type" => "strategy_recommendation",
          "source" => "campaign_strategy.recommendation",
          "subject_id" => "baseline",
          "branch_id" => "baseline",
          "recommended_branch_id" => "baseline",
          "ranked_branch_ids" => ["baseline", "urgent"],
          "action" => "review_strategy_recommendation",
          "required_operator_action" => "review_strategy_recommendation",
          "approval_status" => "operator_review_required",
          "reason" => "best expected score requiring operator review",
          "tradeoff_count" => 2,
          "risk_count" => 1,
          "risk_types" => ["command_success_rate_low"],
          "activity_ids" => ["cmd_health_1"],
          "scenario_ids" => ["leo_1"],
          "spacecraft_ids" => ["sat_1"],
          "source_window_ids" => ["window:leo_1:command:equator_prime:1"],
          "source_window_types" => ["ground_station_access"],
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
          ],
          "approval_requirement_count" => 1,
          "operational_feedback_trust_boundary_status" => "missing",
          "operational_feedback_input_keys" => ["contact_success_rate"],
          "source_operational_feedback_provenance" => %{
            "input_keys" => ["contact_success_rate"],
            "source_count" => 1,
            "sources" => [
              %{
                "source" => "request.operational_feedback",
                "trust_boundary_status" => "missing"
              }
            ]
          },
          "source_recommendation" => %{
            "recommended_branch_id" => "baseline",
            "approval_status" => "operator_review_required",
            "reason" => "best expected score requiring operator review"
          }
        }
      ],
      "provenance" => %{},
      "assumptions" => %{}
    }

    manifest = CadenceImport.from_operator_review_package(package)

    assert %{
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_strategy_recommendation" => 1},
             "rows" => [
               %{
                 "import_action" => "review_strategy_recommendation",
                 "source_review_type" => "strategy_recommendation",
                 "source_review_action" => "review_strategy_recommendation",
                 "source" => "campaign_strategy.recommendation",
                 "subject_id" => "baseline",
                 "branch_id" => "baseline",
                 "recommended_branch_id" => "baseline",
                 "ranked_branch_ids" => ["baseline", "urgent"],
                 "tradeoff_count" => 2,
                 "risk_count" => 1,
                 "risk_types" => ["command_success_rate_low"],
                 "activity_ids" => ["cmd_health_1"],
                 "scenario_ids" => ["leo_1"],
                 "spacecraft_ids" => ["sat_1"],
                 "source_window_ids" => ["window:leo_1:command:equator_prime:1"],
                 "source_window_types" => ["ground_station_access"],
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
                 "operational_feedback_trust_boundary_status" => "missing",
                 "operational_feedback_input_keys" => ["contact_success_rate"],
                 "reason" => "best expected score requiring operator review",
                 "source_operational_feedback_provenance" => %{
                   "source_count" => 1
                 },
                 "source_recommendation" => %{
                   "recommended_branch_id" => "baseline",
                   "reason" => "best expected score requiring operator review"
                 },
                 "source_review_row" => %{
                   "review_type" => "strategy_recommendation",
                   "branch_event_trust_boundary_status_counts" => %{
                     "declared" => 1,
                     "missing" => 1
                   }
                 }
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_review =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("reason", "stale recommendation reason")
          |> Map.put("risk_count", 2)

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.reason" and
                 &1["message"] == "must match reason on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.risk_count" and
                 &1["message"] == "must match risk_count on Cadence import row")
           )
  end

  test "builds timeline-protection import rows with protection context" do
    package = %{
      "schema_contract" => "operator_review_package.v1",
      "review_id" => "review:timeline_protection_manifest",
      "source_artifact_type" => "campaign_repair.v2",
      "source_artifact_id" => "repair:timeline_protection_manifest",
      "row_count" => 2,
      "rows" => [
        %{
          "id" => "timeline_protection:preserved_locked_or_approved:dl_1:1",
          "rank" => 1,
          "review_type" => "timeline_protection",
          "source" => "campaign_repair.repair_metadata.timeline_protection",
          "subject_id" => "dl_1",
          "activity_id" => "dl_1",
          "action" => "record_protected_timeline_preservation",
          "required_operator_action" => "record_protected_timeline_preservation",
          "approval_status" => "not_required",
          "reason" => "locked or approved activity preserved by repair policy",
          "protection_category" => "preserved_locked_or_approved",
          "protection_decision" => "preserved",
          "source_timeline_protection" => %{
            "preserved_locked_or_approved_activity_ids" => ["dl_1"],
            "changed_locked_or_approved_activity_ids" => ["cmd_1"]
          }
        },
        %{
          "id" => "timeline_protection:changed_locked_or_approved:cmd_1:1",
          "rank" => 2,
          "review_type" => "timeline_protection",
          "source" => "campaign_repair.repair_metadata.timeline_protection",
          "subject_id" => "cmd_1",
          "activity_id" => "cmd_1",
          "action" => "review_changed_protected_timeline_item",
          "required_operator_action" => "review_changed_protected_timeline_item",
          "approval_status" => "operator_review_required",
          "reason" => "locked or approved activity changed by repair",
          "protection_category" => "changed_locked_or_approved",
          "protection_decision" => "changed",
          "source_timeline_protection" => %{
            "preserved_locked_or_approved_activity_ids" => ["dl_1"],
            "changed_locked_or_approved_activity_ids" => ["cmd_1"]
          }
        }
      ],
      "provenance" => %{},
      "assumptions" => %{}
    }

    manifest = CadenceImport.from_operator_review_package(package)

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "row_count" => 2,
             "ready_count" => 1,
             "review_required_count" => 1,
             "rows" => rows
           } = manifest

    assert %{
             "import_action" => "review_timeline_protection",
             "import_status" => "ready_for_import",
             "activity_id" => "dl_1",
             "protection_category" => "preserved_locked_or_approved",
             "protection_decision" => "preserved",
             "source_timeline_protection" => %{
               "preserved_locked_or_approved_activity_ids" => ["dl_1"]
             },
             "source_review_row" => %{
               "review_type" => "timeline_protection",
               "source_timeline_protection" => %{
                 "preserved_locked_or_approved_activity_ids" => ["dl_1"],
                 "changed_locked_or_approved_activity_ids" => ["cmd_1"]
               }
             }
           } = Enum.find(rows, &(&1["activity_id"] == "dl_1"))

    assert %{
             "import_action" => "review_timeline_protection",
             "import_status" => "review_required_before_import",
             "activity_id" => "cmd_1",
             "protection_category" => "changed_locked_or_approved",
             "protection_decision" => "changed"
           } = Enum.find(rows, &(&1["activity_id"] == "cmd_1"))

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_review =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"activity_id" => "dl_1", "source_review_row" => %{}} = row ->
            source_review_row =
              row["source_review_row"]
              |> Map.put("reason", "stale protection reason")
              |> Map.put("protection_decision", "changed")

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.reason" and
                 &1["message"] == "must match reason on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.protection_decision" and
                 &1["message"] == "must match protection_decision on Cadence import row")
           )

    stale_source_protection =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"activity_id" => "dl_1", "source_review_row" => %{}} = row ->
            source_review_row =
              put_in(
                row["source_review_row"],
                ["source_timeline_protection", "preserved_locked_or_approved_activity_ids"],
                ["dl_other"]
              )

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_protection_report} =
             Schema.validate_artifact(stale_source_protection)

    assert Enum.any?(
             stale_source_protection_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_timeline_protection" and
                 &1["message"] == "must match source_timeline_protection on Cadence import row")
           )

    invalid_source_protection =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"activity_id" => "dl_1", "source_review_row" => %{}} = row ->
            source_timeline_protection =
              Map.put(
                row["source_timeline_protection"],
                "preserved_locked_or_approved_activity_ids",
                ["invalid id"]
              )

            source_review_row =
              Map.put(
                row["source_review_row"],
                "source_timeline_protection",
                source_timeline_protection
              )

            row
            |> Map.put("source_timeline_protection", source_timeline_protection)
            |> Map.put("source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, invalid_source_protection_report} =
             Schema.validate_artifact(invalid_source_protection)

    assert Enum.any?(
             invalid_source_protection_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_protection.preserved_locked_or_approved_activity_ids[0]")
           )

    assert Enum.any?(
             invalid_source_protection_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_protection.preserved_locked_or_approved_activity_ids[0]")
           )
  end

  test "builds proposed-contact import rows from campaign artifacts" do
    campaign = %{
      "schema_version" => 1,
      "planner" => "OrbitalDynamics.CampaignPlanner.V1",
      "plan_id" => "campaign_plan:manifest_test",
      "proposed_contacts" => [
        %{
          "id" => "dl_1",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "direction" => "downlink",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 120.0,
          "ends_at_s" => 180.0,
          "estimated_throughput_mb" => 60.0,
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
          "cadence_import" => %{
            "activity_type" => "contact",
            "external_id" => "dl_1",
            "schema_contract" => "proposed_contact.v1",
            "adapter" => "cadence_contact_adapter",
            "adapter_version" => "2026-05",
            "provider" => "cadence",
            "provenance" => %{"trust_boundary" => "orbital_dynamics_to_cadence_adapter"}
          }
        },
        %{
          "id" => "dl_2",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "direction" => "downlink",
          "ground_station_id" => "polar_prime",
          "starts_at_s" => 90.0,
          "ends_at_s" => 130.0,
          "estimated_throughput_mb" => 40.0,
          "source_window_id" => "window:leo_1:ground_station_access:polar_prime:1"
        }
      ],
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
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 200.0,
            "ends_at_s" => 220.0,
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
            "cadence_import_type" => "command_window",
            "cadence_import_id" => "cadence_cmd_1",
            "cadence_import_contract" => "command_window.v1",
            "has_source_window" => false,
            "timeline_identity" => %{
              "timeline_id" => "timeline:cmd_1",
              "activity_id" => "cmd_1",
              "activity_type" => "command",
              "scenario_id" => "leo_1"
            }
          }
        ]
      }
    }

    manifest = CadenceImport.from_campaign_artifact(campaign)

    assert OrbitalDynamics.cadence_import_manifest(campaign) == manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => "campaign_plan:manifest_test",
             "row_count" => 3,
             "ready_count" => 1,
             "review_required_count" => 1,
             "blocked_count" => 1,
             "missing_import_count" => 1,
             "model_limits" => model_limits,
             "rows" => [blocked, ready, timeline_review]
           } = manifest

    expected_model_limits =
      CadenceImport.capability()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert model_limits == expected_model_limits

    assert "does_not_write_cadence" in model_limits
    assert "does_not_approve_operator_actions" in model_limits

    assert %{
             "id" => "cadence_import:proposed_contact:dl_2",
             "import_action" => "import_proposed_contact",
             "import_status" => "blocked_missing_cadence_import",
             "source_review_row_id" => "proposed_contact:dl_2",
             "source_review_type" => "proposed_contact",
             "subject_id" => "dl_2",
             "starts_at_s" => 90.0,
             "cadence_import_status" => "missing"
           } = blocked

    assert %{
             "id" => "cadence_import:proposed_contact:dl_1",
             "import_status" => "ready_for_import",
             "cadence_import_id" => "dl_1",
             "cadence_import_contract" => "proposed_contact.v1",
             "cadence_import_provider" => "cadence",
             "cadence_import_adapter" => "cadence_contact_adapter",
             "cadence_import_adapter_version" => "2026-05",
             "cadence_import_trust_boundary" => "orbital_dynamics_to_cadence_adapter",
             "cadence_import_provenance" => %{
               "trust_boundary" => "orbital_dynamics_to_cadence_adapter"
             },
             "has_cadence_import" => true
           } = ready

    assert %{
             "import_action" => "review_operational_timeline",
             "import_status" => "review_required_before_import",
             "source_review_type" => "operational_timeline_review",
             "source_review_action" => "review_command_contact",
             "activity_id" => "cmd_1",
             "timeline_id" => "timeline:cmd_1",
             "operational_kind" => "command",
             "cadence_import_status" => "present",
             "cadence_import_type" => "command_window",
             "cadence_import_id" => "cadence_cmd_1",
             "cadence_import_contract" => "command_window.v1",
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
             },
             "source_operational_timeline" => %{
               "activity_id" => "cmd_1",
               "timeline_id" => "timeline:cmd_1",
               "operational_kind" => "command"
             }
           } = timeline_review

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds strategy recommendation import rows from branch comparisons" do
    strategy = %{
      "schema_version" => 3,
      "planner" => "OrbitalDynamics.CampaignPlanner.V3",
      "source_plan_id" => "campaign_plan:manifest_test",
      "source_repair_id" => "repair:manifest_test",
      "recommendation" => %{
        "schema_contract" => "strategy_recommendation.v1",
        "recommended_branch_id" => "baseline",
        "approval_status" => "operator_review_required",
        "reason" => "best_expected_score_requiring_operator_review",
        "ranked_branch_ids" => ["baseline", "urgent"],
        "tradeoffs" => [],
        "explanation" => [
          %{
            "type" => "resource_pressure",
            "activity_id" => "cmd_health_1",
            "first_resource_pressure_source_window_id" =>
              "window:leo_1:command:equator_prime:explanation",
            "first_resource_pressure_source_window_type" => "ground_station_access"
          }
        ],
        "risks_remaining" => [
          %{
            "type" => "command_success_rate_low",
            "severity" => "medium",
            "reason" => "command feedback low",
            "activity_id" => "cmd_health_1",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "sat_1",
            "target_id" => "target_downlink",
            "collection_id" => "collection_downlink",
            "product_id" => "product_downlink",
            "payload_id" => "payload_downlink",
            "instrument_id" => "instrument_downlink",
            "objective_id" => "objective:downlink_latency",
            "objective_type" => "collection_latency",
            "source_activity_ids" => ["obs_downlink"],
            "maneuver_id" => "burn_uncertain",
            "execution_uncertainty_status" => "declared",
            "execution_uncertainty_source" => "provider_execution_covariance",
            "timing_3sigma_s" => 75.0,
            "delta_v_3sigma_magnitude_km_s" => 0.002,
            "feedback_source" => "prior_plan.source_objective_satisfaction_report",
            "feedback_scope" => "objective_satisfaction",
            "first_resource_pressure_activity_id" => "cmd_health_1",
            "first_resource_pressure_direction" => "command",
            "first_resource_pressure_ground_station_id" => "equator_prime",
            "first_resource_pressure_station_calendar_entry_id" => "station_calendar_entry_1",
            "first_resource_pressure_station_calendar_directions" => ["command"],
            "first_resource_pressure_source_window_id" =>
              "window:leo_1:command:equator_prime:risk",
            "first_resource_pressure_source_window_type" => "ground_station_access"
          }
        ],
        "requires_approval" => []
      },
      "branch_comparison_report" => %{
        "schema_contract" => "branch_comparison_report.v1",
        "rows" => [
          %{
            "id" => "branch_comparison:baseline",
            "rank" => 1,
            "branch_id" => "baseline",
            "selected" => true,
            "approval_status" => "operator_review_required",
            "score" => 42.0,
            "score_delta_from_recommended" => 0.0,
            "raw_score" => 42.0,
            "branch_probability" => 1.0,
            "expected_score" => 42.0,
            "risk_count" => 0,
            "risk_types" => ["command_success_rate_low"],
            "high_risk_types" => [],
            "approval_requirement_count" => 1,
            "repair_delta_count" => 0,
            "branch_target_ids" => ["target_downlink"],
            "branch_collection_ids" => ["collection_downlink"],
            "branch_product_ids" => ["product_downlink"],
            "branch_payload_ids" => ["payload_downlink"],
            "branch_instrument_ids" => ["instrument_downlink"],
            "branch_objective_ids" => ["objective:downlink_latency"],
            "branch_objective_types" => ["collection_latency"],
            "branch_feedback_sources" => ["prior_plan.source_objective_satisfaction_report"],
            "branch_feedback_scopes" => ["objective_satisfaction"],
            "branch_source_activity_ids" => ["obs_downlink"],
            "branch_max_latency_s" => 180.0,
            "branch_planned_latency_s" => 420.0,
            "branch_required_downlink_mb" => 30.0,
            "branch_planned_downlink_mb" => 0.0,
            "branch_actual_downlink_completion_ratio" => 0.25,
            "downlink_completion_ratio" => 1.0,
            "coverage_observed_target_count" => 2,
            "feedback_score_adjustment" => -5.0,
            "command_success_factor" => 0.9,
            "resource_risk_types" => ["power_margin_low"],
            "repair_score" => 39.0,
            "repair_score_term_keys" => ["activity_score"],
            "repair_link_required_downlink_mb" => 120.0,
            "repair_link_selected_downlink_shortfall_mb" => 30.0,
            "repair_link_downlink_requirement_status" => "shortfall",
            "repair_link_actual_throughput_mb" => 30.0,
            "repair_link_actual_downlink_completion_ratio" => 0.25,
            "repair_link_actual_downlink_shortfall_mb" => 90.0,
            "repair_link_actual_downlink_requirement_status" => "shortfall"
          },
          %{
            "id" => "branch_comparison:urgent",
            "rank" => 2,
            "branch_id" => "urgent",
            "selected" => false,
            "approval_status" => "operator_review_required",
            "score" => 40.0,
            "score_delta_from_recommended" => -2.0,
            "raw_score" => 40.0,
            "branch_probability" => 1.0,
            "expected_score" => 40.0,
            "risk_count" => 1,
            "risk_types" => ["activity_type_suppressed_by_resource_summary"],
            "high_risk_types" => ["activity_type_suppressed_by_resource_summary"],
            "approval_requirement_count" => 1,
            "repair_delta_count" => 1
          }
        ]
      },
      "strategy_metadata" => %{"strategy_id" => "strategy:manifest_test"},
      "operator_review_package" => %{
        "schema_contract" => "operator_review_package.v1",
        "source_artifact_type" => "campaign_strategy.v3",
        "source_artifact_id" => "strategy:manifest_test",
        "review_count" => 2,
        "rows" => [
          %{
            "id" => "strategy_recommendation:baseline",
            "review_type" => "strategy_recommendation",
            "action" => "review_strategy_recommendation",
            "required_operator_action" => "review_strategy_recommendation",
            "approval_status" => "operator_review_required",
            "branch_id" => "baseline",
            "subject_id" => "baseline"
          },
          %{
            "id" => "contact_allocation:urgent_downlink",
            "review_type" => "contact_allocation_review",
            "action" => "review_contact_allocation",
            "required_operator_action" => "review_contact_allocation",
            "approval_status" => "operator_review_required",
            "branch_id" => "urgent",
            "contact_id" => "urgent_downlink",
            "subject_id" => "urgent_downlink",
            "allocation_status" => "deferred",
            "allocation_reason" => "same_station_contention",
            "requirement_type" => "contact_schedule_change",
            "required_authority" => "contact_schedule_authority",
            "policy_bundle_id" => "ground_network_allocation_v1",
            "rule_id" => "contact_allocation_review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "network_scheduler",
            "sla_s" => 600,
            "source_policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "ground_network_allocation_v1"
            },
            "source_policy_escalation" => %{
              "rule_id" => "contact_allocation_review",
              "required_authority" => "contact_schedule_authority",
              "escalation_level" => "ops_lead",
              "escalation_queue" => "ground_network",
              "escalation_role" => "network_scheduler",
              "sla_s" => 600
            },
            "source_contact_allocation" => %{
              "contact_id" => "urgent_downlink",
              "allocation_status" => "deferred"
            }
          }
        ]
      }
    }

    manifest = CadenceImport.from_strategy_artifact(strategy)

    assert OrbitalDynamics.cadence_import_manifest(strategy) == manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "campaign_strategy.v3",
             "source_artifact_id" => "strategy:manifest_test",
             "row_count" => 3,
             "ready_count" => 0,
             "review_required_count" => 2,
             "blocked_count" => 0,
             "missing_import_count" => 0,
             "provenance" => %{
               "source_review_count" => 2,
               "operator_review_package_source" => "embedded"
             },
             "rows" => [selected, alternative, allocation_review]
           } = manifest

    assert %{
             "id" => "cadence_import:strategy_branch:baseline",
             "import_action" => "import_strategy_recommendation",
             "import_status" => "review_required_before_import",
             "source_review_row_id" => "branch_comparison:baseline",
             "source_review_type" => "strategy_branch_comparison",
             "subject_id" => "baseline",
             "branch_id" => "baseline",
             "recommended_branch_id" => "baseline",
             "selected" => true,
             "approval_status" => "operator_review_required",
             "cadence_import_status" => "not_applicable",
             "downlink_completion_ratio" => 1.0,
             "coverage_observed_target_count" => 2,
             "feedback_score_adjustment" => -5.0,
             "command_success_factor" => 0.9,
             "risk_count" => 0,
             "risk_types" => ["command_success_rate_low"],
             "high_risk_types" => [],
             "activity_ids" => ["cmd_health_1"],
             "scenario_ids" => ["leo_1"],
             "ground_station_ids" => ["equator_prime"],
             "spacecraft_ids" => ["sat_1"],
             "target_ids" => ["target_downlink"],
             "collection_ids" => ["collection_downlink"],
             "product_ids" => ["product_downlink"],
             "payload_ids" => ["payload_downlink"],
             "instrument_ids" => ["instrument_downlink"],
             "objective_ids" => ["objective:downlink_latency"],
             "objective_types" => ["collection_latency"],
             "feedback_sources" => ["prior_plan.source_objective_satisfaction_report"],
             "feedback_scopes" => ["objective_satisfaction"],
             "source_activity_ids" => ["obs_downlink"],
             "maneuver_ids" => ["burn_uncertain"],
             "maneuver_execution_uncertainty_statuses" => ["declared"],
             "maneuver_execution_uncertainty_sources" => ["provider_execution_covariance"],
             "maneuver_execution_uncertainty_timing_3sigma_s" => [75.0],
             "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_km_s" => [0.002],
             "directions" => ["command"],
             "station_calendar_entry_ids" => ["station_calendar_entry_1"],
             "station_calendar_directions" => ["command"],
             "source_window_ids" => [
               "window:leo_1:command:equator_prime:risk",
               "window:leo_1:command:equator_prime:explanation"
             ],
             "source_window_types" => ["ground_station_access"],
             "branch_target_ids" => ["target_downlink"],
             "branch_collection_ids" => ["collection_downlink"],
             "branch_product_ids" => ["product_downlink"],
             "branch_payload_ids" => ["payload_downlink"],
             "branch_instrument_ids" => ["instrument_downlink"],
             "branch_objective_ids" => ["objective:downlink_latency"],
             "branch_objective_types" => ["collection_latency"],
             "branch_feedback_sources" => ["prior_plan.source_objective_satisfaction_report"],
             "branch_feedback_scopes" => ["objective_satisfaction"],
             "branch_source_activity_ids" => ["obs_downlink"],
             "branch_max_latency_s" => 180.0,
             "branch_planned_latency_s" => 420.0,
             "branch_required_downlink_mb" => 30.0,
             "branch_actual_downlink_completion_ratio" => 0.25,
             "resource_risk_types" => ["power_margin_low"],
             "repair_score" => 39.0,
             "repair_score_term_keys" => ["activity_score"],
             "repair_link_required_downlink_mb" => 120.0,
             "repair_link_selected_downlink_shortfall_mb" => 30.0,
             "repair_link_downlink_requirement_status" => "shortfall",
             "repair_link_actual_throughput_mb" => 30.0,
             "repair_link_actual_downlink_completion_ratio" => 0.25,
             "repair_link_actual_downlink_shortfall_mb" => 90.0,
             "repair_link_actual_downlink_requirement_status" => "shortfall"
           } = selected

    assert selected["branch_planned_downlink_mb"] == 0.0

    assert %{
             "id" => "cadence_import:strategy_branch:urgent",
             "import_action" => "review_strategy_branch_alternative",
             "import_status" => "not_applicable",
             "selected" => false,
             "risk_count" => 1,
             "risk_types" => ["activity_type_suppressed_by_resource_summary"],
             "high_risk_types" => ["activity_type_suppressed_by_resource_summary"],
             "source_branch_comparison" => %{"branch_id" => "urgent"}
           } = alternative

    stale_strategy_branch_source =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "strategy_branch_comparison", "branch_id" => "urgent"} = row ->
            put_in(row, ["source_branch_comparison", "risk_count"], 2)

          row ->
            row
        end)
      end)

    assert {:error, stale_strategy_branch_source_report} =
             Schema.validate_artifact(stale_strategy_branch_source)

    assert Enum.any?(
             stale_strategy_branch_source_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.risk_count$/ and
                 &1["message"] == "must match source_branch_comparison.risk_count")
           )

    assert %{
             "id" => "cadence_import:contact_allocation:contact_allocation:urgent_downlink",
             "rank" => 3,
             "import_action" => "review_contact_allocation",
             "import_status" => "review_required_before_import",
             "source_review_type" => "contact_allocation_review",
             "branch_id" => "urgent",
             "contact_id" => "urgent_downlink",
             "allocation_status" => "deferred",
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "contact_allocation_review",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "network_scheduler",
             "sla_s" => 600,
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "policy_bundle_id" => "ground_network_allocation_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "contact_allocation_review",
               "escalation_queue" => "ground_network"
             },
             "source_contact_allocation" => %{
               "contact_id" => "urgent_downlink",
               "allocation_status" => "deferred"
             },
             "source_review_row" => %{
               "review_type" => "contact_allocation_review",
               "contact_id" => "urgent_downlink"
             }
           } = allocation_review

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "strategy import lifts generated branch resource projection review rows" do
    manifest =
      CadenceImport.from_strategy_artifact(%{
        "schema_version" => 3,
        "strategy_metadata" => %{"strategy_id" => "strategy:resource_projection"},
        "recommendation" => %{
          "schema_contract" => "strategy_recommendation.v1",
          "recommended_branch_id" => "baseline",
          "approval_status" => "operator_review_required",
          "reason" => "review_resource_pressure",
          "ranked_branch_ids" => ["baseline"],
          "tradeoffs" => [],
          "explanation" => [],
          "risks_remaining" => [],
          "requires_approval" => []
        },
        "branch_comparison_report" => %{
          "schema_contract" => "branch_comparison_report.v1",
          "rows" => []
        },
        "branches" => [
          %{
            "branch_id" => "baseline",
            "resource_projection_report" => %{
              "schema_contract" => "resource_projection_report.v1",
              "projected_resources" => [
                %{
                  "spacecraft_id" => "leo_1",
                  "projected_downlink_shortfall_mb" => 50.0,
                  "approval_status" => "blocked_by_policy",
                  "activity_resource_flow" => [
                    %{
                      "activity_id" => "dl_pressure",
                      "activity_type" => "downlink",
                      "starts_at_s" => 500.0,
                      "downlink_shortfall_mb" => 50.0
                    }
                  ]
                }
              ]
            }
          }
        ]
      })

    assert %{
             "source_artifact_type" => "campaign_strategy.v3",
             "row_count" => 1,
             "review_required_count" => 1,
             "blocked_count" => 0,
             "provenance" => %{
               "source_review_count" => 2,
               "operator_review_package_source" => "derived"
             }
           } = manifest

    assert %{
             "import_action" => "review_resource_projection",
             "import_status" => "review_required_before_import",
             "source_review_type" => "resource_projection_review",
             "branch_id" => "baseline",
             "spacecraft_id" => "leo_1",
             "projected_downlink_shortfall_mb" => 50.0,
             "first_resource_pressure_activity_id" => "dl_pressure",
             "first_resource_pressure_kind" => "downlink_shortfall",
             "source_review_row" => %{
               "source" =>
                 "campaign_strategy.branches.resource_projection_report.projected_resources"
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds realized feedback import rows from timeline feedback reports" do
    report = %{
      "schema_contract" => "timeline_feedback_report.v1",
      "id" => "timeline_feedback:manifest_test",
      "rows" => [
        %{
          "activity_id" => "cmd_1",
          "status" => "matched",
          "planned_type" => "command",
          "planned_status" => "approved",
          "realized_status" => "completed",
          "feedback_kind" => "command",
          "command_success" => true,
          "completed_fraction" => 1.0,
          "cadence_import_status" => "present",
          "cadence_import_type" => "command_window",
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
          "thermal_confidence" => 0.8
        },
        %{
          "activity_id" => "dl_1",
          "status" => "matched",
          "planned_type" => "downlink",
          "planned_status" => "approved",
          "realized_status" => "failed",
          "feedback_kind" => "contact",
          "contact_success" => false,
          "contact_result" => ["accepted", "dropped"],
          "observation_result" => [:started, :timeout],
          "ground_station_id" => "equator_prime",
          "actual_throughput_mb" => 0.0,
          "cadence_import_status" => "missing"
        }
      ],
      "provenance" => %{"source" => "cadence_feedback"}
    }

    atom_key_report =
      report
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    manifest = CadenceImport.from_timeline_feedback_report(report)

    assert OrbitalDynamics.cadence_import_manifest(report) == manifest
    assert OrbitalDynamics.cadence_import_manifest(atom_key_report) == manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "timeline_feedback_report.v1",
             "source_artifact_id" => "timeline_feedback:manifest_test",
             "row_count" => 2,
             "ready_count" => 1,
             "review_required_count" => 0,
             "blocked_count" => 1,
             "missing_import_count" => 1,
             "rows" => [ready, review]
           } = manifest

    assert %{
             "id" => "cadence_import:realized_feedback:realized_feedback:cmd_1:1",
             "import_action" => "record_realized_feedback",
             "import_status" => "ready_for_import",
             "source_review_type" => "realized_feedback",
             "source_review_action" => "record_command_completion",
             "subject_id" => "cmd_1",
             "activity_id" => "cmd_1",
             "feedback_kind" => "command",
             "realized_status" => "completed",
             "command_success" => true,
             "cadence_import_status" => "present",
             "cadence_import_type" => "command_window",
             "has_cadence_import" => true,
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
             "source_feedback" => %{"activity_id" => "cmd_1"}
           } = ready

    assert %{
             "id" => "cadence_import:realized_feedback:realized_feedback:dl_1:2",
             "import_action" => "review_realized_feedback",
             "import_status" => "blocked_missing_cadence_import",
             "source_review_action" => "review_contact_exception",
             "activity_id" => "dl_1",
             "ground_station_id" => "equator_prime",
             "contact_success" => false,
             "contact_result" => "accepted,dropped",
             "observation_result" => "started,timeout",
             "cadence_import_status" => "missing",
             "has_cadence_import" => false
           } = review

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds station-contention import rows from contact contention reports" do
    report = %{
      "schema_contract" => "contact_contention_report.v1",
      "id" => "contact_contention:manifest_test",
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
          "capacity_fraction_min" => 0.35,
          "contact_result" => ["accepted", "dropped"],
          "command_result" => [:accepted, :rejected],
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
      "provenance" => %{"source" => "contention_test"}
    }

    manifest = CadenceImport.from_contact_contention_report(report)

    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "contact_contention_report.v1",
             "source_artifact_id" => "contact_contention:manifest_test",
             "row_count" => 1,
             "ready_count" => 0,
             "review_required_count" => 1,
             "blocked_count" => 0,
             "missing_import_count" => 0,
             "rows" => [row]
           } = manifest

    assert %{
             "import_action" => "review_contact_contention",
             "import_status" => "review_required_before_import",
             "source_review_type" => "contact_contention_review",
             "source_review_action" => "review_contact_contention",
             "subject_id" => "station:equator_prime:contention:1",
             "ground_station_id" => "equator_prime",
             "contact_count" => 2,
             "contact_ids" => ["dl_1", "dl_2"],
             "source_window_ids" => [
               "window:leo_1:ground_station_access:equator_prime:1",
               "window:leo_2:ground_station_access:equator_prime:1"
             ],
             "scenario_ids" => ["leo_1", "leo_2"],
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
             "cadence_import_status" => "not_applicable",
             "source_contention_group" => %{"contact_ids" => ["dl_1", "dl_2"]}
           } = row

    assert Map.take(row, [
             "capacity_fraction_min",
             "contact_result",
             "command_result",
             "requirement_type"
           ]) == %{
             "capacity_fraction_min" => 0.35,
             "contact_result" => "accepted,dropped",
             "command_result" => "accepted,rejected",
             "requirement_type" => "contact_schedule_change"
           }

    assert Map.take(row["source_review_row"], [
             "capacity_fraction_min",
             "contact_result",
             "command_result",
             "requirement_type"
           ]) == %{
             "capacity_fraction_min" => 0.35,
             "contact_result" => "accepted,dropped",
             "command_result" => "accepted,rejected",
             "requirement_type" => "contact_schedule_change"
           }

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        [
          row
          |> Map.put("ground_station_id", "stale_station")
          |> Map.put("capacity_fraction_min", 0.9)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ground_station_id" and
                 &1["message"] == "must match source_contention_group.ground_station_id")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].capacity_fraction_min" and
                 &1["message"] == "must match source_contention_group.capacity_fraction_min")
           )

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("capacity_fraction_min", 0.9)
          |> Map.put("contact_result", "stale_result")
          |> Map.put("requirement_type", "stale_requirement")

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.capacity_fraction_min" and
                 &1["message"] == "must match capacity_fraction_min on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.contact_result" and
                 &1["message"] == "must match contact_result on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.requirement_type" and
                 &1["message"] == "must match requirement_type on Cadence import row")
           )
  end

  test "validates contact contention invalid input source handoff import rows" do
    report = %{
      "schema_contract" => "contact_contention_report.v1",
      "id" => "contact_contention:invalid_input_manifest_test",
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

    manifest = CadenceImport.from_contact_contention_report(report)

    assert %{
             "import_action" => "review_contact_contention",
             "source_review_type" => "contact_contention_review",
             "subject_id" => "invalid_contact:malformed_contact",
             "contact_id" => "malformed_contact",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_invalid_contact_input" => %{
               "ground_station_id" => "equator_prime",
               "invalid_contact_input_reason" => "invalid_contact_shape"
             },
             "source_review_row" => %{
               "review_type" => "contact_contention_review",
               "ground_station_id" => "equator_prime",
               "invalid_contact_input_reason" => "invalid_contact_shape"
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        [Map.put(row, "ground_station_id", "stale_station")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ground_station_id" and
                 &1["message"] == "must match source_invalid_contact_input.ground_station_id")
           )

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("invalid_contact_input_reason", "stale_reason")

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.invalid_contact_input_reason" and
                 &1["message"] == "must match invalid_contact_input_reason on Cadence import row")
           )
  end

  test "builds station-contention import rows from resolution recommendations" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "id" => "contact_contention_resolution:manifest_test",
      "model" => "deterministic_contact_contention_recommendation",
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
          "capacity_fraction_min" => 0.35,
          "contact_result" => ["accepted", "dropped"],
          "command_result" => [:accepted, :rejected],
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
      "provenance" => %{"source" => "contention_resolution_test"}
    }

    manifest = CadenceImport.from_contact_contention_resolution_report(report)

    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "contact_contention_resolution_report.v1",
             "source_artifact_id" => "contact_contention_resolution:manifest_test",
             "row_count" => 1,
             "review_required_count" => 1,
             "rows" => [row]
           } = manifest

    assert %{
             "import_action" => "review_contact_contention_resolution",
             "import_status" => "review_required_before_import",
             "source_review_type" => "contact_contention_recommendation",
             "source_review_action" => "recommend_preferred_contact_for_operator_review",
             "subject_id" => "station:equator_prime:contention:1",
             "selected_contact_id" => "dl_1",
             "deferred_contact_ids" => ["dl_2"],
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
           } = row

    assert Map.take(row, [
             "capacity_fraction_min",
             "contact_result",
             "command_result",
             "requirement_type"
           ]) == %{
             "capacity_fraction_min" => 0.35,
             "contact_result" => "accepted,dropped",
             "command_result" => "accepted,rejected",
             "requirement_type" => "contact_schedule_change"
           }

    assert Map.take(row["source_review_row"], [
             "capacity_fraction_min",
             "contact_result",
             "command_result",
             "requirement_type"
           ]) == %{
             "capacity_fraction_min" => 0.35,
             "contact_result" => "accepted,dropped",
             "command_result" => "accepted,rejected",
             "requirement_type" => "contact_schedule_change"
           }

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn [row] ->
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

    invalid_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        [Map.put(row, "selected_contact_id", "stale_contact")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].selected_contact_id" and
                 &1["message"] == "must match source_recommendation.selected_contact_id")
           )

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("capacity_fraction_min", 0.9)
          |> Map.put("command_result", "stale_result")
          |> Map.put("requirement_type", "stale_requirement")

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.capacity_fraction_min" and
                 &1["message"] == "must match capacity_fraction_min on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.command_result" and
                 &1["message"] == "must match command_result on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.requirement_type" and
                 &1["message"] == "must match requirement_type on Cadence import row")
           )
  end

  test "builds command-window import rows from command window reports" do
    report = %{
      "schema_contract" => "command_window_report.v1",
      "source" => "mission_plan.activities",
      "rows" => [
        %{
          "activity_id" => "cmd_1",
          "timeline_id" => "timeline:cmd_1",
          "scenario_id" => "leo_1",
          "activity_type" => "command",
          "window_type" => "command_window",
          "direction" => "command",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0,
          "status" => "planned",
          "approval_status" => "operator_review_required",
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
          "cadence_import_type" => "command_window",
          "dependency_activity_ids" => ["health_gate"],
          "dependency_timeline_ids" => ["timeline:health_gate"],
          "exclusive_with_activity_ids" => ["downlink_conflict"],
          "exclusive_with_timeline_ids" => ["timeline:downlink_conflict"],
          "source_window_id" => "window:cmd_1",
          "source_window_type" => "ground_station_access",
          "has_source_window" => true,
          "has_cadence_import" => false,
          "timeline_identity" => %{
            "timeline_id" => "timeline:cmd_1",
            "activity_id" => "cmd_1",
            "activity_type" => "command",
            "scenario_id" => "leo_1"
          },
          "activity_context" => %{
            "starts_at_s" => 10.0,
            "ends_at_s" => 20.0,
            "dependency_timeline_ids" => ["timeline:health_gate"],
            "source_window_id" => "window:cmd_1",
            "command_success" => false,
            "contact_result" => ["accepted", "dropped"],
            "command_result" => [:accepted, :rejected],
            "command_success_factor" => 0.25,
            "timeline_identity" => %{
              "timeline_id" => "timeline:cmd_1",
              "activity_id" => "cmd_1",
              "source_window_id" => "window:cmd_1"
            }
          }
        }
      ]
    }

    manifest = CadenceImport.from_command_window_report(report)

    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "command_window_report.v1",
             "source_artifact_id" => "mission_plan.activities",
             "row_count" => 1,
             "ready_count" => 0,
             "review_required_count" => 0,
             "blocked_count" => 1,
             "missing_import_count" => 1,
             "rows" => [row]
           } = manifest

    assert %{
             "import_action" => "review_command_window",
             "import_status" => "blocked_missing_cadence_import",
             "source_review_type" => "command_window_review",
             "source_review_action" => "review_command_contact",
             "activity_id" => "cmd_1",
             "timeline_id" => "timeline:cmd_1",
             "window_type" => "command_window",
             "dependency_activity_ids" => ["health_gate"],
             "dependency_timeline_ids" => ["timeline:health_gate"],
             "exclusive_with_activity_ids" => ["downlink_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:downlink_conflict"],
             "cadence_import_status" => "missing",
             "command_success" => false,
             "contact_result" => "accepted,dropped",
             "command_result" => "accepted,rejected",
             "command_success_factor" => 0.25,
             "has_cadence_import" => false,
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
               "source_window_id" => "window:cmd_1",
               "contact_result" => "accepted,dropped",
               "command_result" => "accepted,rejected",
               "timeline_identity" => %{"timeline_id" => "timeline:cmd_1"}
             },
             "import_activity_context" => %{
               "dependency_timeline_ids" => ["timeline:health_gate"],
               "contact_result" => "accepted,dropped",
               "command_result" => "accepted,rejected",
               "timeline_identity" => %{"activity_id" => "cmd_1"}
             },
             "source_command_window" => %{"activity_id" => "cmd_1"},
             "source_review_row" => %{
               "review_type" => "command_window_review",
               "timeline_id" => "timeline:cmd_1",
               "has_source_window" => true,
               "command_result" => "accepted,rejected",
               "requirement_type" => "command_review",
               "escalation_queue" => "command_review",
               "source_activity_context" => %{
                 "contact_result" => "accepted,dropped",
                 "command_result" => "accepted,rejected"
               }
             }
           } = row

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        [
          row
          |> Map.put("timeline_id", "timeline:stale")
          |> Map.put("has_source_window", false)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].timeline_id" and
                 &1["message"] == "must match source_command_window.timeline_id")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].has_source_window" and
                 &1["message"] == "must match source_command_window.has_source_window")
           )

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("timeline_id", "timeline:stale")
          |> Map.put("command_result", "stale_result")
          |> Map.put("requirement_type", "stale_requirement")
          |> Map.put("escalation_queue", "stale_queue")

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.timeline_id" and
                 &1["message"] == "must match timeline_id on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.command_result" and
                 &1["message"] == "must match command_result on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.requirement_type" and
                 &1["message"] == "must match requirement_type on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.escalation_queue" and
                 &1["message"] == "must match escalation_queue on Cadence import row")
           )
  end

  test "normalizes map-valued provider results in operational timeline import rows" do
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

    manifest = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "import_action" => "review_operational_timeline",
             "activity_id" => "cmd_provider_map",
             "contact_result" => "accepted,NO-CONTACT",
             "command_result" => "rejected,timed out",
             "source_activity_context" => %{
               "contact_result" => "accepted,NO-CONTACT",
               "command_result" => "rejected,timed out"
             },
             "import_activity_context" => %{
               "contact_result" => "accepted,NO-CONTACT",
               "command_result" => "rejected,timed out"
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds operational timeline import rows from operational timeline reports" do
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
            "dependency_activity_ids" => ["health_1"],
            "dependency_timeline_ids" => ["timeline:health_1"],
            "exclusive_with_activity_ids" => ["health_1"],
            "exclusive_with_timeline_ids" => ["timeline:health_1"],
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

    manifest = CadenceImport.from_operational_timeline_report(report)

    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "operational_timeline_report.v1",
             "source_artifact_id" => "mission_plan.activities",
             "row_count" => 2,
             "ready_count" => 0,
             "review_required_count" => 1,
             "blocked_count" => 1,
             "missing_import_count" => 1,
             "rows" => rows
           } = manifest

    assert %{
             "import_action" => "review_operational_timeline",
             "import_status" => "review_required_before_import",
             "source_review_type" => "operational_timeline_review",
             "source_review_action" => "review_command_contact",
             "activity_id" => "cmd_1",
             "timeline_id" => "timeline:cmd_1",
             "operational_kind" => "command",
             "cadence_import_status" => "present",
             "cadence_import_type" => "command_window",
             "cadence_import_id" => "cadence_cmd_1",
             "cadence_import_contract" => "command_window.v1",
             "contact_result" => "accepted,DROPPED",
             "command_result" => "accepted,rejected",
             "dependency_activity_ids" => ["health_1"],
             "dependency_timeline_ids" => ["timeline:health_1"],
             "exclusive_with_activity_ids" => ["health_1"],
             "exclusive_with_timeline_ids" => ["timeline:health_1"],
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
               "lighting_condition" => "partial_eclipse",
               "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
               "lighting_confidence" => 0.82
             },
             "import_activity_context" => %{
               "contact_result" => "accepted,DROPPED",
               "command_result" => "accepted,rejected",
               "lighting_condition" => "partial_eclipse",
               "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
               "lighting_confidence" => 0.82
             },
             "source_operational_timeline" => %{
               "activity_id" => "cmd_1",
               "timeline_id" => "timeline:cmd_1",
               "cadence_import_status" => "present",
               "cadence_import_type" => "command_window"
             },
             "source_review_row" => %{
               "review_type" => "operational_timeline_review",
               "activity_id" => "cmd_1"
             }
           } = Enum.find(rows, &(&1["activity_id"] == "cmd_1"))

    assert %{
             "import_action" => "review_operational_timeline",
             "import_status" => "blocked_missing_cadence_import",
             "source_review_action" => "prepare_cadence_import",
             "activity_id" => "dl_1",
             "cadence_import_status" => "missing",
             "source_operational_timeline" => %{
               "activity_id" => "dl_1",
               "timeline_id" => "timeline:dl_1",
               "cadence_import_status" => "missing"
             }
           } = Enum.find(rows, &(&1["activity_id"] == "dl_1"))

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_operational_timeline =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{
            "source_review_type" => "operational_timeline_review",
            "source_operational_timeline" => %{}
          } = row ->
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

    stale_source_review_operational_timeline =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{
            "source_review_type" => "operational_timeline_review",
            "source_review_row" => %{}
          } = row ->
            source_review_row =
              row["source_review_row"]
              |> Map.put("activity_id", "stale_cmd")
              |> Map.put("timeline_id", "timeline:stale_cmd")

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_review_operational_timeline_report} =
             Schema.validate_artifact(stale_source_review_operational_timeline)

    assert Enum.any?(
             stale_source_review_operational_timeline_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.activity_id$/ and
                 &1["message"] == "must match activity_id on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_operational_timeline_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.timeline_id$/ and
                 &1["message"] == "must match timeline_id on Cadence import row")
           )
  end

  test "builds station-calendar import rows from station calendar reports" do
    report = %{
      "schema_contract" => "station_calendar_report.v1",
      "affected_contacts" => [
        %{
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
          "contact_result" => ["accepted", "dropped"],
          "command_result" => [:accepted, :rejected],
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
      "assumptions" => %{"source" => "ops_calendar"}
    }

    manifest = CadenceImport.from_station_calendar_report(report)

    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "station_calendar_report.v1",
             "source_artifact_id" => "ops_calendar",
             "row_count" => 1,
             "ready_count" => 0,
             "review_required_count" => 1,
             "blocked_count" => 0,
             "missing_import_count" => 0,
             "rows" => [row]
           } = manifest

    assert %{
             "import_action" => "review_station_calendar",
             "import_status" => "review_required_before_import",
             "source_review_type" => "station_calendar_review",
             "source_review_action" => "review_station_reservation_overlap",
             "contact_id" => "cmd_1",
             "activity_type" => "planned_contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "equator_reserved",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_reserved_1",
             "station_calendar_directions" => ["command"],
             "station_availability" => "reserved",
             "station_calendar_entry_ambiguous" => true,
             "station_calendar_ambiguous_entry_count" => 2,
             "station_calendar_ambiguous_entry_ids" => [
               "equator_reserved",
               "equator_backup_reserved"
             ],
             "station_calendar_trust_boundary_status" => "declared",
             "trust_boundary" => "operator_declared_station_calendar",
             "station_reservation_id" => "provider_reservation_42",
             "contact_result" => "accepted,dropped",
             "command_result" => "accepted,rejected",
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
             "cadence_import_status" => "not_applicable",
             "source_station_calendar_entry" => %{
               "id" => "equator_reserved",
               "availability" => "reserved"
             },
             "source_station_calendar_overlaps" => [
               %{"id" => "equator_reserved", "availability" => "reserved"},
               %{"id" => "equator_capacity", "availability" => "reduced_capacity"}
             ],
             "source_station_calendar_review" => %{"contact_id" => "cmd_1"},
             "source_review_row" => %{
               "review_type" => "station_calendar_review",
               "contact_id" => "cmd_1",
               "starts_at_s" => 10.0,
               "station_contention_status" => "reserved_overlap",
               "contact_result" => "accepted,dropped",
               "command_result" => "accepted,rejected",
               "required_authority" => "contact_schedule_authority",
               "escalation_queue" => "ground_network",
               "source_policy_decision" => %{
                 "policy_bundle_id" => "ground_network_allocation_v1"
               }
             }
           } = row

    assert get_in(row, ["source_station_calendar_review", "station_contention_status"]) ==
             "reserved_overlap"

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn [row] ->
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
      update_in(manifest, ["rows"], fn [row] ->
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

    invalid_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        [
          row
          |> Map.put("station_contention_status", "stale_contention_status")
          |> Map.put("starts_at_s", 11.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

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

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("starts_at_s", 11.0)
          |> Map.put("contact_result", "stale_result")
          |> Map.put("required_authority", "stale_authority")
          |> Map.put("escalation_queue", "stale_queue")
          |> Map.put("source_policy_decision", %{
            "policy_bundle_id" => "stale_policy"
          })

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.starts_at_s" and
                 &1["message"] == "must match starts_at_s on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.contact_result" and
                 &1["message"] == "must match contact_result on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.required_authority" and
                 &1["message"] == "must match required_authority on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.escalation_queue" and
                 &1["message"] == "must match escalation_queue on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_policy_decision" and
                 &1["message"] == "must match source_policy_decision on Cadence import row")
           )
  end

  test "builds generic import rows for remaining operator-review surfaces" do
    package = %{
      "schema_contract" => "operator_review_package.v1",
      "model" => "artifact_only_operator_review_package",
      "source_artifact_type" => "operator_review_package.v1",
      "source_artifact_id" => "review:generic_manifest",
      "review_count" => 5,
      "approval_requirement_count" => 1,
      "contention_recommendation_count" => 0,
      "realized_feedback_count" => 0,
      "warning_count" => 1,
      "risk_count" => 0,
      "recommendation_count" => 0,
      "rows" => [
        %{
          "id" => "link_capacity:equator_prime:1",
          "rank" => 1,
          "review_type" => "link_capacity_review",
          "source" => "link_capacity_report.rows",
          "subject_id" => "equator_prime",
          "ground_station_id" => "equator_prime",
          "action" => "review_link_capacity_summary",
          "required_operator_action" => "review_link_capacity_summary",
          "approval_status" => "operator_review_required",
          "reason" => "review downlink capacity",
          "selected_contact_count" => 1,
          "selected_estimated_throughput_mb" => 42.0
        },
        %{
          "id" => "resource_projection:leo_1:1",
          "rank" => 2,
          "review_type" => "resource_projection_review",
          "source" => "resource_projection_report.projected_resources",
          "subject_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "action" => "review_resource_projection",
          "required_operator_action" => "review_resource_projection",
          "approval_status" => "operator_review_required",
          "reason" => "review resource projection",
          "activity_count" => 3,
          "effective_activity_count" => 2,
          "ignored_activity_count" => 1,
          "ignored_activity_ids" => ["dl_rejected"],
          "projected_storage_margin" => 0.12,
          "projected_downlink_shortfall_mb" => 5.0,
          "storage_limited_downlinked_mb" => 40.0,
          "unused_downlink_capacity_mb" => 20.0,
          "resource_flow_count" => 2,
          "total_battery_energy_consumed_wh" => 23.0,
          "total_battery_energy_generated_wh" => 8.0,
          "net_battery_energy_delta_wh" => 15.0,
          "peak_storage_overflow_mb" => 12.0,
          "peak_downlink_shortfall_mb" => 5.0,
          "peak_battery_overuse_wh" => 4.0,
          "peak_unused_downlink_capacity_mb" => 20.0,
          "first_resource_pressure_activity_id" => "obs_1",
          "first_resource_pressure_activity_type" => "observe",
          "first_resource_pressure_kind" => "storage_overflow",
          "first_resource_pressure_starts_at_s" => 10.0,
          "resource_trust_boundary_status" => "missing",
          "approval_requirements" => [
            %{
              "schema_contract" => "approval_requirement.v1",
              "id" => "approval:resource_projection:leo_1:storage_overflow",
              "activity_id" => "resource_projection:leo_1",
              "activity_type" => "resource_projection",
              "action" => "review_resource_projection",
              "requirement_type" => "operator_review",
              "reason" => "storage_overflow 12.0 MB for leo_1"
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
          "source_policy_escalation" => %{
            "rule_id" => "resource_pressure_block",
            "required_authority" => "resource_authority",
            "escalation_level" => "mission_planner",
            "escalation_queue" => "resource_planning",
            "escalation_role" => "resource_planner",
            "sla_s" => 1200
          },
          "source_policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "policy_bundle_id" => "resource_projection_authority_v1"
          },
          "source_resource_projection" => %{
            "spacecraft_id" => "leo_1",
            "resource_trust_boundary_status" => "missing"
          }
        },
        %{
          "id" => "approval:obs_1:1",
          "rank" => 3,
          "review_type" => "approval_requirement",
          "source" => "approval_requirement",
          "subject_id" => "obs_1",
          "activity_id" => "obs_1",
          "activity_type" => "observe",
          "target_id" => "target_alpha",
          "action" => "approve_strategic_addition",
          "required_operator_action" => "approve_strategic_addition",
          "approval_status" => "not_required",
          "reason" => "already approved",
          "requirement_type" => "strategic_addition",
          "candidate_diff" => %{
            "invalidated_candidate_id" => "obs_old",
            "invalidated_candidate_ids" => ["obs_old", "obs_old_copy"],
            "replacement_candidate_id" => "obs_1",
            "invalidated_reason" => "ambiguous_candidate_diff_match",
            "candidate_diff_match_status" => "ambiguous_replacement_candidate_diff",
            "candidate_diff_match_count" => 2,
            "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
            "candidate_budget_match_count" => 1,
            "budget_dropped_candidate_ids" => ["obs_1"],
            "semantic_change_reasons" => ["source_window_id_changed"]
          },
          "activity_context" => %{
            "timeline_identity" => %{
              "timeline_id" => "timeline:obs_1",
              "activity_id" => "obs_1"
            },
            "dependency_timeline_ids" => ["timeline:command_1"],
            "target_priority" => 4.0,
            "observation_success_factor" => 0.5,
            "contact_success_factor" => 0.4,
            "contact_success_factor_source" => "operational_feedback.contact_success_rate.station"
          },
          "source_requirement" => %{
            "schema_contract" => "approval_requirement.v1",
            "activity_id" => "obs_1",
            "target_id" => "target_alpha",
            "activity_type" => "observe",
            "action" => "approve_strategic_addition"
          }
        },
        %{
          "id" => "warning:campaign:1",
          "rank" => 4,
          "review_type" => "warning",
          "source" => "campaign_plan.warnings",
          "subject_id" => "campaign",
          "action" => "review_warning",
          "required_operator_action" => "review_warning",
          "approval_status" => "operator_review_required",
          "reason" => "review campaign warning",
          "severity" => "warning"
        },
        %{
          "id" => "timeline_diff:obs_1:1",
          "rank" => 5,
          "review_type" => "timeline_diff_review",
          "source" => "timeline_diff_report.rows",
          "subject_id" => "timeline:obs_1",
          "timeline_id" => "timeline:obs_1",
          "diff_status" => "changed",
          "activity_id" => "obs_1",
          "activity_type" => "observation",
          "scenario_id" => "scenario:import",
          "source_activity_id" => "obs_1",
          "replacement_activity_id" => "obs_1",
          "source_activity_type" => "observation",
          "replacement_activity_type" => "observation",
          "source_protection_decision" => %{
            "activity_id" => "obs_1",
            "timeline_id" => "timeline:obs_1",
            "timeline_preservation_protection_decision" => "preserve",
            "protection_category" => "locked_or_approved",
            "reason" => "activity_locked_or_approved"
          },
          "source_protection_category" => "locked_or_approved",
          "source_protection_reason" => "activity_locked_or_approved",
          "replacement_protection_decision" => %{
            "activity_id" => "obs_1",
            "timeline_id" => "timeline:obs_1",
            "protection_decision" => "mutable",
            "protection_category" => "none",
            "reason" => "no_timeline_protection"
          },
          "replacement_protection_category" => "none",
          "replacement_protection_reason" => "no_timeline_protection",
          "action" => "review_timeline_diff",
          "required_operator_action" => "review_timeline_diff",
          "approval_status" => "operator_review_required",
          "reason" => "dependency changed",
          "operator_action_reason" => "dependency changed",
          "changed_fields" => ["dependency_timeline_ids"],
          "status_transition" => %{
            "field" => "status",
            "from" => "planned",
            "to" => "partial",
            "transition_type" => "changed"
          },
          "approval_transition" => %{
            "field" => "approval_status",
            "from" => "approved",
            "to" => "operator_review_required",
            "transition_type" => "changed"
          },
          "source_timeline_identity" => %{
            "timeline_id" => "timeline:obs_1",
            "activity_id" => "obs_1"
          },
          "replacement_timeline_identity" => %{
            "timeline_id" => "timeline:obs_1",
            "activity_id" => "obs_1"
          },
          "timeline_link" => %{
            "source_timeline_id" => "timeline:obs_1",
            "replacement_timeline_id" => "timeline:obs_1",
            "source_timeline_identity" => %{
              "timeline_id" => "timeline:obs_1",
              "activity_id" => "obs_1"
            },
            "replacement_timeline_identity" => %{
              "timeline_id" => "timeline:obs_1",
              "activity_id" => "obs_1"
            }
          },
          "source_activity_context" => %{
            "timeline_identity" => %{
              "timeline_id" => "timeline:obs_1",
              "activity_id" => "obs_1"
            },
            "exclusive_with_timeline_ids" => ["timeline:obs_2"]
          },
          "source_timeline_diff" => %{
            "timeline_id" => "timeline:obs_1",
            "changed_fields" => ["dependency_timeline_ids"],
            "requires_operator_review" => true
          }
        }
      ],
      "provenance" => %{},
      "assumptions" => %{}
    }

    manifest = CadenceImport.from_operator_review_package(package)

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "operator_review_package.v1",
             "source_artifact_id" => "review:generic_manifest",
             "row_count" => 5,
             "ready_count" => 1,
             "review_required_count" => 4,
             "blocked_count" => 0,
             "missing_import_count" => 0,
             "rows" => rows
           } = manifest

    assert Enum.map(rows, & &1["import_action"]) == [
             "review_link_capacity",
             "review_resource_projection",
             "review_approval_requirement",
             "review_warning",
             "review_timeline_diff"
           ]

    assert %{
             "import_status" => "ready_for_import",
             "activity_id" => "obs_1",
             "target_id" => "target_alpha",
             "requirement_type" => "strategic_addition",
             "invalidated_candidate_id" => "obs_old",
             "invalidated_candidate_ids" => ["obs_old", "obs_old_copy"],
             "replacement_candidate_id" => "obs_1",
             "invalidated_reason" => "ambiguous_candidate_diff_match",
             "candidate_diff_match_status" => "ambiguous_replacement_candidate_diff",
             "candidate_diff_match_count" => 2,
             "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
             "candidate_budget_match_count" => 1,
             "budget_dropped_candidate_ids" => ["obs_1"],
             "import_activity_context" => %{
               "dependency_timeline_ids" => ["timeline:command_1"],
               "target_priority" => 4.0,
               "observation_success_factor" => 0.5,
               "contact_success_factor" => 0.4,
               "contact_success_factor_source" =>
                 "operational_feedback.contact_success_rate.station"
             },
             "candidate_diff" => %{
               "semantic_change_reasons" => ["source_window_id_changed"]
             },
             "source_requirement" => %{
               "schema_contract" => "approval_requirement.v1",
               "activity_id" => "obs_1",
               "target_id" => "target_alpha",
               "action" => "approve_strategic_addition"
             },
             "source_review_row" => %{"review_type" => "approval_requirement"}
           } = Enum.find(rows, &(&1["source_review_type"] == "approval_requirement"))

    assert %{
             "import_action" => "review_resource_projection",
             "activity_count" => 3,
             "effective_activity_count" => 2,
             "ignored_activity_count" => 1,
             "ignored_activity_ids" => ["dl_rejected"],
             "projected_downlink_shortfall_mb" => 5.0,
             "storage_limited_downlinked_mb" => 40.0,
             "unused_downlink_capacity_mb" => 20.0,
             "resource_flow_count" => 2,
             "total_battery_energy_consumed_wh" => 23.0,
             "total_battery_energy_generated_wh" => 8.0,
             "net_battery_energy_delta_wh" => 15.0,
             "peak_storage_overflow_mb" => 12.0,
             "peak_battery_overuse_wh" => 4.0,
             "peak_unused_downlink_capacity_mb" => 20.0,
             "first_resource_pressure_activity_id" => "obs_1",
             "first_resource_pressure_kind" => "storage_overflow",
             "resource_trust_boundary_status" => "missing",
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
             "source_policy_escalation" => %{
               "rule_id" => "resource_pressure_block",
               "escalation_queue" => "resource_planning"
             },
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "policy_bundle_id" => "resource_projection_authority_v1"
             },
             "source_resource_projection" => %{
               "spacecraft_id" => "leo_1",
               "resource_trust_boundary_status" => "missing"
             },
             "source_review_row" => %{
               "review_type" => "resource_projection_review",
               "activity_count" => 3,
               "ignored_activity_ids" => ["dl_rejected"],
               "projected_downlink_shortfall_mb" => 5.0,
               "resource_trust_boundary_status" => "missing"
             }
           } = Enum.find(rows, &(&1["source_review_type"] == "resource_projection_review"))

    invalid_resource_projection_review =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "resource_projection_review"} = row ->
            source_review_row =
              row["source_review_row"]
              |> Map.put("activity_count", 4)
              |> Map.put("ignored_activity_ids", [])
              |> Map.put("projected_downlink_shortfall_mb", 6.0)
              |> Map.put("resource_trust_boundary_status", "declared")

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, resource_projection_report} =
             Schema.validate_artifact(invalid_resource_projection_review)

    assert Enum.any?(
             resource_projection_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.activity_count$/ and
                 &1["message"] == "must match activity_count on Cadence import row")
           )

    assert Enum.any?(
             resource_projection_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.ignored_activity_ids$/ and
                 &1["message"] == "must match ignored_activity_ids on Cadence import row")
           )

    assert Enum.any?(
             resource_projection_report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_review_row\.projected_downlink_shortfall_mb$/ and
                 &1["message"] ==
                   "must match projected_downlink_shortfall_mb on Cadence import row")
           )

    assert Enum.any?(
             resource_projection_report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_review_row\.resource_trust_boundary_status$/ and
                 &1["message"] ==
                   "must match resource_trust_boundary_status on Cadence import row")
           )

    timeline_diff_row = Enum.find(rows, &(&1["source_review_type"] == "timeline_diff_review"))

    assert timeline_diff_row["import_action"] == "review_timeline_diff"
    assert timeline_diff_row["diff_status"] == "changed"
    assert timeline_diff_row["activity_id"] == "obs_1"
    assert timeline_diff_row["activity_type"] == "observation"
    assert timeline_diff_row["source_activity_id"] == "obs_1"
    assert timeline_diff_row["replacement_activity_id"] == "obs_1"
    assert timeline_diff_row["operator_action_reason"] == "dependency changed"
    assert timeline_diff_row["source_protection_category"] == "locked_or_approved"
    assert timeline_diff_row["source_protection_reason"] == "activity_locked_or_approved"
    assert timeline_diff_row["replacement_protection_category"] == "none"
    assert timeline_diff_row["replacement_protection_reason"] == "no_timeline_protection"

    assert get_in(timeline_diff_row, [
             "source_protection_decision",
             "timeline_preservation_protection_decision"
           ]) ==
             "preserve"

    assert get_in(timeline_diff_row, ["source_protection_decision", "protection_category"]) ==
             "locked_or_approved"

    assert get_in(timeline_diff_row, ["replacement_protection_decision", "protection_decision"]) ==
             "mutable"

    assert get_in(timeline_diff_row, ["replacement_protection_decision", "protection_category"]) ==
             "none"

    assert get_in(timeline_diff_row, ["source_timeline_identity", "timeline_id"]) ==
             "timeline:obs_1"

    assert get_in(timeline_diff_row, ["replacement_timeline_identity", "timeline_id"]) ==
             "timeline:obs_1"

    assert get_in(timeline_diff_row, ["timeline_link", "source_timeline_id"]) ==
             "timeline:obs_1"

    assert get_in(timeline_diff_row, [
             "source_review_row",
             "source_timeline_identity",
             "timeline_id"
           ]) == "timeline:obs_1"

    assert get_in(timeline_diff_row, [
             "source_review_row",
             "replacement_timeline_identity",
             "timeline_id"
           ]) == "timeline:obs_1"

    assert get_in(timeline_diff_row, ["source_review_row", "timeline_link", "source_timeline_id"]) ==
             "timeline:obs_1"

    assert get_in(timeline_diff_row, ["source_activity_context", "exclusive_with_timeline_ids"]) ==
             ["timeline:obs_2"]

    assert get_in(timeline_diff_row, ["import_activity_context", "exclusive_with_timeline_ids"]) ==
             ["timeline:obs_2"]

    assert get_in(timeline_diff_row, ["source_timeline_diff", "requires_operator_review"])

    assert get_in(timeline_diff_row, [
             "source_review_row",
             "source_timeline_diff",
             "requires_operator_review"
           ])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_timeline_identity =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "timeline_diff_review"} = row ->
            row
            |> put_in(["source_timeline_identity", "timeline_id"], "bad timeline id")
            |> put_in(
              ["source_review_row", "source_timeline_identity", "timeline_id"],
              "bad timeline id"
            )

          row ->
            row
        end)
      end)

    assert {:error, invalid_timeline_identity_report} =
             Schema.validate_artifact(invalid_timeline_identity)

    assert Enum.any?(
             invalid_timeline_identity_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_timeline_identity\.timeline_id$/)
           )

    assert Enum.any?(
             invalid_timeline_identity_report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_review_row\.source_timeline_identity\.timeline_id$/)
           )

    invalid_timeline_link =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "timeline_diff_review"} = row ->
            row
            |> put_in(["timeline_link", "source_timeline_id"], "bad timeline id")
            |> put_in(
              ["source_review_row", "timeline_link", "source_timeline_id"],
              "bad timeline id"
            )

          row ->
            row
        end)
      end)

    assert {:error, invalid_timeline_link_report} =
             Schema.validate_artifact(invalid_timeline_link)

    assert Enum.any?(
             invalid_timeline_link_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.timeline_link\.source_timeline_id$/)
           )

    assert Enum.any?(
             invalid_timeline_link_report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_review_row\.timeline_link\.source_timeline_id$/)
           )

    stale_source_timeline_diff =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "timeline_diff_review"} = row ->
            source_timeline_diff =
              row["source_timeline_diff"]
              |> Map.put("diff_status", "removed")
              |> Map.put("changed_fields", ["stale_changed_field"])

            Map.put(row, "source_timeline_diff", source_timeline_diff)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_timeline_diff_report} =
             Schema.validate_artifact(stale_source_timeline_diff)

    assert Enum.any?(
             stale_source_timeline_diff_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.changed_fields$/ and
                 &1["message"] == "must match source_timeline_diff.changed_fields")
           )

    assert Enum.any?(
             stale_source_timeline_diff_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.diff_status$/ and
                 &1["message"] == "must match source_timeline_diff.diff_status")
           )

    stale_source_review =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "timeline_diff_review"} = row ->
            source_review_row =
              row["source_review_row"]
              |> Map.put("diff_status", "removed")
              |> Map.put("changed_fields", ["stale_changed_field"])

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.changed_fields$/ and
                 &1["message"] == "must match changed_fields on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.diff_status$/ and
                 &1["message"] == "must match diff_status on Cadence import row")
           )
  end

  test "schema validation rejects resource projection import counts stale against source flow" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "model" => "thin_campaign_selected_activity_resource_projection",
      "input_resource_summary_count" => 1,
      "activity_count" => 3,
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "activity_count" => 3,
          "effective_activity_count" => 2,
          "ignored_activity_count" => 1,
          "ignored_activity_ids" => ["cmd_ignored"],
          "observation_count" => 1,
          "downlink_count" => 1,
          "projected_storage_margin" => 0.7,
          "activity_resource_flow" => [
            %{
              "activity_id" => "obs_1",
              "activity_type" => "observe",
              "battery_energy_consumed_wh" => 5.0
            },
            %{
              "activity_id" => "dl_1",
              "activity_type" => "planned_contact",
              "direction" => "downlink",
              "ground_station_id" => "equator_prime",
              "battery_energy_generated_wh" => 3.0
            },
            %{
              "activity_id" => "cmd_ignored",
              "activity_type" => "command",
              "resource_effect_status" => "ignored"
            }
          ]
        }
      ],
      "assumptions" => %{"source" => "resource_projection_handoff"}
    }

    manifest = CadenceImport.from_resource_projection_report(report)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid =
      update_in(manifest, ["rows"], fn [row | rows] ->
        stale_source_review_row =
          row["source_review_row"]
          |> Map.put("activity_count", 99)
          |> Map.put("ignored_activity_ids", [])

        stale_row =
          row
          |> Map.put("activity_count", 99)
          |> Map.put("ignored_activity_ids", [])
          |> Map.put("source_review_row", stale_source_review_row)

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

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.activity_count" and
                 &1["message"] == "must equal source_resource_projection flow row count")
           )
  end

  test "builds import manifest from resource projection flow summary rows" do
    flow_summary = resource_projection_flow_summary()

    manifest = CadenceImport.from_resource_projection_flow_summary(flow_summary)

    assert CadenceImport.manifest(flow_summary) == manifest
    assert OrbitalDynamics.cadence_import_manifest(flow_summary) == manifest

    assert %{
             "source_artifact_type" => "resource_projection_flow_summary.v1",
             "source_artifact_id" => "flow_handoff",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_resource_projection" => 1},
             "source_review_type_counts" => %{"resource_projection_review" => 1}
           } = manifest

    row = List.first(manifest["rows"])

    assert %{
             "import_action" => "review_resource_projection",
             "source_review_type" => "resource_projection_review",
             "spacecraft_id" => "leo_1",
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
             "first_resource_pressure_kind" => "storage_overflow",
             "source_resource_projection_flow_summary" => %{
               "schema_contract" => "resource_projection_flow_summary.v1",
               "resource_flow_status" => "review_required",
               "total_downlink_shortfall_mb" => 5.0
             },
             "source_review_row" => %{
               "review_type" => "resource_projection_review",
               "source" => "resource_projection_flow_summary.projected_resources",
               "source_resource_projection_flow_summary" => %{
                 "schema_contract" => "resource_projection_flow_summary.v1"
               }
             }
           } = row

    assert row["projected_storage_remaining_mb"] == 0.0
    assert row["projected_downlink_remaining_mb"] == 0.0

    flow_context = row["source_resource_projection_flow_summary"]
    assert flow_context["total_projected_storage_remaining_mb"] == 0.0
    assert flow_context["minimum_projected_storage_remaining_mb"] == 0.0
    assert flow_context["total_projected_downlink_remaining_mb"] == 0.0
    assert flow_context["minimum_projected_downlink_remaining_mb"] == 0.0

    assert row["source_resource_projection"]["source_resource_projection_flow_summary"][
             "schema_contract"
           ] == "resource_projection_flow_summary.v1"

    assert length(row["source_resource_projection"]["activity_resource_flow"]) == 2

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_summary =
      update_in(manifest, ["rows"], fn [row] ->
        [
          put_in(
            row,
            [
              "source_resource_projection",
              "source_resource_projection_flow_summary",
              "total_downlink_shortfall_mb"
            ],
            6.0
          )
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_summary)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_resource_projection_flow_summary" and
                 &1["message"] ==
                   "must match source_resource_projection.source_resource_projection_flow_summary")
           )

    invalid_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> put_in(
            ["source_resource_projection_flow_summary", "total_downlink_shortfall_mb"],
            6.0
          )

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_resource_projection_flow_summary" and
                 &1["message"] ==
                   "must match source_resource_projection_flow_summary on Cadence import row")
           )
  end

  test "builds policy escalation import rows with authority queue context" do
    decision = %{
      "schema_contract" => "policy_decision.v1",
      "classification" => "operator_review_required",
      "model_limits" => Policy.capabilities().known_limits |> Enum.map(&to_string/1),
      "policy_bundle_id" => "command_contact_authority_v1",
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
          "rule_id" => "command_uplink_authority_review",
          "classification" => "operator_review_required",
          "escalation_level" => "authority_review",
          "escalation_queue" => "mission_operations",
          "escalation_role" => "command_authority",
          "required_authority" => "command_authority",
          "sla_s" => 900
        }
      ],
      "provenance" => %{"source" => "test"}
    }

    manifest = CadenceImport.from_policy_decision(decision)

    assert OrbitalDynamics.cadence_import_manifest(decision) == manifest

    assert %{
             "source_artifact_type" => "policy_decision.v1",
             "source_artifact_id" => "command_contact_authority_v1",
             "row_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "import_action" => "review_policy_escalation",
                 "import_status" => "review_required_before_import",
                 "source_review_type" => "policy_escalation",
                 "source_review_action" => "review_policy_escalation",
                 "policy_bundle_id" => "command_contact_authority_v1",
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
                 "rule_id" => "command_uplink_authority_review",
                 "escalation_level" => "authority_review",
                 "escalation_queue" => "mission_operations",
                 "escalation_role" => "command_authority",
                 "required_authority" => "command_authority",
                 "sla_s" => 900,
                 "source_policy_escalation" => %{
                   "rule_id" => "command_uplink_authority_review"
                 },
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
                 },
                 "source_review_row" => %{"review_type" => "policy_escalation"}
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_review =
      update_in(manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        row
        |> Map.put("rule_id", "stale_rule")
        |> Map.put("escalation_queue", "stale_queue")
      end)

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.rule_id" and
                 &1["message"] == "must match rule_id on Cadence import row")
           )

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.escalation_queue" and
                 &1["message"] == "must match escalation_queue on Cadence import row")
           )
  end

  test "builds generic import rows from standalone review reports" do
    link_report = %{
      "schema_contract" => "link_capacity_report.v1",
      "source" => "campaign_plan.candidate_activities",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "contact_count" => 2,
          "contact_ids" => ["selected_contact", "rejected_contact"],
          "ignored_contact_count" => 1,
          "ignored_contact_ids" => ["rejected_contact"],
          "ignored_contact_reason_counts" => %{"approval_status_rejected" => 1},
          "selected_contact_count" => 1,
          "selected_contact_ids" => ["selected_contact"],
          "ignored_selected_contact_count" => 1,
          "ignored_selected_contact_ids" => ["rejected_contact"],
          "ignored_selected_contact_reason_counts" => %{"approval_status_rejected" => 1},
          "estimated_throughput_mb" => 100.0,
          "selected_estimated_throughput_mb" => 40.0,
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
              "capacity_fraction" => 0.4
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
          }
        }
      ]
    }

    manifest = CadenceImport.from_link_capacity_report(link_report)

    assert OrbitalDynamics.cadence_import_manifest(link_report) == manifest

    assert %{
             "source_artifact_type" => "link_capacity_report.v1",
             "source_artifact_id" => "campaign_plan.candidate_activities",
             "row_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "import_action" => "review_link_capacity",
                 "source_review_type" => "link_capacity_review",
                 "ground_station_id" => "equator_prime",
                 "contact_count" => 2,
                 "contact_ids" => ["selected_contact", "rejected_contact"],
                 "ignored_contact_count" => 1,
                 "ignored_contact_ids" => ["rejected_contact"],
                 "ignored_contact_reason_counts" => %{"approval_status_rejected" => 1},
                 "selected_contact_count" => 1,
                 "selected_contact_ids" => ["selected_contact"],
                 "ignored_selected_contact_count" => 1,
                 "ignored_selected_contact_ids" => ["rejected_contact"],
                 "ignored_selected_contact_reason_counts" => %{
                   "approval_status_rejected" => 1
                 },
                 "approval_rule_matches" => [
                   %{"rule_id" => "severe_capacity_reduction_review"}
                 ],
                 "requirement_type" => "contact_schedule_change",
                 "required_authority" => "ground_network_authority",
                 "policy_bundle_id" => "ground_network_allocation_v1",
                 "rule_id" => "severe_capacity_reduction_review",
                 "escalation_level" => "ops_lead",
                 "escalation_queue" => "link_capacity",
                 "escalation_role" => "link_budget_analyst",
                 "sla_s" => 900,
                 "source_policy_decision" => %{
                   "policy_bundle_id" => "ground_network_allocation_v1"
                 },
                 "source_policy_escalation" => %{
                   "rule_id" => "severe_capacity_reduction_review",
                   "escalation_queue" => "link_capacity"
                 },
                 "source_link_capacity" => %{
                   "ground_station_id" => "equator_prime",
                   "selected_estimated_throughput_mb" => 40.0
                 },
                 "source_review_row" => %{
                   "review_type" => "link_capacity_review",
                   "ground_station_id" => "equator_prime",
                   "selected_estimated_throughput_mb" => 40.0,
                   "requirement_type" => "contact_schedule_change",
                   "ignored_contact_reason_counts" => %{"approval_status_rejected" => 1}
                 }
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        [
          row
          |> Map.put("selected_contact_count", 2)
          |> Map.put("ground_station_id", "stale_station")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].selected_contact_count" and
                 &1["message"] == "must equal length of selected_contact_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ground_station_id" and
                 &1["message"] == "must match source_link_capacity.ground_station_id")
           )

    mismatched_source_review_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("selected_contact_count", 2)
          |> Map.put("selected_contact_ids", ["selected_contact", "unexpected_contact"])
          |> Map.put("ground_station_id", "stale_station")
          |> Map.put("selected_estimated_throughput_mb", 41.0)
          |> Map.put("requirement_type", "stale_requirement")
          |> Map.put("ignored_contact_reason_counts", %{"approval_status_rejected" => 2})

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(mismatched_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.selected_contact_count" and
                 &1["message"] == "must match selected_contact_count on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.ground_station_id" and
                 &1["message"] == "must match ground_station_id on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.selected_estimated_throughput_mb" and
                 &1["message"] ==
                   "must match selected_estimated_throughput_mb on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.requirement_type" and
                 &1["message"] == "must match requirement_type on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.ignored_contact_reason_counts" and
                 &1["message"] == "must match ignored_contact_reason_counts on Cadence import row")
           )
  end

  test "builds contact suppression import rows with policy evidence" do
    report = %{
      "schema_contract" => "contact_filter_report.v1",
      "id" => "contact_filter:manifest_test",
      "model" => "thin_ground_network_availability_filter",
      "input_candidate_count" => 1,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "dl_reserved",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "direction" => "downlink",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "suppressed_reason" => "ground_station_reserved",
          "station_availability" => "reserved",
          "station_contention_status" => "reserved_overlap",
          "station_reservation_id" => "reservation_1",
          "station_reserved_by" => "network_partner",
          "station_reservation_status" => "confirmed",
          "station_reservation_match_status" => "overlap",
          "approval_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "activity_id" => "dl_reserved",
              "activity_type" => "downlink",
              "action" => "review_suppressed_contact",
              "requirement_type" => "contact_schedule_change",
              "reason" => "ground_station_reserved"
            }
          ],
          "approval_rule_matches" => [
            %{"rule_id" => "reserved_station_contact_review"}
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "ground_network_allocation_v1",
            "rule_matches" => [
              %{"rule_id" => "reserved_station_contact_review"}
            ],
            "escalations" => [
              %{"rule_id" => "unmatched_contact_rule", "escalation_queue" => "ignore_queue"},
              %{
                "rule_id" => "reserved_station_contact_review",
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
      ]
    }

    manifest = CadenceImport.from_contact_filter_report(report)

    assert %{
             "source_artifact_type" => "contact_filter_report.v1",
             "source_artifact_id" => "contact_filter:manifest_test",
             "row_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "import_action" => "review_contact_suppression",
                 "source_review_type" => "contact_suppression",
                 "subject_id" => "dl_reserved",
                 "ground_station_id" => "equator_prime",
                 "direction" => "downlink",
                 "requirement_type" => "contact_schedule_change",
                 "required_authority" => "contact_schedule_authority",
                 "policy_bundle_id" => "ground_network_allocation_v1",
                 "rule_id" => "reserved_station_contact_review",
                 "escalation_level" => "ops_lead",
                 "escalation_queue" => "ground_network",
                 "escalation_role" => "network_scheduler",
                 "sla_s" => 600,
                 "station_reservation_id" => "reservation_1",
                 "station_reservation_match_status" => "overlap",
                 "approval_rule_matches" => [
                   %{"rule_id" => "reserved_station_contact_review"}
                 ],
                 "source_policy_decision" => %{
                   "policy_bundle_id" => "ground_network_allocation_v1"
                 },
                 "source_policy_escalation" => %{
                   "rule_id" => "reserved_station_contact_review",
                   "escalation_queue" => "ground_network"
                 },
                 "source_contact_suppression" => %{
                   "id" => "dl_reserved",
                   "suppressed_reason" => "ground_station_reserved",
                   "station_availability" => "reserved",
                   "station_reservation_id" => "reservation_1",
                   "station_reservation_match_status" => "overlap"
                 },
                 "source_review_row" => %{"review_type" => "contact_suppression"}
               }
             ]
           } = manifest

    [row] = manifest["rows"]

    assert Map.take(row["source_review_row"], [
             "requirement_type",
             "required_authority",
             "policy_bundle_id",
             "rule_id",
             "escalation_queue"
           ]) == %{
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "reserved_station_contact_review",
             "escalation_queue" => "ground_network"
           }

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        [Map.put(row, "station_reservation_id", "stale_reservation")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].station_reservation_id" and
                 &1["message"] ==
                   "must match source_contact_suppression.station_reservation_id")
           )

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("requirement_type", "stale_requirement")
          |> Map.put("policy_bundle_id", "stale_policy")
          |> Map.put("escalation_queue", "stale_queue")

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.requirement_type" and
                 &1["message"] == "must match requirement_type on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.policy_bundle_id" and
                 &1["message"] == "must match policy_bundle_id on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.escalation_queue" and
                 &1["message"] == "must match escalation_queue on Cadence import row")
           )
  end

  test "builds resource suppression import rows with policy evidence" do
    report = %{
      "schema_contract" => "resource_filter_report.v1",
      "id" => "resource_filter:manifest_test",
      "model" => "resource_summary_availability_and_margin_filter",
      "input_candidate_count" => 1,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "obs_payload",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "sat_payload",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "suppressed_reason" => "payload_unavailable",
          "resource_trust_boundary_status" => "missing",
          "station_contention_status" => "reserved_overlap",
          "station_reservation_id" => "reservation_resource",
          "station_reserved_by" => "network_partner",
          "station_reservation_status" => "confirmed",
          "station_reservation_match_status" => "matched",
          "payload_available" => false,
          "approval_status" => "blocked_by_policy",
          "approval_requirements" => [
            %{
              "activity_id" => "obs_payload",
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
            "classification" => "blocked_by_policy",
            "policy_bundle_id" => "degraded_payload_guard_v1",
            "rule_matches" => [
              %{"rule_id" => "payload_unavailable_observation_block"}
            ],
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
            ],
            "approval_requirement_count" => 1,
            "risk_count" => 0
          }
        }
      ]
    }

    manifest = CadenceImport.from_resource_filter_report(report)

    assert %{
             "source_artifact_type" => "resource_filter_report.v1",
             "source_artifact_id" => "resource_filter:manifest_test",
             "row_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "import_action" => "review_resource_suppression",
                 "source_review_type" => "resource_suppression",
                 "subject_id" => "obs_payload",
                 "spacecraft_id" => "sat_payload",
                 "requirement_type" => "observation_reassignment",
                 "required_authority" => "payload_operations_authority",
                 "policy_bundle_id" => "degraded_payload_guard_v1",
                 "rule_id" => "payload_unavailable_observation_block",
                 "escalation_level" => "payload_lead",
                 "escalation_queue" => "payload_ops",
                 "escalation_role" => "payload_scheduler",
                 "sla_s" => 900,
                 "station_reservation_id" => "reservation_resource",
                 "station_reservation_match_status" => "matched",
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
                 "resource_trust_boundary_status" => "missing",
                 "payload_available" => false,
                 "source_resource_suppression" => %{
                   "id" => "obs_payload",
                   "suppressed_reason" => "payload_unavailable",
                   "resource_trust_boundary_status" => "missing",
                   "station_reservation_id" => "reservation_resource",
                   "station_reservation_match_status" => "matched",
                   "payload_available" => false
                 },
                 "source_review_row" => %{"review_type" => "resource_suppression"}
               }
             ]
           } = manifest

    [row] = manifest["rows"]

    assert Map.take(row["source_review_row"], [
             "requirement_type",
             "required_authority",
             "policy_bundle_id",
             "rule_id",
             "escalation_queue"
           ]) == %{
             "requirement_type" => "observation_reassignment",
             "required_authority" => "payload_operations_authority",
             "policy_bundle_id" => "degraded_payload_guard_v1",
             "rule_id" => "payload_unavailable_observation_block",
             "escalation_queue" => "payload_ops"
           }

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        [Map.put(row, "payload_available", true)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].payload_available" and
                 &1["message"] == "must match source_resource_suppression.payload_available")
           )

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("required_authority", "stale_authority")
          |> Map.put("policy_bundle_id", "stale_policy")
          |> Map.put("source_policy_decision", %{
            "policy_bundle_id" => "stale_policy"
          })

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.required_authority" and
                 &1["message"] == "must match required_authority on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.policy_bundle_id" and
                 &1["message"] == "must match policy_bundle_id on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_policy_decision" and
                 &1["message"] == "must match source_policy_decision on Cadence import row")
           )
  end

  test "builds maneuver import rows with policy evidence" do
    report =
      OrbitalDynamics.maneuver_review_report(
        [
          %{
            "id" => "trim_burn",
            "scenario_id" => "leo_1",
            "type" => "impulsive_burn",
            "epoch_s" => 120.0,
            "frame" => "eci_j2000",
            "delta_v_km_s" => [0.0, 0.01, 0.0],
            "delta_v_magnitude_km_s" => 0.01,
            "maneuver_model" => "impulsive_burns",
            "maneuver_success_factor" => 0.4,
            "maneuver_success_factor_source" => "realized_activity.completed_fraction"
          }
        ],
        approval_policy: %{policy_bundle_id: "maneuver_authority_v1"}
      )

    report =
      update_in(report, ["rows"], fn [row] ->
        policy_decision =
          row
          |> Map.get("policy_decision", %{})
          |> Map.put("escalations", [
            %{"rule_id" => "unmatched_maneuver_rule", "escalation_queue" => "ignore_queue"},
            %{
              "rule_id" => "maneuver_timing_authority_review",
              "escalation_level" => "flight_director",
              "escalation_queue" => "maneuver_authority",
              "escalation_role" => "flight_dynamics_lead",
              "required_authority" => "maneuver_authority",
              "sla_s" => 1200
            }
          ])

        [
          row
          |> Map.put("approval_rule_matches", [
            %{"rule_id" => "maneuver_timing_authority_review"}
          ])
          |> Map.put("policy_decision", policy_decision)
        ]
      end)

    manifest = CadenceImport.from_maneuver_review_report(report)

    assert %{
             "source_artifact_type" => "maneuver_review_report.v1",
             "row_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "import_action" => "review_maneuver",
                 "source_review_type" => "maneuver_review",
                 "maneuver_id" => "trim_burn",
                 "maneuver_type" => "impulsive_burn",
                 "delta_v_magnitude_km_s" => 0.01,
                 "maneuver_model" => "impulsive_burns",
                 "maneuver_success_factor" => 0.4,
                 "maneuver_success_factor_source" => "realized_activity.completed_fraction",
                 "source_policy_decision" => %{
                   "policy_bundle_id" => "maneuver_authority_v1"
                 },
                 "source_policy_escalation" => %{
                   "rule_id" => "maneuver_timing_authority_review",
                   "escalation_queue" => "maneuver_authority"
                 },
                 "escalation_level" => "flight_director",
                 "escalation_queue" => "maneuver_authority",
                 "escalation_role" => "flight_dynamics_lead",
                 "required_authority" => "maneuver_authority",
                 "sla_s" => 1200,
                 "source_maneuver_review" => %{
                   "maneuver_id" => "trim_burn",
                   "maneuver_success_factor" => 0.4,
                   "maneuver_success_factor_source" => "realized_activity.completed_fraction",
                   "source_recommendation" => %{
                     "id" => "trim_burn",
                     "type" => "impulsive_burn"
                   }
                 },
                 "source_review_row" => %{"review_type" => "maneuver_review"}
               }
             ]
           } = manifest

    [row] = manifest["rows"]
    assert row["delta_v_km_s"] == [0.0, 0.01, 0.0]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "maneuver import rows reject stale nested source review evidence" do
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

    manifest =
      report
      |> CadenceImport.from_maneuver_review_report()
      |> put_in(["rows", Access.at(0), "subject_id"], "trim_burn_stale")
      |> put_in(["rows", Access.at(0), "maneuver_id"], "trim_burn_stale")
      |> put_in(
        ["rows", Access.at(0), "source_maneuver_review", "maneuver_id"],
        "trim_burn_stale"
      )

    assert {:error, stale_source_review_report} = Schema.validate_artifact(manifest)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.maneuver_id" and
                 &1["message"] == "must match maneuver_id on Cadence import row")
           )
  end

  test "builds import manifest from standalone maneuver recommendation" do
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

    manifest = CadenceImport.from_maneuver_recommendation(recommendation)
    assert OrbitalDynamics.cadence_import_manifest(recommendation) == manifest

    assert %{
             "source_artifact_type" => "maneuver_recommendation.v1",
             "source_artifact_id" => "trim_burn",
             "row_count" => 1,
             "import_action_counts" => %{"review_maneuver" => 1},
             "rows" => [
               %{
                 "import_action" => "review_maneuver",
                 "source_review_type" => "maneuver_review",
                 "source_review_action" => "review_maneuver_recommendation",
                 "maneuver_id" => "trim_burn",
                 "scenario_id" => "ops_checkout",
                 "maneuver_type" => "impulsive_burn",
                 "delta_v_magnitude_km_s" => 0.01,
                 "source_recommendation" => %{
                   "schema_contract" => "maneuver_recommendation.v1"
                 },
                 "source_maneuver_review" => %{"maneuver_id" => "trim_burn"}
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds import manifest from standalone maneuver execution delta" do
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

    manifest = CadenceImport.from_maneuver_execution_delta(delta)
    assert OrbitalDynamics.cadence_import_manifest(delta) == manifest

    assert %{
             "source_artifact_type" => "maneuver_execution_delta.v1",
             "source_artifact_id" => "trim_burn_1",
             "row_count" => 1,
             "import_action_counts" => %{"review_realized_feedback" => 1},
             "rows" => [
               %{
                 "import_action" => "review_realized_feedback",
                 "source_review_type" => "realized_feedback",
                 "source_review_action" => "review_unplanned_realization",
                 "activity_id" => "trim_burn_1",
                 "feedback_status" => "realized_only",
                 "realized_status" => "completed",
                 "realized_type" => "impulsive_burn",
                 "realized_trust_boundary" => "operator_supplied",
                 "realized_provenance" => %{"trust_boundary" => "operator_supplied"},
                 "source_feedback" => %{
                   "realized_activity" => %{
                     "schema_contract" => "maneuver_execution_delta.v1"
                   }
                 }
               }
             ]
           } = manifest

    [row] = manifest["rows"]

    assert get_in(row, ["source_feedback", "realized_activity", "delta_v_km_s"]) == [
             0.0,
             0.01,
             0.0
           ]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds import rows from standalone provider counteroffer reports" do
    report = provider_counteroffer_report()

    manifest = CadenceImport.from_provider_counteroffer_report(report)

    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "source_artifact_id" => "cadence_supported_source_fixture",
             "row_count" => 1,
             "review_required_count" => 1,
             "rows" => [row]
           } = manifest

    assert %{
             "import_action" => "review_provider_counteroffer",
             "source_review_type" => "provider_counteroffer_review",
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
             },
             "source_review_row" => %{
               "review_type" => "provider_counteroffer_review",
               "provider_counteroffer_status" => "proposed",
               "provider_counteroffer_lock_deadline_s" => 150.0,
               "provider_counteroffer_start_delta_s" => 30.0,
               "provider_counteroffer_end_delta_s" => 40.0,
               "provider_counteroffer_duration_delta_s" => 10.0
             }
           } = row

    assert Map.take(row["source_review_row"], [
             "subject_id",
             "approval_status",
             "cadence_import_status"
           ]) == %{
             "subject_id" => "provider_offer_1",
             "approval_status" => "operator_review_required",
             "cadence_import_status" => "present"
           }

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn [row] ->
        [put_in(row, ["source_provider_counteroffer", "id"], "provider source with spaces")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_provider_counteroffer.id")
           )

    invalid_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        [
          row
          |> Map.put("provider_counteroffer_status", "accepted")
          |> Map.put("provider_counteroffer_lock_deadline_s", 151.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

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

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn [row] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("provider_counteroffer_lock_deadline_s", 151.0)
          |> Map.put("subject_id", "stale_provider_offer")
          |> Map.put("cadence_import_status", "missing")

        [Map.put(row, "source_review_row", source_review_row)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.provider_counteroffer_lock_deadline_s" and
                 &1["message"] ==
                   "must match provider_counteroffer_lock_deadline_s on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.subject_id" and
                 &1["message"] == "must match subject_id on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.cadence_import_status" and
                 &1["message"] == "must match cadence_import_status on Cadence import row")
           )
  end

  test "builds import rows from standalone contact allocation reports" do
    report =
      "study_results/contact_allocation_report_v1.json"
      |> File.read!()
      |> :json.decode()

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source_artifact_id" => "fixture.contact_allocation",
             "row_count" => 5,
             "review_required_count" => 5,
             "calendar_entry_trust_boundary_status_counts" => %{"missing" => 2},
             "rows" => [first | _rest]
           } = manifest

    assert %{
             "import_action" => "review_contact_allocation",
             "source_review_type" => "contact_allocation_review",
             "contact_id" => "dl_1",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_contention_resolution",
             "contention_group_id" => "station:equator_prime:contention:1",
             "source_contact_allocation" => %{
               "contact_id" => "dl_1",
               "allocation_status" => "allocated",
               "allocation_reason" => "selected_by_contention_resolution"
             },
             "source_contention_recommendation" => %{
               "selected_contact_id" => "dl_1"
             }
           } = first

    assert %{
             "contact_id" => "dl_3",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_reserved",
             "suppressed_reason" => "ground_station_reserved",
             "station_calendar_entry_id" => "declared:equator_prime:240.000000:300.000000",
             "station_calendar_overlap_count" => 1,
             "station_calendar_overlap_entry_ids" => [
               "declared:equator_prime:240.000000:300.000000"
             ],
             "station_calendar_reservation_ids" => ["reservation_1"],
             "source_contact_allocation" => %{
               "contact_id" => "dl_3",
               "allocation_status" => "blocked",
               "station_calendar_entry_id" => "declared:equator_prime:240.000000:300.000000"
             },
             "source_contact_suppression" => %{
               "suppressed_reason" => "ground_station_reserved",
               "station_calendar_overlap_count" => 1
             }
           } = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_3"))

    assert %{
             "contact_id" => "cmd_unavailable",
             "activity_type" => "command",
             "direction" => "command",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable",
             "approval_status" => "blocked_by_policy",
             "requirement_type" => "command_review",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "unavailable_station_contact_block",
             "escalation_queue" => "ground_network",
             "source_contact_allocation" => %{
               "source_station_calendar_contact" => %{
                 "id" => "cmd_unavailable",
                 "station_availability" => "unavailable"
               }
             }
           } =
             cmd_unavailable_row =
             Enum.find(manifest["rows"], &(&1["contact_id"] == "cmd_unavailable"))

    assert Map.take(cmd_unavailable_row["source_review_row"], [
             "requirement_type",
             "required_authority",
             "policy_bundle_id",
             "rule_id",
             "escalation_queue"
           ]) == %{
             "requirement_type" => "command_review",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "unavailable_station_contact_block",
             "escalation_queue" => "ground_network"
           }

    assert %{
             "contact_id" => "dl_resource_blocked",
             "allocation_status" => "blocked",
             "allocation_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "source_resource_suppression" => %{
               "suppressed_reason" => "antenna_unavailable"
             },
             "source_contact_allocation" => %{
               "source_resource_suppression" => %{
                 "resource_trust_boundary_status" => "declared"
               }
             }
           } = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_resource_blocked"))

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{
            "source_review_type" => "contact_allocation_review",
            "source_contact_allocation" => %{}
          } = row ->
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
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{
            "source_review_type" => "contact_allocation_review",
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

    valid_duplicate_manifest =
      update_in(manifest, ["rows"], fn [row | rest] ->
        duplicate_fields = %{
          "allocation_reason" => "duplicate_contact_id",
          "duplicate_contact_candidate_count" => 1,
          "duplicate_contact_candidate_ids" => [row["contact_id"]],
          "resolution_priority_override_count" => 1,
          "resolution_priority_override_contact_ids" => [row["contact_id"]]
        }

        source_contact_allocation = Map.merge(row["source_contact_allocation"], duplicate_fields)

        source_review_row =
          row["source_review_row"]
          |> Map.merge(duplicate_fields)
          |> Map.put("source_contact_allocation", source_contact_allocation)

        [
          row
          |> Map.merge(duplicate_fields)
          |> Map.put("source_review_row", source_review_row)
          |> Map.put("source_contact_allocation", source_contact_allocation)
          | rest
        ]
      end)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(valid_duplicate_manifest)

    invalid_manifest =
      update_in(valid_duplicate_manifest, ["rows"], fn [row | rest] ->
        [
          Map.merge(row, %{
            "contact_id" => "stale_contact",
            "duplicate_contact_candidate_count" => 2,
            "resolution_priority_override_count" => 2
          })
          | rest
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

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
             &(&1["path"] == "$.rows[0].contact_id" and
                 &1["message"] == "must match source_contact_allocation.contact_id")
           )

    mismatched_source_review_manifest =
      update_in(valid_duplicate_manifest, ["rows"], fn [row | rest] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("duplicate_contact_candidate_count", 2)
          |> Map.put("duplicate_contact_candidate_ids", [
            row["contact_id"],
            "unexpected_duplicate_contact"
          ])

        [Map.put(row, "source_review_row", source_review_row) | rest]
      end)

    assert {:error, report} = Schema.validate_artifact(mismatched_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.duplicate_contact_candidate_count" and
                 &1["message"] ==
                   "must match duplicate_contact_candidate_count on Cadence import row")
           )

    mismatched_source_review_handoff =
      update_in(valid_duplicate_manifest, ["rows"], fn [row | rest] ->
        source_review_row =
          row["source_review_row"]
          |> Map.put("ground_station_id", "stale_station")

        [Map.put(row, "source_review_row", source_review_row) | rest]
      end)

    assert {:error, report} = Schema.validate_artifact(mismatched_source_review_handoff)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.ground_station_id" and
                 &1["message"] == "must match ground_station_id on Cadence import row")
           )

    mismatched_source_review_context =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"contact_id" => "cmd_unavailable"} = row ->
            source_review_row =
              row["source_review_row"]
              |> Map.put("requirement_type", "stale_requirement")
              |> Map.put("policy_bundle_id", "stale_policy")
              |> Map.put("escalation_queue", "stale_queue")

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(mismatched_source_review_context)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.requirement_type$/ and
                 &1["message"] == "must match requirement_type on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.policy_bundle_id$/ and
                 &1["message"] == "must match policy_bundle_id on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.escalation_queue$/ and
                 &1["message"] == "must match escalation_queue on Cadence import row")
           )
  end

  test "builds import rows from standalone reduced-capacity contact allocation pack fixture" do
    report =
      "study_results/contact_allocation_capacity_pack_report_v1.json"
      |> File.read!()
      |> :json.decode()
      |> put_in(
        ["reduced_capacity_pack_groups", Access.at(0), "default_required_capacity_fraction"],
        0.25
      )

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source_artifact_id" => "fixture.contact_allocation.capacity_pack",
             "row_count" => 4,
             "review_required_count" => 4,
             "calendar_entry_trust_boundary_status_counts" => %{"declared" => 1}
           } = manifest

    assert %{
             "import_action" => "review_contact_allocation_capacity_pack",
             "source_review_type" => "contact_allocation_capacity_pack_review",
             "contention_group_id" => "station:equator_prime:contention:1",
             "ground_station_id" => "equator_prime",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "default_required_capacity_fraction" => 0.25,
             "selected_contact_ids" => ["dl_capacity_primary"],
             "capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "deferred_contact_ids" => ["dl_capacity_overflow"],
             "capacity_pack_contact_ids_by_direction" => %{
               "downlink" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             },
             "capacity_pack_selected_contact_ids_by_direction" => %{
               "downlink" => ["dl_capacity_primary", "dl_capacity_secondary"]
             },
             "capacity_pack_deferred_contact_ids_by_direction" => %{
               "downlink" => ["dl_capacity_overflow"]
             },
             "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.75},
             "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25
             },
             "source_contact_allocation_capacity_pack" => %{
               "contention_group_id" => "station:equator_prime:contention:1"
             },
             "source_review_row" => %{
               "review_type" => "contact_allocation_capacity_pack_review",
               "subject_id" => "station:equator_prime:contention:1",
               "required_operator_action" => "review_contact_allocation_capacity_pack",
               "approval_status" => "operator_review_required",
               "contention_group_id" => "station:equator_prime:contention:1",
               "default_required_capacity_fraction" => 0.25
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["source_review_type"] == "contact_allocation_capacity_pack_review")
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "contact_allocation_capacity_pack_review"} = row ->
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

    invalid_manifest =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "contact_allocation_capacity_pack_review"} = row ->
            Map.put(row, "capacity_fraction", 0.4)

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.capacity_fraction$/ and
                 &1["message"] ==
                   "must match source_contact_allocation_capacity_pack.capacity_fraction")
           )

    invalid_direction_map_manifest =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "contact_allocation_capacity_pack_review"} = row ->
            Map.put(row, "capacity_pack_selected_contact_ids_by_direction", %{
              "downlink" => ["dl_capacity_primary"]
            })

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_direction_map_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.capacity_pack_selected_contact_ids_by_direction$/ and
                 &1["message"] ==
                   "must match source_contact_allocation_capacity_pack.capacity_pack_selected_contact_ids_by_direction")
           )

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_review_type" => "contact_allocation_capacity_pack_review"} = row ->
            source_review_row =
              row["source_review_row"]
              |> Map.put("default_required_capacity_fraction", 0.3)
              |> Map.put("subject_id", "stale_contention_group")
              |> Map.put("required_operator_action", "stale_action")

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_review_row\.default_required_capacity_fraction$/ and
                 &1["message"] ==
                   "must match default_required_capacity_fraction on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.subject_id$/ and
                 &1["message"] == "must match subject_id on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_review_row\.required_operator_action$/ and
                 &1["message"] == "must match required_operator_action on Cadence import row")
           )
  end

  test "builds import rows from standalone contact allocation summary artifacts" do
    capacity_pack_summary =
      "study_results/contact_allocation_capacity_pack_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    capacity_pack_manifest =
      CadenceImport.from_contact_allocation_capacity_pack_summary(capacity_pack_summary)

    assert OrbitalDynamics.cadence_import_manifest(capacity_pack_summary) ==
             capacity_pack_manifest

    assert %{
             "source_artifact_type" => "contact_allocation_capacity_pack_summary.v1",
             "source_artifact_id" => "validation.contact_allocation_capacity_pack_summary",
             "row_count" => 4,
             "review_required_count" => 4,
             "reduced_capacity_pack_group_count" => 1,
             "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1}
           } = capacity_pack_manifest

    assert %{
             "import_action" => "review_contact_allocation_capacity_pack",
             "source_review_type" => "contact_allocation_capacity_pack_review",
             "contention_group_id" => "capacity_pack:equator_prime:downlink:100_160",
             "capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "capacity_pack_contact_ids_by_direction" => %{
               "downlink" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             },
             "capacity_pack_selected_contact_ids_by_direction" => %{
               "downlink" => ["dl_capacity_primary", "dl_capacity_secondary"]
             },
             "capacity_pack_deferred_contact_ids_by_direction" => %{
               "downlink" => ["dl_capacity_overflow"]
             },
             "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.75},
             "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25
             },
             "source_contact_allocation_capacity_pack" => %{
               "source_contact_allocation_summary" => %{
                 "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
                 "model" => "artifact_only_contact_allocation_capacity_pack_summary"
               }
             },
             "source_review_row" => %{
               "source_contact_allocation_capacity_pack" => %{
                 "source_summary_schema_contract" => "contact_allocation_capacity_pack_summary.v1"
               }
             }
           } =
             Enum.find(
               capacity_pack_manifest["rows"],
               &(&1["source_review_type"] == "contact_allocation_capacity_pack_review")
             )

    reservation_conflict_summary =
      "study_results/contact_allocation_reservation_conflict_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    reservation_conflict_manifest =
      CadenceImport.from_contact_allocation_reservation_conflict_summary(
        reservation_conflict_summary
      )

    assert OrbitalDynamics.cadence_import_manifest(reservation_conflict_summary) ==
             reservation_conflict_manifest

    assert %{
             "source_artifact_type" => "contact_allocation_reservation_conflict_summary.v1",
             "source_artifact_id" => "validation.contact_allocation_reservation_conflict_summary",
             "row_count" => 1,
             "review_required_count" => 1,
             "reservation_conflict_contact_ids_by_direction" => %{
               "downlink" => ["dl_reserved_intruder"]
             }
           } = reservation_conflict_manifest

    assert [
             %{
               "import_action" => "review_contact_allocation",
               "source_review_type" => "contact_allocation_review",
               "contact_id" => "dl_reserved_intruder",
               "station_reservation_id" => "reservation_1",
               "source_contact_allocation" => %{
                 "source_summary_schema_contract" =>
                   "contact_allocation_reservation_conflict_summary.v1",
                 "source_contact_allocation_summary" => %{
                   "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
                   "model" => "artifact_only_contact_allocation_reservation_conflict_summary"
                 }
               },
               "source_review_row" => %{
                 "source_contact_allocation" => %{
                   "source_summary_schema_contract" =>
                     "contact_allocation_reservation_conflict_summary.v1"
                 }
               }
             }
           ] = reservation_conflict_manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(capacity_pack_manifest)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(reservation_conflict_manifest)
  end

  test "lifts embedded contact-allocation summary fields from wrapper manifests" do
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
        "reservation_conflict_contact_ids_by_direction" => %{
          "downlink" => ["dl_campaign_conflict"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"gs_campaign" => ["dl_campaign_conflict"]}
        },
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "antenna" => ["dl_campaign_resource"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_campaign" => ["dl_campaign_resource"]
        },
        "station_pressure_contact_count" => 1,
        "station_pressure_contact_ids" => ["dl_campaign_station"],
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
        "station_pressure_contact_ids_by_direction" => %{
          "downlink" => ["dl_campaign_station"]
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
        "capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["dl_campaign_pack"]
        },
        "capacity_pack_selected_contact_ids_by_direction" => %{
          "downlink" => ["dl_campaign_pack"]
        },
        "capacity_pack_deferred_contact_ids_by_direction" => %{},
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
        "reservation_conflict_contact_ids_by_direction" => %{
          "downlink" => ["dl_refresh_conflict_a", "dl_refresh_conflict_b"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{
            "gs_refresh" => ["dl_refresh_conflict_a", "dl_refresh_conflict_b"]
          }
        },
        "resource_blocking_dimension_counts" => %{"thermal" => 2},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "thermal" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_refresh" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
        },
        "station_pressure_contact_count" => 2,
        "station_pressure_contact_ids" => ["dl_refresh_station_a", "dl_refresh_station_b"],
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
        "station_pressure_contact_ids_by_direction" => %{
          "downlink" => ["dl_refresh_station_a", "dl_refresh_station_b"]
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
        "capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["dl_refresh_pack", "dl_refresh_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_direction" => %{
          "downlink" => ["dl_refresh_pack"]
        },
        "capacity_pack_deferred_contact_ids_by_direction" => %{
          "downlink" => ["dl_refresh_deferred"]
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
        "reservation_conflict_contact_ids_by_direction" => %{
          "downlink" => ["dl_source_conflict"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"gs_source" => ["dl_source_conflict"]}
        },
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "antenna" => ["dl_source_resource"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_source" => ["dl_source_resource"]
        },
        "station_pressure_contact_count" => 1,
        "station_pressure_contact_ids" => ["dl_source_station", "dl_source_station"],
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
        "station_pressure_contact_ids_by_direction" => %{
          "downlink" => ["dl_source_station"]
        },
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
        "capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["dl_source_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_direction" => %{},
        "capacity_pack_deferred_contact_ids_by_direction" => %{
          "downlink" => ["dl_source_deferred"]
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
        "reservation_conflict_contact_ids_by_direction" => %{
          "downlink" => ["dl_result_conflict_a", "dl_result_conflict_b"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"gs_result" => ["dl_result_conflict_a", "dl_result_conflict_b"]}
        },
        "resource_blocking_dimension_counts" => %{"activity_type" => 2},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "activity_type" => ["dl_result_resource_a", "dl_result_resource_b"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_result" => ["dl_result_resource_a", "dl_result_resource_b"]
        },
        "station_pressure_contact_count" => 2,
        "station_pressure_contact_ids" => ["dl_result_station_b", "dl_result_station_a"],
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
        "station_pressure_contact_ids_by_direction" => %{
          "downlink" => ["dl_result_station_a", "dl_result_station_b"]
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
        "capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["dl_result_pack", "dl_result_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_direction" => %{
          "downlink" => ["dl_result_pack"]
        },
        "capacity_pack_deferred_contact_ids_by_direction" => %{
          "downlink" => ["dl_result_deferred"]
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
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:calendar_counts",
        "contact_allocation_report" => campaign_summary
      })

    refresh =
      CadenceImport.from_candidate_refresh_artifact(%{
        "refresh_id" => "refresh:calendar_counts",
        "contact_allocation_report" => refresh_summary
      })

    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:calendar_counts"},
        "source_plan_id" => "plan:calendar_counts",
        "source_contact_allocation_report" => source_summary,
        "contact_allocation_report" => result_summary
      })

    strategy =
      CadenceImport.from_strategy_artifact(%{
        "strategy_metadata" => %{"strategy_id" => "strategy:calendar_counts"},
        "branches" => [
          %{
            "branch_id" => "branch_calendar_counts",
            "repair_result" => %{
              "source_contact_allocation_report" => source_summary,
              "contact_allocation_report" => result_summary
            }
          }
        ],
        "branch_comparison_report" => %{"rows" => []},
        "recommendation" => %{}
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

    assert campaign["reservation_conflict_contact_ids_by_direction"] == %{
             "downlink" => ["dl_campaign_conflict"]
           }

    assert campaign["reservation_conflict_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{"gs_campaign" => ["dl_campaign_conflict"]}
           }

    assert campaign["resource_blocking_dimension_counts"] == %{"antenna" => 1}

    assert campaign["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "antenna" => ["dl_campaign_resource"]
           }

    assert campaign["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_campaign" => ["dl_campaign_resource"]
           }

    assert campaign["station_pressure_contact_count"] == 1
    assert campaign["station_pressure_contact_ids"] == ["dl_campaign_station"]
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

    assert campaign["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => ["dl_campaign_station"]
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

    assert campaign["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["dl_campaign_pack"]
           }

    assert campaign["capacity_pack_selected_contact_ids_by_direction"] == %{
             "downlink" => ["dl_campaign_pack"]
           }

    refute Map.has_key?(campaign, "capacity_pack_deferred_contact_ids_by_direction")

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

    assert refresh["reservation_conflict_contact_ids_by_direction"] == %{
             "downlink" => ["dl_refresh_conflict_a", "dl_refresh_conflict_b"]
           }

    assert refresh["reservation_conflict_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{
               "gs_refresh" => ["dl_refresh_conflict_a", "dl_refresh_conflict_b"]
             }
           }

    assert refresh["resource_blocking_dimension_counts"] == %{"thermal" => 2}

    assert refresh["resource_blocked_contact_ids_by_blocking_dimension"] == %{
             "thermal" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
           }

    assert refresh["resource_blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_refresh" => ["dl_refresh_resource_a", "dl_refresh_resource_b"]
           }

    assert refresh["station_pressure_contact_count"] == 2

    assert refresh["station_pressure_contact_ids"] == [
             "dl_refresh_station_a",
             "dl_refresh_station_b"
           ]

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

    assert refresh["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => ["dl_refresh_station_a", "dl_refresh_station_b"]
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

    assert refresh["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["dl_refresh_pack", "dl_refresh_deferred"]
           }

    assert refresh["capacity_pack_selected_contact_ids_by_direction"] == %{
             "downlink" => ["dl_refresh_pack"]
           }

    assert refresh["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["dl_refresh_deferred"]
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

    assert repair["reservation_conflict_contact_ids_by_direction"] == %{
             "downlink" => [
               "dl_result_conflict_a",
               "dl_result_conflict_b",
               "dl_source_conflict"
             ]
           }

    assert repair["reservation_conflict_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{
               "gs_result" => ["dl_result_conflict_a", "dl_result_conflict_b"],
               "gs_source" => ["dl_source_conflict"]
             }
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

    assert repair["station_pressure_contact_ids"] == [
             "dl_result_station_a",
             "dl_result_station_b",
             "dl_source_station"
           ]

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

    assert repair["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => [
               "dl_result_station_a",
               "dl_result_station_b",
               "dl_source_station"
             ]
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

    assert repair["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["dl_result_deferred", "dl_result_pack", "dl_source_deferred"]
           }

    assert repair["capacity_pack_selected_contact_ids_by_direction"] == %{
             "downlink" => ["dl_result_pack"]
           }

    assert repair["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["dl_result_deferred", "dl_source_deferred"]
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
             "pack_result_a",
             "pack_result_b",
             "pack_source"
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

    assert strategy["reservation_conflict_contact_ids_by_direction"] == %{
             "downlink" => [
               "dl_result_conflict_a",
               "dl_result_conflict_b",
               "dl_source_conflict"
             ]
           }

    assert strategy["reservation_conflict_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{
               "gs_result" => ["dl_result_conflict_a", "dl_result_conflict_b"],
               "gs_source" => ["dl_source_conflict"]
             }
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

    assert strategy["station_pressure_contact_ids"] == [
             "dl_result_station_a",
             "dl_result_station_b",
             "dl_source_station"
           ]

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

    assert strategy["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => [
               "dl_result_station_a",
               "dl_result_station_b",
               "dl_source_station"
             ]
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

    assert strategy["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["dl_result_deferred", "dl_result_pack", "dl_source_deferred"]
           }

    assert strategy["capacity_pack_selected_contact_ids_by_direction"] ==
             %{"downlink" => ["dl_result_pack"]}

    assert strategy["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["dl_result_deferred", "dl_source_deferred"]
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
             "pack_result_a",
             "pack_result_b",
             "pack_source"
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

    for manifest <- [campaign, refresh, repair, strategy] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "correlates station-pressure identity across overlapping review summaries" do
    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:station_pressure_overlap"},
        "source_plan_id" => "plan:station_pressure_overlap",
        "source_contact_allocation_report" => %{
          "station_pressure_contact_count" => 2,
          "station_pressure_contact_ids" => ["contact_source", "contact_shared"],
          "station_pressure_contact_counts_by_ground_station_id" => %{"gs_shared" => 2},
          "station_pressure_contact_ids_by_ground_station_id" => %{
            "gs_shared" => ["contact_source", "contact_shared"]
          },
          "station_pressure_contact_counts_by_availability" => %{"reserved" => 2},
          "station_pressure_contact_ids_by_availability" => %{
            "reserved" => ["contact_source", "contact_shared"]
          },
          "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 2},
          "station_pressure_contact_ids_by_precedence_availability" => %{
            "reserved" => ["contact_source", "contact_shared"]
          },
          "station_pressure_contact_counts_by_precedence_rank" => %{"1" => 2},
          "station_pressure_contact_ids_by_precedence_rank" => %{
            "1" => ["contact_source", "contact_shared"]
          },
          "station_pressure_contact_counts_by_status" => %{"reservation_hold" => 2},
          "station_pressure_contact_ids_by_status" => %{
            "reservation_hold" => ["contact_source", "contact_shared"]
          },
          "station_pressure_contact_ids_by_direction" => %{
            "downlink" => ["contact_source", "contact_shared"]
          },
          "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
            "downlink" => %{"gs_shared" => ["contact_source", "contact_shared"]}
          }
        },
        "contact_allocation_report" => %{
          "station_pressure_contact_count" => 2,
          "station_pressure_contact_ids" => ["contact_shared", "contact_result"],
          "station_pressure_contact_counts_by_ground_station_id" => %{"gs_shared" => 2},
          "station_pressure_contact_ids_by_ground_station_id" => %{
            "gs_shared" => ["contact_shared", "contact_result"]
          },
          "station_pressure_contact_counts_by_availability" => %{"reserved" => 2},
          "station_pressure_contact_ids_by_availability" => %{
            "reserved" => ["contact_shared", "contact_result"]
          },
          "station_pressure_contact_counts_by_precedence_availability" => %{"reserved" => 2},
          "station_pressure_contact_ids_by_precedence_availability" => %{
            "reserved" => ["contact_shared", "contact_result"]
          },
          "station_pressure_contact_counts_by_precedence_rank" => %{"1" => 2},
          "station_pressure_contact_ids_by_precedence_rank" => %{
            "1" => ["contact_shared", "contact_result"]
          },
          "station_pressure_contact_counts_by_status" => %{"reservation_hold" => 2},
          "station_pressure_contact_ids_by_status" => %{
            "reservation_hold" => ["contact_shared", "contact_result"]
          },
          "station_pressure_contact_ids_by_direction" => %{
            "downlink" => ["contact_shared", "contact_result"]
          },
          "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
            "downlink" => %{"gs_shared" => ["contact_shared", "contact_result"]}
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:station_pressure_empty",
        "contact_allocation_report" => %{
          "station_pressure_contact_count" => 9,
          "station_pressure_contact_ids" => [],
          "station_pressure_contact_counts_by_ground_station_id" => %{"gs_empty" => 9},
          "station_pressure_contact_ids_by_ground_station_id" => %{"gs_empty" => []},
          "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
            "downlink" => %{"gs_empty" => []}
          }
        }
      })

    routed_identity =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:station_pressure_routed_identity",
        "contact_allocation_report" => %{
          "station_pressure_contact_count" => 99,
          "station_pressure_review_contact_count" => 1,
          "station_pressure_review_contact_ids" => ["contact_review"],
          "station_pressure_contact_counts_by_ground_station_id" => %{"gs_route" => 1},
          "station_pressure_contact_ids_by_ground_station_id" => %{
            "gs_route" => ["contact_group"]
          },
          "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
            "downlink" => %{"gs_route" => ["contact_nested"]}
          }
        }
      })

    scalar_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:station_pressure_scalar",
        "contact_allocation_report" => %{
          "station_pressure_contact_count" => 2,
          "station_pressure_contact_counts_by_ground_station_id" => %{"gs_scalar" => 2}
        }
      })

    assert repair["station_pressure_contact_count"] == 3

    assert repair["station_pressure_contact_ids"] == [
             "contact_result",
             "contact_shared",
             "contact_source"
           ]

    expected_group_ids = ["contact_result", "contact_shared", "contact_source"]

    for {count_field, id_field, key} <- [
          {"station_pressure_contact_counts_by_ground_station_id",
           "station_pressure_contact_ids_by_ground_station_id", "gs_shared"},
          {"station_pressure_contact_counts_by_availability",
           "station_pressure_contact_ids_by_availability", "reserved"},
          {"station_pressure_contact_counts_by_precedence_availability",
           "station_pressure_contact_ids_by_precedence_availability", "reserved"},
          {"station_pressure_contact_counts_by_precedence_rank",
           "station_pressure_contact_ids_by_precedence_rank", "1"},
          {"station_pressure_contact_counts_by_status", "station_pressure_contact_ids_by_status",
           "reservation_hold"}
        ] do
      assert repair[count_field] == %{key => 3}
      assert repair[id_field] == %{key => expected_group_ids}
    end

    assert repair["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => expected_group_ids
           }

    assert repair["station_pressure_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{"gs_shared" => expected_group_ids}
           }

    assert explicit_empty["station_pressure_contact_count"] == 0
    assert explicit_empty["station_pressure_contact_ids"] == []

    assert explicit_empty["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_empty" => 0
           }

    assert explicit_empty["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_empty" => []
           }

    assert explicit_empty["station_pressure_contact_ids_by_direction"] == %{"downlink" => []}

    assert explicit_empty["station_pressure_contact_ids_by_direction_and_ground_station_id"] == %{
             "downlink" => %{"gs_empty" => []}
           }

    assert routed_identity["station_pressure_contact_count"] == 3

    assert routed_identity["station_pressure_contact_ids"] == [
             "contact_group",
             "contact_nested",
             "contact_review"
           ]

    assert routed_identity["station_pressure_review_contact_count"] == 1
    assert routed_identity["station_pressure_review_contact_ids"] == ["contact_review"]

    assert routed_identity["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_route" => 1
           }

    assert routed_identity["station_pressure_contact_ids_by_ground_station_id"] == %{
             "gs_route" => ["contact_group"]
           }

    assert routed_identity["station_pressure_contact_ids_by_direction"] == %{
             "downlink" => ["contact_nested"]
           }

    assert routed_identity[
             "station_pressure_contact_ids_by_direction_and_ground_station_id"
           ] == %{
             "downlink" => %{"gs_route" => ["contact_nested"]}
           }

    assert scalar_only["station_pressure_contact_count"] == 2

    assert scalar_only["station_pressure_contact_counts_by_ground_station_id"] == %{
             "gs_scalar" => 2
           }

    refute Map.has_key?(scalar_only, "station_pressure_contact_ids")
    refute Map.has_key?(scalar_only, "station_pressure_contact_ids_by_ground_station_id")

    for manifest <- [repair, explicit_empty, routed_identity, scalar_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "correlates station-pressure review identity across overlapping review summaries" do
    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:station_pressure_review_overlap"},
        "source_plan_id" => "plan:station_pressure_review_overlap",
        "source_contact_allocation_report" => %{
          "station_pressure_review_contact_count" => 2,
          "station_pressure_review_contact_ids" => ["contact_source", "contact_shared"]
        },
        "contact_allocation_report" => %{
          "station_pressure_review_contact_count" => 2,
          "station_pressure_review_contact_ids" => ["contact_shared", "contact_result"]
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:station_pressure_review_empty",
        "contact_allocation_report" => %{
          "station_pressure_review_contact_count" => 9,
          "station_pressure_review_contact_ids" => []
        }
      })

    scalar_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:station_pressure_review_scalar",
        "contact_allocation_report" => %{
          "station_pressure_review_contact_count" => 2
        }
      })

    expected_review_ids = ["contact_result", "contact_shared", "contact_source"]

    assert repair["station_pressure_review_contact_count"] == 3
    assert repair["station_pressure_review_contact_ids"] == expected_review_ids
    assert repair["station_pressure_contact_count"] == 3
    assert repair["station_pressure_contact_ids"] == expected_review_ids

    assert explicit_empty["station_pressure_review_contact_count"] == 0
    assert explicit_empty["station_pressure_review_contact_ids"] == []
    assert explicit_empty["station_pressure_contact_count"] == 0
    assert explicit_empty["station_pressure_contact_ids"] == []

    assert scalar_only["station_pressure_review_contact_count"] == 2
    refute Map.has_key?(scalar_only, "station_pressure_review_contact_ids")
    refute Map.has_key?(scalar_only, "station_pressure_contact_count")
    refute Map.has_key?(scalar_only, "station_pressure_contact_ids")

    for manifest <- [repair, explicit_empty, scalar_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "correlates provider-reservation review identity across routed summaries" do
    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:provider_review_overlap"},
        "source_plan_id" => "plan:provider_review_overlap",
        "source_contact_allocation_report" => %{
          "provider_reservation_review_contact_count" => 2,
          "provider_reservation_review_contact_ids" => ["contact_source", "contact_shared"],
          "provider_reservation_review_contact_ids_by_ground_station_id" => %{
            "gs_a" => ["contact_station"]
          },
          "provider_reservation_review_contact_ids_by_direction" => %{
            "downlink" => ["contact_direction"]
          }
        },
        "contact_allocation_report" => %{
          "provider_reservation_review_contact_count" => 2,
          "provider_reservation_review_contact_ids" => ["contact_shared", "contact_result"],
          "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" => %{
            "downlink" => %{"gs_b" => ["contact_nested"]}
          },
          "provider_reservation_review_contact_ids_by_match_status" => %{
            "overlap" => ["contact_match"]
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:provider_review_empty",
        "contact_allocation_report" => %{
          "provider_reservation_review_contact_count" => 9,
          "provider_reservation_review_contact_ids_by_ground_station_id" => %{
            "gs_empty" => []
          }
        }
      })

    scalar_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:provider_review_scalar",
        "contact_allocation_report" => %{
          "provider_reservation_review_contact_count" => 2
        }
      })

    expected_review_ids = [
      "contact_direction",
      "contact_match",
      "contact_nested",
      "contact_result",
      "contact_shared",
      "contact_source",
      "contact_station"
    ]

    assert repair["provider_reservation_review_contact_count"] == 7
    assert repair["provider_reservation_review_contact_ids"] == expected_review_ids

    assert repair["provider_reservation_review_contact_ids_by_ground_station_id"] == %{
             "gs_a" => ["contact_station"]
           }

    assert repair["provider_reservation_review_contact_ids_by_direction"] == %{
             "downlink" => ["contact_direction"]
           }

    assert repair[
             "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
           ] == %{"downlink" => %{"gs_b" => ["contact_nested"]}}

    assert repair["provider_reservation_review_contact_ids_by_match_status"] == %{
             "overlap" => ["contact_match"]
           }

    assert explicit_empty["provider_reservation_review_contact_count"] == 0
    assert explicit_empty["provider_reservation_review_contact_ids"] == []

    assert explicit_empty["provider_reservation_review_contact_ids_by_ground_station_id"] == %{
             "gs_empty" => []
           }

    assert scalar_only["provider_reservation_review_contact_count"] == 2
    refute Map.has_key?(scalar_only, "provider_reservation_review_contact_ids")

    for manifest <- [repair, explicit_empty, scalar_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "correlates provider-reservation request identity across routed summaries" do
    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:provider_request_overlap"},
        "source_plan_id" => "plan:provider_request_overlap",
        "source_contact_allocation_report" => %{
          "provider_reservation_request_contact_count" => 2,
          "provider_reservation_request_contact_ids" => ["contact_source", "contact_shared"],
          "provider_reservation_request_contact_ids_by_ground_station_id" => %{
            "gs_a" => ["contact_station"]
          },
          "provider_reservation_request_contact_ids_by_direction" => %{
            "downlink" => ["contact_direction"]
          }
        },
        "contact_allocation_report" => %{
          "provider_reservation_request_contact_count" => 2,
          "provider_reservation_request_contact_ids" => ["contact_shared", "contact_result"],
          "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" => %{
            "downlink" => %{"gs_b" => ["contact_nested"]}
          },
          "provider_reservation_request_contact_ids_by_match_status" => %{
            "matched" => ["contact_match"]
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:provider_request_empty",
        "contact_allocation_report" => %{
          "provider_reservation_request_contact_count" => 9,
          "provider_reservation_request_contact_ids_by_ground_station_id" => %{
            "gs_empty" => []
          }
        }
      })

    scalar_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:provider_request_scalar",
        "contact_allocation_report" => %{
          "provider_reservation_request_contact_count" => 2
        }
      })

    expected_request_ids = [
      "contact_direction",
      "contact_match",
      "contact_nested",
      "contact_result",
      "contact_shared",
      "contact_source",
      "contact_station"
    ]

    assert repair["provider_reservation_request_contact_count"] == 7
    assert repair["provider_reservation_request_contact_ids"] == expected_request_ids

    assert repair["provider_reservation_request_contact_ids_by_ground_station_id"] == %{
             "gs_a" => ["contact_station"]
           }

    assert repair["provider_reservation_request_contact_ids_by_direction"] == %{
             "downlink" => ["contact_direction"]
           }

    assert repair[
             "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
           ] == %{"downlink" => %{"gs_b" => ["contact_nested"]}}

    assert repair["provider_reservation_request_contact_ids_by_match_status"] == %{
             "matched" => ["contact_match"]
           }

    assert explicit_empty["provider_reservation_request_contact_count"] == 0
    assert explicit_empty["provider_reservation_request_contact_ids"] == []

    assert explicit_empty["provider_reservation_request_contact_ids_by_ground_station_id"] == %{
             "gs_empty" => []
           }

    assert scalar_only["provider_reservation_request_contact_count"] == 2
    refute Map.has_key?(scalar_only, "provider_reservation_request_contact_ids")

    for manifest <- [repair, explicit_empty, scalar_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "correlates provider-reservation no-request identity across routed summaries" do
    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:provider_no_request_overlap"},
        "source_plan_id" => "plan:provider_no_request_overlap",
        "source_contact_allocation_report" => %{
          "provider_reservation_no_request_contact_count" => 2,
          "provider_reservation_no_request_contact_ids" => [
            "contact_source",
            "contact_shared"
          ],
          "provider_reservation_no_request_contact_ids_by_direction" => %{
            "downlink" => ["contact_direction"]
          }
        },
        "contact_allocation_report" => %{
          "provider_reservation_no_request_contact_count" => 2,
          "provider_reservation_no_request_contact_ids" => [
            "contact_shared",
            "contact_result"
          ],
          "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" => %{
            "downlink" => %{"gs_b" => ["contact_nested"]}
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:provider_no_request_empty",
        "contact_allocation_report" => %{
          "provider_reservation_no_request_contact_count" => 9,
          "provider_reservation_no_request_contact_ids_by_direction" => %{
            "downlink" => []
          }
        }
      })

    scalar_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:provider_no_request_scalar",
        "contact_allocation_report" => %{
          "provider_reservation_no_request_contact_count" => 2
        }
      })

    assert repair["provider_reservation_no_request_contact_count"] == 5

    assert repair["provider_reservation_no_request_contact_ids"] == [
             "contact_direction",
             "contact_nested",
             "contact_result",
             "contact_shared",
             "contact_source"
           ]

    assert repair["provider_reservation_no_request_contact_ids_by_direction"] == %{
             "downlink" => ["contact_direction"]
           }

    assert repair[
             "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
           ] == %{"downlink" => %{"gs_b" => ["contact_nested"]}}

    assert explicit_empty["provider_reservation_no_request_contact_count"] == 0
    assert explicit_empty["provider_reservation_no_request_contact_ids"] == []

    assert explicit_empty["provider_reservation_no_request_contact_ids_by_direction"] == %{
             "downlink" => []
           }

    assert scalar_only["provider_reservation_no_request_contact_count"] == 2
    refute Map.has_key?(scalar_only, "provider_reservation_no_request_contact_ids")

    for manifest <- [repair, explicit_empty, scalar_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "correlates capacity-pack group identity and status counts" do
    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:capacity_pack_group_overlap"},
        "source_plan_id" => "plan:capacity_pack_group_overlap",
        "source_contact_allocation_report" => %{
          "reduced_capacity_pack_group_count" => 7,
          "reduced_capacity_pack_status_counts" => %{"all_fit" => 7},
          "capacity_pack_group_ids" => ["pack_source", "pack_shared"],
          "capacity_pack_group_ids_by_status" => %{
            "all_fit" => ["pack_source", "pack_shared"]
          }
        },
        "contact_allocation_report" => %{
          "reduced_capacity_pack_group_count" => 7,
          "reduced_capacity_pack_status_counts" => %{"all_fit" => 7},
          "capacity_pack_group_ids" => ["pack_shared", "pack_result"],
          "capacity_pack_group_ids_by_status" => %{
            "all_fit" => ["pack_result", "pack_routed", "pack_shared"]
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:capacity_pack_group_empty",
        "contact_allocation_report" => %{
          "reduced_capacity_pack_group_count" => 9,
          "reduced_capacity_pack_status_counts" => %{"all_fit" => 9},
          "capacity_pack_group_ids_by_status" => %{"all_fit" => []}
        }
      })

    scalar_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:capacity_pack_group_scalar",
        "contact_allocation_report" => %{
          "reduced_capacity_pack_group_count" => 2,
          "reduced_capacity_pack_status_counts" => %{"all_fit" => 2}
        }
      })

    expected_group_ids = ["pack_result", "pack_routed", "pack_shared", "pack_source"]

    assert repair["reduced_capacity_pack_group_count"] == 4
    assert repair["reduced_capacity_pack_status_counts"] == %{"all_fit" => 4}
    assert repair["capacity_pack_group_ids"] == expected_group_ids
    assert repair["capacity_pack_group_ids_by_status"] == %{"all_fit" => expected_group_ids}

    assert explicit_empty["reduced_capacity_pack_group_count"] == 0
    assert explicit_empty["reduced_capacity_pack_status_counts"] == %{"all_fit" => 0}
    assert explicit_empty["capacity_pack_group_ids"] == []
    assert explicit_empty["capacity_pack_group_ids_by_status"] == %{"all_fit" => []}

    assert scalar_only["reduced_capacity_pack_group_count"] == 2
    assert scalar_only["reduced_capacity_pack_status_counts"] == %{"all_fit" => 2}
    refute Map.has_key?(scalar_only, "capacity_pack_group_ids")
    refute Map.has_key?(scalar_only, "capacity_pack_group_ids_by_status")

    for manifest <- [repair, explicit_empty, scalar_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "correlates capacity-pack contact identity and status counts" do
    status = "deferred_by_reduced_station_capacity_pack"

    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:capacity_pack_contact_overlap"},
        "source_plan_id" => "plan:capacity_pack_contact_overlap",
        "source_contact_allocation_report" => %{
          "capacity_pack_status_counts" => %{status => 7},
          "capacity_pack_contact_ids_by_status" => %{
            status => ["contact_source", "contact_shared"]
          }
        },
        "contact_allocation_report" => %{
          "capacity_pack_status_counts" => %{status => 7},
          "capacity_pack_contact_ids_by_status" => %{
            status => ["contact_result", "contact_routed", "contact_shared"]
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:capacity_pack_contact_empty",
        "contact_allocation_report" => %{
          "capacity_pack_status_counts" => %{status => 9},
          "capacity_pack_contact_ids_by_status" => %{status => []}
        }
      })

    count_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:capacity_pack_contact_count",
        "contact_allocation_report" => %{
          "capacity_pack_status_counts" => %{status => 2}
        }
      })

    expected_contact_ids = [
      "contact_result",
      "contact_routed",
      "contact_shared",
      "contact_source"
    ]

    assert repair["capacity_pack_status_counts"] == %{status => 4}
    assert repair["capacity_pack_contact_ids_by_status"] == %{status => expected_contact_ids}
    assert explicit_empty["capacity_pack_status_counts"] == %{status => 0}
    assert explicit_empty["capacity_pack_contact_ids_by_status"] == %{status => []}
    assert count_only["capacity_pack_status_counts"] == %{status => 2}
    refute Map.has_key?(count_only, "capacity_pack_contact_ids_by_status")

    for manifest <- [repair, explicit_empty, count_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "correlates station-reservation match-status contact identity and counts" do
    status = "overlap"

    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:reservation_match_overlap"},
        "source_plan_id" => "plan:reservation_match_overlap",
        "source_contact_allocation_report" => %{
          "station_reservation_match_status_counts" => %{status => 7},
          "station_reservation_contact_ids_by_match_status" => %{
            status => ["contact_source", "contact_shared"]
          },
          "station_reservation_ids_by_match_status" => %{
            status => ["reservation_shared"]
          }
        },
        "contact_allocation_report" => %{
          "station_reservation_match_status_counts" => %{status => 7},
          "station_reservation_contact_ids_by_match_status" => %{
            status => ["contact_result", "contact_routed", "contact_shared"]
          },
          "station_reservation_ids_by_match_status" => %{
            status => ["reservation_result", "reservation_shared"]
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:reservation_match_empty",
        "contact_allocation_report" => %{
          "station_reservation_match_status_counts" => %{status => 9},
          "station_reservation_contact_ids_by_match_status" => %{status => []}
        }
      })

    count_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:reservation_match_count",
        "contact_allocation_report" => %{
          "station_reservation_match_status_counts" => %{status => 2}
        }
      })

    expected_contact_ids = [
      "contact_result",
      "contact_routed",
      "contact_shared",
      "contact_source"
    ]

    assert repair["station_reservation_match_status_counts"] == %{status => 4}

    assert repair["station_reservation_contact_ids_by_match_status"] == %{
             status => expected_contact_ids
           }

    assert repair["station_reservation_ids_by_match_status"] == %{
             status => ["reservation_result", "reservation_shared"]
           }

    assert explicit_empty["station_reservation_match_status_counts"] == %{status => 0}
    assert explicit_empty["station_reservation_contact_ids_by_match_status"] == %{status => []}
    assert count_only["station_reservation_match_status_counts"] == %{status => 2}
    refute Map.has_key?(count_only, "station_reservation_contact_ids_by_match_status")

    for manifest <- [repair, explicit_empty, count_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "lifts and correlates station-reservation owner contact identity and counts" do
    owner = "mission_ops"

    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:reservation_owner_overlap"},
        "source_plan_id" => "plan:reservation_owner_overlap",
        "source_contact_allocation_report" => %{
          "station_reserved_by_counts" => %{owner => 7},
          "station_reservation_contact_ids_by_reserved_by" => %{
            owner => ["contact_source", "contact_shared"]
          },
          "station_reservation_ids_by_reserved_by" => %{
            owner => ["reservation_shared"]
          }
        },
        "contact_allocation_report" => %{
          "station_reserved_by_counts" => %{owner => 7},
          "station_reservation_contact_ids_by_reserved_by" => %{
            owner => ["contact_result", "contact_routed", "contact_shared"]
          },
          "station_reservation_ids_by_reserved_by" => %{
            owner => ["reservation_result", "reservation_shared"]
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:reservation_owner_empty",
        "contact_allocation_report" => %{
          "station_reserved_by_counts" => %{owner => 9},
          "station_reservation_contact_ids_by_reserved_by" => %{owner => []}
        }
      })

    count_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:reservation_owner_count",
        "contact_allocation_report" => %{"station_reserved_by_counts" => %{owner => 2}}
      })

    expected_contact_ids = [
      "contact_result",
      "contact_routed",
      "contact_shared",
      "contact_source"
    ]

    assert repair["station_reserved_by_counts"] == %{owner => 4}

    assert repair["station_reservation_contact_ids_by_reserved_by"] == %{
             owner => expected_contact_ids
           }

    assert repair["station_reservation_ids_by_reserved_by"] == %{
             owner => ["reservation_result", "reservation_shared"]
           }

    assert explicit_empty["station_reserved_by_counts"] == %{owner => 0}
    assert explicit_empty["station_reservation_contact_ids_by_reserved_by"] == %{owner => []}
    assert count_only["station_reserved_by_counts"] == %{owner => 2}
    refute Map.has_key?(count_only, "station_reservation_contact_ids_by_reserved_by")

    for manifest <- [repair, explicit_empty, count_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "lifts and correlates station-reservation status contact identity and counts" do
    status = "confirmed"

    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:reservation_status_overlap"},
        "source_plan_id" => "plan:reservation_status_overlap",
        "source_contact_allocation_report" => %{
          "station_reservation_status_counts" => %{status => 7},
          "station_reservation_contact_ids_by_status" => %{
            status => ["contact_source", "contact_shared"]
          },
          "station_reservation_ids_by_status" => %{
            status => ["reservation_shared"]
          }
        },
        "contact_allocation_report" => %{
          "station_reservation_status_counts" => %{status => 7},
          "station_reservation_contact_ids_by_status" => %{
            status => ["contact_result", "contact_routed", "contact_shared"]
          },
          "station_reservation_ids_by_status" => %{
            status => ["reservation_result", "reservation_shared"]
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:reservation_status_empty",
        "contact_allocation_report" => %{
          "station_reservation_status_counts" => %{status => 9},
          "station_reservation_contact_ids_by_status" => %{status => []}
        }
      })

    count_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:reservation_status_count",
        "contact_allocation_report" => %{
          "station_reservation_status_counts" => %{status => 2}
        }
      })

    expected_contact_ids = [
      "contact_result",
      "contact_routed",
      "contact_shared",
      "contact_source"
    ]

    assert repair["station_reservation_status_counts"] == %{status => 4}

    assert repair["station_reservation_contact_ids_by_status"] == %{
             status => expected_contact_ids
           }

    assert repair["station_reservation_ids_by_status"] == %{
             status => ["reservation_result", "reservation_shared"]
           }

    assert explicit_empty["station_reservation_status_counts"] == %{status => 0}
    assert explicit_empty["station_reservation_contact_ids_by_status"] == %{status => []}
    assert count_only["station_reservation_status_counts"] == %{status => 2}
    refute Map.has_key?(count_only, "station_reservation_contact_ids_by_status")

    for manifest <- [repair, explicit_empty, count_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "correlates station-reservation expiration contact identity and counts" do
    status = "missing"
    scalar_count_field = "station_reservation_missing_expiration_contact_count"

    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:reservation_expiration_overlap"},
        "source_plan_id" => "plan:reservation_expiration_overlap",
        "source_contact_allocation_report" => %{
          "station_reservation_expiration_status_counts" => %{status => 7},
          scalar_count_field => 7,
          "station_reservation_contact_ids_by_expiration_status" => %{
            status => ["contact_source", "contact_shared"]
          },
          "station_reservation_ids_by_expiration_status" => %{
            status => ["reservation_shared"]
          }
        },
        "contact_allocation_report" => %{
          "station_reservation_expiration_status_counts" => %{status => 7},
          scalar_count_field => 7,
          "station_reservation_contact_ids_by_expiration_status" => %{
            status => ["contact_result", "contact_routed", "contact_shared"]
          },
          "station_reservation_ids_by_expiration_status" => %{
            status => ["reservation_result", "reservation_shared"]
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:reservation_expiration_empty",
        "contact_allocation_report" => %{
          "station_reservation_expiration_status_counts" => %{status => 9},
          scalar_count_field => 9,
          "station_reservation_contact_ids_by_expiration_status" => %{status => []}
        }
      })

    count_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:reservation_expiration_count",
        "contact_allocation_report" => %{
          "station_reservation_expiration_status_counts" => %{status => 2},
          scalar_count_field => 2
        }
      })

    expected_contact_ids = [
      "contact_result",
      "contact_routed",
      "contact_shared",
      "contact_source"
    ]

    assert repair["station_reservation_expiration_status_counts"] == %{status => 4}
    assert repair[scalar_count_field] == 4

    assert repair["station_reservation_contact_ids_by_expiration_status"] == %{
             status => expected_contact_ids
           }

    assert repair["station_reservation_ids_by_expiration_status"] == %{
             status => ["reservation_result", "reservation_shared"]
           }

    assert explicit_empty["station_reservation_expiration_status_counts"] == %{status => 0}
    assert explicit_empty[scalar_count_field] == 0

    assert explicit_empty["station_reservation_contact_ids_by_expiration_status"] == %{
             status => []
           }

    assert count_only["station_reservation_expiration_status_counts"] == %{status => 2}
    assert count_only[scalar_count_field] == 2
    refute Map.has_key?(count_only, "station_reservation_contact_ids_by_expiration_status")

    for manifest <- [repair, explicit_empty, count_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "correlates required-capacity source identity and counts" do
    source = "capacity_model"

    repair =
      CadenceImport.from_repair_artifact(%{
        "repair_metadata" => %{"repair_id" => "repair:required_capacity_source_overlap"},
        "source_plan_id" => "plan:required_capacity_source_overlap",
        "source_contact_allocation_report" => %{
          "required_capacity_fraction_source_counts" => %{source => 7},
          "required_capacity_fraction_contact_ids_by_source" => %{
            source => ["contact_source", "contact_shared"]
          }
        },
        "contact_allocation_report" => %{
          "required_capacity_fraction_source_counts" => %{source => 7},
          "required_capacity_fraction_contact_ids_by_source" => %{
            source => ["contact_result", "contact_routed", "contact_shared"]
          }
        }
      })

    explicit_empty =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:required_capacity_source_empty",
        "contact_allocation_report" => %{
          "required_capacity_fraction_source_counts" => %{source => 9},
          "required_capacity_fraction_contact_ids_by_source" => %{source => []}
        }
      })

    count_only =
      CadenceImport.from_campaign_artifact(%{
        "plan_id" => "plan:required_capacity_source_count",
        "contact_allocation_report" => %{
          "required_capacity_fraction_source_counts" => %{source => 2}
        }
      })

    expected_contact_ids = [
      "contact_result",
      "contact_routed",
      "contact_shared",
      "contact_source"
    ]

    assert repair["required_capacity_fraction_source_counts"] == %{source => 4}

    assert repair["required_capacity_fraction_contact_ids_by_source"] == %{
             source => expected_contact_ids
           }

    assert explicit_empty["required_capacity_fraction_source_counts"] == %{source => 0}
    assert explicit_empty["required_capacity_fraction_contact_ids_by_source"] == %{source => []}
    assert count_only["required_capacity_fraction_source_counts"] == %{source => 2}
    refute Map.has_key?(count_only, "required_capacity_fraction_contact_ids_by_source")

    for manifest <- [repair, explicit_empty, count_only] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(manifest)
    end
  end

  test "builds deterministic import manifest rows from plan-delta reviews" do
    package = %{
      "schema_contract" => "operator_review_package.v1",
      "model" => "artifact_only_operator_review_package",
      "source_artifact_type" => "campaign_repair.v2",
      "source_artifact_id" => "repair:manifest_test",
      "review_count" => 2,
      "approval_requirement_count" => 0,
      "contention_recommendation_count" => 0,
      "realized_feedback_count" => 0,
      "warning_count" => 0,
      "risk_count" => 0,
      "recommendation_count" => 0,
      "rows" => [
        %{
          "id" => "plan_delta:dl_1:moved:1",
          "rank" => 1,
          "review_type" => "plan_delta_review",
          "source" => "campaign_repair.deltas",
          "subject_id" => "dl_1",
          "activity_id" => "dl_1",
          "activity_type" => "downlink",
          "target_id" => "target_alpha",
          "action" => "review_moved_timeline_item",
          "required_operator_action" => "review_moved_timeline_item",
          "reason" => "missed_contact_rescheduled",
          "approval_status" => "not_required",
          "repair_action" => "moved",
          "source_timeline_id" => "timeline:dl_1",
          "replacement_activity_id" => "dl_2",
          "replacement_timeline_id" => "timeline:dl_2",
          "replacement_cadence_import_status" => "present",
          "replacement_cadence_import_type" => "contact",
          "replacement_cadence_import_id" => "dl_2",
          "replacement_cadence_import_contract" => "proposed_contact.v1",
          "replacement_has_cadence_import" => true,
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
          "source_delta" => %{
            "schema_contract" => "plan_delta.v1",
            "activity_id" => "dl_1",
            "activity_type" => "downlink",
            "repair_action" => "moved",
            "reason" => "missed_contact_rescheduled",
            "source_timeline_id" => "timeline:dl_1",
            "replacement_activity_id" => "dl_2",
            "replacement_timeline_id" => "timeline:dl_2"
          }
        },
        %{
          "id" => "plan_delta:dl_3:moved:2",
          "rank" => 2,
          "review_type" => "plan_delta_review",
          "source" => "campaign_repair.deltas",
          "subject_id" => "dl_3",
          "activity_id" => "dl_3",
          "activity_type" => "downlink",
          "action" => "review_moved_timeline_item",
          "required_operator_action" => "review_moved_timeline_item",
          "reason" => "replacement_missing_import",
          "approval_status" => "not_required",
          "repair_action" => "moved",
          "source_timeline_id" => "timeline:dl_3",
          "replacement_activity_id" => "dl_4",
          "replacement_timeline_id" => "timeline:dl_4",
          "replacement_cadence_import_status" => "missing",
          "replacement_has_cadence_import" => false,
          "source_delta" => %{"schema_contract" => "plan_delta.v1"}
        }
      ],
      "provenance" => %{},
      "assumptions" => %{}
    }

    manifest = CadenceImport.from_operator_review_package(package)

    assert OrbitalDynamics.cadence_import_manifest(package) == manifest

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "schema_version" => 1,
             "model" => "artifact_only_cadence_import_manifest",
             "manifest_id" => "cadence_import_manifest:repair:manifest_test",
             "source_artifact_type" => "campaign_repair.v2",
             "source_artifact_id" => "repair:manifest_test",
             "row_count" => 2,
             "ready_count" => 1,
             "review_required_count" => 0,
             "blocked_count" => 1,
             "missing_import_count" => 1,
             "rows" => [ready, blocked]
           } = manifest

    assert {:ok, cadence_import_manifest_schema} =
             Schema.json_schema("cadence_import_manifest.v1")

    assert get_in(cadence_import_manifest_schema, ["properties", "model", "const"]) ==
             "artifact_only_cadence_import_manifest"

    stale_manifest_model =
      Map.put(manifest, "model", "stale_cadence_import_manifest")

    assert {:error, stale_manifest_model_report} =
             Schema.validate_artifact(stale_manifest_model)

    assert Enum.any?(
             stale_manifest_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"artifact_only_cadence_import_manifest\"")
           )

    assert %{
             "id" => "cadence_import:plan_delta:dl_1:moved:1",
             "rank" => 1,
             "import_action" => "import_replacement_activity",
             "import_status" => "ready_for_import",
             "import_side" => "replacement",
             "source_review_row_id" => "plan_delta:dl_1:moved:1",
             "subject_id" => "dl_1",
             "target_id" => "target_alpha",
             "replacement_activity_id" => "dl_2",
             "cadence_import_status" => "present",
             "cadence_import_type" => "contact",
             "cadence_import_id" => "dl_2",
             "cadence_import_contract" => "proposed_contact.v1",
             "has_cadence_import" => true,
             "import_activity_context" => %{"cadence_import" => %{"external_id" => "dl_2"}}
           } = ready

    assert %{
             "id" => "cadence_import:plan_delta:dl_3:moved:2",
             "import_status" => "blocked_missing_cadence_import",
             "cadence_import_status" => "missing",
             "has_cadence_import" => false
           } = blocked

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_source_delta =
      update_in(manifest, ["rows"], fn [ready, blocked] ->
        source_delta =
          ready["source_delta"]
          |> Map.put("repair_action", "suppressed")
          |> Map.put("replacement_activity_id", "stale_replacement")

        [Map.put(ready, "source_delta", source_delta), blocked]
      end)

    assert {:error, stale_source_delta_report} = Schema.validate_artifact(stale_source_delta)

    assert Enum.any?(
             stale_source_delta_report["errors"],
             &(&1["path"] == "$.rows[0].repair_action" and
                 &1["message"] == "must match source_delta.repair_action")
           )

    assert Enum.any?(
             stale_source_delta_report["errors"],
             &(&1["path"] == "$.rows[0].replacement_activity_id" and
                 &1["message"] == "must match source_delta.replacement_activity_id")
           )
  end

  test "timeline dependency impact summaries become Cadence review rows" do
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
    manifest = CadenceImport.from_timeline_dependency_impact_summary(summary)

    atom_key_summary =
      summary |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_dependency_impact_summary.v1",
             "source_artifact_id" => "timeline_diff_report.v1",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_timeline_dependency_impact" => 2},
             "source_review_type_counts" => %{"timeline_dependency_impact_review" => 2}
           } = manifest

    assert [
             %{
               "import_action" => "review_timeline_dependency_impact",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_dependency_impact_review",
               "source_review_action" => "review_timeline_integrity",
               "timeline_id" => "timeline:command:20.0",
               "activity_id" => "cmd_combo",
               "dependency_impact_scope" => "source",
               "dependency_impact_status" => "review_required",
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
               },
               "source_review_row" => %{
                 "source_timeline_dependency_impact" => %{
                   "scope" => "source",
                   "activity_id" => "cmd_combo"
                 },
                 "source_dependency_impact_impacted_dependency_timeline_ids" => [
                   "timeline:health_check:0.0"
                 ],
                 "source_dependency_impact_impacted_exclusive_with_activity_ids" => [
                   "health_gate"
                 ]
               }
             },
             %{
               "source_review_type" => "timeline_dependency_impact_review",
               "dependency_impact_scope" => "replacement"
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_dependency_impact =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_timeline_dependency_impact", "activity_id"],
        "bad activity id"
      )

    assert {:error, invalid_source_dependency_impact_report} =
             Schema.validate_artifact(invalid_source_dependency_impact)

    assert Enum.any?(
             invalid_source_dependency_impact_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_dependency_impact.activity_id")
           )

    invalid_source_dependency_status =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_timeline_dependency_impact", "dependency_impact_status"],
        "clear"
      )

    assert {:error, invalid_source_dependency_status_report} =
             Schema.validate_artifact(invalid_source_dependency_status)

    assert Enum.any?(
             invalid_source_dependency_status_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_dependency_impact.dependency_impact_status")
           )

    invalid_nested_source_dependency_impact =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_dependency_impact",
          "activity_id"
        ],
        "bad activity id"
      )

    assert {:error, invalid_nested_source_dependency_impact_report} =
             Schema.validate_artifact(invalid_nested_source_dependency_impact)

    assert Enum.any?(
             invalid_nested_source_dependency_impact_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_dependency_impact.activity_id")
           )

    invalid_nested_source_dependency_status =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_dependency_impact",
          "dependency_impact_status"
        ],
        "clear"
      )

    assert {:error, invalid_nested_source_dependency_status_report} =
             Schema.validate_artifact(invalid_nested_source_dependency_status)

    assert Enum.any?(
             invalid_nested_source_dependency_status_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_dependency_impact.dependency_impact_status")
           )

    stale_nested_source_dependency_impact =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_dependency_impact",
          "activity_id"
        ],
        "stale_cmd_combo"
      )

    assert {:error, stale_nested_source_dependency_impact_report} =
             Schema.validate_artifact(stale_nested_source_dependency_impact)

    assert Enum.any?(
             stale_nested_source_dependency_impact_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_timeline_dependency_impact" and
                 &1["message"] ==
                   "must match source_timeline_dependency_impact on Cadence import row")
           )

    assert OrbitalDynamics.cadence_import_manifest(summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(summary, "schema_contract")) ==
             manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(atom_key_summary, :schema_contract)) ==
             manifest
  end

  test "timeline publication summaries become Cadence review rows" do
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

    manifest = CadenceImport.from_timeline_publication_summary(summary)

    atom_key_summary =
      summary |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_publication_summary.v1",
             "source_artifact_id" =>
               "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_timeline_publication" => 1},
             "source_review_type_counts" => %{"timeline_publication_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_timeline_publication",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_publication_review",
               "source_review_action" => "review_timeline_publication",
               "publication_id" =>
                 "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
               "publication_sequence" => 7,
               "publication_status" => "published_with_downstream_invalidations",
               "downstream_invalidation_status" => "invalidated",
               "publication_authority" => "mission_operations",
               "source_artifact_id" => "timeline:published_plan:v2",
               "source_artifact_type" => "operational_timeline_report.v1",
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
               "impacted_dependency_activity_ids" => ["health_gate"],
               "timeline_diff_row_count" => 3,
               "timeline_diff_review_required_count" => 2,
               "changed_field_counts" => %{"timeline_presence" => 2},
               "source_timeline_publication_summary" => ^summary,
               "source_review_row" => %{
                 "review_type" => "timeline_publication_review",
                 "downstream_invalidation_reason_counts" => %{
                   "dependency_impact_review_required" => 2
                 },
                 "invalidated_downstream_product_ids_by_reason" => %{
                   "dependency_impact_review_required" => [
                     "cadence_import:plan:v1",
                     "operator_review:plan:v1"
                   ]
                 },
                 "impacted_source_activity_ids" => ["health_gate"],
                 "impacted_source_timeline_ids" => ["timeline:health_check:0.0"],
                 "dependent_activity_ids" => ["cmd_main"],
                 "dependent_timeline_ids" => ["timeline:command:20.0"],
                 "source_dependent_activity_ids" => ["cmd_main"],
                 "source_dependent_timeline_ids" => ["timeline:command:20.0"],
                 "replacement_dependent_activity_ids" => ["cmd_main"],
                 "replacement_dependent_timeline_ids" => ["timeline:command:20.0"],
                 "impacted_dependency_activity_ids" => ["health_gate"],
                 "source_timeline_publication_summary" => ^summary
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_publication_status =
      put_in(manifest, ["rows", Access.at(0), "publication_status"], "published")

    assert {:error, stale_publication_status_report} =
             Schema.validate_artifact(stale_publication_status)

    assert Enum.any?(
             stale_publication_status_report["errors"],
             &(&1["path"] == "$.rows[0].publication_status" and
                 &1["message"] ==
                   "must equal source_timeline_publication_summary.publication_status")
           )

    invalid_nested_source_publication =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row", "source_timeline_publication_summary"],
        Map.put(summary, "publication_status", "published")
      )

    assert {:error, invalid_nested_source_publication_report} =
             Schema.validate_artifact(invalid_nested_source_publication)

    assert Enum.any?(
             invalid_nested_source_publication_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_publication_summary.publication_status")
           )

    stale_summary =
      Timeline.publication_summary(
        %{
          "schema_contract" => "operational_timeline_report.v1",
          "id" => "timeline:published_plan:stale"
        },
        publication_sequence: 8,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:published_plan:v0"],
        downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
        dependency_impact_summary: dependency_impact,
        timeline_diff_summary: timeline_diff_summary
      )

    stale_nested_source_publication =
      update_in(manifest, ["rows"], fn [row] ->
        stale_source_review_row =
          row["source_review_row"]
          |> Map.merge(Map.take(stale_summary, Map.keys(row)))
          |> Map.put("source_timeline_publication_summary", stale_summary)

        [Map.put(row, "source_review_row", stale_source_review_row)]
      end)

    assert {:error, stale_nested_source_publication_report} =
             Schema.validate_artifact(stale_nested_source_publication)

    assert Enum.any?(
             stale_nested_source_publication_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_publication_summary" and
                 &1["message"] ==
                   "must match source_timeline_publication_summary on Cadence import row")
           )

    assert OrbitalDynamics.cadence_import_manifest(summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(summary, "schema_contract")) ==
             manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(atom_key_summary, :schema_contract)) ==
             manifest
  end

  test "timeline lifecycle-state summaries become import review rows" do
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
    manifest = CadenceImport.from_timeline_lifecycle_state_summary(summary)

    atom_key_summary =
      summary |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_lifecycle_state_summary.v1",
             "source_artifact_id" => "timeline.lifecycle_state",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_lifecycle_state_review",
               "source_review_action" => "review_activity_approval",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "timeline_lifecycle_state_status" => "review_required",
               "transition_decision" => "review",
               "source_lifecycle_state_operator_action_reason_counts" => %{
                 "activity_execution_recorded" => 1,
                 "approval_grant_requires_operator_authority" => 1
               },
               "source_lifecycle_state_review_timeline_ids_by_operator_action_reason" => %{
                 "activity_execution_recorded" => ["timeline:cmd_provider"],
                 "approval_grant_requires_operator_authority" => ["timeline:cmd_provider"]
               },
               "status_transition" => %{
                 "transition_category" => "execution_recorded"
               },
               "approval_transition" => %{
                 "transition_category" => "approval_granted"
               },
               "source_timeline_lifecycle_state" => %{
                 "timeline_id" => "timeline:cmd_provider",
                 "transition_decision" => "review"
               },
               "source_review_row" => %{
                 "source_lifecycle_state_operator_action_reason_counts" => %{
                   "activity_execution_recorded" => 1,
                   "approval_grant_requires_operator_authority" => 1
                 },
                 "source_lifecycle_state_review_timeline_ids_by_operator_action_reason" => %{
                   "activity_execution_recorded" => ["timeline:cmd_provider"],
                   "approval_grant_requires_operator_authority" => ["timeline:cmd_provider"]
                 },
                 "source_timeline_lifecycle_state" => %{
                   "timeline_id" => "timeline:cmd_provider"
                 }
               }
             }
           ] = manifest["rows"]

    assert CadenceImport.manifest(summary) == manifest

    assert CadenceImport.manifest(Map.delete(summary, "schema_contract")) == manifest

    assert OrbitalDynamics.cadence_import_manifest(summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(summary, "schema_contract")) ==
             manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(atom_key_summary, :schema_contract)) ==
             manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_lifecycle_state =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_timeline_lifecycle_state", "timeline_id"],
        "bad timeline id"
      )

    assert {:error, invalid_source_lifecycle_state_report} =
             Schema.validate_artifact(invalid_source_lifecycle_state)

    assert Enum.any?(
             invalid_source_lifecycle_state_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_lifecycle_state.timeline_id")
           )

    invalid_source_review_lifecycle_state =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_lifecycle_state",
          "timeline_id"
        ],
        "bad timeline id"
      )

    assert {:error, invalid_source_review_lifecycle_state_report} =
             Schema.validate_artifact(invalid_source_review_lifecycle_state)

    assert Enum.any?(
             invalid_source_review_lifecycle_state_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_lifecycle_state.timeline_id")
           )

    stale_source_review_lifecycle_state =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_lifecycle_state",
          "timeline_id"
        ],
        "timeline:stale_cmd_provider"
      )

    assert {:error, stale_source_review_lifecycle_state_report} =
             Schema.validate_artifact(stale_source_review_lifecycle_state)

    assert Enum.any?(
             stale_source_review_lifecycle_state_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_timeline_lifecycle_state" and
                 &1["message"] ==
                   "must match source_timeline_lifecycle_state on Cadence import row")
           )
  end

  test "timeline activity precondition summaries become import manifest rows" do
    summary =
      Timeline.activity_precondition_summary(%{
        id: :cmd_preflight,
        type: :command,
        payload_available: false,
        degraded: true,
        resource_blocking_dimension: :power,
        dependency_activity_ids: [:health_check_1, :obs_1],
        dependency_timeline_ids: [:"timeline:health_check_1"],
        exclusive_with_activity_ids: [:dl_conflict],
        exclusive_with_timeline_ids: [:"timeline:dl_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: :"timeline:cmd_preflight"}
      })

    manifest = CadenceImport.from_timeline_activity_precondition_summary(summary)

    atom_key_summary =
      summary |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end) |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_activity_precondition_summary.v1",
             "source_artifact_id" => "timeline:cmd_preflight",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_timeline_precondition" => 1},
             "source_review_type_counts" => %{"timeline_activity_precondition_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_timeline_precondition",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_activity_precondition_review",
               "source_review_action" => "review_blocked_activity_precondition",
               "timeline_id" => "timeline:cmd_preflight",
               "activity_id" => "cmd_preflight",
               "precondition_status" => "blocked",
               "blocked_precondition_count" => 2,
               "review_precondition_count" => 1,
               "dependency_activity_ids" => ["health_check_1", "obs_1"],
               "dependency_timeline_ids" => ["timeline:health_check_1"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
               "allow_overlap" => true,
               "source_timeline_activity_precondition_summary" => %{
                 "schema_contract" => "timeline_activity_precondition_summary.v1",
                 "precondition_status" => "blocked"
               },
               "source_review_row" => %{
                 "source_timeline_activity_precondition_summary" => %{
                   "schema_contract" => "timeline_activity_precondition_summary.v1",
                   "allow_overlap" => true
                 }
               }
             }
           ] = manifest["rows"]

    assert CadenceImport.manifest(summary) == manifest
    assert CadenceImport.manifest(Map.delete(summary, "schema_contract")) == manifest
    assert OrbitalDynamics.cadence_import_manifest(summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(summary, "schema_contract")) ==
             manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(atom_key_summary, :schema_contract)) ==
             manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source =
      put_in(
        manifest,
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

    invalid_source_review =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_activity_precondition_summary",
          "timeline_id"
        ],
        "bad timeline id"
      )

    assert {:error, invalid_source_review_report} =
             Schema.validate_artifact(invalid_source_review)

    assert Enum.any?(
             invalid_source_review_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_activity_precondition_summary.timeline_id")
           )

    stale_source_review =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_activity_precondition_summary",
          "timeline_id"
        ],
        "timeline:stale_cmd_preflight"
      )

    assert {:error, stale_source_review_report} =
             Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_activity_precondition_summary" and
                 &1["message"] ==
                   "must match source_timeline_activity_precondition_summary on Cadence import row")
           )
  end

  test "candidate refresh precondition summaries become import manifest rows" do
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

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:precondition_handoff",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_timeline_precondition" => 2},
             "source_review_type_counts" => %{"timeline_activity_precondition_review" => 2}
           } = manifest

    assert [
             %{
               "source_review_action" => "review_blocked_activity_precondition",
               "dependency_activity_ids" => ["health_check_1"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "allow_overlap" => true
             },
             %{
               "source_review_action" => "review_invalid_activity_input",
               "invalid_activity_input" => true,
               "source_timeline_activity_precondition_summary" => %{
                 "invalid_activity_input" => true,
                 "invalid_activity_input_reason" => "missing_activity_type"
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped timeline activity precondition summaries" do
    summary =
      Timeline.activity_precondition_summary(%{
        id: :cmd_wrapped_preflight,
        type: :command,
        payload_available: false,
        degraded: true,
        resource_blocking_dimension: :power,
        dependency_activity_ids: [:health_check_1, :obs_1],
        dependency_timeline_ids: [:"timeline:health_check_1"],
        exclusive_with_activity_ids: [:dl_conflict],
        exclusive_with_timeline_ids: [:"timeline:dl_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: :"timeline:cmd_wrapped_preflight"}
      })

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_precondition_import",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_activity_precondition_summary" => summary
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_precondition_import",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_timeline_precondition" => 1},
             "source_review_type_counts" => %{"timeline_activity_precondition_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_timeline_precondition",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_activity_precondition_review",
               "source_review_action" => "review_blocked_activity_precondition",
               "approval_status" => "operator_review_required",
               "timeline_id" => "timeline:cmd_wrapped_preflight",
               "activity_id" => "cmd_wrapped_preflight",
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
               "allow_overlap" => true,
               "has_cadence_import" => false,
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact[0].timeline_activity_precondition_summary.summary",
                 "review_type" => "timeline_activity_precondition_review"
               }
             } = row
           ] = manifest["rows"]

    assert row["source"] ==
             "candidate_refresh.source_result_artifact[0].timeline_activity_precondition_summary.summary"

    assert row["source_timeline_activity_precondition_summary"] == summary

    assert get_in(row, ["source_review_row", "source_timeline_activity_precondition_summary"]) ==
             summary

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "single activity timeline states become import manifest rows" do
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

    atom_key_artifact = fn artifact ->
      artifact
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()
    end

    atom_key_activity_state = atom_key_artifact.(activity_state)

    status_manifest = CadenceImport.from_timeline_activity_status_state(status_state)

    assert %{
             "source_artifact_type" => "timeline_activity_status_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "row_count" => 1,
             "ready_count" => 1,
             "review_required_count" => 0,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = status_manifest

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "import_status" => "ready_for_import",
               "source_review_type" => "timeline_lifecycle_state_review",
               "source_review_action" => "record_timeline_change",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "transition_decision" => "record",
               "approval_status" => "not_required",
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_status_state.v1",
                 "timeline_id" => "timeline:cmd_provider"
               }
             }
           ] = status_manifest["rows"]

    activity_state_manifest = CadenceImport.from_timeline_activity_state(activity_state)

    assert %{
             "source_artifact_type" => "timeline_activity_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "row_count" => 1,
             "ready_count" => 1,
             "review_required_count" => 0,
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = activity_state_manifest

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "import_status" => "ready_for_import",
               "source_review_type" => "timeline_lifecycle_state_review",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "approval_status" => "not_required",
               "source_timeline_activity_state" => %{
                 "schema_contract" => "timeline_activity_state.v1",
                 "timeline_id" => "timeline:cmd_provider",
                 "state_status" => "matched",
                 "row_count" => 1
               },
               "source_review_row" => %{
                 "source" => "timeline_activity_state.state",
                 "source_timeline_activity_state" => %{
                   "schema_contract" => "timeline_activity_state.v1",
                   "timeline_id" => "timeline:cmd_provider",
                   "state_status" => "matched",
                   "row_count" => 1
                 }
               }
             }
           ] = activity_state_manifest["rows"]

    refute Map.has_key?(
             hd(activity_state_manifest["rows"]),
             "source_timeline_lifecycle_state"
           )

    approval_manifest = CadenceImport.from_timeline_activity_approval_state(approval_state)

    assert %{
             "source_artifact_type" => "timeline_activity_approval_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "row_count" => 1,
             "review_required_count" => 1
           } = approval_manifest

    assert [
             %{
               "import_status" => "review_required_before_import",
               "source_review_action" => "review_activity_approval",
               "approval_transition" => %{"transition_category" => "approval_granted"}
             }
           ] = approval_manifest["rows"]

    lifecycle_manifest = CadenceImport.from_timeline_activity_lifecycle_state(lifecycle_state)

    assert %{
             "source_artifact_type" => "timeline_activity_lifecycle_state.v1",
             "source_artifact_id" => "timeline:cmd_provider",
             "row_count" => 1,
             "review_required_count" => 1
           } = lifecycle_manifest

    assert CadenceImport.manifest(status_state) == status_manifest
    assert CadenceImport.manifest(Map.delete(status_state, "schema_contract")) == status_manifest
    assert CadenceImport.manifest(activity_state) == activity_state_manifest

    assert CadenceImport.manifest(Map.delete(activity_state, "schema_contract")) ==
             activity_state_manifest

    assert OrbitalDynamics.cadence_import_manifest(activity_state) == activity_state_manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(activity_state, "schema_contract")) ==
             activity_state_manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_activity_state) ==
             activity_state_manifest

    assert OrbitalDynamics.cadence_import_manifest(
             Map.delete(atom_key_activity_state, :schema_contract)
           ) == activity_state_manifest

    assert CadenceImport.manifest(approval_state) == approval_manifest
    assert CadenceImport.manifest(lifecycle_state) == lifecycle_manifest

    Enum.each(
      [
        {status_state, status_manifest},
        {approval_state, approval_manifest},
        {lifecycle_state, lifecycle_manifest}
      ],
      fn {state, manifest} ->
        atom_key_state = atom_key_artifact.(state)

        assert OrbitalDynamics.cadence_import_manifest(state) == manifest

        assert OrbitalDynamics.cadence_import_manifest(Map.delete(state, "schema_contract")) ==
                 manifest

        assert OrbitalDynamics.cadence_import_manifest(atom_key_state) == manifest

        assert OrbitalDynamics.cadence_import_manifest(
                 Map.delete(atom_key_state, :schema_contract)
               ) ==
                 manifest
      end
    )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(lifecycle_manifest)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(activity_state_manifest)

    invalid_activity_state_source =
      put_in(
        activity_state_manifest,
        ["rows", Access.at(0), "source_timeline_activity_state", "timeline_id"],
        "bad timeline id"
      )

    assert {:error, invalid_activity_state_source_report} =
             Schema.validate_artifact(invalid_activity_state_source)

    assert Enum.any?(
             invalid_activity_state_source_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_activity_state.timeline_id")
           )

    invalid_status_state =
      Timeline.activity_status_state(
        %{id: :obs_missing_type, status: :planned},
        %{id: :obs_missing_type, type: :observe, status: :completed}
      )

    invalid_status_manifest =
      CadenceImport.from_timeline_activity_status_state(invalid_status_state)

    assert %{
             "source_artifact_type" => "timeline_activity_status_state.v1",
             "source_artifact_id" => "timeline:invalid_activity_input:obs_missing_type",
             "row_count" => 1,
             "review_required_count" => 1
           } = invalid_status_manifest

    assert [
             %{
               "import_status" => "review_required_before_import",
               "source_review_action" => "review_activity_transition",
               "activity_id" => "obs_missing_type",
               "timeline_id" => "timeline:invalid_activity_input:obs_missing_type",
               "transition_decision" => "review",
               "invalid_activity_input" => true,
               "invalid_activity_input_count" => 1,
               "invalid_activity_input_reasons" => ["missing_activity_type"],
               "status_transition" => %{"transition_category" => "invalid_activity_input"},
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_status_state.v1",
                 "invalid_activity_input" => true,
                 "invalid_activity_input_count" => 1,
                 "invalid_activity_input_reasons" => ["missing_activity_type"]
               },
               "source_review_row" => %{
                 "invalid_activity_input" => true,
                 "invalid_activity_input_count" => 1,
                 "source_timeline_lifecycle_state" => %{
                   "invalid_activity_input" => true,
                   "invalid_activity_input_count" => 1
                 }
               }
             }
           ] = invalid_status_manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(invalid_status_manifest)

    invalid_approval_state =
      Timeline.activity_approval_state(
        %{id: :cmd_missing_type, type: :command, approval_status: :pending},
        %{id: :cmd_missing_type, approval_status: :approved}
      )

    invalid_approval_manifest =
      CadenceImport.from_timeline_activity_approval_state(invalid_approval_state)

    assert [
             %{
               "source_review_action" => "review_activity_approval",
               "invalid_activity_input" => true,
               "invalid_activity_input_count" => 1,
               "invalid_activity_input_reasons" => ["missing_activity_type"],
               "approval_transition" => %{"transition_category" => "invalid_activity_input"},
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_approval_state.v1",
                 "invalid_activity_input" => true
               }
             }
           ] = invalid_approval_manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(invalid_approval_manifest)

    invalid_lifecycle_state =
      Timeline.activity_lifecycle_state(
        %{id: :cmd_lifecycle_missing_type, status: :planned, approval_status: :pending},
        nil
      )

    invalid_lifecycle_manifest =
      CadenceImport.from_timeline_activity_lifecycle_state(invalid_lifecycle_state)

    assert [
             %{
               "source_review_action" => "review_activity_transition",
               "invalid_activity_input" => true,
               "invalid_activity_input_count" => 1,
               "invalid_activity_input_reasons" => ["missing_activity_type"],
               "source_timeline_lifecycle_state" => %{
                 "schema_contract" => "timeline_activity_lifecycle_state.v1",
                 "invalid_activity_input" => true,
                 "invalid_activity_input_count" => 1
               }
             }
           ] = invalid_lifecycle_manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(invalid_lifecycle_manifest)
  end

  test "timeline preservation artifacts become import manifest rows" do
    activities = [
      %{id: :cmd_mutable, type: :command, status: :planned, approval_status: :pending},
      %{id: :contact_locked, type: :planned_contact, locked: true, approval_status: :pending},
      %{id: :obs_done, type: :observe, status: :completed},
      %{id: :bad_missing_type, status: :planned}
    ]

    report = Timeline.preservation_report(activities, source: "selected_activities")
    manifest = CadenceImport.from_timeline_preservation_report(report)

    atom_key_artifact = fn artifact ->
      artifact
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()
    end

    atom_key_report = atom_key_artifact.(report)

    assert %{
             "source_artifact_type" => "timeline_preservation_report.v1",
             "source_artifact_id" => "selected_activities",
             "row_count" => 3,
             "ready_count" => 2,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_timeline_preservation" => 3},
             "source_review_type_counts" => %{"timeline_preservation_review" => 3}
           } = manifest

    assert [
             %{
               "import_action" => "review_timeline_preservation",
               "import_status" => "ready_for_import",
               "source_review_type" => "timeline_preservation_review",
               "source_review_action" => "record_timeline_preservation",
               "activity_id" => "contact_locked",
               "timeline_preservation_status" => "preservation_required",
               "requires_preservation" => true,
               "requires_operator_review" => false,
               "timeline_preservation_protection_decision" => "preserve",
               "source_preservation_protection_category_counts" => %{
                 "executed" => 1,
                 "invalid_activity_input" => 1,
                 "locked_or_approved" => 1,
                 "none" => 1
               },
               "source_preservation_activity_id_sets_by_protection_category" => %{
                 "executed" => ["obs_done"],
                 "invalid_activity_input" => ["bad_missing_type"],
                 "locked_or_approved" => ["contact_locked"],
                 "none" => ["cmd_mutable"]
               },
               "source_preservation_timeline_id_sets_by_protection_category" => %{
                 "executed" => ["timeline:observe"],
                 "invalid_activity_input" => ["timeline:invalid_activity_input:bad_missing_type"],
                 "locked_or_approved" => ["timeline:planned_contact"],
                 "none" => ["timeline:command"]
               },
               "source_timeline_preservation" => %{
                 "activity_id" => "contact_locked",
                 "protection_decision" => "preserve"
               }
             },
             %{
               "activity_id" => "obs_done",
               "import_status" => "ready_for_import",
               "source_review_action" => "record_timeline_preservation"
             },
             %{
               "activity_id" => "bad_missing_type",
               "import_status" => "review_required_before_import",
               "source_review_action" => "review_timeline_preservation",
               "timeline_preservation_status" => "review_required",
               "requires_operator_review" => true,
               "invalid_activity_input" => true
             }
           ] = manifest["rows"]

    assert CadenceImport.manifest(report) == manifest
    assert CadenceImport.manifest(Map.delete(report, "schema_contract")) == manifest
    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(report, "schema_contract")) ==
             manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_report) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(atom_key_report, :schema_contract)) ==
             manifest

    status = Timeline.preservation_status(%{id: :bad_missing_type, status: :planned})
    status_manifest = CadenceImport.from_timeline_preservation_status(status)
    atom_key_status = atom_key_artifact.(status)

    assert %{
             "source_artifact_type" => "timeline_preservation_status.v1",
             "source_artifact_id" => "timeline:invalid_activity_input:bad_missing_type",
             "row_count" => 1,
             "review_required_count" => 1
           } = status_manifest

    assert CadenceImport.manifest(status) == status_manifest
    assert CadenceImport.manifest(Map.delete(status, "schema_contract")) == status_manifest
    assert OrbitalDynamics.cadence_import_manifest(status) == status_manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(status, "schema_contract")) ==
             status_manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_status) == status_manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(atom_key_status, :schema_contract)) ==
             status_manifest

    assert get_in(manifest, [
             "rows",
             Access.at(0),
             "source_review_row",
             "source_timeline_preservation",
             "activity_id"
           ]) == "contact_locked"

    assert get_in(manifest, [
             "rows",
             Access.at(0),
             "source_review_row",
             "source_preservation_activity_id_sets_by_protection_category",
             "locked_or_approved"
           ]) == ["contact_locked"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(status_manifest)

    invalid_source_preservation =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_timeline_preservation", "activity_id"],
        "bad activity id"
      )

    assert {:error, invalid_source_preservation_report} =
             Schema.validate_artifact(invalid_source_preservation)

    assert Enum.any?(
             invalid_source_preservation_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_preservation.activity_id")
           )

    invalid_nested_source_preservation =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_preservation",
          "activity_id"
        ],
        "bad activity id"
      )

    assert {:error, invalid_nested_source_preservation_report} =
             Schema.validate_artifact(invalid_nested_source_preservation)

    assert Enum.any?(
             invalid_nested_source_preservation_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_preservation.activity_id")
           )

    stale_nested_source_preservation =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_preservation",
          "activity_id"
        ],
        "stale_contact_locked"
      )

    assert {:error, stale_nested_source_preservation_report} =
             Schema.validate_artifact(stale_nested_source_preservation)

    assert Enum.any?(
             stale_nested_source_preservation_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_timeline_preservation" and
                 &1["message"] ==
                   "must match source_timeline_preservation on Cadence import row")
           )
  end

  test "timeline integrity reports become import manifest rows" do
    report = timeline_integrity_report()
    manifest = CadenceImport.from_timeline_integrity_report(report)

    atom_key_report =
      report
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_integrity_report.v1",
             "source_artifact_id" => "selected_activities",
             "row_count" => 2,
             "ready_count" => 0,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_timeline_integrity" => 2},
             "source_review_type_counts" => %{"timeline_integrity_review" => 2}
           } = manifest

    assert [
             %{
               "import_action" => "review_timeline_integrity",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_integrity_review",
               "source_review_action" => "review_timeline_integrity",
               "activity_id" => "dl_conflict",
               "timeline_id" => "timeline:downlink:12.0",
               "timeline_integrity_issue_types" => [
                 "duplicate_exclusivity_timeline",
                 "exclusivity_overlap"
               ],
               "exclusivity_violation_activity_ids" => ["cmd_main"],
               "exclusivity_violation_timeline_ids" => ["timeline:command:dss_14:10.0"],
               "duplicate_exclusivity_timeline_ids" => ["timeline:command:dss_14:10.0"],
               "source_timeline_integrity_issue_count" => 11,
               "source_timeline_integrity" => %{
                 "activity_id" => "dl_conflict",
                 "exclusivity_violation_timeline_ids" => ["timeline:command:dss_14:10.0"],
                 "duplicate_exclusivity_timeline_ids" => ["timeline:command:dss_14:10.0"]
               },
               "source_review_row" => %{
                 "source_timeline_integrity" => %{
                   "activity_id" => "dl_conflict",
                   "timeline_integrity_status" => "review_required",
                   "exclusivity_violation_timeline_ids" => ["timeline:command:dss_14:10.0"],
                   "duplicate_exclusivity_timeline_ids" => ["timeline:command:dss_14:10.0"]
                 }
               }
             },
             %{
               "activity_id" => "cmd_main",
               "timeline_id" => "timeline:command:dss_14:10.0",
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
               },
               "source_review_row" => %{
                 "source_timeline_integrity" => %{
                   "activity_template" => %{
                     "id" => "template:command:basic",
                     "activity_type" => "command"
                   }
                 }
               }
             }
           ] = manifest["rows"]

    assert "missing_dependency_activity" in hd(tl(manifest["rows"]))[
             "timeline_integrity_issue_types"
           ]

    assert CadenceImport.manifest(report) == manifest
    assert CadenceImport.manifest(atom_key_report) == manifest
    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(report, "schema_contract")) ==
             manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_report) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(atom_key_report, :schema_contract)) ==
             manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_integrity =
      put_in(
        manifest,
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

    invalid_review_source_integrity =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_integrity",
          "timeline_integrity_issue_types"
        ],
        []
      )

    assert {:error, invalid_review_source_integrity_report} =
             Schema.validate_artifact(invalid_review_source_integrity)

    assert Enum.any?(
             invalid_review_source_integrity_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_integrity.timeline_integrity_issue_types")
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

  test "uses typed import action for preserved executed plan deltas" do
    package = %{
      "schema_contract" => "operator_review_package.v1",
      "model" => "artifact_only_operator_review_package",
      "source_artifact_type" => "campaign_repair.v2",
      "source_artifact_id" => "repair:preserved_executed",
      "review_count" => 1,
      "approval_requirement_count" => 0,
      "contention_recommendation_count" => 0,
      "realized_feedback_count" => 0,
      "warning_count" => 0,
      "risk_count" => 0,
      "recommendation_count" => 0,
      "rows" => [
        %{
          "id" => "plan_delta:partial_dl:preserved_executed:1",
          "rank" => 1,
          "review_type" => "plan_delta_review",
          "source" => "campaign_repair.deltas",
          "subject_id" => "partial_dl",
          "activity_id" => "partial_dl",
          "activity_type" => "downlink",
          "action" => "record_preserved_executed_item",
          "required_operator_action" => "record_preserved_executed_item",
          "approval_status" => "not_required",
          "repair_action" => "preserved_executed",
          "source_cadence_import_status" => "present",
          "source_cadence_import_type" => "contact",
          "source_cadence_import_id" => "partial_dl",
          "source_cadence_import_contract" => "proposed_contact.v1",
          "source_has_cadence_import" => true,
          "source_delta" => %{
            "schema_contract" => "plan_delta.v1",
            "realized" => %{"status" => "partial", "completed_fraction" => 0.5}
          }
        }
      ],
      "provenance" => %{},
      "assumptions" => %{}
    }

    manifest = CadenceImport.from_operator_review_package(package)

    assert %{
             "row_count" => 1,
             "ready_count" => 1,
             "rows" => [
               %{
                 "import_action" => "record_preserved_executed_activity",
                 "import_status" => "ready_for_import",
                 "repair_action" => "preserved_executed",
                 "source_review_action" => "record_preserved_executed_item",
                 "source_delta" => %{
                   "realized" => %{"completed_fraction" => 0.5}
                 }
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "schema validation rejects inconsistent manifest counts" do
    manifest =
      CadenceImport.from_operator_review_package(%{
        "schema_contract" => "operator_review_package.v1",
        "source_artifact_type" => "campaign_repair.v2",
        "source_artifact_id" => "repair:manifest_count",
        "review_count" => 0,
        "rows" => []
      })

    invalid = Map.put(manifest, "row_count", 99)

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.row_count"))
  end

  test "schema validation rejects unsupported manifest source artifact types" do
    manifest =
      CadenceImport.from_operator_review_package(%{
        "schema_contract" => "operator_review_package.v1",
        "source_artifact_type" => "campaign_repair.v2",
        "source_artifact_id" => "repair:manifest_source",
        "review_count" => 0,
        "rows" => []
      })

    invalid = Map.put(manifest, "source_artifact_type", "provider_custom.v1")

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.source_artifact_type" and &1["message"] =~ "must be one of")
           )
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

  defp score_term_report do
    %{
      "schema_contract" => "score_term_report.v1",
      "model" => "ranked_timeline_score_terms",
      "source" => "campaign_plan.score_terms",
      "row_count" => 2,
      "score_term_keys" => ["target_value", "activity_count_penalty"],
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
      "score_term_keys" => ["target_value", "activity_count_penalty"],
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

  defp schema_validation_batch_report do
    failing_report = schema_validation_report()

    passing_report =
      Map.merge(failing_report, %{
        "validated_contract" => "candidate_refresh.v1",
        "validated_artifact_family" => "candidate_refresh",
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 0,
        "errors" => [],
        "warnings" => [],
        "artifact_path" => "study_results/candidate_refresh_v1.json",
        "remediation_count" => 0,
        "remediation" => []
      })

    %{
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
  end

  defp cadence_supported_source_fixtures do
    %{
      "campaign_plan.v1" => {:path, "study_results/leo_constellation_campaign.json"},
      "campaign_repair.v2" => {:path, "study_results/leo_constellation_campaign_repair_v2.json"},
      "campaign_strategy.v3" =>
        {:path, "study_results/leo_constellation_campaign_strategy_v3.json"},
      "candidate_refresh.v1" => {:path, "study_results/candidate_refresh_v1.json"},
      "proposed_contact.v1" => {:path, "study_results/proposed_contact_v1.json"},
      "planned_activity.v1" => {:path, "study_results/planned_activity_v1.json"},
      "realized_activity.v1" => {:path, "study_results/realized_activity_v1.json"},
      "realized_state_snapshot.v1" => {:path, "study_results/realized_state_snapshot_v1.json"},
      "timeline_feedback_report.v1" => {:path, "study_results/timeline_feedback_report_v1.json"},
      "operational_timeline_report.v1" =>
        {:path, "study_results/operational_timeline_report_v1.json"},
      "contact_contention_report.v1" =>
        {:path, "study_results/contact_contention_report_v1.json"},
      "contact_contention_resolution_report.v1" =>
        {:path, "study_results/contact_contention_resolution_report_v1.json"},
      "command_window_report.v1" => {:path, "study_results/command_window_report_v1.json"},
      "station_calendar_report.v1" => {:path, "study_results/station_calendar_report_v1.json"},
      "station_reservation_report.v1" => {:artifact, station_reservation_report()},
      "link_capacity_report.v1" => {:path, "study_results/link_capacity_report_v1.json"},
      "contact_allocation_report.v1" =>
        {:path, "study_results/contact_allocation_report_v1.json"},
      "contact_allocation_capacity_pack_summary.v1" =>
        {:path, "study_results/contact_allocation_capacity_pack_summary_v1.json"},
      "contact_allocation_reservation_conflict_summary.v1" =>
        {:path, "study_results/contact_allocation_reservation_conflict_summary_v1.json"},
      "resource_projection_report.v1" =>
        {:path, "study_results/resource_projection_report_v1.json"},
      "resource_projection_flow_summary.v1" => {:artifact, resource_projection_flow_summary()},
      "contact_intent.v1" => {:path, "study_results/contact_intent_v1.json"},
      "contact_filter_report.v1" => {:path, "study_results/contact_filter_report_v1.json"},
      "candidate_rejection_report.v1" => {:artifact, candidate_rejection_report()},
      "provider_counteroffer_report.v1" => {:artifact, provider_counteroffer_report()},
      "candidate_diff_report.v1" => {:path, "study_results/candidate_diff_report_v1.json"},
      "invalidated_candidate.v1" => {:path, "study_results/invalidated_candidate_v1.json"},
      "resource_filter_report.v1" => {:path, "study_results/resource_filter_report_v1.json"},
      "freshness_report.v1" => {:path, "study_results/freshness_report_v1.json"},
      "refresh_budget_report.v1" => {:path, "study_results/refresh_budget_report_v1.json"},
      "constraint_report.v1" => {:path, "study_results/constraint_report_v1.json"},
      "objective_satisfaction_report.v1" =>
        {:path, "study_results/objective_satisfaction_report_v1.json"},
      "maneuver_recommendation.v1" => {:path, "study_results/maneuver_recommendation_v1.json"},
      "maneuver_execution_delta.v1" => {:path, "study_results/maneuver_execution_delta_v1.json"},
      "maneuver_review_report.v1" => {:path, "study_results/maneuver_review_report_v1.json"},
      "timeline_diff_report.v1" => {:path, "study_results/timeline_diff_report_v1.json"},
      "timeline_diff_summary.v1" => {:artifact, timeline_diff_summary()},
      "timeline_dependency_impact_summary.v1" =>
        {:artifact, timeline_dependency_impact_summary()},
      "timeline_publication_summary.v1" => {:artifact, timeline_publication_summary()},
      "timeline_activity_precondition_summary.v1" =>
        {:artifact, timeline_activity_precondition_summary()},
      "timeline_activity_state.v1" => {:artifact, timeline_activity_state()},
      "timeline_activity_status_state.v1" => {:artifact, timeline_activity_status_state()},
      "timeline_activity_approval_state.v1" => {:artifact, timeline_activity_approval_state()},
      "timeline_activity_lifecycle_state.v1" => {:artifact, timeline_activity_lifecycle_state()},
      "timeline_lifecycle_state_summary.v1" => {:artifact, timeline_lifecycle_state_summary()},
      "timeline_preservation_report.v1" => {:artifact, timeline_preservation_report()},
      "timeline_preservation_status.v1" => {:artifact, timeline_preservation_status()},
      "timeline_integrity_report.v1" => {:artifact, timeline_integrity_report()},
      "timeline_transition_application_summary.v1" =>
        {:artifact, timeline_transition_application_summary()},
      "timeline_transition_application_report.v1" =>
        {:path, "study_results/timeline_transition_application_report_v1.json"},
      "approval_requirement.v1" => {:path, "study_results/approval_requirement_v1.json"},
      "policy_decision.v1" => {:path, "study_results/policy_decision_v1.json"},
      "branch_comparison_report.v1" => {:path, "study_results/branch_comparison_report_v1.json"},
      "ranking_comparison_report.v1" =>
        {:path, "study_results/ranking_comparison_report_v1.json"},
      "score_term_report.v1" => {:path, "study_results/score_term_report_v1.json"},
      "objective_tradeoff_report.v1" =>
        {:path, "study_results/objective_tradeoff_report_v1.json"},
      "pareto_frontier_report.v1" => {:path, "study_results/pareto_frontier_report_v1.json"},
      "schema_validation_report.v1" => {:path, "study_results/schema_validation_report_v1.json"},
      "schema_validation_batch_report.v1" => {:artifact, schema_validation_batch_report()},
      "execution_report.v1" => {:path, "study_results/execution_report_v1.json"},
      "operational_readiness_report.v1" => {:artifact, operational_readiness_report()},
      "quality_gate_report.v1" => {:artifact, quality_gate_report()},
      "result_artifact.v1" => {:path, "study_results/ground_track_crossings.json"},
      "operator_review_package.v1" => {:path, "study_results/operator_review_package_v1.json"}
    }
  end

  defp timeline_dependency_impact_summary do
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

    Timeline.dependency_impact_summary(source, replacement)
  end

  defp timeline_publication_summary do
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

    Timeline.publication_summary(
      %{
        "schema_contract" => "operational_timeline_report.v1",
        "id" => "timeline:published_plan:v2"
      },
      publication_sequence: 7,
      publication_authority: :mission_operations,
      supersedes_artifact_ids: ["timeline:published_plan:v1"],
      downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
      dependency_impact_summary: Timeline.dependency_impact_summary(source, replacement),
      timeline_diff_summary: Timeline.diff_summary(source, replacement)
    )
  end

  defp timeline_activity_precondition_summary do
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
  end

  defp timeline_activity_status_state do
    {planned, realized} = timeline_activity_state_pair()
    Timeline.activity_status_state(planned, realized)
  end

  defp timeline_activity_state do
    {planned, realized} = timeline_activity_state_pair()
    OrbitalDynamics.timeline_activity_state(planned, realized)
  end

  defp timeline_activity_approval_state do
    {planned, realized} = timeline_activity_state_pair()
    Timeline.activity_approval_state(planned, realized)
  end

  defp timeline_activity_lifecycle_state do
    {planned, realized} = timeline_activity_state_pair()
    Timeline.activity_lifecycle_state(planned, realized)
  end

  defp timeline_preservation_report do
    Timeline.preservation_report(
      [
        %{id: :cmd_mutable, type: :command, status: :planned, approval_status: :pending},
        %{id: :contact_locked, type: :planned_contact, locked: true, approval_status: :pending},
        %{id: :bad_missing_type, status: :planned}
      ],
      source: "selected_activities"
    )
  end

  defp timeline_preservation_status do
    Timeline.preservation_status(%{id: :bad_missing_type, status: :planned})
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

  defp timeline_activity_state_pair do
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

    {planned, realized}
  end

  defp timeline_lifecycle_state_summary do
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

    Timeline.lifecycle_state_summary(planned, realized)
  end

  defp operational_readiness_gate_summary do
    operational_readiness_resource_report()
    |> OrbitalDynamics.operational_readiness_gate_summary()
  end

  defp operational_execution_boundary_summary do
    operational_readiness_resource_report()
    |> OrbitalDynamics.operational_execution_boundary_summary()
  end

  defp operational_import_eligibility_summary do
    %{
      "schema_contract" => "operational_import_eligibility_summary.v1",
      "model" => "artifact_only_import_eligibility_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "import_eligible" => false,
      "gate_count" => 5,
      "passed_gate_count" => 2,
      "review_gate_count" => 1,
      "analysis_gate_count" => 1,
      "blocked_gate_count" => 1,
      "non_passed_gate_count" => 3,
      "non_passed_gates" => [
        %{"id" => "operational_mode"},
        %{"id" => "operator_review"},
        %{"id" => "cadence_import"}
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "operational_import_eligibility_summary_routes_only",
        "operational_import_eligibility_summary_does_not_approve_or_import"
      ],
      "provenance" => %{"trust_boundary" => "ops_import_eligibility_summary"}
    }
  end

  defp operational_quality_gate_summary do
    operational_readiness_resource_report()
    |> OrbitalDynamics.operational_quality_gate_report()
    |> OrbitalDynamics.operational_quality_gate_summary()
  end

  defp quality_gate_report do
    operational_readiness_resource_report()
    |> OrbitalDynamics.operational_quality_gate_report()
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

  defp candidate_rejection_report do
    OrbitalDynamics.candidate_rejection_report(
      [
        %{
          id: :dl_reserved,
          type: :downlink,
          ground_station_id: :dss_14,
          station_availability: "Reservation Hold",
          starts_at_s: 30.0,
          ends_at_s: 35.0,
          min_duration_s: 10.0
        }
      ],
      source: :candidate_refresh
    )
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

  defp station_reservation_report do
    OrbitalDynamics.station_reservation_report(%{
      "schema_contract" => "station_calendar_report.v1",
      "affected_contacts" => [
        %{
          "contact_id" => "dl_reserved",
          "ground_station_id" => "dss_14",
          "source_station_calendar_entry" => %{
            "id" => "calendar_reserved_1",
            "availability" => "Reserved",
            "reservation_id" => "reservation_1",
            "reservation_status" => "Held",
            "reservation_match_status" => "Overlap"
          }
        }
      ],
      "provider_calendar_contention_groups" => []
    })
  end

  defp operational_readiness_report do
    %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => "operational_readiness:planned_activity.v1:activity_1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "readiness_level" => "import_eligible",
      "import_classification" => "importable",
      "status" => "passed",
      "gate_count" => 4,
      "passed_gate_count" => 4,
      "review_gate_count" => 0,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gates" => [
        %{
          "id" => "source_contract",
          "status" => "passed",
          "classification" => "importable",
          "reason" => "source contract is supported"
        }
      ],
      "evidence" => %{
        "source_row_count" => 1,
        "review_required_count" => 0,
        "ready_for_import_count" => 1,
        "blocked_import_count" => 0,
        "missing_cadence_import_count" => 0,
        "invalid_cadence_import_count" => 0
      },
      "assumptions" => %{"not_for_execution" => false},
      "model_limits" => ["artifact_only", "does_not_write_cadence"]
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
        "analysis_mode_source" => "cadence_import_fixture"
      })
    end)
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

  defp cadence_supported_source_fixture!(fixtures, source) do
    case Map.fetch!(fixtures, source) do
      {:path, path} -> read_json!(path)
      {:artifact, artifact} -> artifact
    end
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
