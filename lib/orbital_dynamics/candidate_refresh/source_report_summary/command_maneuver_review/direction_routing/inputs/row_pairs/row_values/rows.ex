defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.RowValues.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def normalized(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  def reject_empty_pairs(pairs) do
    Enum.reject(pairs, fn {direction, identifier} ->
      direction in [nil, ""] or identifier in [nil, ""]
    end)
  end
end
