defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts.SourceContactIds.ContactIdMaps.SummaryMaps.ContactIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent,
    as: SourceReportContactIntent

  def from_maps(contact_id_maps) do
    Enum.flat_map(contact_id_maps, &SourceReportContactIntent.string_list_map_contact_ids/1)
  end

  def from_nested_maps(contact_id_maps) do
    Enum.flat_map(
      contact_id_maps,
      &SourceReportContactIntent.nested_string_list_map_contact_ids/1
    )
  end
end
