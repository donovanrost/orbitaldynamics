defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffResourceAvailabilityEvidence do
  @moduledoc false

  def evidence(row, callbacks) do
    [
      side_evidence(row, "source", callbacks),
      row,
      side_evidence(row, "replacement", callbacks)
    ]
    |> Enum.reduce(%{}, fn evidence, merged ->
      evidence =
        evidence
        |> callback!(callbacks, :stringify_keys).()
        |> callback!(callbacks, :normalize_resource_availability_aliases).()
        |> callback!(callbacks, :compact_map).()

      Map.merge(merged, evidence)
    end)
  end

  def spacecraft_id(row, evidence) do
    evidence["spacecraft_id"] ||
      row["spacecraft_id"] ||
      row["scenario_id"] ||
      get_in(row, ["replacement_activity_context", "spacecraft_id"]) ||
      get_in(row, ["replacement_activity_context", "scenario_id"]) ||
      get_in(row, ["source_activity_context", "spacecraft_id"]) ||
      get_in(row, ["source_activity_context", "scenario_id"])
  end

  defp side_evidence(row, side, callbacks) do
    context = callback!(callbacks, :stringify_keys).(row["#{side}_activity_context"] || %{})

    context
    |> callback!(callbacks, :put_default_if_present).(
      "spacecraft_id",
      row["#{side}_spacecraft_id"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "spacecraft_available",
      row["#{side}_spacecraft_available"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "spacecraft_available?",
      row["#{side}_spacecraft_available?"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "spacecraft_availability",
      row["#{side}_spacecraft_availability"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "payload_available",
      row["#{side}_payload_available"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "payload_available?",
      row["#{side}_payload_available?"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "payload_status",
      row["#{side}_payload_status"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "antenna_available",
      row["#{side}_antenna_available"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "antenna_available?",
      row["#{side}_antenna_available?"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "antenna_status",
      row["#{side}_antenna_status"]
    )
    |> callback!(callbacks, :put_default_if_present).("degraded", row["#{side}_degraded"])
    |> callback!(callbacks, :put_default_if_present).("degraded?", row["#{side}_degraded?"])
    |> callback!(callbacks, :put_default_if_present).("mode", row["#{side}_mode"])
    |> callback!(callbacks, :put_default_if_present).(
      "incompatible_activity_types",
      row["#{side}_incompatible_activity_types"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "suppressed_activity_types",
      row["#{side}_suppressed_activity_types"]
    )
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
