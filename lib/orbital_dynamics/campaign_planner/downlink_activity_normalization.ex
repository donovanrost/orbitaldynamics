defmodule OrbitalDynamics.CampaignPlanner.DownlinkActivityNormalization do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ActivityTiming, CollectionLatencyIdentity, ScalarValues}

  def proposed_contacts(candidates), do: proposed_contacts(candidates, callbacks())

  def proposed_contacts(candidates, callbacks) do
    candidates
    |> Enum.map(&normalize(&1, callbacks))
    |> Enum.filter(&downlink?(&1, callbacks))
    |> Enum.filter(&valid_proposed_contact?/1)
    |> Enum.map(&proposed_contact_row/1)
  end

  def normalize(activity), do: normalize(activity, callbacks())

  def normalize(%{} = activity, callbacks) do
    activity
    |> normalize_activity_type_alias()
    |> normalize_activity_station_id(callbacks)
    |> normalize_activity_data_identity()
    |> normalize_activity_time("starts_at_s", "start_s", callbacks)
    |> normalize_activity_time("ends_at_s", "end_s", callbacks)
    |> normalize_activity_number("estimated_throughput_mb", callbacks)
    |> normalize_activity_number("planned_throughput_mb", callbacks)
    |> normalize_activity_number("capacity_adjusted_throughput_mb", callbacks)
    |> normalize_activity_number("station_capacity_fraction", callbacks)
    |> normalize_activity_number("score", callbacks)
    |> normalize_activity_throughput_model(callbacks)
    |> normalize_inferred_provider_downlink(callbacks)
  end

  def normalize(activity, _callbacks), do: activity

  def downlink?(activity), do: downlink?(activity, callbacks())

  def downlink?(%{"type" => "downlink"}, _callbacks), do: true
  def downlink?(%{"type" => "planned_contact", "direction" => "downlink"}, _callbacks), do: true
  def downlink?(%{"type" => "contact", "direction" => "downlink"}, _callbacks), do: true
  def downlink?(activity, callbacks), do: provider_downlink_activity?(activity, callbacks)

  def command_feedback?(activity) do
    Map.has_key?(activity, "command_success") or Map.has_key?(activity, "command_result")
  end

  defp proposed_contact_row(activity) do
    activity
    |> Map.put("type", "downlink")
    |> Map.put("direction", "downlink")
  end

  defp valid_proposed_contact?(activity) do
    not is_nil(Map.get(activity, "id")) and
      not is_nil(Map.get(activity, "scenario_id")) and
      not is_nil(Map.get(activity, "ground_station_id")) and
      is_number(Map.get(activity, "starts_at_s")) and
      is_number(Map.get(activity, "ends_at_s")) and
      is_number(Map.get(activity, "estimated_throughput_mb")) and
      is_map(Map.get(activity, "source_window")) and
      is_map(Map.get(activity, "cadence_import"))
  end

  defp normalize_activity_station_id(%{"ground_station_id" => station_id} = activity, _callbacks)
       when not is_nil(station_id),
       do: activity

  defp normalize_activity_station_id(%{"station_id" => station_id} = activity, _callbacks)
       when not is_nil(station_id),
       do: Map.put(activity, "ground_station_id", station_id)

  defp normalize_activity_station_id(activity, _callbacks) do
    case nested_ground_station_id(activity) do
      nil -> activity
      station_id -> Map.put(activity, "ground_station_id", station_id)
    end
  end

  defp normalize_activity_data_identity(activity) do
    activity
    |> put_activity_identity_field("collection_id", CollectionLatencyIdentity.collection_keys())
    |> put_activity_identity_field("product_id", CollectionLatencyIdentity.product_keys())
    |> put_activity_product_ids()
    |> put_activity_identity_field("payload_id", CollectionLatencyIdentity.payload_keys())
    |> put_activity_identity_field("instrument_id", CollectionLatencyIdentity.instrument_keys())
  end

  defp put_activity_identity_field(activity, field, keys) do
    case Map.get(activity, field) do
      value when value not in [nil, ""] ->
        activity

      _value ->
        case CollectionLatencyIdentity.selector_values(activity, keys) do
          [] -> activity
          [value | _values] -> Map.put(activity, field, value)
        end
    end
  end

  defp put_activity_product_ids(activity) do
    if Map.has_key?(activity, "product_ids") do
      activity
    else
      values =
        CollectionLatencyIdentity.selector_values(activity, [
          "product_ids",
          "data_product_ids",
          "products",
          "data_products"
        ])

      case values do
        [] -> activity
        values -> Map.put(activity, "product_ids", values)
      end
    end
  end

  def nested_ground_station_id(activity) do
    Enum.find_value(["ground_station", "station", :ground_station, :station], fn station_key ->
      case Map.get(activity, station_key) do
        %{} = station ->
          Enum.find_value(
            ["ground_station_id", "station_id", "id", :ground_station_id, :station_id, :id],
            fn identity_key -> Map.get(station, identity_key) end
          )

        _station ->
          nil
      end
    end)
  end

  defp normalize_activity_time(activity, canonical_key, alternate_key, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    case {numeric_or_nil.(Map.get(activity, canonical_key)),
          numeric_or_nil.(Map.get(activity, alternate_key))} do
      {value, _alternate} when is_number(value) -> Map.put(activity, canonical_key, value)
      {nil, value} when is_number(value) -> Map.put(activity, canonical_key, value)
      _values -> activity
    end
  end

  defp normalize_activity_number(activity, key, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    case numeric_or_nil.(Map.get(activity, key)) do
      value when is_number(value) -> Map.put(activity, key, value)
      _value -> activity
    end
  end

  defp normalize_activity_throughput_model(
         %{"throughput_model" => %{} = throughput_model} = activity,
         callbacks
       ) do
    throughput_model =
      throughput_model
      |> normalize_activity_number("estimated_throughput_mb", callbacks)
      |> normalize_activity_number("planned_throughput_mb", callbacks)
      |> normalize_activity_number("capacity_adjusted_throughput_mb", callbacks)
      |> normalize_activity_number("station_capacity_fraction", callbacks)
      |> normalize_activity_number("required_downlink_mb", callbacks)

    Map.put(activity, "throughput_model", throughput_model)
  end

  defp normalize_activity_throughput_model(activity, _callbacks), do: activity

  defp normalize_inferred_provider_downlink(activity, callbacks) do
    if provider_downlink_activity?(activity, callbacks) do
      activity
      |> Map.put_new("type", "downlink")
      |> Map.put_new("direction", "downlink")
    else
      activity
    end
  end

  defp normalize_activity_type_alias(%{"type" => type} = activity) when not is_nil(type),
    do: activity

  defp normalize_activity_type_alias(%{"activity_type" => type} = activity)
       when is_binary(type) and type != "",
       do: Map.put(activity, "type", type)

  defp normalize_activity_type_alias(activity), do: activity

  defp provider_downlink_activity?(activity, callbacks) do
    activity_ground_station_id = Keyword.fetch!(callbacks, :activity_ground_station_id)
    activity_raw_start = Keyword.fetch!(callbacks, :activity_raw_start)
    activity_raw_end = Keyword.fetch!(callbacks, :activity_raw_end)
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    direction = activity_direction(activity)

    type in [nil, "contact", "planned_contact"] and
      direction in [nil, "downlink"] and
      not command_feedback?(activity) and
      not is_nil(activity_ground_station_id.(activity)) and
      is_number(activity_raw_start.(activity)) and
      is_number(activity_raw_end.(activity))
  end

  defp activity_direction(activity), do: normalized_status_token(Map.get(activity, "direction"))

  defp normalized_status_token(nil), do: nil

  defp normalized_status_token(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> normalized_status_token()
  end

  defp normalized_status_token(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalized_status_token(status), do: status

  defp callbacks,
    do: [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      activity_ground_station_id: &activity_ground_station_id/1,
      activity_raw_start: &ActivityTiming.activity_raw_start/1,
      activity_raw_end: &ActivityTiming.activity_raw_end/1
    ]

  defp activity_ground_station_id(activity) do
    Map.get(activity, "ground_station_id") || Map.get(activity, "station_id") ||
      nested_ground_station_id(activity)
  end
end
