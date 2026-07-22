defmodule OrbitalDynamics.Schema.OperationalQualityGateSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.OperationalReadinessClassificationContracts,
    as: ReadinessClassification

  alias OrbitalDynamics.Schema.OperationalQualityGateSummaryLineageValidation,
    as: SummaryLineage

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
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

  def validate_summary(issues, path, summary, model_limits, row_validator)
      when is_list(model_limits) and is_function(row_validator, 3) do
    rows = Map.get(summary, "rows", [])
    non_passed_rows = Map.get(summary, "non_passed_rows", [])
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "operational_quality_gate_summary.v1"
    )
    |> expect_equal(path, summary, "model", "artifact_only_quality_gate_summary")
    |> expect_equal(path, summary, "source", "quality_gate_report.v1")
    |> expect_type(path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(path, summary, [
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id"
    ])
    |> SummaryLineage.validate(path, summary)
    |> expect_one_of(path, summary, "readiness_level", capability.readiness_levels)
    |> expect_one_of(
      path,
      summary,
      "import_classification",
      capability.import_classifications
    )
    |> expect_one_of(path, summary, "status", capability.gate_statuses)
    |> expect_equal(path, summary, "handoff_only", true)
    |> expect_equal(path, summary, "execution_allowed", false)
    |> expect_equal(path, summary, "cadence_write_allowed", false)
    |> expect_equal(path, summary, "operator_authority_granted", false)
    |> expect_one_of(path, summary, "execution_boundary", [
      "adapter_handoff_only",
      "operator_review_required_before_import",
      "analysis_only_not_for_execution",
      "blocked_not_for_import_or_execution"
    ])
    |> expect_non_negative_integer(path, summary, "gate_count")
    |> expect_non_negative_integer(path, summary, "passed_gate_count")
    |> expect_non_negative_integer(path, summary, "review_gate_count")
    |> expect_non_negative_integer(path, summary, "analysis_gate_count")
    |> expect_non_negative_integer(path, summary, "blocked_gate_count")
    |> expect_non_negative_integer(path, summary, "non_passed_gate_count")
    |> expect_type(path, summary, "gate_status_counts", :map)
    |> expect_type(path, summary, "gate_classification_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".gate_status_counts",
      Map.get(summary, "gate_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".gate_classification_counts",
      Map.get(summary, "gate_classification_counts")
    )
    |> expect_type(path, summary, "gate_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".gate_ids_by_status",
      Map.get(summary, "gate_ids_by_status")
    )
    |> expect_type(path, summary, "gate_ids_by_classification", :map)
    |> validate_stable_id_array_map(
      path <> ".gate_ids_by_classification",
      Map.get(summary, "gate_ids_by_classification")
    )
    |> expect_type(path, summary, "quality_gate_row_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".quality_gate_row_ids_by_status",
      Map.get(summary, "quality_gate_row_ids_by_status")
    )
    |> expect_type(path, summary, "quality_gate_row_ids_by_classification", :map)
    |> validate_stable_id_array_map(
      path <> ".quality_gate_row_ids_by_classification",
      Map.get(summary, "quality_gate_row_ids_by_classification")
    )
    |> expect_type(path, summary, "passed_gate_ids", :list)
    |> validate_stable_id_list(
      path <> ".passed_gate_ids",
      Map.get(summary, "passed_gate_ids")
    )
    |> expect_type(path, summary, "review_required_gate_ids", :list)
    |> validate_stable_id_list(
      path <> ".review_required_gate_ids",
      Map.get(summary, "review_required_gate_ids")
    )
    |> expect_type(path, summary, "analysis_only_gate_ids", :list)
    |> validate_stable_id_list(
      path <> ".analysis_only_gate_ids",
      Map.get(summary, "analysis_only_gate_ids")
    )
    |> expect_type(path, summary, "blocked_gate_ids", :list)
    |> validate_stable_id_list(
      path <> ".blocked_gate_ids",
      Map.get(summary, "blocked_gate_ids")
    )
    |> expect_type(path, summary, "non_passed_gate_ids", :list)
    |> validate_stable_id_list(
      path <> ".non_passed_gate_ids",
      Map.get(summary, "non_passed_gate_ids")
    )
    |> expect_type(path, summary, "non_passed_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      path <> ".non_passed_quality_gate_row_ids",
      Map.get(summary, "non_passed_quality_gate_row_ids")
    )
    |> expect_type(path, summary, "non_passed_rows", :list)
    |> validate_rows(path <> ".non_passed_rows", non_passed_rows, fn acc, row_path, row ->
      row_validator.(acc, row_path, row)
    end)
    |> expect_type(path, summary, "rows", :list)
    |> validate_rows(path <> ".rows", rows, fn acc, row_path, row ->
      row_validator.(acc, row_path, row)
    end)
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match quality gate summary model limits"
    )
    |> validate_assumptions(path, summary)
    |> validate_classification(path, summary, rows)
    |> validate_counts(path, summary, rows)
    |> validate_id_sets(path, summary, rows)
  end

  defp validate_assumptions(issues, path, summary) do
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
          expect_equal(acc, path <> ".assumptions", assumptions, field, expected)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_classification(issues, path, summary, rows) when is_list(rows) do
    import_classification = ReadinessClassification.import_classification(rows)

    issues
    |> expect_field_equals(
      path,
      summary,
      "import_classification",
      import_classification,
      "must match row-derived import classification"
    )
    |> expect_field_equals(
      path,
      summary,
      "readiness_level",
      ReadinessClassification.readiness_level(import_classification),
      "must match row-derived readiness level"
    )
    |> expect_field_equals(
      path,
      summary,
      "status",
      ReadinessClassification.report_status(import_classification),
      "must match row-derived report status"
    )
    |> expect_field_equals(
      path,
      summary,
      "execution_boundary",
      quality_gate_execution_boundary(import_classification),
      "must match row-derived execution boundary"
    )
  end

  defp validate_classification(issues, _path, _summary, _rows), do: issues

  defp validate_counts(issues, path, summary, rows) when is_list(rows) do
    issues
    |> expect_field_equals(path, summary, "gate_count", length(rows))
    |> expect_field_equals(
      path,
      summary,
      "passed_gate_count",
      quality_gate_status_count(rows, "passed")
    )
    |> expect_field_equals(
      path,
      summary,
      "review_gate_count",
      quality_gate_status_count(rows, "review_required")
    )
    |> expect_field_equals(
      path,
      summary,
      "analysis_gate_count",
      quality_gate_status_count(rows, "analysis_only")
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_gate_count",
      quality_gate_status_count(rows, "blocked")
    )
    |> expect_field_equals(
      path,
      summary,
      "non_passed_gate_count",
      Enum.count(rows, &(is_map(&1) and Map.get(&1, "status") != "passed"))
    )
    |> expect_field_equals(
      path,
      summary,
      "gate_status_counts",
      frequency_map(rows, "status"),
      "must match gate status counts from rows"
    )
    |> expect_field_equals(
      path,
      summary,
      "gate_classification_counts",
      frequency_map(rows, "classification"),
      "must match gate classification counts from rows"
    )
  end

  defp validate_counts(issues, _path, _summary, _rows), do: issues

  defp validate_id_sets(issues, path, summary, rows) when is_list(rows) do
    non_passed_rows = Enum.reject(rows, &(is_map(&1) and Map.get(&1, "status") == "passed"))

    issues
    |> expect_field_equals(
      path,
      summary,
      "gate_ids_by_status",
      quality_gate_ids_by(rows, "status"),
      "must match gate IDs grouped by row status"
    )
    |> expect_field_equals(
      path,
      summary,
      "gate_ids_by_classification",
      quality_gate_ids_by(rows, "classification"),
      "must match gate IDs grouped by row classification"
    )
    |> expect_field_equals(
      path,
      summary,
      "quality_gate_row_ids_by_status",
      quality_gate_row_ids_by(rows, "status"),
      "must match quality-gate row IDs grouped by row status"
    )
    |> expect_field_equals(
      path,
      summary,
      "quality_gate_row_ids_by_classification",
      quality_gate_row_ids_by(rows, "classification"),
      "must match quality-gate row IDs grouped by row classification"
    )
    |> expect_field_equals(
      path,
      summary,
      "passed_gate_ids",
      quality_gate_ids(rows, "passed")
    )
    |> expect_field_equals(
      path,
      summary,
      "review_required_gate_ids",
      quality_gate_ids(rows, "review_required")
    )
    |> expect_field_equals(
      path,
      summary,
      "analysis_only_gate_ids",
      quality_gate_ids(rows, "analysis_only")
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_gate_ids",
      quality_gate_ids(rows, "blocked")
    )
    |> expect_field_equals(
      path,
      summary,
      "non_passed_gate_ids",
      non_passed_rows |> Enum.map(&Map.get(&1, "gate_id")) |> stable_sorted_ids(),
      "must match non-passed gate IDs"
    )
    |> expect_field_equals(
      path,
      summary,
      "non_passed_quality_gate_row_ids",
      non_passed_rows |> Enum.map(&Map.get(&1, "id")) |> stable_sorted_ids(),
      "must match non-passed quality-gate row IDs"
    )
    |> expect_field_equals(
      path,
      summary,
      "non_passed_rows",
      non_passed_rows,
      "must match non-passed quality-gate rows"
    )
  end

  defp validate_id_sets(issues, _path, _summary, _rows), do: issues

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp quality_gate_execution_boundary("importable"), do: "adapter_handoff_only"

  defp quality_gate_execution_boundary("review_only"),
    do: "operator_review_required_before_import"

  defp quality_gate_execution_boundary("analysis_only"), do: "analysis_only_not_for_execution"
  defp quality_gate_execution_boundary("blocked"), do: "blocked_not_for_import_or_execution"

  defp quality_gate_status_count(rows, status) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  defp quality_gate_ids_by(rows, field) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "gate_id"))
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {to_string(key), stable_sorted_ids(ids)} end)
  end

  defp quality_gate_row_ids_by(rows, field) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "id"))
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {to_string(key), stable_sorted_ids(ids)} end)
  end

  defp quality_gate_ids(rows, status) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.filter(&(Map.get(&1, "status") == status))
    |> Enum.map(&Map.get(&1, "gate_id"))
    |> stable_sorted_ids()
  end

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
