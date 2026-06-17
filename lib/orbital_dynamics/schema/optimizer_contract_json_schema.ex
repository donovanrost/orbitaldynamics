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
end
