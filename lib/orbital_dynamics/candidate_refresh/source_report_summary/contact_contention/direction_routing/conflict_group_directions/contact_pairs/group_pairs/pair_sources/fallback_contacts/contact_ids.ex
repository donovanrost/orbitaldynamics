defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.GroupPairs.PairSources.FallbackContacts.ContactIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def values(group) do
    group
    |> Map.get("contact_ids", [])
    |> List.wrap()
    |> List.flatten()
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
  end
end
