defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.DirectionTokens.NormalizedValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.DirectionTokens.Aliases

  def normalize(direction) when direction in [nil, ""], do: nil

  def normalize(direction) do
    direction
    |> EncodedValue.value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> Aliases.normalized()
  end
end
