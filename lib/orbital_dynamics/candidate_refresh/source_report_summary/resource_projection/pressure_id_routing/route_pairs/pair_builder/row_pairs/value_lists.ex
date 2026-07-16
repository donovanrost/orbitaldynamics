defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RoutePairs.PairBuilder.RowPairs.ValueLists do
  @moduledoc false

  def wrap(value), do: List.wrap(value)

  def non_blank(value) do
    value
    |> wrap()
    |> Enum.reject(&blank?/1)
  end

  defp blank?(value), do: value in [nil, ""]
end
