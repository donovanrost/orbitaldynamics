defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.GroupPairs.PairSources do
  @moduledoc false

  alias __MODULE__.FallbackContacts
  alias __MODULE__.SourceContacts

  def source_contacts(group), do: SourceContacts.values(group)
  def fallback_contacts(group), do: FallbackContacts.values(group)
end
