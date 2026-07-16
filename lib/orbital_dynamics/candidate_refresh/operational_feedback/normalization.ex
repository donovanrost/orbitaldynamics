defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.Normalization do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.{RealizedActivityRows, RowValues}

  @resource_availability_value_aliases %{
    "payload_available" => ["payload_available?"],
    "antenna_available" => ["antenna_available?"],
    "spacecraft_available" => ["spacecraft_available?"]
  }
  @resource_availability_boolean_aliases %{
    "spacecraft_available" => ["spacecraft_availability"]
  }
  @resource_availability_status_aliases %{
    "payload_available" => ["payload_status"],
    "antenna_available" => ["antenna_status"],
    "spacecraft_available" => ["spacecraft_status"]
  }
  @resource_availability_true_tokens ~w(true yes y available nominal operational enabled 1)
  @resource_availability_false_tokens ~w(false no n unavailable offline down outage maintenance disabled 0)

  def normalize_explicit(feedback) when is_map(feedback) do
    %{
      "contact_success_rate" =>
        normalize_feedback_factor_map(Map.get(feedback, "contact_success_rate", %{})),
      "observation_success_rate" =>
        normalize_feedback_factor_map(Map.get(feedback, "observation_success_rate", %{})),
      "image_quality_score" =>
        normalize_feedback_factor_map(Map.get(feedback, "image_quality_score", %{})),
      "image_quality_status" =>
        normalize_string_map(Map.get(feedback, "image_quality_status", %{})),
      "image_quality_source" =>
        normalize_string_map(Map.get(feedback, "image_quality_source", %{})),
      "cloud_cover_fraction" =>
        normalize_feedback_factor_map(Map.get(feedback, "cloud_cover_fraction", %{})),
      "blur_score" => normalize_feedback_factor_map(Map.get(feedback, "blur_score", %{})),
      "maneuver_success_rate" =>
        normalize_feedback_factor_map(Map.get(feedback, "maneuver_success_rate", %{})),
      "maneuver_execution_uncertainty" =>
        normalize_maneuver_execution_uncertainty_feedback_map(
          Map.get(feedback, "maneuver_execution_uncertainty", %{})
        ),
      "command_success_rate" =>
        normalize_feedback_factor_map(Map.get(feedback, "command_success_rate", %{})),
      "station_throughput_factor" =>
        normalize_feedback_factor_map(Map.get(feedback, "station_throughput_factor", %{})),
      "downlink_demand_mb" =>
        normalize_nonnegative_number_map(Map.get(feedback, "downlink_demand_mb", %{})),
      "downlink_demand_sources" =>
        normalize_string_list_map(Map.get(feedback, "downlink_demand_sources", %{})),
      "downlink_demand_context" =>
        normalize_object_map(Map.get(feedback, "downlink_demand_context", %{})),
      "target_priority_overrides" =>
        normalize_nonnegative_number_map(Map.get(feedback, "target_priority_overrides", %{})),
      "resource_margin_overrides" =>
        normalize_resource_margin_feedback_map(
          Map.get(feedback, "resource_margin_overrides", %{})
        ),
      "resource_availability_overrides" =>
        feedback
        |> availability_override_feedback()
        |> normalize_resource_availability_feedback_map(),
      "trust_boundary" => Map.get(feedback, "trust_boundary"),
      "provenance" => Map.get(feedback, "provenance")
    }
    |> RowValues.compact_nonempty()
  end

  def invalid_sections(feedback) when is_map(feedback) do
    feedback = RowValues.stringify_keys(feedback)

    scalar_map_fields = [
      "contact_success_rate",
      "observation_success_rate",
      "maneuver_success_rate",
      "command_success_rate",
      "station_throughput_factor",
      "downlink_demand_mb",
      "target_priority_overrides",
      "image_quality_score",
      "cloud_cover_fraction",
      "blur_score"
    ]

    string_map_fields = ["image_quality_status", "image_quality_source"]
    string_list_map_fields = ["downlink_demand_sources"]

    nested_map_fields = [
      "maneuver_execution_uncertainty",
      "resource_margin_overrides",
      "resource_availability_overrides",
      "availability_overrides"
    ]

    array_fields = ["realized_activities"]

    map_fields =
      scalar_map_fields ++ string_map_fields ++ string_list_map_fields ++ nested_map_fields

    invalid_key_sections =
      map_fields
      |> Enum.flat_map(&invalid_key_sections(feedback, &1))

    scalar_sections =
      scalar_map_fields
      |> Enum.flat_map(&invalid_field_sections(feedback, &1, :number_entries))

    string_list_sections =
      string_list_map_fields
      |> Enum.flat_map(&invalid_string_list_sections(feedback, &1))

    string_map_sections =
      string_map_fields
      |> Enum.flat_map(&invalid_string_sections(feedback, &1))

    nested_sections =
      nested_map_fields
      |> Enum.flat_map(&invalid_nested_sections(feedback, &1))

    array_sections =
      array_fields
      |> Enum.flat_map(&invalid_array_sections(feedback, &1))

    realized_activity_sections = RealizedActivityRows.invalid_sections(feedback)

    (invalid_key_sections ++
       scalar_sections ++
       string_list_sections ++
       string_map_sections ++
       nested_sections ++
       array_sections ++
       realized_activity_sections)
    |> Enum.sort_by(&{&1["field"], Map.get(&1, "key", "")})
  end

  def invalid_sections(_feedback), do: []

  def key?(key), do: not is_nil(RowValues.stable_id_or_nil(key))

  def valid_source_string?(value) when is_binary(value), do: value != ""
  def valid_source_string?(value) when is_atom(value), do: not is_nil(value)
  def valid_source_string?(_value), do: false

  def normalize_resource_margin_aliases(%{} = value) do
    value
    |> RowValues.stringify_keys()
    |> copy_resource_margin_alias("storage_margin", "storage_capacity_margin")
    |> copy_resource_margin_alias("downlink_margin", "downlink_capacity_margin")
    |> copy_resource_margin_alias("battery_state_of_charge", "battery_soc")
    |> put_power_margin_from_battery_state_of_charge()
    |> normalize_resource_margin_values()
  end

  def resource_availability_boolean_value(value) when is_boolean(value), do: value

  def resource_availability_boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  def resource_availability_boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      value when value in @resource_availability_true_tokens -> true
      value when value in @resource_availability_false_tokens -> false
      _value -> nil
    end
  end

  def resource_availability_boolean_value(_value), do: nil

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

  defp normalize_feedback_factor_map(%{} = factors) do
    factors
    |> RowValues.stringify_keys()
    |> Enum.reduce(%{}, fn {key, value}, normalized ->
      case RowValues.numeric_value(value) do
        number when is_number(number) and number >= 0.0 and number <= 1.0 ->
          put_entry(normalized, key, number)

        _value ->
          normalized
      end
    end)
  end

  defp normalize_feedback_factor_map(_factors), do: %{}

  defp normalize_nonnegative_number_map(%{} = values) do
    values
    |> RowValues.stringify_keys()
    |> Enum.reduce(%{}, fn {key, value}, normalized ->
      case RowValues.numeric_value(value) do
        number when is_number(number) and number >= 0.0 ->
          put_entry(normalized, key, number)

        _value ->
          normalized
      end
    end)
  end

  defp normalize_nonnegative_number_map(_values), do: %{}

  defp normalize_string_list_map(%{} = values) do
    values
    |> RowValues.stringify_keys()
    |> Enum.reduce(%{}, fn {key, value}, normalized ->
      if key?(key) and is_list(value) and Enum.all?(value, &valid_source_string?/1) do
        sources =
          value
          |> Enum.map(&feedback_source_string/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
          |> Enum.sort()

        if sources == [] do
          normalized
        else
          put_entry(normalized, key, sources)
        end
      else
        normalized
      end
    end)
  end

  defp normalize_string_list_map(_values), do: %{}

  defp normalize_object_map(%{} = values) do
    values
    |> RowValues.stringify_keys()
    |> Enum.reduce(%{}, fn {key, value}, normalized ->
      if key?(key) and is_map(value) do
        put_entry(
          normalized,
          key,
          value |> RowValues.stringify_keys() |> RowValues.compact_nil_values()
        )
      else
        normalized
      end
    end)
  end

  defp normalize_object_map(_values), do: %{}

  defp normalize_string_map(%{} = values) do
    values
    |> RowValues.stringify_keys()
    |> Enum.reduce(%{}, fn {key, value}, normalized ->
      case feedback_source_string(value) do
        value when is_binary(value) and value != "" ->
          put_entry(normalized, key, value)

        _value ->
          normalized
      end
    end)
  end

  defp normalize_string_map(_values), do: %{}

  defp feedback_source_string(value) when is_binary(value) and value != "", do: value

  defp feedback_source_string(value) when is_atom(value) and not is_nil(value),
    do: Atom.to_string(value)

  defp feedback_source_string(_value), do: nil

  defp normalize_maneuver_execution_uncertainty_feedback_map(%{} = values) do
    values
    |> RowValues.stringify_keys()
    |> Enum.reduce(%{}, fn
      {key, %{} = value}, normalized ->
        put_entry(normalized, key, normalize_maneuver_execution_uncertainty_feedback(value))

      {_key, _value}, normalized ->
        normalized
    end)
  end

  defp normalize_maneuver_execution_uncertainty_feedback_map(_values), do: %{}

  defp normalize_maneuver_execution_uncertainty_feedback(%{} = value) do
    value = RowValues.stringify_keys(value)

    %{
      "execution_uncertainty_status" => Map.get(value, "execution_uncertainty_status"),
      "execution_uncertainty" => stringify_map_or_nil(Map.get(value, "execution_uncertainty")),
      "timing_3sigma_s" => RowValues.numeric_value(Map.get(value, "timing_3sigma_s")),
      "delta_v_3sigma_km_s" =>
        RowValues.numeric_triplet_or_nil(Map.get(value, "delta_v_3sigma_km_s")),
      "delta_v_3sigma_magnitude_km_s" =>
        RowValues.numeric_value(Map.get(value, "delta_v_3sigma_magnitude_km_s")),
      "execution_uncertainty_source" => Map.get(value, "execution_uncertainty_source")
    }
    |> RowValues.compact_nil_values()
  end

  defp stringify_map_or_nil(%{} = value), do: RowValues.stringify_keys(value)
  defp stringify_map_or_nil(_value), do: nil

  defp normalize_resource_margin_feedback_map(%{} = values) do
    values
    |> RowValues.stringify_keys()
    |> Enum.reduce(%{}, fn
      {key, %{} = value}, normalized ->
        put_entry(normalized, key, normalize_resource_margin_aliases(value))

      {_key, _value}, normalized ->
        normalized
    end)
  end

  defp normalize_resource_margin_feedback_map(_values), do: %{}

  defp copy_resource_margin_alias(value, canonical_key, alias_key) do
    value =
      if Map.has_key?(value, canonical_key) or not Map.has_key?(value, alias_key) do
        value
      else
        Map.put(value, canonical_key, Map.get(value, alias_key))
      end

    Map.delete(value, alias_key)
  end

  defp put_power_margin_from_battery_state_of_charge(value) do
    case {Map.get(value, "power_margin"),
          RowValues.numeric_value(Map.get(value, "battery_state_of_charge"))} do
      {nil, state_of_charge} when is_number(state_of_charge) ->
        Map.put(value, "power_margin", state_of_charge)

      _values ->
        value
    end
  end

  defp normalize_resource_margin_values(value) do
    Enum.reduce(
      [
        "fuel_margin",
        "power_margin",
        "storage_margin",
        "downlink_margin",
        "thermal_margin_c",
        "battery_capacity_wh",
        "battery_energy_used_wh",
        "battery_state_of_charge"
      ],
      value,
      fn field, normalized ->
        case {Map.get(normalized, field), RowValues.numeric_value(Map.get(normalized, field))} do
          {raw_value, number} when is_number(raw_value) and is_number(number) ->
            Map.put(normalized, field, number)

          {raw_value, number} when is_binary(raw_value) and is_number(number) ->
            Map.put(normalized, field, number)

          {raw_value, nil} when is_binary(raw_value) ->
            Map.delete(normalized, field)

          _value ->
            normalized
        end
      end
    )
  end

  defp normalize_resource_availability_feedback_map(%{} = values) do
    values
    |> RowValues.stringify_keys()
    |> Enum.reduce(%{}, fn
      {key, %{} = value}, normalized ->
        put_entry(normalized, key, normalize_resource_availability_aliases(value))

      {_key, _value}, normalized ->
        normalized
    end)
  end

  defp normalize_resource_availability_feedback_map(_values), do: %{}

  defp put_entry(map, key, value) do
    case RowValues.stable_id_or_nil(key) do
      nil -> map
      key -> Map.put(map, key, value)
    end
  end

  defp normalize_resource_availability_aliases(%{} = value) do
    value
    |> RowValues.stringify_keys()
    |> copy_resource_availability_aliases(@resource_availability_value_aliases)
    |> copy_boolean_resource_availability_aliases(@resource_availability_boolean_aliases)
    |> copy_resource_availability_status_aliases(@resource_availability_status_aliases)
    |> copy_resource_availability_alias("degraded", "degraded?")
    |> normalize_resource_availability_boolean_values()
  end

  defp normalize_resource_availability_boolean_values(value) do
    Enum.reduce(
      ["payload_available", "antenna_available", "spacecraft_available", "degraded"],
      value,
      fn field, normalized ->
        case resource_availability_boolean_value(Map.get(normalized, field)) do
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

  defp copy_resource_availability_aliases(value, aliases_by_field) do
    Enum.reduce(aliases_by_field, value, fn {canonical_key, aliases}, normalized ->
      Enum.reduce(aliases, normalized, fn alias_key, normalized ->
        copy_resource_availability_alias(normalized, canonical_key, alias_key)
      end)
    end)
  end

  defp copy_boolean_resource_availability_alias(value, canonical_key, alias_key) do
    alias_value = resource_availability_boolean_value(Map.get(value, alias_key))

    if Map.has_key?(value, canonical_key) or not is_boolean(alias_value) do
      value
    else
      value
      |> Map.put(canonical_key, alias_value)
      |> Map.delete(alias_key)
    end
  end

  defp copy_boolean_resource_availability_aliases(value, aliases_by_field) do
    Enum.reduce(aliases_by_field, value, fn {canonical_key, aliases}, normalized ->
      Enum.reduce(aliases, normalized, fn alias_key, normalized ->
        copy_boolean_resource_availability_alias(normalized, canonical_key, alias_key)
      end)
    end)
  end

  defp copy_resource_availability_status_alias(value, canonical_key, alias_key) do
    alias_value = resource_availability_boolean_value(Map.get(value, alias_key))

    if Map.has_key?(value, canonical_key) or not is_boolean(alias_value) do
      value
    else
      Map.put(value, canonical_key, alias_value)
    end
  end

  defp copy_resource_availability_status_aliases(value, aliases_by_field) do
    Enum.reduce(aliases_by_field, value, fn {canonical_key, aliases}, normalized ->
      Enum.reduce(aliases, normalized, fn alias_key, normalized ->
        copy_resource_availability_status_alias(normalized, canonical_key, alias_key)
      end)
    end)
  end

  defp invalid_key_sections(feedback, field) do
    case Map.get(feedback, field) do
      %{} = entries ->
        entries
        |> RowValues.stringify_keys()
        |> Enum.flat_map(fn {key, _value} ->
          if key?(key) do
            []
          else
            [
              %{
                "field" => field,
                "key" => invalid_key_label(key),
                "reason" => "key_must_be_stable_id"
              }
            ]
          end
        end)

      _entries ->
        []
    end
  end

  defp invalid_key_label(key) when is_binary(key), do: key
  defp invalid_key_label(key), do: inspect(key)

  defp invalid_array_sections(feedback, field) do
    if Map.has_key?(feedback, field) and not is_list(Map.get(feedback, field)) do
      [
        %{
          "field" => field,
          "reason" => "field_must_be_array",
          "invalid_feedback_shape" => RowValues.encode_value(Map.get(feedback, field))
        }
      ]
    else
      []
    end
  end

  defp invalid_field_sections(feedback, field) do
    if Map.has_key?(feedback, field) and not is_map(Map.get(feedback, field)) do
      [
        %{
          "field" => field,
          "reason" => "field_must_be_object",
          "invalid_feedback_shape" => RowValues.encode_value(Map.get(feedback, field))
        }
      ]
    else
      []
    end
  end

  defp invalid_field_sections(feedback, field, :number_entries) do
    cond do
      not Map.has_key?(feedback, field) ->
        []

      not is_map(Map.get(feedback, field)) ->
        invalid_field_sections(feedback, field)

      true ->
        feedback
        |> Map.fetch!(field)
        |> RowValues.stringify_keys()
        |> Enum.flat_map(fn {key, value} ->
          number = RowValues.numeric_value(value)

          cond do
            not key?(key) ->
              []

            is_number(number) and not unit_interval_field?(field) and number >= 0.0 ->
              []

            is_number(number) and number >= 0.0 and number <= 1.0 ->
              []

            is_number(number) and not unit_interval_field?(field) ->
              [
                %{
                  "field" => field,
                  "key" => key,
                  "reason" => "entry_must_be_nonnegative_number",
                  "invalid_feedback_shape" => RowValues.encode_value(value)
                }
              ]

            is_number(number) ->
              [
                %{
                  "field" => field,
                  "key" => key,
                  "reason" => "entry_must_be_unit_interval_number",
                  "invalid_feedback_shape" => RowValues.encode_value(value)
                }
              ]

            true ->
              [
                %{
                  "field" => field,
                  "key" => key,
                  "reason" => "entry_must_be_number",
                  "invalid_feedback_shape" => RowValues.encode_value(value)
                }
              ]
          end
        end)
    end
  end

  defp invalid_string_list_sections(feedback, field) do
    cond do
      not Map.has_key?(feedback, field) ->
        []

      not is_map(Map.get(feedback, field)) ->
        [
          %{
            "field" => field,
            "reason" => "field_must_be_object",
            "invalid_feedback_shape" => RowValues.encode_value(Map.get(feedback, field))
          }
        ]

      true ->
        feedback
        |> Map.fetch!(field)
        |> RowValues.stringify_keys()
        |> Enum.flat_map(fn
          {key, values} when is_list(values) ->
            if Enum.all?(values, &valid_source_string?/1) do
              []
            else
              [
                %{
                  "field" => field,
                  "key" => key,
                  "reason" => "entry_must_be_string_array",
                  "invalid_feedback_shape" => RowValues.encode_value(values)
                }
              ]
            end

          {key, value} ->
            [
              %{
                "field" => field,
                "key" => key,
                "reason" => "entry_must_be_string_array",
                "invalid_feedback_shape" => RowValues.encode_value(value)
              }
            ]
        end)
    end
  end

  defp invalid_string_sections(feedback, field) do
    cond do
      not Map.has_key?(feedback, field) ->
        []

      not is_map(Map.get(feedback, field)) ->
        [
          %{
            "field" => field,
            "reason" => "field_must_be_object",
            "invalid_feedback_shape" => RowValues.encode_value(Map.get(feedback, field))
          }
        ]

      true ->
        feedback
        |> Map.fetch!(field)
        |> RowValues.stringify_keys()
        |> Enum.flat_map(fn
          {_key, value} when is_binary(value) and value != "" ->
            []

          {_key, value} when is_atom(value) and not is_nil(value) ->
            []

          {key, value} ->
            [
              %{
                "field" => field,
                "key" => key,
                "reason" => "entry_must_be_string",
                "invalid_feedback_shape" => RowValues.encode_value(value)
              }
            ]
        end)
    end
  end

  defp invalid_nested_sections(feedback, field) do
    cond do
      not Map.has_key?(feedback, field) ->
        []

      not is_map(Map.get(feedback, field)) ->
        [
          %{
            "field" => field,
            "reason" => "field_must_be_object",
            "invalid_feedback_shape" => RowValues.encode_value(Map.get(feedback, field))
          }
        ]

      true ->
        feedback
        |> Map.fetch!(field)
        |> RowValues.stringify_keys()
        |> Enum.flat_map(fn
          {_key, %{}} ->
            []

          {key, value} ->
            [
              %{
                "field" => field,
                "key" => key,
                "reason" => "entry_must_be_object",
                "invalid_feedback_shape" => RowValues.encode_value(value)
              }
            ]
        end)
    end
  end

  defp unit_interval_field?(field)
       when field in [
              "contact_success_rate",
              "observation_success_rate",
              "maneuver_success_rate",
              "command_success_rate",
              "station_throughput_factor",
              "image_quality_score",
              "cloud_cover_fraction",
              "blur_score"
            ],
       do: true

  defp unit_interval_field?(_field), do: false
end
