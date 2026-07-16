defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ThroughputFields.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.Report,
    as: ThroughputReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "row_count" => count_sum(reports, &ThroughputReport.row_count/1),
      "selected_shortfall_row_count" =>
        count_sum(reports, &ThroughputReport.selected_shortfall_row_count/1),
      "actual_shortfall_row_count" =>
        count_sum(reports, &ThroughputReport.actual_shortfall_row_count/1),
      "actual_throughput_row_count" =>
        count_sum(reports, &ThroughputReport.actual_throughput_row_count/1),
      "capacity_adjusted_throughput_row_count" =>
        count_sum(reports, &ThroughputReport.capacity_adjusted_throughput_row_count/1),
      "ground_station_counts" =>
        count_map_merge(reports, &ThroughputReport.ground_station_counts/1),
      "spacecraft_counts" => count_map_merge(reports, &ThroughputReport.spacecraft_counts/1)
    }
  end

  defp count_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end

  defp count_sum(reports, counter),
    do: sum_report_count(reports, counter)
end
