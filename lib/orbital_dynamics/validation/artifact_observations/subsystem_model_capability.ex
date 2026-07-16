defmodule OrbitalDynamics.Validation.ArtifactObservations.SubsystemModelCapability do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    applicability = stringify_keys(Map.get(artifact, "applicability") || %{})
    activity_effects = stringify_keys(Map.get(artifact, "activity_effects") || %{})
    parameters = stringify_keys(Map.get(artifact, "parameters") || %{})
    known_limits = list_values(artifact, "known_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "subsystem" => Map.get(artifact, "subsystem"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "fidelity_tier" => Map.get(artifact, "fidelity_tier"),
      "resource_dimension_count" => count(applicability, "resource_dimensions"),
      "resource_dimensions" =>
        applicability
        |> list_values("resource_dimensions")
        |> Enum.join("|"),
      "activity_effect_field_count" => count(applicability, "activity_effect_fields"),
      "activity_effect_fields" =>
        applicability
        |> list_values("activity_effect_fields")
        |> Enum.join("|"),
      "activity_effect_type_count" => map_size(activity_effects),
      "activity_effect_types" =>
        activity_effects
        |> Map.keys()
        |> Enum.sort()
        |> Enum.join("|"),
      "time_span" => Map.get(applicability, "time_span"),
      "state_variable_count" => count(artifact, "state_variables"),
      "state_variables" =>
        artifact
        |> list_values("state_variables")
        |> Enum.join("|"),
      "parameter_count" => map_size(parameters),
      "parameter_keys" =>
        parameters
        |> Map.keys()
        |> Enum.sort()
        |> Enum.join("|"),
      "capacity_wh" => Map.get(parameters, "capacity_wh"),
      "min_state_of_charge_fraction" => Map.get(parameters, "min_state_of_charge_fraction"),
      "max_state_of_charge_fraction" => Map.get(parameters, "max_state_of_charge_fraction"),
      "round_trip_efficiency" => Map.get(parameters, "round_trip_efficiency"),
      "storage_capacity_mb" => Map.get(parameters, "storage_capacity_mb"),
      "min_storage_margin" => Map.get(parameters, "min_storage_margin"),
      "downlink_completion_policy" => Map.get(parameters, "downlink_completion_policy"),
      "known_limit_count" => length(known_limits),
      "known_limit_keys" => Enum.join(known_limits, "|"),
      "selected_activity_sequence_only" => "selected_activity_sequence_only" in known_limits,
      "declared_energy_hints_only" => "declared_energy_hints_only" in known_limits,
      "no_continuous_power_bus_or_thermal_coupling" =>
        "no_continuous_power_bus_or_thermal_coupling" in known_limits,
      "no_battery_degradation_or_charge_dynamics" =>
        "no_battery_degradation_or_charge_dynamics" in known_limits,
      "declared_data_volume_hints_only" => "declared_data_volume_hints_only" in known_limits,
      "storage_limited_downlink_arithmetic_only" =>
        "storage_limited_downlink_arithmetic_only" in known_limits,
      "no_partition_priority_deletion_or_latency_model" =>
        "no_partition_priority_deletion_or_latency_model" in known_limits
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
