defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.CountFields.CountMaps.CountValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  alias __MODULE__.ReportCounts

  def fields(reports) do
    Map.new(count_route_specs(), fn {field, count_fun} ->
      {
        field,
        reports
        |> Enum.map(count_fun)
        |> merge_count_maps()
      }
    end)
  end

  defp count_route_specs do
    [
      {"suppressed_reason_counts", &ReportCounts.suppressed_reason_counts/1},
      {"resource_filter_spacecraft_counts", &ReportCounts.spacecraft_counts/1},
      {"resource_filter_resource_counts", &ReportCounts.resource_counts/1},
      {"resource_filter_blocking_dimension_counts", &ReportCounts.blocking_dimension_counts/1}
    ]
  end
end
