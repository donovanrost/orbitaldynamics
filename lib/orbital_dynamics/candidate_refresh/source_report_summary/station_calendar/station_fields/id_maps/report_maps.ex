defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.StationFields.IdMaps.ReportMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def string_list(reports, report_values) when is_function(report_values, 1) do
    reports
    |> Enum.map(report_values)
    |> merge_string_list_maps()
  end
end
