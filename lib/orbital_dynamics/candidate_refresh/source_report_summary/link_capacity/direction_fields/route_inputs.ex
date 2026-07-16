defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.DirectionFields.RouteInputs do
  @moduledoc false

  def values(grouped_ids, throughput_maps) do
    [
      grouped_ids.direction_counts,
      grouped_ids.contact_ids_by_direction,
      grouped_ids.source_window_ids_by_direction,
      grouped_ids.station_calendar_entry_ids_by_direction,
      grouped_ids.station_calendar_provider_entry_ids_by_direction,
      throughput_maps.capacity_adjusted,
      throughput_maps.selected_capacity_adjusted,
      throughput_maps.unused_capacity_adjusted
    ]
  end
end
