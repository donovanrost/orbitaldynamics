defmodule OrbitalDynamics.OperationalReadiness do
  @moduledoc """
  Classifies artifact-only operational readiness from review/import evidence.

  The report is a gate summary over existing operator-review packages and
  Cadence-import manifests. It does not approve work, mutate schedules, or call
  external import APIs.
  """

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperationalReadiness.AdapterBoundaryEvidence
  alias OrbitalDynamics.OperationalReadiness.EvidenceNormalization
  alias OrbitalDynamics.OperationalReadiness.GateSummary
  alias OrbitalDynamics.OperationalReadiness.OperatorTrainingEvidence
  alias OrbitalDynamics.OperationalReadiness.OperationalModeDecision
  alias OrbitalDynamics.OperationalReadiness.QualityGateOperatorTrainingSummary
  alias OrbitalDynamics.OperationalReadiness.QualityGateImportReadinessSummary
  alias OrbitalDynamics.OperationalReadiness.QualityGateSchemaValidationSummary
  alias OrbitalDynamics.OperationalReadiness.ResourceAvailabilityEvidence
  alias OrbitalDynamics.OperationalReadiness.TimelinePublicationContext

  @schema_contract "operational_readiness_report.v1"
  @import_eligibility_summary_schema_contract "operational_import_eligibility_summary.v1"
  @gate_summary_schema_contract "operational_readiness_gate_summary.v1"
  @execution_boundary_summary_schema_contract "operational_execution_boundary_summary.v1"
  @quality_gate_schema_contract "quality_gate_report.v1"
  @quality_gate_summary_schema_contract "operational_quality_gate_summary.v1"
  @quality_gate_unavailable_resource_summary_schema_contract "operational_quality_gate_unavailable_resource_summary.v1"
  @quality_gate_operator_training_summary_schema_contract "operational_quality_gate_operator_training_summary.v1"
  @quality_gate_import_readiness_summary_schema_contract "operational_quality_gate_import_readiness_summary.v1"
  @schema_version 1
  @import_classifications ~w(importable review_only analysis_only blocked)
  @readiness_levels ~w(import_eligible operator_review analysis_only blocked)
  @gate_statuses ~w(passed review_required analysis_only blocked)
  @freshness_statuses ~w(current stale unknown)
  @doc """
  Declares the operational-readiness report model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      model: :artifact_only_operational_readiness_classifier,
      validation_level: :artifact_contract,
      import_eligibility_summary_artifact_contract: @import_eligibility_summary_schema_contract,
      gate_summary_artifact_contract: @gate_summary_schema_contract,
      execution_boundary_summary_artifact_contract: @execution_boundary_summary_schema_contract,
      quality_gate_summary_artifact_contract: @quality_gate_summary_schema_contract,
      quality_gate_unavailable_resource_summary_artifact_contract:
        @quality_gate_unavailable_resource_summary_schema_contract,
      quality_gate_operator_training_summary_artifact_contract:
        @quality_gate_operator_training_summary_schema_contract,
      quality_gate_schema_validation_summary_artifact_contract:
        QualityGateSchemaValidationSummary.schema_contract(),
      quality_gate_import_readiness_summary_artifact_contract:
        @quality_gate_import_readiness_summary_schema_contract,
      import_classifications: @import_classifications,
      readiness_levels: @readiness_levels,
      gate_statuses: @gate_statuses,
      freshness_statuses: @freshness_statuses,
      import_statuses: CadenceImport.capability().import_statuses,
      cadence_import_statuses: CadenceImport.capability().cadence_import_statuses,
      analysis_modes: OperationalModeDecision.analysis_modes(),
      analysis_mode_aliases: OperationalModeDecision.analysis_mode_aliases(),
      gates: [
        "source_contract",
        "operational_mode",
        "adapter_boundary",
        "mission_policy",
        "operator_training",
        "resource_availability",
        "operator_review",
        "cadence_import"
      ],
      readiness_helpers: [
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
      ],
      summary_semantics: [
        :import_eligibility_summary,
        :readiness_summary_row_derived_gate_counts,
        :gate_status_routing_id_sets,
        :gate_classification_routing_id_sets,
        :quality_gate_report_routing_id_sets,
        :quality_gate_report_row_derived_classification,
        :quality_gate_report_execution_boundary,
        :quality_gate_summary,
        :quality_gate_summary_row_derived_counts,
        :quality_gate_resource_availability_row_context,
        :quality_gate_unavailable_resource_summary,
        :quality_gate_unavailable_resource_routing_id_sets,
        :quality_gate_operator_training_summary,
        :quality_gate_operator_training_routing_id_sets,
        :quality_gate_schema_validation_summary,
        :quality_gate_schema_validation_routing_id_sets,
        :quality_gate_import_readiness_summary,
        :quality_gate_import_readiness_routing_id_sets,
        :quality_gate_import_readiness_freshness_status_values,
        :quality_gate_import_readiness_import_status_values,
        :quality_gate_import_readiness_cadence_import_status_values,
        :quality_gate_cadence_import_row_context,
        :resource_availability_quality_gate,
        :execution_boundary_summary
      ],
      readiness_evidence_semantics: [
        :readiness_review_and_import_row_counts,
        :readiness_review_status_count_maps,
        :readiness_import_status_count_maps,
        :readiness_timeline_publication_context,
        :readiness_freshness_status_count_maps,
        :readiness_schema_validation_status_and_issue_counts,
        :readiness_source_model_and_limit_count_maps,
        :readiness_mission_policy_classification_count_maps,
        :readiness_operator_training_requirement_count_maps,
        :readiness_adapter_boundary_status_count_maps,
        :readiness_adapter_boundary_untrusted_count_maps,
        :readiness_resource_availability_reason_count_maps,
        :readiness_resource_availability_reason_ids,
        :readiness_unavailable_resource_reason_ids,
        :readiness_station_availability_reason_count_maps
      ],
      quality_gate_row_semantics: [
        :quality_gate_status_and_classification_counts,
        :quality_gate_status_and_classification_id_sets,
        :quality_gate_adapter_boundary_status_counts,
        :quality_gate_operator_training_requirement_context,
        :quality_gate_resource_availability_reason_ids,
        :quality_gate_station_availability_reason_ids,
        :quality_gate_unavailable_resource_reason_ids,
        :quality_gate_resource_blocking_dimension_counts,
        :quality_gate_resource_blocked_contact_id_maps,
        :quality_gate_cadence_import_status_count_maps,
        :quality_gate_freshness_status_count_maps,
        :quality_gate_schema_validation_status_and_issue_counts,
        :quality_gate_timeline_publication_context
      ],
      public_facades: [
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
      ],
      quality_gate_contract: @quality_gate_schema_contract,
      handoff_artifacts: [
        "operator_review_package.v1",
        "cadence_import_manifest.v1"
      ],
      handoff_review_type: "operational_readiness_review",
      handoff_import_action: "review_operational_readiness",
      known_limits: [
        :artifact_only,
        :does_not_write_cadence,
        :does_not_approve_operator_actions,
        :does_not_execute_commands,
        :uses_declared_review_and_import_evidence
      ]
    }
  end

  @doc """
  Builds an `operational_readiness_report.v1` from an artifact, review package,
  or Cadence import manifest.
  """
  def report(artifact, opts \\ [])

  def report(%{"schema_contract" => @schema_contract} = report, _opts), do: report

  def report(%{schema_contract: @schema_contract} = report, _opts), do: stringify_keys(report)

  def report(%{} = artifact, opts) when is_list(opts) do
    artifact = stringify_keys(artifact)
    review_package = review_package_for(artifact)
    import_manifest = import_manifest_for(artifact, review_package)

    build_report(artifact, review_package, import_manifest, opts)
  end

  def report(_artifact, _opts) do
    raise ArgumentError, "operational readiness artifact must be a map"
  end

  @doc """
  Builds a compact import-eligibility summary from readiness evidence.

  This helper derives its decision from `report/2` and returns only the
  classification, gate counts, non-passed gates, and boundary assumptions. It
  does not write to Cadence, approve operator actions, or execute commands.
  """
  def import_eligibility(artifact, opts \\ []) do
    artifact
    |> report(opts)
    |> import_eligibility_summary()
  end

  @doc """
  Builds a compact gate-routing summary from readiness evidence.

  This helper keeps the full readiness gates visible while grouping gate IDs by
  status and classification. It does not write to Cadence, approve operator
  actions, or execute commands.
  """
  def gate_summary(artifact, opts \\ []) do
    artifact
    |> report(opts)
    |> GateSummary.build(@gate_summary_schema_contract)
  end

  @doc """
  Builds a compact execution-boundary summary from readiness evidence.

  This helper exposes whether a readiness result is import eligible while
  keeping command execution, Cadence writes, and operator authority explicitly
  out of scope. It does not write to Cadence, approve operator actions, or
  execute commands.
  """
  def execution_boundary_summary(artifact, opts \\ []) do
    artifact
    |> report(opts)
    |> execution_boundary_summary_from_report()
  end

  @doc """
  Builds a standalone quality-gate report from operational-readiness evidence.

  The report is a deterministic, row-oriented projection of readiness gates for
  adapters that need machine-readable gate routing without reopening the full
  readiness report. It does not write to Cadence, approve operator actions, or
  execute commands.
  """
  def quality_gate_report(artifact, opts \\ [])

  def quality_gate_report(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_report
  end

  def quality_gate_report(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_report(opts)
  end

  def quality_gate_report(artifact, opts) do
    artifact
    |> report(opts)
    |> quality_gate_report_from_readiness()
  end

  @doc """
  Builds a compact row-derived summary from quality-gate rows.

  This helper accepts a `quality_gate_report.v1` directly or derives one from
  readiness evidence. It summarizes gate status/classification routing only; it
  does not write to Cadence, approve operator actions, or execute commands.
  """
  def quality_gate_summary(artifact, opts \\ [])

  def quality_gate_summary(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_summary_from_report(quality_gate_report)
  end

  def quality_gate_summary(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_summary(opts)
  end

  def quality_gate_summary(artifact, opts) do
    artifact
    |> quality_gate_report(opts)
    |> quality_gate_summary_from_report()
  end

  @doc """
  Builds a compact unavailable-resource routing summary from quality-gate rows.

  This helper accepts a `quality_gate_report.v1` directly or derives one from
  readiness evidence. It only summarizes artifact rows for review/import
  routing; it does not write to Cadence, approve operator actions, or execute
  commands.
  """
  def quality_gate_unavailable_resource_summary(artifact, opts \\ [])

  def quality_gate_unavailable_resource_summary(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_unavailable_resource_summary_from_report(quality_gate_report)
  end

  def quality_gate_unavailable_resource_summary(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_unavailable_resource_summary(opts)
  end

  def quality_gate_unavailable_resource_summary(artifact, opts) do
    artifact
    |> quality_gate_report(opts)
    |> quality_gate_unavailable_resource_summary_from_report()
  end

  @doc """
  Builds a compact operator-training routing summary from quality-gate rows.

  This helper accepts a `quality_gate_report.v1` directly or derives one from
  readiness evidence. It summarizes existing operator-training quality-gate
  role, training, certification, and qualification fields for review/import
  routing only; it does not write to Cadence, approve operator actions, or
  execute commands.
  """
  def quality_gate_operator_training_summary(artifact, opts \\ [])

  def quality_gate_operator_training_summary(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_operator_training_summary_from_report(quality_gate_report)
  end

  def quality_gate_operator_training_summary(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_operator_training_summary(opts)
  end

  def quality_gate_operator_training_summary(artifact, opts) do
    artifact
    |> quality_gate_report(opts)
    |> quality_gate_operator_training_summary_from_report()
  end

  @doc """
  Builds a compact schema-validation routing summary from quality-gate rows.

  This helper accepts a `quality_gate_report.v1` directly or derives one from
  readiness evidence. It summarizes existing Cadence-import quality-gate
  schema-validation fields for review/import routing only; it does not write to
  Cadence, approve operator actions, or execute commands.
  """
  def quality_gate_schema_validation_summary(artifact, opts \\ [])

  def quality_gate_schema_validation_summary(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_schema_validation_summary_from_report(quality_gate_report)
  end

  def quality_gate_schema_validation_summary(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_schema_validation_summary(opts)
  end

  def quality_gate_schema_validation_summary(artifact, opts) do
    artifact
    |> quality_gate_report(opts)
    |> quality_gate_schema_validation_summary_from_report()
  end

  @doc """
  Builds a compact import-readiness routing summary from quality-gate rows.

  This helper accepts a `quality_gate_report.v1` directly or derives one from
  readiness evidence. It summarizes existing Cadence-import quality-gate
  freshness and import-status fields for review/import routing only; it does not
  write to Cadence, approve operator actions, or execute commands.
  """
  def quality_gate_import_readiness_summary(artifact, opts \\ [])

  def quality_gate_import_readiness_summary(
        %{"schema_contract" => @quality_gate_schema_contract} = quality_gate_report,
        _opts
      ) do
    quality_gate_import_readiness_summary_from_report(quality_gate_report)
  end

  def quality_gate_import_readiness_summary(
        %{schema_contract: @quality_gate_schema_contract} = quality_gate_report,
        opts
      ) do
    quality_gate_report
    |> stringify_keys()
    |> quality_gate_import_readiness_summary(opts)
  end

  def quality_gate_import_readiness_summary(artifact, opts) do
    artifact
    |> quality_gate_report(opts)
    |> quality_gate_import_readiness_summary_from_report()
  end

  defp import_eligibility_summary(report) do
    gates = Map.get(report, "gates", []) |> Enum.filter(&is_map/1)
    gate_counts = GateSummary.counts(gates)

    non_passed_gates =
      gates
      |> Enum.reject(&(&1["status"] == "passed"))

    %{
      "schema_contract" => @import_eligibility_summary_schema_contract,
      "model" => "artifact_only_import_eligibility_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "readiness_level" => report["readiness_level"],
      "import_classification" => report["import_classification"],
      "status" => report["status"],
      "import_eligible" => report["import_classification"] == "importable",
      "gate_count" => gate_counts.gate_count,
      "passed_gate_count" => gate_counts.passed_gate_count,
      "review_gate_count" => gate_counts.review_gate_count,
      "analysis_gate_count" => gate_counts.analysis_gate_count,
      "blocked_gate_count" => gate_counts.blocked_gate_count,
      "non_passed_gate_count" => length(non_passed_gates),
      "non_passed_gates" => non_passed_gates,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => [
        "operational_import_eligibility_summary_routes_only",
        "operational_import_eligibility_summary_does_not_approve_or_import"
      ]
    }
  end

  defp execution_boundary_summary_from_report(report) do
    gates = Map.get(report, "gates", []) |> Enum.filter(&is_map/1)
    operational_mode_gate = Enum.find(gates, &(&1["id"] == "operational_mode"))
    non_passed_gates = Enum.reject(gates, &(&1["status"] == "passed"))
    import_eligible? = report["import_classification"] == "importable"
    gate_counts = GateSummary.counts(gates)

    %{
      "schema_contract" => @execution_boundary_summary_schema_contract,
      "model" => "artifact_only_operational_execution_boundary_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "readiness_level" => report["readiness_level"],
      "import_classification" => report["import_classification"],
      "status" => report["status"],
      "import_eligible" => import_eligible?,
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => execution_boundary(report["import_classification"]),
      "analysis_mode" => Map.get(operational_mode_gate || %{}, "analysis_mode"),
      "analysis_mode_source" => Map.get(operational_mode_gate || %{}, "analysis_mode_source"),
      "operational_mode_gate" => operational_mode_gate,
      "gate_count" => gate_counts.gate_count,
      "passed_gate_count" => gate_counts.passed_gate_count,
      "review_gate_count" => gate_counts.review_gate_count,
      "analysis_gate_count" => gate_counts.analysis_gate_count,
      "blocked_gate_count" => gate_counts.blocked_gate_count,
      "non_passed_gate_count" => length(non_passed_gates),
      "non_passed_gate_ids" => Enum.map(non_passed_gates, & &1["id"]),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write_no_command_execution",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_execution_boundary_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "operational_execution_boundary_summary_routes_only",
        "operational_execution_boundary_summary_does_not_execute_or_import"
      ]
    }
    |> compact_map()
  end

  defp execution_boundary("importable"), do: "adapter_handoff_only"
  defp execution_boundary("review_only"), do: "operator_review_required_before_import"
  defp execution_boundary("analysis_only"), do: "analysis_only_not_for_execution"
  defp execution_boundary("blocked"), do: "blocked_not_for_import_or_execution"

  defp quality_gate_report_from_readiness(%{} = readiness_report) do
    gates = Map.get(readiness_report, "gates", []) |> Enum.filter(&is_map/1)

    rows =
      gates
      |> Enum.with_index(1)
      |> Enum.map(fn {gate, rank} -> quality_gate_row(gate, readiness_report, rank) end)

    import_classification = import_classification(rows)

    %{
      "schema_contract" => @quality_gate_schema_contract,
      "schema_version" => @schema_version,
      "model" => "artifact_only_operational_quality_gate_report",
      "report_id" =>
        quality_gate_report_id(
          readiness_report["source_artifact_type"],
          readiness_report["source_artifact_id"]
        ),
      "source_artifact_type" => readiness_report["source_artifact_type"],
      "source_artifact_id" => readiness_report["source_artifact_id"],
      "source_readiness_report_id" => readiness_report["report_id"],
      "readiness_level" => readiness_level(import_classification),
      "import_classification" => import_classification,
      "status" => report_status(import_classification),
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => execution_boundary(import_classification),
      "gate_count" => length(rows),
      "passed_gate_count" => GateSummary.count(rows, "passed"),
      "review_gate_count" => GateSummary.count(rows, "review_required"),
      "analysis_gate_count" => GateSummary.count(rows, "analysis_only"),
      "blocked_gate_count" => GateSummary.count(rows, "blocked"),
      "gate_status_counts" => GateSummary.field_counts(rows, "status"),
      "gate_classification_counts" => GateSummary.field_counts(rows, "classification"),
      "gate_ids_by_status" => quality_gate_ids_by(rows, "status"),
      "gate_ids_by_classification" => quality_gate_ids_by(rows, "classification"),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by(rows, "status"),
      "quality_gate_row_ids_by_classification" => quality_gate_row_ids_by(rows, "classification"),
      "passed_gate_ids" => quality_gate_ids(rows, "passed"),
      "review_required_gate_ids" => quality_gate_ids(rows, "review_required"),
      "analysis_only_gate_ids" => quality_gate_ids(rows, "analysis_only"),
      "blocked_gate_ids" => quality_gate_ids(rows, "blocked"),
      "rows" => rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_quality_gate_report"
      },
      "model_limits" => [
        "quality_gate_report_derives_classification_from_gate_rows",
        "quality_gate_report_does_not_approve_or_import"
      ]
    }
  end

  defp quality_gate_summary_from_report(%{} = quality_gate_report) do
    report = stringify_keys(quality_gate_report)
    rows = rows(report)
    non_passed_rows = Enum.reject(rows, &(&1["status"] == "passed"))

    %{
      "schema_contract" => @quality_gate_summary_schema_contract,
      "model" => "artifact_only_quality_gate_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "source_quality_gate_report_id" => report["report_id"],
      "source_readiness_report_id" => report["source_readiness_report_id"],
      "readiness_level" => readiness_level(import_classification(rows)),
      "import_classification" => import_classification(rows),
      "status" => report_status(import_classification(rows)),
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => execution_boundary(import_classification(rows)),
      "gate_count" => length(rows),
      "passed_gate_count" => GateSummary.count(rows, "passed"),
      "review_gate_count" => GateSummary.count(rows, "review_required"),
      "analysis_gate_count" => GateSummary.count(rows, "analysis_only"),
      "blocked_gate_count" => GateSummary.count(rows, "blocked"),
      "non_passed_gate_count" => length(non_passed_rows),
      "gate_status_counts" => GateSummary.field_counts(rows, "status"),
      "gate_classification_counts" => GateSummary.field_counts(rows, "classification"),
      "gate_ids_by_status" => quality_gate_ids_by(rows, "status"),
      "gate_ids_by_classification" => quality_gate_ids_by(rows, "classification"),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by(rows, "status"),
      "quality_gate_row_ids_by_classification" => quality_gate_row_ids_by(rows, "classification"),
      "passed_gate_ids" => quality_gate_ids(rows, "passed"),
      "review_required_gate_ids" => quality_gate_ids(rows, "review_required"),
      "analysis_only_gate_ids" => quality_gate_ids(rows, "analysis_only"),
      "blocked_gate_ids" => quality_gate_ids(rows, "blocked"),
      "non_passed_gate_ids" =>
        non_passed_rows |> Enum.map(& &1["gate_id"]) |> stable_sorted_ids(),
      "non_passed_quality_gate_row_ids" =>
        non_passed_rows |> Enum.map(& &1["id"]) |> stable_sorted_ids(),
      "non_passed_rows" => non_passed_rows,
      "rows" => rows,
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
    }
  end

  defp quality_gate_unavailable_resource_summary_from_report(%{} = quality_gate_report) do
    resource_rows = quality_gate_report |> rows() |> resource_availability_rows()
    resource_availability_counts = resource_availability_reason_counts(resource_rows)
    unavailable_counts = unavailable_resource_reason_counts(resource_rows)
    station_counts = station_availability_reason_counts(resource_availability_counts)
    quality_gate_row_ids_by_status = quality_gate_row_ids_by_status(resource_rows)

    blocked_contact_ids_by_blocking_dimension =
      blocked_contact_ids(resource_rows, "resource_blocked_contact_ids_by_blocking_dimension")

    blocked_contact_ids_by_spacecraft_id =
      blocked_contact_ids(resource_rows, "resource_blocked_contact_ids_by_spacecraft_id")

    %{
      "schema_contract" => @quality_gate_unavailable_resource_summary_schema_contract,
      "model" => "artifact_only_quality_gate_unavailable_resource_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => quality_gate_report["source_artifact_type"],
      "source_artifact_id" => quality_gate_report["source_artifact_id"],
      "source_quality_gate_report_id" => quality_gate_report["report_id"],
      "source_readiness_report_id" => quality_gate_report["source_readiness_report_id"],
      "resource_availability_row_count" => length(resource_rows),
      "unavailable_resource_row_count" => unavailable_resource_row_count(resource_rows),
      "unavailable_resource_pressure_count" => map_value_count(unavailable_counts),
      "unavailable_resource_reason_counts" => unavailable_counts,
      "unavailable_resource_reason_ids" => sorted_count_keys(unavailable_counts),
      "station_availability_reason_counts" => station_counts,
      "station_availability_reason_ids" => sorted_count_keys(station_counts),
      "resource_blocking_dimension_counts" =>
        resource_rows
        |> Enum.map(&Map.get(&1, "resource_blocking_dimension_counts"))
        |> merge_positive_count_maps(),
      "blocked_contact_ids_by_blocking_dimension" => blocked_contact_ids_by_blocking_dimension,
      "blocked_contact_ids_by_spacecraft_id" => blocked_contact_ids_by_spacecraft_id,
      "blocked_contact_ids_by_status" => blocked_contact_ids_by_status(resource_rows),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_ids_by_status" => quality_gate_ids_by(resource_rows, "status"),
      "review_required_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("review_required", []),
      "blocked_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("blocked", []),
      "resource_availability_gate_ids" =>
        resource_rows
        |> Enum.map(& &1["gate_id"])
        |> stable_sorted_ids(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_unavailable_resource_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_unavailable_resource_summary_routes_only",
        "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
      ]
    }
    |> compact_map()
  end

  defp quality_gate_operator_training_summary_from_report(%{} = quality_gate_report),
    do: QualityGateOperatorTrainingSummary.build(quality_gate_report)

  defp quality_gate_schema_validation_summary_from_report(%{} = quality_gate_report),
    do: QualityGateSchemaValidationSummary.build(quality_gate_report)

  defp quality_gate_import_readiness_summary_from_report(%{} = quality_gate_report),
    do: QualityGateImportReadinessSummary.build(quality_gate_report)

  defp quality_gate_row(gate, readiness_report, rank) do
    %{
      "id" =>
        quality_gate_row_id(
          readiness_report["source_artifact_type"],
          readiness_report["source_artifact_id"],
          gate["id"],
          rank
        ),
      "rank" => rank,
      "gate_id" => gate["id"],
      "status" => gate["status"],
      "classification" => gate["classification"],
      "reason" => gate["reason"],
      "analysis_mode" => gate["analysis_mode"],
      "analysis_mode_source" => gate["analysis_mode_source"],
      "source_operational_readiness_gate" => gate
    }
    |> Map.merge(quality_gate_row_context(gate))
    |> compact_map()
  end

  defp quality_gate_row_context(%{"id" => "resource_availability"} = gate) do
    resource_availability_reason_counts =
      gate
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()

    %{
      "resource_availability_pressure_count" => gate["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => resource_availability_reason_counts,
      "resource_availability_reason_ids" =>
        sorted_count_keys(resource_availability_reason_counts),
      "station_availability_reason_ids" =>
        station_availability_reason_ids(resource_availability_reason_counts),
      "station_availability_reason_counts" =>
        station_availability_reason_counts(resource_availability_reason_counts),
      "unavailable_resource_reason_ids" =>
        unavailable_resource_reason_ids(resource_availability_reason_counts),
      "resource_blocking_dimension_counts" =>
        gate
        |> Map.get("resource_blocking_dimension_counts", %{})
        |> positive_count_map(),
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        gate
        |> Map.get("resource_blocked_contact_ids_by_blocking_dimension", %{})
        |> stable_id_array_map(),
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        gate
        |> Map.get("resource_blocked_contact_ids_by_spacecraft_id", %{})
        |> stable_id_array_map(),
      "resource_source_quality_counts" =>
        gate
        |> Map.get("resource_source_quality_counts", %{})
        |> positive_count_map(),
      "resource_trust_boundary_status_counts" =>
        gate
        |> Map.get("resource_trust_boundary_status_counts", %{})
        |> positive_count_map()
    }
  end

  defp quality_gate_row_context(%{"id" => "cadence_import"} = gate) do
    cadence_import_gate_context(gate)
  end

  defp quality_gate_row_context(%{"id" => "adapter_boundary"} = gate) do
    adapter_boundary_gate_context(gate)
  end

  defp quality_gate_row_context(%{"id" => "operator_training"} = gate) do
    operator_training_gate_context(gate)
  end

  defp quality_gate_row_context(_gate), do: %{}

  defp positive_count_map(%{} = counts) do
    counts
    |> Enum.filter(fn {_key, value} -> is_integer(value) and value > 0 end)
    |> Map.new()
  end

  defp positive_count_map(_counts), do: %{}

  defp sorted_count_keys(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> stable_sorted_ids()
  end

  defp unavailable_resource_reason_ids(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in unavailable_resource_reasons()))
    |> stable_sorted_ids()
  end

  defp station_availability_reason_ids(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in station_availability_reasons()))
    |> stable_sorted_ids()
  end

  defp station_availability_reason_counts(counts) when is_map(counts) do
    counts
    |> positive_count_map()
    |> Map.filter(fn {reason, _count} -> reason in station_availability_reasons() end)
  end

  defp resource_availability_rows(rows) do
    Enum.filter(rows, &(&1["gate_id"] == "resource_availability"))
  end

  defp unavailable_resource_reason_counts(rows) do
    rows
    |> Enum.map(fn row ->
      row
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()
      |> Map.filter(fn {reason, _count} -> reason in unavailable_resource_reasons() end)
    end)
    |> merge_positive_count_maps()
  end

  defp resource_availability_reason_counts(rows) do
    rows
    |> Enum.map(fn row ->
      row
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()
    end)
    |> merge_positive_count_maps()
  end

  defp unavailable_resource_row_count(rows) do
    Enum.count(rows, fn row ->
      row
      |> Map.get("unavailable_resource_reason_ids", [])
      |> list_value()
      |> Enum.any?()
    end)
  end

  defp merge_positive_count_maps(maps) do
    Enum.reduce(maps, %{}, fn
      %{} = counts, acc ->
        counts
        |> positive_count_map()
        |> Enum.reduce(acc, fn {key, count}, inner_acc ->
          Map.update(inner_acc, key, count, &(&1 + count))
        end)

      _counts, acc ->
        acc
    end)
  end

  defp blocked_contact_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> merge_string_list_maps()
  end

  defp blocked_contact_ids_by_status(rows) do
    Enum.reduce(rows, %{}, fn row, acc ->
      status = normalized_evidence_string(row["status"])
      ids = row_blocked_contact_ids(row)

      if status && ids != [] do
        Map.update(acc, status, ids, fn current ->
          (current ++ ids)
          |> Enum.uniq()
          |> Enum.sort()
        end)
      else
        acc
      end
    end)
  end

  defp row_blocked_contact_ids(row) do
    [
      Map.get(row, "resource_blocked_contact_ids_by_blocking_dimension"),
      Map.get(row, "resource_blocked_contact_ids_by_spacecraft_id")
    ]
    |> merge_string_list_maps()
    |> Map.values()
    |> List.flatten()
    |> stable_sorted_ids()
  end

  defp unavailable_resource_reasons do
    ~w(
      antenna_unavailable
      payload_unavailable
      spacecraft_degraded_payload_unavailable
      spacecraft_unavailable
    )
  end

  defp station_availability_reasons do
    ~w(
      ground_station_capacity_zero
      ground_station_reduced_capacity_insufficient
      ground_station_reserved
      ground_station_unavailable
    )
  end

  defp quality_gate_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["gate_id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp quality_gate_ids(rows, status) do
    rows
    |> Enum.filter(&(&1["status"] == status))
    |> Enum.map(& &1["gate_id"])
    |> stable_sorted_ids()
  end

  defp quality_gate_row_ids_by_status(rows) do
    rows
    |> Enum.group_by(&Map.get(&1, "status"), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp quality_gate_row_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp quality_gate_report_id(source_artifact_type, source_artifact_id) do
    ["quality_gate", source_artifact_type, source_artifact_id || "unknown"]
    |> Enum.map(&stable_id_fragment/1)
    |> Enum.join(":")
  end

  defp quality_gate_row_id(source_artifact_type, source_artifact_id, gate_id, rank) do
    ["quality_gate", source_artifact_type, source_artifact_id || "unknown", gate_id, rank]
    |> Enum.map(&stable_id_fragment/1)
    |> Enum.join(":")
  end

  defp review_package_for(%{"schema_contract" => "operator_review_package.v1"} = package),
    do: package

  defp review_package_for(%{"schema_contract" => "cadence_import_manifest.v1"}), do: nil

  defp review_package_for(%{} = artifact), do: OrbitalDynamics.operator_review_package(artifact)

  defp import_manifest_for(
         %{"schema_contract" => "cadence_import_manifest.v1"} = manifest,
         _package
       ),
       do: manifest

  defp import_manifest_for(_artifact, %{} = review_package),
    do: CadenceImport.manifest(review_package)

  defp import_manifest_for(%{} = artifact, _package), do: CadenceImport.manifest(artifact)

  defp build_report(artifact, review_package, import_manifest, opts) do
    source_artifact_type = source_artifact_type(artifact, review_package, import_manifest)
    source_artifact_id = source_artifact_id(artifact, review_package, import_manifest)
    evidence = evidence(artifact, review_package, import_manifest)

    gates =
      [
        source_contract_gate(source_artifact_type),
        operational_mode_gate(artifact, opts),
        adapter_boundary_gate(evidence),
        mission_policy_gate(evidence),
        operator_training_gate(evidence),
        resource_availability_gate(evidence),
        operator_review_gate(evidence),
        cadence_import_gate(evidence)
      ]
      |> Enum.reject(&is_nil/1)

    import_classification = import_classification(gates)

    %{
      "schema_contract" => @schema_contract,
      "schema_version" => @schema_version,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => report_id(source_artifact_type, source_artifact_id),
      "source_artifact_type" => source_artifact_type,
      "source_artifact_id" => source_artifact_id,
      "readiness_level" => readiness_level(import_classification),
      "import_classification" => import_classification,
      "status" => report_status(import_classification),
      "gate_count" => length(gates),
      "passed_gate_count" => GateSummary.count(gates, "passed"),
      "review_gate_count" => GateSummary.count(gates, "review_required"),
      "analysis_gate_count" => GateSummary.count(gates, "analysis_only"),
      "blocked_gate_count" => GateSummary.count(gates, "blocked"),
      "gates" => gates,
      "evidence" => evidence,
      "assumptions" => [
        "classification_uses_declared_operator_review_and_cadence_import_manifest_evidence",
        "cadence_import_manifest_rows_are_adapter_handoff_not_external_import_writes"
      ],
      "model_limits" => capabilities().known_limits |> Enum.map(&Atom.to_string/1)
    }
  end

  defp source_contract_gate(nil) do
    gate(
      "source_contract",
      "blocked",
      "blocked",
      "source artifact type could not be inferred"
    )
  end

  defp source_contract_gate(_source_artifact_type) do
    gate(
      "source_contract",
      "passed",
      "importable",
      "source artifact type is declared"
    )
  end

  defp operational_mode_gate(artifact, opts) do
    case OperationalModeDecision.decide(artifact, opts) do
      nil ->
        gate(
          "operational_mode",
          "passed",
          "importable",
          "artifact is not marked as simulation, rehearsal, trade study, or not-for-execution"
        )

      {mode, source, reason} ->
        gate(
          "operational_mode",
          "analysis_only",
          "analysis_only",
          reason,
          %{"analysis_mode" => mode, "analysis_mode_source" => source}
        )
    end
  end

  defp adapter_boundary_gate(evidence) do
    cond do
      evidence["adapter_trust_boundary_untrusted_count"] > 0 ->
        gate(
          "adapter_boundary",
          "blocked",
          "blocked",
          "adapter import context declares untrusted trust-boundary evidence",
          adapter_boundary_gate_context(evidence)
        )

      evidence["adapter_trust_boundary_missing_count"] > 0 ->
        gate(
          "adapter_boundary",
          "review_required",
          "review_only",
          "adapter import context is missing a declared trust boundary",
          adapter_boundary_gate_context(evidence)
        )

      evidence["adapter_context_count"] > 0 ->
        gate(
          "adapter_boundary",
          "passed",
          "importable",
          "adapter import context declares trust boundary evidence",
          adapter_boundary_gate_context(evidence)
        )

      true ->
        gate(
          "adapter_boundary",
          "passed",
          "importable",
          "no adapter-specific import boundary context was declared"
        )
    end
  end

  defp adapter_boundary_gate_context(evidence) do
    %{
      "adapter_context_count" => evidence["adapter_context_count"],
      "adapter_trust_boundary_declared_count" =>
        evidence["adapter_trust_boundary_declared_count"],
      "adapter_trust_boundary_missing_count" => evidence["adapter_trust_boundary_missing_count"],
      "adapter_trust_boundary_untrusted_count" =>
        evidence["adapter_trust_boundary_untrusted_count"],
      "adapter_boundary_status_counts" => evidence["adapter_boundary_status_counts"]
    }
  end

  defp mission_policy_gate(evidence) do
    cond do
      evidence["policy_blocked_count"] > 0 ->
        gate(
          "mission_policy",
          "blocked",
          "blocked",
          "mission-policy evidence blocks import eligibility",
          mission_policy_gate_context(evidence)
        )

      evidence["policy_review_required_count"] > 0 ->
        gate(
          "mission_policy",
          "review_required",
          "review_only",
          "mission-policy evidence requires operator review before import",
          mission_policy_gate_context(evidence)
        )

      evidence["policy_decision_count"] > 0 ->
        gate(
          "mission_policy",
          "passed",
          "importable",
          "mission-policy evidence is auto-approvable",
          mission_policy_gate_context(evidence)
        )

      true ->
        nil
    end
  end

  defp mission_policy_gate_context(evidence) do
    %{
      "policy_decision_count" => evidence["policy_decision_count"],
      "policy_classification_counts" => evidence["policy_classification_counts"]
    }
  end

  defp operator_training_gate(evidence) do
    case evidence["operator_training_requirement_count"] do
      count when is_integer(count) and count > 0 ->
        gate(
          "operator_training",
          "review_required",
          "review_only",
          "operator training or qualification evidence requires role-qualified review before import",
          operator_training_gate_context(evidence)
        )

      _count ->
        nil
    end
  end

  defp operator_training_gate_context(evidence) do
    %{
      "operator_training_requirement_count" => evidence["operator_training_requirement_count"],
      "operator_training_requirement_counts" => evidence["operator_training_requirement_counts"],
      "required_operator_roles" => evidence["required_operator_roles"],
      "required_training_ids" => evidence["required_training_ids"],
      "required_certification_ids" => evidence["required_certification_ids"],
      "required_qualification_ids" => evidence["required_qualification_ids"]
    }
  end

  defp resource_availability_gate(evidence) do
    case evidence["resource_availability_pressure_count"] do
      count when is_integer(count) and count > 0 ->
        gate(
          "resource_availability",
          "review_required",
          "review_only",
          "resource availability evidence requires operator review before import",
          resource_availability_gate_context(evidence)
        )

      _count ->
        nil
    end
  end

  defp resource_availability_gate_context(evidence) do
    resource_availability_reason_counts =
      evidence
      |> Map.get("resource_availability_reason_counts", %{})
      |> positive_count_map()

    %{
      "resource_availability_pressure_count" => evidence["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => resource_availability_reason_counts,
      "resource_availability_reason_ids" =>
        sorted_count_keys(resource_availability_reason_counts),
      "station_availability_reason_ids" =>
        station_availability_reason_ids(resource_availability_reason_counts),
      "station_availability_reason_counts" =>
        station_availability_reason_counts(resource_availability_reason_counts),
      "unavailable_resource_reason_ids" =>
        unavailable_resource_reason_ids(resource_availability_reason_counts),
      "resource_blocking_dimension_counts" => evidence["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        evidence["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        evidence["resource_blocked_contact_ids_by_spacecraft_id"],
      "resource_source_quality_counts" => evidence["resource_source_quality_counts"],
      "resource_trust_boundary_status_counts" => evidence["resource_trust_boundary_status_counts"]
    }
  end

  defp operator_review_gate(evidence) do
    cond do
      evidence["blocked_review_count"] > 0 ->
        gate(
          "operator_review",
          "blocked",
          "blocked",
          "operator-review evidence includes blocked approval status"
        )

      evidence["review_required_count"] > 0 ->
        gate(
          "operator_review",
          "review_required",
          "review_only",
          "operator-review evidence requires human review before import"
        )

      evidence["review_row_count"] > 0 ->
        gate(
          "operator_review",
          "passed",
          "importable",
          "operator-review rows have no blocked or review-required status"
        )

      evidence["import_row_count"] > 0 ->
        gate(
          "operator_review",
          "passed",
          "importable",
          "Cadence import rows carry source review handoff evidence"
        )

      true ->
        gate(
          "operator_review",
          "analysis_only",
          "analysis_only",
          "no operator-review rows were available"
        )
    end
  end

  defp cadence_import_gate(evidence) do
    cond do
      evidence["blocked_import_count"] > 0 or evidence["invalid_cadence_import_count"] > 0 ->
        gate(
          "cadence_import",
          "blocked",
          "blocked",
          "Cadence import evidence is blocked or invalid",
          cadence_import_gate_context(evidence)
        )

      evidence["schema_validation_fail_count"] > 0 or
          evidence["schema_validation_error_count"] > 0 ->
        gate(
          "cadence_import",
          "blocked",
          "blocked",
          "source schema-validation evidence failed",
          cadence_import_gate_context(evidence)
        )

      evidence["manifest_review_required_count"] > 0 or evidence["missing_import_count"] > 0 ->
        gate(
          "cadence_import",
          "review_required",
          "review_only",
          "Cadence import evidence requires review or import preparation",
          cadence_import_gate_context(evidence)
        )

      evidence["stale_freshness_count"] > 0 or evidence["unknown_freshness_count"] > 0 ->
        gate(
          "cadence_import",
          "review_required",
          "review_only",
          "source freshness evidence is stale or unknown",
          cadence_import_gate_context(evidence)
        )

      evidence["ready_for_import_count"] > 0 ->
        gate(
          "cadence_import",
          "passed",
          "importable",
          "Cadence import manifest has ready-for-import rows",
          cadence_import_gate_context(evidence)
        )

      true ->
        gate(
          "cadence_import",
          "analysis_only",
          "analysis_only",
          "no ready-for-import rows were available",
          cadence_import_gate_context(evidence)
        )
    end
  end

  defp cadence_import_gate_context(evidence) do
    %{
      "ready_for_import_count" => evidence["ready_for_import_count"],
      "manifest_review_required_count" => evidence["manifest_review_required_count"],
      "blocked_import_count" => evidence["blocked_import_count"],
      "missing_import_count" => evidence["missing_import_count"],
      "invalid_cadence_import_count" => evidence["invalid_cadence_import_count"],
      "current_freshness_count" => evidence["current_freshness_count"],
      "stale_freshness_count" => evidence["stale_freshness_count"],
      "unknown_freshness_count" => evidence["unknown_freshness_count"],
      "freshness_status_counts" => positive_count_map(evidence["freshness_status_counts"]),
      "schema_validation_pass_count" => evidence["schema_validation_pass_count"],
      "schema_validation_fail_count" => evidence["schema_validation_fail_count"],
      "schema_validation_error_count" => evidence["schema_validation_error_count"],
      "schema_validation_warning_count" => evidence["schema_validation_warning_count"],
      "schema_validation_remediation_count" => evidence["schema_validation_remediation_count"],
      "schema_validation_status_counts" =>
        positive_count_map(evidence["schema_validation_status_counts"]),
      "import_status_counts" => positive_count_map(evidence["import_status_counts"]),
      "cadence_import_status_counts" =>
        positive_count_map(evidence["cadence_import_status_counts"])
    }
    |> Map.merge(timeline_publication_context_from_evidence(evidence))
  end

  defp gate(id, status, classification, reason, context \\ %{}) do
    %{
      "id" => id,
      "status" => status,
      "classification" => classification,
      "reason" => reason
    }
    |> Map.merge(context)
  end

  defp evidence(artifact, review_package, import_manifest) do
    review_rows = rows(review_package)
    import_rows = rows(import_manifest)
    review_type_counts = row_counts(review_rows, "review_type")
    approval_status_counts = row_counts(review_rows, "approval_status")
    import_action_counts = row_counts(import_rows, "import_action")
    source_review_type_counts = row_counts(import_rows, "source_review_type")
    import_status_counts = row_counts(import_rows, "import_status")
    cadence_import_status_counts = row_counts(import_rows, "cadence_import_status")
    freshness_status_counts = freshness_status_counts(artifact, review_rows, import_rows)

    schema_validation_status_counts =
      schema_validation_status_counts(artifact, review_rows, import_rows)

    source_model_counts = source_model_counts(artifact, review_rows, import_rows)
    source_model_limit_counts = source_model_limit_counts(artifact, review_rows, import_rows)

    policy_classification_counts =
      policy_classification_counts(artifact, review_rows, import_rows)

    adapter_boundary_status_counts =
      adapter_boundary_status_counts(artifact, review_rows, import_rows)

    operator_training_context =
      operator_training_context(artifact, review_rows, import_rows)

    resource_availability_reason_counts =
      resource_availability_reason_counts(review_rows, import_rows)

    resource_blocking_dimension_counts =
      resource_blocking_dimension_counts(review_rows, import_rows)

    resource_blocked_contact_ids_by_blocking_dimension =
      resource_blocked_contact_id_map(
        review_rows,
        import_rows,
        "resource_blocked_contact_ids_by_blocking_dimension",
        "resource_blocking_dimension"
      )

    resource_blocked_contact_ids_by_spacecraft_id =
      resource_blocked_contact_id_map(
        review_rows,
        import_rows,
        "resource_blocked_contact_ids_by_spacecraft_id",
        "spacecraft_id"
      )

    resource_source_quality_counts =
      resource_provenance_counts(review_rows, import_rows, "resource_source_quality")

    resource_trust_boundary_status_counts =
      resource_provenance_counts(review_rows, import_rows, "resource_trust_boundary_status")

    timeline_publication_context =
      timeline_publication_context(artifact, review_rows, import_rows)

    %{
      "review_row_count" => length(review_rows),
      "import_row_count" => length(import_rows),
      "review_required_count" =>
        count_values(approval_status_counts, ["operator_review_required", "pending"]),
      "blocked_review_count" => count_values(approval_status_counts, ["blocked_by_policy"]),
      "ready_for_import_count" => count_values(import_status_counts, ["ready_for_import"]),
      "manifest_review_required_count" =>
        count_values(import_status_counts, ["review_required_before_import"]),
      "blocked_import_count" =>
        count_values(import_status_counts, ["blocked_missing_cadence_import"]),
      "missing_import_count" => count_values(cadence_import_status_counts, ["missing"]),
      "invalid_cadence_import_count" => count_values(cadence_import_status_counts, ["invalid"]),
      "current_freshness_count" => count_values(freshness_status_counts, ["current"]),
      "stale_freshness_count" => count_values(freshness_status_counts, ["stale"]),
      "unknown_freshness_count" => count_values(freshness_status_counts, ["unknown"]),
      "schema_validation_pass_count" => count_values(schema_validation_status_counts, ["pass"]),
      "schema_validation_fail_count" => count_values(schema_validation_status_counts, ["fail"]),
      "schema_validation_error_count" =>
        schema_validation_issue_count(artifact, review_rows, import_rows, "error_count"),
      "schema_validation_warning_count" =>
        schema_validation_issue_count(artifact, review_rows, import_rows, "warning_count"),
      "schema_validation_remediation_count" =>
        schema_validation_issue_count(artifact, review_rows, import_rows, "remediation_count"),
      "source_model_count" => map_value_count(source_model_counts),
      "source_model_limit_count" => map_value_count(source_model_limit_counts),
      "policy_decision_count" => map_value_count(policy_classification_counts),
      "policy_auto_approvable_count" =>
        count_values(policy_classification_counts, ["auto_approvable"]),
      "policy_review_required_count" =>
        count_values(policy_classification_counts, ["operator_review_required"]),
      "policy_blocked_count" => count_values(policy_classification_counts, ["blocked_by_policy"]),
      "adapter_context_count" => map_value_count(adapter_boundary_status_counts),
      "adapter_trust_boundary_declared_count" =>
        count_values(adapter_boundary_status_counts, ["declared"]),
      "adapter_trust_boundary_missing_count" =>
        count_values(adapter_boundary_status_counts, ["missing"]),
      "adapter_trust_boundary_untrusted_count" =>
        count_values(adapter_boundary_status_counts, ["untrusted"]),
      "operator_training_requirement_count" =>
        operator_training_context["operator_training_requirement_count"],
      "resource_availability_pressure_count" =>
        map_value_count(resource_availability_reason_counts),
      "resource_blocking_dimension_count" => map_value_count(resource_blocking_dimension_counts),
      "review_type_counts" => review_type_counts,
      "approval_status_counts" => approval_status_counts,
      "import_action_counts" => import_action_counts,
      "source_review_type_counts" => source_review_type_counts,
      "import_status_counts" => import_status_counts,
      "cadence_import_status_counts" => cadence_import_status_counts,
      "freshness_status_counts" => freshness_status_counts,
      "schema_validation_status_counts" => schema_validation_status_counts,
      "source_model_counts" => source_model_counts,
      "source_model_limit_counts" => source_model_limit_counts,
      "policy_classification_counts" => policy_classification_counts,
      "adapter_boundary_status_counts" => adapter_boundary_status_counts,
      "operator_training_requirement_counts" =>
        operator_training_context["operator_training_requirement_counts"],
      "required_operator_roles" => operator_training_context["required_operator_roles"],
      "required_training_ids" => operator_training_context["required_training_ids"],
      "required_certification_ids" => operator_training_context["required_certification_ids"],
      "required_qualification_ids" => operator_training_context["required_qualification_ids"],
      "resource_availability_reason_counts" => resource_availability_reason_counts,
      "resource_availability_reason_ids" =>
        sorted_count_keys(resource_availability_reason_counts),
      "station_availability_reason_ids" =>
        station_availability_reason_ids(resource_availability_reason_counts),
      "station_availability_reason_counts" =>
        station_availability_reason_counts(resource_availability_reason_counts),
      "unavailable_resource_reason_ids" =>
        unavailable_resource_reason_ids(resource_availability_reason_counts),
      "resource_blocking_dimension_counts" => resource_blocking_dimension_counts,
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        resource_blocked_contact_ids_by_blocking_dimension,
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        resource_blocked_contact_ids_by_spacecraft_id,
      "resource_source_quality_counts" => resource_source_quality_counts,
      "resource_trust_boundary_status_counts" => resource_trust_boundary_status_counts
    }
    |> Map.merge(timeline_publication_context)
  end

  defp rows(artifact), do: EvidenceNormalization.rows(artifact)

  defp row_counts(rows, field), do: EvidenceNormalization.row_counts(rows, field)

  defp freshness_status_counts(artifact, review_rows, import_rows),
    do: EvidenceNormalization.freshness_status_counts(artifact, review_rows, import_rows)

  defp schema_validation_status_counts(artifact, review_rows, import_rows),
    do:
      EvidenceNormalization.schema_validation_status_counts(
        artifact,
        review_rows,
        import_rows
      )

  defp schema_validation_issue_count(artifact, review_rows, import_rows, field),
    do:
      EvidenceNormalization.schema_validation_issue_count(
        artifact,
        review_rows,
        import_rows,
        field
      )

  defp source_model_counts(artifact, review_rows, import_rows),
    do: EvidenceNormalization.source_model_counts(artifact, review_rows, import_rows)

  defp source_model_limit_counts(artifact, review_rows, import_rows),
    do: EvidenceNormalization.source_model_limit_counts(artifact, review_rows, import_rows)

  defp map_value_count(counts), do: EvidenceNormalization.map_value_count(counts)

  defp policy_classification_counts(artifact, review_rows, import_rows),
    do: EvidenceNormalization.policy_classification_counts(artifact, review_rows, import_rows)

  defp list_value(value), do: EvidenceNormalization.list_value(value)

  defp normalized_evidence_string(value),
    do: EvidenceNormalization.normalized_evidence_string(value)

  defp operator_training_context(artifact, review_rows, import_rows),
    do: OperatorTrainingEvidence.context(artifact, review_rows, import_rows)

  defp stable_id_array_map(map), do: ResourceAvailabilityEvidence.stable_id_array_map(map)

  defp merge_string_list_maps(maps),
    do: ResourceAvailabilityEvidence.merge_string_list_maps(maps)

  defp timeline_publication_context(artifact, review_rows, import_rows),
    do: TimelinePublicationContext.build(artifact, review_rows, import_rows)

  defp timeline_publication_context_from_evidence(evidence),
    do: TimelinePublicationContext.from_evidence(evidence)

  defp resource_availability_reason_counts(review_rows, import_rows),
    do:
      ResourceAvailabilityEvidence.resource_availability_reason_counts(
        review_rows,
        import_rows
      )

  defp resource_blocking_dimension_counts(review_rows, import_rows),
    do:
      ResourceAvailabilityEvidence.resource_blocking_dimension_counts(
        review_rows,
        import_rows
      )

  defp resource_blocked_contact_id_map(review_rows, import_rows, map_field, group_field),
    do:
      ResourceAvailabilityEvidence.resource_blocked_contact_id_map(
        review_rows,
        import_rows,
        map_field,
        group_field
      )

  defp resource_provenance_counts(review_rows, import_rows, field),
    do:
      ResourceAvailabilityEvidence.resource_provenance_counts(
        review_rows,
        import_rows,
        field
      )

  defp adapter_boundary_status_counts(artifact, review_rows, import_rows),
    do: AdapterBoundaryEvidence.status_counts(artifact, review_rows, import_rows)

  defp count_values(counts, values) do
    values
    |> Enum.map(&Map.get(counts, &1, 0))
    |> Enum.sum()
  end

  defp import_classification(gates) do
    statuses = Enum.map(gates, & &1["status"])

    cond do
      "blocked" in statuses -> "blocked"
      "analysis_only" in statuses -> "analysis_only"
      "review_required" in statuses -> "review_only"
      true -> "importable"
    end
  end

  defp readiness_level("importable"), do: "import_eligible"
  defp readiness_level("review_only"), do: "operator_review"
  defp readiness_level("analysis_only"), do: "analysis_only"
  defp readiness_level("blocked"), do: "blocked"

  defp report_status("importable"), do: "passed"
  defp report_status("review_only"), do: "review_required"
  defp report_status("analysis_only"), do: "analysis_only"
  defp report_status("blocked"), do: "blocked"

  defp source_artifact_type(artifact, review_package, import_manifest) do
    cond do
      artifact["schema_contract"] == "cadence_import_manifest.v1" ->
        artifact["source_artifact_type"]

      artifact["schema_contract"] == "operator_review_package.v1" ->
        artifact["source_artifact_type"]

      is_map(import_manifest) ->
        import_manifest["source_artifact_type"] || artifact["schema_contract"]

      is_map(review_package) ->
        review_package["source_artifact_type"] || artifact["schema_contract"]

      true ->
        artifact["schema_contract"]
    end
  end

  defp source_artifact_id(artifact, review_package, import_manifest) do
    cond do
      artifact["schema_contract"] == "cadence_import_manifest.v1" ->
        artifact["source_artifact_id"] || artifact["manifest_id"]

      artifact["schema_contract"] == "operator_review_package.v1" ->
        artifact["source_artifact_id"] || artifact["package_id"]

      is_map(import_manifest) ->
        import_manifest["source_artifact_id"] || artifact["id"] || artifact["report_id"]

      is_map(review_package) ->
        review_package["source_artifact_id"] || artifact["id"] || artifact["report_id"]

      true ->
        artifact["id"] || artifact["report_id"]
    end
  end

  defp report_id(source_artifact_type, source_artifact_id) do
    ["operational_readiness", source_artifact_type, source_artifact_id || "unknown"]
    |> Enum.map(&stable_id_fragment/1)
    |> Enum.join(":")
  end

  defp stable_id_fragment(value) do
    value
    |> encode_value()
    |> to_string()
    |> String.replace(~r/[^A-Za-z0-9._:@-]/, "_")
    |> String.trim("_")
    |> case do
      "" -> "unknown"
      fragment -> fragment
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
