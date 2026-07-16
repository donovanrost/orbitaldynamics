defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ProviderReservationSummary.ContactFields.RouteFields.RouteMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_nested_string_list_maps: 1,
      merge_string_list_maps: 1
    ]

  def nested_string_list_maps(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_nested_string_list_maps()
  end

  def string_list_maps(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end
end
