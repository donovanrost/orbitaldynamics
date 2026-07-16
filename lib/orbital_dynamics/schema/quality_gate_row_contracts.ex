defmodule OrbitalDynamics.Schema.QualityGateRowContracts do
  @moduledoc false

  def validate(issues, path, row, callbacks) do
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> require_fields(
      path,
      row,
      ["id", "rank", "gate_id", "status", "classification", "reason"],
      callbacks
    )
    |> validate_stable_ids(path, row, ["id"], callbacks)
    |> expect_non_negative_integer(path, row, "rank", callbacks)
    |> expect_one_of(path, row, "gate_id", capability.gates, callbacks)
    |> expect_one_of(path, row, "status", capability.gate_statuses, callbacks)
    |> expect_one_of(path, row, "classification", capability.import_classifications, callbacks)
    |> expect_type(path, row, "reason", :binary, callbacks)
    |> expect_optional_one_of(path, row, "analysis_mode", capability.analysis_modes, callbacks)
    |> expect_optional_type(path, row, "analysis_mode_source", :binary, callbacks)
    |> expect_optional_type(path, row, "source_operational_readiness_gate", :map, callbacks)
    |> validate_source_gate_handoff_matches(path, row, callbacks)
    |> validate_source_report_handoff_matches(path, row, callbacks)
    |> validate_resource_context(path, row, callbacks)
    |> validate_operator_training_context(path, row, callbacks)
    |> validate_adapter_boundary_context(path, row, callbacks)
    |> validate_cadence_import_context(path, row, callbacks)
    |> validate_timeline_publication_context(path, row, callbacks)
  end

  def status_count(rows, status) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  def status_count(_rows, _status), do: nil

  def ids_by(rows, field, callbacks) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "gate_id"))
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {to_string(key), stable_sorted_ids(ids, callbacks)} end)
  end

  def ids_by(_rows, _field, _callbacks), do: nil

  def row_ids_by(rows, field, callbacks) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "id"))
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {to_string(key), stable_sorted_ids(ids, callbacks)} end)
  end

  def row_ids_by(_rows, _field, _callbacks), do: nil

  def ids(rows, status, callbacks) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.filter(&(Map.get(&1, "status") == status))
    |> Enum.map(&Map.get(&1, "gate_id"))
    |> stable_sorted_ids(callbacks)
  end

  def ids(_rows, _status, _callbacks), do: nil

  defp require_fields(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_non_negative_integer(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_one_of(issues, path, map, field, allowed, callbacks),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, path, map, field, type, callbacks),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_one_of(issues, path, map, field, allowed, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_optional_type(issues, path, map, field, type, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp validate_source_gate_handoff_matches(issues, path, row, callbacks),
    do:
      apply(require_callback(callbacks, :validate_source_gate_handoff_matches), [
        issues,
        path,
        row
      ])

  defp validate_source_report_handoff_matches(issues, path, row, callbacks),
    do:
      apply(require_callback(callbacks, :validate_source_report_handoff_matches), [
        issues,
        path,
        row
      ])

  defp validate_resource_context(issues, path, row, callbacks),
    do: apply(require_callback(callbacks, :validate_resource_context), [issues, path, row])

  defp validate_operator_training_context(issues, path, row, callbacks),
    do:
      apply(require_callback(callbacks, :validate_operator_training_context), [issues, path, row])

  defp validate_adapter_boundary_context(issues, path, row, callbacks),
    do:
      apply(require_callback(callbacks, :validate_adapter_boundary_context), [issues, path, row])

  defp validate_cadence_import_context(issues, path, row, callbacks),
    do: apply(require_callback(callbacks, :validate_cadence_import_context), [issues, path, row])

  defp validate_timeline_publication_context(issues, path, row, callbacks),
    do:
      apply(require_callback(callbacks, :validate_timeline_publication_context), [
        issues,
        path,
        row
      ])

  defp stable_sorted_ids(ids, callbacks),
    do: apply(require_callback(callbacks, :stable_sorted_ids), [ids])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
