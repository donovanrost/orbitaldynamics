defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.Summary.Routing do
  @moduledoc false

  def fields(link_summary) do
    %{
      "ground_station_counts" => Map.get(link_summary, "ground_station_counts", %{}),
      "direction_counts" => Map.get(link_summary, "direction_counts", %{}),
      "directions" => Map.get(link_summary, "directions", []),
      "spacecraft_counts" => Map.get(link_summary, "spacecraft_counts", %{}),
      "contact_ids_by_direction" => Map.get(link_summary, "contact_ids_by_direction", %{}),
      "source_window_ids_by_direction" =>
        Map.get(link_summary, "source_window_ids_by_direction", %{}),
      "station_calendar_entry_ids_by_direction" =>
        Map.get(link_summary, "station_calendar_entry_ids_by_direction", %{}),
      "station_calendar_provider_entry_ids_by_direction" =>
        Map.get(link_summary, "station_calendar_provider_entry_ids_by_direction", %{}),
      "direction_routing" => Map.get(link_summary, "direction_routing", %{}),
      "contact_ids_by_ground_station" =>
        Map.get(link_summary, "contact_ids_by_ground_station", %{}),
      "source_window_ids_by_ground_station" =>
        Map.get(link_summary, "source_window_ids_by_ground_station", %{}),
      "station_calendar_entry_ids_by_ground_station" =>
        Map.get(link_summary, "station_calendar_entry_ids_by_ground_station", %{}),
      "station_calendar_provider_entry_ids_by_ground_station" =>
        Map.get(link_summary, "station_calendar_provider_entry_ids_by_ground_station", %{}),
      "contact_ids_by_spacecraft" => Map.get(link_summary, "contact_ids_by_spacecraft", %{}),
      "source_window_ids_by_spacecraft" =>
        Map.get(link_summary, "source_window_ids_by_spacecraft", %{}),
      "station_calendar_entry_ids_by_spacecraft" =>
        Map.get(link_summary, "station_calendar_entry_ids_by_spacecraft", %{}),
      "station_calendar_provider_entry_ids_by_spacecraft" =>
        Map.get(link_summary, "station_calendar_provider_entry_ids_by_spacecraft", %{}),
      "selected_contact_id_counts" => Map.get(link_summary, "selected_contact_id_counts", %{}),
      "selected_contact_ids" => Map.get(link_summary, "selected_contact_ids", []),
      "selected_source_window_ids" => Map.get(link_summary, "selected_source_window_ids", []),
      "selected_station_calendar_entry_ids" =>
        Map.get(link_summary, "selected_station_calendar_entry_ids", []),
      "selected_station_calendar_provider_entry_ids" =>
        Map.get(link_summary, "selected_station_calendar_provider_entry_ids", [])
    }
  end

  def pressure?(replay) do
    map_size(replay["ground_station_counts"] || %{}) > 0 or
      map_size(replay["direction_counts"] || %{}) > 0 or
      length(List.wrap(replay["directions"])) > 0 or
      map_size(replay["spacecraft_counts"] || %{}) > 0 or
      map_size(replay["contact_ids_by_direction"] || %{}) > 0 or
      map_size(replay["source_window_ids_by_direction"] || %{}) > 0 or
      map_size(replay["station_calendar_entry_ids_by_direction"] || %{}) > 0 or
      map_size(replay["station_calendar_provider_entry_ids_by_direction"] || %{}) > 0 or
      map_size(replay["direction_routing"] || %{}) > 0 or
      map_size(replay["contact_ids_by_ground_station"] || %{}) > 0 or
      map_size(replay["source_window_ids_by_ground_station"] || %{}) > 0 or
      map_size(replay["station_calendar_entry_ids_by_ground_station"] || %{}) > 0 or
      map_size(replay["station_calendar_provider_entry_ids_by_ground_station"] || %{}) > 0 or
      map_size(replay["contact_ids_by_spacecraft"] || %{}) > 0 or
      map_size(replay["source_window_ids_by_spacecraft"] || %{}) > 0 or
      map_size(replay["station_calendar_entry_ids_by_spacecraft"] || %{}) > 0 or
      map_size(replay["station_calendar_provider_entry_ids_by_spacecraft"] || %{}) > 0 or
      map_size(replay["selected_contact_id_counts"] || %{}) > 0 or
      replay["selected_contact_ids"] != [] or
      replay["selected_source_window_ids"] != [] or
      replay["selected_station_calendar_entry_ids"] != [] or
      replay["selected_station_calendar_provider_entry_ids"] != []
  end
end
