defmodule OrbitalDynamics.TimelineFeedback.SuccessFactor do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.ProviderResult

  def observation(activity, provider_result_map_value_keys) do
    explicit_observation(activity) ||
      provider_result_observation(activity, provider_result_map_value_keys) ||
      completed_fraction_observation(activity)
  end

  def observation_source(activity, provider_result_map_value_keys) do
    Map.get(activity, "observation_success_factor_source") ||
      get_in(activity, ["metadata", "observation_success_factor_source"]) ||
      if is_nil(explicit_observation(activity)) do
        provider_result_observation_source(activity, provider_result_map_value_keys) ||
          completed_fraction_observation_source(activity)
      end
  end

  def contact(activity, command_contact_directions) do
    explicit_contact(activity) ||
      if contact_activity?(activity, command_contact_directions) do
        completed_fraction(activity)
      end
  end

  def contact_source(activity, command_contact_directions) do
    explicit_contact_source(activity) ||
      if is_nil(explicit_contact(activity)) and
           contact_activity?(activity, command_contact_directions) and
           completed_fraction(activity) do
        "realized_activity.completed_fraction"
      end
  end

  def command(activity, command_contact_directions) do
    explicit_command(activity) ||
      if command_activity?(activity, command_contact_directions) do
        completed_fraction(activity)
      end
  end

  def command_source(activity, command_contact_directions) do
    explicit_command_source(activity) ||
      if is_nil(explicit_command(activity)) and
           command_activity?(activity, command_contact_directions) and
           completed_fraction(activity) do
        "realized_activity.completed_fraction"
      end
  end

  def first_unit_interval_number(activity, fields) do
    Enum.find_value(fields, fn field ->
      value =
        case field do
          path when is_list(path) -> path_value(activity, path)
          field -> first_value(activity, [field])
        end

      unit_interval_number_or_nil(value)
    end)
  end

  def unit_interval_number_or_nil(value) do
    case unit_interval_number_status(value) do
      {:ok, number} -> number
      _status -> nil
    end
  end

  def unit_interval_number_status(value) do
    case numeric_value(value) do
      number when is_number(number) and number >= 0.0 and number <= 1.0 ->
        {:ok, number * 1.0}

      number when is_number(number) ->
        {:invalid_number, number}

      _value ->
        if missing?(value), do: :missing, else: {:invalid_shape, value}
    end
  end

  def nonnegative_number_status(value) do
    case numeric_value(value) do
      number when is_number(number) and number >= 0.0 ->
        {:ok, number * 1.0}

      number when is_number(number) ->
        {:invalid_number, number}

      _value ->
        if missing?(value), do: :missing, else: {:invalid_shape, value}
    end
  end

  defp explicit_observation(activity) do
    first_unit_interval_number(activity, [
      "observation_success_factor",
      ["metadata", "observation_success_factor"]
    ])
  end

  defp provider_result_observation(
         %{"observation_result" => result} = activity,
         provider_result_map_value_keys
       ) do
    case ProviderResult.outcome(result, provider_result_map_value_keys) do
      :failure -> 0.0
      :success -> unit_interval_number_or_nil(activity["completed_fraction"]) || 1.0
      :unknown -> nil
    end
  end

  defp provider_result_observation(_activity, _provider_result_map_value_keys), do: nil

  defp provider_result_observation_source(
         %{"observation_result" => result},
         provider_result_map_value_keys
       )
       when not is_nil(result) do
    case ProviderResult.outcome(result, provider_result_map_value_keys) do
      outcome when outcome in [:failure, :success] -> "realized_activity.observation_result"
      :unknown -> nil
    end
  end

  defp provider_result_observation_source(_activity, _provider_result_map_value_keys), do: nil

  defp completed_fraction_observation(%{"type" => type} = activity)
       when type in ["observe", "observation"] do
    unit_interval_number_or_nil(activity["completed_fraction"])
  end

  defp completed_fraction_observation(_activity), do: nil

  defp completed_fraction_observation_source(activity) do
    if completed_fraction_observation(activity), do: "realized_activity.completed_fraction"
  end

  defp explicit_contact(activity) do
    first_unit_interval_number(activity, [
      "contact_success_factor",
      ["metadata", "contact_success_factor"],
      ["throughput_model", "contact_success_factor"]
    ])
  end

  defp explicit_contact_source(activity) do
    Map.get(activity, "contact_success_factor_source") ||
      get_in(activity, ["metadata", "contact_success_factor_source"]) ||
      get_in(activity, ["throughput_model", "confidence_source"])
  end

  defp explicit_command(activity) do
    first_unit_interval_number(activity, [
      "command_success_factor",
      ["metadata", "command_success_factor"]
    ])
  end

  defp explicit_command_source(activity) do
    Map.get(activity, "command_success_factor_source") ||
      get_in(activity, ["metadata", "command_success_factor_source"])
  end

  defp completed_fraction(activity) do
    unit_interval_number_or_nil(Map.get(activity, "completed_fraction"))
  end

  defp command_activity?(%{"type" => type}, _directions)
       when type in ["command", "health_check"],
       do: true

  defp command_activity?(%{"direction" => direction}, directions),
    do: direction in directions or direction == "health_check"

  defp command_activity?(_activity, _directions), do: false

  defp contact_activity?(%{"type" => type} = activity, directions)
       when type in ["downlink", "planned_contact", "tracking"],
       do: not command_activity?(activity, directions)

  defp contact_activity?(%{"direction" => direction}, _directions)
       when direction in ["downlink", "tracking"],
       do: true

  defp contact_activity?(activity, directions) do
    not command_activity?(activity, directions) and
      (present_string?(Map.get(activity, "ground_station_id")) or
         present_string?(Map.get(activity, "station_id")) or
         is_map(Map.get(activity, "ground_station")) or
         is_map(Map.get(activity, "station")))
  end

  defp path_value(%{} = map, [key]), do: Map.get(map, key)

  defp path_value(%{} = map, [key | rest]) do
    case Map.get(map, key) do
      %{} = nested -> path_value(nested, rest)
      _value -> nil
    end
  end

  defp path_value(_value, _path), do: nil

  defp first_value(map, keys) do
    Enum.reduce_while(keys, nil, fn key, _value ->
      metadata = Map.get(map, "metadata") || Map.get(map, :metadata) || %{}

      case fetch_key_or_atom(map, key) do
        {:ok, nil} -> first_value_from_metadata(metadata, key)
        {:ok, value} -> {:halt, value}
        :error -> first_value_from_metadata(metadata, key)
      end
    end)
  end

  defp first_value_from_metadata(metadata, key) do
    case fetch_key_or_atom(metadata, key) do
      {:ok, nil} -> {:cont, nil}
      {:ok, value} -> {:halt, value}
      :error -> {:cont, nil}
    end
  end

  defp fetch_key_or_atom(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error when is_binary(key) -> fetch_existing_atom_key(map, key)
      :error -> :error
    end
  end

  defp fetch_key_or_atom(_map, _key), do: :error

  defp fetch_existing_atom_key(map, key) do
    atom_key = String.to_existing_atom(key)
    Map.fetch(map, atom_key)
  rescue
    ArgumentError -> :error
  end

  defp numeric_value(value) when is_number(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp missing?(nil), do: true
  defp missing?(""), do: true
  defp missing?(_value), do: false

  defp present_string?(value), do: is_binary(value) and value != ""
end
