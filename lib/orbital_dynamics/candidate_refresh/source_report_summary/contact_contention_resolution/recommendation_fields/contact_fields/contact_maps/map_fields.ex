defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.ContactFields.ContactMaps.MapFields do
  @moduledoc false

  @recommendation_group_fields [
    "selected_contact_ids_by_group_id",
    "deferred_contact_ids_by_group_id"
  ]
  @review_group_fields ["review_contact_ids_by_group_id"]
  @group_contact_id_fields %{
    "selected_contact_ids_by_group_id" => "selected_contact_ids",
    "deferred_contact_ids_by_group_id" => "deferred_contact_ids",
    "review_contact_ids_by_group_id" => "review_contact_ids"
  }
  @resource_scope_fields [
    "selected_contact_ids_by_resource_scope",
    "deferred_contact_ids_by_resource_scope",
    "review_contact_ids_by_resource_scope"
  ]
  @selection_reason_fields ["selected_contact_ids_by_selection_reason"]
  @categorical_contact_id_fields %{
    "selected_contact_ids_by_resource_scope" => "selected_contact_ids",
    "deferred_contact_ids_by_resource_scope" => "deferred_contact_ids",
    "review_contact_ids_by_resource_scope" => "review_contact_ids",
    "selected_contact_ids_by_selection_reason" => "selected_contact_ids"
  }

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

  defp lineage_map(report, field) when field in @recommendation_group_fields do
    report
    |> take_group_keys(field, "recommendation_group_ids")
    |> filter_contact_ids(Map.get(report, Map.fetch!(@group_contact_id_fields, field)))
  end

  defp lineage_map(report, field) when field in @review_group_fields do
    report
    |> take_group_keys(field, "review_group_ids", "recommendation_group_ids")
    |> filter_contact_ids(Map.get(report, Map.fetch!(@group_contact_id_fields, field)))
  end

  defp lineage_map(report, field) when field in @resource_scope_fields do
    take_positive_count_keys(
      report,
      field,
      "resource_scope_counts",
      Map.fetch!(@categorical_contact_id_fields, field)
    )
  end

  defp lineage_map(report, field) when field in @selection_reason_fields do
    take_positive_count_keys(
      report,
      field,
      "selection_reason_counts",
      Map.fetch!(@categorical_contact_id_fields, field)
    )
  end

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

  defp take_positive_count_keys(report, field, count_field, contact_id_field) do
    case {Map.get(report, field), Map.get(report, count_field)} do
      {%{} = values, %{} = counts} ->
        positive_count_keys =
          for {key, count} <- counts, is_integer(count) and count > 0, do: key

        values
        |> Map.take(positive_count_keys)
        |> filter_contact_ids(Map.get(report, contact_id_field))

      _values ->
        %{}
    end
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
