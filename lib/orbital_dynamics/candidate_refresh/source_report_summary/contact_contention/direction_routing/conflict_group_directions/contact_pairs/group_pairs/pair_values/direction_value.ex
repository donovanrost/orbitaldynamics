defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.GroupPairs.PairValues.DirectionValue do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.Direction

  def direction(contact, group) do
    [
      contact["direction"],
      contact["type"],
      get_in(contact, ["activity_context", "direction"]),
      group["direction"]
    ]
    |> Enum.map(&Direction.normalize/1)
    |> Enum.find(&(&1 not in [nil, "", "mixed", "contact"]))
  end
end
