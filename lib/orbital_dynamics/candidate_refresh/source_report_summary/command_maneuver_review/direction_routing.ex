defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting do
  @moduledoc false

  alias __MODULE__.Inputs
  alias __MODULE__.RouteMap

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    direction_counts =
      reports
      |> Enum.map(&Inputs.direction_counts/1)
      |> merge_count_maps()

    activity_ids_by_direction =
      reports
      |> Enum.map(&Inputs.activity_ids_by_direction/1)
      |> merge_string_list_maps()

    window_ids_by_direction =
      reports
      |> Enum.map(&Inputs.window_ids_by_direction/1)
      |> merge_string_list_maps()

    %{
      "direction_counts" => direction_counts,
      "activity_ids_by_direction" => activity_ids_by_direction,
      "window_ids_by_direction" => window_ids_by_direction,
      "direction_routing" =>
        RouteMap.build(direction_counts, activity_ids_by_direction, window_ids_by_direction)
    }
  end
end
