defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffContactCommandIdentityFields do
  @moduledoc false

  def contact_identity_reasons(row, callbacks) do
    [
      "timeline_diff_changed_activity",
      "timeline_diff_changed_contact_identity"
    ] ++ Enum.map(contact_identity_mismatch_fields(row, callbacks), &"#{&1}_mismatch")
  end

  def contact_identity_mismatch?(row, callbacks) do
    contact_identity_mismatch_fields(row, callbacks) != []
  end

  def contact_identity_mismatch_fields(row, callbacks) do
    ["direction", "ground_station", "source_window"]
    |> Enum.filter(&(contact_identity_match_status(row, &1, callbacks) == "mismatch"))
  end

  def contact_identity_match_status(row, "direction", callbacks) do
    callback!(callbacks, :timeline_diff_match_status).(
      planned_contact_direction(row, callbacks),
      realized_contact_direction(row, callbacks)
    )
  end

  def contact_identity_match_status(row, "ground_station", callbacks) do
    callback!(callbacks, :timeline_diff_match_status).(
      planned_ground_station_id(row, callbacks),
      realized_ground_station_id(row, callbacks)
    )
  end

  def contact_identity_match_status(row, "source_window", callbacks) do
    callback!(callbacks, :timeline_diff_match_status).(
      planned_source_window_id(row, callbacks),
      realized_source_window_id(row, callbacks)
    )
  end

  def command_identity_reasons(row, callbacks) do
    [
      "timeline_diff_changed_activity",
      "timeline_diff_changed_command_identity"
    ] ++ Enum.map(command_identity_mismatch_fields(row, callbacks), &"#{&1}_mismatch")
  end

  def command_identity_mismatch?(row, callbacks) do
    command_identity_mismatch_fields(row, callbacks) != []
  end

  def command_identity_mismatch_fields(row, callbacks) do
    ["direction", "ground_station", "source_window"]
    |> Enum.filter(&(command_identity_match_status(row, &1, callbacks) == "mismatch"))
  end

  def command_identity_match_status(row, field, callbacks) do
    contact_identity_match_status(row, field, callbacks)
  end

  def contact_direction(row, callbacks) do
    realized_contact_direction(row, callbacks) || planned_contact_direction(row, callbacks)
  end

  def planned_contact_direction(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "planned_direction",
      "source_planned_direction",
      "source_direction",
      ["source_activity_context", "planned_direction"],
      ["source_activity_context", "direction"]
    ])
    |> callback!(callbacks, :normalized_status_token).()
  end

  def realized_contact_direction(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "realized_direction",
      "replacement_realized_direction",
      "replacement_direction",
      ["replacement_activity_context", "realized_direction"],
      ["replacement_activity_context", "direction"]
    ])
    |> callback!(callbacks, :normalized_status_token).()
  end

  def planned_ground_station_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_stable_id).(row, [
      "planned_ground_station_id",
      "source_planned_ground_station_id",
      "source_ground_station_id",
      "source_station_id",
      ["source_activity_context", "planned_ground_station_id"],
      ["source_activity_context", "ground_station_id"],
      ["source_activity_context", "station_id"],
      ["source_activity_context", "ground_station", "ground_station_id"],
      ["source_activity_context", "ground_station", "station_id"],
      ["source_activity_context", "ground_station", "id"],
      ["source_activity_context", "station", "ground_station_id"],
      ["source_activity_context", "station", "station_id"],
      ["source_activity_context", "station", "id"]
    ])
  end

  def realized_ground_station_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_stable_id).(row, [
      "realized_ground_station_id",
      "replacement_realized_ground_station_id",
      "replacement_ground_station_id",
      "replacement_station_id",
      ["replacement_activity_context", "realized_ground_station_id"],
      ["replacement_activity_context", "ground_station_id"],
      ["replacement_activity_context", "station_id"],
      ["replacement_activity_context", "ground_station", "ground_station_id"],
      ["replacement_activity_context", "ground_station", "station_id"],
      ["replacement_activity_context", "ground_station", "id"],
      ["replacement_activity_context", "station", "ground_station_id"],
      ["replacement_activity_context", "station", "station_id"],
      ["replacement_activity_context", "station", "id"]
    ])
  end

  def contact_source_window_id(row, callbacks) do
    realized_source_window_id(row, callbacks) || planned_source_window_id(row, callbacks)
  end

  def planned_source_window_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_stable_id).(row, [
      "planned_source_window_id",
      "source_planned_source_window_id",
      "source_source_window_id",
      "source_window_id",
      ["source_activity_context", "planned_source_window_id"],
      ["source_activity_context", "source_window_id"],
      ["source_activity_context", "source_window", "source_window_id"],
      ["source_activity_context", "source_window", "id"]
    ])
  end

  def realized_source_window_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_stable_id).(row, [
      "realized_source_window_id",
      "replacement_realized_source_window_id",
      "replacement_source_window_id",
      ["replacement_activity_context", "realized_source_window_id"],
      ["replacement_activity_context", "source_window_id"],
      ["replacement_activity_context", "source_window", "source_window_id"],
      ["replacement_activity_context", "source_window", "id"]
    ])
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
