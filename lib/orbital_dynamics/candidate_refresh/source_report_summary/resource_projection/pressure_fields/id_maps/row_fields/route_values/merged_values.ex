defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields.RouteValues.MergedValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def from_reports(reports, route_values_fun) do
    reports
    |> Enum.map(route_values_fun)
    |> merge_string_list_maps()
  end
end
