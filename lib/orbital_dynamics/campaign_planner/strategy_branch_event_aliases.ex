defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchEventAliases do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchOperationalFeedback,
    OperationalFeedbackNormalization,
    ScalarValues,
    ValueEncoding
  }

  @resource_availability_true_tokens ~w(true 1 yes y available nominal operational enabled)
  @resource_availability_false_tokens ~w(false 0 no n unavailable offline down outage maintenance disabled)

  def normalize(event), do: normalize(event, callbacks())

  def normalize(%{"type" => "resource_margin_pressure"} = event, callbacks) do
    normalize_resource_margin_aliases =
      Keyword.fetch!(callbacks, :normalize_resource_margin_aliases)

    event = normalize_resource_margin_aliases.(event)

    field =
      canonical_resource_margin_field(event["resource_field"]) ||
        resource_margin_event_field(event, callbacks)

    if field do
      event
      |> Map.put("resource_field", field)
      |> normalize_resource_margin_threshold_alias(field)
    else
      event
    end
  end

  def normalize(%{"type" => "resource_availability_constraint"} = event, callbacks) do
    normalize_resource_availability_aliases =
      Keyword.fetch!(callbacks, :normalize_resource_availability_aliases)

    event = normalize_resource_availability_aliases.(event)

    field =
      canonical_resource_availability_field(event["resource_field"]) ||
        resource_availability_event_field(event)

    if field do
      event
      |> Map.put("resource_field", field)
      |> normalize_resource_availability_event_value(field, callbacks)
    else
      event
    end
  end

  def normalize(%{"type" => "degraded_spacecraft"} = event, callbacks) do
    normalize_resource_availability_aliases =
      Keyword.fetch!(callbacks, :normalize_resource_availability_aliases)

    degraded_event_mode = Keyword.fetch!(callbacks, :degraded_event_mode)
    degradation_activity_types = Keyword.fetch!(callbacks, :degradation_activity_types)

    normalize_incompatible_activity_types =
      Keyword.fetch!(callbacks, :normalize_incompatible_activity_types)

    event = normalize_resource_availability_aliases.(event)

    event
    |> Map.put("mode", degraded_event_mode.(event))
    |> Map.put(
      "incompatible_activity_types",
      event
      |> degradation_activity_types.()
      |> normalize_incompatible_activity_types.()
    )
    |> Map.delete("suppressed_activity_types")
  end

  def normalize(%{"type" => "observation_success_feedback"} = event, callbacks) do
    event
    |> normalize_observation_quality_event_fields(callbacks)
    |> put_observation_success_factor_from_quality(callbacks)
  end

  def normalize(event, _callbacks), do: event

  defp normalize_observation_quality_event_fields(event, callbacks) do
    image_quality_score =
      first_numeric_field(
        event,
        [
          "image_quality_score",
          "product_quality_score",
          "quality_score"
        ],
        callbacks
      )

    image_quality_status =
      first_encoded_field(
        event,
        [
          "image_quality_status",
          "product_quality_status",
          "quality_status"
        ],
        callbacks
      )

    image_quality_source =
      first_encoded_field(
        event,
        [
          "image_quality_source",
          "product_quality_source",
          "quality_source"
        ],
        callbacks
      )

    cloud_cover_fraction =
      first_numeric_field(
        event,
        [
          "cloud_cover_fraction",
          "cloud_fraction",
          "cloud_cover"
        ],
        callbacks
      )

    blur_score =
      first_numeric_field(
        event,
        [
          "blur_score",
          "image_blur_score",
          "sharpness_loss_fraction"
        ],
        callbacks
      )

    event
    |> drop_fields([
      "product_quality_score",
      "quality_score",
      "product_quality_status",
      "quality_status",
      "product_quality_source",
      "quality_source",
      "cloud_fraction",
      "cloud_cover",
      "image_blur_score",
      "sharpness_loss_fraction"
    ])
    |> put_optional_number("image_quality_score", image_quality_score)
    |> put_optional_string("image_quality_status", image_quality_status)
    |> put_optional_string("image_quality_source", image_quality_source)
    |> put_optional_number("cloud_cover_fraction", cloud_cover_fraction)
    |> put_optional_number("blur_score", blur_score)
  end

  defp put_observation_success_factor_from_quality(event, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    cond do
      is_number(numeric_or_nil.(event["observation_success_factor"])) ->
        event

      is_number(event["image_quality_score"]) ->
        event
        |> Map.put("observation_success_factor", event["image_quality_score"])
        |> Map.put_new("feedback_source", "branch_event.image_quality_score")

      true ->
        event
    end
  end

  defp first_numeric_field(map, fields, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    fields
    |> Enum.map(&numeric_or_nil.(Map.get(map, &1)))
    |> Enum.find(&is_number/1)
  end

  defp first_encoded_field(map, fields, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    fields
    |> Enum.map(&(map |> Map.get(&1) |> encode_value.()))
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  defp drop_fields(map, fields), do: Enum.reduce(fields, map, &Map.delete(&2, &1))

  defp put_optional_number(map, _field, value) when not is_number(value), do: map
  defp put_optional_number(map, field, value), do: Map.put(map, field, value)

  defp put_optional_string(map, _field, value) when value in [nil, ""], do: map
  defp put_optional_string(map, field, value), do: Map.put(map, field, value)

  defp canonical_resource_margin_field("downlink_capacity_margin"), do: "downlink_margin"
  defp canonical_resource_margin_field("battery_state_of_charge"), do: "power_margin"
  defp canonical_resource_margin_field("storage_capacity_margin"), do: "storage_margin"
  defp canonical_resource_margin_field("battery_soc"), do: "power_margin"

  defp canonical_resource_margin_field(field)
       when field in [
              "fuel_margin",
              "power_margin",
              "storage_margin",
              "downlink_margin",
              "thermal_margin_c"
            ],
       do: field

  defp canonical_resource_margin_field(_field), do: nil

  defp resource_margin_event_field(event, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    Enum.find(
      ["fuel_margin", "power_margin", "storage_margin", "downlink_margin", "thermal_margin_c"],
      &(event |> Map.get(&1) |> numeric_or_nil.() |> is_number())
    )
  end

  defp normalize_resource_margin_threshold_alias(event, "downlink_margin") do
    if Map.has_key?(event, "downlink_margin_threshold") or
         not Map.has_key?(event, "downlink_capacity_margin_threshold") do
      event
    else
      event
      |> Map.put("downlink_margin_threshold", event["downlink_capacity_margin_threshold"])
      |> Map.delete("downlink_capacity_margin_threshold")
    end
  end

  defp normalize_resource_margin_threshold_alias(event, "storage_margin") do
    if Map.has_key?(event, "storage_margin_threshold") or
         not Map.has_key?(event, "storage_capacity_margin_threshold") do
      event
    else
      event
      |> Map.put("storage_margin_threshold", event["storage_capacity_margin_threshold"])
      |> Map.delete("storage_capacity_margin_threshold")
    end
  end

  defp normalize_resource_margin_threshold_alias(event, "power_margin") do
    battery_threshold =
      cond do
        Map.has_key?(event, "battery_state_of_charge_threshold") ->
          {"battery_state_of_charge_threshold", event["battery_state_of_charge_threshold"]}

        Map.has_key?(event, "battery_soc_threshold") ->
          {"battery_soc_threshold", event["battery_soc_threshold"]}

        true ->
          nil
      end

    if Map.has_key?(event, "power_margin_threshold") or is_nil(battery_threshold) do
      event
    else
      {alias_key, value} = battery_threshold

      event
      |> Map.put("power_margin_threshold", value)
      |> Map.delete(alias_key)
    end
  end

  defp normalize_resource_margin_threshold_alias(event, _field), do: event

  defp canonical_resource_availability_field("payload_available?"), do: "payload_available"
  defp canonical_resource_availability_field("antenna_available?"), do: "antenna_available"
  defp canonical_resource_availability_field("spacecraft_available?"), do: "spacecraft_available"

  defp canonical_resource_availability_field("spacecraft_availability"),
    do: "spacecraft_available"

  defp canonical_resource_availability_field(field)
       when field in ["payload_available", "antenna_available", "spacecraft_available"],
       do: field

  defp canonical_resource_availability_field(_field), do: nil

  defp resource_availability_event_field(event) do
    Enum.find(
      ["payload_available", "antenna_available", "spacecraft_available"],
      &is_boolean(event[&1])
    )
  end

  defp normalize_resource_availability_event_value(event, field, callbacks) do
    resource_availability_boolean_value =
      Keyword.fetch!(callbacks, :resource_availability_boolean_value)

    case resource_availability_boolean_value.(event["available"]) do
      value when is_boolean(value) ->
        Map.put(event, "available", value)

      nil ->
        case event[field] do
          value when is_boolean(value) -> Map.put(event, "available", value)
          _value -> event
        end
    end
  end

  defp callbacks,
    do: [
      normalize_resource_margin_aliases: &normalize_resource_margin_aliases/1,
      normalize_resource_availability_aliases: &normalize_resource_availability_aliases/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      encode_value: &ValueEncoding.encode_value/1,
      resource_availability_boolean_value: &resource_availability_boolean_value/1,
      degraded_event_mode: &degraded_event_mode/1,
      degradation_activity_types: &degradation_activity_types/1,
      normalize_incompatible_activity_types:
        &BranchOperationalFeedback.normalize_incompatible_activity_types/1
    ]

  defp normalize_resource_margin_aliases(value) do
    OperationalFeedbackNormalization.normalize_resource_margin_aliases(
      value,
      operational_feedback_normalization_callbacks()
    )
  end

  defp normalize_resource_availability_aliases(value) do
    OperationalFeedbackNormalization.normalize_resource_availability_aliases(
      value,
      operational_feedback_normalization_callbacks()
    )
  end

  defp resource_availability_boolean_value(value) do
    OperationalFeedbackNormalization.resource_availability_boolean_value(
      value,
      operational_feedback_normalization_callbacks()
    )
  end

  defp operational_feedback_normalization_callbacks,
    do: [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      compact_map: &ValueEncoding.compact_map/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens
    ]

  defp degraded_event_mode(event) do
    case ValueEncoding.encode_value(Map.get(event, "mode", "degraded")) do
      value when value in [nil, ""] -> "degraded"
      value -> value
    end
  end

  defp degradation_activity_types(degradation) do
    explicit =
      Map.get(degradation, "incompatible_activity_types") ||
        Map.get(degradation, "suppressed_activity_types")

    cond do
      explicit not in [nil, []] ->
        explicit

      Map.get(degradation, "spacecraft_available") == false or
          Map.get(degradation, "spacecraft_availability") == false ->
        ["downlink", "observe", "planned_contact"]

      true ->
        ["observe"]
    end
  end
end
