defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary.CountMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report,
    as: CapacityPackReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def fields(reports) do
    %{
      "capacity_pack_status_counts" =>
        count_map_merge(reports, &CapacityPackReport.status_counts/1),
      "capacity_pack_contact_status_counts" =>
        count_map_merge(reports, &CapacityPackReport.contact_status_counts/1),
      "reduced_capacity_pack_status_counts" =>
        count_map_merge(reports, &CapacityPackReport.reduced_status_counts/1)
    }
  end

  defp count_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
