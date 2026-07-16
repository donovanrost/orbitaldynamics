defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics.RowValues.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def count(report), do: length(all(report))

  def normalized(report) do
    report
    |> all()
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  defp all(report), do: Map.get(report, "rows", [])
end
