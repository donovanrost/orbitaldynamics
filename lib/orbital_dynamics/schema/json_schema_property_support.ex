defmodule OrbitalDynamics.Schema.JsonSchemaPropertySupport do
  @moduledoc false

  def fallback(field, name, contract, context) do
    default_property(
      field,
      name,
      contract,
      context_value(context, :field_type_hints),
      context_value(context, :stable_id_pattern)
    )
  end

  def default_property(field, name, contract, field_type_hints, stable_id_pattern) do
    OrbitalDynamics.Schema.FallbackPropertyJsonSchema.property(field, name, contract,
      field_type_hints: field_type_hints,
      stable_id_pattern: stable_id_pattern
    )
  end

  def provider(context, name, args) do
    context
    |> Keyword.fetch!(:schema_providers)
    |> Map.fetch!({name, length(args)})
    |> apply(args)
  end

  def context_value(context, name), do: Keyword.fetch!(context, name)
end
