defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.Summary.Pressure do
  @moduledoc false

  def fields(context) do
    %{
      "branch_local_contact_intent_pressure" => contact_intent_pressure?(context),
      "branch_local_station_feedback_pressure" => station_feedback_pressure?(context),
      "branch_local_capacity_pack_pressure" => capacity_pack_pressure?(context)
    }
  end

  defp contact_intent_pressure?(context) do
    Map.fetch!(context, :station_feedback_count) + Map.fetch!(context, :required_contact_count) >
      0 or
      map_size(Map.fetch!(context, :station_calendar_status_counts)) > 0 or
      map_size(Map.fetch!(context, :cadence_import_status_counts)) > 0 or
      map_size(Map.fetch!(context, :policy_classification_counts)) > 0 or
      Map.fetch!(context, :required_capacity_fraction) > 0.0 or
      map_size(Map.fetch!(context, :required_by_station)) > 0 or
      map_size(Map.fetch!(context, :required_by_direction)) > 0 or
      map_size(Map.fetch!(context, :required_by_direction_and_station)) > 0 or
      map_size(Map.fetch!(context, :required_source_counts)) > 0 or
      map_size(Map.fetch!(context, :required_contact_ids_by_source)) > 0 or
      map_size(Map.fetch!(context, :capacity_contact_ids_by_station)) > 0 or
      map_size(Map.fetch!(context, :contact_ids_by_station)) > 0 or
      map_size(Map.fetch!(context, :capacity_contact_ids_by_direction)) > 0 or
      map_size(Map.fetch!(context, :capacity_contact_ids_by_direction_and_station)) > 0 or
      map_size(Map.fetch!(context, :contact_ids_by_direction_and_station)) > 0 or
      length(List.wrap(Map.fetch!(context, :directions))) > 0 or
      map_size(Map.fetch!(context, :direction_counts)) > 0 or
      map_size(Map.fetch!(context, :contact_ids_by_direction)) > 0 or
      map_size(Map.fetch!(context, :direction_routing)) > 0
  end

  defp station_feedback_pressure?(context) do
    Map.fetch!(context, :station_feedback_count) > 0 or
      map_size(Map.fetch!(context, :station_calendar_status_counts)) > 0 or
      map_size(Map.fetch!(context, :cadence_import_status_counts)) > 0 or
      map_size(Map.fetch!(context, :policy_classification_counts)) > 0
  end

  defp capacity_pack_pressure?(context) do
    Map.fetch!(context, :required_contact_count) > 0 or
      Map.fetch!(context, :required_capacity_fraction) > 0.0 or
      map_size(Map.fetch!(context, :required_by_station)) > 0 or
      map_size(Map.fetch!(context, :required_by_direction)) > 0 or
      map_size(Map.fetch!(context, :required_by_direction_and_station)) > 0 or
      map_size(Map.fetch!(context, :required_source_counts)) > 0 or
      map_size(Map.fetch!(context, :required_contact_ids_by_source)) > 0 or
      map_size(Map.fetch!(context, :capacity_contact_ids_by_station)) > 0 or
      map_size(Map.fetch!(context, :capacity_contact_ids_by_direction)) > 0 or
      map_size(Map.fetch!(context, :capacity_contact_ids_by_direction_and_station)) > 0 or
      map_size(Map.fetch!(context, :direction_routing)) > 0
  end
end
