defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.CapacityPackFields.RequiredCapacity do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.CapacityPackFields.ContactIds

  def fields(summary) do
    %{
      "capacity_pack_selected_required_capacity_fraction" =>
        NumericValue.value(Map.get(summary, "capacity_pack_selected_required_capacity_fraction")),
      "capacity_pack_deferred_required_capacity_fraction" =>
        NumericValue.value(Map.get(summary, "capacity_pack_deferred_required_capacity_fraction")),
      "capacity_pack_required_capacity_fraction_by_status" =>
        Map.get(summary, "capacity_pack_required_capacity_fraction_by_status"),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        Map.get(summary, "capacity_pack_required_capacity_fraction_by_ground_station_id"),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        Map.get(summary, "capacity_pack_selected_required_capacity_fraction_by_ground_station_id"),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        Map.get(summary, "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"),
      "capacity_pack_required_capacity_fraction_by_direction" =>
        Map.get(summary, "capacity_pack_required_capacity_fraction_by_direction"),
      "capacity_pack_selected_required_capacity_fraction_by_direction" =>
        Map.get(summary, "capacity_pack_selected_required_capacity_fraction_by_direction"),
      "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
        Map.get(summary, "capacity_pack_deferred_required_capacity_fraction_by_direction"),
      "required_capacity_fraction_source_counts" =>
        Map.get(summary, "required_capacity_fraction_source_counts"),
      "required_capacity_fraction_contact_ids_by_source" =>
        ContactIds.string_list_map(summary, "required_capacity_fraction_contact_ids_by_source")
    }
  end
end
