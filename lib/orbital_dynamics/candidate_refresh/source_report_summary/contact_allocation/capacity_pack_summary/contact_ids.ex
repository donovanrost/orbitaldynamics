defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary.ContactIds do
  @moduledoc false

  alias __MODULE__.GroupedContactIds

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report,
    as: CapacityPackReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_lists: 1
    ]

  def fields(reports) do
    %{
      "capacity_pack_group_ids" => string_list_merge(reports, &CapacityPackReport.group_ids/1),
      "reduced_capacity_packed_contact_ids" =>
        string_list_merge(reports, &CapacityPackReport.packed_contact_ids/1),
      "reduced_capacity_deferred_contact_ids" =>
        string_list_merge(reports, &CapacityPackReport.deferred_contact_ids/1)
    }
    |> Map.merge(GroupedContactIds.fields(reports))
  end

  defp string_list_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_lists()
  end
end
