defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.CapacityFields.CapacityMaps.FieldSpecs do
  @moduledoc false

  def compact do
    %{
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        {"capacity_pack_required_capacity_fraction_by_ground_station_id", :numeric},
      "required_capacity_fraction_source_counts" =>
        {"required_capacity_fraction_source_counts", :count},
      "required_capacity_fraction_contact_ids_by_source" =>
        {"required_capacity_fraction_contact_ids_by_source", :string_list},
      "capacity_pack_contact_ids_by_ground_station" =>
        {"capacity_pack_contact_ids_by_ground_station_id", :string_list},
      "contact_ids_by_ground_station" => {"contact_ids_by_ground_station_id", :string_list}
    }
  end

  def input do
    %{
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        {"capacity_pack_required_capacity_fraction_by_ground_station", :numeric},
      "required_capacity_fraction_source_counts" =>
        {"required_capacity_fraction_source_counts", :count},
      "required_capacity_fraction_contact_ids_by_source" =>
        {"required_capacity_fraction_contact_ids_by_source", :string_list},
      "capacity_pack_contact_ids_by_ground_station" =>
        {"capacity_pack_contact_ids_by_ground_station", :string_list},
      "contact_ids_by_ground_station" => {"contact_ids_by_ground_station", :string_list}
    }
  end
end
