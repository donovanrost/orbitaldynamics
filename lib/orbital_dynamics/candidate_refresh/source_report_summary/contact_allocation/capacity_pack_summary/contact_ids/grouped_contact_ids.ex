defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary.ContactIds.GroupedContactIds do
  @moduledoc false

  alias __MODULE__.MergedMaps
  alias __MODULE__.SelectedDeferredFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report,
    as: CapacityPackReport

  def fields(reports) do
    %{
      "capacity_pack_contact_ids_by_ground_station" =>
        MergedMaps.string_list(reports, &CapacityPackReport.contact_ids_by_station/1),
      "capacity_pack_contact_ids_by_direction" =>
        MergedMaps.string_list(reports, &CapacityPackReport.contact_ids_by_direction/1),
      "capacity_pack_contact_ids_by_status" =>
        MergedMaps.string_list(reports, &CapacityPackReport.contact_ids_by_status/1),
      "capacity_pack_group_ids_by_status" =>
        MergedMaps.string_list(reports, &CapacityPackReport.group_ids_by_status/1)
    }
    |> Map.merge(SelectedDeferredFields.fields(reports))
  end
end
