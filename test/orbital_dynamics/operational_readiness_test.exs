defmodule OrbitalDynamics.OperationalReadinessTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.Communications.StationCalendar
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.OperationalReadiness
  alias OrbitalDynamics.ResourceProjection
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Timeline

  test "declares artifact-only readiness capability metadata" do
    capabilities = OperationalReadiness.capabilities()

    assert %{
             artifact_contract: "operational_readiness_report.v1",
             model: :artifact_only_operational_readiness_classifier,
             import_eligibility_summary_artifact_contract:
               "operational_import_eligibility_summary.v1",
             gate_summary_artifact_contract: "operational_readiness_gate_summary.v1",
             execution_boundary_summary_artifact_contract:
               "operational_execution_boundary_summary.v1",
             quality_gate_summary_artifact_contract: "operational_quality_gate_summary.v1",
             quality_gate_unavailable_resource_summary_artifact_contract:
               "operational_quality_gate_unavailable_resource_summary.v1",
             quality_gate_operator_training_summary_artifact_contract:
               "operational_quality_gate_operator_training_summary.v1",
             quality_gate_schema_validation_summary_artifact_contract:
               "operational_quality_gate_schema_validation_summary.v1",
             quality_gate_import_readiness_summary_artifact_contract:
               "operational_quality_gate_import_readiness_summary.v1",
             import_classifications: classifications,
             readiness_levels: readiness_levels,
             gate_statuses: gate_statuses,
             analysis_modes: analysis_modes,
             analysis_mode_aliases: analysis_mode_aliases,
             gates: gates,
             readiness_helpers: readiness_helpers,
             summary_semantics: summary_semantics,
             readiness_evidence_semantics: readiness_evidence_semantics,
             quality_gate_row_semantics: quality_gate_row_semantics,
             public_facades: public_facades,
             handoff_artifacts: handoff_artifacts,
             handoff_review_type: "operational_readiness_review",
             handoff_import_action: "review_operational_readiness",
             known_limits: known_limits
           } = capabilities

    assert classifications == ["importable", "review_only", "analysis_only", "blocked"]
    assert readiness_levels == ["import_eligible", "operator_review", "analysis_only", "blocked"]

    assert analysis_modes == [
             "analysis_only",
             "simulation",
             "rehearsal",
             "trade_study",
             "training",
             "not_for_execution"
           ]

    assert analysis_mode_aliases["analysis"] == "analysis_only"
    assert analysis_mode_aliases["sim"] == "simulation"
    assert analysis_mode_aliases["tradeoff"] == "trade_study"
    assert analysis_mode_aliases["no_execution"] == "not_for_execution"

    assert "review_required" in gate_statuses

    assert gates == [
             "source_contract",
             "operational_mode",
             "adapter_boundary",
             "mission_policy",
             "operator_training",
             "resource_availability",
             "operator_review",
             "cadence_import"
           ]

    assert readiness_helpers == [
             :report,
             :import_eligibility,
             :gate_summary,
             :execution_boundary_summary,
             :quality_gate_report,
             :quality_gate_summary,
             :quality_gate_unavailable_resource_summary,
             :quality_gate_operator_training_summary,
             :quality_gate_schema_validation_summary,
             :quality_gate_import_readiness_summary
           ]

    assert :gate_status_routing_id_sets in summary_semantics
    assert :gate_classification_routing_id_sets in summary_semantics
    assert :readiness_summary_row_derived_gate_counts in summary_semantics
    assert :quality_gate_report_routing_id_sets in summary_semantics
    assert :quality_gate_report_row_derived_classification in summary_semantics
    assert :quality_gate_report_execution_boundary in summary_semantics
    assert :quality_gate_summary in summary_semantics
    assert :quality_gate_summary_row_derived_counts in summary_semantics
    assert :quality_gate_resource_availability_row_context in summary_semantics
    assert :quality_gate_unavailable_resource_summary in summary_semantics
    assert :quality_gate_unavailable_resource_routing_id_sets in summary_semantics
    assert :quality_gate_operator_training_summary in summary_semantics
    assert :quality_gate_operator_training_routing_id_sets in summary_semantics
    assert :quality_gate_schema_validation_summary in summary_semantics
    assert :quality_gate_schema_validation_routing_id_sets in summary_semantics
    assert :quality_gate_import_readiness_summary in summary_semantics
    assert :quality_gate_import_readiness_routing_id_sets in summary_semantics
    assert :resource_availability_quality_gate in summary_semantics

    assert :readiness_freshness_status_count_maps in readiness_evidence_semantics
    assert :readiness_schema_validation_status_and_issue_counts in readiness_evidence_semantics
    assert :readiness_mission_policy_classification_count_maps in readiness_evidence_semantics
    assert :readiness_operator_training_requirement_count_maps in readiness_evidence_semantics
    assert :readiness_adapter_boundary_status_count_maps in readiness_evidence_semantics
    assert :readiness_adapter_boundary_untrusted_count_maps in readiness_evidence_semantics
    assert :readiness_resource_availability_reason_count_maps in readiness_evidence_semantics
    assert :readiness_resource_availability_reason_ids in readiness_evidence_semantics
    assert :readiness_unavailable_resource_reason_ids in readiness_evidence_semantics
    assert :readiness_station_availability_reason_count_maps in readiness_evidence_semantics

    assert :quality_gate_adapter_boundary_status_counts in quality_gate_row_semantics
    assert :quality_gate_operator_training_requirement_context in quality_gate_row_semantics
    assert :quality_gate_resource_availability_reason_ids in quality_gate_row_semantics
    assert :quality_gate_station_availability_reason_ids in quality_gate_row_semantics
    assert :quality_gate_unavailable_resource_reason_ids in quality_gate_row_semantics
    assert :quality_gate_resource_blocked_contact_id_maps in quality_gate_row_semantics
    assert :quality_gate_cadence_import_status_count_maps in quality_gate_row_semantics
    assert :quality_gate_freshness_status_count_maps in quality_gate_row_semantics
    assert :quality_gate_schema_validation_status_and_issue_counts in quality_gate_row_semantics

    assert public_facades == [
             :operational_readiness_report,
             :operational_import_eligibility,
             :operational_readiness_gate_summary,
             :operational_execution_boundary_summary,
             :operational_quality_gate_report,
             :operational_quality_gate_summary,
             :operational_quality_gate_unavailable_resource_summary,
             :operational_quality_gate_operator_training_summary,
             :operational_quality_gate_schema_validation_summary,
             :operational_quality_gate_import_readiness_summary
           ]

    assert capabilities.quality_gate_contract == "quality_gate_report.v1"
    assert handoff_artifacts == ["operator_review_package.v1", "cadence_import_manifest.v1"]
    assert :does_not_write_cadence in known_limits

    assert OrbitalDynamics.capability_catalog().operations.operational_readiness.public_facades ==
             public_facades

    assert {:ok, schema} = Schema.json_schema("operational_readiness_report.v1")
    assert get_in(schema, ["properties", "import_classification", "enum"]) == classifications
    assert get_in(schema, ["properties", "readiness_level", "enum"]) == readiness_levels
    expected_model_limits = Enum.map(known_limits, &Atom.to_string/1)

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             expected_model_limits

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             expected_model_limits

    assert {:ok, import_eligibility_schema} =
             Schema.json_schema("operational_import_eligibility_summary.v1")

    assert get_in(import_eligibility_schema, ["properties", "schema_contract", "const"]) ==
             "operational_import_eligibility_summary.v1"

    assert get_in(schema, [
             "properties",
             "gates",
             "items",
             "properties",
             "analysis_mode",
             "enum"
           ]) == analysis_modes
  end

  test "classifies ready Cadence import evidence as importable" do
    report = OperationalReadiness.report(ready_manifest())

    assert OrbitalDynamics.operational_readiness_report(ready_manifest()) == report

    assert %{
             "schema_contract" => "operational_readiness_report.v1",
             "model" => "artifact_only_operational_readiness_classifier",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "readiness_level" => "import_eligible",
             "import_classification" => "importable",
             "status" => "passed",
             "gate_count" => 5,
             "passed_gate_count" => 5,
             "review_gate_count" => 0,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "evidence" => %{
               "ready_for_import_count" => 1,
               "review_required_count" => 0,
               "blocked_import_count" => 0,
               "invalid_cadence_import_count" => 0,
               "adapter_context_count" => 0,
               "adapter_trust_boundary_declared_count" => 0,
               "adapter_trust_boundary_missing_count" => 0,
               "adapter_boundary_status_counts" => %{}
             }
           } = report

    assert Enum.map(report["gates"], & &1["id"]) == [
             "source_contract",
             "operational_mode",
             "adapter_boundary",
             "operator_review",
             "cadence_import"
           ]

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(report)

    stale_model = Map.put(report, "model", "stale_operational_readiness_model")

    assert {:error, stale_model_report} = Schema.validate_artifact(stale_model)

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_operational_readiness_classifier\"")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_only"])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match operational readiness model limits")
           )
  end

  test "builds compact import eligibility summaries from readiness reports" do
    importable = OperationalReadiness.import_eligibility(ready_manifest())

    assert %{
             "schema_contract" => "operational_import_eligibility_summary.v1",
             "model" => "artifact_only_import_eligibility_summary",
             "source" => "operational_readiness_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "readiness_level" => "import_eligible",
             "import_classification" => "importable",
             "status" => "passed",
             "import_eligible" => true,
             "gate_count" => 5,
             "passed_gate_count" => 5,
             "non_passed_gate_count" => 0,
             "non_passed_gates" => [],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_summary"
             },
             "model_limits" => [
               "operational_import_eligibility_summary_routes_only",
               "operational_import_eligibility_summary_does_not_approve_or_import"
             ]
           } = importable

    assert OrbitalDynamics.operational_import_eligibility(ready_manifest()) == importable

    assert {:ok, %{"schema_contract" => "operational_import_eligibility_summary.v1"}} =
             Schema.validate_artifact(importable)

    assert {:ok, import_eligibility_schema} =
             Schema.json_schema("operational_import_eligibility_summary.v1")

    assert get_in(import_eligibility_schema, ["properties", "model", "const"]) ==
             "artifact_only_import_eligibility_summary"

    assert get_in(import_eligibility_schema, ["properties", "model_limits", "const"]) ==
             importable["model_limits"]

    stale_model_limits =
      Map.put(importable, "model_limits", [
        "operational_import_eligibility_summary_routes_only"
      ])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] ==
                   "must match operational import eligibility summary model limits")
           )

    stale_gate_count = Map.put(importable, "gate_count", 99)

    assert {:error, stale_gate_count_report} = Schema.validate_artifact(stale_gate_count)

    assert Enum.any?(
             stale_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count" and &1["message"] == "must equal gate status counts")
           )

    stale_report_counts =
      ready_manifest()
      |> OperationalReadiness.report()
      |> Map.merge(%{
        "gate_count" => 99,
        "passed_gate_count" => 99,
        "review_gate_count" => 99,
        "analysis_gate_count" => 99,
        "blocked_gate_count" => 99
      })

    assert %{
             "gate_count" => 5,
             "passed_gate_count" => 5,
             "review_gate_count" => 0,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "non_passed_gate_count" => 0
           } = OperationalReadiness.import_eligibility(stale_report_counts)

    review_only = OperationalReadiness.import_eligibility(review_required_manifest())

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "import_eligible" => false,
             "review_gate_count" => 1,
             "non_passed_gate_count" => 1,
             "non_passed_gates" => non_passed_gates
           } = review_only

    assert Enum.map(non_passed_gates, & &1["id"]) == ["cadence_import"]

    assert {:ok, %{"schema_contract" => "operational_import_eligibility_summary.v1"}} =
             Schema.validate_artifact(review_only)

    stale_classification = Map.put(review_only, "import_classification", "importable")

    assert {:error, stale_classification_report} = Schema.validate_artifact(stale_classification)

    assert Enum.any?(
             stale_classification_report["errors"],
             &(&1["path"] == "$.import_classification" and
                 &1["message"] == "must match non-passed gate-derived import classification")
           )

    stale_non_passed_count = Map.put(review_only, "non_passed_gate_count", 0)

    assert {:error, stale_non_passed_count_report} =
             Schema.validate_artifact(stale_non_passed_count)

    assert Enum.any?(
             stale_non_passed_count_report["errors"],
             &(&1["path"] == "$.non_passed_gate_count" and
                 &1["message"] == "must equal review, analysis, and blocked gate counts")
           )

    analysis_only =
      ready_manifest()
      |> OperationalReadiness.report(not_for_execution: true)
      |> OperationalReadiness.import_eligibility()

    assert %{
             "import_classification" => "analysis_only",
             "import_eligible" => false,
             "analysis_gate_count" => 1,
             "non_passed_gates" => [%{"id" => "operational_mode"}]
           } = analysis_only
  end

  test "builds compact readiness gate summaries from reports and manifests" do
    analysis_report = OperationalReadiness.report(ready_manifest(), mode: :simulation)
    summary = OperationalReadiness.gate_summary(analysis_report)

    assert %{
             "schema_contract" => "operational_readiness_gate_summary.v1",
             "model" => "artifact_only_operational_readiness_gate_summary",
             "source" => "operational_readiness_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "gate_count" => 5,
             "passed_gate_count" => 4,
             "analysis_gate_count" => 1,
             "non_passed_gate_count" => 1,
             "gate_status_counts" => %{"analysis_only" => 1, "passed" => 4},
             "gate_classification_counts" => %{"analysis_only" => 1, "importable" => 4},
             "gate_ids_by_status" => %{
               "analysis_only" => ["operational_mode"],
               "passed" => [
                 "adapter_boundary",
                 "cadence_import",
                 "operator_review",
                 "source_contract"
               ]
             },
             "gate_ids_by_classification" => %{
               "analysis_only" => ["operational_mode"],
               "importable" => [
                 "adapter_boundary",
                 "cadence_import",
                 "operator_review",
                 "source_contract"
               ]
             },
             "analysis_only_gate_ids" => ["operational_mode"],
             "blocked_gate_ids" => [],
             "review_required_gate_ids" => [],
             "non_passed_gate_ids" => ["operational_mode"],
             "non_passed_gates" => [%{"id" => "operational_mode"}],
             "gates" => gates,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_summary"
             },
             "model_limits" => [
               "operational_readiness_gate_summary_routes_only",
               "operational_readiness_gate_summary_does_not_approve_or_import"
             ]
           } = summary

    assert Enum.map(gates, & &1["id"]) == [
             "source_contract",
             "operational_mode",
             "adapter_boundary",
             "operator_review",
             "cadence_import"
           ]

    assert OrbitalDynamics.operational_readiness_gate_summary(analysis_report) == summary

    assert {:ok, %{"schema_contract" => "operational_readiness_gate_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, summary_schema} = Schema.json_schema("operational_readiness_gate_summary.v1")

    assert get_in(summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_operational_readiness_gate_summary"

    assert get_in(summary_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]

    stale_model_limits =
      Map.put(summary, "model_limits", ["operational_readiness_gate_summary_routes_only"])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] ==
                   "must match operational readiness gate summary model limits")
           )

    stale_gate_count = Map.put(summary, "gate_count", 99)

    assert {:error, stale_gate_count_report} = Schema.validate_artifact(stale_gate_count)

    assert Enum.any?(
             stale_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count" and &1["message"] == "must equal 5")
           )

    stale_classification = Map.put(summary, "import_classification", "importable")

    assert {:error, stale_classification_report} = Schema.validate_artifact(stale_classification)

    assert Enum.any?(
             stale_classification_report["errors"],
             &(&1["path"] == "$.import_classification" and
                 &1["message"] == "must match gate-derived import classification")
           )

    stale_id_map = put_in(summary, ["gate_ids_by_status", "analysis_only"], [])

    assert {:error, stale_id_map_report} = Schema.validate_artifact(stale_id_map)

    assert Enum.any?(
             stale_id_map_report["errors"],
             &(&1["path"] == "$.gate_ids_by_status" and
                 &1["message"] == "must match gate IDs grouped by status")
           )

    stale_report_counts =
      Map.merge(analysis_report, %{
        "gate_count" => 99,
        "passed_gate_count" => 99,
        "review_gate_count" => 99,
        "analysis_gate_count" => 99,
        "blocked_gate_count" => 99
      })

    assert %{
             "gate_count" => 5,
             "passed_gate_count" => 4,
             "review_gate_count" => 0,
             "analysis_gate_count" => 1,
             "blocked_gate_count" => 0,
             "non_passed_gate_count" => 1,
             "gate_status_counts" => %{"analysis_only" => 1, "passed" => 4}
           } = OperationalReadiness.gate_summary(stale_report_counts)

    review_summary = OperationalReadiness.gate_summary(review_required_manifest())

    assert %{
             "readiness_level" => "operator_review",
             "review_gate_count" => 1,
             "review_required_gate_ids" => ["cadence_import"],
             "non_passed_gate_ids" => ["cadence_import"]
           } = review_summary

    assert {:ok, %{"schema_contract" => "operational_readiness_gate_summary.v1"}} =
             Schema.validate_artifact(review_summary)
  end

  test "builds execution-boundary summaries for analysis-only readiness evidence" do
    summary =
      OperationalReadiness.execution_boundary_summary(ready_manifest(), mode: :trade_study)

    assert OrbitalDynamics.operational_execution_boundary_summary(ready_manifest(),
             mode: :trade_study
           ) == summary

    assert %{
             "schema_contract" => "operational_execution_boundary_summary.v1",
             "model" => "artifact_only_operational_execution_boundary_summary",
             "source" => "operational_readiness_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "import_eligible" => false,
             "handoff_only" => true,
             "execution_allowed" => false,
             "cadence_write_allowed" => false,
             "operator_authority_granted" => false,
             "execution_boundary" => "analysis_only_not_for_execution",
             "analysis_mode" => "trade_study",
             "analysis_mode_source" => "opts.mode",
             "gate_count" => 5,
             "passed_gate_count" => 4,
             "review_gate_count" => 0,
             "analysis_gate_count" => 1,
             "blocked_gate_count" => 0,
             "non_passed_gate_ids" => ["operational_mode"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write_no_command_execution",
               "operator_authority" => "not_granted_by_execution_boundary_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             },
             "model_limits" => [
               "operational_execution_boundary_summary_routes_only",
               "operational_execution_boundary_summary_does_not_execute_or_import"
             ],
             "operational_mode_gate" => %{
               "id" => "operational_mode",
               "status" => "analysis_only",
               "classification" => "analysis_only",
               "analysis_mode" => "trade_study"
             }
           } = summary

    assert {:ok, %{"schema_contract" => "operational_execution_boundary_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, execution_boundary_schema} =
             Schema.json_schema("operational_execution_boundary_summary.v1")

    assert get_in(execution_boundary_schema, ["properties", "model", "const"]) ==
             "artifact_only_operational_execution_boundary_summary"

    assert get_in(execution_boundary_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]

    stale_model_limits =
      Map.put(summary, "model_limits", [
        "operational_execution_boundary_summary_routes_only"
      ])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] ==
                   "must match operational execution boundary summary model limits")
           )

    stale_gate_count = Map.put(summary, "gate_count", 99)

    assert {:error, stale_gate_count_report} = Schema.validate_artifact(stale_gate_count)

    assert Enum.any?(
             stale_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count" and &1["message"] == "must equal gate status counts")
           )

    stale_analysis_mode = Map.put(summary, "analysis_mode", "simulation")

    assert {:error, stale_analysis_mode_report} = Schema.validate_artifact(stale_analysis_mode)

    assert Enum.any?(
             stale_analysis_mode_report["errors"],
             &(&1["path"] == "$.analysis_mode" and
                 &1["message"] == "must match operational_mode_gate.analysis_mode")
           )

    stale_report_counts =
      ready_manifest()
      |> OperationalReadiness.report(mode: :trade_study)
      |> Map.merge(%{
        "gate_count" => 99,
        "passed_gate_count" => 99,
        "review_gate_count" => 99,
        "analysis_gate_count" => 99,
        "blocked_gate_count" => 99
      })

    assert %{
             "gate_count" => 5,
             "passed_gate_count" => 4,
             "review_gate_count" => 0,
             "analysis_gate_count" => 1,
             "blocked_gate_count" => 0,
             "non_passed_gate_count" => 1
           } = OperationalReadiness.execution_boundary_summary(stale_report_counts)
  end

  test "preserves not-for-execution marker source provenance across readiness summaries" do
    for {artifact, expected_source} <- [
          {
            ready_manifest()
            |> Map.put("not_for_execution", " YES "),
            "artifact.not_for_execution"
          },
          {
            ready_manifest()
            |> Map.put("metadata", %{"not_for_execution" => true}),
            "artifact.metadata.not_for_execution"
          },
          {
            ready_manifest()
            |> Map.put("assumptions", %{"not_for_execution" => "true"}),
            "artifact.assumptions.not_for_execution"
          },
          {
            ready_manifest()
            |> Map.put("metadata", %{"mode" => "tradeoff"}),
            "artifact mode"
          }
        ] do
      report = OperationalReadiness.report(artifact)
      gate_summary = OperationalReadiness.gate_summary(report)
      boundary_summary = OperationalReadiness.execution_boundary_summary(report)
      quality_gate_report = OperationalReadiness.quality_gate_report(report)

      assert %{
               "readiness_level" => "analysis_only",
               "import_classification" => "analysis_only",
               "analysis_gate_count" => 1,
               "gates" => [%{"id" => "source_contract"}, operational_mode_gate | _]
             } = report

      assert %{
               "id" => "operational_mode",
               "status" => "analysis_only",
               "classification" => "analysis_only",
               "analysis_mode_source" => ^expected_source
             } = operational_mode_gate

      assert gate_summary["non_passed_gates"] == [operational_mode_gate]
      assert boundary_summary["analysis_mode_source"] == expected_source
      assert boundary_summary["operational_mode_gate"] == operational_mode_gate

      assert [
               %{
                 "gate_id" => "operational_mode",
                 "analysis_mode_source" => ^expected_source,
                 "source_operational_readiness_gate" => ^operational_mode_gate
               }
             ] = Enum.filter(quality_gate_report["rows"], &(&1["gate_id"] == "operational_mode"))

      assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
               Schema.validate_artifact(report)

      assert {:ok, %{"schema_contract" => "operational_readiness_gate_summary.v1"}} =
               Schema.validate_artifact(gate_summary)

      assert {:ok, %{"schema_contract" => "operational_execution_boundary_summary.v1"}} =
               Schema.validate_artifact(boundary_summary)

      assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
               Schema.validate_artifact(quality_gate_report)
    end
  end

  test "execution-boundary summaries keep importable evidence as handoff only" do
    summary = OperationalReadiness.execution_boundary_summary(ready_manifest())

    assert %{
             "readiness_level" => "import_eligible",
             "import_classification" => "importable",
             "status" => "passed",
             "import_eligible" => true,
             "handoff_only" => true,
             "execution_allowed" => false,
             "cadence_write_allowed" => false,
             "operator_authority_granted" => false,
             "execution_boundary" => "adapter_handoff_only",
             "gate_count" => 5,
             "non_passed_gate_count" => 0,
             "non_passed_gate_ids" => [],
             "operational_mode_gate" => %{
               "id" => "operational_mode",
               "status" => "passed",
               "classification" => "importable"
             }
           } = summary

    refute Map.has_key?(summary, "analysis_mode")
    refute Map.has_key?(summary, "analysis_mode_source")
  end

  test "classifies review-required and blocked import evidence" do
    review_report =
      ready_manifest()
      |> put_in(["rows"], [
        %{
          "id" => "import_1",
          "rank" => 1,
          "import_action" => "review_operator_row",
          "import_status" => "review_required_before_import",
          "cadence_import_status" => "present"
        }
      ])
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "review_gate_count" => 1
           } = review_report

    blocked_report =
      ready_manifest()
      |> put_in(["rows"], [
        %{
          "id" => "import_1",
          "rank" => 1,
          "import_action" => "review_operator_row",
          "import_status" => "blocked_missing_cadence_import",
          "cadence_import_status" => "invalid"
        }
      ])
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "blocked",
             "import_classification" => "blocked",
             "status" => "blocked",
             "blocked_gate_count" => 1,
             "evidence" => %{
               "blocked_import_count" => 1,
               "invalid_cadence_import_count" => 1
             }
           } = blocked_report
  end

  test "not-for-execution inputs stay analysis only even with ready import rows" do
    report = OperationalReadiness.report(ready_manifest(), not_for_execution: true)

    assert %{
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "analysis_gate_count" => 1
           } = report

    assert %{
             "id" => "operational_mode",
             "status" => "analysis_only",
             "classification" => "analysis_only",
             "analysis_mode" => "not_for_execution",
             "analysis_mode_source" => "opts.not_for_execution"
           } = Enum.find(report["gates"], &(&1["id"] == "operational_mode"))

    artifact_report =
      ready_manifest()
      |> put_in(["metadata"], %{"not_for_execution" => " YES "})
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only"
           } = artifact_report

    assert %{
             "analysis_mode" => "not_for_execution",
             "analysis_mode_source" => "artifact.metadata.not_for_execution",
             "reason" => "artifact metadata marks the artifact not-for-execution"
           } = Enum.find(artifact_report["gates"], &(&1["id"] == "operational_mode"))

    assumptions_report =
      ready_manifest()
      |> put_in(["assumptions"], %{"not_for_execution" => "true"})
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only"
           } = assumptions_report

    assert %{
             "analysis_mode" => "not_for_execution",
             "analysis_mode_source" => "artifact.assumptions.not_for_execution",
             "reason" => "artifact assumptions mark the artifact not-for-execution"
           } = Enum.find(assumptions_report["gates"], &(&1["id"] == "operational_mode"))

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(assumptions_report)
  end

  test "operational-mode gates preserve normalized analysis mode evidence" do
    opts_report = OperationalReadiness.report(ready_manifest(), mode: :"Trade Study")

    assert %{
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only"
           } = opts_report

    assert %{
             "id" => "operational_mode",
             "status" => "analysis_only",
             "classification" => "analysis_only",
             "analysis_mode" => "trade_study",
             "analysis_mode_source" => "opts.mode",
             "reason" => "opts.mode marks the artifact trade_study"
           } = Enum.find(opts_report["gates"], &(&1["id"] == "operational_mode"))

    artifact_report =
      ready_manifest()
      |> put_in(["metadata"], %{"operational_mode" => "Rehearsal"})
      |> OperationalReadiness.report()

    assert %{
             "analysis_mode" => "rehearsal",
             "analysis_mode_source" => "artifact mode",
             "reason" => "artifact mode marks the artifact rehearsal"
           } = Enum.find(artifact_report["gates"], &(&1["id"] == "operational_mode"))

    alias_report = OperationalReadiness.report(ready_manifest(), operational_mode: "no execution")

    assert %{
             "analysis_mode" => "not_for_execution",
             "analysis_mode_source" => "opts.operational_mode",
             "reason" => "opts.operational_mode marks the artifact not_for_execution"
           } = Enum.find(alias_report["gates"], &(&1["id"] == "operational_mode"))

    invalid_gate =
      put_in(opts_report, ["gates", Access.at(1), "analysis_mode"], "flight_certified")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_gate)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.gates[1].analysis_mode")
           )
  end

  test "readiness reports produce deterministic operator-review handoff rows" do
    importable = OperationalReadiness.report(ready_manifest())
    review_only = OperationalReadiness.report(review_required_manifest())
    blocked = OperationalReadiness.report(blocked_manifest())

    assert_readiness_review_row(
      importable,
      "record_operational_readiness_importable",
      "auto_approvable"
    )

    assert_readiness_review_row(
      review_only,
      "review_operational_readiness",
      "operator_review_required"
    )

    assert_readiness_review_row(
      blocked,
      "review_blocked_operational_readiness",
      "blocked_by_policy"
    )
  end

  test "readiness reports produce Cadence import rows with classification evidence" do
    importable = OperationalReadiness.report(ready_manifest())
    review_only = OperationalReadiness.report(review_required_manifest())
    analysis_only = OperationalReadiness.report(ready_manifest(), not_for_execution: true)
    blocked = OperationalReadiness.report(blocked_manifest())

    assert_readiness_import_row(importable, "ready_for_import")
    assert_readiness_import_row(review_only, "review_required_before_import")
    assert_readiness_import_row(analysis_only, "not_applicable")
    assert_readiness_import_row(blocked, "review_required_before_import")
  end

  test "readiness handoffs emit review rows for non-passed gates" do
    report = OperationalReadiness.report(ready_manifest(), not_for_execution: true)

    package = OperatorReview.from_operational_readiness_report(report)

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "operational_readiness_report.gates",
             "action" => "record_operational_readiness_analysis_only",
             "approval_status" => "not_required",
             "cadence_import_status" => "not_applicable",
             "readiness_gate_id" => "operational_mode",
             "readiness_gate_status" => "analysis_only",
             "readiness_gate_classification" => "analysis_only",
             "analysis_mode" => "not_for_execution",
             "analysis_mode_source" => "opts.not_for_execution",
             "source_operational_readiness_gate" => %{
               "id" => "operational_mode",
               "status" => "analysis_only",
               "classification" => "analysis_only"
             }
           } = Enum.find(package["rows"], &(&1["readiness_gate_id"] == "operational_mode"))

    manifest = CadenceImport.from_operational_readiness_report(report)

    assert %{
             "import_action" => "review_operational_readiness",
             "import_status" => "not_applicable",
             "source_review_type" => "operational_readiness_review",
             "readiness_gate_id" => "operational_mode",
             "readiness_gate_status" => "analysis_only",
             "readiness_gate_classification" => "analysis_only",
             "analysis_mode" => "not_for_execution",
             "analysis_mode_source" => "opts.not_for_execution",
             "source_operational_readiness_gate" => %{
               "id" => "operational_mode",
               "status" => "analysis_only",
               "classification" => "analysis_only"
             }
           } = Enum.find(manifest["rows"], &(&1["readiness_gate_id"] == "operational_mode"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    stale_review_source_gate =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"source_operational_readiness_gate" => %{} = source_gate} = row ->
            Map.put(
              row,
              "source_operational_readiness_gate",
              Map.put(source_gate, "analysis_mode", "simulation")
            )

          row ->
            row
        end)
      end)

    assert {:error, stale_review_source_gate_report} =
             Schema.validate_artifact(stale_review_source_gate)

    assert Enum.any?(
             stale_review_source_gate_report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_operational_readiness_gate\.analysis_mode$/ and
                 &1["message"] == "must match analysis_mode on handoff row")
           )
  end

  test "untrusted adapter-boundary evidence flows into review and import handoffs" do
    report =
      ready_manifest()
      |> put_in(["rows", Access.at(0), "cadence_import_adapter"], "cadence_contact_adapter")
      |> put_in(["rows", Access.at(0), "cadence_import_trust_boundary"], "untrusted_external")
      |> OperationalReadiness.report()

    package = OperatorReview.from_operational_readiness_report(report)

    assert %{
             "approval_status" => "blocked_by_policy",
             "readiness_gate_id" => "adapter_boundary",
             "readiness_gate_status" => "blocked",
             "readiness_gate_classification" => "blocked",
             "adapter_context_count" => 1,
             "adapter_trust_boundary_untrusted_count" => 1,
             "adapter_boundary_status_counts" => %{"untrusted" => 1}
           } = Enum.find(package["rows"], &(&1["readiness_gate_id"] == "adapter_boundary"))

    manifest = CadenceImport.from_operational_readiness_report(report)

    assert %{
             "import_status" => "review_required_before_import",
             "readiness_gate_id" => "adapter_boundary",
             "readiness_gate_status" => "blocked",
             "readiness_gate_classification" => "blocked",
             "adapter_context_count" => 1,
             "adapter_trust_boundary_untrusted_count" => 1,
             "adapter_boundary_status_counts" => %{"untrusted" => 1}
           } = Enum.find(manifest["rows"], &(&1["readiness_gate_id"] == "adapter_boundary"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds standalone quality gate reports from readiness evidence" do
    readiness_report =
      ready_manifest()
      |> put_in(
        ["rows", Access.at(0), "source_policy_decision"],
        policy_decision("operator_review_required")
      )
      |> OperationalReadiness.report()

    report = OperationalReadiness.quality_gate_report(readiness_report)

    assert OrbitalDynamics.operational_quality_gate_report(readiness_report) == report
    assert OperationalReadiness.quality_gate_report(report) == report
    assert OrbitalDynamics.operational_quality_gate_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert OperationalReadiness.quality_gate_report(atom_keyed_report) == report
    assert OrbitalDynamics.operational_quality_gate_report(atom_keyed_report) == report

    assert %{
             "schema_contract" => "quality_gate_report.v1",
             "model" => "artifact_only_operational_quality_gate_report",
             "report_id" => "quality_gate:planned_activity.v1:activity_1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "source_readiness_report_id" =>
               "operational_readiness:planned_activity.v1:activity_1",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "handoff_only" => true,
             "execution_allowed" => false,
             "cadence_write_allowed" => false,
             "operator_authority_granted" => false,
             "execution_boundary" => "operator_review_required_before_import",
             "gate_count" => 6,
             "passed_gate_count" => 5,
             "review_gate_count" => 1,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "gate_status_counts" => %{"passed" => 5, "review_required" => 1},
             "gate_classification_counts" => %{"importable" => 5, "review_only" => 1},
             "gate_ids_by_status" => %{
               "passed" => [
                 "adapter_boundary",
                 "cadence_import",
                 "operational_mode",
                 "operator_review",
                 "source_contract"
               ],
               "review_required" => ["mission_policy"]
             },
             "gate_ids_by_classification" => %{
               "importable" => [
                 "adapter_boundary",
                 "cadence_import",
                 "operational_mode",
                 "operator_review",
                 "source_contract"
               ],
               "review_only" => ["mission_policy"]
             },
             "quality_gate_row_ids_by_status" => %{
               "passed" => [
                 "quality_gate:planned_activity.v1:activity_1:adapter_boundary:3",
                 "quality_gate:planned_activity.v1:activity_1:cadence_import:6",
                 "quality_gate:planned_activity.v1:activity_1:operational_mode:2",
                 "quality_gate:planned_activity.v1:activity_1:operator_review:5",
                 "quality_gate:planned_activity.v1:activity_1:source_contract:1"
               ],
               "review_required" => [
                 "quality_gate:planned_activity.v1:activity_1:mission_policy:4"
               ]
             },
             "quality_gate_row_ids_by_classification" => %{
               "importable" => [
                 "quality_gate:planned_activity.v1:activity_1:adapter_boundary:3",
                 "quality_gate:planned_activity.v1:activity_1:cadence_import:6",
                 "quality_gate:planned_activity.v1:activity_1:operational_mode:2",
                 "quality_gate:planned_activity.v1:activity_1:operator_review:5",
                 "quality_gate:planned_activity.v1:activity_1:source_contract:1"
               ],
               "review_only" => [
                 "quality_gate:planned_activity.v1:activity_1:mission_policy:4"
               ]
             },
             "passed_gate_ids" => [
               "adapter_boundary",
               "cadence_import",
               "operational_mode",
               "operator_review",
               "source_contract"
             ],
             "review_required_gate_ids" => ["mission_policy"],
             "analysis_only_gate_ids" => [],
             "blocked_gate_ids" => [],
             "model_limits" => [
               "quality_gate_report_derives_classification_from_gate_rows",
               "quality_gate_report_does_not_approve_or_import"
             ],
             "rows" => rows,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_quality_gate_report"
             }
           } = report

    expected_model_limits = [
      "quality_gate_report_derives_classification_from_gate_rows",
      "quality_gate_report_does_not_approve_or_import"
    ]

    assert report["model_limits"] == expected_model_limits

    assert {:ok, quality_gate_report_schema} = Schema.json_schema("quality_gate_report.v1")

    assert get_in(quality_gate_report_schema, ["properties", "model_limits", "const"]) ==
             expected_model_limits

    assert get_in(quality_gate_report_schema, ["properties", "model_limits", "items", "enum"]) ==
             expected_model_limits

    assert Enum.map(rows, & &1["gate_id"]) == [
             "source_contract",
             "operational_mode",
             "adapter_boundary",
             "mission_policy",
             "operator_review",
             "cadence_import"
           ]

    assert %{
             "id" => "quality_gate:planned_activity.v1:activity_1:mission_policy:4",
             "rank" => 4,
             "gate_id" => "mission_policy",
             "status" => "review_required",
             "classification" => "review_only",
             "source_operational_readiness_gate" => %{
               "id" => "mission_policy",
               "status" => "review_required"
             }
           } = Enum.find(rows, &(&1["gate_id"] == "mission_policy"))

    mission_policy_quality_gate_row_id =
      rows
      |> Enum.find(&(&1["gate_id"] == "mission_policy"))
      |> Map.fetch!("id")

    assert %{
             "schema_contract" => "operational_quality_gate_summary.v1",
             "model" => "artifact_only_quality_gate_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
             "source_readiness_report_id" =>
               "operational_readiness:planned_activity.v1:activity_1",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "handoff_only" => true,
             "execution_allowed" => false,
             "cadence_write_allowed" => false,
             "operator_authority_granted" => false,
             "execution_boundary" => "operator_review_required_before_import",
             "gate_count" => 6,
             "passed_gate_count" => 5,
             "review_gate_count" => 1,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "non_passed_gate_count" => 1,
             "gate_status_counts" => %{"passed" => 5, "review_required" => 1},
             "gate_classification_counts" => %{"importable" => 5, "review_only" => 1},
             "gate_ids_by_status" => %{
               "passed" => [
                 "adapter_boundary",
                 "cadence_import",
                 "operational_mode",
                 "operator_review",
                 "source_contract"
               ],
               "review_required" => ["mission_policy"]
             },
             "gate_ids_by_classification" => %{
               "importable" => [
                 "adapter_boundary",
                 "cadence_import",
                 "operational_mode",
                 "operator_review",
                 "source_contract"
               ],
               "review_only" => ["mission_policy"]
             },
             "quality_gate_row_ids_by_status" => %{
               "review_required" => [^mission_policy_quality_gate_row_id]
             },
             "quality_gate_row_ids_by_classification" => %{
               "review_only" => [^mission_policy_quality_gate_row_id]
             },
             "passed_gate_ids" => [
               "adapter_boundary",
               "cadence_import",
               "operational_mode",
               "operator_review",
               "source_contract"
             ],
             "review_required_gate_ids" => ["mission_policy"],
             "analysis_only_gate_ids" => [],
             "blocked_gate_ids" => [],
             "non_passed_gate_ids" => ["mission_policy"],
             "non_passed_quality_gate_row_ids" => [^mission_policy_quality_gate_row_id],
             "non_passed_rows" => [%{"gate_id" => "mission_policy"}],
             "rows" => ^rows,
             "assumptions" => %{
               "source" => "quality_gate_report.v1",
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_quality_gate_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             },
             "model_limits" => [
               "quality_gate_summary_derives_classification_from_gate_rows",
               "quality_gate_summary_does_not_approve_or_import"
             ]
           } = quality_gate_summary = OperationalReadiness.quality_gate_summary(report)

    assert OrbitalDynamics.operational_quality_gate_summary(report) == quality_gate_summary

    assert OrbitalDynamics.operational_quality_gate_summary(readiness_report) ==
             quality_gate_summary

    assert {:ok, %{"schema_contract" => "operational_quality_gate_summary.v1"}} =
             Schema.validate_artifact(quality_gate_summary)

    assert {:ok, quality_gate_summary_schema} =
             Schema.json_schema("operational_quality_gate_summary.v1")

    assert get_in(quality_gate_summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_quality_gate_summary"

    assert get_in(quality_gate_summary_schema, ["properties", "model_limits", "const"]) ==
             quality_gate_summary["model_limits"]

    stale_model_limits =
      Map.put(quality_gate_summary, "model_limits", [
        "quality_gate_summary_derives_classification_from_gate_rows"
      ])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match quality gate summary model limits")
           )

    stale_summary_count = Map.put(quality_gate_summary, "gate_count", 99)

    assert {:error, stale_summary_count_report} = Schema.validate_artifact(stale_summary_count)

    assert Enum.any?(
             stale_summary_count_report["errors"],
             &(&1["path"] == "$.gate_count" and &1["message"] == "must equal 6")
           )

    stale_summary_classification =
      Map.put(quality_gate_summary, "import_classification", "importable")

    assert {:error, stale_summary_classification_report} =
             Schema.validate_artifact(stale_summary_classification)

    assert Enum.any?(
             stale_summary_classification_report["errors"],
             &(&1["path"] == "$.import_classification" and
                 &1["message"] == "must match row-derived import classification")
           )

    stale_summary_id_map =
      put_in(quality_gate_summary, ["quality_gate_row_ids_by_status", "review_required"], [])

    assert {:error, stale_summary_id_map_report} = Schema.validate_artifact(stale_summary_id_map)

    assert Enum.any?(
             stale_summary_id_map_report["errors"],
             &(&1["path"] == "$.quality_gate_row_ids_by_status" and
                 &1["message"] == "must match quality-gate row IDs grouped by row status")
           )

    stale_quality_gate_counts =
      Map.merge(report, %{
        "gate_count" => 99,
        "passed_gate_count" => 99,
        "review_gate_count" => 99,
        "gate_status_counts" => %{"stale" => 99}
      })

    assert %{
             "gate_count" => 6,
             "passed_gate_count" => 5,
             "review_gate_count" => 1,
             "gate_status_counts" => %{"passed" => 5, "review_required" => 1}
           } = OperationalReadiness.quality_gate_summary(stale_quality_gate_counts)

    stale_readiness_classification =
      Map.merge(readiness_report, %{
        "readiness_level" => "blocked",
        "import_classification" => "blocked",
        "status" => "blocked"
      })

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "gate_status_counts" => %{"passed" => 5, "review_required" => 1}
           } =
             stale_quality_gate_report =
             OperationalReadiness.quality_gate_report(stale_readiness_classification)

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(stale_quality_gate_report)

    assert {:ok, quality_gate_report_schema} = Schema.json_schema("quality_gate_report.v1")

    assert get_in(quality_gate_report_schema, ["properties", "model", "const"]) ==
             "artifact_only_operational_quality_gate_report"

    invalid_model = Map.put(report, "model", "stale_quality_gate_model")
    invalid_gate_count = Map.put(report, "gate_count", 99)
    invalid_execution_boundary = Map.put(report, "execution_boundary", "adapter_handoff_only")
    invalid_gate_status_counts = put_in(report, ["gate_status_counts", "passed"], 99)

    invalid_gate_classification_counts =
      put_in(report, ["gate_classification_counts", "importable"], 99)

    invalid_gate_id_map = put_in(report, ["gate_ids_by_status", "review_required"], [])

    invalid_gate_classification_id_map =
      put_in(report, ["gate_ids_by_classification", "review_only"], [])

    invalid_quality_gate_row_id_map =
      put_in(report, ["quality_gate_row_ids_by_status", "review_required"], [])

    invalid_quality_gate_row_classification_id_map =
      put_in(report, ["quality_gate_row_ids_by_classification", "review_only"], [])

    invalid_model_limits =
      Map.put(report, "model_limits", ["quality_gate_report_does_not_approve_or_import"])

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:error, invalid_model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             invalid_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_operational_quality_gate_report\"")
           )

    assert {:error, invalid_gate_count_report} =
             Schema.validate_artifact(invalid_gate_count)

    assert Enum.any?(
             invalid_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count")
           )

    assert {:error, invalid_model_limits_report} = Schema.validate_artifact(invalid_model_limits)

    assert Enum.any?(
             invalid_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match quality gate report model limits")
           )

    assert {:error, invalid_execution_boundary_report} =
             Schema.validate_artifact(invalid_execution_boundary)

    assert Enum.any?(
             invalid_execution_boundary_report["errors"],
             &(&1["path"] == "$.execution_boundary" and
                 &1["message"] == "must match row-derived execution boundary")
           )

    assert {:error, invalid_gate_status_counts_report} =
             Schema.validate_artifact(invalid_gate_status_counts)

    assert Enum.any?(
             invalid_gate_status_counts_report["errors"],
             &(&1["path"] == "$.gate_status_counts")
           )

    assert {:error, invalid_gate_classification_counts_report} =
             Schema.validate_artifact(invalid_gate_classification_counts)

    assert Enum.any?(
             invalid_gate_classification_counts_report["errors"],
             &(&1["path"] == "$.gate_classification_counts")
           )

    assert {:error, invalid_gate_id_map_report} =
             Schema.validate_artifact(invalid_gate_id_map)

    assert Enum.any?(
             invalid_gate_id_map_report["errors"],
             &(&1["path"] == "$.gate_ids_by_status")
           )

    assert {:error, invalid_gate_classification_id_map_report} =
             Schema.validate_artifact(invalid_gate_classification_id_map)

    assert Enum.any?(
             invalid_gate_classification_id_map_report["errors"],
             &(&1["path"] == "$.gate_ids_by_classification")
           )

    assert {:error, invalid_quality_gate_row_id_map_report} =
             Schema.validate_artifact(invalid_quality_gate_row_id_map)

    assert Enum.any?(
             invalid_quality_gate_row_id_map_report["errors"],
             &(&1["path"] == "$.quality_gate_row_ids_by_status")
           )

    assert {:error, invalid_quality_gate_row_classification_id_map_report} =
             Schema.validate_artifact(invalid_quality_gate_row_classification_id_map)

    assert Enum.any?(
             invalid_quality_gate_row_classification_id_map_report["errors"],
             &(&1["path"] == "$.quality_gate_row_ids_by_classification")
           )

    assert {:ok, schema} = Schema.json_schema("quality_gate_report.v1")

    assert get_in(schema, [
             "properties",
             "gate_ids_by_status",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "quality_gate_row_ids_by_status",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "handoff_only", "type"]) == "boolean"
    assert get_in(schema, ["properties", "execution_allowed", "type"]) == "boolean"
    assert get_in(schema, ["properties", "cadence_write_allowed", "type"]) == "boolean"
    assert get_in(schema, ["properties", "operator_authority_granted", "type"]) == "boolean"

    assert get_in(schema, ["properties", "execution_boundary", "enum"]) == [
             "adapter_handoff_only",
             "operator_review_required_before_import",
             "analysis_only_not_for_execution",
             "blocked_not_for_import_or_execution"
           ]
  end

  test "readiness evidence preserves freshness status counts" do
    stale_report = OperationalReadiness.report(freshness_report("stale"))

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "evidence" => %{
               "stale_freshness_count" => 3,
               "current_freshness_count" => 0,
               "unknown_freshness_count" => 0,
               "freshness_status_counts" => %{"stale" => 3}
             }
           } = stale_report

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(stale_report)

    invalid_freshness_count =
      put_in(stale_report, ["evidence", "freshness_status_counts", "stale"], -1)

    assert {:error, freshness_count_report} =
             Schema.validate_artifact(invalid_freshness_count)

    assert Enum.any?(
             freshness_count_report["errors"],
             &(&1["path"] == "$.evidence.freshness_status_counts.stale")
           )

    current_report = OperationalReadiness.report(freshness_report("current"))

    assert %{
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "evidence" => %{
               "current_freshness_count" => 1,
               "stale_freshness_count" => 0,
               "unknown_freshness_count" => 0,
               "freshness_status_counts" => %{"current" => 1}
             }
           } = current_report
  end

  test "readiness evidence preserves schema-validation status and issue counts" do
    failing_report = OperationalReadiness.report(schema_validation_report("fail"))

    assert %{
             "readiness_level" => "blocked",
             "import_classification" => "blocked",
             "status" => "blocked",
             "evidence" => %{
               "schema_validation_pass_count" => 0,
               "schema_validation_fail_count" => 3,
               "schema_validation_error_count" => 3,
               "schema_validation_warning_count" => 0,
               "schema_validation_remediation_count" => 3,
               "schema_validation_status_counts" => %{"fail" => 3}
             }
           } = failing_report

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(failing_report)

    passing_report = OperationalReadiness.report(schema_validation_report("pass"))

    assert %{
             "readiness_level" => "analysis_only",
             "import_classification" => "analysis_only",
             "status" => "analysis_only",
             "evidence" => %{
               "schema_validation_pass_count" => 1,
               "schema_validation_fail_count" => 0,
               "schema_validation_error_count" => 0,
               "schema_validation_warning_count" => 0,
               "schema_validation_remediation_count" => 0,
               "schema_validation_status_counts" => %{"pass" => 1}
             }
           } = passing_report
  end

  test "readiness evidence preserves source model and model-limit counts" do
    report = OperationalReadiness.report(ready_manifest())

    assert %{
             "readiness_level" => "import_eligible",
             "import_classification" => "importable",
             "evidence" => %{
               "source_model_count" => 1,
               "source_model_limit_count" => 1,
               "source_model_counts" => %{"cadence_import_manifest_fixture" => 1},
               "source_model_limit_counts" => %{"adapter_handoff_only" => 1}
             }
           } = report

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "mission-policy evidence gates import eligibility" do
    review_report =
      ready_manifest()
      |> put_in(
        ["rows", Access.at(0), "source_policy_decision"],
        policy_decision("operator_review_required")
      )
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "gate_count" => 6,
             "passed_gate_count" => 5,
             "review_gate_count" => 1,
             "blocked_gate_count" => 0,
             "evidence" => %{
               "policy_decision_count" => 1,
               "policy_auto_approvable_count" => 0,
               "policy_review_required_count" => 1,
               "policy_blocked_count" => 0,
               "policy_classification_counts" => %{"operator_review_required" => 1}
             }
           } = review_report

    assert %{
             "id" => "mission_policy",
             "status" => "review_required",
             "classification" => "review_only",
             "reason" => "mission-policy evidence requires operator review before import",
             "policy_decision_count" => 1,
             "policy_classification_counts" => %{"operator_review_required" => 1}
           } = Enum.find(review_report["gates"], &(&1["id"] == "mission_policy"))

    blocked_report =
      ready_manifest()
      |> put_in(
        ["rows", Access.at(0), "source_policy_decision"],
        policy_decision("blocked_by_policy")
      )
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "blocked",
             "import_classification" => "blocked",
             "status" => "blocked",
             "gate_count" => 6,
             "blocked_gate_count" => 1,
             "evidence" => %{
               "policy_decision_count" => 1,
               "policy_blocked_count" => 1,
               "policy_classification_counts" => %{"blocked_by_policy" => 1}
             }
           } = blocked_report

    assert %{
             "id" => "mission_policy",
             "status" => "blocked",
             "classification" => "blocked",
             "reason" => "mission-policy evidence blocks import eligibility"
           } = Enum.find(blocked_report["gates"], &(&1["id"] == "mission_policy"))

    invalid_policy_count =
      put_in(
        review_report,
        ["evidence", "policy_classification_counts", "operator_review_required"],
        -1
      )

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(review_report)

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(blocked_report)

    assert {:error, invalid_policy_count_report} =
             Schema.validate_artifact(invalid_policy_count)

    assert Enum.any?(
             invalid_policy_count_report["errors"],
             &(&1["path"] ==
                 "$.evidence.policy_classification_counts.operator_review_required")
           )
  end

  test "operator training requirements gate import eligibility and flow through handoffs" do
    report =
      ready_manifest()
      |> put_in(["rows", Access.at(0), "required_operator_roles"], [
        "mission_director",
        "contact_operator"
      ])
      |> put_in(["rows", Access.at(0), "required_training_ids"], ["contact_replan_drill"])
      |> put_in(["rows", Access.at(0), "required_certification_ids"], ["cadence_import_cert"])
      |> put_in(["rows", Access.at(0), "required_qualification_ids"], ["sat_ops_current"])
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "gate_count" => 6,
             "passed_gate_count" => 5,
             "review_gate_count" => 1,
             "evidence" => %{
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
           } = report

    assert %{
             "id" => "operator_training",
             "status" => "review_required",
             "classification" => "review_only",
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
           } = Enum.find(report["gates"], &(&1["id"] == "operator_training"))

    quality_report = OperationalReadiness.quality_gate_report(report)

    operator_training_row_id =
      quality_report["rows"]
      |> Enum.find(&(&1["gate_id"] == "operator_training"))
      |> Map.fetch!("id")

    assert %{
             "gate_id" => "operator_training",
             "status" => "review_required",
             "operator_training_requirement_count" => 5,
             "required_operator_roles" => ["contact_operator", "mission_director"],
             "required_training_ids" => ["contact_replan_drill"],
             "required_certification_ids" => ["cadence_import_cert"],
             "required_qualification_ids" => ["sat_ops_current"]
           } = Enum.find(quality_report["rows"], &(&1["gate_id"] == "operator_training"))

    assert %{
             "schema_contract" => "operational_quality_gate_operator_training_summary.v1",
             "model" => "artifact_only_quality_gate_operator_training_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
             "source_readiness_report_id" =>
               "operational_readiness:planned_activity.v1:activity_1",
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
               "review_required" => [^operator_training_row_id]
             },
             "quality_gate_row_ids_by_classification" => %{
               "review_only" => [^operator_training_row_id]
             },
             "quality_gate_ids_by_status" => %{"review_required" => ["operator_training"]},
             "quality_gate_ids_by_classification" => %{"review_only" => ["operator_training"]},
             "review_required_quality_gate_row_ids" => [^operator_training_row_id],
             "review_only_quality_gate_row_ids" => [^operator_training_row_id],
             "operator_training_gate_ids" => ["operator_training"],
             "operator_training_review_required" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "source" => "quality_gate_report.v1",
               "operator_authority" => "not_granted_by_operator_training_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             },
             "model_limits" => [
               "quality_gate_operator_training_summary_routes_only",
               "quality_gate_operator_training_summary_does_not_approve_or_import"
             ]
           } =
             operator_training_summary =
             OperationalReadiness.quality_gate_operator_training_summary(quality_report)

    assert OrbitalDynamics.operational_quality_gate_operator_training_summary(report) ==
             operator_training_summary

    assert {:ok, %{"schema_contract" => "operational_quality_gate_operator_training_summary.v1"}} =
             Schema.validate_artifact(operator_training_summary)

    assert {:ok, operator_training_schema} =
             Schema.json_schema("operational_quality_gate_operator_training_summary.v1")

    assert get_in(operator_training_schema, ["properties", "model", "const"]) ==
             "artifact_only_quality_gate_operator_training_summary"

    assert get_in(operator_training_schema, ["properties", "model_limits", "const"]) ==
             operator_training_summary["model_limits"]

    stale_model_limits =
      Map.put(operator_training_summary, "model_limits", [
        "quality_gate_operator_training_summary_routes_only"
      ])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] ==
                   "must match quality gate operator-training summary model limits")
           )

    stale_requirement_count =
      Map.put(operator_training_summary, "operator_training_requirement_count", 99)

    assert {:error, stale_requirement_count_report} =
             Schema.validate_artifact(stale_requirement_count)

    assert Enum.any?(
             stale_requirement_count_report["errors"],
             &(&1["path"] == "$.operator_training_requirement_count" and
                 &1["message"] == "must equal operator_training_requirement_counts sum")
           )

    stale_requirement_ids =
      Map.put(operator_training_summary, "operator_training_requirement_ids", [])

    assert {:error, stale_requirement_ids_report} =
             Schema.validate_artifact(stale_requirement_ids)

    assert Enum.any?(
             stale_requirement_ids_report["errors"],
             &(&1["path"] == "$.operator_training_requirement_ids" and
                 &1["message"] ==
                   "must equal operator_training_requirement_counts keys with positive counts")
           )

    stale_review_flag =
      Map.put(operator_training_summary, "operator_training_review_required", false)

    assert {:error, stale_review_flag_report} = Schema.validate_artifact(stale_review_flag)

    assert Enum.any?(
             stale_review_flag_report["errors"],
             &(&1["path"] == "$.operator_training_review_required" and
                 &1["message"] == "must match review-required quality-gate row IDs")
           )

    assert %{
             "operator_training_row_count" => 0,
             "operator_training_requirement_count" => 0,
             "required_operator_roles" => [],
             "required_training_ids" => [],
             "required_certification_ids" => [],
             "required_qualification_ids" => [],
             "operator_training_gate_ids" => [],
             "operator_training_review_required" => false
           } =
             ready_training_summary =
             OperationalReadiness.quality_gate_operator_training_summary(ready_manifest())

    assert {:ok, %{"schema_contract" => "operational_quality_gate_operator_training_summary.v1"}} =
             Schema.validate_artifact(ready_training_summary)

    package = OperatorReview.from_operational_readiness_report(report)

    assert %{
             "readiness_gate_id" => "operator_training",
             "approval_status" => "operator_review_required",
             "operator_training_requirement_count" => 5,
             "required_operator_roles" => ["contact_operator", "mission_director"],
             "required_training_ids" => ["contact_replan_drill"],
             "required_certification_ids" => ["cadence_import_cert"],
             "required_qualification_ids" => ["sat_ops_current"]
           } = Enum.find(package["rows"], &(&1["readiness_gate_id"] == "operator_training"))

    manifest = CadenceImport.from_operational_readiness_report(report)

    assert %{
             "readiness_gate_id" => "operator_training",
             "import_status" => "review_required_before_import",
             "operator_training_requirement_count" => 5,
             "required_operator_roles" => ["contact_operator", "mission_director"],
             "required_training_ids" => ["contact_replan_drill"],
             "required_certification_ids" => ["cadence_import_cert"],
             "required_qualification_ids" => ["sat_ops_current"]
           } = Enum.find(manifest["rows"], &(&1["readiness_gate_id"] == "operator_training"))

    invalid_requirement_count =
      put_in(
        report,
        ["gates", Access.at(3), "operator_training_requirement_count"],
        99
      )

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(quality_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert {:error, invalid_requirement_count_report} =
             Schema.validate_artifact(invalid_requirement_count)

    assert Enum.any?(
             invalid_requirement_count_report["errors"],
             &(&1["path"] == "$.gates[3].operator_training_requirement_count")
           )
  end

  test "adapter-boundary gate requires trust boundary for adapter-shaped import rows" do
    missing_boundary_report =
      ready_manifest()
      |> put_in(["rows", Access.at(0), "cadence_import_adapter"], "cadence_contact_adapter")
      |> put_in(["rows", Access.at(0), "cadence_import_adapter_version"], "2026-05")
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "review_gate_count" => 1,
             "evidence" => %{
               "adapter_context_count" => 1,
               "adapter_trust_boundary_declared_count" => 0,
               "adapter_trust_boundary_missing_count" => 1,
               "adapter_trust_boundary_untrusted_count" => 0,
               "adapter_boundary_status_counts" => %{"missing" => 1}
             }
           } = missing_boundary_report

    assert %{
             "id" => "adapter_boundary",
             "status" => "review_required",
             "classification" => "review_only",
             "reason" => "adapter import context is missing a declared trust boundary"
           } = Enum.find(missing_boundary_report["gates"], &(&1["id"] == "adapter_boundary"))

    declared_boundary_report =
      missing_boundary_report
      |> put_in(["evidence", "adapter_boundary_status_counts"], %{"declared" => 1})

    invalid_boundary_count =
      put_in(
        missing_boundary_report,
        ["evidence", "adapter_boundary_status_counts", "missing"],
        -1
      )

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(missing_boundary_report)

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(declared_boundary_report)

    assert {:error, invalid_boundary_count_report} =
             Schema.validate_artifact(invalid_boundary_count)

    assert Enum.any?(
             invalid_boundary_count_report["errors"],
             &(&1["path"] == "$.evidence.adapter_boundary_status_counts.missing")
           )

    untrusted_boundary_report =
      ready_manifest()
      |> put_in(["rows", Access.at(0), "cadence_import_adapter"], "cadence_contact_adapter")
      |> put_in(["rows", Access.at(0), "cadence_import_trust_boundary"], "unknown_external")
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "blocked",
             "import_classification" => "blocked",
             "status" => "blocked",
             "blocked_gate_count" => 1,
             "evidence" => %{
               "adapter_context_count" => 1,
               "adapter_trust_boundary_declared_count" => 0,
               "adapter_trust_boundary_missing_count" => 0,
               "adapter_trust_boundary_untrusted_count" => 1,
               "adapter_boundary_status_counts" => %{"untrusted" => 1}
             }
           } = untrusted_boundary_report

    assert %{
             "id" => "adapter_boundary",
             "status" => "blocked",
             "classification" => "blocked",
             "reason" => "adapter import context declares untrusted trust-boundary evidence",
             "adapter_boundary_status_counts" => %{"untrusted" => 1}
           } = Enum.find(untrusted_boundary_report["gates"], &(&1["id"] == "adapter_boundary"))

    quality_gate = OperationalReadiness.quality_gate_report(untrusted_boundary_report)

    assert %{
             "status" => "blocked",
             "blocked_gate_ids" => ["adapter_boundary"]
           } = quality_gate

    assert %{
             "gate_id" => "adapter_boundary",
             "adapter_trust_boundary_untrusted_count" => 1,
             "adapter_boundary_status_counts" => %{"untrusted" => 1}
           } = Enum.find(quality_gate["rows"], &(&1["gate_id"] == "adapter_boundary"))

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(untrusted_boundary_report)

    importable_report =
      ready_manifest()
      |> put_in(["rows", Access.at(0), "cadence_import_adapter"], "cadence_contact_adapter")
      |> put_in(["rows", Access.at(0), "cadence_import_trust_boundary"], "cadence_adapter")
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "import_eligible",
             "import_classification" => "importable",
             "review_gate_count" => 0,
             "evidence" => %{
               "adapter_context_count" => 1,
               "adapter_trust_boundary_declared_count" => 1,
               "adapter_trust_boundary_missing_count" => 0,
               "adapter_trust_boundary_untrusted_count" => 0,
               "adapter_boundary_status_counts" => %{"declared" => 1}
             }
           } = importable_report
  end

  test "readiness evidence preserves review and import routing family counts" do
    contact_readiness =
      [
        %{
          id: :dl_1,
          type: :downlink,
          ground_station_id: :equator_prime,
          starts_at_s: 10.0,
          ends_at_s: 40.0
        }
      ]
      |> OrbitalDynamics.contact_allocation_report([
        %{ground_station_id: :equator_prime, status: :reserved, starts_at_s: 0.0, ends_at_s: 60.0}
      ])
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "evidence" => %{
               "resource_availability_pressure_count" => 1,
               "resource_availability_reason_counts" => %{"ground_station_reserved" => 1},
               "resource_availability_reason_ids" => ["ground_station_reserved"],
               "station_availability_reason_ids" => ["ground_station_reserved"],
               "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
               "review_type_counts" => %{"contact_allocation_review" => 1},
               "import_action_counts" => %{"review_contact_allocation" => 1},
               "source_review_type_counts" => %{"contact_allocation_review" => 1}
             }
           } = contact_readiness

    assert %{
             "id" => "resource_availability",
             "status" => "review_required",
             "classification" => "review_only",
             "resource_availability_pressure_count" => 1,
             "resource_availability_reason_counts" => %{"ground_station_reserved" => 1},
             "resource_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1}
           } = Enum.find(contact_readiness["gates"], &(&1["id"] == "resource_availability"))

    contact_quality_gate_report = OperationalReadiness.quality_gate_report(contact_readiness)

    assert %{
             "gate_id" => "resource_availability",
             "resource_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
             "resource_availability_reason_counts" => %{"ground_station_reserved" => 1}
           } =
             Enum.find(
               contact_quality_gate_report["rows"],
               &(&1["gate_id"] == "resource_availability")
             )

    contact_review_package = OperatorReview.from_operational_readiness_report(contact_readiness)

    assert %{
             "readiness_gate_id" => "resource_availability",
             "resource_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1}
           } =
             Enum.find(
               contact_review_package["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    contact_import_manifest = CadenceImport.from_operational_readiness_report(contact_readiness)

    assert %{
             "readiness_gate_id" => "resource_availability",
             "resource_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_ids" => ["ground_station_reserved"],
             "station_availability_reason_counts" => %{"ground_station_reserved" => 1}
           } =
             Enum.find(
               contact_import_manifest["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    resource_readiness =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 20.0
          }
        ],
        [
          %{spacecraft_id: :leo_1, storage_capacity_mb: 100.0, storage_used_mb: 10.0},
          %{spacecraft_id: :leo_2, battery_capacity_wh: 100.0, battery_energy_used_wh: -1.0}
        ]
      )
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "evidence" => %{
               "review_type_counts" => %{"resource_projection_review" => 2},
               "import_action_counts" => %{"review_resource_projection" => 2},
               "source_review_type_counts" => %{"resource_projection_review" => 2}
             }
           } = resource_readiness

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(contact_readiness)

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(contact_quality_gate_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(contact_review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(contact_import_manifest)

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(resource_readiness)

    invalid_evidence_count =
      put_in(
        contact_readiness,
        ["evidence", "review_type_counts", "contact_allocation_review"],
        -1
      )

    assert {:error, invalid_evidence_count_report} =
             Schema.validate_artifact(invalid_evidence_count)

    assert Enum.any?(
             invalid_evidence_count_report["errors"],
             &(&1["path"] == "$.evidence.review_type_counts.contact_allocation_review")
           )

    stale_station_reason_ids =
      update_in(contact_quality_gate_report, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"gate_id" => "resource_availability"} = row ->
            Map.put(row, "station_availability_reason_ids", [])

          row ->
            row
        end)
      end)

    assert {:error, stale_station_reason_report} =
             Schema.validate_artifact(stale_station_reason_ids)

    assert Enum.any?(
             stale_station_reason_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.station_availability_reason_ids$/ and
                 &1["message"] ==
                   "must equal station availability reason IDs from resource_availability_reason_counts")
           )

    stale_station_reason_counts =
      update_in(contact_quality_gate_report, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"gate_id" => "resource_availability"} = row ->
            Map.put(row, "station_availability_reason_counts", %{})

          row ->
            row
        end)
      end)

    assert {:error, stale_station_reason_counts_report} =
             Schema.validate_artifact(stale_station_reason_counts)

    assert Enum.any?(
             stale_station_reason_counts_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.station_availability_reason_counts$/ and
                 &1["message"] ==
                   "must equal station availability reason counts from resource_availability_reason_counts")
           )
  end

  test "contact-filter suppressions feed unavailable-resource quality gates" do
    contact_filter_report =
      OrbitalDynamics.contact_filter_report(
        [
          %{
            id: :dl_filter_unavailable,
            type: :downlink,
            spacecraft_id: :leo_1,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 40.0
          }
        ],
        [
          %{
            ground_station_id: :equator_prime,
            status: :unavailable,
            starts_at_s: 0.0,
            ends_at_s: 60.0,
            source: "partner_calendar"
          }
        ]
      )

    readiness_report = OperationalReadiness.report(contact_filter_report)

    assert %{
             "source_artifact_type" => "contact_filter_report.v1",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "evidence" => %{
               "resource_availability_pressure_count" => 1,
               "resource_availability_reason_counts" => %{"ground_station_unavailable" => 1},
               "resource_availability_reason_ids" => ["ground_station_unavailable"],
               "station_availability_reason_ids" => ["ground_station_unavailable"],
               "station_availability_reason_counts" => %{"ground_station_unavailable" => 1},
               "review_type_counts" => %{"contact_suppression" => 1},
               "import_action_counts" => %{"review_contact_suppression" => 1},
               "source_review_type_counts" => %{"contact_suppression" => 1}
             }
           } = readiness_report

    quality_gate_report = OperationalReadiness.quality_gate_report(readiness_report)

    assert %{
             "gate_id" => "resource_availability",
             "resource_availability_pressure_count" => 1,
             "resource_availability_reason_counts" => %{"ground_station_unavailable" => 1},
             "resource_availability_reason_ids" => ["ground_station_unavailable"],
             "station_availability_reason_ids" => ["ground_station_unavailable"],
             "station_availability_reason_counts" => %{"ground_station_unavailable" => 1},
             "unavailable_resource_reason_ids" => []
           } =
             quality_gate_row =
             Enum.find(quality_gate_report["rows"], &(&1["gate_id"] == "resource_availability"))

    quality_gate_row_id = quality_gate_row["id"]

    assert %{
             "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
             "model" => "artifact_only_quality_gate_unavailable_resource_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "contact_filter_report.v1",
             "resource_availability_row_count" => 1,
             "unavailable_resource_row_count" => 0,
             "unavailable_resource_pressure_count" => 0,
             "unavailable_resource_reason_counts" => %{},
             "unavailable_resource_reason_ids" => [],
             "station_availability_reason_counts" => %{"ground_station_unavailable" => 1},
             "station_availability_reason_ids" => ["ground_station_unavailable"],
             "blocked_contact_ids_by_spacecraft_id" => %{
               "leo_1" => ["dl_filter_unavailable"]
             },
             "blocked_contact_ids_by_status" => %{
               "review_required" => ["dl_filter_unavailable"]
             },
             "quality_gate_row_ids_by_status" => %{
               "review_required" => [^quality_gate_row_id]
             },
             "resource_availability_gate_ids" => ["resource_availability"],
             "assumptions" => %{
               "operator_authority" => "not_granted_by_unavailable_resource_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             },
             "model_limits" => [
               "quality_gate_unavailable_resource_summary_routes_only",
               "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
             ]
           } =
             filter_unavailable_summary =
             OperationalReadiness.quality_gate_unavailable_resource_summary(quality_gate_report)

    assert {:ok,
            %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"}} =
             Schema.validate_artifact(filter_unavailable_summary)

    assert {:ok, unavailable_resource_schema} =
             Schema.json_schema("operational_quality_gate_unavailable_resource_summary.v1")

    assert get_in(unavailable_resource_schema, ["properties", "model", "const"]) ==
             "artifact_only_quality_gate_unavailable_resource_summary"

    assert get_in(unavailable_resource_schema, ["properties", "model_limits", "const"]) ==
             filter_unavailable_summary["model_limits"]

    stale_model_limits =
      Map.put(filter_unavailable_summary, "model_limits", [
        "quality_gate_unavailable_resource_summary_routes_only"
      ])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] ==
                   "must match quality gate unavailable-resource summary model limits")
           )

    stale_station_reason_ids =
      Map.put(filter_unavailable_summary, "station_availability_reason_ids", [])

    assert {:error, stale_station_reason_ids_report} =
             Schema.validate_artifact(stale_station_reason_ids)

    assert Enum.any?(
             stale_station_reason_ids_report["errors"],
             &(&1["path"] == "$.station_availability_reason_ids" and
                 &1["message"] ==
                   "must equal station availability reason IDs from station_availability_reason_counts")
           )

    review_package = OperatorReview.from_operational_readiness_report(readiness_report)
    import_manifest = CadenceImport.from_operational_readiness_report(readiness_report)

    assert %{
             "readiness_gate_id" => "resource_availability",
             "station_availability_reason_ids" => ["ground_station_unavailable"],
             "station_availability_reason_counts" => %{"ground_station_unavailable" => 1}
           } =
             Enum.find(
               review_package["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    assert %{
             "readiness_gate_id" => "resource_availability",
             "station_availability_reason_ids" => ["ground_station_unavailable"],
             "station_availability_reason_counts" => %{"ground_station_unavailable" => 1}
           } =
             Enum.find(
               import_manifest["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(contact_filter_report)

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(quality_gate_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)
  end

  test "resource availability pressure adds an explicit readiness quality gate" do
    resource_projection =
      ResourceProjection.report(
        [
          %{
            id: :obs_payload_down,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 40.0
          },
          %{
            id: :dl_antenna_down,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 20.0,
            estimated_throughput_mb: 30.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            payload_status: "unavailable",
            antenna_status: "offline",
            resource_source_quality: "operator_supplied",
            resource_trust_boundary: "ops_declared_resource_summary",
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    readiness_report = OperationalReadiness.report(resource_projection)

    assert %{
             "source_artifact_type" => "resource_projection_report.v1",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "review_gate_count" => 3,
             "evidence" => %{
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
               "resource_blocking_dimension_count" => 0,
               "resource_blocking_dimension_counts" => %{},
               "resource_source_quality_counts" => %{"operator_supplied" => 1},
               "resource_trust_boundary_status_counts" => %{"declared" => 1}
             }
           } = readiness_report

    assert %{
             "id" => "resource_availability",
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
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"declared" => 1}
           } = Enum.find(readiness_report["gates"], &(&1["id"] == "resource_availability"))

    quality_gate_report = OperationalReadiness.quality_gate_report(readiness_report)

    assert %{
             "gate_ids_by_status" => %{
               "review_required" => [
                 "cadence_import",
                 "operator_review",
                 "resource_availability"
               ]
             },
             "review_required_gate_ids" => [
               "cadence_import",
               "operator_review",
               "resource_availability"
             ]
           } = quality_gate_report

    assert %{
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
             "resource_blocking_dimension_counts" => %{},
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"declared" => 1}
           } =
             Enum.find(
               quality_gate_report["rows"],
               &(&1["gate_id"] == "resource_availability")
             )

    review_package = OperatorReview.from_operational_readiness_report(readiness_report)

    assert %{
             "review_type" => "operational_readiness_review",
             "readiness_gate_id" => "resource_availability",
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
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"declared" => 1}
           } =
             Enum.find(
               review_package["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    import_manifest = CadenceImport.from_operational_readiness_report(readiness_report)

    assert %{
             "import_action" => "review_operational_readiness",
             "readiness_gate_id" => "resource_availability",
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"declared" => 1},
             "source_review_row" => %{
               "resource_availability_reason_counts" => %{
                 "antenna_unavailable" => 1,
                 "payload_unavailable" => 1
               },
               "resource_source_quality_counts" => %{"operator_supplied" => 1},
               "resource_trust_boundary_status_counts" => %{"declared" => 1}
             }
           } =
             Enum.find(
               import_manifest["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(quality_gate_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)

    invalid_resource_count =
      put_in(
        readiness_report,
        ["evidence", "resource_availability_reason_counts", "payload_unavailable"],
        -1
      )

    assert {:error, invalid_resource_count_report} =
             Schema.validate_artifact(invalid_resource_count)

    assert Enum.any?(
             invalid_resource_count_report["errors"],
             &(&1["path"] ==
                 "$.evidence.resource_availability_reason_counts.payload_unavailable")
           )

    stale_evidence_reason_ids =
      readiness_report
      |> put_in(["evidence", "resource_availability_reason_ids"], ["payload_unavailable"])
      |> put_in(["evidence", "unavailable_resource_reason_ids"], ["antenna_unavailable"])

    assert {:error, stale_evidence_report} = Schema.validate_artifact(stale_evidence_reason_ids)

    assert Enum.any?(
             stale_evidence_report["errors"],
             &(&1["path"] == "$.evidence.resource_availability_reason_ids" and
                 &1["message"] ==
                   "must equal resource_availability_reason_counts keys with positive counts")
           )

    assert Enum.any?(
             stale_evidence_report["errors"],
             &(&1["path"] == "$.evidence.unavailable_resource_reason_ids" and
                 &1["message"] ==
                   "must equal unavailable resource reason IDs from resource_availability_reason_counts")
           )

    stale_readiness_reason_ids =
      update_in(readiness_report, ["gates"], fn gates ->
        Enum.map(gates, fn
          %{"id" => "resource_availability"} = gate ->
            gate
            |> Map.put("resource_availability_reason_ids", ["payload_unavailable"])
            |> Map.put("unavailable_resource_reason_ids", ["antenna_unavailable"])

          gate ->
            gate
        end)
      end)

    assert {:error, stale_readiness_report} = Schema.validate_artifact(stale_readiness_reason_ids)

    assert Enum.any?(
             stale_readiness_report["errors"],
             &(&1["path"] =~ ~r/^\$\.gates\[\d+\]\.resource_availability_reason_ids$/ and
                 &1["message"] ==
                   "must equal resource_availability_reason_counts keys with positive counts")
           )

    assert Enum.any?(
             stale_readiness_report["errors"],
             &(&1["path"] =~ ~r/^\$\.gates\[\d+\]\.unavailable_resource_reason_ids$/ and
                 &1["message"] ==
                   "must equal unavailable resource reason IDs from resource_availability_reason_counts")
           )

    stale_quality_gate_reason_ids =
      update_in(quality_gate_report, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"gate_id" => "resource_availability"} = row ->
            row
            |> Map.put("resource_availability_reason_ids", ["payload_unavailable"])
            |> Map.put("unavailable_resource_reason_ids", ["antenna_unavailable"])

          row ->
            row
        end)
      end)

    assert {:error, stale_quality_gate_report} =
             Schema.validate_artifact(stale_quality_gate_reason_ids)

    assert Enum.any?(
             stale_quality_gate_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.resource_availability_reason_ids$/ and
                 &1["message"] ==
                   "must equal resource_availability_reason_counts keys with positive counts")
           )

    assert Enum.any?(
             stale_quality_gate_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.unavailable_resource_reason_ids$/ and
                 &1["message"] ==
                   "must equal unavailable resource reason IDs from resource_availability_reason_counts")
           )

    stale_review_reason_ids =
      update_in(review_package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"readiness_gate_id" => "resource_availability"} = row ->
            Map.put(row, "resource_availability_reason_ids", ["payload_unavailable"])

          row ->
            row
        end)
      end)

    assert {:error, stale_review_report} = Schema.validate_artifact(stale_review_reason_ids)

    assert Enum.any?(
             stale_review_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.resource_availability_reason_ids$/ and
                 &1["message"] ==
                   "must equal resource_availability_reason_counts keys with positive counts")
           )

    stale_import_source_review_reason_ids =
      update_in(import_manifest, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"readiness_gate_id" => "resource_availability"} = row ->
            source_review_row =
              row["source_review_row"]
              |> Map.put("unavailable_resource_reason_ids", ["payload_unavailable"])

            Map.put(row, "source_review_row", source_review_row)

          row ->
            row
        end)
      end)

    assert {:error, stale_import_report} =
             Schema.validate_artifact(stale_import_source_review_reason_ids)

    assert Enum.any?(
             stale_import_report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_review_row\.unavailable_resource_reason_ids$/ and
                 &1["message"] ==
                   "must equal unavailable resource reason IDs from resource_availability_reason_counts")
           )

    stale_provenance_counts =
      update_in(quality_gate_report, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"gate_id" => "resource_availability"} = row ->
            put_in(row, ["resource_source_quality_counts", "operator_supplied"], -1)

          row ->
            row
        end)
      end)

    assert {:error, stale_provenance_report} = Schema.validate_artifact(stale_provenance_counts)

    assert Enum.any?(
             stale_provenance_report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.resource_source_quality_counts\.operator_supplied$/)
           )
  end

  test "resource availability gates preserve nested contact allocation resource provenance" do
    expected_contact_ids_by_blocking_dimension = %{"antenna" => ["dl_resource_blocked"]}
    expected_contact_ids_by_spacecraft = %{"leo_1" => ["dl_resource_blocked"]}

    review_source = %{
      "schema_contract" => "operator_review_package.v1",
      "source_artifact_type" => "contact_allocation_report.v1",
      "package_id" => "allocation_resource_review",
      "rows" => [
        %{
          "id" => "operator_review:contact_allocation:dl_resource_blocked",
          "review_type" => "contact_allocation_review",
          "approval_status" => "operator_review_required",
          "source_contact_allocation" => %{
            "contact_id" => "dl_resource_blocked",
            "type" => "downlink",
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 620.0,
            "ends_at_s" => 680.0,
            "allocation_status" => "blocked",
            "allocation_reason" => "antenna_unavailable",
            "source_resource_suppression" => %{
              "id" => "dl_resource_blocked",
              "type" => "downlink",
              "spacecraft_id" => "leo_1",
              "suppressed_reason" => "antenna_unavailable",
              "resource_blocking_dimension" => "antenna",
              "antenna_available" => false,
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared"
            }
          }
        }
      ]
    }

    readiness_report = OperationalReadiness.report(review_source)

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "evidence" => %{
               "resource_availability_pressure_count" => 1,
               "resource_availability_reason_counts" => %{"antenna_unavailable" => 1},
               "resource_blocking_dimension_counts" => %{"antenna" => 1},
               "resource_blocked_contact_ids_by_blocking_dimension" =>
                 ^expected_contact_ids_by_blocking_dimension,
               "resource_blocked_contact_ids_by_spacecraft_id" =>
                 ^expected_contact_ids_by_spacecraft,
               "resource_source_quality_counts" => %{"operator_supplied" => 1},
               "resource_trust_boundary_status_counts" => %{"declared" => 1}
             }
           } = readiness_report

    assert %{
             "id" => "resource_availability",
             "resource_availability_reason_counts" => %{"antenna_unavailable" => 1},
             "resource_blocking_dimension_counts" => %{"antenna" => 1},
             "resource_blocked_contact_ids_by_blocking_dimension" =>
               ^expected_contact_ids_by_blocking_dimension,
             "resource_blocked_contact_ids_by_spacecraft_id" =>
               ^expected_contact_ids_by_spacecraft,
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"declared" => 1}
           } = Enum.find(readiness_report["gates"], &(&1["id"] == "resource_availability"))

    quality_gate_report = OperationalReadiness.quality_gate_report(readiness_report)

    quality_gate_resource_row =
      Enum.find(
        quality_gate_report["rows"],
        &(&1["gate_id"] == "resource_availability")
      )

    assert %{
             "gate_id" => "resource_availability",
             "resource_blocked_contact_ids_by_blocking_dimension" =>
               ^expected_contact_ids_by_blocking_dimension,
             "resource_blocked_contact_ids_by_spacecraft_id" =>
               ^expected_contact_ids_by_spacecraft,
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"declared" => 1}
           } =
             quality_gate_resource_row

    quality_summary =
      OperationalReadiness.quality_gate_unavailable_resource_summary(quality_gate_report)

    quality_gate_report_id = quality_gate_report["report_id"]
    readiness_report_id = readiness_report["report_id"]
    quality_gate_resource_row_id = quality_gate_resource_row["id"]

    assert %{
             "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
             "model" => "artifact_only_quality_gate_unavailable_resource_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "contact_allocation_report.v1",
             "source_quality_gate_report_id" => ^quality_gate_report_id,
             "source_readiness_report_id" => ^readiness_report_id,
             "resource_availability_row_count" => 1,
             "unavailable_resource_row_count" => 1,
             "unavailable_resource_pressure_count" => 1,
             "unavailable_resource_reason_counts" => %{"antenna_unavailable" => 1},
             "unavailable_resource_reason_ids" => ["antenna_unavailable"],
             "station_availability_reason_counts" => %{},
             "station_availability_reason_ids" => [],
             "resource_blocking_dimension_counts" => %{"antenna" => 1},
             "blocked_contact_ids_by_blocking_dimension" =>
               ^expected_contact_ids_by_blocking_dimension,
             "blocked_contact_ids_by_spacecraft_id" => ^expected_contact_ids_by_spacecraft,
             "blocked_contact_ids_by_status" => %{"review_required" => ["dl_resource_blocked"]},
             "quality_gate_row_ids_by_status" => %{
               "review_required" => [^quality_gate_resource_row_id]
             },
             "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
             "review_required_quality_gate_row_ids" => [^quality_gate_resource_row_id],
             "blocked_quality_gate_row_ids" => [],
             "resource_availability_gate_ids" => ["resource_availability"],
             "assumptions" => %{
               "source" => "quality_gate_report.v1",
               "operator_authority" => "not_granted_by_unavailable_resource_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             },
             "model_limits" => [
               "quality_gate_unavailable_resource_summary_routes_only",
               "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
             ]
           } = quality_summary

    assert OrbitalDynamics.operational_quality_gate_unavailable_resource_summary(
             quality_gate_report
           ) == quality_summary

    assert OrbitalDynamics.operational_quality_gate_unavailable_resource_summary(readiness_report) ==
             quality_summary

    assert {:ok,
            %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"}} =
             Schema.validate_artifact(quality_summary)

    stale_pressure_count = Map.put(quality_summary, "unavailable_resource_pressure_count", 99)

    assert {:error, stale_pressure_count_report} =
             Schema.validate_artifact(stale_pressure_count)

    assert Enum.any?(
             stale_pressure_count_report["errors"],
             &(&1["path"] == "$.unavailable_resource_pressure_count" and
                 &1["message"] == "must equal unavailable_resource_reason_counts sum")
           )

    stale_reason_ids = Map.put(quality_summary, "unavailable_resource_reason_ids", [])

    assert {:error, stale_reason_ids_report} = Schema.validate_artifact(stale_reason_ids)

    assert Enum.any?(
             stale_reason_ids_report["errors"],
             &(&1["path"] == "$.unavailable_resource_reason_ids" and
                 &1["message"] ==
                   "must equal unavailable resource reason IDs from unavailable_resource_reason_counts")
           )

    stale_row_ids = Map.put(quality_summary, "review_required_quality_gate_row_ids", [])

    assert {:error, stale_row_ids_report} = Schema.validate_artifact(stale_row_ids)

    assert Enum.any?(
             stale_row_ids_report["errors"],
             &(&1["path"] == "$.review_required_quality_gate_row_ids" and
                 &1["message"] == "must equal review-required quality-gate row IDs by status")
           )

    review_package = OperatorReview.from_operational_readiness_report(readiness_report)

    assert %{
             "readiness_gate_id" => "resource_availability",
             "resource_blocked_contact_ids_by_blocking_dimension" =>
               ^expected_contact_ids_by_blocking_dimension,
             "resource_blocked_contact_ids_by_spacecraft_id" =>
               ^expected_contact_ids_by_spacecraft,
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"declared" => 1}
           } =
             Enum.find(
               review_package["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    import_manifest = CadenceImport.from_operational_readiness_report(readiness_report)

    assert %{
             "readiness_gate_id" => "resource_availability",
             "resource_blocked_contact_ids_by_blocking_dimension" =>
               ^expected_contact_ids_by_blocking_dimension,
             "resource_blocked_contact_ids_by_spacecraft_id" =>
               ^expected_contact_ids_by_spacecraft,
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"declared" => 1},
             "source_review_row" => %{
               "resource_blocked_contact_ids_by_blocking_dimension" =>
                 ^expected_contact_ids_by_blocking_dimension,
               "resource_blocked_contact_ids_by_spacecraft_id" =>
                 ^expected_contact_ids_by_spacecraft,
               "resource_source_quality_counts" => %{"operator_supplied" => 1},
               "resource_trust_boundary_status_counts" => %{"declared" => 1}
             }
           } =
             Enum.find(
               import_manifest["rows"],
               &(&1["readiness_gate_id"] == "resource_availability")
             )

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(quality_gate_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)

    stale_evidence_contact_ids =
      put_in(
        readiness_report,
        ["evidence", "resource_blocked_contact_ids_by_blocking_dimension"],
        %{"antenna" => []}
      )

    assert {:error, stale_evidence_contact_ids_report} =
             Schema.validate_artifact(stale_evidence_contact_ids)

    assert Enum.any?(
             stale_evidence_contact_ids_report["errors"],
             &(&1["path"] == "$.evidence.resource_blocked_contact_ids_by_blocking_dimension" and
                 &1["message"] ==
                   "must equal gate-derived resource_blocked_contact_ids_by_blocking_dimension")
           )

    invalid_quality_gate_contact_ids =
      update_in(quality_gate_report, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"gate_id" => "resource_availability"} = row ->
            put_in(
              row,
              ["resource_blocked_contact_ids_by_blocking_dimension", "antenna"],
              ["bad id"]
            )

          row ->
            row
        end)
      end)

    assert {:error, invalid_quality_gate_contact_ids_report} =
             Schema.validate_artifact(invalid_quality_gate_contact_ids)

    assert Enum.any?(
             invalid_quality_gate_contact_ids_report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.resource_blocked_contact_ids_by_blocking_dimension\.antenna\[0\]$/)
           )
  end

  test "ready import rows fail closed when source freshness or schema evidence is unsafe" do
    stale_ready_report =
      ready_manifest()
      |> put_in(["rows", Access.at(0), "source_freshness_report"], freshness_report("stale"))
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "review_gate_count" => 1,
             "blocked_gate_count" => 0,
             "evidence" => %{
               "ready_for_import_count" => 1,
               "stale_freshness_count" => 1
             }
           } = stale_ready_report

    assert %{
             "id" => "cadence_import",
             "status" => "review_required",
             "classification" => "review_only",
             "reason" => "source freshness evidence is stale or unknown",
             "ready_for_import_count" => 1,
             "stale_freshness_count" => 1,
             "freshness_status_counts" => %{"stale" => 1},
             "import_status_counts" => %{"ready_for_import" => 1}
           } =
             stale_gate = Enum.find(stale_ready_report["gates"], &(&1["id"] == "cadence_import"))

    stale_quality_gate_report = OperationalReadiness.quality_gate_report(stale_ready_report)

    assert %{
             "gate_id" => "cadence_import",
             "ready_for_import_count" => 1,
             "stale_freshness_count" => 1,
             "freshness_status_counts" => %{"stale" => 1},
             "source_operational_readiness_gate" => ^stale_gate
           } =
             Enum.find(
               stale_quality_gate_report["rows"],
               &(&1["gate_id"] == "cadence_import")
             )

    stale_quality_gate_row =
      Enum.find(
        stale_quality_gate_report["rows"],
        &(&1["gate_id"] == "cadence_import")
      )

    stale_quality_gate_report_id = stale_quality_gate_report["report_id"]
    stale_ready_report_id = stale_ready_report["report_id"]
    stale_quality_gate_row_id = stale_quality_gate_row["id"]

    import_readiness_summary =
      OperationalReadiness.quality_gate_import_readiness_summary(stale_quality_gate_report)

    assert %{
             "schema_contract" => "operational_quality_gate_import_readiness_summary.v1",
             "model" => "artifact_only_quality_gate_import_readiness_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_quality_gate_report_id" => ^stale_quality_gate_report_id,
             "source_readiness_report_id" => ^stale_ready_report_id,
             "import_readiness_row_count" => 1,
             "ready_for_import_count" => 1,
             "manifest_review_required_count" => 0,
             "blocked_import_count" => 0,
             "missing_import_count" => 0,
             "invalid_cadence_import_count" => 0,
             "current_freshness_count" => 0,
             "stale_freshness_count" => 1,
             "unknown_freshness_count" => 0,
             "freshness_status_counts" => %{"stale" => 1},
             "freshness_status_ids" => ["stale"],
             "import_status_counts" => %{"ready_for_import" => 1},
             "import_status_ids" => ["ready_for_import"],
             "cadence_import_status_counts" => %{"present" => 1},
             "cadence_import_status_ids" => ["present"],
             "freshness_review_required" => true,
             "import_preparation_required" => false,
             "import_blocked" => false,
             "quality_gate_row_ids_by_status" => %{
               "review_required" => [^stale_quality_gate_row_id]
             },
             "quality_gate_ids_by_status" => %{"review_required" => ["cadence_import"]},
             "review_required_quality_gate_row_ids" => [^stale_quality_gate_row_id],
             "blocked_quality_gate_row_ids" => [],
             "ready_quality_gate_row_ids" => [],
             "stale_or_unknown_freshness_quality_gate_row_ids" => [^stale_quality_gate_row_id],
             "import_preparation_quality_gate_row_ids" => [],
             "blocked_import_quality_gate_row_ids" => [],
             "import_readiness_gate_ids" => ["cadence_import"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "source" => "quality_gate_report.v1",
               "operator_authority" => "not_granted_by_import_readiness_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             },
             "model_limits" => [
               "quality_gate_import_readiness_summary_routes_only",
               "quality_gate_import_readiness_summary_does_not_approve_or_import"
             ]
           } = import_readiness_summary

    assert OrbitalDynamics.operational_quality_gate_import_readiness_summary(
             stale_quality_gate_report
           ) == import_readiness_summary

    assert OrbitalDynamics.operational_quality_gate_import_readiness_summary(stale_ready_report) ==
             import_readiness_summary

    assert {:ok, %{"schema_contract" => "operational_quality_gate_import_readiness_summary.v1"}} =
             Schema.validate_artifact(import_readiness_summary)

    assert {:ok, import_readiness_schema} =
             Schema.json_schema("operational_quality_gate_import_readiness_summary.v1")

    assert get_in(import_readiness_schema, ["properties", "model", "const"]) ==
             "artifact_only_quality_gate_import_readiness_summary"

    assert get_in(import_readiness_schema, ["properties", "model_limits", "const"]) ==
             import_readiness_summary["model_limits"]

    stale_model_limits =
      Map.put(import_readiness_summary, "model_limits", [
        "quality_gate_import_readiness_summary_routes_only"
      ])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] ==
                   "must match quality gate import-readiness summary model limits")
           )

    stale_import_summary =
      Map.put(import_readiness_summary, "ready_for_import_count", 0)

    assert {:error, stale_import_summary_report} = Schema.validate_artifact(stale_import_summary)

    assert Enum.any?(
             stale_import_summary_report["errors"],
             &(&1["path"] == "$.ready_for_import_count" and
                 &1["message"] == "must equal import_status_counts ready_for_import count")
           )

    stale_freshness_routing_summary =
      Map.put(import_readiness_summary, "freshness_review_required", false)

    assert {:error, stale_freshness_routing_report} =
             Schema.validate_artifact(stale_freshness_routing_summary)

    assert Enum.any?(
             stale_freshness_routing_report["errors"],
             &(&1["path"] == "$.freshness_review_required" and
                 &1["message"] == "must match stale or unknown freshness evidence")
           )

    stale_freshness_row_summary =
      Map.put(
        import_readiness_summary,
        "stale_or_unknown_freshness_quality_gate_row_ids",
        ["missing_row"]
      )

    assert {:error, stale_freshness_row_report} =
             Schema.validate_artifact(stale_freshness_row_summary)

    assert Enum.any?(
             stale_freshness_row_report["errors"],
             &(&1["path"] == "$.stale_or_unknown_freshness_quality_gate_row_ids" and
                 &1["message"] == "must be present in quality-gate row IDs by status")
           )

    stale_review_package = OperatorReview.from_operational_readiness_report(stale_ready_report)

    assert %{
             "readiness_gate_id" => "cadence_import",
             "ready_for_import_count" => 1,
             "stale_freshness_count" => 1,
             "freshness_status_counts" => %{"stale" => 1}
           } =
             Enum.find(
               stale_review_package["rows"],
               &(&1["readiness_gate_id"] == "cadence_import")
             )

    stale_import_manifest = CadenceImport.from_operational_readiness_report(stale_ready_report)

    assert %{
             "readiness_gate_id" => "cadence_import",
             "ready_for_import_count" => 1,
             "stale_freshness_count" => 1,
             "freshness_status_counts" => %{"stale" => 1}
           } =
             Enum.find(
               stale_import_manifest["rows"],
               &(&1["readiness_gate_id"] == "cadence_import")
             )

    schema_failed_ready_report =
      ready_manifest()
      |> put_in(
        ["rows", Access.at(0), "source_schema_validation_report"],
        schema_validation_report("fail")
      )
      |> OperationalReadiness.report()

    assert %{
             "readiness_level" => "blocked",
             "import_classification" => "blocked",
             "status" => "blocked",
             "blocked_gate_count" => 1,
             "evidence" => %{
               "ready_for_import_count" => 1,
               "schema_validation_fail_count" => 1,
               "schema_validation_error_count" => 1
             }
           } = schema_failed_ready_report

    assert %{
             "id" => "cadence_import",
             "status" => "blocked",
             "classification" => "blocked",
             "reason" => "source schema-validation evidence failed",
             "ready_for_import_count" => 1,
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 1,
             "schema_validation_remediation_count" => 1,
             "schema_validation_status_counts" => %{"fail" => 1}
           } =
             schema_gate =
             Enum.find(schema_failed_ready_report["gates"], &(&1["id"] == "cadence_import"))

    schema_quality_gate_report =
      OperationalReadiness.quality_gate_report(schema_failed_ready_report)

    assert %{
             "gate_id" => "cadence_import",
             "ready_for_import_count" => 1,
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 1,
             "schema_validation_status_counts" => %{"fail" => 1},
             "source_operational_readiness_gate" => ^schema_gate
           } =
             Enum.find(
               schema_quality_gate_report["rows"],
               &(&1["gate_id"] == "cadence_import")
             )

    schema_quality_gate_row =
      Enum.find(
        schema_quality_gate_report["rows"],
        &(&1["gate_id"] == "cadence_import")
      )

    schema_quality_gate_report_id = schema_quality_gate_report["report_id"]
    schema_failed_ready_report_id = schema_failed_ready_report["report_id"]
    schema_quality_gate_row_id = schema_quality_gate_row["id"]

    schema_summary =
      OperationalReadiness.quality_gate_schema_validation_summary(schema_quality_gate_report)

    assert %{
             "schema_contract" => "operational_quality_gate_schema_validation_summary.v1",
             "model" => "artifact_only_quality_gate_schema_validation_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_quality_gate_report_id" => ^schema_quality_gate_report_id,
             "source_readiness_report_id" => ^schema_failed_ready_report_id,
             "schema_validation_row_count" => 1,
             "schema_validation_pass_count" => 0,
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 1,
             "schema_validation_warning_count" => 0,
             "schema_validation_remediation_count" => 1,
             "schema_validation_status_counts" => %{"fail" => 1},
             "schema_validation_status_ids" => ["fail"],
             "schema_validation_import_blocked" => true,
             "quality_gate_row_ids_by_status" => %{"blocked" => [^schema_quality_gate_row_id]},
             "quality_gate_ids_by_status" => %{"blocked" => ["cadence_import"]},
             "blocked_quality_gate_row_ids" => [^schema_quality_gate_row_id],
             "review_required_quality_gate_row_ids" => [],
             "failed_schema_validation_quality_gate_row_ids" => [^schema_quality_gate_row_id],
             "schema_validation_gate_ids" => ["cadence_import"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "source" => "quality_gate_report.v1",
               "operator_authority" => "not_granted_by_schema_validation_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             },
             "model_limits" => [
               "quality_gate_schema_validation_summary_routes_only",
               "quality_gate_schema_validation_summary_does_not_approve_or_import"
             ]
           } = schema_summary

    assert OrbitalDynamics.operational_quality_gate_schema_validation_summary(
             schema_quality_gate_report
           ) == schema_summary

    assert OrbitalDynamics.operational_quality_gate_schema_validation_summary(
             schema_failed_ready_report
           ) == schema_summary

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(stale_ready_report)

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(schema_quality_gate_report)

    assert {:ok, %{"schema_contract" => "operational_quality_gate_schema_validation_summary.v1"}} =
             Schema.validate_artifact(schema_summary)

    assert {:ok, schema_validation_schema} =
             Schema.json_schema("operational_quality_gate_schema_validation_summary.v1")

    assert get_in(schema_validation_schema, ["properties", "model", "const"]) ==
             "artifact_only_quality_gate_schema_validation_summary"

    assert get_in(schema_validation_schema, ["properties", "model_limits", "const"]) ==
             schema_summary["model_limits"]

    stale_model_limits =
      Map.put(schema_summary, "model_limits", [
        "quality_gate_schema_validation_summary_routes_only"
      ])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] ==
                   "must match quality gate schema-validation summary model limits")
           )

    stale_schema_summary =
      Map.put(schema_summary, "schema_validation_fail_count", 0)

    assert {:error, stale_schema_summary_report} = Schema.validate_artifact(stale_schema_summary)

    assert Enum.any?(
             stale_schema_summary_report["errors"],
             &(&1["path"] == "$.schema_validation_fail_count" and
                 &1["message"] == "must equal schema_validation_status_counts fail count")
           )

    stale_schema_blocked_summary =
      Map.put(schema_summary, "schema_validation_import_blocked", false)

    assert {:error, stale_schema_blocked_report} =
             Schema.validate_artifact(stale_schema_blocked_summary)

    assert Enum.any?(
             stale_schema_blocked_report["errors"],
             &(&1["path"] == "$.schema_validation_import_blocked" and
                 &1["message"] == "must match failed or errored schema-validation evidence")
           )

    stale_schema_failed_row_summary =
      Map.put(schema_summary, "failed_schema_validation_quality_gate_row_ids", ["missing_row"])

    assert {:error, stale_schema_failed_row_report} =
             Schema.validate_artifact(stale_schema_failed_row_summary)

    assert Enum.any?(
             stale_schema_failed_row_report["errors"],
             &(&1["path"] == "$.failed_schema_validation_quality_gate_row_ids" and
                 &1["message"] == "must be present in quality-gate row IDs by status")
           )

    invalid_gate_freshness_count =
      put_in(stale_ready_report, ["gates", Access.at(4), "freshness_status_counts", "stale"], -1)

    assert {:error, invalid_gate_report} = Schema.validate_artifact(invalid_gate_freshness_count)

    assert Enum.any?(
             invalid_gate_report["errors"],
             &(&1["path"] == "$.gates[4].freshness_status_counts.stale")
           )
  end

  test "import readiness summaries expose analysis-only quality-gate row routing" do
    quality_gate_report =
      ready_manifest()
      |> OperationalReadiness.report()
      |> OperationalReadiness.quality_gate_report()

    analysis_only_quality_gate_report =
      update_in(quality_gate_report, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"gate_id" => "cadence_import"} = row ->
            row
            |> Map.merge(%{
              "status" => "analysis_only",
              "classification" => "analysis_only",
              "reason" => "Cadence import evidence is analysis-only",
              "ready_for_import_count" => 0,
              "import_status_counts" => %{"not_applicable" => 1},
              "cadence_import_status_counts" => %{"not_applicable" => 1}
            })
            |> put_in(["source_operational_readiness_gate", "status"], "analysis_only")
            |> put_in(["source_operational_readiness_gate", "classification"], "analysis_only")

          row ->
            row
        end)
      end)

    analysis_only_row =
      Enum.find(analysis_only_quality_gate_report["rows"], &(&1["gate_id"] == "cadence_import"))

    assert %{
             "id" => analysis_only_row_id,
             "status" => "analysis_only",
             "classification" => "analysis_only",
             "import_status_counts" => %{"not_applicable" => 1},
             "cadence_import_status_counts" => %{"not_applicable" => 1}
           } = analysis_only_row

    import_readiness_summary =
      OperationalReadiness.quality_gate_import_readiness_summary(
        analysis_only_quality_gate_report
      )

    assert %{
             "schema_contract" => "operational_quality_gate_import_readiness_summary.v1",
             "import_readiness_row_count" => 1,
             "ready_for_import_count" => 0,
             "manifest_review_required_count" => 0,
             "blocked_import_count" => 0,
             "missing_import_count" => 0,
             "invalid_cadence_import_count" => 0,
             "import_status_counts" => %{"not_applicable" => 1},
             "import_status_ids" => ["not_applicable"],
             "cadence_import_status_counts" => %{"not_applicable" => 1},
             "cadence_import_status_ids" => ["not_applicable"],
             "freshness_review_required" => false,
             "import_preparation_required" => false,
             "import_blocked" => false,
             "quality_gate_row_ids_by_status" => %{
               "analysis_only" => [^analysis_only_row_id]
             },
             "quality_gate_ids_by_status" => %{"analysis_only" => ["cadence_import"]},
             "review_required_quality_gate_row_ids" => [],
             "blocked_quality_gate_row_ids" => [],
             "ready_quality_gate_row_ids" => [],
             "analysis_only_quality_gate_row_ids" => [^analysis_only_row_id],
             "stale_or_unknown_freshness_quality_gate_row_ids" => [],
             "import_preparation_quality_gate_row_ids" => [],
             "blocked_import_quality_gate_row_ids" => [],
             "import_readiness_gate_ids" => ["cadence_import"]
           } = import_readiness_summary

    assert {:ok, %{"schema_contract" => "operational_quality_gate_import_readiness_summary.v1"}} =
             Schema.validate_artifact(import_readiness_summary)

    stale_analysis_only_rows =
      Map.put(import_readiness_summary, "analysis_only_quality_gate_row_ids", [])

    assert {:error, stale_analysis_only_rows_report} =
             Schema.validate_artifact(stale_analysis_only_rows)

    assert Enum.any?(
             stale_analysis_only_rows_report["errors"],
             &(&1["path"] == "$.analysis_only_quality_gate_row_ids" and
                 &1["message"] == "must equal analysis-only quality-gate row IDs by status")
           )
  end

  test "derives review-only readiness from boolean-gated provider counteroffer evidence" do
    readiness_report =
      provider_counteroffer_report()
      |> OperationalReadiness.report()

    assert %{
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "review_gate_count" => 2,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "evidence" => %{
               "review_row_count" => 1,
               "import_row_count" => 1,
               "review_required_count" => 1,
               "manifest_review_required_count" => 1,
               "approval_status_counts" => %{"operator_review_required" => 1},
               "import_status_counts" => %{"review_required_before_import" => 1}
             }
           } = readiness_report

    assert %{
             "id" => "operator_review",
             "status" => "review_required",
             "classification" => "review_only"
           } = Enum.find(readiness_report["gates"], &(&1["id"] == "operator_review"))

    assert %{
             "id" => "cadence_import",
             "status" => "review_required",
             "classification" => "review_only"
           } = Enum.find(readiness_report["gates"], &(&1["id"] == "cadence_import"))

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)
  end

  test "derives review-only readiness from boolean-gated candidate rejection evidence" do
    readiness_report =
      candidate_rejection_report()
      |> OperationalReadiness.report()

    assert %{
             "source_artifact_type" => "candidate_rejection_report.v1",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "review_gate_count" => 2,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "evidence" => %{
               "review_row_count" => 1,
               "import_row_count" => 1,
               "review_required_count" => 1,
               "manifest_review_required_count" => 1,
               "approval_status_counts" => %{"operator_review_required" => 1},
               "import_status_counts" => %{"review_required_before_import" => 1}
             }
           } = readiness_report

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)
  end

  defp ready_manifest do
    %{
      "schema_contract" => "cadence_import_manifest.v1",
      "model" => "cadence_import_manifest_fixture",
      "manifest_id" => "manifest_1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "model_limits" => ["adapter_handoff_only"],
      "rows" => [
        %{
          "id" => "import_1",
          "rank" => 1,
          "import_action" => "import_replacement_activity",
          "import_status" => "ready_for_import",
          "cadence_import_status" => "present"
        }
      ]
    }
  end

  defp review_required_manifest do
    ready_manifest()
    |> put_in(["rows"], [
      %{
        "id" => "import_1",
        "rank" => 1,
        "import_action" => "review_operator_row",
        "import_status" => "review_required_before_import",
        "cadence_import_status" => "present"
      }
    ])
  end

  defp blocked_manifest do
    ready_manifest()
    |> put_in(["rows"], [
      %{
        "id" => "import_1",
        "rank" => 1,
        "import_action" => "review_operator_row",
        "import_status" => "blocked_missing_cadence_import",
        "cadence_import_status" => "invalid"
      }
    ])
  end

  defp policy_decision(classification) do
    %{
      "schema_contract" => "policy_decision.v1",
      "classification" => classification,
      "policy_bundle_id" => "mission_ops_policy",
      "model_limits" => ["artifact_only_policy_classification"]
    }
  end

  defp provider_counteroffer_report do
    contacts = [
      %{
        id: :dl_counteroffer,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 140.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_counteroffer_window,
          station_id: :equator_prime,
          availability: :available,
          directions: [:downlink],
          start_s: 130.0,
          end_s: 170.0,
          counteroffer_id: :provider_offer_1,
          counteroffer_status: :proposed,
          counteroffer_reason_code: :provider_shifted_window,
          counteroffer_cost_delta: 125.5,
          schedule_lock_deadline_s: 150.0,
          counteroffer_start_s: 130.0,
          counteroffer_end_s: 170.0
        }
      ]
    }

    {_annotated, station_report} =
      StationCalendar.overlay_contacts(contacts, provider, source: "provider_counteroffers")

    StationCalendar.provider_counteroffer_report(station_report)
  end

  defp candidate_rejection_report do
    Timeline.candidate_rejection_report(
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

  defp freshness_report(status) do
    %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "generated_at" => "2026-05-14T00:00:00Z",
      "source" => "accepted_planning_state",
      "accepted_state_snapshot_id" => "accepted_state_1",
      "accepted_state_age_s" => 120.0,
      "max_accepted_state_age_s" => 60.0,
      "horizon_start_s" => 0.0,
      "horizon_end_s" => 600.0,
      "accepted_state_epoch_s" => -120.0,
      "state_quality" => "planning_accepted",
      "allowed_state_quality_levels" => ["planning_accepted"],
      "status" => status,
      "stale_reasons" =>
        if(status == "stale", do: ["accepted_snapshot_older_than_policy"], else: []),
      "unknown_reasons" =>
        if(status == "unknown", do: ["accepted_snapshot_age_missing"], else: [])
    }
  end

  defp schema_validation_report("fail") do
    %{
      "schema_contract" => "schema_validation_report.v1",
      "model" => "artifact_contract_validation",
      "validation_mode" => "artifact_file",
      "validated_contract" => "campaign_plan.v1",
      "validated_artifact_family" => "campaign_plan",
      "status" => "fail",
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
      "warnings" => [],
      "remediation" => [
        %{
          "path" => "$.plan_id",
          "category" => "missing_required_field",
          "action" => "Populate this required field"
        }
      ],
      "artifact_path" => "study_results/bad_campaign.json",
      "assumptions" => %{"validation_scope" => "artifact_contract"}
    }
  end

  defp schema_validation_report("pass") do
    "fail"
    |> schema_validation_report()
    |> Map.merge(%{
      "status" => "pass",
      "error_count" => 0,
      "warning_count" => 0,
      "remediation_count" => 0,
      "errors" => [],
      "remediation" => [],
      "artifact_path" => "study_results/leo_constellation_campaign.json"
    })
  end

  defp assert_readiness_review_row(report, action, approval_status) do
    package = OperatorReview.from_operational_readiness_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    expected_review_count = 1 + Enum.count(report["gates"], &(&1["status"] != "passed"))

    assert %{
             "source_artifact_type" => "operational_readiness_report.v1",
             "source_artifact_id" => report_id,
             "review_count" => ^expected_review_count,
             "operational_readiness_review_count" => ^expected_review_count,
             "review_type_counts" => %{"operational_readiness_review" => ^expected_review_count},
             "rows" => rows
           } = package

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "operational_readiness_report",
             "subject_id" => ^report_id,
             "action" => ^action,
             "required_operator_action" => ^action,
             "approval_status" => ^approval_status,
             "import_classification" => import_classification,
             "readiness_level" => readiness_level,
             "operational_readiness_status" => status,
             "gate_count" => gate_count,
             "passed_gate_count" => passed_gate_count,
             "review_gate_count" => review_gate_count,
             "analysis_gate_count" => analysis_gate_count,
             "blocked_gate_count" => blocked_gate_count,
             "gates" => gates,
             "evidence" => evidence,
             "source_operational_readiness_report" => source_report
           } = Enum.find(rows, &is_nil(&1["readiness_gate_id"]))

    gate_rows = Enum.filter(rows, & &1["readiness_gate_id"])
    non_passed_gates = Enum.filter(report["gates"], &(&1["status"] != "passed"))

    assert Enum.map(gate_rows, & &1["readiness_gate_id"]) ==
             Enum.map(non_passed_gates, & &1["id"])

    assert report_id == report["report_id"]
    assert import_classification == report["import_classification"]
    assert readiness_level == report["readiness_level"]
    assert status == report["status"]
    assert gate_count == report["gate_count"]
    assert passed_gate_count == report["passed_gate_count"]
    assert review_gate_count == report["review_gate_count"]
    assert analysis_gate_count == report["analysis_gate_count"]
    assert blocked_gate_count == report["blocked_gate_count"]
    assert gates == report["gates"]
    assert evidence == report["evidence"]
    assert source_report["report_id"] == report["report_id"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  defp assert_readiness_import_row(report, import_status) do
    manifest = CadenceImport.from_operational_readiness_report(report)

    assert CadenceImport.manifest(
             %{schema_contract: "operational_readiness_report.v1"}
             |> Map.merge(report)
           ) ==
             manifest

    expected_row_count = 1 + Enum.count(report["gates"], &(&1["status"] != "passed"))

    assert %{
             "source_artifact_type" => "operational_readiness_report.v1",
             "source_artifact_id" => report_id,
             "row_count" => ^expected_row_count,
             "source_review_type_counts" => %{
               "operational_readiness_review" => ^expected_row_count
             },
             "import_action_counts" => %{"review_operational_readiness" => ^expected_row_count},
             "rows" => rows
           } = manifest

    assert %{
             "import_action" => "review_operational_readiness",
             "import_status" => ^import_status,
             "source_review_type" => "operational_readiness_review",
             "readiness_level" => readiness_level,
             "import_classification" => import_classification,
             "operational_readiness_status" => status,
             "gate_count" => gate_count,
             "passed_gate_count" => passed_gate_count,
             "review_gate_count" => review_gate_count,
             "analysis_gate_count" => analysis_gate_count,
             "blocked_gate_count" => blocked_gate_count,
             "gates" => gates,
             "evidence" => evidence,
             "source_operational_readiness_report" => source_report
           } = Enum.find(rows, &is_nil(&1["readiness_gate_id"]))

    gate_rows = Enum.filter(rows, & &1["readiness_gate_id"])
    non_passed_gates = Enum.filter(report["gates"], &(&1["status"] != "passed"))

    assert Enum.map(gate_rows, & &1["readiness_gate_id"]) ==
             Enum.map(non_passed_gates, & &1["id"])

    assert report_id == report["report_id"]
    assert readiness_level == report["readiness_level"]
    assert import_classification == report["import_classification"]
    assert status == report["status"]
    assert gate_count == report["gate_count"]
    assert passed_gate_count == report["passed_gate_count"]
    assert review_gate_count == report["review_gate_count"]
    assert analysis_gate_count == report["analysis_gate_count"]
    assert blocked_gate_count == report["blocked_gate_count"]
    assert gates == report["gates"]
    assert evidence == report["evidence"]
    assert source_report["report_id"] == report["report_id"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end
end
