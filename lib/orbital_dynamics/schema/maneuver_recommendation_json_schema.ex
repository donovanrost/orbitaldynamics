defmodule OrbitalDynamics.Schema.ManeuverRecommendationJsonSchema do
  @moduledoc false

  @numeric_fields ["delta_v_magnitude_km_s", "epoch_s"]
  @stable_id_fields ["id", "scenario_id"]
  @string_fields ["epoch_scale", "frame", "maneuver_model", "type", "validation_level"]

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
end
