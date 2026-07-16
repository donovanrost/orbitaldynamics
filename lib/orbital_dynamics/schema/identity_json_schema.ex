defmodule OrbitalDynamics.Schema.IdentityJsonSchema do
  @moduledoc false

  def target_from_context(stable_id_pattern) do
    target(stable_id_pattern)
  end

  def target(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "id" => stable_id(stable_id_pattern),
        "target_id" => stable_id(stable_id_pattern)
      }
    }
  end

  def ground_station_from_context(stable_id_pattern) do
    ground_station(stable_id_pattern)
  end

  def ground_station(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "id" => stable_id(stable_id_pattern),
        "station_id" => stable_id(stable_id_pattern),
        "ground_station_id" => stable_id(stable_id_pattern)
      }
    }
  end

  def spacecraft_from_context(stable_id_pattern) do
    spacecraft(stable_id_pattern)
  end

  def spacecraft(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "id" => stable_id(stable_id_pattern),
        "spacecraft_id" => stable_id(stable_id_pattern),
        "satellite_id" => stable_id(stable_id_pattern)
      }
    }
  end

  defp stable_id(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end
end
