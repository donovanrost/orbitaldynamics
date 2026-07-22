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
          &Recommendation.selected_contact_ids_by_station/1,
          &Recommendation.selected_contact_ids/1
        ),
      "deferred_contact_ids_by_ground_station" =>
        string_list_map(
          reports,
          &Recommendation.deferred_contact_ids_by_station/1,
          &Recommendation.deferred_contact_ids/1
        )
    }
  end

  defp string_list_map(reports, extractor, allowed_ids_extractor) do
    reports
    |> Enum.map(fn report ->
      filter_contact_ids(extractor.(report), allowed_ids_extractor.(report))
    end)
    |> merge_string_list_maps()
  end

  defp filter_contact_ids(%{} = values_by_station, allowed_ids) do
    allowed_ids = MapSet.new(List.wrap(allowed_ids))

    Enum.reduce(values_by_station, %{}, fn {station_id, contact_ids}, filtered ->
      contact_ids = Enum.filter(List.wrap(contact_ids), &MapSet.member?(allowed_ids, &1))

      case contact_ids do
        [] -> filtered
        contact_ids -> Map.put(filtered, station_id, contact_ids)
      end
    end)
  end

  defp filter_contact_ids(_values_by_station, _allowed_ids), do: %{}
end
