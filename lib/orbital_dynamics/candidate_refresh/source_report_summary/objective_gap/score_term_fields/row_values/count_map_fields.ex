defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ScoreTermFields.RowValues.CountMapFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ScoreTermFields.RowValues.IdentityCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(row_groups) do
    %{
      "term_key_counts" => count_maps(row_groups, &IdentityCounts.term_key_counts/1),
      "ground_station_counts" => count_maps(row_groups, &IdentityCounts.ground_station_counts/1),
      "target_counts" => count_maps(row_groups, &IdentityCounts.target_counts/1),
      "collection_counts" => count_maps(row_groups, &IdentityCounts.collection_counts/1),
      "source_activity_id_counts" =>
        count_maps(row_groups, &IdentityCounts.source_activity_id_counts/1)
    }
  end

  defp count_maps(row_groups, row_counts) do
    row_groups
    |> Enum.map(row_counts)
    |> merge_count_maps()
  end
end
