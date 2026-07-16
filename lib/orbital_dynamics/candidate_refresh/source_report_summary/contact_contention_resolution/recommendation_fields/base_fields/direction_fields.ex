defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.BaseFields.DirectionFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.DirectionRouting

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    direction_counts = count_map(reports, &Recommendation.direction_counts/1)

    contact_ids_by_direction =
      string_list_map(reports, &Recommendation.contact_ids_by_direction/1)

    %{
      "direction_counts" => direction_counts,
      "contact_ids_by_direction" => contact_ids_by_direction,
      "direction_routing" => DirectionRouting.field(direction_counts, contact_ids_by_direction)
    }
  end

  defp count_map(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end

  defp string_list_map(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end
end
