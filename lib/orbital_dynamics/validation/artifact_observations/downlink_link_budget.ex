defmodule OrbitalDynamics.Validation.ArtifactObservations.DownlinkLinkBudget do
  @moduledoc false

  alias OrbitalDynamics.Communications.DownlinkLinkBudget

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    binding = map_value(artifact, "contact_binding")
    derived = map_value(artifact, "derived")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "model" => Map.get(artifact, "model"),
      "status" => Map.get(artifact, "status"),
      "pass" => Map.get(artifact, "pass"),
      "contact_id" => Map.get(binding, "contact_id"),
      "source_window_id" => Map.get(binding, "source_window_id"),
      "source_window_revision" => Map.get(binding, "source_window_revision"),
      "received_power_dbw" => Map.get(derived, "received_power_dbw"),
      "c_n0_db_hz" => Map.get(derived, "c_n0_db_hz"),
      "eb_n0_db" => Map.get(derived, "eb_n0_db"),
      "supported_data_rate_bps" => Map.get(derived, "supported_data_rate_bps"),
      "supported_volume_mb" => Map.get(derived, "supported_volume_mb"),
      "pass_fail_margin_db" => Map.get(derived, "pass_fail_margin_db"),
      "geometry_margin_deg" => Map.get(derived, "geometry_margin_deg"),
      "source_revision" => get_in(artifact, ["provenance", "source_revision"]),
      "identity_matches_content" => identity_matches_content?(artifact),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp identity_matches_content?(artifact) do
    core = Map.delete(artifact, "id")
    Map.get(artifact, "id") == DownlinkLinkBudget.artifact_id(core)
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp map_value(map, key) do
    case Map.get(map, key) do
      value when is_map(value) -> value
      _value -> %{}
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
