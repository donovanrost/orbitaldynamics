defmodule OrbitalDynamics.Timeline.ActivitySchedulingCoordinateContext do
  @moduledoc false

  def timing(activity) do
    %{
      "starts_at_s" => OrbitalDynamics.Timeline.ActivityTimingPolicy.start(activity),
      "ends_at_s" => OrbitalDynamics.Timeline.ActivityTimingPolicy.end_time(activity),
      "duration_s" => OrbitalDynamics.Timeline.ActivityTimingPolicy.duration(activity),
      "target_id" => activity["target_id"]
    }
    |> compact_map()
  end

  def source_window(activity) do
    %{
      "source_window_id" =>
        OrbitalDynamics.Timeline.ActivityIdentityPolicy.source_window_id(activity),
      "source_window_type" =>
        OrbitalDynamics.Timeline.ActivityIdentityPolicy.source_window_type(activity)
    }
    |> compact_map()
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
