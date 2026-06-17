defmodule OrbitalDynamics.Schema.OperationalQualityGateOperatorTrainingSummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    requirement_counts = Map.get(summary, "operator_training_requirement_counts")
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    quality_gate_row_ids_by_classification =
      Map.get(summary, "quality_gate_row_ids_by_classification")

    quality_gate_ids_by_status = Map.get(summary, "quality_gate_ids_by_status")

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "operational_quality_gate_operator_training_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_quality_gate_operator_training_summary"
    )
    |> expect_equal(callbacks, path, summary, "source", "quality_gate_report.v1")
    |> expect_type(callbacks, path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(callbacks, path, summary, [
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id"
    ])
    |> expect_non_negative_integer(callbacks, path, summary, "operator_training_row_count")
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "operator_training_requirement_count"
    )
    |> expect_type(callbacks, path, summary, "operator_training_requirement_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".operator_training_requirement_counts",
      requirement_counts
    )
    |> expect_type(callbacks, path, summary, "operator_training_requirement_ids", :list)
    |> validate_string_list_items(callbacks, path, summary, "operator_training_requirement_ids")
    |> expect_type(callbacks, path, summary, "required_operator_roles", :list)
    |> validate_string_list_items(callbacks, path, summary, "required_operator_roles")
    |> expect_type(callbacks, path, summary, "required_training_ids", :list)
    |> validate_string_list_items(callbacks, path, summary, "required_training_ids")
    |> expect_type(callbacks, path, summary, "required_certification_ids", :list)
    |> validate_string_list_items(callbacks, path, summary, "required_certification_ids")
    |> expect_type(callbacks, path, summary, "required_qualification_ids", :list)
    |> validate_string_list_items(callbacks, path, summary, "required_qualification_ids")
    |> expect_type(callbacks, path, summary, "quality_gate_row_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_row_ids_by_status",
      quality_gate_row_ids_by_status
    )
    |> expect_type(callbacks, path, summary, "quality_gate_row_ids_by_classification", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_row_ids_by_classification",
      quality_gate_row_ids_by_classification
    )
    |> expect_type(callbacks, path, summary, "quality_gate_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_ids_by_status",
      quality_gate_ids_by_status
    )
    |> expect_type(callbacks, path, summary, "quality_gate_ids_by_classification", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_ids_by_classification",
      Map.get(summary, "quality_gate_ids_by_classification")
    )
    |> expect_type(callbacks, path, summary, "review_required_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".review_required_quality_gate_row_ids",
      Map.get(summary, "review_required_quality_gate_row_ids")
    )
    |> expect_type(callbacks, path, summary, "blocked_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".blocked_quality_gate_row_ids",
      Map.get(summary, "blocked_quality_gate_row_ids")
    )
    |> expect_type(callbacks, path, summary, "review_only_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".review_only_quality_gate_row_ids",
      Map.get(summary, "review_only_quality_gate_row_ids")
    )
    |> expect_type(callbacks, path, summary, "operator_training_gate_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".operator_training_gate_ids",
      Map.get(summary, "operator_training_gate_ids")
    )
    |> expect_type(callbacks, path, summary, "operator_training_review_required", :boolean)
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      quality_gate_operator_training_summary_model_limits(callbacks),
      "must match quality gate operator-training summary model limits"
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
          {"operator_authority", "not_granted_by_operator_training_summary"},
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
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "operator_training_row_count",
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
      "operator_training_requirement_count",
      non_negative_integer_map_sum(
        callbacks,
        Map.get(summary, "operator_training_requirement_counts")
      ),
      "must equal operator_training_requirement_counts sum"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "operator_training_requirement_ids",
      positive_count_map_keys(
        callbacks,
        Map.get(summary, "operator_training_requirement_counts")
      ),
      "must equal operator_training_requirement_counts keys with positive counts"
    )
  end

  defp validate_id_sets(issues, callbacks, path, summary) do
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    quality_gate_row_ids_by_classification =
      Map.get(summary, "quality_gate_row_ids_by_classification")

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
      "review_only_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_classification),
        do: Map.get(quality_gate_row_ids_by_classification, "review_only", [])
      ),
      "must equal review-only quality-gate row IDs by classification"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "operator_training_gate_ids",
      stable_id_array_map_ids(callbacks, Map.get(summary, "quality_gate_ids_by_status")),
      "must equal quality-gate IDs by status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "operator_training_review_required",
      not Enum.empty?(
        list_or_empty(callbacks, Map.get(summary, "review_required_quality_gate_row_ids"))
      ),
      "must match review-required quality-gate row IDs"
    )
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

  defp quality_gate_operator_training_summary_model_limits(callbacks) do
    apply(Keyword.fetch!(callbacks, :quality_gate_operator_training_summary_model_limits), [])
  end

  defp stable_id_array_map_value_count(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :stable_id_array_map_value_count), [values])

  defp stable_id_array_map_ids(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :stable_id_array_map_ids), [values])

  defp non_negative_integer_map_sum(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :non_negative_integer_map_sum), [values])

  defp positive_count_map_keys(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :positive_count_map_keys), [values])

  defp list_or_empty(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :list_or_empty), [values])
end
