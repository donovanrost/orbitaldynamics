defmodule OrbitalDynamics.CampaignPlanner.FuelPreservationBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    MissionStateResourceSources,
    OperationalFeedbackNormalization,
    ResourceMarginPressureEvents
  }

  @resource_availability_true_tokens ~w(true 1 yes y available nominal operational enabled)
  @resource_availability_false_tokens ~w(false 0 no n unavailable offline down outage maintenance disabled)

  def build(mission_state, policy) do
    resources =
      mission_state
      |> Map.get("resources", %{})
      |> stringify_keys()

    fuel_sources = mission_state_resource_margin_sources(mission_state, "fuel_margin")
    fuel_source = List.first(fuel_sources)
    fuel_margin = fuel_source && fuel_source["fuel_margin"]
    requested? = truthy?(Map.get(resources, "fuel_preservation_requested"))
    low_fuel? = is_number(fuel_margin) and fuel_margin <= policy["fuel_margin_threshold"]

    objective_requested? =
      mission_state
      |> Map.get("objectives", [])
      |> Enum.any?(&(Map.get(&1, "type") == "fuel_preservation"))

    if requested? or objective_requested? or low_fuel? do
      [
        %{
          "id" => "derived_fuel_preservation",
          "label" => "Derived fuel preservation",
          "events" =>
            [%{"type" => "fuel_preservation_mode"}] ++
              resource_margin_pressure_events(
                mission_state,
                fuel_sources,
                policy,
                "fuel_margin",
                "fuel_margin_threshold",
                "fuel_margin_low"
              ),
          "metadata" => %{
            "derived_source" => mission_state_resource_source_path(mission_state, "fuel_margin")
          }
        }
      ]
    else
      []
    end
  end

  defp mission_state_resource_margin_sources(mission_state, field) do
    MissionStateResourceSources.margin_sources(
      mission_state,
      field,
      mission_state_resource_source_callbacks()
    )
  end

  defp mission_state_resource_source_path(mission_state, field) do
    MissionStateResourceSources.source_path(mission_state, field)
  end

  defp mission_state_resource_spacecraft_id(mission_state) do
    MissionStateResourceSources.spacecraft_id(
      mission_state,
      mission_state_resource_source_callbacks()
    )
  end

  defp mission_state_resource_source_callbacks,
    do: [
      stringify_keys: &stringify_keys/1,
      normalize_resource_margin_aliases: &normalize_resource_margin_aliases/1,
      normalize_resource_availability_aliases: &normalize_resource_availability_aliases/1,
      numeric_or_nil: &numeric_or_nil/1
    ]

  defp normalize_resource_margin_aliases(value) do
    OperationalFeedbackNormalization.normalize_resource_margin_aliases(
      value,
      resource_normalization_callbacks()
    )
  end

  defp normalize_resource_availability_aliases(value) do
    OperationalFeedbackNormalization.normalize_resource_availability_aliases(
      value,
      resource_normalization_callbacks()
    )
  end

  defp resource_normalization_callbacks,
    do: [
      stringify_keys: &stringify_keys/1,
      numeric_or_nil: &numeric_or_nil/1,
      resource_availability_boolean_value: &resource_availability_boolean_value/1,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens
    ]

  defp resource_availability_boolean_value(value) do
    OperationalFeedbackNormalization.resource_availability_boolean_value(
      value,
      resource_normalization_callbacks()
    )
  end

  defp resource_margin_pressure_events(
         mission_state,
         sources,
         policy,
         field,
         threshold_key,
         reason
       ) do
    ResourceMarginPressureEvents.build(
      mission_state,
      sources,
      policy,
      field,
      threshold_key,
      reason,
      resource_margin_pressure_event_callbacks()
    )
  end

  defp resource_margin_pressure_event_callbacks,
    do: [
      resource_spacecraft_id: &mission_state_resource_spacecraft_id/1,
      compact_map: &compact_map/1
    ]

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

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_struct{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values), do: Enum.map(values, &encode_value/1)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
