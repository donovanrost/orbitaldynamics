defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.MergedValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def from_reports(reports, values_fun) when is_function(values_fun, 1) do
    reports
    |> Enum.map(values_fun)
    |> merge_count_maps()
  end
end
