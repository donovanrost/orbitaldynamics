defmodule OrbitalDynamics.Timeline.LifecycleStateInputPolicy do
  @moduledoc false

  def lifecycle_state_input_row(
        {activity, sequence},
        activity_input_to_map,
        activity_to_map
      ) do
    case activity_input_to_map.(activity, sequence) do
      {:ok, activity} -> activity_to_map.(activity)
      {:error, row} -> row
    end
  end

  def lifecycle_state_row_timeline_id(row, activity_timeline_id) do
    row["timeline_id"] || get_in(row, ["timeline_identity", "timeline_id"]) ||
      activity_timeline_id.(row)
  end
end
