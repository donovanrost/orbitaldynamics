defmodule OrbitalDynamics.Schema.OperationalQualityGateImportReadinessSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CollectionAggregation

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_optional_field_equals: 6,
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
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  def validate_summary(issues, path, summary, model_limits, context_validator)
      when is_list(model_limits) and is_function(context_validator, 3) do
    freshness_counts = Map.get(summary, "freshness_status_counts")
    import_counts = Map.get(summary, "import_status_counts")
    cadence_import_counts = Map.get(summary, "cadence_import_status_counts")
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")
    quality_gate_ids_by_status = Map.get(summary, "quality_gate_ids_by_status")

    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "operational_quality_gate_import_readiness_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_quality_gate_import_readiness_summary"
    )
    |> expect_equal(path, summary, "source", "quality_gate_report.v1")
    |> expect_type(path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(path, summary, [
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id"
    ])
    |> expect_non_negative_integer(path, summary, "import_readiness_row_count")
    |> expect_non_negative_integer(path, summary, "ready_for_import_count")
    |> expect_non_negative_integer(path, summary, "manifest_review_required_count")
    |> expect_non_negative_integer(path, summary, "blocked_import_count")
    |> expect_non_negative_integer(path, summary, "missing_import_count")
    |> expect_non_negative_integer(path, summary, "invalid_cadence_import_count")
    |> expect_non_negative_integer(path, summary, "current_freshness_count")
    |> expect_non_negative_integer(path, summary, "stale_freshness_count")
    |> expect_non_negative_integer(path, summary, "unknown_freshness_count")
    |> expect_type(path, summary, "freshness_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".freshness_status_counts",
      freshness_counts
    )
    |> expect_type(path, summary, "freshness_status_ids", :list)
    |> validate_string_list_items(path, summary, "freshness_status_ids")
    |> expect_type(path, summary, "import_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".import_status_counts",
      import_counts
    )
    |> expect_type(path, summary, "import_status_ids", :list)
    |> validate_string_list_items(path, summary, "import_status_ids")
    |> expect_type(path, summary, "cadence_import_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".cadence_import_status_counts",
      cadence_import_counts
    )
    |> expect_type(path, summary, "cadence_import_status_ids", :list)
    |> validate_string_list_items(path, summary, "cadence_import_status_ids")
    |> expect_type(path, summary, "freshness_review_required", :boolean)
    |> expect_type(path, summary, "import_preparation_required", :boolean)
    |> expect_type(path, summary, "import_blocked", :boolean)
    |> expect_type(path, summary, "quality_gate_row_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".quality_gate_row_ids_by_status",
      quality_gate_row_ids_by_status
    )
    |> expect_type(path, summary, "quality_gate_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".quality_gate_ids_by_status",
      quality_gate_ids_by_status
    )
    |> validate_id_list_types(path, summary)
    |> expect_optional_type(path, summary, "analysis_only_quality_gate_row_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      summary,
      "analysis_only_quality_gate_row_ids"
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match quality gate import-readiness summary model limits"
    )
    |> validate_assumptions(path, summary)
    |> validate_counts(path, summary)
    |> validate_id_sets(path, summary)
    |> context_validator.(path, summary)
  end

  defp validate_id_list_types(issues, path, summary) do
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
      |> expect_type(path, summary, field, :list)
      |> validate_stable_id_list(path <> ".#{field}", Map.get(summary, field))
    end)
  end

  defp validate_assumptions(issues, path, summary) do
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
          expect_equal(acc, path <> ".assumptions", assumptions, field, expected)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, path, summary) do
    freshness_counts = Map.get(summary, "freshness_status_counts")
    import_counts = Map.get(summary, "import_status_counts")
    cadence_import_counts = Map.get(summary, "cadence_import_status_counts")

    issues
    |> expect_field_equals(
      path,
      summary,
      "import_readiness_row_count",
      CollectionAggregation.stable_id_array_map_value_count(
        Map.get(summary, "quality_gate_row_ids_by_status")
      ),
      "must equal quality-gate row IDs by status count"
    )
    |> expect_field_equals(
      path,
      summary,
      "ready_for_import_count",
      CollectionAggregation.non_negative_integer_map_value(import_counts, "ready_for_import"),
      "must equal import_status_counts ready_for_import count"
    )
    |> expect_field_equals(
      path,
      summary,
      "manifest_review_required_count",
      CollectionAggregation.non_negative_integer_map_value(
        import_counts,
        "review_required_before_import"
      ),
      "must equal import_status_counts review_required_before_import count"
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_import_count",
      CollectionAggregation.non_negative_integer_map_value(
        import_counts,
        "blocked_missing_cadence_import"
      ),
      "must equal import_status_counts blocked_missing_cadence_import count"
    )
    |> expect_field_equals(
      path,
      summary,
      "missing_import_count",
      CollectionAggregation.non_negative_integer_map_value(cadence_import_counts, "missing"),
      "must equal cadence_import_status_counts missing count"
    )
    |> expect_field_equals(
      path,
      summary,
      "invalid_cadence_import_count",
      CollectionAggregation.non_negative_integer_map_value(cadence_import_counts, "invalid"),
      "must equal cadence_import_status_counts invalid count"
    )
    |> expect_field_equals(
      path,
      summary,
      "current_freshness_count",
      CollectionAggregation.non_negative_integer_map_value(freshness_counts, "current"),
      "must equal freshness_status_counts current count"
    )
    |> expect_field_equals(
      path,
      summary,
      "stale_freshness_count",
      CollectionAggregation.non_negative_integer_map_value(freshness_counts, "stale"),
      "must equal freshness_status_counts stale count"
    )
    |> expect_field_equals(
      path,
      summary,
      "unknown_freshness_count",
      CollectionAggregation.non_negative_integer_map_value(freshness_counts, "unknown"),
      "must equal freshness_status_counts unknown count"
    )
    |> expect_field_equals(
      path,
      summary,
      "freshness_status_ids",
      CollectionAggregation.positive_count_map_keys(freshness_counts),
      "must equal freshness_status_counts keys with positive counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "import_status_ids",
      CollectionAggregation.positive_count_map_keys(import_counts),
      "must equal import_status_counts keys with positive counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "cadence_import_status_ids",
      CollectionAggregation.positive_count_map_keys(cadence_import_counts),
      "must equal cadence_import_status_counts keys with positive counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "freshness_review_required",
      freshness_review_required?(summary),
      "must match stale or unknown freshness evidence"
    )
    |> expect_field_equals(
      path,
      summary,
      "import_preparation_required",
      preparation_required?(summary),
      "must match review-required or missing import evidence"
    )
    |> expect_field_equals(
      path,
      summary,
      "import_blocked",
      blocked?(summary),
      "must match blocked or invalid import evidence"
    )
  end

  defp validate_id_sets(issues, path, summary) do
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    issues
    |> expect_field_equals(
      path,
      summary,
      "review_required_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "review_required", [])
      ),
      "must equal review-required quality-gate row IDs by status"
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "blocked", [])
      ),
      "must equal blocked quality-gate row IDs by status"
    )
    |> expect_field_equals(
      path,
      summary,
      "ready_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "passed", [])
      ),
      "must equal passed quality-gate row IDs by status"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "analysis_only_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "analysis_only", [])
      ),
      "must equal analysis-only quality-gate row IDs by status"
    )
    |> expect_field_equals(
      path,
      summary,
      "import_readiness_gate_ids",
      CollectionAggregation.stable_id_array_map_ids(
        Map.get(summary, "quality_gate_ids_by_status")
      ),
      "must equal quality-gate IDs by status"
    )
    |> validate_routing_ids(
      path,
      summary,
      "stale_or_unknown_freshness_quality_gate_row_ids",
      freshness_review_required?(summary),
      "must match stale or unknown freshness routing"
    )
    |> validate_routing_ids(
      path,
      summary,
      "import_preparation_quality_gate_row_ids",
      preparation_required?(summary),
      "must match review-required or missing import routing"
    )
    |> validate_routing_ids(
      path,
      summary,
      "blocked_import_quality_gate_row_ids",
      blocked?(summary),
      "must match blocked or invalid import routing"
    )
  end

  defp validate_routing_ids(issues, path, summary, field, expected?, message) do
    routing_ids = Map.get(summary, field)

    row_ids =
      CollectionAggregation.stable_id_array_map_ids(
        Map.get(summary, "quality_gate_row_ids_by_status")
      )

    cond do
      expected? == nil or not is_list(routing_ids) or not is_list(row_ids) ->
        issues

      not subset?(routing_ids, row_ids) ->
        [
          error(
            path <> ".#{field}",
            "must be present in quality-gate row IDs by status"
          )
          | issues
        ]

      expected? and routing_ids == [] ->
        [error(path <> ".#{field}", message) | issues]

      not expected? and routing_ids != [] ->
        [error(path <> ".#{field}", message) | issues]

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
end
