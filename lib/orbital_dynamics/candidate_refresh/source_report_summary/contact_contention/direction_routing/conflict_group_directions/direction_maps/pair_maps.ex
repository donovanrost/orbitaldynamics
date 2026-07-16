defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.DirectionMaps.PairMaps do
  @moduledoc false

  alias __MODULE__.Counts
  alias __MODULE__.Ids

  defdelegate counts(pairs), to: Counts
  defdelegate ids(pairs), to: Ids
end
