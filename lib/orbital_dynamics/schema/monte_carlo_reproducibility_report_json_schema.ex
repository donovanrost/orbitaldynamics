defmodule OrbitalDynamics.Schema.MonteCarloReproducibilityReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields ["requested_count", "generated_scenario_count"]
  @numeric_triplet_fields ["position_sigma_km", "velocity_sigma_km_s"]
  @object_fields ["assumptions", "seed_manifest"]
  @string_fields ["generator", "id_prefix", "rng", "sampling_method", "source"]

  @property_fields [
    "schema_contract",
    "generated_scenario_ids",
    "known_limits",
    "model_limits",
    "model",
    "deterministic_seed",
    "seed"
    | @string_fields ++ @count_fields ++ @numeric_triplet_fields ++ @object_fields
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

  def property_field_opts("generated_scenario_ids", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_field_opts(field, deps) when field in ["known_limits", "model_limits"] do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_field_opts(field, deps) when field in @numeric_triplet_fields do
    [numeric_triplet_schema: fetch_dep!(deps, :numeric_triplet_schema)]
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

  def property("generated_scenario_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in ["known_limits", "model_limits"] do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, _opts) when field in @string_fields do
    %{"type" => "string"}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "seeded_independent_normal_cartesian_dispersion"}
  end

  def property("deterministic_seed", _opts) do
    %{"type" => "boolean"}
  end

  def property("seed", _opts) do
    %{"type" => "integer"}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @numeric_triplet_fields do
    Keyword.fetch!(opts, :numeric_triplet_schema)
  end

  def property(field, _opts) when field in @object_fields do
    %{"type" => "object"}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
