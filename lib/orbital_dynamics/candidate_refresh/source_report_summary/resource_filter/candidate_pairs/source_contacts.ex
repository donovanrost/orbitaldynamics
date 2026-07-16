defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidatePairs.SourceContacts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from_row(row) do
    row
    |> source_values()
    |> Enum.flat_map(&List.wrap/1)
    |> List.flatten()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  defp source_values(row) do
    [
      row["source_contact_candidate"],
      row["source_contact_candidates"],
      row["source_candidate"],
      row["contact_candidate"],
      row["source_contact"],
      row["source_contacts"],
      row["contact"]
    ]
  end
end
