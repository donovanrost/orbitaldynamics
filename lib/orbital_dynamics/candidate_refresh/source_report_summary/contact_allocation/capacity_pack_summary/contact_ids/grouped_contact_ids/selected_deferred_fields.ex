defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary.ContactIds.GroupedContactIds.SelectedDeferredFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report,
    as: CapacityPackReport

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary.ContactIds.GroupedContactIds.MergedMaps

  def fields(reports) do
    %{
      "capacity_pack_selected_contact_ids_by_ground_station" =>
        MergedMaps.string_list(reports, &CapacityPackReport.selected_contact_ids_by_station/1),
      "capacity_pack_selected_contact_ids_by_direction" =>
        MergedMaps.string_list(reports, &CapacityPackReport.selected_contact_ids_by_direction/1),
      "capacity_pack_deferred_contact_ids_by_ground_station" =>
        MergedMaps.string_list(reports, &CapacityPackReport.deferred_contact_ids_by_station/1),
      "capacity_pack_deferred_contact_ids_by_direction" =>
        MergedMaps.string_list(reports, &CapacityPackReport.deferred_contact_ids_by_direction/1)
    }
  end
end
