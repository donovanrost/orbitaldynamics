defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffStationThroughputFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffStationThroughputAmountFields

  def threshold(row, policy, callbacks) do
    [
      row["station_throughput_feedback_threshold"],
      row["replacement_station_throughput_feedback_threshold"],
      get_in(row, ["replacement_activity_context", "station_throughput_feedback_threshold"]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "station_throughput_feedback_threshold"
      ]),
      row["source_station_throughput_feedback_threshold"],
      get_in(row, ["source_activity_context", "station_throughput_feedback_threshold"]),
      get_in(row, [
        "source_activity_context",
        "throughput_model",
        "station_throughput_feedback_threshold"
      ])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) ->
        value

      _value ->
        callback!(callbacks, :numeric_policy_value).(
          policy,
          "station_throughput_feedback_threshold",
          0.8
        )
    end
  end

  def factor(row, callbacks) do
    [
      row["station_throughput_factor"],
      row["replacement_station_throughput_factor"],
      get_in(row, ["replacement_activity_context", "station_throughput_factor"]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "station_throughput_factor"
      ]),
      row["source_station_throughput_factor"],
      get_in(row, ["source_activity_context", "station_throughput_factor"]),
      get_in(row, ["source_activity_context", "throughput_model", "station_throughput_factor"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) ->
        callback!(callbacks, :clamp_unit_interval).(value)

      _value ->
        actual = actual_mb(row, callbacks)
        expected = expected_mb(row, callbacks)

        if is_number(actual) and is_number(expected) and expected > 0.0 do
          actual
          |> Kernel./(expected)
          |> callback!(callbacks, :clamp_unit_interval).()
        end
    end
  end

  def actual_mb(row, callbacks) do
    TimelineDiffStationThroughputAmountFields.actual_mb(row, callbacks)
  end

  def expected_mb(row, callbacks) do
    TimelineDiffStationThroughputAmountFields.expected_mb(row, callbacks)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
