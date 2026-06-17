defmodule OrbitalDynamics.Schema.BranchComparisonReportJsonSchema do
  @moduledoc false

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
end
