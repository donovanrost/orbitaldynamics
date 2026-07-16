defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields.CountFields.IdentityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields.RowValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields.RowValues.IdentityCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    %{
      "ground_station_counts" => count_row_map(reports, &IdentityCounts.ground_station_counts/1),
      "target_counts" => count_row_map(reports, &IdentityCounts.target_counts/1),
      "collection_counts" => count_row_map(reports, &IdentityCounts.collection_counts/1),
      "source_activity_id_counts" =>
        count_row_map(reports, &IdentityCounts.source_activity_id_counts/1)
    }
  end

  defp count_row_map(reports, counter) do
    reports
    |> Enum.map(fn report ->
      report
      |> RowValues.rows()
      |> counter.()
    end)
    |> merge_count_maps()
  end
end
