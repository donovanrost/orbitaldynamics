defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.CapacityPackFields.ReducedCapacity do
  @moduledoc false

  alias __MODULE__.GroupFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sorted_string_values: 1
    ]

  def fields(summary) do
    %{
      "reduced_capacity_packed_contact_ids" =>
        sorted_string_values(Map.get(summary, "reduced_capacity_packed_contact_ids", [])),
      "reduced_capacity_deferred_contact_ids" =>
        sorted_string_values(Map.get(summary, "reduced_capacity_deferred_contact_ids", [])),
      "reduced_capacity_pack_group_count" =>
        numeric_report_count(summary, "reduced_capacity_pack_group_count"),
      "reduced_capacity_pack_status_counts" =>
        Map.get(summary, "reduced_capacity_pack_status_counts")
    }
    |> Map.merge(GroupFields.fields(summary))
  end
end
