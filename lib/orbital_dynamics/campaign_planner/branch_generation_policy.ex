defmodule OrbitalDynamics.CampaignPlanner.BranchGenerationPolicy do
  @moduledoc false

  def build(request) do
    policy = stringify_keys(get_key(request, :branch_generation_policy) || %{})
    urgent_priority_threshold = numeric_policy_value(policy, "urgent_priority_threshold", 8.0)

    derive? =
      truthy?(get_key(request, :derive_branches?)) or
        truthy?(get_key(request, :derive_branches)) or
        truthy?(Map.get(policy, "derive_branches"))

    %{
      "derive_branches" => derive?,
      "fuel_margin_threshold" => numeric_policy_value(policy, "fuel_margin_threshold", 0.25),
      "power_margin_threshold" => numeric_policy_value(policy, "power_margin_threshold", 0.2),
      "downlink_margin_threshold" =>
        numeric_policy_value(policy, "downlink_margin_threshold", 0.75),
      "storage_margin_threshold" => numeric_policy_value(policy, "storage_margin_threshold", 0.2),
      "thermal_margin_c_threshold" =>
        numeric_policy_value(
          policy,
          "thermal_margin_c_threshold",
          numeric_policy_value(policy, "thermal_margin_threshold", nil)
        ),
      "urgent_priority_threshold" => urgent_priority_threshold,
      "target_priority_feedback_threshold" =>
        numeric_policy_value(
          policy,
          "target_priority_feedback_threshold",
          urgent_priority_threshold
        ),
      "station_throughput_feedback_threshold" =>
        numeric_policy_value(policy, "station_throughput_feedback_threshold", 0.8),
      "contact_success_feedback_threshold" =>
        numeric_policy_value(policy, "contact_success_feedback_threshold", 0.8),
      "observation_success_feedback_threshold" =>
        numeric_policy_value(policy, "observation_success_feedback_threshold", 0.8),
      "maneuver_success_feedback_threshold" =>
        numeric_policy_value(policy, "maneuver_success_feedback_threshold", 0.8),
      "maneuver_execution_timing_3sigma_threshold_s" =>
        numeric_policy_value(policy, "maneuver_execution_timing_3sigma_threshold_s", 60.0),
      "maneuver_execution_delta_v_3sigma_threshold_km_s" =>
        numeric_policy_value(
          policy,
          "maneuver_execution_delta_v_3sigma_threshold_km_s",
          0.001
        ),
      "command_success_feedback_threshold" =>
        numeric_policy_value(policy, "command_success_feedback_threshold", 0.8),
      "downlink_demand_feedback_threshold_mb" =>
        numeric_policy_value(policy, "downlink_demand_feedback_threshold_mb", 0.0),
      "allow_urgent_placeholder" =>
        boolean_policy_value(policy, "allow_urgent_placeholder", true),
      "combine_derived_branches" => truthy?(Map.get(policy, "combine_derived_branches"))
    }
  end

  defp numeric_policy_value(policy, key, default) do
    case numeric_or_nil(Map.get(policy, key)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp boolean_policy_value(policy, key, default) do
    case json_boolean_value(Map.get(policy, key, default)) do
      value when is_boolean(value) -> value
      _value -> default
    end
  end

  defp truthy?(value), do: json_boolean_value(value) == true

  defp json_boolean_value(value) when is_boolean(value), do: value

  defp json_boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp json_boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  defp json_boolean_value(_value), do: nil

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp get_key(nil, _key), do: nil

  defp get_key(%{} = map, key) when is_atom(key),
    do: fetch_key_or_alias(map, key, Atom.to_string(key))

  defp fetch_key_or_alias(map, key, alias_key) do
    case Map.fetch(map, key) do
      {:ok, nil} -> Map.get(map, alias_key)
      {:ok, value} -> value
      :error -> Map.get(map, alias_key)
    end
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
