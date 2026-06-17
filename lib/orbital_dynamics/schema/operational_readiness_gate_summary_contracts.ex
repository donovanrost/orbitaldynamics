defmodule OrbitalDynamics.Schema.OperationalReadinessGateSummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    gates = Map.get(summary, "gates", [])
    non_passed_gates = Map.get(summary, "non_passed_gates", [])
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "operational_readiness_gate_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_operational_readiness_gate_summary"
    )
    |> expect_equal(callbacks, path, summary, "source", "operational_readiness_report.v1")
    |> expect_type(callbacks, path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(callbacks, path, summary, ["source_artifact_id"])
    |> expect_one_of(callbacks, path, summary, "readiness_level", capability.readiness_levels)
    |> expect_one_of(
      callbacks,
      path,
      summary,
      "import_classification",
      capability.import_classifications
    )
    |> expect_one_of(callbacks, path, summary, "status", capability.gate_statuses)
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
    |> expect_type(callbacks, path, summary, "non_passed_gates", :list)
    |> validate_rows(
      callbacks,
      path <> ".non_passed_gates",
      non_passed_gates,
      fn acc, row_path, gate ->
        validate_operational_readiness_gate(acc, callbacks, row_path, gate)
      end
    )
    |> expect_type(callbacks, path, summary, "gates", :list)
    |> validate_rows(callbacks, path <> ".gates", gates, fn acc, row_path, gate ->
      validate_operational_readiness_gate(acc, callbacks, row_path, gate)
    end)
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> expect_optional_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      operational_readiness_gate_summary_model_limits(callbacks),
      "must match operational readiness gate summary model limits"
    )
    |> validate_assumptions(callbacks, path, summary)
    |> validate_classification(callbacks, path, summary, gates)
    |> validate_counts(callbacks, path, summary, gates)
    |> validate_id_sets(callbacks, path, summary, gates)
  end

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        [
          {"execution_boundary", "artifact_only_no_cadence_write"},
          {"source", "operational_readiness_report.v1"},
          {"operator_authority", "not_granted_by_summary"}
        ]
        |> Enum.reduce(issues, fn {field, expected}, acc ->
          expect_equal(acc, callbacks, path <> ".assumptions", assumptions, field, expected)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_classification(issues, callbacks, path, summary, gates) when is_list(gates) do
    import_classification = operational_readiness_import_classification(callbacks, gates)

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_classification",
      import_classification,
      "must match gate-derived import classification"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "readiness_level",
      operational_readiness_level(callbacks, import_classification),
      "must match gate-derived readiness level"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "status",
      operational_readiness_report_status(callbacks, import_classification),
      "must match gate-derived report status"
    )
  end

  defp validate_classification(issues, _callbacks, _path, _summary, _gates), do: issues

  defp validate_counts(issues, callbacks, path, summary, gates) when is_list(gates) do
    issues
    |> expect_field_equals(callbacks, path, summary, "gate_count", length(gates))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "passed_gate_count",
      gate_status_count(callbacks, gates, "passed")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_gate_count",
      gate_status_count(callbacks, gates, "review_required")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "analysis_gate_count",
      gate_status_count(callbacks, gates, "analysis_only")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_gate_count",
      gate_status_count(callbacks, gates, "blocked")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "non_passed_gate_count",
      Enum.count(gates, &(is_map(&1) and Map.get(&1, "status") != "passed"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "gate_status_counts",
      frequency_map(gates, "status"),
      "must match gate status counts from rows"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "gate_classification_counts",
      frequency_map(gates, "classification"),
      "must match gate classification counts from rows"
    )
  end

  defp validate_counts(issues, _callbacks, _path, _summary, _gates), do: issues

  defp validate_id_sets(issues, callbacks, path, summary, gates) when is_list(gates) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "gate_ids_by_status",
      operational_readiness_gate_ids_by(gates, "status"),
      "must match gate IDs grouped by status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "gate_ids_by_classification",
      operational_readiness_gate_ids_by(gates, "classification"),
      "must match gate IDs grouped by classification"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "passed_gate_ids",
      operational_readiness_gate_ids(gates, "passed"),
      "must match passed gate IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_required_gate_ids",
      operational_readiness_gate_ids(gates, "review_required"),
      "must match review-required gate IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "analysis_only_gate_ids",
      operational_readiness_gate_ids(gates, "analysis_only"),
      "must match analysis-only gate IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_gate_ids",
      operational_readiness_gate_ids(gates, "blocked"),
      "must match blocked gate IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "non_passed_gate_ids",
      operational_readiness_non_passed_gate_ids(gates),
      "must match non-passed gate IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "non_passed_gates",
      Enum.reject(gates, &(is_map(&1) and Map.get(&1, "status") == "passed")),
      "must match non-passed gate rows"
    )
  end

  defp validate_id_sets(issues, _callbacks, _path, _summary, _gates), do: issues

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

  defp validate_operational_readiness_gate(issues, callbacks, path, gate) do
    apply(Keyword.fetch!(callbacks, :validate_operational_readiness_gate), [issues, path, gate])
  end

  defp operational_readiness_gate_summary_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_gate_summary_model_limits), [])

  defp operational_readiness_import_classification(callbacks, gates),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_import_classification), [gates])

  defp operational_readiness_level(callbacks, classification),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_level), [classification])

  defp operational_readiness_report_status(callbacks, classification),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_report_status), [classification])

  defp gate_status_count(callbacks, gates, status),
    do: apply(Keyword.fetch!(callbacks, :gate_status_count), [gates, status])
end
