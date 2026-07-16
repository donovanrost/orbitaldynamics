defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.CapacityPackFields.ReducedCapacity.GroupFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.CapacityPackFields.ContactIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  def fields(summary) do
    %{
      "capacity_pack_group_ids" =>
        sorted_string_values(Map.get(summary, "capacity_pack_group_ids", [])),
      "capacity_pack_group_ids_by_status" =>
        ContactIds.string_list_map(summary, "capacity_pack_group_ids_by_status"),
      "reduced_capacity_pack_groups" => pack_groups(summary)
    }
  end

  defp pack_groups(summary) do
    summary
    |> Map.get("reduced_capacity_pack_groups", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&EncodedValue.stringify_keys_with_keyword_maps/1)
  end
end
