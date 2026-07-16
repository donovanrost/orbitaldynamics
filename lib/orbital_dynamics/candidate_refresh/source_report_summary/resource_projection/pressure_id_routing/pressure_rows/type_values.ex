defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.PressureRows.TypeValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken
  alias __MODULE__.ValueSets

  def normalized(values) do
    values
    |> List.wrap()
    |> Enum.map(&NormalizedToken.value/1)
    |> ValueSets.non_empty_sorted()
  end
end
