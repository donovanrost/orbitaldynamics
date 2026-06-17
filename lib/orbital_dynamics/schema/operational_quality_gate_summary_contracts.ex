defmodule OrbitalDynamics.Schema.OperationalQualityGateSummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    rows = Map.get(summary, "rows", [])
    non_passed_rows = Map.get(summary, "non_passed_rows", [])
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "operational_quality_gate_summary.v1"
    )
    |> expect_equal(callbacks, path, summary, "model", "artifact_only_quality_gate_summary")
    |> expect_equal(callbacks, path, summary, "source", "quality_gate_report.v1")
    |> expect_type(callbacks, path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(callbacks, path, summary, [
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id"
    ])
    |> expect_one_of(callbacks, path, summary, "readiness_level", capability.readiness_levels)
    |> expect_one_of(
      callbacks,
      path,
      summary,
      "import_classification",
      capability.import_classifications
    )
    |> expect_one_of(callbacks, path, summary, "status", capability.gate_statuses)
    |> expect_equal(callbacks, path, summary, "handoff_only", true)
    |> expect_equal(callbacks, path, summary, "execution_allowed", false)
    |> expect_equal(callbacks, path, summary, "cadence_write_allowed", false)
    |> expect_equal(callbacks, path, summary, "operator_authority_granted", false)
    |> expect_one_of(callbacks, path, summary, "execution_boundary", [
      "adapter_handoff_only",
      "operator_review_required_before_import",
      "analysis_only_not_for_execution",
      "blocked_not_for_import_or_execution"
    ])
    |> expect_non_negative_integer(callbacks, path, summary, "gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "passed_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "review_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "analysis_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "blocked_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "non_passed_gate_count")
    |> expect_type(callbacks, path, summary, "gate_status_counts", :map)
    |> expect_type(callbacks, path, summary, "gate_classification_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".gate_status_counts",
      Map.get(summary, "gate_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".gate_classification_counts",
      Map.get(summary, "gate_classification_counts")
    )
    |> expect_type(callbacks, path, summary, "gate_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".gate_ids_by_status",
      Map.get(summary, "gate_ids_by_status")
    )
    |> expect_type(callbacks, path, summary, "gate_ids_by_classification", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".gate_ids_by_classification",
      Map.get(summary, "gate_ids_by_classification")
    )
    |> expect_type(callbacks, path, summary, "quality_gate_row_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_row_ids_by_status",
      Map.get(summary, "quality_gate_row_ids_by_status")
    )
    |> expect_type(callbacks, path, summary, "quality_gate_row_ids_by_classification", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_row_ids_by_classification",
      Map.get(summary, "quality_gate_row_ids_by_classification")
    )
    |> expect_type(callbacks, path, summary, "passed_gate_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".passed_gate_ids",
      Map.get(summary, "passed_gate_ids")
    )
    |> expect_type(callbacks, path, summary, "review_required_gate_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".review_required_gate_ids",
      Map.get(summary, "review_required_gate_ids")
    )
    |> expect_type(callbacks, path, summary, "analysis_only_gate_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".analysis_only_gate_ids",
      Map.get(summary, "analysis_only_gate_ids")
    )
    |> expect_type(callbacks, path, summary, "blocked_gate_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".blocked_gate_ids",
      Map.get(summary, "blocked_gate_ids")
    )
    |> expect_type(callbacks, path, summary, "non_passed_gate_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".non_passed_gate_ids",
      Map.get(summary, "non_passed_gate_ids")
    )
    |> expect_type(callbacks, path, summary, "non_passed_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".non_passed_quality_gate_row_ids",
      Map.get(summary, "non_passed_quality_gate_row_ids")
    )
    |> expect_type(callbacks, path, summary, "non_passed_rows", :list)
    |> validate_rows(callbacks, path <> ".non_passed_rows", non_passed_rows, fn acc,
                                                                                row_path,
                                                                                row ->
      validate_quality_gate_row(acc, callbacks, row_path, row)
    end)
    |> expect_type(callbacks, path, summary, "rows", :list)
    |> validate_rows(callbacks, path <> ".rows", rows, fn acc, row_path, row ->
      validate_quality_gate_row(acc, callbacks, row_path, row)
    end)
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      quality_gate_summary_model_limits(callbacks),
      "must match quality gate summary model limits"
    )
    |> validate_assumptions(callbacks, path, summary)
    |> validate_classification(callbacks, path, summary, rows)
    |> validate_counts(callbacks, path, summary, rows)
    |> validate_id_sets(callbacks, path, summary, rows)
  end

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        [
          {"source", "quality_gate_report.v1"},
          {"execution_boundary", "artifact_only_no_cadence_write"},
          {"operator_authority", "not_granted_by_quality_gate_summary"},
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

  defp validate_classification(issues, callbacks, path, summary, rows) when is_list(rows) do
    import_classification = operational_readiness_import_classification(callbacks, rows)

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_classification",
      import_classification,
      "must match row-derived import classification"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "readiness_level",
      operational_readiness_level(callbacks, import_classification),
      "must match row-derived readiness level"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "status",
      operational_readiness_report_status(callbacks, import_classification),
      "must match row-derived report status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "execution_boundary",
      quality_gate_execution_boundary(callbacks, import_classification),
      "must match row-derived execution boundary"
    )
  end

  defp validate_classification(issues, _callbacks, _path, _summary, _rows), do: issues

  defp validate_counts(issues, callbacks, path, summary, rows) when is_list(rows) do
    issues
    |> expect_field_equals(callbacks, path, summary, "gate_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "passed_gate_count",
      quality_gate_status_count(callbacks, rows, "passed")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_gate_count",
      quality_gate_status_count(callbacks, rows, "review_required")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "analysis_gate_count",
      quality_gate_status_count(callbacks, rows, "analysis_only")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_gate_count",
      quality_gate_status_count(callbacks, rows, "blocked")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "non_passed_gate_count",
      Enum.count(rows, &(is_map(&1) and Map.get(&1, "status") != "passed"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "gate_status_counts",
      frequency_map(rows, "status"),
      "must match gate status counts from rows"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "gate_classification_counts",
      frequency_map(rows, "classification"),
      "must match gate classification counts from rows"
    )
  end

  defp validate_counts(issues, _callbacks, _path, _summary, _rows), do: issues

  defp validate_id_sets(issues, callbacks, path, summary, rows) when is_list(rows) do
    non_passed_rows = Enum.reject(rows, &(is_map(&1) and Map.get(&1, "status") == "passed"))

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "gate_ids_by_status",
      quality_gate_ids_by(callbacks, rows, "status"),
      "must match gate IDs grouped by row status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "gate_ids_by_classification",
      quality_gate_ids_by(callbacks, rows, "classification"),
      "must match gate IDs grouped by row classification"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "quality_gate_row_ids_by_status",
      quality_gate_row_ids_by(callbacks, rows, "status"),
      "must match quality-gate row IDs grouped by row status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "quality_gate_row_ids_by_classification",
      quality_gate_row_ids_by(callbacks, rows, "classification"),
      "must match quality-gate row IDs grouped by row classification"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "passed_gate_ids",
      quality_gate_ids(callbacks, rows, "passed")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_required_gate_ids",
      quality_gate_ids(callbacks, rows, "review_required")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "analysis_only_gate_ids",
      quality_gate_ids(callbacks, rows, "analysis_only")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_gate_ids",
      quality_gate_ids(callbacks, rows, "blocked")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "non_passed_gate_ids",
      non_passed_rows |> Enum.map(&Map.get(&1, "gate_id")) |> stable_sorted_ids(callbacks),
      "must match non-passed gate IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "non_passed_quality_gate_row_ids",
      non_passed_rows |> Enum.map(&Map.get(&1, "id")) |> stable_sorted_ids(callbacks),
      "must match non-passed quality-gate row IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "non_passed_rows",
      non_passed_rows,
      "must match non-passed quality-gate rows"
    )
  end

  defp validate_id_sets(issues, _callbacks, _path, _summary, _rows), do: issues

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_field_equals(issues, callbacks, path, map, field, expected) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals), [
      issues,
      path,
      map,
      field,
      expected
    ])
  end

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

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message) do
    apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      artifact,
      expected,
      message
    ])
  end

  defp validate_quality_gate_row(issues, callbacks, path, row),
    do: apply(Keyword.fetch!(callbacks, :validate_quality_gate_row), [issues, path, row])

  defp quality_gate_summary_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :quality_gate_summary_model_limits), [])

  defp operational_readiness_import_classification(callbacks, rows),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_import_classification), [rows])

  defp operational_readiness_level(callbacks, classification),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_level), [classification])

  defp operational_readiness_report_status(callbacks, classification),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_report_status), [classification])

  defp quality_gate_execution_boundary(callbacks, classification),
    do: apply(Keyword.fetch!(callbacks, :quality_gate_execution_boundary), [classification])

  defp quality_gate_status_count(callbacks, rows, status),
    do: apply(Keyword.fetch!(callbacks, :quality_gate_status_count), [rows, status])

  defp quality_gate_ids_by(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :quality_gate_ids_by), [rows, field])

  defp quality_gate_row_ids_by(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :quality_gate_row_ids_by), [rows, field])

  defp quality_gate_ids(callbacks, rows, status),
    do: apply(Keyword.fetch!(callbacks, :quality_gate_ids), [rows, status])

  defp stable_sorted_ids(ids, callbacks),
    do: apply(Keyword.fetch!(callbacks, :stable_sorted_ids), [ids])
end
