defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields.CountFields do
  @moduledoc false

  alias __MODULE__.IdentityFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields.RowValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields.RowValues.GapCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &RowValues.row_count/1),
      "downlink_gap_row_count" => sum_row_count(reports, &GapCounts.downlink_gap_row_count/1),
      "target_gap_row_count" => sum_row_count(reports, &GapCounts.target_gap_row_count/1),
      "collection_latency_gap_row_count" =>
        sum_row_count(reports, &GapCounts.collection_latency_gap_row_count/1)
    }
    |> Map.merge(IdentityFields.fields(reports))
  end

  defp sum_row_count(reports, counter) do
    sum_report_count(reports, fn report ->
      report
      |> RowValues.rows()
      |> counter.()
    end)
  end
end
