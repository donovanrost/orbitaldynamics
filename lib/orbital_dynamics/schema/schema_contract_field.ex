defmodule OrbitalDynamics.Schema.SchemaContractField do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate_optional(issues, path, map, expected) when is_map(map) do
    if Map.has_key?(map, "schema_contract") do
      PrimitiveValidation.expect_equal(issues, path, map, "schema_contract", expected)
    else
      issues
    end
  end
end
