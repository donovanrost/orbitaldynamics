defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  def normalized_rows(rows, field, normalizer \\ &NormalizedToken.value_with_keyword_maps/1) do
    rows
    |> Enum.map(&(Map.get(&1, field) |> normalizer.()))
    |> frequencies()
  end

  def normalized_values(values, normalizer \\ &NormalizedToken.value_with_keyword_maps/1) do
    values
    |> Enum.map(normalizer)
    |> frequencies()
  end

  def encoded_values(values) do
    values
    |> Enum.map(&EncodedValue.value_with_keyword_maps/1)
    |> frequencies()
  end

  defp frequencies(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end
end
