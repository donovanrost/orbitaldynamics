defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.Pressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.{
    CapacityPack,
    ProviderReservation,
    ReservationConflict,
    StationPressure,
    StationReservation
  }

  def fields(context) do
    station_pressure_replay = Map.fetch!(context, :station_pressure_replay)
    capacity_pack_replay = Map.fetch!(context, :capacity_pack_replay)
    reservation_conflict_replay = Map.fetch!(context, :reservation_conflict_replay)
    station_reservation_replay = Map.fetch!(context, :station_reservation_replay)
    provider_reservation_replay = Map.fetch!(context, :provider_reservation_replay)
    capacity_pack_pressure = Map.fetch!(context, :capacity_pack_pressure)

    provider_reservation_request_pressure =
      ProviderReservation.pressure?(provider_reservation_replay)

    %{
      "branch_local_contact_allocation_pressure" =>
        contact_allocation_pressure?(
          context,
          station_pressure_replay,
          capacity_pack_replay,
          capacity_pack_pressure,
          provider_reservation_request_pressure
        ),
      "branch_local_blocked_allocation_pressure" => Map.fetch!(context, :blocked_row_count) > 0,
      "branch_local_deferred_allocation_pressure" =>
        deferred_allocation_pressure?(context, capacity_pack_replay),
      "branch_local_station_pressure" => StationPressure.pressure?(station_pressure_replay),
      "branch_local_capacity_pack_pressure" => capacity_pack_pressure,
      "branch_local_reservation_conflict_pressure" =>
        if(ReservationConflict.pressure?(reservation_conflict_replay), do: true),
      "branch_local_station_reservation_pressure" =>
        if(StationReservation.pressure?(station_reservation_replay), do: true),
      "branch_local_provider_reservation_request_pressure" =>
        if(provider_reservation_request_pressure, do: true)
    }
  end

  defp contact_allocation_pressure?(
         context,
         station_pressure_replay,
         capacity_pack_replay,
         capacity_pack_pressure,
         provider_reservation_request_pressure
       ) do
    Map.fetch!(context, :blocked_row_count) + Map.fetch!(context, :deferred_row_count) +
      (station_pressure_replay["station_pressure_contact_count"] || 0) > 0 or
      map_size(Map.fetch!(context, :allocation_status_counts)) > 0 or
      map_size(Map.fetch!(context, :allocation_reason_counts)) > 0 or
      map_size(Map.fetch!(context, :effective_allocation_status_counts)) > 0 or
      map_size(capacity_pack_replay["capacity_pack_status_counts"] || %{}) > 0 or
      (capacity_pack_replay["capacity_pack_contact_count"] || 0) > 0 or
      capacity_pack_pressure or
      (Map.get(context, :allocated_contact_ids) || []) != [] or
      (Map.get(context, :returned_allocated_contact_ids) || []) != [] or
      (Map.get(context, :deferred_contact_count) || 0) > 0 or
      (Map.get(context, :deferred_contact_ids) || []) != [] or
      (Map.get(context, :blocked_contact_count) || 0) > 0 or
      (Map.get(context, :blocked_contact_ids) || []) != [] or
      map_size(Map.get(context, :direction_counts) || %{}) > 0 or
      map_size(Map.get(context, :contact_ids_by_direction) || %{}) > 0 or
      map_size(Map.fetch!(context, :direction_routing)) > 0 or
      (Map.get(context, :policy_blocked_contact_ids) || []) != [] or
      (Map.get(context, :invalid_contact_input_count) || 0) > 0 or
      (Map.get(context, :duplicate_contact_id_count) || 0) > 0 or
      (Map.get(context, :invalid_contact_input_ids) || []) != [] or
      (Map.get(context, :status_blocked_contact_count) || 0) > 0 or
      (Map.get(context, :status_blocked_contact_ids) || []) != [] or
      (Map.get(context, :resource_blocked_contact_count) || 0) > 0 or
      (Map.get(context, :resource_blocked_contact_ids) || []) != [] or
      (Map.get(context, :review_contact_ids) || []) != [] or
      provider_reservation_request_pressure or
      map_size(Map.get(context, :allocated_contact_ids_by_station) || %{}) > 0 or
      map_size(Map.get(context, :returned_allocated_contact_ids_by_station) || %{}) > 0 or
      map_size(Map.get(context, :deferred_contact_ids_by_general_station) || %{}) > 0 or
      map_size(Map.get(context, :blocked_contact_ids_by_station) || %{}) > 0 or
      map_size(Map.get(context, :policy_blocked_contact_ids_by_station) || %{}) > 0 or
      map_size(Map.get(context, :resource_blocking_dimension_counts) || %{}) > 0 or
      map_size(Map.get(context, :resource_blocked_contact_ids_by_blocking_dimension) || %{}) > 0 or
      map_size(Map.get(context, :resource_blocked_contact_ids_by_spacecraft) || %{}) > 0 or
      map_size(Map.get(context, :contact_ids_by_allocation_reason) || %{}) > 0
  end

  defp deferred_allocation_pressure?(context, capacity_pack_replay) do
    Map.fetch!(context, :deferred_row_count) > 0 or
      (Map.get(context, :deferred_contact_count) || 0) > 0 or
      (Map.get(context, :deferred_contact_ids) || []) != [] or
      map_size(Map.get(context, :deferred_contact_ids_by_general_station) || %{}) > 0 or
      CapacityPack.deferred_pressure?(capacity_pack_replay)
  end
end
