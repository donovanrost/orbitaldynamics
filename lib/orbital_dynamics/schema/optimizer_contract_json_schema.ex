defmodule OrbitalDynamics.Schema.OptimizerContractJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "candidate_count",
    "ranked_timeline_count",
    "selected_activity_count"
  ]

  @stable_id_array_fields [
    "selected_activity_ids",
    "candidate_activity_ids",
    "ranked_scenario_ids"
  ]

  @string_array_fields [
    "score_term_keys",
    "deterministic_ordering",
    "preserved_lineage_fields",
    "known_limits"
  ]

  @string_fields [
    "objective",
    "optimizer",
    "selection_policy"
  ]

  @object_fields [
    "assumptions",
    "constraints",
    "scoring_policy"
  ]

  @property_fields [
    "schema_contract",
    "id"
    | @string_fields ++
        @object_fields ++
        @count_fields ++
        @stable_id_array_fields ++
        @string_array_fields
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
    base_opts = [
      schema_contract: fetch_dep!(deps, :schema_contract),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)
    ]

    if field in @stable_id_array_fields do
      Keyword.take(base_opts, [:stable_id_pattern])
    else
      base_opts
    end
  end

  def property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def property("id", opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property(field, _opts) when field in @string_fields do
    %{"type" => "string"}
  end

  def property(field, _opts) when field in @object_fields do
    %{"type" => "object"}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @string_array_fields do
    CommonJsonSchema.string_array()
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
