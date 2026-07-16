defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.ValueCounts do
  @moduledoc false

  alias __MODULE__.EncodedCounts
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  def count_values(values) do
    EncodedCounts.from_values(values)
  end

  def count_source_report_values(values) do
    values
    |> Enum.map(&NormalizedToken.value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> non_empty_map()
  end

  def count_report_field_values(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field))
    |> count_source_report_values()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
