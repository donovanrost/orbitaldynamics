defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.GroupPairs.PairSources.FallbackContacts.GroupDirections do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.Direction

  def values(group) do
    [
      group["directions"],
      group["direction"]
    ]
    |> List.flatten()
    |> Enum.map(&Direction.normalize/1)
    |> Enum.reject(&(&1 in [nil, "", "mixed", "contact"]))
    |> Enum.uniq()
  end
end
