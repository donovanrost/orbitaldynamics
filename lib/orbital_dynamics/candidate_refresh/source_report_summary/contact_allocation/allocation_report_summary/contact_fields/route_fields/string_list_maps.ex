defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.AllocationReportSummary.ContactFields.RouteFields.StringListMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def from_reports(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end
end
