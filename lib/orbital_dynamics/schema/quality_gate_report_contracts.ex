defmodule OrbitalDynamics.Schema.QualityGateReportContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.OperationalReadinessClassificationContracts,
    as: ReadinessClassification

  alias OrbitalDynamics.Schema.QualityGateRowContracts, as: QualityGateRow
  alias OrbitalDynamics.OperationalReadiness.SourceIdentity

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
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

  def validate_report(issues, path, report, model_limits, row_validator)
      when is_list(model_limits) and is_function(row_validator, 3) do
    rows = Map.get(report, "rows", [])
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(path, report, "schema_contract", "quality_gate_report.v1")
    |> expect_equal(
      path,
      report,
      "model",
      "artifact_only_operational_quality_gate_report"
    )
    |> validate_stable_ids(path, report, [
      "report_id",
      "source_artifact_id",
      "source_readiness_report_id"
    ])
    |> validate_report_identity(path, report)
    |> expect_one_of(path, report, "readiness_level", capability.readiness_levels)
    |> expect_one_of(
      path,
      report,
      "import_classification",
      capability.import_classifications
    )
    |> expect_one_of(path, report, "status", capability.gate_statuses)
    |> expect_equal(path, report, "handoff_only", true)
    |> expect_equal(path, report, "execution_allowed", false)
    |> expect_equal(path, report, "cadence_write_allowed", false)
    |> expect_equal(path, report, "operator_authority_granted", false)
    |> expect_non_negative_integer(path, report, "gate_count")
    |> expect_non_negative_integer(path, report, "passed_gate_count")
    |> expect_non_negative_integer(path, report, "review_gate_count")
    |> expect_non_negative_integer(path, report, "analysis_gate_count")
    |> expect_non_negative_integer(path, report, "blocked_gate_count")
    |> expect_type(path, report, "gate_status_counts", :map)
    |> expect_type(path, report, "gate_classification_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".gate_status_counts",
      Map.get(report, "gate_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".gate_classification_counts",
      Map.get(report, "gate_classification_counts")
    )
    |> validate_aggregate_maps(path, report, rows)
    |> validate_id_sets(path, report, rows)
    |> expect_type(path, report, "rows", :list)
    |> validate_rows(path <> ".rows", rows, fn acc, row_path, row ->
      row_validator.(acc, row_path, row)
    end)
    |> validate_row_identities(path, report, rows)
    |> expect_type(path, report, "assumptions", :map)
    |> expect_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      model_limits,
      "must match quality gate report model limits"
    )
    |> validate_assumptions(path, report)
    |> validate_classification(path, report, rows)
    |> validate_counts(path, report, rows)
  end

  defp validate_report_identity(issues, path, report) do
    case {report["source_artifact_type"], report["source_artifact_id"]} do
      {source_artifact_type, source_artifact_id}
      when is_binary(source_artifact_type) and source_artifact_type != "" and
             is_binary(source_artifact_id) and source_artifact_id != "" ->
        issues
        |> expect_field_equals(
          path,
          report,
          "report_id",
          SourceIdentity.quality_gate_report_id(source_artifact_type, source_artifact_id),
          "must match source artifact identity"
        )
        |> expect_field_equals(
          path,
          report,
          "source_readiness_report_id",
          SourceIdentity.readiness_report_id(source_artifact_type, source_artifact_id),
          "must match source artifact identity"
        )

      _source_identity ->
        issues
    end
  end

  defp validate_row_identities(issues, path, report, rows) when is_list(rows) do
    source_artifact_type = report["source_artifact_type"]
    source_artifact_id = report["source_artifact_id"]

    if is_binary(source_artifact_type) and source_artifact_type != "" and
         is_binary(source_artifact_id) and source_artifact_id != "" do
      rows
      |> Enum.with_index()
      |> Enum.reduce(issues, fn
        {%{"gate_id" => gate_id, "rank" => rank} = row, index}, acc
        when is_binary(gate_id) and gate_id != "" and is_integer(rank) and rank >= 0 ->
          expect_field_equals(
            acc,
            "#{path}.rows[#{index}]",
            row,
            "id",
            SourceIdentity.quality_gate_row_id(
              source_artifact_type,
              source_artifact_id,
              gate_id,
              rank
            ),
            "must match source artifact, gate, and rank identity"
          )

        {_row, _index}, acc ->
          acc
      end)
    else
      issues
    end
  end

  defp validate_row_identities(issues, _path, _report, _rows), do: issues

  defp validate_aggregate_maps(issues, path, report, rows) do
    issues
    |> expect_field_equals(
      path,
      report,
      "gate_status_counts",
      if(is_list(rows), do: frequency_map(rows, "status")),
      "must match gate status counts from rows"
    )
    |> expect_field_equals(
      path,
      report,
      "gate_classification_counts",
      if(is_list(rows), do: frequency_map(rows, "classification")),
      "must match gate classification counts from rows"
    )
  end

  defp validate_id_sets(issues, path, report, rows) do
    issues
    |> expect_optional_type(path, report, "gate_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".gate_ids_by_status",
      Map.get(report, "gate_ids_by_status")
    )
    |> expect_field_equals(
      path,
      report,
      "gate_ids_by_status",
      QualityGateRow.ids_by(rows, "status"),
      "must match gate IDs grouped by row status"
    )
    |> expect_optional_type(path, report, "gate_ids_by_classification", :map)
    |> validate_stable_id_array_map(
      path <> ".gate_ids_by_classification",
      Map.get(report, "gate_ids_by_classification")
    )
    |> expect_field_equals(
      path,
      report,
      "gate_ids_by_classification",
      QualityGateRow.ids_by(rows, "classification"),
      "must match gate IDs grouped by row classification"
    )
    |> expect_optional_type(path, report, "quality_gate_row_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".quality_gate_row_ids_by_status",
      Map.get(report, "quality_gate_row_ids_by_status")
    )
    |> expect_field_equals(
      path,
      report,
      "quality_gate_row_ids_by_status",
      QualityGateRow.row_ids_by(rows, "status"),
      "must match quality-gate row IDs grouped by row status"
    )
    |> expect_optional_type(
      path,
      report,
      "quality_gate_row_ids_by_classification",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".quality_gate_row_ids_by_classification",
      Map.get(report, "quality_gate_row_ids_by_classification")
    )
    |> expect_field_equals(
      path,
      report,
      "quality_gate_row_ids_by_classification",
      QualityGateRow.row_ids_by(rows, "classification"),
      "must match quality-gate row IDs grouped by row classification"
    )
    |> validate_status_id_sets(path, report, rows)
  end

  defp validate_status_id_sets(issues, path, report, rows) do
    [
      {"passed_gate_ids", "passed"},
      {"review_required_gate_ids", "review_required"},
      {"analysis_only_gate_ids", "analysis_only"},
      {"blocked_gate_ids", "blocked"}
    ]
    |> Enum.reduce(issues, fn {field, status}, acc ->
      acc
      |> expect_optional_type(path, report, field, :list)
      |> validate_optional_stable_id_list(path, report, field)
      |> expect_field_equals(
        path,
        report,
        field,
        QualityGateRow.ids(rows, status),
        "must match #{status_label(status)} gate IDs"
      )
    end)
  end

  defp validate_assumptions(issues, path, report) do
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
              error("#{path}.assumptions.#{field}", "must equal #{inspect(expected)}")
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

  defp validate_classification(issues, path, report, rows) when is_list(rows) do
    import_classification = ReadinessClassification.import_classification(rows)
    readiness_level = ReadinessClassification.readiness_level(import_classification)
    status = ReadinessClassification.report_status(import_classification)
    execution_boundary = quality_gate_execution_boundary(import_classification)

    issues
    |> expect_field_equals(
      path,
      report,
      "import_classification",
      import_classification,
      "must match row-derived import classification"
    )
    |> expect_field_equals(
      path,
      report,
      "readiness_level",
      readiness_level,
      "must match row-derived readiness level"
    )
    |> expect_field_equals(
      path,
      report,
      "status",
      status,
      "must match row-derived report status"
    )
    |> expect_field_equals(
      path,
      report,
      "execution_boundary",
      execution_boundary,
      "must match row-derived execution boundary"
    )
  end

  defp validate_classification(issues, _path, _report, _rows), do: issues

  defp validate_counts(issues, path, report, rows) when is_list(rows) do
    issues
    |> expect_field_equals(path, report, "gate_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "passed_gate_count",
      QualityGateRow.status_count(rows, "passed")
    )
    |> expect_field_equals(
      path,
      report,
      "review_gate_count",
      QualityGateRow.status_count(rows, "review_required")
    )
    |> expect_field_equals(
      path,
      report,
      "analysis_gate_count",
      QualityGateRow.status_count(rows, "analysis_only")
    )
    |> expect_field_equals(
      path,
      report,
      "blocked_gate_count",
      QualityGateRow.status_count(rows, "blocked")
    )
  end

  defp validate_counts(issues, _path, _report, _rows), do: issues

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp status_label("review_required"), do: "review-required"
  defp status_label("analysis_only"), do: "analysis-only"
  defp status_label(status), do: status

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp quality_gate_execution_boundary("importable"), do: "adapter_handoff_only"

  defp quality_gate_execution_boundary("review_only"),
    do: "operator_review_required_before_import"

  defp quality_gate_execution_boundary("analysis_only"), do: "analysis_only_not_for_execution"
  defp quality_gate_execution_boundary("blocked"), do: "blocked_not_for_import_or_execution"
end
