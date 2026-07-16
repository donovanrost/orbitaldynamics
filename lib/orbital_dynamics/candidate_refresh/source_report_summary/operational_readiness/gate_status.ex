defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.CountFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.IdFields

  def fields(reports) do
    IdFields.fields(reports)
    |> Map.merge(CountFields.fields(reports))
  end
end
