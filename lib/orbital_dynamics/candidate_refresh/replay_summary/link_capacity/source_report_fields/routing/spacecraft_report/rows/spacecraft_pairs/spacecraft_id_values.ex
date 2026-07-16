defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.SpacecraftIdValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.RowValues.SourceContacts.SpacecraftIds,
    as: SourceContactSpacecraftIds

  def spacecraft_id(row) do
    [
      row["spacecraft_id"],
      row["source_spacecraft_id"],
      row["scenario_id"],
      SourceContactSpacecraftIds.source_contact_spacecraft_ids(row)
    ]
    |> List.flatten()
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
end
