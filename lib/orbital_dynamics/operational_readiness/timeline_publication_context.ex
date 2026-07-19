defmodule OrbitalDynamics.OperationalReadiness.TimelinePublicationContext do
  @moduledoc false

  def build(artifact, review_rows, import_rows) do
    [artifact | review_rows ++ import_rows]
    |> Enum.flat_map(&timeline_publication_sources/1)
    |> Enum.map(&timeline_publication_source_context/1)
    |> Enum.reject(&(&1 == %{}))
    |> merge_timeline_publication_contexts()
  end

  defp timeline_publication_sources(%{"source_timeline_publication_summary" => %{} = source}) do
    [source]
  end

  defp timeline_publication_sources(%{"source_review_row" => %{} = source_review_row} = row) do
    direct_timeline_publication_sources(row) ++ timeline_publication_sources(source_review_row)
  end

  defp timeline_publication_sources(%{} = row), do: direct_timeline_publication_sources(row)
  defp timeline_publication_sources(_row), do: []

  defp direct_timeline_publication_sources(
         %{"schema_contract" => "timeline_publication_summary.v1"} = summary
       ),
       do: [summary]

  defp direct_timeline_publication_sources(%{} = row) do
    if Enum.any?(timeline_publication_direct_fields(), &Map.has_key?(row, &1)) do
      [row]
    else
      []
    end
  end

  defp timeline_publication_direct_fields do
    ~w(
      publication_id
      publication_status
      publication_authority
      dependency_impact_status
      dependency_impact_row_count
      timeline_diff_row_count
      timeline_diff_changed_count
      timeline_diff_review_required_count
      changed_field_counts
      review_timeline_ids
      invalidated_downstream_product_ids
    )
  end

  defp timeline_publication_source_context(%{} = source) do
    %{
      "publication_id" => normalized_evidence_string(source["publication_id"]),
      "publication_status" => normalized_evidence_string(source["publication_status"]),
      "dependency_impact_status" =>
        normalized_evidence_string(source["dependency_impact_status"]),
      "publication_authority" => normalized_evidence_string(source["publication_authority"]),
      "source_artifact_type" => normalized_evidence_string(source["source_artifact_type"]),
      "source_artifact_ids" => stable_sorted_evidence_values([source["source_artifact_id"]]),
      "supersedes_artifact_ids" =>
        stable_sorted_evidence_values(list_value(source["supersedes_artifact_ids"])),
      "downstream_product_ids" =>
        stable_sorted_evidence_values(list_value(source["downstream_product_ids"])),
      "invalidated_downstream_product_ids" =>
        stable_sorted_evidence_values(list_value(source["invalidated_downstream_product_ids"])),
      "impacted_dependency_activity_ids" =>
        stable_sorted_evidence_values(list_value(source["impacted_dependency_activity_ids"])),
      "impacted_dependency_timeline_ids" =>
        stable_sorted_evidence_values(list_value(source["impacted_dependency_timeline_ids"])),
      "impacted_exclusive_with_activity_ids" =>
        stable_sorted_evidence_values(list_value(source["impacted_exclusive_with_activity_ids"])),
      "impacted_exclusive_with_timeline_ids" =>
        stable_sorted_evidence_values(list_value(source["impacted_exclusive_with_timeline_ids"])),
      "changed_timeline_ids" =>
        stable_sorted_evidence_values(list_value(source["changed_timeline_ids"])),
      "review_timeline_ids" =>
        stable_sorted_evidence_values(list_value(source["review_timeline_ids"])),
      "dependency_impact_row_count" => integer_value(source["dependency_impact_row_count"]),
      "timeline_diff_row_count" => integer_value(source["timeline_diff_row_count"]),
      "timeline_diff_changed_count" => integer_value(source["timeline_diff_changed_count"]),
      "timeline_diff_review_required_count" =>
        integer_value(source["timeline_diff_review_required_count"]),
      "changed_field_counts" => positive_count_map(source["changed_field_counts"]),
      "timeline_ids_by_changed_field" =>
        stable_id_array_map(source["timeline_ids_by_changed_field"])
    }
    |> compact_map()
  end

  defp timeline_publication_source_context(_source), do: %{}

  defp merge_timeline_publication_contexts([]), do: %{}

  defp merge_timeline_publication_contexts(contexts) do
    contexts
    |> merge_duplicate_timeline_publication_contexts()
    |> summarize_timeline_publication_contexts()
  end

  defp merge_duplicate_timeline_publication_contexts(contexts) do
    contexts
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {context, index}, acc ->
      key = context["publication_id"] || "__timeline_publication_context_#{index}"
      Map.update(acc, key, context, &merge_timeline_publication_context(&1, context))
    end)
    |> Map.values()
  end

  defp merge_timeline_publication_context(left, right) do
    %{
      "publication_id" => left["publication_id"] || right["publication_id"],
      "publication_status" => left["publication_status"] || right["publication_status"],
      "dependency_impact_status" =>
        left["dependency_impact_status"] || right["dependency_impact_status"],
      "publication_authority" => left["publication_authority"] || right["publication_authority"],
      "source_artifact_type" => left["source_artifact_type"] || right["source_artifact_type"],
      "source_artifact_ids" =>
        stable_sorted_evidence_values(
          list_value(left["source_artifact_ids"]) ++ list_value(right["source_artifact_ids"])
        ),
      "supersedes_artifact_ids" =>
        stable_sorted_evidence_values(
          list_value(left["supersedes_artifact_ids"]) ++
            list_value(right["supersedes_artifact_ids"])
        ),
      "downstream_product_ids" =>
        stable_sorted_evidence_values(
          list_value(left["downstream_product_ids"]) ++
            list_value(right["downstream_product_ids"])
        ),
      "invalidated_downstream_product_ids" =>
        stable_sorted_evidence_values(
          list_value(left["invalidated_downstream_product_ids"]) ++
            list_value(right["invalidated_downstream_product_ids"])
        ),
      "impacted_dependency_activity_ids" =>
        stable_sorted_evidence_values(
          list_value(left["impacted_dependency_activity_ids"]) ++
            list_value(right["impacted_dependency_activity_ids"])
        ),
      "impacted_dependency_timeline_ids" =>
        stable_sorted_evidence_values(
          list_value(left["impacted_dependency_timeline_ids"]) ++
            list_value(right["impacted_dependency_timeline_ids"])
        ),
      "impacted_exclusive_with_activity_ids" =>
        stable_sorted_evidence_values(
          list_value(left["impacted_exclusive_with_activity_ids"]) ++
            list_value(right["impacted_exclusive_with_activity_ids"])
        ),
      "impacted_exclusive_with_timeline_ids" =>
        stable_sorted_evidence_values(
          list_value(left["impacted_exclusive_with_timeline_ids"]) ++
            list_value(right["impacted_exclusive_with_timeline_ids"])
        ),
      "changed_timeline_ids" =>
        stable_sorted_evidence_values(
          list_value(left["changed_timeline_ids"]) ++ list_value(right["changed_timeline_ids"])
        ),
      "review_timeline_ids" =>
        stable_sorted_evidence_values(
          list_value(left["review_timeline_ids"]) ++ list_value(right["review_timeline_ids"])
        ),
      "dependency_impact_row_count" =>
        max_integer(left["dependency_impact_row_count"], right["dependency_impact_row_count"]),
      "timeline_diff_row_count" =>
        max_integer(left["timeline_diff_row_count"], right["timeline_diff_row_count"]),
      "timeline_diff_changed_count" =>
        max_integer(left["timeline_diff_changed_count"], right["timeline_diff_changed_count"]),
      "timeline_diff_review_required_count" =>
        max_integer(
          left["timeline_diff_review_required_count"],
          right["timeline_diff_review_required_count"]
        ),
      "changed_field_counts" =>
        merge_max_count_maps([left["changed_field_counts"], right["changed_field_counts"]]),
      "timeline_ids_by_changed_field" =>
        merge_string_list_maps([
          left["timeline_ids_by_changed_field"],
          right["timeline_ids_by_changed_field"]
        ])
    }
    |> compact_map()
  end

  defp summarize_timeline_publication_contexts(contexts) do
    publication_status_counts =
      contexts |> Enum.map(& &1["publication_status"]) |> count_normalized_values()

    dependency_impact_status_counts =
      contexts |> Enum.map(& &1["dependency_impact_status"]) |> count_normalized_values()

    publication_authority_counts =
      contexts |> Enum.map(& &1["publication_authority"]) |> count_normalized_values()

    source_artifact_type_counts =
      contexts |> Enum.map(& &1["source_artifact_type"]) |> count_normalized_values()

    %{
      "publication_status_counts" => publication_status_counts,
      "dependency_impact_status_counts" => dependency_impact_status_counts,
      "publication_authority_counts" => publication_authority_counts,
      "source_artifact_type_counts" => source_artifact_type_counts,
      "publication_ids" =>
        contexts |> Enum.map(& &1["publication_id"]) |> stable_sorted_evidence_values(),
      "source_artifact_ids" => contexts |> merge_context_lists("source_artifact_ids"),
      "supersedes_artifact_ids" => contexts |> merge_context_lists("supersedes_artifact_ids"),
      "downstream_product_ids" => contexts |> merge_context_lists("downstream_product_ids"),
      "invalidated_downstream_product_ids" =>
        contexts |> merge_context_lists("invalidated_downstream_product_ids"),
      "dependency_impact_row_count" =>
        contexts |> Enum.map(& &1["dependency_impact_row_count"]) |> integer_sum(),
      "impacted_dependency_activity_ids" =>
        contexts |> merge_context_lists("impacted_dependency_activity_ids"),
      "impacted_dependency_timeline_ids" =>
        contexts |> merge_context_lists("impacted_dependency_timeline_ids"),
      "impacted_exclusive_with_activity_ids" =>
        contexts |> merge_context_lists("impacted_exclusive_with_activity_ids"),
      "impacted_exclusive_with_timeline_ids" =>
        contexts |> merge_context_lists("impacted_exclusive_with_timeline_ids"),
      "timeline_diff_row_count" =>
        contexts |> Enum.map(& &1["timeline_diff_row_count"]) |> integer_sum(),
      "timeline_diff_changed_count" =>
        contexts |> Enum.map(& &1["timeline_diff_changed_count"]) |> integer_sum(),
      "timeline_diff_review_required_count" =>
        contexts |> Enum.map(& &1["timeline_diff_review_required_count"]) |> integer_sum(),
      "changed_field_counts" =>
        contexts |> Enum.map(& &1["changed_field_counts"]) |> merge_positive_count_maps(),
      "changed_timeline_ids" => contexts |> merge_context_lists("changed_timeline_ids"),
      "review_timeline_ids" => contexts |> merge_context_lists("review_timeline_ids"),
      "timeline_ids_by_changed_field" =>
        contexts |> Enum.map(& &1["timeline_ids_by_changed_field"]) |> merge_string_list_maps()
    }
    |> drop_empty_timeline_publication_context()
  end

  def from_rows(rows) do
    contexts =
      rows
      |> Enum.filter(&is_map/1)
      |> Enum.map(
        &(Map.take(&1, timeline_publication_context_fields())
          |> drop_empty_timeline_publication_context())
      )
      |> Enum.reject(&(&1 == %{}))

    %{
      "publication_status_counts" =>
        contexts |> Enum.map(& &1["publication_status_counts"]) |> merge_positive_count_maps(),
      "dependency_impact_status_counts" =>
        contexts
        |> Enum.map(& &1["dependency_impact_status_counts"])
        |> merge_positive_count_maps(),
      "publication_authority_counts" =>
        contexts |> Enum.map(& &1["publication_authority_counts"]) |> merge_positive_count_maps(),
      "source_artifact_type_counts" =>
        contexts |> Enum.map(& &1["source_artifact_type_counts"]) |> merge_positive_count_maps(),
      "publication_ids" => contexts |> merge_context_lists("publication_ids"),
      "source_artifact_ids" => contexts |> merge_context_lists("source_artifact_ids"),
      "supersedes_artifact_ids" => contexts |> merge_context_lists("supersedes_artifact_ids"),
      "downstream_product_ids" => contexts |> merge_context_lists("downstream_product_ids"),
      "invalidated_downstream_product_ids" =>
        contexts |> merge_context_lists("invalidated_downstream_product_ids"),
      "dependency_impact_row_count" =>
        contexts |> Enum.map(& &1["dependency_impact_row_count"]) |> integer_sum(),
      "impacted_dependency_activity_ids" =>
        contexts |> merge_context_lists("impacted_dependency_activity_ids"),
      "impacted_dependency_timeline_ids" =>
        contexts |> merge_context_lists("impacted_dependency_timeline_ids"),
      "impacted_exclusive_with_activity_ids" =>
        contexts |> merge_context_lists("impacted_exclusive_with_activity_ids"),
      "impacted_exclusive_with_timeline_ids" =>
        contexts |> merge_context_lists("impacted_exclusive_with_timeline_ids"),
      "timeline_diff_row_count" =>
        contexts |> Enum.map(& &1["timeline_diff_row_count"]) |> integer_sum(),
      "timeline_diff_changed_count" =>
        contexts |> Enum.map(& &1["timeline_diff_changed_count"]) |> integer_sum(),
      "timeline_diff_review_required_count" =>
        contexts |> Enum.map(& &1["timeline_diff_review_required_count"]) |> integer_sum(),
      "changed_field_counts" =>
        contexts |> Enum.map(& &1["changed_field_counts"]) |> merge_positive_count_maps(),
      "changed_timeline_ids" => contexts |> merge_context_lists("changed_timeline_ids"),
      "review_timeline_ids" => contexts |> merge_context_lists("review_timeline_ids"),
      "timeline_ids_by_changed_field" =>
        contexts |> Enum.map(& &1["timeline_ids_by_changed_field"]) |> merge_string_list_maps()
    }
    |> drop_empty_timeline_publication_context()
  end

  def from_evidence(evidence) do
    evidence
    |> Map.take(timeline_publication_context_fields())
    |> drop_empty_timeline_publication_context()
  end

  defp timeline_publication_context_fields do
    ~w(
      publication_status_counts
      dependency_impact_status_counts
      publication_authority_counts
      source_artifact_type_counts
      publication_ids
      source_artifact_ids
      supersedes_artifact_ids
      downstream_product_ids
      invalidated_downstream_product_ids
      dependency_impact_row_count
      impacted_dependency_activity_ids
      impacted_dependency_timeline_ids
      impacted_exclusive_with_activity_ids
      impacted_exclusive_with_timeline_ids
      timeline_diff_row_count
      timeline_diff_changed_count
      timeline_diff_review_required_count
      changed_field_counts
      changed_timeline_ids
      review_timeline_ids
      timeline_ids_by_changed_field
    )
  end

  defp merge_context_lists(contexts, field) do
    contexts
    |> Enum.flat_map(&list_value(Map.get(&1, field)))
    |> stable_sorted_evidence_values()
  end

  defp count_normalized_values(values) do
    values
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp max_integer(left, right) do
    [left, right]
    |> Enum.filter(&is_integer/1)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp merge_max_count_maps(maps) do
    Enum.reduce(maps, %{}, fn
      %{} = counts, acc ->
        counts
        |> positive_count_map()
        |> Enum.reduce(acc, fn {key, count}, inner_acc ->
          Map.update(inner_acc, key, count, &max(&1, count))
        end)

      _counts, acc ->
        acc
    end)
  end

  defp drop_empty_timeline_publication_context(context) do
    context
    |> Enum.reject(fn
      {_key, value} when value in [nil, [], %{}] -> true
      {_key, value} when is_integer(value) and value == 0 -> true
      {_key, _value} -> false
    end)
    |> Map.new()
  end

  defp positive_count_map(%{} = counts) do
    counts
    |> Enum.filter(fn {_key, value} -> is_integer(value) and value > 0 end)
    |> Map.new()
  end

  defp positive_count_map(_counts), do: %{}

  defp merge_positive_count_maps(maps) do
    Enum.reduce(maps, %{}, fn
      %{} = counts, acc ->
        counts
        |> positive_count_map()
        |> Enum.reduce(acc, fn {key, count}, inner_acc ->
          Map.update(inner_acc, key, count, &(&1 + count))
        end)

      _counts, acc ->
        acc
    end)
  end

  defp integer_sum(values) do
    values
    |> Enum.map(&integer_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
  end

  defp integer_value(value) when is_integer(value), do: value
  defp integer_value(value) when is_float(value), do: trunc(value)

  defp integer_value(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} -> integer
      _parse_error -> nil
    end
  end

  defp integer_value(_value), do: nil

  defp list_value(values) when is_list(values), do: values
  defp list_value(value) when value in [nil, ""], do: []
  defp list_value(value), do: [value]

  defp normalized_evidence_string(value) when value in [nil, :null], do: nil

  defp normalized_evidence_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalized_evidence_string(value) when is_atom(value), do: value |> Atom.to_string()
  defp normalized_evidence_string(_value), do: nil

  defp stable_sorted_evidence_values(values) do
    values
    |> Enum.map(&normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stable_id_array_map(%{} = map) do
    map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      key = normalized_evidence_string(key)
      ids = values |> list_value() |> stable_sorted_evidence_values()

      if key && ids != [] do
        Map.put(acc, key, ids)
      else
        acc
      end
    end)
  end

  defp stable_id_array_map(_map), do: %{}

  defp merge_string_list_maps(maps) do
    Enum.reduce(maps, %{}, fn
      %{} = map, acc ->
        map
        |> stable_id_array_map()
        |> Enum.reduce(acc, fn {key, ids}, inner_acc ->
          Map.update(inner_acc, key, ids, fn current ->
            (current ++ ids)
            |> Enum.uniq()
            |> Enum.sort()
          end)
        end)

      _map, acc ->
        acc
    end)
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
