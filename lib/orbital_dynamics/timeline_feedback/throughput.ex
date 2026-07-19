defmodule OrbitalDynamics.TimelineFeedback.Throughput do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{ExecutionUncertainty, RealizedIdentity}

  def first_number(map, keys) do
    Enum.find_value(keys, fn key ->
      value =
        case key do
          path when is_list(path) -> get_in(map, path)
          key -> RealizedIdentity.first_value(map, [key])
        end

      ExecutionUncertainty.numeric_value(value)
    end)
  end

  def planned_data_volume_mb(activity) do
    first_number(activity, [
      "planned_data_volume_mb",
      "data_volume_mb",
      "estimated_data_volume_mb",
      "estimated_storage_mb",
      "estimated_downlink_mb"
    ])
  end

  def actual_data_volume_mb(activity) do
    first_number(activity, [
      "actual_data_volume_mb",
      "actual_storage_mb",
      "actual_downlink_mb",
      "delivered_data_mb",
      "received_data_mb"
    ])
  end

  def data_rate_mbps(activity) do
    first_number(activity, [
      "data_rate_mbps",
      "downlink_rate_mbps",
      "actual_data_rate_mbps",
      "actual_downlink_rate_mbps",
      ["link", "data_rate_mbps"],
      ["link", "downlink_rate_mbps"],
      ["communications", "data_rate_mbps"],
      ["communications", "downlink_rate_mbps"],
      ["throughput_model", "data_rate_mbps"],
      ["throughput_model", "downlink_rate_mbps"],
      ["throughput_model", "actual_data_rate_mbps"],
      ["throughput_model", "actual_downlink_rate_mbps"],
      ["metadata", "data_rate_mbps"],
      ["metadata", "downlink_rate_mbps"]
    ]) || data_rate_mb_s(activity)
  end

  def actual_throughput_mb(activity) do
    explicit_actual_throughput_mb(activity) || actual_data_rate_derived_throughput_mb(activity)
  end

  def actual_data_rate_throughput_derivation(activity) do
    duration_s = actual_duration_s(activity)

    cond do
      is_number(explicit_actual_throughput_mb(activity)) ->
        nil

      not is_number(duration_s) or duration_s <= 0.0 ->
        nil

      rate_mb_s = actual_data_rate_mb_s(activity) ->
        %{
          "derivation" => "actual_data_rate_times_duration",
          "rate_unit" => "MB/s",
          "actual_data_rate_mb_s" => rate_mb_s,
          "duration_s" => duration_s,
          "actual_throughput_mb" => rate_mb_s * duration_s
        }

      rate_mbps = actual_data_rate_mbps(activity) ->
        rate_mb_s = rate_mbps / 8.0

        %{
          "derivation" => "actual_data_rate_times_duration",
          "rate_unit" => "Mbps",
          "actual_data_rate_mbps" => rate_mbps,
          "actual_data_rate_mb_s" => rate_mb_s,
          "duration_s" => duration_s,
          "actual_throughput_mb" => rate_mb_s * duration_s
        }

      true ->
        nil
    end
  end

  def derived_throughput_completion_fraction(row) do
    actual_throughput_mb = actual_throughput_mb(row)

    denominator =
      first_number(row, [
        "planned_estimated_throughput_mb",
        "estimated_throughput_mb",
        "required_downlink_mb",
        ["throughput_model", "estimated_throughput_mb"],
        ["throughput_model", "required_downlink_mb"]
      ])

    if is_number(actual_throughput_mb) and is_number(denominator) and denominator > 0.0 do
      actual_throughput_mb / denominator
    end
  end

  def reconciliation_context(planned, realized) do
    planned_throughput = value(planned, "estimated_throughput_mb")

    throughput_denominator =
      planned_throughput || value(planned, "required_downlink_mb") ||
        value(realized, "required_downlink_mb")

    actual_throughput = value(realized, "actual_throughput_mb")
    planned_data_volume_mb = value(planned, "planned_data_volume_mb")
    actual_data_volume_mb = value(realized, "actual_data_volume_mb")

    %{
      "planned_estimated_throughput_mb" => planned_throughput,
      "actual_throughput_mb" => actual_throughput,
      "actual_data_rate_throughput_derivation" =>
        value(realized, "actual_data_rate_throughput_derivation"),
      "throughput_delta_mb" => delta(actual_throughput, planned_throughput),
      "throughput_completion_fraction" =>
        throughput_fraction(actual_throughput, throughput_denominator),
      "planned_data_volume_mb" => planned_data_volume_mb,
      "actual_data_volume_mb" => actual_data_volume_mb,
      "data_volume_delta_mb" => delta(actual_data_volume_mb, planned_data_volume_mb),
      "data_volume_completion_fraction" =>
        throughput_fraction(actual_data_volume_mb, planned_data_volume_mb),
      "required_downlink_mb" =>
        value(planned, "required_downlink_mb") || value(realized, "required_downlink_mb")
    }
  end

  defp data_rate_mb_s(activity) do
    case first_number(activity, [
           "data_rate_mb_s",
           "downlink_rate_mb_s",
           "actual_data_rate_mb_s",
           "actual_downlink_rate_mb_s",
           ["link", "data_rate_mb_s"],
           ["link", "downlink_rate_mb_s"],
           ["communications", "data_rate_mb_s"],
           ["communications", "downlink_rate_mb_s"],
           ["throughput_model", "data_rate_mb_s"],
           ["throughput_model", "downlink_rate_mb_s"],
           ["throughput_model", "actual_data_rate_mb_s"],
           ["throughput_model", "actual_downlink_rate_mb_s"],
           ["metadata", "data_rate_mb_s"],
           ["metadata", "downlink_rate_mb_s"]
         ]) do
      value when is_number(value) -> value * 8.0
      _value -> nil
    end
  end

  defp explicit_actual_throughput_mb(activity) do
    first_number(activity, [
      "actual_throughput_mb",
      "actual_downlink_mb",
      "actual_data_volume_mb",
      "delivered_data_mb",
      "received_data_mb",
      ["throughput_model", "actual_throughput_mb"],
      ["throughput_model", "actual_downlink_mb"],
      ["throughput_model", "actual_data_volume_mb"],
      ["throughput_model", "delivered_data_mb"],
      ["throughput_model", "received_data_mb"]
    ])
  end

  defp actual_data_rate_derived_throughput_mb(activity) do
    case actual_data_rate_throughput_derivation(activity) do
      %{"actual_throughput_mb" => actual_throughput_mb} when is_number(actual_throughput_mb) ->
        actual_throughput_mb

      _derivation ->
        nil
    end
  end

  defp actual_data_rate_mb_s(activity) do
    first_number(activity, [
      "actual_data_rate_mb_s",
      "actual_downlink_rate_mb_s",
      "delivered_rate_mb_s",
      "received_rate_mb_s",
      ["throughput_model", "actual_data_rate_mb_s"],
      ["throughput_model", "actual_downlink_rate_mb_s"],
      ["throughput_model", "delivered_rate_mb_s"],
      ["throughput_model", "received_rate_mb_s"]
    ])
  end

  defp actual_data_rate_mbps(activity) do
    first_number(activity, [
      "actual_data_rate_mbps",
      "actual_downlink_rate_mbps",
      "delivered_rate_mbps",
      "received_rate_mbps",
      ["throughput_model", "actual_data_rate_mbps"],
      ["throughput_model", "actual_downlink_rate_mbps"],
      ["throughput_model", "delivered_rate_mbps"],
      ["throughput_model", "received_rate_mbps"]
    ])
  end

  defp actual_duration_s(activity) do
    first_number(activity, [
      "actual_duration_s",
      "actual_contact_duration_s",
      "contact_duration_s",
      "duration_s",
      ["throughput_model", "actual_duration_s"],
      ["throughput_model", "actual_contact_duration_s"],
      ["throughput_model", "contact_duration_s"],
      ["throughput_model", "duration_s"]
    ]) || interval_duration_s(activity)
  end

  defp interval_duration_s(activity) do
    start_s =
      first_number(activity, [
        "actual_starts_at_s",
        "actual_start_s",
        "starts_at_s",
        "start_s"
      ])

    end_s =
      first_number(activity, [
        "actual_ends_at_s",
        "actual_end_s",
        "ends_at_s",
        "end_s"
      ])

    if is_number(start_s) and is_number(end_s) and end_s > start_s do
      end_s - start_s
    end
  end

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)

  defp delta(actual, planned) when is_number(actual) and is_number(planned), do: actual - planned
  defp delta(_actual, _planned), do: nil

  defp throughput_fraction(actual, planned)
       when is_number(actual) and is_number(planned) and planned > 0.0 do
    actual / planned
  end

  defp throughput_fraction(_actual, _planned), do: nil
end
