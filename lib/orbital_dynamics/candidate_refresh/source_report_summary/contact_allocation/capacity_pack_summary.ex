defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary do
  @moduledoc false

  alias __MODULE__.{ContactIds, CountMaps, RequiredCapacity}

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report,
    as: CapacityPackReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "capacity_pack_contact_count" =>
        sum_report_count(reports, &CapacityPackReport.contact_count/1),
      "reduced_capacity_pack_group_count" =>
        sum_report_count(reports, &CapacityPackReport.reduced_group_count/1)
    }
    |> Map.merge(CountMaps.fields(reports))
    |> Map.merge(ContactIds.fields(reports))
    |> Map.merge(RequiredCapacity.fields(reports))
    |> compact_map()
  end
end
