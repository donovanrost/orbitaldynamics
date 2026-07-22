defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.CapacityFields.CapacityMaps do
  @moduledoc false

  alias __MODULE__.MapFields
  alias __MODULE__.ScalarFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.CapacityPack

  def fields(reports) do
    ScalarFields.fields(reports)
    |> Map.merge(%{
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        MapFields.numeric(
          reports,
          &CapacityPack.required_by_station/1,
          &CapacityPack.required_fraction/1
        ),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
        MapFields.numeric(
          reports,
          &CapacityPack.selected_by_station/1,
          &CapacityPack.selected_required_fraction/1
        ),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
        MapFields.numeric(
          reports,
          &CapacityPack.deferred_by_station/1,
          &CapacityPack.deferred_required_fraction/1
        ),
      "capacity_pack_required_capacity_fraction_by_status" =>
        MapFields.capacity_status(
          reports,
          &CapacityPack.required_fraction/1,
          &CapacityPack.selected_required_fraction/1,
          &CapacityPack.deferred_required_fraction/1
        ),
      "required_capacity_fraction_source_counts" =>
        MapFields.count_field(reports, "required_capacity_fraction_source_counts"),
      "required_capacity_fraction_contact_ids_by_source" =>
        MapFields.capacity_source_contact_ids(reports)
    })
  end
end
