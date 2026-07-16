defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.CapacityFields.CapacityMaps do
  @moduledoc false

  alias __MODULE__.MapFields
  alias __MODULE__.ScalarFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.CapacityPack

  def fields(reports) do
    ScalarFields.fields(reports)
    |> Map.merge(%{
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        MapFields.numeric(reports, &CapacityPack.required_by_station/1),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
        MapFields.numeric(reports, &CapacityPack.selected_by_station/1),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
        MapFields.numeric(reports, &CapacityPack.deferred_by_station/1),
      "capacity_pack_required_capacity_fraction_by_status" =>
        MapFields.numeric_field(
          reports,
          "capacity_pack_required_capacity_fraction_by_status"
        ),
      "required_capacity_fraction_source_counts" =>
        MapFields.count_field(reports, "required_capacity_fraction_source_counts"),
      "required_capacity_fraction_contact_ids_by_source" =>
        MapFields.string_list_field(
          reports,
          "required_capacity_fraction_contact_ids_by_source"
        )
    })
  end
end
