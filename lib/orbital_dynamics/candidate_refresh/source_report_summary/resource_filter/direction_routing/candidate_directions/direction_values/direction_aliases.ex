defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.CandidateDirections.DirectionValues.DirectionAliases do
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
    |> normalized_direction()
  end

  defp normalized_direction("nil"), do: nil
  defp normalized_direction(""), do: nil

  defp normalized_direction(value), do: ProviderAliases.value(value)
end
