defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.GroupPairs.PairSources.FallbackContacts do
  @moduledoc false

  alias __MODULE__.ContactIds
  alias __MODULE__.GroupDirections

  def values(group) do
    for direction <- GroupDirections.values(group),
        contact_id <- ContactIds.values(group),
        do: {direction, contact_id}
  end
end
