defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def value(value) do
    value
    |> EncodedValue.value()
    |> normalize_value()
  end

  def value_with_keyword_maps(value) do
    value
    |> EncodedValue.value_with_keyword_maps()
    |> normalize_value()
  end

  defp normalize_value(nil), do: nil

  defp normalize_value(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> String.trim("_")
  end
end
