defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.IntentDirections.RowValues.DirectionAliases do
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
    |> normalize_alias()
  end

  defp normalize_alias("nil"), do: nil
  defp normalize_alias(""), do: nil

  defp normalize_alias(token), do: ProviderAliases.normalize(token)
end
