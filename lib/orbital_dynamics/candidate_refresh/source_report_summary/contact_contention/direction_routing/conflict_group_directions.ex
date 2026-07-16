defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections do
  @moduledoc false

  alias __MODULE__.ContactPairs
  alias __MODULE__.DirectionMaps

  def direction_counts(report) do
    report
    |> ContactPairs.direction_contact_pairs()
    |> DirectionMaps.direction_counts(Map.get(report, "direction_counts"))
  end

  def contact_ids_by_direction(report) do
    report
    |> ContactPairs.direction_contact_pairs()
    |> DirectionMaps.contact_ids_by_direction(Map.get(report, "contact_ids_by_direction"))
  end
end
