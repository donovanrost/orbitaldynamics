defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.PrecedenceFields.ReservedUnderHigherPrecedence.Values do
  @moduledoc false

  alias __MODULE__.SummaryIntegers

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def count(reports, field) do
    sum_report_count(reports, &SummaryIntegers.value(&1, field))
  end

  def string_values(reports, field) do
    reports
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
  end

  def string_list_map(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_string_list_maps()
  end
end
