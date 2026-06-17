defmodule OrbitalDynamics.Schema.ProposedContactJsonSchema do
  @moduledoc false

  @status_string_fields ["station_availability", "schedule_conflict_status"]

  def property("direction", _opts) do
    %{
      "type" => "string",
      "enum" => ["downlink", "uplink", "command", "tracking"]
    }
  end

  def property("source_window", opts) do
    Keyword.fetch!(opts, :source_window_schema)
  end

  def property("cadence_import", opts) do
    Keyword.fetch!(opts, :cadence_import_schema)
  end

  def property("timeline_identity", opts) do
    Keyword.fetch!(opts, :timeline_identity_schema)
  end

  def property(field, _opts) when field in @status_string_fields do
    %{"type" => "string"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end
end
