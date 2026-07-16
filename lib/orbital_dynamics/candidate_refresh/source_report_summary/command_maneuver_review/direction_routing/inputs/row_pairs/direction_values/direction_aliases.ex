defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.DirectionValues.DirectionAliases do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias __MODULE__.ProviderAliases

  def normalize(direction) when direction in [nil, ""], do: nil

  def normalize(direction) do
    direction
    |> EncodedValue.value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> ProviderAliases.normalize()
  end
end
