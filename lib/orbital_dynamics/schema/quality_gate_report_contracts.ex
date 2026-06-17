defmodule OrbitalDynamics.Schema.QualityGateReportContracts do
  @moduledoc false

  def validate_report(issues, path, report, callbacks) when is_list(callbacks) do
    rows = Map.get(report, "rows", [])
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "quality_gate_report.v1")
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "artifact_only_operational_quality_gate_report"
    )
    |> validate_stable_ids(callbacks, path, report, [
      "report_id",
      "source_artifact_id",
      "source_readiness_report_id"
    ])
    |> expect_one_of(callbacks, path, report, "readiness_level", capability.readiness_levels)
    |> expect_one_of(
      callbacks,
      path,
      report,
      "import_classification",
      capability.import_classifications
    )
    |> expect_one_of(callbacks, path, report, "status", capability.gate_statuses)
    |> expect_equal(callbacks, path, report, "handoff_only", true)
    |> expect_equal(callbacks, path, report, "execution_allowed", false)
    |> expect_equal(callbacks, path, report, "cadence_write_allowed", false)
    |> expect_equal(callbacks, path, report, "operator_authority_granted", false)
    |> expect_non_negative_integer(callbacks, path, report, "gate_count")
    |> expect_non_negative_integer(callbacks, path, report, "passed_gate_count")
    |> expect_non_negative_integer(callbacks, path, report, "review_gate_count")
    |> expect_non_negative_integer(callbacks, path, report, "analysis_gate_count")
    |> expect_non_negative_integer(callbacks, path, report, "blocked_gate_count")
    |> expect_type(callbacks, path, report, "gate_status_counts", :map)
    |> expect_type(callbacks, path, report, "gate_classification_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".gate_status_counts",
      Map.get(report, "gate_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".gate_classification_counts",
      Map.get(report, "gate_classification_counts")
    )
    |> validate_aggregate_maps(callbacks, path, report, rows)
    |> validate_id_sets(callbacks, path, report, rows)
    |> expect_type(callbacks, path, report, "rows", :list)
    |> validate_rows(callbacks, path <> ".rows", rows, fn acc, row_path, row ->
      validate_quality_gate_row(acc, callbacks, row_path, row)
    end)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> expect_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      quality_gate_report_model_limits(callbacks),
      "must match quality gate report model limits"
    )
    |> validate_assumptions(callbacks, path, report)
    |> validate_classification(callbacks, path, report, rows)
    |> validate_counts(callbacks, path, report, rows)
  end

  defp validate_aggregate_maps(issues, callbacks, path, report, rows) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "gate_status_counts",
      if(is_list(rows), do: frequency_map(rows, "status")),
      "must match gate status counts from rows"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "gate_classification_counts",
      if(is_list(rows), do: frequency_map(rows, "classification")),
      "must match gate classification counts from rows"
    )
  end

  defp validate_id_sets(issues, callbacks, path, report, rows) do
    issues
    |> expect_optional_type(callbacks, path, report, "gate_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".gate_ids_by_status",
      Map.get(report, "gate_ids_by_status")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "gate_ids_by_status",
      quality_gate_ids_by(callbacks, rows, "status"),
      "must match gate IDs grouped by row status"
    )
    |> expect_optional_type(callbacks, path, report, "gate_ids_by_classification", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".gate_ids_by_classification",
      Map.get(report, "gate_ids_by_classification")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "gate_ids_by_classification",
      quality_gate_ids_by(callbacks, rows, "classification"),
      "must match gate IDs grouped by row classification"
    )
    |> expect_optional_type(callbacks, path, report, "quality_gate_row_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_row_ids_by_status",
      Map.get(report, "quality_gate_row_ids_by_status")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "quality_gate_row_ids_by_status",
      quality_gate_row_ids_by(callbacks, rows, "status"),
      "must match quality-gate row IDs grouped by row status"
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "quality_gate_row_ids_by_classification",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_row_ids_by_classification",
      Map.get(report, "quality_gate_row_ids_by_classification")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "quality_gate_row_ids_by_classification",
      quality_gate_row_ids_by(callbacks, rows, "classification"),
      "must match quality-gate row IDs grouped by row classification"
    )
    |> validate_status_id_sets(callbacks, path, report, rows)
  end

  defp validate_status_id_sets(issues, callbacks, path, report, rows) do
    [
      {"passed_gate_ids", "passed"},
      {"review_required_gate_ids", "review_required"},
      {"analysis_only_gate_ids", "analysis_only"},
      {"blocked_gate_ids", "blocked"}
    ]
    |> Enum.reduce(issues, fn {field, status}, acc ->
      acc
      |> expect_optional_type(callbacks, path, report, field, :list)
      |> validate_optional_stable_id_list(callbacks, path, report, field)
      |> expect_field_equals(
        callbacks,
        path,
        report,
        field,
        quality_gate_ids(callbacks, rows, status),
        "must match #{status_label(status)} gate IDs"
      )
    end)
  end

  defp validate_assumptions(issues, callbacks, path, report) do
    case Map.get(report, "assumptions") do
      %{} = assumptions ->
        [
          {"execution_boundary", "artifact_only_no_cadence_write"},
          {"operator_authority", "not_granted_by_quality_gate_report"},
          {"source", "operational_readiness_report.v1"}
        ]
        |> Enum.reduce(issues, fn {field, expected}, acc ->
          if Map.has_key?(assumptions, field) and Map.get(assumptions, field) != expected do
            [
              error(callbacks, "#{path}.assumptions.#{field}", "must equal #{inspect(expected)}")
              | acc
            ]
          else
            acc
          end
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_classification(issues, callbacks, path, report, rows) when is_list(rows) do
    import_classification = operational_readiness_import_classification(callbacks, rows)
    readiness_level = operational_readiness_level(callbacks, import_classification)
    status = operational_readiness_report_status(callbacks, import_classification)
    execution_boundary = quality_gate_execution_boundary(callbacks, import_classification)

    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "import_classification",
      import_classification,
      "must match row-derived import classification"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "readiness_level",
      readiness_level,
      "must match row-derived readiness level"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status",
      status,
      "must match row-derived report status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "execution_boundary",
      execution_boundary,
      "must match row-derived execution boundary"
    )
  end

  defp validate_classification(issues, _callbacks, _path, _report, _rows), do: issues

  defp validate_counts(issues, callbacks, path, report, rows) when is_list(rows) do
    issues
    |> expect_field_equals(callbacks, path, report, "gate_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "passed_gate_count",
      quality_gate_status_count(callbacks, rows, "passed")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_gate_count",
      quality_gate_status_count(callbacks, rows, "review_required")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "analysis_gate_count",
      quality_gate_status_count(callbacks, rows, "analysis_only")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "blocked_gate_count",
      quality_gate_status_count(callbacks, rows, "blocked")
    )
  end

  defp validate_counts(issues, _callbacks, _path, _report, _rows), do: issues

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp status_label("review_required"), do: "review-required"
  defp status_label("analysis_only"), do: "analysis-only"
  defp status_label(status), do: status

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

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

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
      issues,
      path,
      map,
      field
    ])
  end

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

  defp quality_gate_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :quality_gate_report_model_limits), [])

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

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
