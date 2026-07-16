defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts.SourceContactIds do
  @moduledoc false

  alias __MODULE__.ContactIdMaps
  alias __MODULE__.FieldSets

  def contact_count(summary) do
    ContactIdMaps.count(summary, FieldSets.contact_count_fields(), "contact_ids")
  end

  def capacity_pack_contact_count(summary) do
    ContactIdMaps.count(
      summary,
      FieldSets.capacity_pack_contact_count_fields(),
      "capacity_pack_contact_ids"
    )
  end
end
