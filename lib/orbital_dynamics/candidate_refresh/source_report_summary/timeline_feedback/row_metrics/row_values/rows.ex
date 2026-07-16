defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics.RowValues.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def raw(report), do: Map.get(report, "rows", [])

  def all(report) do
    report
    |> raw()
    |> Enum.map(&EncodedValue.stringify_keys_preserving_values/1)
  end
end
