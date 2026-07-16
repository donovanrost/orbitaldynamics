defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.CapacityPackFields.ContactIds do
  @moduledoc false

  alias __MODULE__.StringListMaps

  def fields(summary) do
    %{
      "capacity_pack_contact_ids_by_status" =>
        string_list_map(summary, "capacity_pack_contact_ids_by_status"),
      "capacity_pack_contact_ids_by_ground_station_id" =>
        string_list_map(summary, "capacity_pack_contact_ids_by_ground_station_id"),
      "capacity_pack_selected_contact_ids_by_ground_station_id" =>
        string_list_map(
          summary,
          "capacity_pack_selected_contact_ids_by_ground_station_id"
        ),
      "capacity_pack_deferred_contact_ids_by_ground_station_id" =>
        string_list_map(
          summary,
          "capacity_pack_deferred_contact_ids_by_ground_station_id"
        ),
      "capacity_pack_contact_ids_by_direction" =>
        string_list_map(summary, "capacity_pack_contact_ids_by_direction"),
      "capacity_pack_selected_contact_ids_by_direction" =>
        string_list_map(summary, "capacity_pack_selected_contact_ids_by_direction"),
      "capacity_pack_deferred_contact_ids_by_direction" =>
        string_list_map(summary, "capacity_pack_deferred_contact_ids_by_direction")
    }
  end

  def string_list_map(summary, field) do
    StringListMaps.value(summary, field)
  end
end
