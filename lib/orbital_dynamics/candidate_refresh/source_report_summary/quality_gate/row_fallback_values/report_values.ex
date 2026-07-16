defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues.ReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues.ListValues

  def string_list(report, field) do
    ListValues.list(report, field)
  end

  def string_list_map(report, field) do
    case Map.get(report, field) do
      %{} = map -> map
      _value -> %{}
    end
  end
end
