defmodule OrbitalDynamics.Validation.ArtifactObservations.ActivityTemplate do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    operational_hints = stringify_keys(Map.get(artifact, "operational_hints") || %{})
    lifecycle_defaults = stringify_keys(Map.get(artifact, "lifecycle_defaults") || %{})
    default_fields = stringify_keys(Map.get(artifact, "default_fields") || %{})
    resource_hints = stringify_keys(Map.get(artifact, "resource_hints") || %{})
    subsystem_hints = stringify_keys(Map.get(artifact, "subsystem_state_hints") || %{})

    required_states =
      subsystem_hints |> Map.get("required_states", []) |> Enum.map(&stringify_keys/1)

    produced_states =
      subsystem_hints |> Map.get("produced_states", []) |> Enum.map(&stringify_keys/1)

    preconditions = map_rows(artifact, "precondition_hints")
    known_limits = list_values(artifact, "known_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "activity_type" => Map.get(artifact, "activity_type"),
      "template_version" => Map.get(artifact, "template_version"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "display_name" => Map.get(artifact, "display_name"),
      "field_count" => Map.get(artifact, "field_count"),
      "required_field_count" => Map.get(artifact, "required_field_count"),
      "optional_field_count" => Map.get(artifact, "optional_field_count"),
      "required_field_keys" =>
        artifact
        |> list_values("required_fields")
        |> Enum.join("|"),
      "optional_field_keys" =>
        artifact
        |> list_values("optional_fields")
        |> Enum.join("|"),
      "default_type" => Map.get(default_fields, "type"),
      "default_allow_overlap" => Map.get(default_fields, "allow_overlap"),
      "lifecycle_status" => Map.get(lifecycle_defaults, "status"),
      "lifecycle_approval_status" => Map.get(lifecycle_defaults, "approval_status"),
      "lifecycle_locked" => Map.get(lifecycle_defaults, "locked"),
      "lifecycle_allow_overlap" => Map.get(lifecycle_defaults, "allow_overlap"),
      "setup_duration_s" => Map.get(operational_hints, "setup_duration_s"),
      "cooldown_duration_s" => Map.get(operational_hints, "cooldown_duration_s"),
      "telemetry_confirmation_required" =>
        Map.get(operational_hints, "telemetry_confirmation_required"),
      "telemetry_confirmation_status" =>
        Map.get(operational_hints, "telemetry_confirmation_status"),
      "required_state_count" => length(required_states),
      "required_state_keys" => joined_subsystem_state_keys(required_states),
      "required_blocking_state_count" => Enum.count(required_states, &(&1["blocking"] == true)),
      "produced_state_count" => length(produced_states),
      "produced_state_keys" => joined_subsystem_state_keys(produced_states),
      "precondition_count" => length(preconditions),
      "precondition_type_keys" =>
        preconditions
        |> Enum.map(&Map.get(&1, "precondition_type"))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("|"),
      "blocking_precondition_count" => Enum.count(preconditions, &(&1["blocking"] == true)),
      "precondition_status_counts" => count_rows_by_value(preconditions, "status"),
      "requires_payload" => Map.get(resource_hints, "requires_payload"),
      "uses_storage" => Map.get(resource_hints, "uses_storage"),
      "estimated_data_volume_mb" => Map.get(resource_hints, "estimated_data_volume_mb"),
      "suppressed_activity_type_keys" =>
        resource_hints
        |> list_values("suppressed_activity_types")
        |> Enum.join("|"),
      "boundary" => get_in(artifact, ["assumptions", "boundary"]),
      "known_limit_count" => length(known_limits),
      "known_limit_keys" => Enum.join(known_limits, "|"),
      "template_only_no_schedule_mutation" =>
        "template_only_no_schedule_mutation" in known_limits,
      "no_resource_reservation" => "no_resource_reservation" in known_limits
    }
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp joined_subsystem_state_keys(rows) when is_list(rows) do
    rows
    |> Enum.map(fn row ->
      subsystem = Map.get(row, "subsystem")
      state = Map.get(row, "state")

      if is_nil(subsystem) or is_nil(state), do: nil, else: "#{subsystem}:#{state}"
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("|")
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
