defmodule OrbitalDynamics.Schema.ObjectiveReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @objective_satisfaction_report "objective_satisfaction_report.v1"
  @objective_tradeoff_report "objective_tradeoff_report.v1"

  def property("rows", @objective_satisfaction_report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :satisfaction_row_schema)}
  end

  def property("model", @objective_satisfaction_report, _opts) do
    %{"type" => "string", "const" => "campaign_v1_selected_activity_objective_summary"}
  end

  def property("model_limits", @objective_satisfaction_report, opts) do
    model_limits = Keyword.fetch!(opts, :satisfaction_model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("objective_count", @objective_satisfaction_report, _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("tradeoffs", @objective_tradeoff_report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :tradeoff_row_schema)}
  end

  def property("ranking_count", @objective_tradeoff_report, _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("score_term_keys", @objective_tradeoff_report, _opts) do
    CommonJsonSchema.string_array()
  end

  def property("model", @objective_tradeoff_report, opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :tradeoff_models)}
  end

  def property("model_limits", @objective_tradeoff_report, opts) do
    model_limits = Keyword.fetch!(opts, :score_report_model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("policy", @objective_tradeoff_report, _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end
end
