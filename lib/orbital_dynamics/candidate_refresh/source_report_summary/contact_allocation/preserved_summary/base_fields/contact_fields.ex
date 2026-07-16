defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.BaseFields.ContactFields do
  @moduledoc false

  alias __MODULE__.StringListMaps

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  def fields(summary) do
    %{
      "contact_ids_by_allocation_reason" =>
        StringListMaps.value(summary, "contact_ids_by_allocation_reason"),
      "allocated_contact_ids" =>
        sorted_string_values(Map.get(summary, "allocated_contact_ids", [])),
      "allocated_contact_ids_by_ground_station_id" =>
        StringListMaps.value(summary, "allocated_contact_ids_by_ground_station_id"),
      "returned_allocated_contact_ids" =>
        sorted_string_values(Map.get(summary, "returned_allocated_contact_ids", [])),
      "returned_allocated_contact_ids_by_ground_station_id" =>
        StringListMaps.value(summary, "returned_allocated_contact_ids_by_ground_station_id"),
      "deferred_contact_ids" =>
        sorted_string_values(Map.get(summary, "deferred_contact_ids", [])),
      "deferred_contact_ids_by_ground_station_id" =>
        StringListMaps.value(summary, "deferred_contact_ids_by_ground_station_id"),
      "blocked_contact_ids" => sorted_string_values(Map.get(summary, "blocked_contact_ids", [])),
      "blocked_contact_ids_by_ground_station_id" =>
        StringListMaps.value(summary, "blocked_contact_ids_by_ground_station_id"),
      "policy_blocked_contact_ids" =>
        sorted_string_values(Map.get(summary, "policy_blocked_contact_ids", [])),
      "policy_blocked_contact_ids_by_ground_station_id" =>
        StringListMaps.value(summary, "policy_blocked_contact_ids_by_ground_station_id"),
      "review_contact_ids" => sorted_string_values(Map.get(summary, "review_contact_ids", []))
    }
  end
end
