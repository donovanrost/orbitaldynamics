defmodule OrbitalDynamics.CampaignPlanner.OperationalFeedbackNormalization do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalFeedback,
    ScalarValues,
    ValueEncoding
  }

  @resource_availability_true_tokens ~w(true 1 yes y available nominal operational enabled)
  @resource_availability_false_tokens ~w(false 0 no n unavailable offline down outage maintenance disabled)

  def normalize(feedback), do: normalize(feedback, default_callbacks())

  def normalize(%OperationalFeedback{} = feedback, callbacks) do
    feedback
    |> Map.from_struct()
    |> normalize(callbacks)
  end

  def normalize(feedback, callbacks) when not is_map(feedback) do
    normalize(%{}, callbacks)
  end

  def normalize(feedback, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    feedback = stringify_keys.(feedback)

    %{
      "contact_success_rate" =>
        normalize_feedback_factor_map(Map.get(feedback, "contact_success_rate", %{}), callbacks),
      "observation_success_rate" =>
        normalize_feedback_factor_map(
          Map.get(feedback, "observation_success_rate", %{}),
          callbacks
        ),
      "image_quality_score" =>
        normalize_feedback_factor_map(Map.get(feedback, "image_quality_score", %{}), callbacks),
      "image_quality_status" =>
        normalize_string_map(Map.get(feedback, "image_quality_status", %{}), callbacks),
      "image_quality_source" =>
        normalize_string_map(Map.get(feedback, "image_quality_source", %{}), callbacks),
      "cloud_cover_fraction" =>
        normalize_feedback_factor_map(Map.get(feedback, "cloud_cover_fraction", %{}), callbacks),
      "blur_score" =>
        normalize_feedback_factor_map(Map.get(feedback, "blur_score", %{}), callbacks),
      "maneuver_success_rate" =>
        normalize_feedback_factor_map(
          Map.get(feedback, "maneuver_success_rate", %{}),
          callbacks
        ),
      "maneuver_execution_uncertainty" =>
        normalize_maneuver_execution_uncertainty_feedback_map(
          Map.get(feedback, "maneuver_execution_uncertainty", %{}),
          callbacks
        ),
      "command_success_rate" =>
        normalize_feedback_factor_map(Map.get(feedback, "command_success_rate", %{}), callbacks),
      "station_throughput_factor" =>
        normalize_feedback_factor_map(
          Map.get(feedback, "station_throughput_factor", %{}),
          callbacks
        ),
      "downlink_demand_mb" =>
        normalize_nonnegative_number_map(Map.get(feedback, "downlink_demand_mb", %{}), callbacks),
      "downlink_demand_sources" =>
        normalize_string_list_map(Map.get(feedback, "downlink_demand_sources", %{}), callbacks),
      "downlink_demand_context" =>
        normalize_object_map(Map.get(feedback, "downlink_demand_context", %{}), callbacks),
      "target_priority_overrides" =>
        normalize_nonnegative_number_map(
          Map.get(feedback, "target_priority_overrides", %{}),
          callbacks
        ),
      "resource_margin_overrides" =>
        normalize_resource_margin_feedback_map(
          Map.get(feedback, "resource_margin_overrides", %{}),
          callbacks
        ),
      "resource_availability_overrides" =>
        feedback
        |> availability_override_feedback()
        |> normalize_resource_availability_feedback_map(callbacks)
    }
  end

  def merge(derived, explicit), do: merge(derived, explicit, default_callbacks())

  def merge(derived, explicit, callbacks) do
    derived = normalize(derived, callbacks)
    explicit = normalize(explicit, callbacks)

    Map.new(derived, fn {key, derived_values} ->
      {key, Map.merge(derived_values, Map.get(explicit, key, %{}))}
    end)
  end

  def normalize_resource_margin_aliases(value),
    do: normalize_resource_margin_aliases(value, default_callbacks())

  def normalize_resource_margin_aliases(%{} = value, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    value
    |> stringify_keys.()
    |> copy_resource_margin_alias("storage_margin", "storage_capacity_margin")
    |> copy_resource_margin_alias("downlink_margin", "downlink_capacity_margin")
    |> copy_resource_margin_alias("battery_state_of_charge", "battery_soc")
    |> copy_resource_margin_alias(
      "min_operating_temperature_c",
      "minimum_operating_temperature_c"
    )
    |> copy_resource_margin_alias(
      "max_operating_temperature_c",
      "maximum_operating_temperature_c"
    )
    |> copy_resource_margin_alias("min_operating_temperature_c", "min_temperature_c")
    |> copy_resource_margin_alias("max_operating_temperature_c", "max_temperature_c")
    |> put_power_margin_from_battery_state_of_charge(callbacks)
    |> put_thermal_margin_from_temperature_bounds(callbacks)
    |> normalize_resource_margin_numbers(callbacks)
  end

  def normalize_resource_margin_aliases(value, _callbacks), do: value

  def normalize_resource_availability_aliases(value),
    do: normalize_resource_availability_aliases(value, default_callbacks())

  def normalize_resource_availability_aliases(%{} = value, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    value
    |> stringify_keys.()
    |> copy_resource_availability_alias("payload_available", "payload_available?")
    |> copy_resource_availability_alias("antenna_available", "antenna_available?")
    |> copy_resource_availability_alias("spacecraft_available", "spacecraft_available?")
    |> copy_boolean_resource_availability_alias(
      "spacecraft_available",
      "spacecraft_availability",
      callbacks
    )
    |> copy_resource_availability_status_alias("payload_available", "payload_status", callbacks)
    |> copy_resource_availability_status_alias("antenna_available", "antenna_status", callbacks)
    |> copy_resource_availability_status_alias(
      "spacecraft_available",
      "spacecraft_status",
      callbacks
    )
    |> copy_resource_availability_alias("degraded", "degraded?")
    |> normalize_resource_availability_boolean_values(callbacks)
  end

  def normalize_resource_availability_aliases(value, _callbacks), do: value

  def copy_resource_availability_status_alias(value, canonical_key, alias_key),
    do:
      copy_resource_availability_status_alias(
        value,
        canonical_key,
        alias_key,
        default_callbacks()
      )

  def copy_resource_availability_status_alias(value, canonical_key, alias_key, callbacks) do
    alias_value = resource_availability_boolean_value(Map.get(value, alias_key), callbacks)

    if Map.has_key?(value, canonical_key) or not is_boolean(alias_value) do
      value
    else
      Map.put(value, canonical_key, alias_value)
    end
  end

  def resource_availability_boolean_value(value, _callbacks) when is_boolean(value), do: value

  def resource_availability_boolean_value(value, _callbacks) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  def resource_availability_boolean_value(value, callbacks) when is_binary(value) do
    true_tokens = Keyword.fetch!(callbacks, :resource_availability_true_tokens)
    false_tokens = Keyword.fetch!(callbacks, :resource_availability_false_tokens)

    value = String.downcase(String.trim(value))

    cond do
      value in true_tokens -> true
      value in false_tokens -> false
      true -> nil
    end
  end

  def resource_availability_boolean_value(_value, _callbacks), do: nil

  def operational_feedback_key?(key), do: operational_feedback_key?(key, default_callbacks())

  def operational_feedback_key?(key, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)
    stable_id_string?.(key)
  end

  defp default_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      compact_map: &ValueEncoding.compact_map/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens
    ]
  end

  defp availability_override_feedback(feedback) do
    alias_overrides =
      case Map.get(feedback, "availability_overrides") do
        %{} = overrides -> overrides
        _other -> %{}
      end

    canonical_overrides =
      case Map.get(feedback, "resource_availability_overrides") do
        %{} = overrides -> overrides
        _other -> %{}
      end

    Map.merge(alias_overrides, canonical_overrides)
  end

  defp normalize_feedback_factor_map(%{} = factors, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    factors
    |> stringify_keys.()
    |> Enum.reduce(%{}, fn {key, value}, normalized ->
      case numeric_or_nil.(value) do
        number when is_number(number) and number >= 0.0 and number <= 1.0 ->
          put_operational_feedback_entry(normalized, key, number, callbacks)

        _value ->
          normalized
      end
    end)
  end

  defp normalize_feedback_factor_map(_factors, _callbacks), do: %{}

  defp normalize_nonnegative_number_map(%{} = values, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    values
    |> stringify_keys.()
    |> Enum.reduce(%{}, fn {key, value}, normalized ->
      case numeric_or_nil.(value) do
        number when is_number(number) and number >= 0.0 ->
          put_operational_feedback_entry(normalized, key, number, callbacks)

        _value ->
          normalized
      end
    end)
  end

  defp normalize_nonnegative_number_map(_values, _callbacks), do: %{}

  defp normalize_string_list_map(%{} = values, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    values
    |> stringify_keys.()
    |> Enum.reduce(%{}, fn {key, value}, normalized ->
      if operational_feedback_key?(key, callbacks) and is_list(value) and
           Enum.all?(value, &valid_feedback_source_string?/1) do
        sources =
          value
          |> Enum.map(&feedback_source_string/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
          |> Enum.sort()

        if sources == [] do
          normalized
        else
          Map.put(normalized, key, sources)
        end
      else
        normalized
      end
    end)
  end

  defp normalize_string_list_map(_values, _callbacks), do: %{}

  defp normalize_object_map(%{} = values, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    values
    |> stringify_keys.()
    |> Enum.reduce(%{}, fn {key, value}, normalized ->
      if operational_feedback_key?(key, callbacks) and is_map(value) do
        put_operational_feedback_entry(
          normalized,
          key,
          value |> stringify_keys.() |> compact_map.(),
          callbacks
        )
      else
        normalized
      end
    end)
  end

  defp normalize_object_map(_values, _callbacks), do: %{}

  defp normalize_string_map(%{} = values, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    values
    |> stringify_keys.()
    |> Enum.reduce(%{}, fn {key, value}, normalized ->
      case feedback_source_string(value) do
        value when is_binary(value) and value != "" ->
          put_operational_feedback_entry(normalized, key, value, callbacks)

        _value ->
          normalized
      end
    end)
  end

  defp normalize_string_map(_values, _callbacks), do: %{}

  defp feedback_source_string(value) when is_binary(value) and value != "", do: value

  defp feedback_source_string(value) when is_atom(value) and not is_nil(value),
    do: Atom.to_string(value)

  defp feedback_source_string(_value), do: nil

  defp valid_feedback_source_string?(value) when is_binary(value), do: value != ""
  defp valid_feedback_source_string?(value) when is_atom(value), do: not is_nil(value)
  defp valid_feedback_source_string?(_value), do: false

  defp normalize_maneuver_execution_uncertainty_feedback_map(%{} = values, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    values
    |> stringify_keys.()
    |> Enum.reduce(%{}, fn
      {key, %{} = value}, normalized ->
        put_operational_feedback_entry(
          normalized,
          key,
          normalize_maneuver_execution_uncertainty_feedback(value, callbacks),
          callbacks
        )

      {_key, _value}, normalized ->
        normalized
    end)
  end

  defp normalize_maneuver_execution_uncertainty_feedback_map(_values, _callbacks), do: %{}

  defp normalize_maneuver_execution_uncertainty_feedback(%{} = value, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    value = stringify_keys.(value)

    %{
      "execution_uncertainty_status" => Map.get(value, "execution_uncertainty_status"),
      "execution_uncertainty" =>
        stringify_map_or_nil(Map.get(value, "execution_uncertainty"), callbacks),
      "timing_3sigma_s" => numeric_or_nil.(Map.get(value, "timing_3sigma_s")),
      "delta_v_3sigma_km_s" =>
        numeric_triplet_or_nil(Map.get(value, "delta_v_3sigma_km_s"), callbacks),
      "delta_v_3sigma_magnitude_km_s" =>
        numeric_or_nil.(Map.get(value, "delta_v_3sigma_magnitude_km_s")),
      "execution_uncertainty_source" => Map.get(value, "execution_uncertainty_source")
    }
    |> compact_map.()
  end

  defp stringify_map_or_nil(%{} = value, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    stringify_keys.(value)
  end

  defp stringify_map_or_nil(_value, _callbacks), do: nil

  defp numeric_triplet_or_nil(values, callbacks) when is_list(values) and length(values) == 3 do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    triplet = Enum.map(values, numeric_or_nil)

    if Enum.all?(triplet, &is_number/1), do: triplet, else: nil
  end

  defp numeric_triplet_or_nil(_values, _callbacks), do: nil

  defp normalize_resource_margin_feedback_map(%{} = values, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    values
    |> stringify_keys.()
    |> Enum.reduce(%{}, fn
      {key, %{} = value}, normalized ->
        put_operational_feedback_entry(
          normalized,
          key,
          normalize_resource_margin_aliases(value, callbacks),
          callbacks
        )

      {_key, _value}, normalized ->
        normalized
    end)
  end

  defp normalize_resource_margin_feedback_map(_values, _callbacks), do: %{}

  defp normalize_resource_margin_numbers(value, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    [
      "fuel_margin",
      "power_margin",
      "storage_margin",
      "downlink_margin",
      "thermal_margin_c",
      "temperature_c",
      "actual_temperature_c",
      "measured_temperature_c",
      "planned_temperature_c",
      "min_operating_temperature_c",
      "max_operating_temperature_c",
      "thermal_confidence",
      "battery_capacity_wh",
      "battery_energy_used_wh",
      "battery_state_of_charge"
    ]
    |> Enum.reduce(value, fn field, acc ->
      if Map.has_key?(acc, field) do
        case numeric_or_nil.(Map.get(acc, field)) do
          number when is_number(number) -> Map.put(acc, field, number * 1.0)
          _value -> Map.delete(acc, field)
        end
      else
        acc
      end
    end)
  end

  defp copy_resource_margin_alias(value, canonical_key, alias_key) do
    value =
      if Map.has_key?(value, canonical_key) or not Map.has_key?(value, alias_key) do
        value
      else
        Map.put(value, canonical_key, Map.get(value, alias_key))
      end

    Map.delete(value, alias_key)
  end

  defp put_power_margin_from_battery_state_of_charge(value, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    case {Map.get(value, "power_margin"),
          numeric_or_nil.(Map.get(value, "battery_state_of_charge"))} do
      {nil, state_of_charge} when is_number(state_of_charge) ->
        Map.put(value, "power_margin", state_of_charge)

      _values ->
        value
    end
  end

  defp put_thermal_margin_from_temperature_bounds(value, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    with nil <- numeric_or_nil.(Map.get(value, "thermal_margin_c")),
         temperature when is_number(temperature) <-
           resource_margin_temperature_c(value, callbacks),
         margin when is_number(margin) <-
           resource_margin_thermal_bound_margin_c(value, temperature, callbacks) do
      value
      |> Map.put("thermal_margin_c", margin)
      |> Map.put_new("temperature_c", temperature)
    else
      _value -> value
    end
  end

  defp resource_margin_temperature_c(value, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    [
      "actual_temperature_c",
      "measured_temperature_c",
      "temperature_c",
      "planned_temperature_c"
    ]
    |> Enum.map(&(value |> Map.get(&1) |> numeric_or_nil.()))
    |> Enum.find(&is_number/1)
  end

  defp resource_margin_thermal_bound_margin_c(value, temperature, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    min_temperature = numeric_or_nil.(Map.get(value, "min_operating_temperature_c"))
    max_temperature = numeric_or_nil.(Map.get(value, "max_operating_temperature_c"))

    case {min_temperature, max_temperature} do
      {min_c, max_c} when is_number(min_c) and is_number(max_c) ->
        min(temperature - min_c, max_c - temperature)

      {min_c, nil} when is_number(min_c) ->
        temperature - min_c

      {nil, max_c} when is_number(max_c) ->
        max_c - temperature

      _bounds ->
        nil
    end
  end

  defp normalize_resource_availability_feedback_map(%{} = values, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    values
    |> stringify_keys.()
    |> Enum.reduce(%{}, fn
      {key, %{} = value}, normalized ->
        put_operational_feedback_entry(
          normalized,
          key,
          normalize_resource_availability_aliases(value, callbacks),
          callbacks
        )

      {_key, _value}, normalized ->
        normalized
    end)
  end

  defp normalize_resource_availability_feedback_map(_values, _callbacks), do: %{}

  defp put_operational_feedback_entry(map, key, value, callbacks) do
    if operational_feedback_key?(key, callbacks), do: Map.put(map, key, value), else: map
  end

  defp normalize_resource_availability_boolean_values(value, callbacks) do
    Enum.reduce(
      ["payload_available", "antenna_available", "spacecraft_available", "degraded"],
      value,
      fn field, normalized ->
        case resource_availability_boolean_value(Map.get(normalized, field), callbacks) do
          bool when is_boolean(bool) -> Map.put(normalized, field, bool)
          nil -> normalized
        end
      end
    )
  end

  defp copy_resource_availability_alias(value, canonical_key, alias_key) do
    value =
      if Map.has_key?(value, canonical_key) or not Map.has_key?(value, alias_key) do
        value
      else
        Map.put(value, canonical_key, Map.get(value, alias_key))
      end

    Map.delete(value, alias_key)
  end

  defp copy_boolean_resource_availability_alias(value, canonical_key, alias_key, callbacks) do
    alias_value = resource_availability_boolean_value(Map.get(value, alias_key), callbacks)

    if Map.has_key?(value, canonical_key) or not is_boolean(alias_value) do
      value
    else
      value
      |> Map.put(canonical_key, alias_value)
      |> Map.delete(alias_key)
    end
  end
end
