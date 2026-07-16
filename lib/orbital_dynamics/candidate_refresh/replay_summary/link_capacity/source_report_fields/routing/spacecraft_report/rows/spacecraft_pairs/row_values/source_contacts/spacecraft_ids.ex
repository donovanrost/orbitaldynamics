defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.RowValues.SourceContacts.SpacecraftIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.ContactSpacecraftIds

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SourceContactValues

  def source_contact_spacecraft_ids(row) do
    row
    |> SourceContactValues.source_contact_maps(Normalization)
    |> Enum.flat_map(&ContactSpacecraftIds.contact_spacecraft_ids/1)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
end
