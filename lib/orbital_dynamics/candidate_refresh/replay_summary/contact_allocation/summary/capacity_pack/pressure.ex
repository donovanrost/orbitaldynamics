defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary.CapacityPack.Pressure do
  @moduledoc false

  def pressure?(
        replay,
        allocated_contact_count,
        returned_allocated_contact_count,
        policy_blocked_allocated_contact_count
      ) do
    (replay["capacity_pack_required_capacity_fraction"] || 0.0) +
      (replay["capacity_pack_selected_required_capacity_fraction"] || 0.0) +
      (replay["capacity_pack_deferred_required_capacity_fraction"] || 0.0) > 0.0 or
      Enum.any?(
        [
          "capacity_pack_required_capacity_fraction_by_status",
          "capacity_pack_required_capacity_fraction_by_ground_station",
          "capacity_pack_selected_required_capacity_fraction_by_ground_station",
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station",
          "capacity_pack_required_capacity_fraction_by_direction",
          "capacity_pack_selected_required_capacity_fraction_by_direction",
          "capacity_pack_deferred_required_capacity_fraction_by_direction",
          "capacity_pack_selected_contact_ids_by_ground_station",
          "capacity_pack_deferred_contact_ids_by_ground_station",
          "capacity_pack_contact_ids_by_ground_station",
          "capacity_pack_selected_contact_ids_by_direction",
          "capacity_pack_deferred_contact_ids_by_direction",
          "capacity_pack_contact_ids_by_direction",
          "capacity_pack_contact_ids_by_status",
          "reduced_capacity_pack_status_counts",
          "capacity_pack_group_ids_by_status",
          "required_capacity_fraction_source_counts",
          "required_capacity_fraction_contact_ids_by_source"
        ],
        &(map_size(replay[&1] || %{}) > 0)
      ) or
      (replay["reduced_capacity_pack_group_count"] || 0) > 0 or
      (replay["capacity_pack_group_ids"] || []) != [] or
      (replay["reduced_capacity_packed_contact_ids"] || []) != [] or
      (replay["reduced_capacity_deferred_contact_ids"] || []) != [] or
      (allocated_contact_count || 0) > 0 or
      (returned_allocated_contact_count || 0) > 0 or
      (policy_blocked_allocated_contact_count || 0) > 0
  end

  def deferred_pressure?(replay) do
    (replay["capacity_pack_deferred_required_capacity_fraction"] || 0.0) > 0.0 or
      map_size(
        replay["capacity_pack_deferred_required_capacity_fraction_by_ground_station"] || %{}
      ) >
        0 or
      map_size(replay["capacity_pack_deferred_required_capacity_fraction_by_direction"] || %{}) >
        0 or
      map_size(replay["capacity_pack_deferred_contact_ids_by_direction"] || %{}) > 0 or
      map_size(replay["capacity_pack_deferred_contact_ids_by_ground_station"] || %{}) > 0 or
      (replay["reduced_capacity_deferred_contact_ids"] || []) != []
  end
end
