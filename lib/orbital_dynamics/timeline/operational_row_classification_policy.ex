defmodule OrbitalDynamics.Timeline.OperationalRowClassificationPolicy do
  @moduledoc false

  @command_contact_directions ~w(command uplink)

  def command_contact_directions, do: @command_contact_directions

  def contact?(row) do
    row["activity_type"] in ["downlink", "planned_contact", "tracking"] ||
      is_binary(row["ground_station_id"])
  end

  def command?(row, command_health_activity_types, command_contact_directions) do
    row["activity_type"] in command_health_activity_types ||
      row["direction"] in command_contact_directions
  end

  def operational_kind(%{"type" => "command"}), do: "command"
  def operational_kind(%{"type" => "health_check"}), do: "health_check"
  def operational_kind(%{"type" => "observe"}), do: "observation"
  def operational_kind(%{"type" => "impulsive_burn"}), do: "maneuver"
  def operational_kind(%{"type" => "slew"}), do: "attitude"
  def operational_kind(%{"type" => "attitude"}), do: "attitude"
  def operational_kind(%{"type" => "coast"}), do: "coast"

  def operational_kind(%{"direction" => direction})
      when direction in @command_contact_directions,
      do: "command"

  def operational_kind(%{"type" => type})
      when type in ["downlink", "planned_contact", "contact", "tracking"] do
    "contact"
  end

  def operational_kind(%{"ground_station_id" => ground_station_id})
      when is_binary(ground_station_id) and ground_station_id != "" do
    "contact"
  end

  def operational_kind(_activity), do: "activity"
end
