defmodule OrbitalDynamics.Schema.ModelAcceptanceReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "model_count",
    "accepted_count",
    "review_required_count",
    "blocked_count",
    "unknown_model_count"
  ]

  @model_id_map_fields [
    "model_ids_by_status",
    "model_ids_by_validation_level",
    "model_ids_by_intended_use"
  ]

  def property_field?(field)
      when field in [
             "intended_use",
             "status",
             "model",
             "model_limits",
             "validation_level_counts",
             "status_counts",
             "records",
             "rows"
           ],
      do: true

  def property_field?(field) when field in @count_fields, do: true
  def property_field?(field) when field in @model_id_map_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_opts("intended_use", deps) do
    [intended_uses: fetch_dep!(deps, :intended_uses)]
  end

  def property_opts("status", deps) do
    [acceptance_statuses: fetch_dep!(deps, :acceptance_statuses)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("status_counts", deps) do
    [row_statuses: fetch_dep!(deps, :row_statuses)]
  end

  def property_opts(field, deps) when field in @model_id_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("records", deps) do
    [validation_record_schema: fetch_dep!(deps, :validation_record_schema)]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("intended_use", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :intended_uses)}
  end

  def property("status", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :acceptance_statuses)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "registry_model_acceptance_classifier"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("validation_level_counts", _opts) do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property("status_counts", opts) do
    opts
    |> Keyword.fetch!(:row_statuses)
    |> CommonJsonSchema.enum_count_map()
  end

  def property(field, opts) when field in @model_id_map_fields do
    %{
      "type" => "object",
      "additionalProperties" =>
        opts
        |> Keyword.fetch!(:stable_id_pattern)
        |> CommonJsonSchema.stable_id_array()
    }
  end

  def property("records", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :validation_record_schema)
    }
  end

  def property("rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
