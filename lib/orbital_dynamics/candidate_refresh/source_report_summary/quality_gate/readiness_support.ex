defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport do
  @moduledoc false

  alias __MODULE__.AdapterBoundaryFields
  alias __MODULE__.ReadinessFields

  def fields(reports) do
    reports
    |> AdapterBoundaryFields.fields()
    |> Map.merge(ReadinessFields.fields(reports))
  end
end
