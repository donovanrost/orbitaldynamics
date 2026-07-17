defmodule OrbitalDynamics.Schema.TimelinePublicationSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.TimelineDependencyImpactSummaryContracts
  alias OrbitalDynamics.Schema.TimelineDiffSummaryContracts

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_field_equals: 6,
      expect_optional_non_negative_integer: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_ids: 4
    ]

  def validate(issues, path, summary) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "timeline_publication_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_timeline_publication_summary"
    )
    |> expect_equal(path, summary, "validation_level", "artifact_contract")
    |> expect_type(path, summary, "source", :binary)
    |> expect_type(path, summary, "source_artifact_type", :binary)
    |> expect_field_equals(
      path,
      summary,
      "source",
      Map.get(summary, "source_artifact_type"),
      "must equal source_artifact_type"
    )
    |> validate_stable_ids(path, summary, [
      "publication_id",
      "publication_authority",
      "source_artifact_id"
    ])
    |> expect_non_negative_integer(path, summary, "publication_sequence")
    |> expect_one_of(path, summary, "publication_status", [
      "published",
      "published_with_downstream_invalidations",
      "review_required"
    ])
    |> expect_optional_one_of(path, summary, "downstream_invalidation_status", [
      "clear",
      "invalidated"
    ])
    |> expect_one_of(path, summary, "dependency_impact_status", [
      "clear",
      "not_evaluated",
      "review_required"
    ])
    |> expect_non_negative_integer(path, summary, "dependency_impact_row_count")
    |> validate_id_fields(path, summary)
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      timeline_report_model_limits(),
      "must match timeline report model limits"
    )
    |> validate_diff_audit(path, summary)
    |> validate_dependency_impact_source(path, summary)
    |> validate_derived_fields(path, summary)
  end

  defp validate_id_fields(issues, path, summary) do
    [
      "supersedes_artifact_ids",
      "downstream_product_ids",
      "invalidated_downstream_product_ids"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      acc
      |> expect_type(path, summary, field, :list)
      |> validate_optional_stable_id_list(path, summary, field)
    end)
    |> validate_optional_dependency_impact_id_fields(path, summary)
  end

  defp validate_optional_dependency_impact_id_fields(issues, path, summary) do
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
      |> expect_optional_type(path, summary, field, :list)
      |> validate_optional_stable_id_list(path, summary, field)
    end)
  end

  defp validate_derived_fields(issues, path, summary) do
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
      path,
      summary,
      "publication_status",
      expected_status,
      "must equal downstream invalidation and dependency impact state"
    )
    |> expect_field_equals(
      path,
      summary,
      "downstream_invalidation_status",
      expected_downstream_invalidation_status,
      "must equal invalidated_downstream_product_ids state"
    )
    |> validate_dependency_count(path, summary)
    |> validate_no_impact_without_review(path, summary)
    |> validate_invalidation_subset(path, summary)
    |> validate_invalidation_reasons(path, summary)
  end

  defp validate_diff_audit(issues, path, summary) do
    source_summary = Map.get(summary, "source_timeline_diff_summary")

    issues
    |> expect_optional_type(path, summary, "source_timeline_diff_summary", :map)
    |> validate_diff_audit_count_fields(path, summary)
    |> validate_diff_audit_routing_fields(path, summary)
    |> validate_optional_timeline_diff_summary_source(
      path <> ".source_timeline_diff_summary",
      source_summary
    )
    |> validate_diff_audit_source(path, summary, source_summary)
  end

  defp validate_diff_audit_count_fields(issues, path, summary) do
    count_fields = [
      "timeline_diff_row_count",
      "timeline_diff_changed_count",
      "timeline_diff_review_required_count"
    ]

    issues =
      Enum.reduce(count_fields, issues, fn field, acc ->
        expect_optional_non_negative_integer(acc, path, summary, field)
      end)

    issues
    |> expect_optional_type(path, summary, "changed_field_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".changed_field_counts",
      Map.get(summary, "changed_field_counts")
    )
  end

  defp validate_diff_audit_routing_fields(issues, path, summary) do
    id_fields = [
      "changed_timeline_ids",
      "review_timeline_ids"
    ]

    issues =
      Enum.reduce(id_fields, issues, fn field, acc ->
        acc
        |> expect_optional_type(path, summary, field, :list)
        |> validate_optional_stable_id_list(path, summary, field)
      end)

    issues
    |> expect_optional_type(path, summary, "timeline_ids_by_changed_field", :map)
    |> validate_stable_id_array_map(
      path <> ".timeline_ids_by_changed_field",
      Map.get(summary, "timeline_ids_by_changed_field")
    )
  end

  defp validate_diff_audit_source(issues, path, summary, %{} = source_summary) do
    issues
    |> require_diff_audit_fields(path, summary)
    |> expect_field_equals(
      path,
      summary,
      "timeline_diff_row_count",
      Map.get(source_summary, "row_count"),
      "must equal source_timeline_diff_summary.row_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "timeline_diff_changed_count",
      Map.get(source_summary, "changed_count"),
      "must equal source_timeline_diff_summary.changed_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "timeline_diff_review_required_count",
      Map.get(source_summary, "review_required_count"),
      "must equal source_timeline_diff_summary.review_required_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "changed_field_counts",
      Map.get(source_summary, "changed_field_counts"),
      "must equal source_timeline_diff_summary.changed_field_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "changed_timeline_ids",
      Map.get(source_summary, "changed_timeline_ids"),
      "must equal source_timeline_diff_summary.changed_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_timeline_ids",
      Map.get(source_summary, "review_timeline_ids"),
      "must equal source_timeline_diff_summary.review_timeline_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "timeline_ids_by_changed_field",
      Map.get(source_summary, "timeline_ids_by_changed_field"),
      "must equal source_timeline_diff_summary.timeline_ids_by_changed_field"
    )
  end

  defp validate_diff_audit_source(issues, path, summary, _source) do
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
          path <> ".source_timeline_diff_summary",
          "must be present when timeline diff audit fields are present"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp require_diff_audit_fields(issues, path, summary) do
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
            "#{path}.#{field}",
            "must be present when source_timeline_diff_summary is present"
          )
          | acc
        ]
      end
    end)
  end

  defp validate_dependency_impact_source(issues, path, summary) do
    source_summary = Map.get(summary, "source_timeline_dependency_impact_summary")

    issues
    |> expect_optional_type(
      path,
      summary,
      "source_timeline_dependency_impact_summary",
      :map
    )
    |> validate_optional_timeline_dependency_impact_summary_source(
      path <> ".source_timeline_dependency_impact_summary",
      source_summary
    )
    |> validate_dependency_impact_source_fields(path, summary, source_summary)
  end

  defp validate_dependency_impact_source_fields(
         issues,
         path,
         summary,
         %{} = source_summary
       ) do
    issues
    |> require_dependency_impact_fields(path, summary)
    |> expect_field_equals(
      path,
      summary,
      "dependency_impact_status",
      Map.get(source_summary, "dependency_impact_status"),
      "must equal source_timeline_dependency_impact_summary.dependency_impact_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "dependency_impact_row_count",
      source_summary |> Map.get("dependency_impact_rows", []) |> length(),
      "must equal source_timeline_dependency_impact_summary row count"
    )
    |> expect_dependency_impact_id_fields(path, summary, source_summary)
  end

  defp validate_dependency_impact_source_fields(issues, __path, _summary, _source) do
    issues
  end

  defp require_dependency_impact_fields(issues, path, summary) do
    dependency_impact_source_field_pairs()
    |> Enum.reduce(issues, fn {field, _source_field}, acc ->
      if Map.has_key?(summary, field) do
        acc
      else
        [
          error(
            "#{path}.#{field}",
            "must be present when source_timeline_dependency_impact_summary is present"
          )
          | acc
        ]
      end
    end)
  end

  defp expect_dependency_impact_id_fields(issues, path, summary, source_summary) do
    dependency_impact_source_field_pairs()
    |> Enum.reduce(issues, fn {field, source_field}, acc ->
      expect_field_equals(
        acc,
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

  defp validate_dependency_count(issues, path, summary) do
    if summary["dependency_impact_status"] in ["clear", "not_evaluated"] do
      expect_field_equals(
        issues,
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

  defp validate_no_impact_without_review(issues, path, summary) do
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

  defp validate_invalidation_subset(issues, path, summary) do
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

  defp validate_invalidation_reasons(issues, path, summary) do
    expected_ids_by_reason = expected_invalidation_ids_by_reason(summary)

    expected_reason_counts =
      invalidation_reason_counts(expected_ids_by_reason)

    issues
    |> expect_optional_type(
      path,
      summary,
      "downstream_invalidation_reason_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      path <> ".downstream_invalidation_reason_counts",
      Map.get(summary, "downstream_invalidation_reason_counts")
    )
    |> expect_optional_type(
      path,
      summary,
      "invalidated_downstream_product_ids_by_reason",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".invalidated_downstream_product_ids_by_reason",
      Map.get(summary, "invalidated_downstream_product_ids_by_reason")
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "downstream_invalidation_reason_counts",
      expected_reason_counts,
      "must equal invalidated downstream product reason counts"
    )
    |> expect_optional_field_equals(
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

  def validate_optional_timeline_diff_summary_source(issues, _path, nil), do: issues

  def validate_optional_timeline_diff_summary_source(issues, path, %{} = summary),
    do:
      TimelineDiffSummaryContracts.validate(issues, path, summary, timeline_report_model_limits())

  def validate_optional_timeline_diff_summary_source(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_dependency_impact_summary_source(issues, _path, nil),
    do: issues

  def validate_optional_timeline_dependency_impact_summary_source(issues, path, %{} = summary),
    do:
      TimelineDependencyImpactSummaryContracts.validate(
        issues,
        path,
        summary,
        timeline_report_model_limits()
      )

  def validate_optional_timeline_dependency_impact_summary_source(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  defp timeline_report_model_limits do
    OrbitalDynamics.Timeline.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
