defmodule OrbitalDynamics.Schema.OperationalImportEligibilitySummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    non_passed_gates = Map.get(summary, "non_passed_gates", [])
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "operational_import_eligibility_summary.v1"
    )
    |> expect_equal(callbacks, path, summary, "model", "artifact_only_import_eligibility_summary")
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
    |> expect_type(callbacks, path, summary, "import_eligible", :boolean)
    |> expect_non_negative_integer(callbacks, path, summary, "gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "passed_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "review_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "analysis_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "blocked_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "non_passed_gate_count")
    |> expect_type(callbacks, path, summary, "non_passed_gates", :list)
    |> validate_rows(
      callbacks,
      path <> ".non_passed_gates",
      non_passed_gates,
      fn acc, row_path, gate ->
        validate_operational_readiness_gate(acc, callbacks, row_path, gate)
      end
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> expect_optional_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      operational_import_eligibility_summary_model_limits(callbacks),
      "must match operational import eligibility summary model limits"
    )
    |> validate_assumptions(callbacks, path, summary)
    |> validate_classification(callbacks, path, summary, non_passed_gates)
    |> validate_counts(callbacks, path, summary)
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

  defp validate_classification(issues, callbacks, path, summary, non_passed_gates)
       when is_list(non_passed_gates) do
    import_classification =
      operational_readiness_import_classification(callbacks, non_passed_gates)

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_classification",
      import_classification,
      "must match non-passed gate-derived import classification"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "readiness_level",
      operational_readiness_level(callbacks, import_classification),
      "must match import classification"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "status",
      operational_readiness_report_status(callbacks, import_classification),
      "must match import classification"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_eligible",
      import_classification == "importable",
      "must match import classification"
    )
  end

  defp validate_classification(issues, _callbacks, _path, _summary, _non_passed_gates), do: issues

  defp validate_counts(issues, callbacks, path, summary) do
    passed_count = Map.get(summary, "passed_gate_count")
    review_count = Map.get(summary, "review_gate_count")
    analysis_count = Map.get(summary, "analysis_gate_count")
    blocked_count = Map.get(summary, "blocked_gate_count")

    total_count =
      non_negative_integer_sum(callbacks, [
        passed_count,
        review_count,
        analysis_count,
        blocked_count
      ])

    non_passed_count =
      non_negative_integer_sum(callbacks, [review_count, analysis_count, blocked_count])

    non_passed_gates =
      case Map.get(summary, "non_passed_gates", []) do
        gates when is_list(gates) -> Enum.filter(gates, &is_map/1)
        _gates -> []
      end

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "gate_count",
      total_count,
      "must equal gate status counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "non_passed_gate_count",
      non_passed_count,
      "must equal review, analysis, and blocked gate counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "non_passed_gate_count",
      length(non_passed_gates),
      "must equal non-passed gate row count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_gate_count",
      gate_status_count(callbacks, non_passed_gates, "review_required"),
      "must equal non-passed review gate count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "analysis_gate_count",
      gate_status_count(callbacks, non_passed_gates, "analysis_only"),
      "must equal non-passed analysis gate count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_gate_count",
      gate_status_count(callbacks, non_passed_gates, "blocked"),
      "must equal non-passed blocked gate count"
    )
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

  defp operational_import_eligibility_summary_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :operational_import_eligibility_summary_model_limits), [])

  defp operational_readiness_import_classification(callbacks, gates),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_import_classification), [gates])

  defp operational_readiness_level(callbacks, classification),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_level), [classification])

  defp operational_readiness_report_status(callbacks, classification),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_report_status), [classification])

  defp non_negative_integer_sum(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :non_negative_integer_sum), [values])

  defp gate_status_count(callbacks, gates, status),
    do: apply(Keyword.fetch!(callbacks, :gate_status_count), [gates, status])
end
