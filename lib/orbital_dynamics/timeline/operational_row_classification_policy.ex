defmodule OrbitalDynamics.Timeline.OperationalRowClassificationPolicy do
  @moduledoc false

  def contact?(row) do
    row["activity_type"] in ["downlink", "planned_contact", "tracking"] ||
      is_binary(row["ground_station_id"])
  end

  def command?(row, command_health_activity_types, command_contact_directions) do
    row["activity_type"] in command_health_activity_types ||
      row["direction"] in command_contact_directions
  end
end
