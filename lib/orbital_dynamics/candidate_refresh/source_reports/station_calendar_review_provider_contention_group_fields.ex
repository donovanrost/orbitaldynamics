defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewProviderContentionGroupFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewProviderContentionGroupRowFields

  def from_row(%{} = row, %{} = embedded) do
    row
    |> StationCalendarReviewProviderContentionGroupRowFields.fields()
    |> Enum.reduce(embedded, fn {key, value}, group -> Map.put_new(group, key, value) end)
    |> Map.put_new("source_station_calendar_provider_contention", embedded)
    |> compact_map()
  end
end
