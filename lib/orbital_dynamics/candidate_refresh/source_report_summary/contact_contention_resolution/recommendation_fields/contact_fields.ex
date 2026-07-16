defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.ContactFields do
  @moduledoc false

  alias __MODULE__.ContactMaps

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_lists: 1,
      sorted_string_values: 1
    ]

  def fields(reports) do
    %{
      "selected_contact_ids" => string_list(reports, &Recommendation.selected_contact_ids/1),
      "deferred_contact_ids" => string_list(reports, &Recommendation.deferred_contact_ids/1),
      "review_contact_ids" => sorted_field_values(reports, "review_contact_ids")
    }
    |> Map.merge(ContactMaps.fields(reports))
  end

  defp string_list(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_lists()
  end

  defp sorted_field_values(reports, field) do
    reports
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
    |> non_empty_list()
  end

  defp non_empty_list([]), do: nil
  defp non_empty_list(list), do: list
end
