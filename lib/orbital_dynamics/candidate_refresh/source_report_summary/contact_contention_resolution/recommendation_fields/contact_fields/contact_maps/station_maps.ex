defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.ContactFields.ContactMaps.StationMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    %{
      "selected_contact_ids_by_ground_station" =>
        string_list_map(
          reports,
          &Recommendation.selected_contact_ids_by_station/1
        ),
      "deferred_contact_ids_by_ground_station" =>
        string_list_map(
          reports,
          &Recommendation.deferred_contact_ids_by_station/1
        )
    }
  end

  defp string_list_map(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end
end
