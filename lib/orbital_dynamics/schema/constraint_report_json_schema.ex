defmodule OrbitalDynamics.Schema.ConstraintReportJsonSchema do
  @moduledoc false

  @property_fields ["rows", "constraint_count", "row_count", "model", "model_limits"]

  def property_field?(field), do: field in @property_fields

  def property_opts("rows", deps), do: [row_schema: fetch_dep!(deps, :row_schema)]

  def property_opts("model", deps), do: [models: fetch_dep!(deps, :models)]

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
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

  def property(field, _opts) when field in ["constraint_count", "row_count"] do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :models)}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def row_from_context(deps) when is_list(deps) do
    row(stable_id_pattern: fetch_dep!(deps, :stable_id_pattern))
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "constraint_id",
        "scenario_id",
        "metric",
        "operator",
        "threshold",
        "status"
      ],
      "properties" => %{
        "constraint_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "metric" => %{"type" => "string"},
        "operator" => %{"type" => "string", "enum" => ["<", "<=", "==", ">=", ">"]},
        "threshold" => %{"type" => "number"},
        "value" => %{"type" => "number"},
        "score" => %{"type" => "number"},
        "status" => %{"type" => "string", "enum" => ["pass", "fail", "warning"]}
      }
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      value when is_function(value, 0) -> value.()
      value -> value
    end
  end
end
