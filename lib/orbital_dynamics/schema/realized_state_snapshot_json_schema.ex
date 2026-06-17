defmodule OrbitalDynamics.Schema.RealizedStateSnapshotJsonSchema do
  @moduledoc false

  def property("activities", opts) do
    array_of(Keyword.fetch!(opts, :realized_activity_schema))
  end

  def property("spacecraft_states", opts) do
    array_of(Keyword.fetch!(opts, :realized_spacecraft_state_schema))
  end

  def property("metadata", opts) do
    Keyword.fetch!(opts, :metadata_schema)
  end

  def property("model_limits", opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  defp array_of(item_schema) do
    %{
      "type" => "array",
      "items" => item_schema
    }
  end
end
