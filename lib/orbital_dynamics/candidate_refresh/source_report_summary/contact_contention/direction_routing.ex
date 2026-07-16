defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting do
  @moduledoc false

  alias __MODULE__.{ConflictGroupDirections, RouteMap}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    direction_counts =
      reports
      |> Enum.map(&ConflictGroupDirections.direction_counts/1)
      |> merge_count_maps()

    contact_ids_by_direction =
      reports
      |> Enum.map(&ConflictGroupDirections.contact_ids_by_direction/1)
      |> merge_string_list_maps()

    %{
      "direction_counts" => direction_counts,
      "contact_ids_by_direction" => contact_ids_by_direction,
      "direction_routing" => RouteMap.field(direction_counts, contact_ids_by_direction)
    }
  end
end
