defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence.Values.MergedValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence.Values.EvidenceMap

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def count_sum(reports, field) do
    sum_report_count(reports, &EvidenceMap.count(&1, field))
  end

  def count_map_merge(reports, field) do
    reports
    |> Enum.map(&count_map(&1, field))
    |> merge_count_maps()
  end

  def string_values(reports, field) do
    reports
    |> Enum.flat_map(&EvidenceMap.string_list(&1, field))
    |> sorted_string_values()
  end

  def string_list_map_merge(reports, field) do
    reports
    |> Enum.map(&EvidenceMap.string_list_map(&1, field))
    |> merge_string_list_maps()
  end

  def count_map(report, field) do
    EvidenceMap.count_map(report, field)
  end
end
