defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateReportSources do
  @moduledoc false

  @fields [
    "source_quality_gate_report",
    "quality_gate_report",
    "source_operational_quality_gate_summary",
    "operational_quality_gate_summary",
    "source_operational_quality_gate_unavailable_resource_summary",
    "operational_quality_gate_unavailable_resource_summary",
    "source_operational_quality_gate_operator_training_summary",
    "operational_quality_gate_operator_training_summary",
    "source_operational_quality_gate_schema_validation_summary",
    "operational_quality_gate_schema_validation_summary",
    "source_operational_quality_gate_import_readiness_summary",
    "operational_quality_gate_import_readiness_summary"
  ]

  def root_entries(refresh) do
    Enum.map(@fields, fn field -> {field, Map.get(refresh, field)} end)
  end

  def scoped_entries(refresh, scope) do
    Enum.map(@fields, fn field ->
      {"#{scope}.#{field}", get_in(refresh, [scope, field])}
    end)
  end

  def artifact_entries(path, artifact) do
    [{"#{path}", artifact}] ++
      Enum.map(@fields, fn field -> {"#{path}.#{field}", Map.get(artifact, field)} end)
  end
end
