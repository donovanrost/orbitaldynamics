defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessDirectReportSourceFields do
  @moduledoc false

  @source_fields [
    "source_operational_readiness_report",
    "operational_readiness_report",
    "source_operational_import_eligibility_summary",
    "operational_import_eligibility_summary",
    "source_operational_readiness_gate_summary",
    "operational_readiness_gate_summary",
    "source_operational_execution_boundary_summary",
    "operational_execution_boundary_summary"
  ]

  def sources(refresh) do
    scoped_sources(refresh, "accepted_planning_state") ++
      scoped_sources(refresh, "mission_state") ++
      root_sources(refresh)
  end

  defp scoped_sources(refresh, scope) do
    Enum.map(@source_fields, fn field ->
      {"#{scope}.#{field}", get_in(refresh, [scope, field])}
    end)
  end

  defp root_sources(refresh) do
    Enum.map(@source_fields, fn field ->
      {field, Map.get(refresh, field)}
    end)
  end
end
