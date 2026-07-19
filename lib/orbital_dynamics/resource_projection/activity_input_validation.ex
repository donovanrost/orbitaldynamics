defmodule OrbitalDynamics.ResourceProjection.ActivityInputValidation do
  @moduledoc false

  @actual_data_volume_paths [
    ["actual_data_volume_mb"],
    ["actual_storage_mb"],
    ["actual_downlink_mb"],
    ["delivered_data_mb"],
    ["received_data_mb"],
    ["metadata", "actual_data_volume_mb"],
    ["metadata", "actual_storage_mb"],
    ["metadata", "actual_downlink_mb"],
    ["metadata", "delivered_data_mb"],
    ["metadata", "received_data_mb"]
  ]

  def actual_data_volume_paths, do: @actual_data_volume_paths

  def completed_fraction_issue(activity) do
    activity
    |> completed_fraction_values()
    |> Enum.find_value(fn {field, value} ->
      case numeric_or_nil(value) do
        parsed when is_number(parsed) and parsed >= 0.0 and parsed <= 1.0 -> nil
        _value -> "invalid_#{field}"
      end
    end)
  end

  def capacity_fraction_issue(activity) do
    activity
    |> capacity_evidence_values()
    |> Enum.find_value(fn
      {:fraction, field, value} ->
        case numeric_or_nil(value) do
          parsed when is_number(parsed) and parsed >= 0.0 and parsed <= 1.0 -> nil
          _value -> "invalid_#{field}"
        end

      {:percent, field, value} ->
        case numeric_or_nil(value) do
          parsed when is_number(parsed) and parsed >= 0.0 and parsed <= 100.0 -> nil
          _value -> "invalid_#{field}"
        end
    end)
  end

  def latency_evidence_issue(activity) do
    activity
    |> latency_evidence_values()
    |> Enum.find_value(fn {field, value, validation} ->
      case numeric_or_nil(value) do
        parsed when is_number(parsed) and validation == :non_negative and parsed < 0.0 ->
          "negative_#{field}"

        parsed when is_number(parsed) ->
          nil

        nil when is_nil(value) ->
          nil

        _value ->
          "invalid_#{field}"
      end
    end)
  end

  def resource_quantity_issue(activity) do
    activity
    |> resource_quantity_values()
    |> Enum.find_value(fn {field, value} ->
      case numeric_or_nil(value) do
        parsed when is_number(parsed) and parsed < 0.0 -> "negative_#{field}"
        parsed when is_number(parsed) -> nil
        nil when is_nil(value) -> nil
        _value -> "invalid_#{field}"
      end
    end)
  end

  defp completed_fraction_values(activity) do
    top_level =
      for field <- ~w(completed_fraction completion_fraction),
          Map.has_key?(activity, field),
          do: {field, Map.get(activity, field)}

    metadata = Map.get(activity, "metadata")

    nested =
      if is_map(metadata) do
        for field <- ~w(completed_fraction completion_fraction),
            Map.has_key?(metadata, field),
            do: {field, Map.get(metadata, field)}
      else
        []
      end

    top_level ++ nested
  end

  defp capacity_evidence_values(activity) do
    [
      activity,
      activity["throughput_model"],
      activity["capacity_model"],
      activity["activity_context"],
      activity["source_contact_allocation"],
      get_in(activity, ["source_station_calendar_entry", "source_contact_allocation"])
    ]
    |> Enum.flat_map(&capacity_values/1)
    |> Kernel.++(capacity_values(activity["source_station_calendar_entry"]))
    |> Kernel.++(capacity_values(activity["source_station_calendar_overlaps"]))
  end

  defp capacity_values(values) when is_list(values),
    do: Enum.flat_map(values, &capacity_values/1)

  defp capacity_values(%{} = values) do
    fraction_values =
      for field <- ~w(station_capacity_fraction capacity_fraction),
          Map.has_key?(values, field),
          do: {:fraction, field, Map.get(values, field)}

    allocation_fraction_values =
      for field <- ~w(capacity_pack_capacity_fraction),
          Map.has_key?(values, field),
          do: {:fraction, field, Map.get(values, field)}

    percent_values =
      for field <- ~w(station_capacity_percent capacity_percent),
          Map.has_key?(values, field),
          do: {:percent, field, Map.get(values, field)}

    nested_values =
      [
        values["throughput_model"],
        values["capacity_model"],
        values["activity_context"],
        values["source_contact_allocation"]
      ]
      |> Enum.flat_map(&capacity_values/1)

    fraction_values ++ allocation_fraction_values ++ percent_values ++ nested_values
  end

  defp capacity_values(_values), do: []

  defp latency_evidence_values(activity) do
    top_level = latency_values(activity)
    metadata = latency_values(activity["metadata"])

    top_level ++ metadata
  end

  defp latency_values(%{} = values) do
    time_values =
      for field <-
            ~w(collection_ends_at_s collection_end_s planned_delivery_at_s expected_delivery_at_s delivery_at_s actual_delivery_at_s delivered_at_s),
          Map.has_key?(values, field),
          do: {field, Map.get(values, field), :number}

    duration_values =
      for field <- ~w(max_latency_s latency_requirement_s planned_latency_s actual_latency_s),
          Map.has_key?(values, field),
          do: {field, Map.get(values, field), :non_negative}

    time_values ++ duration_values
  end

  defp latency_values(_values), do: []

  defp resource_quantity_values(activity) do
    top_level =
      for field <- resource_quantity_fields(),
          Map.has_key?(activity, field),
          do: {field, Map.get(activity, field)}

    metadata = nested_resource_quantity_values(activity, "metadata")
    throughput_model = nested_resource_quantity_values(activity, "throughput_model")
    actual_data_volume = actual_data_volume_values(activity)

    top_level ++ metadata ++ throughput_model ++ actual_data_volume
  end

  defp actual_data_volume_values(activity) do
    @actual_data_volume_paths
    |> Enum.flat_map(fn path ->
      case present_path_value(activity, path) do
        {:ok, value} -> [{List.last(path), value}]
        :error -> []
      end
    end)
  end

  defp present_path_value(%{} = source, [field]) do
    if Map.has_key?(source, field), do: {:ok, Map.get(source, field)}, else: :error
  end

  defp present_path_value(%{} = source, [field | rest]) do
    case Map.get(source, field) do
      %{} = nested -> present_path_value(nested, rest)
      _value -> :error
    end
  end

  defp present_path_value(_source, _path), do: :error

  defp nested_resource_quantity_values(activity, key) do
    case Map.get(activity, key) do
      %{} = values ->
        for field <- resource_quantity_fields(),
            Map.has_key?(values, field),
            do: {field, Map.get(values, field)}

      _values ->
        []
    end
  end

  defp resource_quantity_fields do
    ~w(
      estimated_storage_mb
      planned_data_volume_mb
      data_volume_mb
      estimated_data_volume_mb
      capacity_adjusted_throughput_mb
      estimated_throughput_mb
      estimated_downlink_mb
      planned_throughput_mb
      estimated_energy_used_wh
      estimated_battery_energy_used_wh
      planned_energy_used_wh
      battery_energy_used_wh
      estimated_energy_generated_wh
      estimated_battery_energy_generated_wh
      planned_energy_generated_wh
      battery_energy_generated_wh
    )
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil
end
