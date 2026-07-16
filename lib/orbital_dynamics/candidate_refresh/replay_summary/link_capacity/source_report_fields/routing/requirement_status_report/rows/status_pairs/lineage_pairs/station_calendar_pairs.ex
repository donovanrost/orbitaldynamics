defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.StationCalendarPairs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.PairRows

  alias __MODULE__.RowIds

  def requirement_status_station_calendar_entry_pairs(row) do
    PairRows.requirement_status_lineage_pairs(
      row,
      &RowIds.selected_contact_station_calendar_entry_ids/1,
      &RowIds.actual_throughput_station_calendar_entry_ids/1
    )
  end

  def requirement_status_station_calendar_provider_entry_pairs(row) do
    PairRows.requirement_status_lineage_pairs(
      row,
      &RowIds.selected_contact_station_calendar_provider_entry_ids/1,
      &RowIds.actual_throughput_station_calendar_provider_entry_ids/1
    )
  end
end
