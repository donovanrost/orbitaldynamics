defmodule OrbitalDynamics.Schema.ResourceProjectionAssumptionsContracts do
  @moduledoc false

  def validate_subsystem_model_assumptions(
        issues,
        path,
        %{"assumptions" => assumptions},
        callbacks
      )
      when is_map(assumptions) and is_list(callbacks) do
    issues
    |> expect_optional_field_equals(
      callbacks,
      path <> ".assumptions",
      assumptions,
      "subsystem_model_capability_contract",
      "subsystem_model_capability.v1",
      "must equal \"subsystem_model_capability.v1\""
    )
    |> expect_optional_field_equals(
      callbacks,
      path <> ".assumptions",
      assumptions,
      "subsystem_model_capability_ids",
      subsystem_model_capability_ids(),
      "must match ResourceProjection subsystem model capability IDs"
    )
    |> expect_optional_field_equals(
      callbacks,
      path <> ".assumptions",
      assumptions,
      "subsystem_model_capability_ids_by_resource",
      subsystem_model_capability_ids_by_resource(),
      "must match ResourceProjection subsystem model capability IDs by resource"
    )
  end

  def validate_subsystem_model_assumptions(issues, _path, _artifact, _callbacks),
    do: issues

  def subsystem_model_capability_ids do
    OrbitalDynamics.ResourceProjection.capabilities()
    |> Map.fetch!(:subsystem_model_capability_ids)
  end

  def subsystem_model_capability_ids_by_resource do
    OrbitalDynamics.ResourceProjection.capabilities()
    |> Map.fetch!(:subsystem_model_capability_ids_by_resource)
    |> Map.new(fn {resource, id} -> {Atom.to_string(resource), id} end)
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_optional_field_equals), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])
end
