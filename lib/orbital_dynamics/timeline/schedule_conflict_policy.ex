defmodule OrbitalDynamics.Timeline.ScheduleConflictPolicy do
  @moduledoc false

  def status(activity) do
    activity["schedule_conflict_status"] ||
      get_in(activity, ["metadata", "schedule_conflict_status"])
  end
end
