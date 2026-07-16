defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues.ContactSources.StationEntries.SourceContacts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues.Normalization

  def source_contact_values(row) do
    [
      row["source_contact_candidate"],
      row["source_contact_candidates"],
      row["source_candidate"],
      row["contact_candidate"],
      row["source_contact"],
      row["source_contacts"],
      row["contact"]
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> List.flatten()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
  end

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
