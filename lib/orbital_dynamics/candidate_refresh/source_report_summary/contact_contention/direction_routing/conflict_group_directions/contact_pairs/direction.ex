defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.Direction do
  @moduledoc false

  alias __MODULE__.ProviderAliases
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

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
