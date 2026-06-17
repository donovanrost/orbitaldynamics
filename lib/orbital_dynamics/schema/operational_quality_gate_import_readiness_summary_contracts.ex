defmodule OrbitalDynamics.Schema.OperationalQualityGateImportReadinessSummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    freshness_counts = Map.get(summary, "freshness_status_counts")
    import_counts = Map.get(summary, "import_status_counts")
    cadence_import_counts = Map.get(summary, "cadence_import_status_counts")
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")
    quality_gate_ids_by_status = Map.get(summary, "quality_gate_ids_by_status")

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "operational_quality_gate_import_readiness_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_quality_gate_import_readiness_summary"
    )
    |> expect_equal(callbacks, path, summary, "source", "quality_gate_report.v1")
    |> expect_type(callbacks, path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(callbacks, path, summary, [
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id"
    ])
    |> expect_non_negative_integer(callbacks, path, summary, "import_readiness_row_count")
    |> expect_non_negative_integer(callbacks, path, summary, "ready_for_import_count")
    |> expect_non_negative_integer(callbacks, path, summary, "manifest_review_required_count")
    |> expect_non_negative_integer(callbacks, path, summary, "blocked_import_count")
    |> expect_non_negative_integer(callbacks, path, summary, "missing_import_count")
    |> expect_non_negative_integer(callbacks, path, summary, "invalid_cadence_import_count")
    |> expect_non_negative_integer(callbacks, path, summary, "current_freshness_count")
    |> expect_non_negative_integer(callbacks, path, summary, "stale_freshness_count")
    |> expect_non_negative_integer(callbacks, path, summary, "unknown_freshness_count")
    |> expect_type(callbacks, path, summary, "freshness_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".freshness_status_counts",
      freshness_counts
    )
    |> expect_type(callbacks, path, summary, "freshness_status_ids", :list)
    |> validate_string_list_items(callbacks, path, summary, "freshness_status_ids")
    |> expect_type(callbacks, path, summary, "import_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".import_status_counts",
      import_counts
    )
    |> expect_type(callbacks, path, summary, "import_status_ids", :list)
    |> validate_string_list_items(callbacks, path, summary, "import_status_ids")
    |> expect_type(callbacks, path, summary, "cadence_import_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".cadence_import_status_counts",
      cadence_import_counts
    )
    |> expect_type(callbacks, path, summary, "cadence_import_status_ids", :list)
    |> validate_string_list_items(callbacks, path, summary, "cadence_import_status_ids")
    |> expect_type(callbacks, path, summary, "freshness_review_required", :boolean)
    |> expect_type(callbacks, path, summary, "import_preparation_required", :boolean)
    |> expect_type(callbacks, path, summary, "import_blocked", :boolean)
    |> expect_type(callbacks, path, summary, "quality_gate_row_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_row_ids_by_status",
      quality_gate_row_ids_by_status
    )
    |> expect_type(callbacks, path, summary, "quality_gate_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_ids_by_status",
      quality_gate_ids_by_status
    )
    |> validate_id_list_types(callbacks, path, summary)
    |> expect_optional_type(callbacks, path, summary, "analysis_only_quality_gate_row_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      summary,
      "analysis_only_quality_gate_row_ids"
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      quality_gate_import_readiness_summary_model_limits(callbacks),
      "must match quality gate import-readiness summary model limits"
    )
    |> validate_assumptions(callbacks, path, summary)
    |> validate_counts(callbacks, path, summary)
    |> validate_id_sets(callbacks, path, summary)
    |> validate_timeline_publication_context(callbacks, path, summary)
  end

  defp validate_id_list_types(issues, callbacks, path, summary) do
    [
      "review_required_quality_gate_row_ids",
      "blocked_quality_gate_row_ids",
      "ready_quality_gate_row_ids",
      "stale_or_unknown_freshness_quality_gate_row_ids",
      "import_preparation_quality_gate_row_ids",
      "blocked_import_quality_gate_row_ids",
      "import_readiness_gate_ids"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      acc
      |> expect_type(callbacks, path, summary, field, :list)
      |> validate_stable_id_list(callbacks, path <> ".#{field}", Map.get(summary, field))
    end)
  end

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        [
          {"source", "quality_gate_report.v1"},
          {"execution_boundary", "artifact_only_no_cadence_write"},
          {"operator_authority", "not_granted_by_import_readiness_summary"},
          {"cadence_write", "not_performed_by_summary"},
          {"command_execution", "not_performed_by_summary"}
        ]
        |> Enum.reduce(issues, fn {field, expected}, acc ->
          expect_equal(acc, callbacks, path <> ".assumptions", assumptions, field, expected)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, callbacks, path, summary) do
    freshness_counts = Map.get(summary, "freshness_status_counts")
    import_counts = Map.get(summary, "import_status_counts")
    cadence_import_counts = Map.get(summary, "cadence_import_status_counts")

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_readiness_row_count",
      stable_id_array_map_value_count(
        callbacks,
        Map.get(summary, "quality_gate_row_ids_by_status")
      ),
      "must equal quality-gate row IDs by status count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "ready_for_import_count",
      non_negative_integer_map_value(callbacks, import_counts, "ready_for_import"),
      "must equal import_status_counts ready_for_import count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "manifest_review_required_count",
      non_negative_integer_map_value(callbacks, import_counts, "review_required_before_import"),
      "must equal import_status_counts review_required_before_import count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_import_count",
      non_negative_integer_map_value(callbacks, import_counts, "blocked_missing_cadence_import"),
      "must equal import_status_counts blocked_missing_cadence_import count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "missing_import_count",
      non_negative_integer_map_value(callbacks, cadence_import_counts, "missing"),
      "must equal cadence_import_status_counts missing count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "invalid_cadence_import_count",
      non_negative_integer_map_value(callbacks, cadence_import_counts, "invalid"),
      "must equal cadence_import_status_counts invalid count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "current_freshness_count",
      non_negative_integer_map_value(callbacks, freshness_counts, "current"),
      "must equal freshness_status_counts current count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "stale_freshness_count",
      non_negative_integer_map_value(callbacks, freshness_counts, "stale"),
      "must equal freshness_status_counts stale count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "unknown_freshness_count",
      non_negative_integer_map_value(callbacks, freshness_counts, "unknown"),
      "must equal freshness_status_counts unknown count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "freshness_status_ids",
      positive_count_map_keys(callbacks, freshness_counts),
      "must equal freshness_status_counts keys with positive counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_status_ids",
      positive_count_map_keys(callbacks, import_counts),
      "must equal import_status_counts keys with positive counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "cadence_import_status_ids",
      positive_count_map_keys(callbacks, cadence_import_counts),
      "must equal cadence_import_status_counts keys with positive counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "freshness_review_required",
      freshness_review_required?(summary),
      "must match stale or unknown freshness evidence"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_preparation_required",
      preparation_required?(summary),
      "must match review-required or missing import evidence"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_blocked",
      blocked?(summary),
      "must match blocked or invalid import evidence"
    )
  end

  defp validate_id_sets(issues, callbacks, path, summary) do
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_required_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "review_required", [])
      ),
      "must equal review-required quality-gate row IDs by status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "blocked", [])
      ),
      "must equal blocked quality-gate row IDs by status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "ready_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "passed", [])
      ),
      "must equal passed quality-gate row IDs by status"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "analysis_only_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "analysis_only", [])
      ),
      "must equal analysis-only quality-gate row IDs by status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_readiness_gate_ids",
      stable_id_array_map_ids(callbacks, Map.get(summary, "quality_gate_ids_by_status")),
      "must equal quality-gate IDs by status"
    )
    |> validate_routing_ids(
      callbacks,
      path,
      summary,
      "stale_or_unknown_freshness_quality_gate_row_ids",
      freshness_review_required?(summary),
      "must match stale or unknown freshness routing"
    )
    |> validate_routing_ids(
      callbacks,
      path,
      summary,
      "import_preparation_quality_gate_row_ids",
      preparation_required?(summary),
      "must match review-required or missing import routing"
    )
    |> validate_routing_ids(
      callbacks,
      path,
      summary,
      "blocked_import_quality_gate_row_ids",
      blocked?(summary),
      "must match blocked or invalid import routing"
    )
  end

  defp validate_routing_ids(issues, callbacks, path, summary, field, expected?, message) do
    routing_ids = Map.get(summary, field)

    row_ids =
      stable_id_array_map_ids(callbacks, Map.get(summary, "quality_gate_row_ids_by_status"))

    cond do
      expected? == nil or not is_list(routing_ids) or not is_list(row_ids) ->
        issues

      not subset?(routing_ids, row_ids) ->
        [
          error(
            callbacks,
            path <> ".#{field}",
            "must be present in quality-gate row IDs by status"
          )
          | issues
        ]

      expected? and routing_ids == [] ->
        [error(callbacks, path <> ".#{field}", message) | issues]

      not expected? and routing_ids != [] ->
        [error(callbacks, path <> ".#{field}", message) | issues]

      true ->
        issues
    end
  end

  defp freshness_review_required?(summary) when is_map(summary) do
    with stale when is_integer(stale) <- Map.get(summary, "stale_freshness_count"),
         unknown when is_integer(unknown) <- Map.get(summary, "unknown_freshness_count") do
      stale > 0 or unknown > 0
    else
      _value -> nil
    end
  end

  defp preparation_required?(summary) when is_map(summary) do
    with review when is_integer(review) <- Map.get(summary, "manifest_review_required_count"),
         missing when is_integer(missing) <- Map.get(summary, "missing_import_count") do
      review > 0 or missing > 0
    else
      _value -> nil
    end
  end

  defp blocked?(summary) when is_map(summary) do
    with blocked when is_integer(blocked) <- Map.get(summary, "blocked_import_count"),
         invalid when is_integer(invalid) <- Map.get(summary, "invalid_cadence_import_count") do
      blocked > 0 or invalid > 0
    else
      _value -> nil
    end
  end

  defp subset?(ids, row_ids) do
    row_id_set = MapSet.new(row_ids)
    Enum.all?(ids, &MapSet.member?(row_id_set, &1))
  end

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_optional_field_equals), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message) do
    apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      artifact,
      expected,
      message
    ])
  end

  defp validate_timeline_publication_context(issues, callbacks, path, summary) do
    apply(Keyword.fetch!(callbacks, :validate_timeline_publication_context), [
      issues,
      path,
      summary
    ])
  end

  defp quality_gate_import_readiness_summary_model_limits(callbacks) do
    apply(Keyword.fetch!(callbacks, :quality_gate_import_readiness_summary_model_limits), [])
  end

  defp stable_id_array_map_value_count(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :stable_id_array_map_value_count), [values])

  defp stable_id_array_map_ids(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :stable_id_array_map_ids), [values])

  defp positive_count_map_keys(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :positive_count_map_keys), [values])

  defp non_negative_integer_map_value(callbacks, values, key),
    do: apply(Keyword.fetch!(callbacks, :non_negative_integer_map_value), [values, key])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
