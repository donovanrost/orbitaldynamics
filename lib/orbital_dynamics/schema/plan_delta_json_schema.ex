defmodule OrbitalDynamics.Schema.PlanDeltaJsonSchema do
  @moduledoc false

  @activity_context_fields ["source_activity_context", "replacement_activity_context"]

  @base_fields [
    "planned",
    "realized",
    "requires_approval"
  ]

  def property_field?(field) do
    field in @base_fields or field in @activity_context_fields
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def dispatch_property(field, contract, opts) do
    focused_property = Keyword.fetch!(opts, :focused_property)
    execution_uncertainty_schema = Keyword.fetch!(opts, :execution_uncertainty_schema)
    number_or_string_schema = Keyword.fetch!(opts, :number_or_string_schema)
    default_property = Keyword.fetch!(opts, :default_property)

    cond do
      property_field?(field) ->
        focused_property.(field)

      field in ["execution_uncertainty", "maneuver_execution_uncertainty"] ->
        execution_uncertainty_schema.()

      field == "lighting_confidence" ->
        number_or_string_schema.()

      true ->
        default_property.(field, contract)
    end
  end

  def property_opts("planned", deps) do
    [planned_activity_schema: fetch_dep!(deps, :planned_activity_schema)]
  end

  def property_opts("realized", deps) do
    [realized_activity_schema: fetch_dep!(deps, :realized_activity_schema)]
  end

  def property_opts(field, deps) when field in @activity_context_fields do
    [activity_context_schema: fetch_dep!(deps, :activity_context_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property("planned", opts) do
    Keyword.fetch!(opts, :planned_activity_schema)
  end

  def property("realized", opts) do
    Keyword.fetch!(opts, :realized_activity_schema)
  end

  def property("requires_approval", _opts) do
    %{"type" => "boolean"}
  end

  def property(field, opts) when field in @activity_context_fields do
    Keyword.fetch!(opts, :activity_context_schema)
  end

  defp fetch_dep!(deps, key), do: Keyword.fetch!(deps, key)
end
