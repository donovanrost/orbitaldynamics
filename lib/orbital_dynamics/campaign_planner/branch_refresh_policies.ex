defmodule OrbitalDynamics.CampaignPlanner.BranchRefreshPolicies do
  @moduledoc false

  def resource_filter_policy(branch, defaults) do
    branch
    |> Map.get("events", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.reduce(Map.get(defaults, "resource_filter_policy", %{}), fn
      %{"type" => "resource_margin_pressure", "resource_field" => "thermal_margin_c"} = event,
      policy ->
        put_numeric_policy_threshold(
          policy,
          "min_activity_thermal_margin_c",
          event["thermal_margin_c_threshold"]
        )

      _event, policy ->
        policy
    end)
  end

  def candidate_limit_policy(branch, defaults) do
    base_policy = Map.get(defaults, "candidate_limit_policy", %{})

    branch
    |> Map.get("events", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.reduce(base_policy, fn
      %{"type" => "refresh_budget_pressure"} = event, policy ->
        case numeric_or_nil(event["relaxed_max_candidate_activities"]) do
          value when is_number(value) and value > 0 ->
            relaxed_limit = ceil_count(value)
            current_limit = numeric_or_nil(Map.get(policy, "max_candidate_activities"))

            if is_number(current_limit) and current_limit >= relaxed_limit do
              policy
            else
              Map.put(policy, "max_candidate_activities", relaxed_limit)
            end

          _value ->
            policy
        end

      _event, policy ->
        policy
    end)
  end

  defp put_numeric_policy_threshold(policy, key, value) do
    case numeric_or_nil(value) do
      threshold when is_number(threshold) -> Map.put(policy, key, threshold)
      _value -> policy
    end
  end

  defp ceil_count(value) when is_integer(value), do: max(value, 0)
  defp ceil_count(value) when is_float(value), do: value |> Float.ceil() |> trunc() |> max(0)

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

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
