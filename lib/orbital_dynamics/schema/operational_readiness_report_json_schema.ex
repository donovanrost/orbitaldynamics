defmodule OrbitalDynamics.Schema.OperationalReadinessReportJsonSchema do
  @moduledoc false

  @count_fields [
    "gate_count",
    "passed_gate_count",
    "review_gate_count",
    "analysis_gate_count",
    "blocked_gate_count",
    "non_passed_gate_count"
  ]

  @capability_fields ["readiness_level", "import_classification", "status"]

  def property_field?(field) when field in ["gates", "model", "model_limits", "evidence"],
    do: true

  def property_field?(field) when field in @capability_fields, do: true
  def property_field?(field) when field in @count_fields, do: true
  def property_field?(_field), do: false

  def property_opts(field, deps) when field in @capability_fields do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts("gates", deps) do
    [gate_schema: fetch_dep!(deps, :gate_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("evidence", deps) do
    [evidence_schema: fetch_dep!(deps, :evidence_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property("readiness_level", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :capability).readiness_levels
    }
  end

  def property("import_classification", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :capability).import_classifications
    }
  end

  def property("status", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :capability).gate_statuses
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("gates", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :gate_schema)
    }
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_operational_readiness_classifier"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{
        "type" => "string",
        "enum" => model_limits
      }
    }
  end

  def property("evidence", opts) do
    Keyword.fetch!(opts, :evidence_schema)
  end

  defp fetch_dep!(deps, key), do: Keyword.fetch!(deps, key)
end
