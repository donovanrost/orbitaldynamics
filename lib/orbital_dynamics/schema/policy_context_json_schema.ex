defmodule OrbitalDynamics.Schema.PolicyContextJsonSchema do
  @moduledoc false

  def properties(fields) do
    fields.string
    |> OrbitalDynamics.Schema.CommonJsonSchema.string_properties()
    |> Map.merge(
      OrbitalDynamics.Schema.CommonJsonSchema.string_array_properties(fields.string_array)
    )
    |> Map.merge(
      OrbitalDynamics.Schema.CommonJsonSchema.string_or_array_properties(fields.string_or_array)
    )
    |> Map.merge(OrbitalDynamics.Schema.CommonJsonSchema.number_properties(fields.number))
    |> Map.merge(OrbitalDynamics.Schema.CommonJsonSchema.integer_properties(fields.integer))
    |> Map.merge(
      OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_properties(
        fields.non_negative_integer
      )
    )
    |> Map.merge(OrbitalDynamics.Schema.CommonJsonSchema.boolean_properties(fields.boolean))
  end
end
