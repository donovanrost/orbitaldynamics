defmodule OrbitalDynamics.Schema.BranchComparisonReportJsonSchema do
  @moduledoc false

  @property_fields [
    "rows",
    "model",
    "source",
    "branch_count",
    "model_limits",
    "recommended_branch_id",
    "recommendation_eligibility_mode",
    "recommendation_status",
    "eligible_ranked_branch_ids"
  ]

  def property_field?(field), do: field in @property_fields

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(field, deps)
      when field in ["recommended_branch_id", "eligible_ranked_branch_ids"] do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "deterministic_strategy_branch_score_comparison"}
  end

  def property("source", _opts) do
    %{"type" => "string", "const" => "campaign_strategy.branches"}
  end

  def property("branch_count", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("recommended_branch_id", opts) do
    %{"type" => ["string", "null"], "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("recommendation_eligibility_mode", _opts) do
    %{"type" => "string", "const" => "hard"}
  end

  def property("recommendation_status", _opts) do
    %{
      "type" => "string",
      "enum" => ["recommendable", "no_recommendable_branch"]
    }
  end

  def property("eligible_ranked_branch_ids", opts) do
    %{
      "type" => "array",
      "items" => %{
        "type" => "string",
        "pattern" => Keyword.fetch!(opts, :stable_id_pattern)
      }
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
