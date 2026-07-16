defmodule OrbitalDynamics.Schema.OperationalReadinessGateSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.OperationalReadinessClassificationContracts,
    as: ReadinessClassification

  alias OrbitalDynamics.Schema.OperationalReadinessReportContracts,
    as: ReadinessReport

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
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
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  def validate_summary(issues, path, summary, model_limits, gate_validator)
      when is_list(model_limits) and is_function(gate_validator, 3) do
    gates = Map.get(summary, "gates", [])
    non_passed_gates = Map.get(summary, "non_passed_gates", [])
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "operational_readiness_gate_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_operational_readiness_gate_summary"
    )
    |> expect_equal(path, summary, "source", "operational_readiness_report.v1")
    |> expect_type(path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(path, summary, ["source_artifact_id"])
    |> expect_one_of(path, summary, "readiness_level", capability.readiness_levels)
    |> expect_one_of(
      path,
      summary,
      "import_classification",
      capability.import_classifications
    )
    |> expect_one_of(path, summary, "status", capability.gate_statuses)
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
    |> expect_type(path, summary, "non_passed_gates", :list)
    |> validate_rows(
      path <> ".non_passed_gates",
      non_passed_gates,
      fn acc, row_path, gate ->
        gate_validator.(acc, row_path, gate)
      end
    )
    |> expect_type(path, summary, "gates", :list)
    |> validate_rows(path <> ".gates", gates, fn acc, row_path, gate ->
      gate_validator.(acc, row_path, gate)
    end)
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_optional_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match operational readiness gate summary model limits"
    )
    |> validate_assumptions(path, summary)
    |> validate_classification(path, summary, gates)
    |> validate_counts(path, summary, gates)
    |> validate_id_sets(path, summary, gates)
  end

  defp validate_assumptions(issues, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        [
          {"execution_boundary", "artifact_only_no_cadence_write"},
          {"source", "operational_readiness_report.v1"},
          {"operator_authority", "not_granted_by_summary"}
        ]
        |> Enum.reduce(issues, fn {field, expected}, acc ->
          expect_equal(acc, path <> ".assumptions", assumptions, field, expected)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_classification(issues, path, summary, gates) when is_list(gates) do
    import_classification = ReadinessClassification.import_classification(gates)

    issues
    |> expect_field_equals(
      path,
      summary,
      "import_classification",
      import_classification,
      "must match gate-derived import classification"
    )
    |> expect_field_equals(
      path,
      summary,
      "readiness_level",
      ReadinessClassification.readiness_level(import_classification),
      "must match gate-derived readiness level"
    )
    |> expect_field_equals(
      path,
      summary,
      "status",
      ReadinessClassification.report_status(import_classification),
      "must match gate-derived report status"
    )
  end

  defp validate_classification(issues, _path, _summary, _gates), do: issues

  defp validate_counts(issues, path, summary, gates) when is_list(gates) do
    issues
    |> expect_field_equals(path, summary, "gate_count", length(gates))
    |> expect_field_equals(
      path,
      summary,
      "passed_gate_count",
      ReadinessReport.gate_status_count(gates, "passed")
    )
    |> expect_field_equals(
      path,
      summary,
      "review_gate_count",
      ReadinessReport.gate_status_count(gates, "review_required")
    )
    |> expect_field_equals(
      path,
      summary,
      "analysis_gate_count",
      ReadinessReport.gate_status_count(gates, "analysis_only")
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_gate_count",
      ReadinessReport.gate_status_count(gates, "blocked")
    )
    |> expect_field_equals(
      path,
      summary,
      "non_passed_gate_count",
      Enum.count(gates, &(is_map(&1) and Map.get(&1, "status") != "passed"))
    )
    |> expect_field_equals(
      path,
      summary,
      "gate_status_counts",
      frequency_map(gates, "status"),
      "must match gate status counts from rows"
    )
    |> expect_field_equals(
      path,
      summary,
      "gate_classification_counts",
      frequency_map(gates, "classification"),
      "must match gate classification counts from rows"
    )
  end

  defp validate_counts(issues, _path, _summary, _gates), do: issues

  defp validate_id_sets(issues, path, summary, gates) when is_list(gates) do
    issues
    |> expect_field_equals(
      path,
      summary,
      "gate_ids_by_status",
      operational_readiness_gate_ids_by(gates, "status"),
      "must match gate IDs grouped by status"
    )
    |> expect_field_equals(
      path,
      summary,
      "gate_ids_by_classification",
      operational_readiness_gate_ids_by(gates, "classification"),
      "must match gate IDs grouped by classification"
    )
    |> expect_field_equals(
      path,
      summary,
      "passed_gate_ids",
      operational_readiness_gate_ids(gates, "passed"),
      "must match passed gate IDs"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_required_gate_ids",
      operational_readiness_gate_ids(gates, "review_required"),
      "must match review-required gate IDs"
    )
    |> expect_field_equals(
      path,
      summary,
      "analysis_only_gate_ids",
      operational_readiness_gate_ids(gates, "analysis_only"),
      "must match analysis-only gate IDs"
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_gate_ids",
      operational_readiness_gate_ids(gates, "blocked"),
      "must match blocked gate IDs"
    )
    |> expect_field_equals(
      path,
      summary,
      "non_passed_gate_ids",
      operational_readiness_non_passed_gate_ids(gates),
      "must match non-passed gate IDs"
    )
    |> expect_field_equals(
      path,
      summary,
      "non_passed_gates",
      Enum.reject(gates, &(is_map(&1) and Map.get(&1, "status") == "passed")),
      "must match non-passed gate rows"
    )
  end

  defp validate_id_sets(issues, _path, _summary, _gates), do: issues

  defp operational_readiness_gate_ids_by(gates, field) when is_list(gates) do
    gates
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "id"))
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} ->
      ids =
        ids
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      {key, ids}
    end)
  end

  defp operational_readiness_gate_ids(gates, status) when is_list(gates) do
    gates
    |> Enum.filter(&(is_map(&1) and Map.get(&1, "status") == status))
    |> Enum.map(&Map.get(&1, "id"))
  end

  defp operational_readiness_non_passed_gate_ids(gates) when is_list(gates) do
    gates
    |> Enum.reject(&(is_map(&1) and Map.get(&1, "status") == "passed"))
    |> Enum.map(&Map.get(&1, "id"))
  end

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
end
