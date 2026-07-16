defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.GroupPairs.PairValues do
  @moduledoc false

  alias __MODULE__.ContactIdValue
  alias __MODULE__.DirectionValue

  def contact_pair({direction, contact_id}, _group), do: {direction, contact_id}

  def contact_pair(contact, group) do
    {DirectionValue.direction(contact, group), ContactIdValue.contact_id(contact)}
  end
end
