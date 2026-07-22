defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.ReviewFields do
  @moduledoc false

  alias __MODULE__.Aggregates

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "review_recommendation_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "review_recommendation_count")),
      "review_group_ids" =>
        lineage_group_ids(reports, "review_group_ids", "recommendation_group_ids"),
      "ambiguous_group_ids" =>
        lineage_group_ids(reports, "ambiguous_group_ids", "recommendation_group_ids"),
      "ambiguous_duplicate_contact_ids" =>
        Aggregates.sorted_field_values(reports, "ambiguous_duplicate_contact_ids"),
      "ambiguous_duplicate_contact_ids_by_group_id" =>
        ambiguous_duplicate_contact_ids_by_group_id(reports),
      "required_operator_action_counts" =>
        Aggregates.count_map(reports, &Recommendation.required_action_counts/1),
      "review_contact_ids_by_action" =>
        Aggregates.string_list_map_field(reports, "review_contact_ids_by_action")
    }
  end

  defp ambiguous_duplicate_contact_ids_by_group_id(reports) do
    reports
    |> Enum.map(fn report ->
      case {
        Map.get(report, "ambiguous_duplicate_contact_ids_by_group_id"),
        Map.get(report, "ambiguous_group_ids"),
        Map.get(report, "recommendation_group_ids")
      } do
        {%{} = values, group_ids, recommendation_group_ids}
        when is_list(group_ids) and is_list(recommendation_group_ids) ->
          Map.put(
            report,
            "ambiguous_duplicate_contact_ids_by_group_id",
            Map.take(values, Enum.filter(group_ids, &(&1 in recommendation_group_ids)))
          )

        _values ->
          Map.put(report, "ambiguous_duplicate_contact_ids_by_group_id", %{})
      end
    end)
    |> Aggregates.string_list_map_field("ambiguous_duplicate_contact_ids_by_group_id")
  end

  defp lineage_group_ids(reports, field, allowed_field) do
    reports
    |> Enum.map(fn report ->
      values = Map.get(report, field, [])
      allowed_values = Map.get(report, allowed_field, [])

      if is_list(values) and is_list(allowed_values) do
        Map.put(report, field, Enum.filter(values, &(&1 in allowed_values)))
      else
        Map.put(report, field, [])
      end
    end)
    |> Aggregates.sorted_field_values(field)
  end
end
