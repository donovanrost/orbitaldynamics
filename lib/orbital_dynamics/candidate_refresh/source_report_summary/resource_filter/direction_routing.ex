defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting do
  @moduledoc false

  alias __MODULE__.CandidateDirections
  alias __MODULE__.RouteMap

  def fields(reports) do
    direction_counts = CandidateDirections.direction_counts(reports)
    candidate_ids_by_direction = CandidateDirections.candidate_ids_by_direction(reports)

    %{
      "direction_counts" => direction_counts,
      "directions" => RouteMap.direction_keys(direction_counts, candidate_ids_by_direction),
      "candidate_ids_by_direction" => candidate_ids_by_direction,
      "direction_routing" => RouteMap.entries(direction_counts, candidate_ids_by_direction)
    }
  end
end
