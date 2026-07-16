defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.DirectionMaps.FallbackMaps do
  @moduledoc false

  alias __MODULE__.ContactIdsByDirection
  alias __MODULE__.DirectionCounts

  defdelegate direction_counts(counts), to: DirectionCounts
  defdelegate contact_ids_by_direction(value_map), to: ContactIdsByDirection
end
