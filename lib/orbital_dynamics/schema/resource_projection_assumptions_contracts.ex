defmodule OrbitalDynamics.Schema.ResourceProjectionAssumptionsContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate_subsystem_model_assumptions(issues, path, %{"assumptions" => assumptions})
      when is_map(assumptions) do
    issues
    |> PrimitiveValidation.expect_optional_field_equals(
      path <> ".assumptions",
      assumptions,
      "subsystem_model_capability_contract",
      "subsystem_model_capability.v1",
      "must equal \"subsystem_model_capability.v1\""
    )
    |> PrimitiveValidation.expect_optional_field_equals(
      path <> ".assumptions",
      assumptions,
      "subsystem_model_capability_ids",
      subsystem_model_capability_ids(),
      "must match ResourceProjection subsystem model capability IDs"
    )
    |> PrimitiveValidation.expect_optional_field_equals(
      path <> ".assumptions",
      assumptions,
      "subsystem_model_capability_ids_by_resource",
      subsystem_model_capability_ids_by_resource(),
      "must match ResourceProjection subsystem model capability IDs by resource"
    )
  end

  def validate_subsystem_model_assumptions(issues, _path, _artifact),
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
end
