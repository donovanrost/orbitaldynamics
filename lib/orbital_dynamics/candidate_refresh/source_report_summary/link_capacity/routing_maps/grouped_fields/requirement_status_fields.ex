defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RoutingMaps.GroupedFields.RequirementStatusFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.GroupedIds

  alias __MODULE__.MergedValues

  def fields(reports) do
    %{
      "downlink_requirement_status_counts" =>
        MergedValues.count_map(reports, &GroupedIds.requirement_status_counts/1),
      "contact_ids_by_requirement_status" =>
        MergedValues.string_list_map(reports, &GroupedIds.contact_ids_by_requirement_status/1),
      "source_window_ids_by_requirement_status" =>
        MergedValues.string_list_map(
          reports,
          &GroupedIds.source_window_ids_by_requirement_status/1
        ),
      "station_calendar_entry_ids_by_requirement_status" =>
        MergedValues.string_list_map(
          reports,
          &GroupedIds.station_calendar_entry_ids_by_requirement_status/1
        ),
      "station_calendar_provider_entry_ids_by_requirement_status" =>
        MergedValues.string_list_map(
          reports,
          &GroupedIds.station_calendar_provider_entry_ids_by_requirement_status/1
        )
    }
  end
end
