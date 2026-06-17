defmodule OrbitalDynamics.Schema.PlanDeltaJsonSchema do
  @moduledoc false

  @activity_context_fields ["source_activity_context", "replacement_activity_context"]

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
end
