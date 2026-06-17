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
end
