defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.GroupPairs.PairSources.SourceContacts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def values(group) do
    group
    |> Map.get("source_contact_candidates", [])
    |> List.wrap()
    |> List.flatten()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end
end
