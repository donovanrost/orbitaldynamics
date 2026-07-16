defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.IdentityCounts
  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    CountFields.fields(reports)
    |> Map.merge(%{
      "status_counts" => count_map(reports, &RowValues.status_counts/1),
      "objective_type_counts" => count_map(reports, &RowValues.type_counts/1),
      "ground_station_counts" => count_map(reports, &IdentityCounts.ground_station_counts/1),
      "target_counts" => count_map(reports, &IdentityCounts.target_counts/1),
      "collection_counts" => count_map(reports, &IdentityCounts.collection_counts/1),
      "source_activity_id_counts" =>
        count_map(reports, &IdentityCounts.source_activity_id_counts/1)
    })
  end

  defp count_map(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
