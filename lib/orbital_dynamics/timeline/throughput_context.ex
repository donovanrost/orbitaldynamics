defmodule OrbitalDynamics.Timeline.ThroughputContext do
  @moduledoc false

  def build(activity, callbacks) when is_list(callbacks) do
    planned = planned_estimated_throughput_mb(activity, callbacks)
    derivation = actual_data_rate_throughput_derivation(activity, callbacks)

    actual =
      actual_throughput_mb(activity, callbacks) ||
        get_in(derivation || %{}, ["actual_throughput_mb"])

    %{
      "planned_estimated_throughput_mb" => planned,
      "actual_throughput_mb" => actual,
      "actual_data_rate_throughput_derivation" => derivation,
      "throughput_delta_mb" => delta(actual, planned, callbacks),
      "throughput_completion_fraction" => completion_fraction(actual, planned, callbacks)
    }
    |> compact_map(callbacks)
  end

  defp planned_estimated_throughput_mb(activity, callbacks) do
    first_number(
      activity,
      [
        "planned_estimated_throughput_mb",
        "estimated_throughput_mb",
        "estimated_downlink_mb"
      ],
      callbacks
    )
  end

  defp actual_throughput_mb(activity, callbacks) do
    first_number(
      activity,
      [
        "actual_throughput_mb",
        "actual_downlink_mb",
        "delivered_throughput_mb",
        "received_throughput_mb"
      ],
      callbacks
    )
  end

  defp actual_data_rate_throughput_derivation(activity, callbacks) do
    cond do
      is_map(first_value(activity, ["actual_data_rate_throughput_derivation"], callbacks)) ->
        activity
        |> first_value(["actual_data_rate_throughput_derivation"], callbacks)
        |> stringify_keys(callbacks)

      not is_nil(actual_throughput_mb(activity, callbacks)) ->
        nil

      true ->
        derive_actual_data_rate_throughput(activity, callbacks)
    end
  end

  defp derive_actual_data_rate_throughput(activity, callbacks) do
    duration_s = actual_data_rate_duration_s(activity, callbacks)

    cond do
      rate_mb_s = actual_data_rate_mb_s(activity, callbacks) ->
        actual_data_rate_derivation("actual_data_rate_mb_s", rate_mb_s, duration_s)

      rate_mbps = actual_data_rate_mbps(activity, callbacks) ->
        actual_data_rate_derivation("actual_data_rate_mbps", rate_mbps, duration_s)

      true ->
        nil
    end
  end

  defp actual_data_rate_derivation(_rate_unit, _rate, nil), do: nil

  defp actual_data_rate_derivation("actual_data_rate_mb_s", rate_mb_s, duration_s) do
    %{
      "derivation" => "actual_data_rate_times_duration",
      "rate_unit" => "MB/s",
      "actual_data_rate_mb_s" => rate_mb_s,
      "duration_s" => duration_s,
      "actual_throughput_mb" => rate_mb_s * duration_s
    }
  end

  defp actual_data_rate_derivation("actual_data_rate_mbps", rate_mbps, duration_s) do
    rate_mb_s = rate_mbps / 8.0

    %{
      "derivation" => "actual_data_rate_times_duration",
      "rate_unit" => "Mbps",
      "actual_data_rate_mbps" => rate_mbps,
      "actual_data_rate_mb_s" => rate_mb_s,
      "duration_s" => duration_s,
      "actual_throughput_mb" => rate_mb_s * duration_s
    }
  end

  defp actual_data_rate_mb_s(activity, callbacks) do
    first_number(
      activity,
      [
        "actual_data_rate_mb_s",
        "actual_downlink_rate_mb_s",
        "delivered_rate_mb_s",
        "received_rate_mb_s"
      ],
      callbacks
    )
  end

  defp actual_data_rate_mbps(activity, callbacks) do
    first_number(
      activity,
      [
        "actual_data_rate_mbps",
        "actual_downlink_rate_mbps",
        "delivered_rate_mbps",
        "received_rate_mbps"
      ],
      callbacks
    )
  end

  defp actual_data_rate_duration_s(activity, callbacks) do
    first_number(
      activity,
      [
        "actual_duration_s",
        "actual_contact_duration_s",
        "contact_duration_s"
      ],
      callbacks
    )
  end

  defp first_number(value, fields, callbacks),
    do: apply(Keyword.fetch!(callbacks, :first_number), [value, fields])

  defp first_value(value, fields, callbacks),
    do: apply(Keyword.fetch!(callbacks, :first_value), [value, fields])

  defp stringify_keys(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :stringify_keys), [value])

  defp delta(actual, planned, callbacks),
    do: apply(Keyword.fetch!(callbacks, :delta), [actual, planned])

  defp completion_fraction(actual, planned, callbacks),
    do: apply(Keyword.fetch!(callbacks, :completion_fraction), [actual, planned])

  defp compact_map(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :compact_map), [value])
end
