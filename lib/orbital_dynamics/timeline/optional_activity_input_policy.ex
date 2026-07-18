defmodule OrbitalDynamics.Timeline.OptionalActivityInputPolicy do
  @moduledoc false

  def convert(nil, _activity_to_map), do: nil
  def convert(activity, activity_to_map), do: activity_to_map.(activity)
end
