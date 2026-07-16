defmodule OrbitalDynamics.Schema.ManeuverRecommendationJsonSchema do
  @moduledoc false

  @numeric_fields ["delta_v_magnitude_km_s", "epoch_s"]
  @stable_id_fields ["id", "scenario_id"]
  @string_fields ["epoch_scale", "frame", "maneuver_model", "type", "validation_level"]

  @property_fields [
    "schema_contract",
    "delta_v_km_s",
    "model_limits",
    "assumptions"
    | @stable_id_fields ++ @string_fields ++ @numeric_fields
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

  def property_opts(field, deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)] ++ property_field_opts(field, deps)
  end

  def property_field_opts(field, deps) when field in @stable_id_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_field_opts("delta_v_km_s", deps) do
    [numeric_triplet_schema: fetch_dep!(deps, :numeric_triplet_schema)]
  end

  def property_field_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_field_opts(_field, _deps), do: []

  def property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property(field, _opts) when field in @string_fields do
    %{"type" => "string"}
  end

  def property("delta_v_km_s", opts) do
    Keyword.fetch!(opts, :numeric_triplet_schema)
  end

  def property(field, _opts) when field in @numeric_fields do
    %{"type" => "number"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("assumptions", _opts) do
    %{"type" => "object"}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
