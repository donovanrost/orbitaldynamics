defmodule OrbitalDynamics.OperationalReadiness do
  @moduledoc """
  Classifies artifact-only operational readiness from review/import evidence.

  The report is a gate summary over existing operator-review packages and
  Cadence-import manifests. It does not approve work, mutate schedules, or call
  external import APIs.
  """

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperationalReadiness.ExecutionBoundarySummary
  alias OrbitalDynamics.OperationalReadiness.GateSummary
  alias OrbitalDynamics.OperationalReadiness.ImportEligibilitySummary
  alias OrbitalDynamics.OperationalReadiness.OperationalModeDecision
  alias OrbitalDynamics.OperationalReadiness.QualityGateOperatorTrainingSummary
  alias OrbitalDynamics.OperationalReadiness.QualityGateImportReadinessSummary
  alias OrbitalDynamics.OperationalReadiness.QualityGateReport
  alias OrbitalDynamics.OperationalReadiness.QualityGateSchemaValidationSummary
  alias OrbitalDynamics.OperationalReadiness.QualityGateSummary
  alias OrbitalDynamics.OperationalReadiness.QualityGateUnavailableResourceSummary
  alias OrbitalDynamics.OperationalReadiness.ReadinessEvidence
  alias OrbitalDynamics.OperationalReadiness.ReadinessReport

  @schema_contract "operational_readiness_report.v1"
  @gate_summary_schema_contract "operational_readiness_gate_summary.v1"
  @execution_boundary_summary_schema_contract "operational_execution_boundary_summary.v1"
  @quality_gate_schema_contract "quality_gate_report.v1"
  @quality_gate_unavailable_resource_summary_schema_contract "operational_quality_gate_unavailable_resource_summary.v1"
  @quality_gate_operator_training_summary_schema_contract "operational_quality_gate_operator_training_summary.v1"
  @quality_gate_import_readiness_summary_schema_contract "operational_quality_gate_import_readiness_summary.v1"
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
      import_eligibility_summary_artifact_contract: ImportEligibilitySummary.schema_contract(),
      gate_summary_artifact_contract: @gate_summary_schema_contract,
      execution_boundary_summary_artifact_contract: @execution_boundary_summary_schema_contract,
      quality_gate_summary_artifact_contract: QualityGateSummary.schema_contract(),
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
    |> ImportEligibilitySummary.build()
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
    |> ExecutionBoundarySummary.build(@execution_boundary_summary_schema_contract)
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
    QualityGateSummary.build(quality_gate_report)
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
    |> QualityGateSummary.build()
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

  defp quality_gate_report_from_readiness(%{} = readiness_report),
    do: QualityGateReport.build(readiness_report)

  defp quality_gate_unavailable_resource_summary_from_report(%{} = quality_gate_report),
    do: QualityGateUnavailableResourceSummary.build(quality_gate_report)

  defp quality_gate_operator_training_summary_from_report(%{} = quality_gate_report),
    do: QualityGateOperatorTrainingSummary.build(quality_gate_report)

  defp quality_gate_schema_validation_summary_from_report(%{} = quality_gate_report),
    do: QualityGateSchemaValidationSummary.build(quality_gate_report)

  defp quality_gate_import_readiness_summary_from_report(%{} = quality_gate_report),
    do: QualityGateImportReadinessSummary.build(quality_gate_report)

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
    evidence = ReadinessEvidence.build(artifact, review_package, import_manifest)

    ReadinessReport.build(
      artifact,
      review_package,
      import_manifest,
      opts,
      evidence,
      capabilities().known_limits |> Enum.map(&Atom.to_string/1)
    )
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
