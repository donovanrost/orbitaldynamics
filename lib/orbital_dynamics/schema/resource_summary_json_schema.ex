defmodule OrbitalDynamics.Schema.ResourceSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @probability_fields [
    "fuel_margin",
    "power_margin",
    "battery_state_of_charge",
    "storage_margin",
    "downlink_margin"
  ]

  @non_negative_number_fields [
    "battery_capacity_wh",
    "battery_energy_used_wh",
    "battery_energy_generated_wh",
    "storage_capacity_mb",
    "storage_used_mb",
    "downlink_capacity_mb"
  ]

  @boolean_fields [
    "payload_available",
    "antenna_available",
    "spacecraft_available",
    "degraded"
  ]

  @string_fields [
    "mode",
    "source_quality",
    "trust_boundary"
  ]

  @string_array_fields [
    "suppressed_activity_types",
    "incompatible_activity_types"
  ]

  @object_fields [
    "assumptions",
    "provenance"
  ]

  @property_fields [
    "schema_contract",
    "spacecraft_id",
    "thermal_margin_c"
    | @probability_fields ++
        @non_negative_number_fields ++
        @boolean_fields ++
        @string_fields ++
        @string_array_fields ++
        @object_fields
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_opts("schema_contract", deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)]
  end

  def property_opts("spacecraft_id", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def row_from_context(stable_id_pattern, string_array_schema) do
    row(
      stable_id_pattern: stable_id_pattern,
      string_array_schema: string_array_schema
    )
  end

  def row_from_context(deps) do
    row(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      string_array_schema: fetch_dep!(deps, :string_array_schema)
    )
  end

  def row(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["schema_contract", "spacecraft_id"],
      "properties" => row_properties(opts)
    }
  end

  def property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def property("spacecraft_id", opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  def property(field, _opts) when field in @probability_fields do
    CommonJsonSchema.probability()
  end

  def property(field, _opts) when field in @non_negative_number_fields do
    %{"type" => "number", "minimum" => 0.0}
  end

  def property("thermal_margin_c", _opts), do: %{"type" => "number"}

  def property(field, _opts) when field in @boolean_fields do
    %{"type" => "boolean"}
  end

  def property(field, _opts) when field in @string_fields do
    %{"type" => "string"}
  end

  def property(field, _opts) when field in @string_array_fields do
    CommonJsonSchema.string_array()
  end

  def property(field, _opts) when field in @object_fields do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp row_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    string_array_schema = Keyword.fetch!(opts, :string_array_schema)

    %{
      "schema_contract" => %{"type" => "string", "const" => "resource_summary.v1"},
      "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
      "thermal_margin_c" => %{"type" => "number"},
      "suppressed_activity_types" => string_array_schema,
      "incompatible_activity_types" => string_array_schema
    }
    |> Map.merge(CommonJsonSchema.string_properties(@string_fields))
    |> Map.merge(Map.new(@probability_fields, &{&1, CommonJsonSchema.probability()}))
    |> Map.merge(Map.new(@non_negative_number_fields, &{&1, non_negative_number_schema()}))
    |> Map.merge(CommonJsonSchema.boolean_properties(@boolean_fields))
    |> Map.merge(
      Map.new(@object_fields, &{&1, %{"type" => "object", "additionalProperties" => true}})
    )
  end

  defp non_negative_number_schema do
    %{"type" => "number", "minimum" => 0.0}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      value when is_function(value, 0) -> value.()
      value -> value
    end
  end
end
