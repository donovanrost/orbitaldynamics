defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffStationThroughputAmountFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffStationThroughputAmountLookupFields

  def actual_mb(row, callbacks) do
    case TimelineDiffStationThroughputAmountLookupFields.explicit_actual_mb(row, callbacks) do
      value when is_number(value) ->
        value

      _value ->
        row
        |> evidence(callbacks)
        |> callback!(callbacks, :actual_data_rate_contact_throughput_mb).()
    end
  end

  def expected_mb(row, callbacks) do
    case TimelineDiffStationThroughputAmountLookupFields.explicit_expected_mb(row, callbacks) do
      value when is_number(value) ->
        value

      _value ->
        row
        |> evidence(callbacks)
        |> callback!(callbacks, :expected_contact_throughput_mb).()
    end
  end

  defp evidence(row, callbacks) do
    [
      row["source_activity_context"],
      row,
      row["replacement_activity_context"]
    ]
    |> Enum.reduce(%{}, fn evidence, merged ->
      Map.merge(merged, callback!(callbacks, :stringify_keys).(evidence || %{}))
    end)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
