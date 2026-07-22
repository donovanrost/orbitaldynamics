defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.ContactFields.ContactMaps.MapFields do
  @moduledoc false

  @recommendation_group_fields [
    "selected_contact_ids_by_group_id",
    "deferred_contact_ids_by_group_id"
  ]
  @review_group_fields ["review_contact_ids_by_group_id"]
  @resource_scope_fields [
    "selected_contact_ids_by_resource_scope",
    "deferred_contact_ids_by_resource_scope",
    "review_contact_ids_by_resource_scope"
  ]
  @selection_reason_fields ["selected_contact_ids_by_selection_reason"]

  alias __MODULE__.FieldSpecs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    Map.new(FieldSpecs.string_list_map_fields(), fn field ->
      {field, string_list_map_field(reports, field)}
    end)
  end

  defp string_list_map_field(reports, field) do
    reports
    |> Enum.map(&lineage_map(&1, field))
    |> merge_string_list_maps()
  end

  defp lineage_map(report, field) when field in @recommendation_group_fields,
    do: take_group_keys(report, field, "recommendation_group_ids")

  defp lineage_map(report, field) when field in @review_group_fields,
    do: take_group_keys(report, field, "review_group_ids", "recommendation_group_ids")

  defp lineage_map(report, field) when field in @resource_scope_fields,
    do: take_positive_count_keys(report, field, "resource_scope_counts")

  defp lineage_map(report, field) when field in @selection_reason_fields,
    do: take_positive_count_keys(report, field, "selection_reason_counts")

  defp lineage_map(report, field), do: Map.get(report, field, %{})

  defp take_group_keys(report, field, group_field) do
    case {Map.get(report, field), Map.get(report, group_field)} do
      {%{} = values, group_ids} when is_list(group_ids) -> Map.take(values, group_ids)
      _values -> %{}
    end
  end

  defp take_group_keys(report, field, group_field, allowed_group_field) do
    case {
      Map.get(report, field),
      Map.get(report, group_field),
      Map.get(report, allowed_group_field)
    } do
      {%{} = values, group_ids, allowed_group_ids}
      when is_list(group_ids) and is_list(allowed_group_ids) ->
        Map.take(values, Enum.filter(group_ids, &(&1 in allowed_group_ids)))

      _values ->
        %{}
    end
  end

  defp take_positive_count_keys(report, field, count_field) do
    case {Map.get(report, field), Map.get(report, count_field)} do
      {%{} = values, %{} = counts} ->
        positive_count_keys =
          for {key, count} <- counts, is_integer(count) and count > 0, do: key

        Map.take(values, positive_count_keys)

      _values ->
        %{}
    end
  end
end
