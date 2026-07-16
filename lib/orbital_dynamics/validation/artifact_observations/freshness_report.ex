defmodule OrbitalDynamics.Validation.ArtifactObservations.FreshnessReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    allowed_state_quality_levels = list_values(artifact, "allowed_state_quality_levels")
    stale_reasons = list_values(artifact, "stale_reasons")
    unknown_reasons = list_values(artifact, "unknown_reasons")
    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "status" => Map.get(artifact, "status"),
      "state_quality_status" => Map.get(artifact, "state_quality_status"),
      "accepted_state_quality_level" => Map.get(artifact, "accepted_state_quality_level"),
      "allowed_state_quality_level_count" => length(allowed_state_quality_levels),
      "first_allowed_state_quality_level" => List.first(allowed_state_quality_levels),
      "last_allowed_state_quality_level" => List.last(allowed_state_quality_levels),
      "stale_reason_count" => length(stale_reasons),
      "unknown_reason_count" => length(unknown_reasons),
      "freshness_reason_total" => length(stale_reasons) + length(unknown_reasons),
      "accepted_snapshot_age_s" => Map.get(artifact, "accepted_snapshot_age_s"),
      "horizon_start_offset_s" => Map.get(artifact, "horizon_start_offset_s"),
      "current_epoch_s" => Map.get(artifact, "current_epoch_s"),
      "horizon_starts_at_s" => Map.get(artifact, "horizon_starts_at_s"),
      "max_horizon_start_offset_s" => Map.get(artifact, "max_horizon_start_offset_s"),
      "max_snapshot_age_s" => Map.get(artifact, "max_snapshot_age_s"),
      "artifact_only_no_schedule_mutation" =>
        "artifact_only_no_schedule_mutation" in model_limits,
      "model_limit_count" => length(model_limits)
    }
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _value -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
