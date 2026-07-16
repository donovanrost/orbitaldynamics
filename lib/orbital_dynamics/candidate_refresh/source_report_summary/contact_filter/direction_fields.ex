defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.DirectionFields do
  @moduledoc false

  alias __MODULE__.Routing

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    direction_counts =
      reports
      |> Enum.map(&Report.direction_counts/1)
      |> merge_count_maps()

    contact_ids_by_direction =
      reports
      |> Enum.map(&Report.contact_ids_by_direction/1)
      |> merge_string_list_maps()

    %{
      "direction_counts" => direction_counts,
      "directions" => Routing.keys(direction_counts, contact_ids_by_direction),
      "contact_ids_by_direction" => contact_ids_by_direction,
      "direction_routing" => Routing.values(direction_counts, contact_ids_by_direction)
    }
  end
end
