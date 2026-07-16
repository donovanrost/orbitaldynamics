defmodule OrbitalDynamics.Schema.OptimizerReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @ranking_comparison_report "ranking_comparison_report.v1"
  @pareto_frontier_report "pareto_frontier_report.v1"

  @ranking_count_fields [
    "left_count",
    "right_count",
    "matched_count",
    "left_only_count",
    "right_only_count",
    "row_count"
  ]

  @ranking_string_fields [
    "source",
    "objective",
    "objective_direction",
    "left_label",
    "right_label"
  ]

  @pareto_count_fields [
    "alternative_count",
    "objective_count",
    "frontier_count",
    "dominated_count"
  ]

  def property_field?(field, @ranking_comparison_report)
      when field in ["rows", "winner", "model_limits", "model"],
      do: true

  def property_field?(field, @ranking_comparison_report)
      when field in @ranking_count_fields or field in @ranking_string_fields,
      do: true

  def property_field?(field, @pareto_frontier_report)
      when field in [
             "rows",
             "model_limits",
             "frontier_ids",
             "dominated_ids",
             "objective_directions",
             "assumptions",
             "model",
             "source"
           ],
      do: true

  def property_field?(field, @pareto_frontier_report)
      when field in @pareto_count_fields,
      do: true

  def property_field?(_field, _contract_name), do: false

  def property_opts("rows", @ranking_comparison_report, deps) do
    [ranking_row_schema: fetch_dep!(deps, :ranking_row_schema)]
  end

  def property_opts("winner", @ranking_comparison_report, deps) do
    [ranking_winner_schema: fetch_dep!(deps, :ranking_winner_schema)]
  end

  def property_opts("model_limits", @ranking_comparison_report, deps) do
    [ranking_model_limits: fetch_dep!(deps, :ranking_model_limits)]
  end

  def property_opts("rows", @pareto_frontier_report, deps) do
    [pareto_row_schema: fetch_dep!(deps, :pareto_row_schema)]
  end

  def property_opts("model_limits", @pareto_frontier_report, deps) do
    [pareto_model_limits: fetch_dep!(deps, :pareto_model_limits)]
  end

  def property_opts(field, @pareto_frontier_report, deps)
      when field in ["frontier_ids", "dominated_ids"] do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _contract_name, _deps), do: []

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    contract_name = fetch_dep!(deps, :contract_name)

    property(field, contract_name, property_opts(field, contract_name, deps))
  end

  def property("rows", @ranking_comparison_report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :ranking_row_schema)}
  end

  def property("winner", @ranking_comparison_report, opts) do
    Keyword.fetch!(opts, :ranking_winner_schema)
  end

  def property("model_limits", @ranking_comparison_report, opts) do
    model_limits = Keyword.fetch!(opts, :ranking_model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, @ranking_comparison_report, _opts) when field in @ranking_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, @ranking_comparison_report, _opts) when field in @ranking_string_fields do
    %{"type" => "string"}
  end

  def property("model", @ranking_comparison_report, _opts) do
    %{"type" => "string", "const" => "scenario_ranking_pairwise_delta"}
  end

  def property("rows", @pareto_frontier_report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :pareto_row_schema)}
  end

  def property("model_limits", @pareto_frontier_report, opts) do
    model_limits = Keyword.fetch!(opts, :pareto_model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, @pareto_frontier_report, _opts) when field in @pareto_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, @pareto_frontier_report, opts)
      when field in ["frontier_ids", "dominated_ids"] do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, @pareto_frontier_report, _opts)
      when field in ["objective_directions", "assumptions"] do
    %{"type" => "object", "additionalProperties" => true}
  end

  def property("model", @pareto_frontier_report, _opts) do
    %{"type" => "string", "const" => "objective_vector_pareto_frontier"}
  end

  def property("source", @pareto_frontier_report, _opts) do
    %{"type" => "string"}
  end

  def ranking_comparison_row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "scenario_id",
        "status",
        "left_rank",
        "right_rank",
        "rank_delta",
        "left_value",
        "right_value",
        "value_delta"
      ],
      "properties" => %{
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "status" => %{"type" => "string", "enum" => ["matched", "left_only", "right_only"]},
        "left_rank" => %{"type" => ["integer", "null"]},
        "right_rank" => %{"type" => ["integer", "null"]},
        "rank_delta" => %{"type" => ["integer", "null"]},
        "left_value" => %{"type" => ["number", "null"]},
        "right_value" => %{"type" => ["number", "null"]},
        "value_delta" => %{"type" => ["number", "null"]}
      }
    }
  end

  def ranking_comparison_row_from_context(deps) when is_list(deps) do
    ranking_comparison_row(stable_id_pattern: fetch_dep!(deps, :stable_id_pattern))
  end

  def ranking_comparison_winner(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["left_scenario_id", "right_scenario_id", "changed"],
      "properties" => %{
        "left_scenario_id" => %{"type" => ["string", "null"], "pattern" => stable_id_pattern},
        "right_scenario_id" => %{"type" => ["string", "null"], "pattern" => stable_id_pattern},
        "changed" => %{"type" => "boolean"}
      }
    }
  end

  def ranking_comparison_winner_from_context(deps) when is_list(deps) do
    ranking_comparison_winner(stable_id_pattern: fetch_dep!(deps, :stable_id_pattern))
  end

  def pareto_frontier_row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "scenario_id",
        "objective_values",
        "objective_keys",
        "frontier",
        "dominated_by_ids",
        "dominates_ids"
      ],
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "objective_values" => Keyword.fetch!(opts, :numeric_map_schema),
        "objective_keys" => Keyword.fetch!(opts, :string_array_schema),
        "frontier" => %{"type" => "boolean"},
        "dominated_by_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "dominates_ids" => Keyword.fetch!(opts, :stable_id_array_schema)
      }
    }
  end

  def pareto_frontier_row_from_context(deps) when is_list(deps) do
    pareto_frontier_row(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      numeric_map_schema: fetch_dep!(deps, :numeric_map_schema),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema)
    )
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      value when is_function(value, 0) -> value.()
      value -> value
    end
  end
end
