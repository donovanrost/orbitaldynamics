defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.DirectionFields.RouteMap.Entry do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def for_direction(
        direction,
        [
          direction_counts,
          contact_ids_by_direction,
          source_window_ids_by_direction,
          station_calendar_entry_ids_by_direction,
          station_calendar_provider_entry_ids_by_direction,
          capacity_adjusted_by_direction,
          selected_capacity_adjusted_by_direction,
          unused_capacity_adjusted_by_direction
        ]
      ) do
    %{
      "contact_count" => Map.get(direction_counts, direction),
      "contact_ids" => Map.get(contact_ids_by_direction, direction, []),
      "source_window_ids" => Map.get(source_window_ids_by_direction, direction, []),
      "station_calendar_entry_ids" =>
        Map.get(station_calendar_entry_ids_by_direction, direction, []),
      "station_calendar_provider_entry_ids" =>
        Map.get(station_calendar_provider_entry_ids_by_direction, direction, []),
      "capacity_adjusted_throughput_mb" => Map.get(capacity_adjusted_by_direction, direction),
      "selected_capacity_adjusted_throughput_mb" =>
        Map.get(selected_capacity_adjusted_by_direction, direction),
      "unused_capacity_adjusted_throughput_mb" =>
        Map.get(unused_capacity_adjusted_by_direction, direction)
    }
    |> compact_map()
  end
end
