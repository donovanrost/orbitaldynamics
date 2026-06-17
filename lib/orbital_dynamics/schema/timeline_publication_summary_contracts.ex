defmodule OrbitalDynamics.Schema.TimelinePublicationSummaryContracts do
  @moduledoc false

  def validate(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "timeline_publication_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_timeline_publication_summary"
    )
    |> expect_equal(callbacks, path, summary, "validation_level", "artifact_contract")
    |> expect_type(callbacks, path, summary, "source", :binary)
    |> expect_type(callbacks, path, summary, "source_artifact_type", :binary)
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "source",
      Map.get(summary, "source_artifact_type"),
      "must equal source_artifact_type"
    )
    |> validate_stable_ids(callbacks, path, summary, [
      "publication_id",
      "publication_authority",
      "source_artifact_id"
    ])
    |> expect_non_negative_integer(callbacks, path, summary, "publication_sequence")
    |> expect_one_of(callbacks, path, summary, "publication_status", [
      "published",
      "published_with_downstream_invalidations",
      "review_required"
    ])
    |> expect_optional_one_of(callbacks, path, summary, "downstream_invalidation_status", [
      "clear",
      "invalidated"
    ])
    |> expect_one_of(callbacks, path, summary, "dependency_impact_status", [
      "clear",
      "not_evaluated",
      "review_required"
    ])
    |> expect_non_negative_integer(callbacks, path, summary, "dependency_impact_row_count")
    |> validate_id_fields(callbacks, path, summary)
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      timeline_report_model_limits(callbacks),
      "must match timeline report model limits"
    )
    |> validate_diff_audit(callbacks, path, summary)
    |> validate_dependency_impact_source(callbacks, path, summary)
    |> validate_derived_fields(callbacks, path, summary)
  end

  defp validate_id_fields(issues, callbacks, path, summary) do
    [
      "supersedes_artifact_ids",
      "downstream_product_ids",
      "invalidated_downstream_product_ids"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      acc
      |> expect_type(callbacks, path, summary, field, :list)
      |> validate_optional_stable_id_list(callbacks, path, summary, field)
    end)
    |> validate_optional_dependency_impact_id_fields(callbacks, path, summary)
  end

  defp validate_optional_dependency_impact_id_fields(issues, callbacks, path, summary) do
    [
      "impacted_source_activity_ids",
      "impacted_source_timeline_ids",
      "dependent_activity_ids",
      "dependent_timeline_ids",
      "source_dependent_activity_ids",
      "source_dependent_timeline_ids",
      "replacement_dependent_activity_ids",
      "replacement_dependent_timeline_ids",
      "impacted_dependency_activity_ids",
      "impacted_dependency_timeline_ids",
      "impacted_exclusive_with_activity_ids",
      "impacted_exclusive_with_timeline_ids"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      acc
      |> expect_optional_type(callbacks, path, summary, field, :list)
      |> validate_optional_stable_id_list(callbacks, path, summary, field)
    end)
  end

  defp validate_derived_fields(issues, callbacks, path, summary) do
    expected_status =
      cond do
        list_value(summary, "invalidated_downstream_product_ids") != [] ->
          "published_with_downstream_invalidations"

        summary["dependency_impact_status"] == "review_required" ->
          "review_required"

        true ->
          "published"
      end

    expected_downstream_invalidation_status =
      if list_value(summary, "invalidated_downstream_product_ids") == [] do
        "clear"
      else
        "invalidated"
      end

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "publication_status",
      expected_status,
      "must equal downstream invalidation and dependency impact state"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "downstream_invalidation_status",
      expected_downstream_invalidation_status,
      "must equal invalidated_downstream_product_ids state"
    )
    |> validate_dependency_count(callbacks, path, summary)
    |> validate_no_impact_without_review(callbacks, path, summary)
    |> validate_invalidation_subset(callbacks, path, summary)
    |> validate_invalidation_reasons(callbacks, path, summary)
  end

  defp validate_diff_audit(issues, callbacks, path, summary) do
    source_summary = Map.get(summary, "source_timeline_diff_summary")

    issues
    |> expect_optional_type(callbacks, path, summary, "source_timeline_diff_summary", :map)
    |> validate_diff_audit_count_fields(callbacks, path, summary)
    |> validate_diff_audit_routing_fields(callbacks, path, summary)
    |> validate_optional_timeline_diff_summary_source(
      callbacks,
      path <> ".source_timeline_diff_summary",
      source_summary
    )
    |> validate_diff_audit_source(callbacks, path, summary, source_summary)
  end

  defp validate_diff_audit_count_fields(issues, callbacks, path, summary) do
    count_fields = [
      "timeline_diff_row_count",
      "timeline_diff_changed_count",
      "timeline_diff_review_required_count"
    ]

    issues =
      Enum.reduce(count_fields, issues, fn field, acc ->
        expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
      end)

    issues
    |> expect_optional_type(callbacks, path, summary, "changed_field_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".changed_field_counts",
      Map.get(summary, "changed_field_counts")
    )
  end

  defp validate_diff_audit_routing_fields(issues, callbacks, path, summary) do
    id_fields = [
      "changed_timeline_ids",
      "review_timeline_ids"
    ]

    issues =
      Enum.reduce(id_fields, issues, fn field, acc ->
        acc
        |> expect_optional_type(callbacks, path, summary, field, :list)
        |> validate_optional_stable_id_list(callbacks, path, summary, field)
      end)

    issues
    |> expect_optional_type(callbacks, path, summary, "timeline_ids_by_changed_field", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".timeline_ids_by_changed_field",
      Map.get(summary, "timeline_ids_by_changed_field")
    )
  end

  defp validate_diff_audit_source(issues, callbacks, path, summary, %{} = source_summary) do
    issues
    |> require_diff_audit_fields(callbacks, path, summary)
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "timeline_diff_row_count",
      Map.get(source_summary, "row_count"),
      "must equal source_timeline_diff_summary.row_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "timeline_diff_changed_count",
      Map.get(source_summary, "changed_count"),
      "must equal source_timeline_diff_summary.changed_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "timeline_diff_review_required_count",
      Map.get(source_summary, "review_required_count"),
      "must equal source_timeline_diff_summary.review_required_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "changed_field_counts",
      Map.get(source_summary, "changed_field_counts"),
      "must equal source_timeline_diff_summary.changed_field_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "changed_timeline_ids",
      Map.get(source_summary, "changed_timeline_ids"),
      "must equal source_timeline_diff_summary.changed_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_timeline_ids",
      Map.get(source_summary, "review_timeline_ids"),
      "must equal source_timeline_diff_summary.review_timeline_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "timeline_ids_by_changed_field",
      Map.get(source_summary, "timeline_ids_by_changed_field"),
      "must equal source_timeline_diff_summary.timeline_ids_by_changed_field"
    )
  end

  defp validate_diff_audit_source(issues, callbacks, path, summary, _source) do
    audit_fields = [
      "timeline_diff_row_count",
      "timeline_diff_changed_count",
      "timeline_diff_review_required_count",
      "changed_field_counts",
      "changed_timeline_ids",
      "review_timeline_ids",
      "timeline_ids_by_changed_field"
    ]

    if Enum.any?(audit_fields, &Map.has_key?(summary, &1)) do
      [
        error(
          callbacks,
          path <> ".source_timeline_diff_summary",
          "must be present when timeline diff audit fields are present"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp require_diff_audit_fields(issues, callbacks, path, summary) do
    [
      "timeline_diff_row_count",
      "timeline_diff_changed_count",
      "timeline_diff_review_required_count",
      "changed_field_counts",
      "changed_timeline_ids",
      "review_timeline_ids",
      "timeline_ids_by_changed_field"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      if Map.has_key?(summary, field) do
        acc
      else
        [
          error(
            callbacks,
            "#{path}.#{field}",
            "must be present when source_timeline_diff_summary is present"
          )
          | acc
        ]
      end
    end)
  end

  defp validate_dependency_impact_source(issues, callbacks, path, summary) do
    source_summary = Map.get(summary, "source_timeline_dependency_impact_summary")

    issues
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "source_timeline_dependency_impact_summary",
      :map
    )
    |> validate_optional_timeline_dependency_impact_summary_source(
      callbacks,
      path <> ".source_timeline_dependency_impact_summary",
      source_summary
    )
    |> validate_dependency_impact_source_fields(callbacks, path, summary, source_summary)
  end

  defp validate_dependency_impact_source_fields(
         issues,
         callbacks,
         path,
         summary,
         %{} = source_summary
       ) do
    issues
    |> require_dependency_impact_fields(callbacks, path, summary)
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "dependency_impact_status",
      Map.get(source_summary, "dependency_impact_status"),
      "must equal source_timeline_dependency_impact_summary.dependency_impact_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "dependency_impact_row_count",
      source_summary |> Map.get("dependency_impact_rows", []) |> length(),
      "must equal source_timeline_dependency_impact_summary row count"
    )
    |> expect_dependency_impact_id_fields(callbacks, path, summary, source_summary)
  end

  defp validate_dependency_impact_source_fields(issues, _callbacks, _path, _summary, _source) do
    issues
  end

  defp require_dependency_impact_fields(issues, callbacks, path, summary) do
    dependency_impact_source_field_pairs()
    |> Enum.reduce(issues, fn {field, _source_field}, acc ->
      if Map.has_key?(summary, field) do
        acc
      else
        [
          error(
            callbacks,
            "#{path}.#{field}",
            "must be present when source_timeline_dependency_impact_summary is present"
          )
          | acc
        ]
      end
    end)
  end

  defp expect_dependency_impact_id_fields(issues, callbacks, path, summary, source_summary) do
    dependency_impact_source_field_pairs()
    |> Enum.reduce(issues, fn {field, source_field}, acc ->
      expect_field_equals(
        acc,
        callbacks,
        path,
        summary,
        field,
        Map.get(source_summary, source_field),
        "must equal source_timeline_dependency_impact_summary.#{source_field}"
      )
    end)
  end

  defp dependency_impact_source_field_pairs do
    [
      {"impacted_source_activity_ids", "impacted_source_activity_ids"},
      {"impacted_source_timeline_ids", "impacted_source_timeline_ids"},
      {"dependent_activity_ids", "dependent_activity_ids"},
      {"dependent_timeline_ids", "dependent_timeline_ids"},
      {"source_dependent_activity_ids", "source_dependent_activity_ids"},
      {"source_dependent_timeline_ids", "source_dependent_timeline_ids"},
      {"replacement_dependent_activity_ids", "replacement_dependent_activity_ids"},
      {"replacement_dependent_timeline_ids", "replacement_dependent_timeline_ids"},
      {"impacted_dependency_activity_ids", "impacted_dependency_activity_ids"},
      {"impacted_dependency_timeline_ids", "impacted_dependency_timeline_ids"},
      {"impacted_exclusive_with_activity_ids", "impacted_exclusive_with_activity_ids"},
      {"impacted_exclusive_with_timeline_ids", "impacted_exclusive_with_timeline_ids"}
    ]
  end

  defp validate_dependency_count(issues, callbacks, path, summary) do
    if summary["dependency_impact_status"] in ["clear", "not_evaluated"] do
      expect_field_equals(
        issues,
        callbacks,
        path,
        summary,
        "dependency_impact_row_count",
        0,
        "must be zero unless dependency_impact_status is review_required"
      )
    else
      issues
    end
  end

  defp validate_no_impact_without_review(issues, callbacks, path, summary) do
    if summary["dependency_impact_status"] in ["clear", "not_evaluated"] do
      [
        "impacted_source_activity_ids",
        "impacted_source_timeline_ids",
        "dependent_activity_ids",
        "dependent_timeline_ids",
        "source_dependent_activity_ids",
        "source_dependent_timeline_ids",
        "replacement_dependent_activity_ids",
        "replacement_dependent_timeline_ids",
        "impacted_dependency_activity_ids",
        "impacted_dependency_timeline_ids",
        "impacted_exclusive_with_activity_ids",
        "impacted_exclusive_with_timeline_ids"
      ]
      |> Enum.reduce(issues, fn field, acc ->
        if Map.has_key?(summary, field) do
          expect_field_equals(
            acc,
            callbacks,
            path,
            summary,
            field,
            [],
            "must be empty unless dependency_impact_status is review_required"
          )
        else
          acc
        end
      end)
    else
      issues
    end
  end

  defp validate_invalidation_subset(issues, callbacks, path, summary) do
    downstream_product_ids =
      case Map.get(summary, "downstream_product_ids") do
        ids when is_list(ids) -> MapSet.new(ids)
        _ids -> MapSet.new()
      end

    case Map.get(summary, "invalidated_downstream_product_ids") do
      ids when is_list(ids) ->
        ids
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {id, index}, acc ->
          if is_binary(id) and not MapSet.member?(downstream_product_ids, id) do
            [
              error(
                callbacks,
                "#{path}.invalidated_downstream_product_ids[#{index}]",
                "must be included in downstream_product_ids"
              )
              | acc
            ]
          else
            acc
          end
        end)

      _ids ->
        issues
    end
  end

  defp validate_invalidation_reasons(issues, callbacks, path, summary) do
    expected_ids_by_reason = expected_invalidation_ids_by_reason(summary)

    expected_reason_counts =
      invalidation_reason_counts(expected_ids_by_reason)

    issues
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "downstream_invalidation_reason_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".downstream_invalidation_reason_counts",
      Map.get(summary, "downstream_invalidation_reason_counts")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "invalidated_downstream_product_ids_by_reason",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".invalidated_downstream_product_ids_by_reason",
      Map.get(summary, "invalidated_downstream_product_ids_by_reason")
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "downstream_invalidation_reason_counts",
      expected_reason_counts,
      "must equal invalidated downstream product reason counts"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "invalidated_downstream_product_ids_by_reason",
      expected_ids_by_reason,
      "must equal invalidated downstream product IDs grouped by reason"
    )
  end

  defp expected_invalidation_ids_by_reason(summary) do
    invalidated_ids = list_value(summary, "invalidated_downstream_product_ids")

    cond do
      invalidated_ids == [] ->
        %{}

      summary["dependency_impact_status"] == "review_required" ->
        %{"dependency_impact_review_required" => invalidated_ids}

      list_value(summary, "supersedes_artifact_ids") != [] ->
        %{"superseded_publication" => invalidated_ids}

      true ->
        %{"explicit_downstream_invalidation" => invalidated_ids}
    end
  end

  defp invalidation_reason_counts(ids_by_reason) do
    ids_by_reason
    |> Enum.map(fn {reason, ids} -> {reason, length(ids)} end)
    |> Map.new()
  end

  defp list_value(map, key) when is_map(map), do: Map.get(map, key) || []
  defp list_value(_map, _key), do: []

  defp timeline_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_report_model_limits), [])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_field_equals), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts),
    do:
      apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        counts
      ])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_optional_exact_model_limits(issues, callbacks, path, summary, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        summary,
        expected,
        message
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, summary, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        summary,
        field
      ])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_timeline_diff_summary_source(issues, callbacks, path, source),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_timeline_diff_summary_source), [
        issues,
        path,
        source
      ])

  defp validate_optional_timeline_dependency_impact_summary_source(
         issues,
         callbacks,
         path,
         source
       ),
       do:
         apply(
           Keyword.fetch!(
             callbacks,
             :validate_optional_timeline_dependency_impact_summary_source
           ),
           [issues, path, source]
         )
end
