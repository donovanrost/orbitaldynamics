defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.DirectionMaps do
  @moduledoc false

  alias __MODULE__.FallbackMaps
  alias __MODULE__.PairMaps

  def direction_counts([], fallback_counts), do: FallbackMaps.direction_counts(fallback_counts)
  def direction_counts(pairs, _fallback_counts), do: PairMaps.counts(pairs)

  def contact_ids_by_direction([], fallback_contact_ids),
    do: FallbackMaps.contact_ids_by_direction(fallback_contact_ids)

  def contact_ids_by_direction(pairs, _fallback_contact_ids), do: PairMaps.ids(pairs)
end
