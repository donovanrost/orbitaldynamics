defmodule OrbitalDynamics.Schema.OperationalExecutionBoundarySummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "operational_execution_boundary_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_operational_execution_boundary_summary"
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
    |> expect_type(callbacks, path, summary, "import_eligible", :boolean)
    |> expect_type(callbacks, path, summary, "handoff_only", :boolean)
    |> expect_type(callbacks, path, summary, "execution_allowed", :boolean)
    |> expect_type(callbacks, path, summary, "cadence_write_allowed", :boolean)
    |> expect_type(callbacks, path, summary, "operator_authority_granted", :boolean)
    |> expect_one_of(callbacks, path, summary, "execution_boundary", [
      "adapter_handoff_only",
      "operator_review_required_before_import",
      "analysis_only_not_for_execution",
      "blocked_not_for_import_or_execution"
    ])
    |> expect_optional_one_of(
      callbacks,
      path,
      summary,
      "analysis_mode",
      capability.analysis_modes
    )
    |> expect_optional_type(callbacks, path, summary, "analysis_mode_source", :binary)
    |> expect_type(callbacks, path, summary, "operational_mode_gate", :map)
    |> validate_operational_readiness_gate(
      callbacks,
      path <> ".operational_mode_gate",
      Map.get(summary, "operational_mode_gate")
    )
    |> expect_non_negative_integer(callbacks, path, summary, "gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "passed_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "review_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "analysis_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "blocked_gate_count")
    |> expect_non_negative_integer(callbacks, path, summary, "non_passed_gate_count")
    |> expect_type(callbacks, path, summary, "non_passed_gate_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".non_passed_gate_ids",
      Map.get(summary, "non_passed_gate_ids")
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> expect_optional_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      operational_execution_boundary_summary_model_limits(callbacks),
      "must match operational execution boundary summary model limits"
    )
    |> validate_assumptions(callbacks, path, summary)
    |> validate_classification(callbacks, path, summary)
    |> validate_counts(callbacks, path, summary)
    |> validate_mode(callbacks, path, summary)
  end

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        [
          {"execution_boundary", "artifact_only_no_cadence_write_no_command_execution"},
          {"source", "operational_readiness_report.v1"},
          {"operator_authority", "not_granted_by_execution_boundary_summary"},
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

  defp validate_classification(issues, callbacks, path, summary) do
    import_classification = Map.get(summary, "import_classification")

    issues
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
      "execution_boundary",
      quality_gate_execution_boundary(callbacks, import_classification),
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
    |> expect_field_equals(callbacks, path, summary, "handoff_only", true)
    |> expect_field_equals(callbacks, path, summary, "execution_allowed", false)
    |> expect_field_equals(callbacks, path, summary, "cadence_write_allowed", false)
    |> expect_field_equals(callbacks, path, summary, "operator_authority_granted", false)
  end

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
      length(list_or_empty(Map.get(summary, "non_passed_gate_ids"))),
      "must equal non-passed gate ID count"
    )
  end

  defp validate_mode(issues, callbacks, path, summary) do
    operational_mode_gate = Map.get(summary, "operational_mode_gate")

    issues =
      case operational_mode_gate do
        %{} = gate ->
          issues
          |> expect_equal(
            callbacks,
            path <> ".operational_mode_gate",
            gate,
            "id",
            "operational_mode"
          )
          |> expect_field_equals(
            callbacks,
            path,
            summary,
            "analysis_mode",
            Map.get(gate, "analysis_mode"),
            "must match operational_mode_gate.analysis_mode"
          )
          |> expect_field_equals(
            callbacks,
            path,
            summary,
            "analysis_mode_source",
            Map.get(gate, "analysis_mode_source"),
            "must match operational_mode_gate.analysis_mode_source"
          )

        _gate ->
          issues
      end

    if is_map(operational_mode_gate) and
         is_binary(Map.get(operational_mode_gate, "analysis_mode")) and
         not Map.has_key?(summary, "analysis_mode") do
      [
        error(
          callbacks,
          path <> ".analysis_mode",
          "must match operational_mode_gate.analysis_mode"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed) do
    apply(Keyword.fetch!(callbacks, :expect_optional_one_of), [
      issues,
      path,
      map,
      field,
      allowed
    ])
  end

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

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

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

  defp operational_execution_boundary_summary_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :operational_execution_boundary_summary_model_limits), [])

  defp operational_readiness_level(callbacks, classification),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_level), [classification])

  defp operational_readiness_report_status(callbacks, classification),
    do: apply(Keyword.fetch!(callbacks, :operational_readiness_report_status), [classification])

  defp quality_gate_execution_boundary(callbacks, classification),
    do: apply(Keyword.fetch!(callbacks, :quality_gate_execution_boundary), [classification])

  defp non_negative_integer_sum(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :non_negative_integer_sum), [values])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
