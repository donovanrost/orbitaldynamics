defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.MergedValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def from_reports(reports, values_fun) when is_function(values_fun, 1) do
    reports
    |> Enum.map(values_fun)
    |> merge_string_list_maps()
  end
end
