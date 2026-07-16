defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds do
  @moduledoc false

  alias __MODULE__.SourceWindowIds
  alias __MODULE__.StationCalendarIds

  def source_window_ids(row) do
    SourceWindowIds.values(row)
  end

  def station_calendar_entry_ids(row) do
    StationCalendarIds.entry_ids(row)
  end

  def station_calendar_provider_ids(row) do
    StationCalendarIds.provider_ids(row)
  end

  def station_calendar_provider_entry_ids(row) do
    StationCalendarIds.provider_entry_ids(row)
  end
end
