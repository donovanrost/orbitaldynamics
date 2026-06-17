defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityDataRateLookupFields do
  @moduledoc false

  def planned_data_rate_mbps(row, callbacks) do
    first_data_rate_mbps(row, callbacks,
      mbps_fields: [
        "planned_data_rate_mbps",
        "planned_downlink_rate_mbps",
        "source_planned_data_rate_mbps",
        "source_data_rate_mbps",
        "source_downlink_rate_mbps",
        ["source_activity_context", "planned_data_rate_mbps"],
        ["source_activity_context", "data_rate_mbps"],
        ["source_activity_context", "downlink_rate_mbps"],
        ["source_activity_context", "link", "data_rate_mbps"],
        ["source_activity_context", "communications", "data_rate_mbps"],
        ["source_activity_context", "throughput_model", "data_rate_mbps"]
      ],
      mb_s_fields: [
        "planned_data_rate_mb_s",
        "planned_downlink_rate_mb_s",
        "source_planned_data_rate_mb_s",
        "source_data_rate_mb_s",
        "source_downlink_rate_mb_s",
        ["source_activity_context", "planned_data_rate_mb_s"],
        ["source_activity_context", "data_rate_mb_s"],
        ["source_activity_context", "downlink_rate_mb_s"],
        ["source_activity_context", "link", "data_rate_mb_s"],
        ["source_activity_context", "communications", "data_rate_mb_s"],
        ["source_activity_context", "throughput_model", "data_rate_mb_s"]
      ]
    )
  end

  def realized_data_rate_mbps(row, callbacks) do
    first_data_rate_mbps(row, callbacks,
      mbps_fields: [
        "realized_data_rate_mbps",
        "actual_data_rate_mbps",
        "realized_downlink_rate_mbps",
        "actual_downlink_rate_mbps",
        "replacement_realized_data_rate_mbps",
        "replacement_actual_data_rate_mbps",
        "replacement_data_rate_mbps",
        "replacement_downlink_rate_mbps",
        ["replacement_activity_context", "realized_data_rate_mbps"],
        ["replacement_activity_context", "actual_data_rate_mbps"],
        ["replacement_activity_context", "data_rate_mbps"],
        ["replacement_activity_context", "downlink_rate_mbps"],
        ["replacement_activity_context", "link", "data_rate_mbps"],
        ["replacement_activity_context", "communications", "data_rate_mbps"],
        ["replacement_activity_context", "throughput_model", "data_rate_mbps"],
        ["replacement_activity_context", "throughput_model", "actual_data_rate_mbps"]
      ],
      mb_s_fields: [
        "realized_data_rate_mb_s",
        "actual_data_rate_mb_s",
        "realized_downlink_rate_mb_s",
        "actual_downlink_rate_mb_s",
        "replacement_realized_data_rate_mb_s",
        "replacement_actual_data_rate_mb_s",
        "replacement_data_rate_mb_s",
        "replacement_downlink_rate_mb_s",
        ["replacement_activity_context", "realized_data_rate_mb_s"],
        ["replacement_activity_context", "actual_data_rate_mb_s"],
        ["replacement_activity_context", "data_rate_mb_s"],
        ["replacement_activity_context", "downlink_rate_mb_s"],
        ["replacement_activity_context", "link", "data_rate_mb_s"],
        ["replacement_activity_context", "communications", "data_rate_mb_s"],
        ["replacement_activity_context", "throughput_model", "data_rate_mb_s"],
        ["replacement_activity_context", "throughput_model", "actual_data_rate_mb_s"]
      ]
    )
  end

  defp first_data_rate_mbps(row, callbacks, opts) do
    case callback!(callbacks, :timeline_diff_first_number).(
           row,
           Keyword.fetch!(opts, :mbps_fields)
         ) do
      value when is_number(value) ->
        value

      _value ->
        row
        |> callback!(callbacks, :timeline_diff_first_number).(Keyword.fetch!(opts, :mb_s_fields))
        |> case do
          value when is_number(value) -> value * 8.0
          _value -> nil
        end
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
