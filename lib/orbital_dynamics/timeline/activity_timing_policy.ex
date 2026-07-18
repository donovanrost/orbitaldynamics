defmodule OrbitalDynamics.Timeline.ActivityTimingPolicy do
  @moduledoc false

  def start(activity) do
    Map.get(activity, "starts_at_s") || Map.get(activity, "start_s")
  end

  def end_time(activity) do
    Map.get(activity, "ends_at_s") || Map.get(activity, "end_s")
  end

  def duration(%{"duration_s" => duration_s}) when is_number(duration_s), do: duration_s

  def duration(activity) do
    start_s = start(activity)
    end_s = end_time(activity)

    if is_number(start_s) and is_number(end_s), do: end_s - start_s, else: nil
  end
end
