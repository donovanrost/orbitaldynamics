defmodule OrbitalDynamics.Schema.OperationalReadinessGateContracts do
  @moduledoc false

  def validate(issues, path, gate, callbacks) do
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> require_fields(path, gate, ["id", "status", "classification", "reason"], callbacks)
    |> expect_one_of(path, gate, "id", capability.gates, callbacks)
    |> expect_one_of(path, gate, "status", capability.gate_statuses, callbacks)
    |> expect_one_of(path, gate, "classification", capability.import_classifications, callbacks)
    |> expect_type(path, gate, "reason", :binary, callbacks)
    |> expect_optional_one_of(path, gate, "analysis_mode", capability.analysis_modes, callbacks)
    |> expect_optional_type(path, gate, "analysis_mode_source", :binary, callbacks)
    |> validate_resource_context(path, gate, callbacks)
    |> validate_operator_training_context(path, gate, callbacks)
    |> validate_adapter_boundary_context(path, gate, callbacks)
    |> validate_cadence_import_context(path, gate, callbacks)
    |> validate_timeline_publication_context(path, gate, callbacks)
  end

  defp require_fields(issues, path, map, fields, callbacks),
    do:
      apply(require_callback(callbacks, :require_fields), [
        issues,
        path,
        map,
        fields
      ])

  defp expect_one_of(issues, path, map, field, allowed, callbacks),
    do:
      apply(require_callback(callbacks, :expect_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_type(issues, path, map, field, type, callbacks),
    do:
      apply(require_callback(callbacks, :expect_type), [
        issues,
        path,
        map,
        field,
        type
      ])

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
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp validate_resource_context(issues, path, gate, callbacks),
    do:
      apply(require_callback(callbacks, :validate_resource_context), [
        issues,
        path,
        gate
      ])

  defp validate_operator_training_context(issues, path, gate, callbacks),
    do:
      apply(require_callback(callbacks, :validate_operator_training_context), [
        issues,
        path,
        gate
      ])

  defp validate_adapter_boundary_context(issues, path, gate, callbacks),
    do:
      apply(require_callback(callbacks, :validate_adapter_boundary_context), [
        issues,
        path,
        gate
      ])

  defp validate_cadence_import_context(issues, path, gate, callbacks),
    do:
      apply(require_callback(callbacks, :validate_cadence_import_context), [
        issues,
        path,
        gate
      ])

  defp validate_timeline_publication_context(issues, path, gate, callbacks),
    do:
      apply(require_callback(callbacks, :validate_timeline_publication_context), [
        issues,
        path,
        gate
      ])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
