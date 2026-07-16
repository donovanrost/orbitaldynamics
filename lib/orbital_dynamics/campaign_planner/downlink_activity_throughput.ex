defmodule OrbitalDynamics.CampaignPlanner.DownlinkActivityThroughput do
  @moduledoc false

  def mb(activity) do
    activity_capacity = numeric_or_nil(Map.get(activity, "capacity_adjusted_throughput_mb"))

    model_capacity =
      numeric_or_nil(get_in(activity, ["throughput_model", "capacity_adjusted_throughput_mb"]))

    cond do
      is_number(activity_capacity) ->
        activity_capacity * 1.0

      is_number(model_capacity) ->
        model_capacity * 1.0

      true ->
        throughput_mb =
          numeric_or_nil(Map.get(activity, "estimated_throughput_mb")) ||
            numeric_or_nil(Map.get(activity, "planned_throughput_mb")) || 0.0

        station_capacity_fraction =
          numeric_or_nil(get_in(activity, ["throughput_model", "station_capacity_fraction"])) ||
            numeric_or_nil(Map.get(activity, "station_capacity_fraction")) || 1.0

        throughput_mb * station_capacity_fraction
    end
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil
end
