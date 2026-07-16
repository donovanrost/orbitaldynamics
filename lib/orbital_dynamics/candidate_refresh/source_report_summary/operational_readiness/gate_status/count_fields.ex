defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.CountFields do
  @moduledoc false

  alias __MODULE__.AnalysisModeFields
  alias __MODULE__.GateCounts

  def fields(reports) do
    GateCounts.numeric_fields(reports)
    |> Map.merge(AnalysisModeFields.fields(reports))
    |> Map.merge(GateCounts.status_map_fields(reports))
  end
end
