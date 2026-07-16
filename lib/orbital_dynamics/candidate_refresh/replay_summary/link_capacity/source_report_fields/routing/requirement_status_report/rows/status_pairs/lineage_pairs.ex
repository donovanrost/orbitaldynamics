defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs do
  @moduledoc false

  alias __MODULE__.StationCalendarPairs
  alias __MODULE__.SourceWindowPairs

  def requirement_status_source_window_pairs(row) do
    SourceWindowPairs.requirement_status_source_window_pairs(row)
  end

  def requirement_status_station_calendar_entry_pairs(row) do
    StationCalendarPairs.requirement_status_station_calendar_entry_pairs(row)
  end

  def requirement_status_station_calendar_provider_entry_pairs(row) do
    StationCalendarPairs.requirement_status_station_calendar_provider_entry_pairs(row)
  end
end
