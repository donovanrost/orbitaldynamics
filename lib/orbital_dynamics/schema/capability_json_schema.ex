defmodule OrbitalDynamics.Schema.CapabilityJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @environment_model_string_array_fields ["supported_bodies", "known_limits"]
  @environment_model_string_fields [
    "category",
    "coordinate_frame",
    "interpolation",
    "model",
    "source",
    "time_span"
  ]
  @environment_model_object_fields ["parameters"]

  @environment_provider_string_array_fields ["supported_bodies", "known_limits", "outputs"]
  @environment_provider_string_fields [
    "category",
    "model",
    "source",
    "interpolation",
    "trust_boundary"
  ]
  @environment_provider_plain_object_fields ["coverage"]
  @environment_provider_object_fields ["parameters", "provenance"]

  @subsystem_model_string_array_fields ["state_variables", "known_limits"]
  @subsystem_model_string_fields ["subsystem", "model", "source", "fidelity_tier"]
  @subsystem_model_object_fields ["applicability", "activity_effects", "parameters", "provenance"]

  @environment_model_fields [
    "schema_contract",
    "id",
    "network_access",
    "validation_level"
    | @environment_model_string_array_fields ++
        @environment_model_string_fields ++ @environment_model_object_fields
  ]

  @environment_provider_fields [
    "schema_contract",
    "id",
    "network_access",
    "validation_level"
    | @environment_provider_string_array_fields ++
        @environment_provider_string_fields ++
        @environment_provider_plain_object_fields ++ @environment_provider_object_fields
  ]

  @subsystem_model_fields [
    "schema_contract",
    "id",
    "validation_level"
    | @subsystem_model_string_array_fields ++
        @subsystem_model_string_fields ++ @subsystem_model_object_fields
  ]

  def property_field?(field, :environment_model) when field in @environment_model_fields, do: true

  def property_field?(field, :environment_provider) when field in @environment_provider_fields,
    do: true

  def property_field?(field, :subsystem_model) when field in @subsystem_model_fields, do: true

  def property_field?(_field, _kind), do: false

  def property_from_context(field, deps) when is_list(deps) do
    kind = fetch_dep!(deps, :kind)
    schema_contract = fetch_dep!(deps, :schema_contract)

    field
    |> property_opts(schema_contract, deps)
    |> property_for_kind(field, kind)
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_opts(field, contract, deps) do
    [
      schema_contract: contract,
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)
    ] ++ property_field_opts(field, deps)
  end

  def property_field_opts("validation_level", deps) do
    [validation_level_schema: fetch_dep!(deps, :validation_level_schema)]
  end

  def property_field_opts(_field, _deps), do: []

  def environment_model_property("schema_contract", opts) do
    schema_contract_property(opts)
  end

  def environment_model_property("id", opts) do
    stable_id_property(opts)
  end

  def environment_model_property("network_access", _opts) do
    boolean_schema()
  end

  def environment_model_property(field, _opts)
      when field in @environment_model_string_array_fields do
    CommonJsonSchema.string_array()
  end

  def environment_model_property("validation_level", opts) do
    validation_level_schema(opts)
  end

  def environment_model_property(field, _opts) when field in @environment_model_string_fields do
    string_schema()
  end

  def environment_model_property(field, _opts) when field in @environment_model_object_fields do
    plain_object_schema()
  end

  def environment_provider_property("schema_contract", opts) do
    schema_contract_property(opts)
  end

  def environment_provider_property("id", opts) do
    stable_id_property(opts)
  end

  def environment_provider_property("network_access", _opts) do
    boolean_schema()
  end

  def environment_provider_property(field, _opts)
      when field in @environment_provider_string_array_fields do
    CommonJsonSchema.string_array()
  end

  def environment_provider_property("validation_level", opts) do
    validation_level_schema(opts)
  end

  def environment_provider_property(field, _opts)
      when field in @environment_provider_string_fields do
    string_schema()
  end

  def environment_provider_property(field, _opts)
      when field in @environment_provider_plain_object_fields do
    plain_object_schema()
  end

  def environment_provider_property(field, _opts)
      when field in @environment_provider_object_fields do
    object_schema()
  end

  def subsystem_model_property("schema_contract", opts) do
    schema_contract_property(opts)
  end

  def subsystem_model_property("id", opts) do
    stable_id_property(opts)
  end

  def subsystem_model_property(field, _opts) when field in @subsystem_model_string_array_fields do
    CommonJsonSchema.string_array()
  end

  def subsystem_model_property("validation_level", opts) do
    validation_level_schema(opts)
  end

  def subsystem_model_property(field, _opts) when field in @subsystem_model_string_fields do
    string_schema()
  end

  def subsystem_model_property(field, _opts) when field in @subsystem_model_object_fields do
    object_schema()
  end

  defp property_for_kind(opts, field, :environment_model),
    do: environment_model_property(field, opts)

  defp property_for_kind(opts, field, :environment_provider),
    do: environment_provider_property(field, opts)

  defp property_for_kind(opts, field, :subsystem_model),
    do: subsystem_model_property(field, opts)

  defp validation_level_schema(opts) do
    Keyword.fetch!(opts, :validation_level_schema)
  end

  defp schema_contract_property(opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  defp stable_id_property(opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  defp boolean_schema do
    %{"type" => "boolean"}
  end

  defp string_schema do
    %{"type" => "string"}
  end

  defp plain_object_schema do
    %{"type" => "object"}
  end

  defp object_schema do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
