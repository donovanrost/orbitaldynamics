defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues.GapCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues.NormalizedRows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &NormalizedRows.row_count/1),
      "gap_row_count" => sum_report_count(reports, &GapCounts.gap_row_count/1),
      "downlink_gap_row_count" => sum_report_count(reports, &GapCounts.downlink_gap_row_count/1),
      "target_gap_row_count" => sum_report_count(reports, &GapCounts.target_gap_row_count/1),
      "collection_latency_gap_row_count" =>
        sum_report_count(reports, &GapCounts.collection_latency_gap_row_count/1)
    }
  end
end
