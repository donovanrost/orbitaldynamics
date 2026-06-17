defmodule OrbitalDynamics.Schema.OperationalQualityGateSchemaValidationSummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    status_counts = Map.get(summary, "schema_validation_status_counts")
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")
    quality_gate_ids_by_status = Map.get(summary, "quality_gate_ids_by_status")

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "operational_quality_gate_schema_validation_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_quality_gate_schema_validation_summary"
    )
    |> expect_equal(callbacks, path, summary, "source", "quality_gate_report.v1")
    |> expect_type(callbacks, path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(callbacks, path, summary, [
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id"
    ])
    |> expect_non_negative_integer(callbacks, path, summary, "schema_validation_row_count")
    |> expect_non_negative_integer(callbacks, path, summary, "schema_validation_pass_count")
    |> expect_non_negative_integer(callbacks, path, summary, "schema_validation_fail_count")
    |> expect_non_negative_integer(callbacks, path, summary, "schema_validation_error_count")
    |> expect_non_negative_integer(callbacks, path, summary, "schema_validation_warning_count")
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "schema_validation_remediation_count"
    )
    |> expect_type(callbacks, path, summary, "schema_validation_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".schema_validation_status_counts",
      status_counts
    )
    |> expect_type(callbacks, path, summary, "schema_validation_status_ids", :list)
    |> validate_string_list_items(callbacks, path, summary, "schema_validation_status_ids")
    |> expect_type(callbacks, path, summary, "schema_validation_import_blocked", :boolean)
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
    |> expect_type(callbacks, path, summary, "blocked_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".blocked_quality_gate_row_ids",
      Map.get(summary, "blocked_quality_gate_row_ids")
    )
    |> expect_type(callbacks, path, summary, "review_required_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".review_required_quality_gate_row_ids",
      Map.get(summary, "review_required_quality_gate_row_ids")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "failed_schema_validation_quality_gate_row_ids",
      :list
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".failed_schema_validation_quality_gate_row_ids",
      Map.get(summary, "failed_schema_validation_quality_gate_row_ids")
    )
    |> expect_type(callbacks, path, summary, "schema_validation_gate_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".schema_validation_gate_ids",
      Map.get(summary, "schema_validation_gate_ids")
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      quality_gate_schema_validation_summary_model_limits(callbacks),
      "must match quality gate schema-validation summary model limits"
    )
    |> validate_assumptions(callbacks, path, summary)
    |> validate_counts(callbacks, path, summary)
    |> validate_id_sets(callbacks, path, summary)
  end

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        [
          {"source", "quality_gate_report.v1"},
          {"execution_boundary", "artifact_only_no_cadence_write"},
          {"operator_authority", "not_granted_by_schema_validation_summary"},
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
    status_counts = Map.get(summary, "schema_validation_status_counts")

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "schema_validation_row_count",
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
      "schema_validation_pass_count",
      non_negative_integer_map_value(callbacks, status_counts, "pass"),
      "must equal schema_validation_status_counts pass count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "schema_validation_fail_count",
      non_negative_integer_map_value(callbacks, status_counts, "fail"),
      "must equal schema_validation_status_counts fail count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "schema_validation_status_ids",
      positive_count_map_keys(callbacks, status_counts),
      "must equal schema_validation_status_counts keys with positive counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "schema_validation_import_blocked",
      schema_validation_summary_blocked?(summary),
      "must match failed or errored schema-validation evidence"
    )
  end

  defp validate_id_sets(issues, callbacks, path, summary) do
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    issues
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
      "schema_validation_gate_ids",
      stable_id_array_map_ids(callbacks, Map.get(summary, "quality_gate_ids_by_status")),
      "must equal quality-gate IDs by status"
    )
    |> validate_failed_row_ids(callbacks, path, summary)
  end

  defp validate_failed_row_ids(issues, callbacks, path, summary) do
    failed_ids = Map.get(summary, "failed_schema_validation_quality_gate_row_ids")

    row_ids =
      stable_id_array_map_ids(callbacks, Map.get(summary, "quality_gate_row_ids_by_status"))

    cond do
      not is_list(failed_ids) or not is_list(row_ids) ->
        issues

      not subset?(failed_ids, row_ids) ->
        [
          error(
            callbacks,
            path <> ".failed_schema_validation_quality_gate_row_ids",
            "must be present in quality-gate row IDs by status"
          )
          | issues
        ]

      schema_validation_summary_blocked?(summary) and failed_ids == [] ->
        [
          error(
            callbacks,
            path <> ".failed_schema_validation_quality_gate_row_ids",
            "must include failed schema-validation row IDs when schema validation blocks import"
          )
          | issues
        ]

      true ->
        issues
    end
  end

  defp schema_validation_summary_blocked?(summary) when is_map(summary) do
    case {
      Map.get(summary, "schema_validation_fail_count"),
      Map.get(summary, "schema_validation_error_count")
    } do
      {fail_count, error_count} when is_integer(fail_count) and is_integer(error_count) ->
        fail_count > 0 or error_count > 0

      _counts ->
        nil
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

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message) do
    apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      artifact,
      expected,
      message
    ])
  end

  defp quality_gate_schema_validation_summary_model_limits(callbacks) do
    apply(Keyword.fetch!(callbacks, :quality_gate_schema_validation_summary_model_limits), [])
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
