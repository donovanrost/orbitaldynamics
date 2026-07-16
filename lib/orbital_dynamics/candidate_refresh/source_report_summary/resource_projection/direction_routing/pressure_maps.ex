defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.PressureMaps do
  @moduledoc false

  alias __MODULE__.ReportValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def direction_counts(reports) do
    reports
    |> Enum.map(&ReportValues.direction_counts/1)
    |> merge_count_maps()
  end

  def activity_ids_by_direction(reports) do
    reports
    |> Enum.map(&ReportValues.activity_ids_by_direction/1)
    |> merge_string_list_maps()
  end
end
