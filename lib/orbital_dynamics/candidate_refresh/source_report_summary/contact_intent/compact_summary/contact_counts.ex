defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts do
  @moduledoc false

  alias __MODULE__.SourceContactIds
  alias __MODULE__.SourceFirstCount

  def contact_count(summary) do
    SourceFirstCount.value(
      summary,
      SourceContactIds.contact_count(summary),
      "contact_intent_count"
    )
  end

  def capacity_pack_contact_count(summary) do
    SourceFirstCount.value(
      summary,
      SourceContactIds.capacity_pack_contact_count(summary),
      "capacity_pack_required_contact_count"
    )
  end
end
