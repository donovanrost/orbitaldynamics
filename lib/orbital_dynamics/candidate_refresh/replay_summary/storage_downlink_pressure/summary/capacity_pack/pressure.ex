defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary.CapacityPack.Pressure do
  @moduledoc false

  def pressure?(replay) do
    (replay["capacity_pack_required_capacity_fraction"] || 0.0) +
      (replay["capacity_pack_selected_required_capacity_fraction"] || 0.0) +
      (replay["capacity_pack_deferred_required_capacity_fraction"] || 0.0) > 0.0 or
      Enum.any?(
        [
          "capacity_pack_required_capacity_fraction_by_ground_station",
          "capacity_pack_required_capacity_fraction_by_status",
          "capacity_pack_required_capacity_fraction_by_direction",
          "capacity_pack_selected_required_capacity_fraction_by_ground_station",
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station",
          "capacity_pack_selected_required_capacity_fraction_by_direction",
          "capacity_pack_deferred_required_capacity_fraction_by_direction",
          "capacity_pack_contact_status_counts",
          "capacity_pack_contact_ids_by_ground_station",
          "capacity_pack_contact_ids_by_direction",
          "capacity_pack_contact_ids_by_status",
          "capacity_pack_selected_contact_ids_by_ground_station",
          "capacity_pack_deferred_contact_ids_by_ground_station",
          "capacity_pack_selected_contact_ids_by_direction",
          "capacity_pack_deferred_contact_ids_by_direction",
          "reduced_capacity_pack_status_counts",
          "capacity_pack_group_ids_by_status",
          "required_capacity_fraction_source_counts",
          "required_capacity_fraction_contact_ids_by_source",
          "capacity_pack_status_counts"
        ],
        &(map_size(replay[&1] || %{}) > 0)
      ) or
      (replay["capacity_pack_contact_count"] || 0) > 0 or
      (replay["reduced_capacity_packed_contact_ids"] || []) != [] or
      (replay["reduced_capacity_deferred_contact_ids"] || []) != [] or
      (replay["reduced_capacity_pack_group_count"] || 0) > 0 or
      (replay["capacity_pack_group_ids"] || []) != []
  end
end
