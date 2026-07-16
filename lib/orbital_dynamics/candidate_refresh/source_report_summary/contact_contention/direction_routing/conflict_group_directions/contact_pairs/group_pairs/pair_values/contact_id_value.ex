defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.GroupPairs.PairValues.ContactIdValue do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def contact_id(contact) do
    [
      contact["contact_id"],
      contact["id"],
      contact["activity_id"],
      get_in(contact, ["activity_context", "contact_id"]),
      get_in(contact, ["activity_context", "id"])
    ]
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end
end
