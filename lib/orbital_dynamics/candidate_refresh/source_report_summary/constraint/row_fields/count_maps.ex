defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.CountMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    %{
      "status_counts" => count_map_merge(reports, &RowValues.status_counts/1),
      "ground_station_counts" => count_map_merge(reports, &RowValues.ground_station_counts/1),
      "constraint_metric_counts" => count_map_merge(reports, &RowValues.metric_counts/1),
      "constraint_id_counts" => count_map_merge(reports, &RowValues.constraint_id_counts/1),
      "source_activity_id_counts" =>
        count_map_merge(reports, &RowValues.source_activity_id_counts/1),
      "constraint_resource_counts" => count_map_merge(reports, &RowValues.resource_counts/1),
      "constraint_spacecraft_counts" => count_map_merge(reports, &RowValues.spacecraft_counts/1)
    }
  end

  defp count_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
