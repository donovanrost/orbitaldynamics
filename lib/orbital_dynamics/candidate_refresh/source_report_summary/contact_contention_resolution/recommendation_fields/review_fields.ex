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
      "review_contact_ids_by_action" => review_contact_ids_by_action(reports)
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
          allowed_contact_ids =
            report
            |> Map.get("ambiguous_duplicate_contact_ids")
            |> List.wrap()
            |> MapSet.new()

          values =
            values
            |> Map.take(Enum.filter(group_ids, &(&1 in recommendation_group_ids)))
            |> Enum.reduce(%{}, fn {group_id, contact_ids}, filtered ->
              contact_ids =
                contact_ids
                |> List.wrap()
                |> Enum.filter(&MapSet.member?(allowed_contact_ids, &1))

              case contact_ids do
                [] -> filtered
                contact_ids -> Map.put(filtered, group_id, contact_ids)
              end
            end)

          Map.put(
            report,
            "ambiguous_duplicate_contact_ids_by_group_id",
            values
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

  defp review_contact_ids_by_action(reports) do
    reports
    |> Enum.map(fn report ->
      values = Map.get(report, "review_contact_ids_by_action")
      counts = Recommendation.required_action_counts(report)

      filtered_values =
        if is_map(values) and is_map(counts) do
          positive_count_keys =
            for {key, count} <- counts, is_integer(count) and count > 0, do: key

          values
          |> Map.take(positive_count_keys)
          |> filter_contact_ids(Map.get(report, "review_contact_ids"))
        else
          %{}
        end

      Map.put(report, "review_contact_ids_by_action", filtered_values)
    end)
    |> Aggregates.string_list_map_field("review_contact_ids_by_action")
  end

  defp filter_contact_ids(%{} = values_by_key, allowed_contact_ids) do
    allowed_contact_ids = MapSet.new(List.wrap(allowed_contact_ids))

    Enum.reduce(values_by_key, %{}, fn {key, contact_ids}, filtered ->
      contact_ids =
        contact_ids
        |> List.wrap()
        |> Enum.filter(&MapSet.member?(allowed_contact_ids, &1))

      case contact_ids do
        [] -> filtered
        contact_ids -> Map.put(filtered, key, contact_ids)
      end
    end)
  end

  defp filter_contact_ids(_values_by_key, _allowed_contact_ids), do: %{}
end
