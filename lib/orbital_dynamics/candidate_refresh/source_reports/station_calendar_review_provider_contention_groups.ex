defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewProviderContentionGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewProviderContentionGroupFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewValueEncoding

  def provider_contention_row?(%{} = row) do
    is_map(row["source_station_calendar_provider_contention"]) or
      row["provider_calendar_contention_status"] not in [nil, ""]
  end

  def from_row(%{} = row) do
    embedded =
      case row["source_station_calendar_provider_contention"] do
        %{} = group -> StationCalendarReviewValueEncoding.stringify_keys(group)
        _group -> %{}
      end

    StationCalendarReviewProviderContentionGroupFields.from_row(row, embedded)
  end
end
