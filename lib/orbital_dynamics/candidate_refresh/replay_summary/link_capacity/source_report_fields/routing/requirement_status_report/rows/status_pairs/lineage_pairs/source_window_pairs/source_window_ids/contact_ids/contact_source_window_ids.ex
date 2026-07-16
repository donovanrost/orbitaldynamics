defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.SourceWindowPairs.SourceWindowIds.ContactIds.ContactSourceWindowIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.Normalization

  def contact_source_window_ids(%{} = contact) do
    contact = stringify_keys(contact)

    [
      contact["source_window_id"],
      get_in(contact, ["source_window", "id"]),
      get_in(contact, ["activity_context", "source_window_id"])
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def contact_source_window_ids(_contact), do: []

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
