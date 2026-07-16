defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.RouteMap.Entry do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def for_direction(direction, direction_counts, candidate_ids_by_direction) do
    %{
      "candidate_count" => Map.get(direction_counts, direction),
      "candidate_ids" => Map.get(candidate_ids_by_direction, direction, [])
    }
    |> compact_map()
  end
end
