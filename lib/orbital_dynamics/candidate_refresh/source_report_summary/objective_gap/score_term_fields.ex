defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ScoreTermFields do
  @moduledoc false

  alias __MODULE__.GapCounts
  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common, only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &row_count/1),
      "downlink_gap_row_count" => sum_report_count(reports, &downlink_gap_row_count/1),
      "target_gap_row_count" => sum_report_count(reports, &target_gap_row_count/1),
      "collection_latency_gap_row_count" =>
        sum_report_count(reports, &collection_latency_gap_row_count/1)
    }
    |> Map.merge(count_map_fields(reports))
  end

  def rows(report), do: RowValues.rows(report)

  def trust_boundary(row), do: RowValues.trust_boundary(row)

  defp row_count(report), do: length(Map.get(report, "rows", []))

  defp count_map_fields(reports), do: RowValues.count_map_fields(reports)

  defp downlink_gap_row_count(report) do
    GapCounts.downlink_gap_row_count(report)
  end

  defp target_gap_row_count(report) do
    GapCounts.target_gap_row_count(report)
  end

  defp collection_latency_gap_row_count(report) do
    GapCounts.collection_latency_gap_row_count(report)
  end
end
