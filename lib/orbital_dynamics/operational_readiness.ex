defmodule OrbitalDynamics.OperationalReadiness do
  @moduledoc """
  Classifies artifact-only operational readiness from review/import evidence.

  The report is a gate summary over existing operator-review packages and
  Cadence-import manifests. It does not approve work, mutate schedules, or call
  external import APIs.
  """

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperationalReadiness.Capability
  alias OrbitalDynamics.OperationalReadiness.ExecutionBoundarySummary
  alias OrbitalDynamics.OperationalReadiness.GateSummary
  alias OrbitalDynamics.OperationalReadiness.ImportEligibilitySummary
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
  @doc """
  Declares the operational-readiness report model and known limits.
  """
  def capabilities, do: Capability.build()

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
