defmodule OrbitalDynamics.Schema.OperationalReadinessReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) do
    gates = Map.get(report, "gates", [])
    evidence = Map.get(report, "evidence", %{})
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> expect_equal(path, report, "schema_contract", "operational_readiness_report.v1", callbacks)
    |> expect_equal(
      path,
      report,
      "model",
      "artifact_only_operational_readiness_classifier",
      callbacks
    )
    |> validate_stable_ids(path, report, ["report_id", "source_artifact_id"], callbacks)
    |> expect_one_of(path, report, "readiness_level", capability.readiness_levels, callbacks)
    |> expect_one_of(
      path,
      report,
      "import_classification",
      capability.import_classifications,
      callbacks
    )
    |> expect_one_of(path, report, "status", capability.gate_statuses, callbacks)
    |> expect_non_negative_integer(path, report, "gate_count", callbacks)
    |> expect_non_negative_integer(path, report, "passed_gate_count", callbacks)
    |> expect_non_negative_integer(path, report, "review_gate_count", callbacks)
    |> expect_non_negative_integer(path, report, "analysis_gate_count", callbacks)
    |> expect_non_negative_integer(path, report, "blocked_gate_count", callbacks)
    |> expect_type(path, report, "gates", :list, callbacks)
    |> validate_rows(path <> ".gates", gates, validate_gate_callback(callbacks), callbacks)
    |> expect_type(path, report, "evidence", :map, callbacks)
    |> validate_evidence(path <> ".evidence", evidence, callbacks)
    |> expect_type(path, report, "assumptions", :list, callbacks)
    |> validate_string_list_items(path, report, "assumptions", callbacks)
    |> expect_type(path, report, "model_limits", :list, callbacks)
    |> validate_string_list_items(path, report, "model_limits", callbacks)
    |> validate_optional_exact_model_limits(
      path,
      report,
      operational_readiness_model_limits(callbacks),
      "must match operational readiness model limits",
      callbacks
    )
    |> validate_assumptions(path, report, callbacks)
    |> validate_classification(path, report, gates, callbacks)
    |> validate_evidence_gate_counts(path <> ".evidence", evidence, gates, callbacks)
    |> expect_field_equals(
      path,
      report,
      "gate_count",
      if(is_list(gates), do: length(gates)),
      callbacks
    )
    |> expect_field_equals(
      path,
      report,
      "passed_gate_count",
      gate_status_count(gates, "passed"),
      callbacks
    )
    |> expect_field_equals(
      path,
      report,
      "review_gate_count",
      gate_status_count(gates, "review_required"),
      callbacks
    )
    |> expect_field_equals(
      path,
      report,
      "analysis_gate_count",
      gate_status_count(gates, "analysis_only"),
      callbacks
    )
    |> expect_field_equals(
      path,
      report,
      "blocked_gate_count",
      gate_status_count(gates, "blocked"),
      callbacks
    )
  end

  def gate_status_count(gates, status) when is_list(gates) do
    gates
    |> Enum.filter(&is_map/1)
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  def gate_status_count(_gates, _status), do: nil

  defp expect_equal(issues, path, map, field, expected, callbacks),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp validate_stable_ids(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_one_of(issues, path, map, field, allowed, callbacks),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_non_negative_integer(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_type(issues, path, map, field, type, callbacks),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp validate_rows(issues, path, rows, validator, callbacks),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_evidence(issues, path, evidence, callbacks),
    do: apply(require_callback(callbacks, :validate_evidence), [issues, path, evidence])

  defp validate_string_list_items(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_exact_model_limits(issues, path, map, model_limits, message, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        map,
        model_limits,
        message
      ])

  defp validate_assumptions(issues, path, report, callbacks),
    do: apply(require_callback(callbacks, :validate_assumptions), [issues, path, report])

  defp validate_classification(issues, path, report, gates, callbacks),
    do:
      apply(require_callback(callbacks, :validate_classification), [issues, path, report, gates])

  defp validate_evidence_gate_counts(issues, path, evidence, gates, callbacks),
    do:
      apply(require_callback(callbacks, :validate_evidence_gate_counts), [
        issues,
        path,
        evidence,
        gates
      ])

  defp expect_field_equals(issues, path, map, field, expected, callbacks),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp operational_readiness_model_limits(callbacks),
    do: apply(require_callback(callbacks, :operational_readiness_model_limits), [])

  defp validate_gate_callback(callbacks), do: require_callback(callbacks, :validate_gate)

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
