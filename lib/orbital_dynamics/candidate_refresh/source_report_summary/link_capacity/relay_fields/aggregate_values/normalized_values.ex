defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RelayFields.AggregateValues.NormalizedValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def non_zero_count_sum(reports, counter) do
    reports
    |> sum_report_count(counter)
    |> non_zero_count()
  end

  def sorted_list(reports, extractor) do
    reports
    |> Enum.flat_map(&(extractor.(&1) || []))
    |> sorted_non_empty_values()
  end

  defp non_zero_count(count) when is_integer(count) and count > 0, do: count
  defp non_zero_count(_count), do: nil

  defp sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end
end
