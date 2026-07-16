defmodule OrbitalDynamics.Schema.ContactAllocationCapacityPackRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "contact_allocation_capacity_pack_summary.v1" => %{
        "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
        "artifact_family" => "contact_allocation_capacity_pack_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "input_contact_count",
          "capacity_pack_contact_count",
          "capacity_pack_review_status",
          "reduced_capacity_pack_group_count",
          "reduced_capacity_pack_status_counts",
          "capacity_pack_status_counts",
          "capacity_pack_contact_ids_by_status",
          "capacity_pack_contact_ids_by_ground_station_id",
          "capacity_pack_selected_contact_ids_by_ground_station_id",
          "capacity_pack_deferred_contact_ids_by_ground_station_id",
          "capacity_pack_required_capacity_fraction",
          "capacity_pack_selected_required_capacity_fraction",
          "capacity_pack_deferred_required_capacity_fraction",
          "capacity_pack_required_capacity_fraction_by_status",
          "capacity_pack_required_capacity_fraction_by_ground_station_id",
          "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
          "required_capacity_fraction_source_counts",
          "required_capacity_fraction_contact_ids_by_source",
          "reduced_capacity_packed_contact_ids",
          "reduced_capacity_deferred_contact_ids",
          "capacity_pack_group_ids",
          "capacity_pack_group_ids_by_status",
          "rows",
          "reduced_capacity_pack_groups",
          "review_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "source",
          "capacity_pack_required_capacity_fraction_by_direction",
          "capacity_pack_selected_required_capacity_fraction_by_direction",
          "capacity_pack_deferred_required_capacity_fraction_by_direction",
          "capacity_pack_contact_ids_by_direction",
          "capacity_pack_selected_contact_ids_by_direction",
          "capacity_pack_deferred_contact_ids_by_direction",
          "model_limits"
        ],
        "nested_contracts" => ["contact_allocation_report.v1"]
      }
    }
  end
end
