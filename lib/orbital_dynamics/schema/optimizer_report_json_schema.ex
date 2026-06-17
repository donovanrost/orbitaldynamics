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
end
