defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.RowValues.SourceContacts.ContactIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.ContactIdValues

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.Normalization

  def source_contact_ids(row) do
    ContactIdValues.source_contact_ids(row, Normalization)
  end
end
