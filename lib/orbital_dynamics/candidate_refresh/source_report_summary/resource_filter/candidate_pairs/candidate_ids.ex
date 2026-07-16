defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidatePairs.CandidateIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def from_row(row) do
    row
    |> source_values()
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp source_values(row) do
    [
      row["id"],
      row["candidate_id"],
      row["activity_id"],
      row["source_candidate_id"],
      row["source_activity_id"],
      get_in(row, ["activity_context", "id"]),
      get_in(row, ["activity_context", "activity_id"]),
      get_in(row, ["source_activity_context", "id"]),
      get_in(row, ["source_activity_context", "activity_id"]),
      get_in(row, ["source_contact_candidate", "id"]),
      get_in(row, ["source_contact_candidate", "candidate_id"]),
      get_in(row, ["source_contact_candidate", "activity_id"]),
      get_in(row, ["contact_candidate", "id"]),
      get_in(row, ["contact_candidate", "candidate_id"]),
      get_in(row, ["contact_candidate", "activity_id"])
    ]
  end
end
