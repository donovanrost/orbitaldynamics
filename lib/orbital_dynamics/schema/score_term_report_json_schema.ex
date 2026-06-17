defmodule OrbitalDynamics.Schema.ScoreTermReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  def property("model", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :models)}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("score_term_keys", _opts) do
    CommonJsonSchema.string_array()
  end

  def property("row_count", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end
end
