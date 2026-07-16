defmodule OrbitalDynamics.Schema.OperationalQualityGateSchemaValidationSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CollectionAggregation

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  def validate_summary(issues, path, summary, model_limits) when is_list(model_limits) do
    status_counts = Map.get(summary, "schema_validation_status_counts")
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")
    quality_gate_ids_by_status = Map.get(summary, "quality_gate_ids_by_status")

    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "operational_quality_gate_schema_validation_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_quality_gate_schema_validation_summary"
    )
    |> expect_equal(path, summary, "source", "quality_gate_report.v1")
    |> expect_type(path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(path, summary, [
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id"
    ])
    |> expect_non_negative_integer(path, summary, "schema_validation_row_count")
    |> expect_non_negative_integer(path, summary, "schema_validation_pass_count")
    |> expect_non_negative_integer(path, summary, "schema_validation_fail_count")
    |> expect_non_negative_integer(path, summary, "schema_validation_error_count")
    |> expect_non_negative_integer(path, summary, "schema_validation_warning_count")
    |> expect_non_negative_integer(
      path,
      summary,
      "schema_validation_remediation_count"
    )
    |> expect_type(path, summary, "schema_validation_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".schema_validation_status_counts",
      status_counts
    )
    |> expect_type(path, summary, "schema_validation_status_ids", :list)
    |> validate_string_list_items(path, summary, "schema_validation_status_ids")
    |> expect_type(path, summary, "schema_validation_import_blocked", :boolean)
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
    |> expect_type(path, summary, "blocked_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      path <> ".blocked_quality_gate_row_ids",
      Map.get(summary, "blocked_quality_gate_row_ids")
    )
    |> expect_type(path, summary, "review_required_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      path <> ".review_required_quality_gate_row_ids",
      Map.get(summary, "review_required_quality_gate_row_ids")
    )
    |> expect_type(
      path,
      summary,
      "failed_schema_validation_quality_gate_row_ids",
      :list
    )
    |> validate_stable_id_list(
      path <> ".failed_schema_validation_quality_gate_row_ids",
      Map.get(summary, "failed_schema_validation_quality_gate_row_ids")
    )
    |> expect_type(path, summary, "schema_validation_gate_ids", :list)
    |> validate_stable_id_list(
      path <> ".schema_validation_gate_ids",
      Map.get(summary, "schema_validation_gate_ids")
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match quality gate schema-validation summary model limits"
    )
    |> validate_assumptions(path, summary)
    |> validate_counts(path, summary)
    |> validate_id_sets(path, summary)
  end

  defp validate_assumptions(issues, path, summary) do
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
          expect_equal(acc, path <> ".assumptions", assumptions, field, expected)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, path, summary) do
    status_counts = Map.get(summary, "schema_validation_status_counts")

    issues
    |> expect_field_equals(
      path,
      summary,
      "schema_validation_row_count",
      CollectionAggregation.stable_id_array_map_value_count(
        Map.get(summary, "quality_gate_row_ids_by_status")
      ),
      "must equal quality-gate row IDs by status count"
    )
    |> expect_field_equals(
      path,
      summary,
      "schema_validation_pass_count",
      CollectionAggregation.non_negative_integer_map_value(status_counts, "pass"),
      "must equal schema_validation_status_counts pass count"
    )
    |> expect_field_equals(
      path,
      summary,
      "schema_validation_fail_count",
      CollectionAggregation.non_negative_integer_map_value(status_counts, "fail"),
      "must equal schema_validation_status_counts fail count"
    )
    |> expect_field_equals(
      path,
      summary,
      "schema_validation_status_ids",
      CollectionAggregation.positive_count_map_keys(status_counts),
      "must equal schema_validation_status_counts keys with positive counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "schema_validation_import_blocked",
      schema_validation_summary_blocked?(summary),
      "must match failed or errored schema-validation evidence"
    )
  end

  defp validate_id_sets(issues, path, summary) do
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    issues
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
      "review_required_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "review_required", [])
      ),
      "must equal review-required quality-gate row IDs by status"
    )
    |> expect_field_equals(
      path,
      summary,
      "schema_validation_gate_ids",
      CollectionAggregation.stable_id_array_map_ids(
        Map.get(summary, "quality_gate_ids_by_status")
      ),
      "must equal quality-gate IDs by status"
    )
    |> validate_failed_row_ids(path, summary)
  end

  defp validate_failed_row_ids(issues, path, summary) do
    failed_ids = Map.get(summary, "failed_schema_validation_quality_gate_row_ids")

    row_ids =
      CollectionAggregation.stable_id_array_map_ids(
        Map.get(summary, "quality_gate_row_ids_by_status")
      )

    cond do
      not is_list(failed_ids) or not is_list(row_ids) ->
        issues

      not subset?(failed_ids, row_ids) ->
        [
          error(
            path <> ".failed_schema_validation_quality_gate_row_ids",
            "must be present in quality-gate row IDs by status"
          )
          | issues
        ]

      schema_validation_summary_blocked?(summary) and failed_ids == [] ->
        [
          error(
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
end
