defmodule OrbitalDynamics.Timeline.ActivityLifecycleContext do
  @moduledoc false

  def build(activity) do
    %{}
    |> maybe_put(
      activity,
      "status",
      &activity_status/1
    )
    |> maybe_put(
      activity,
      "approval_status",
      &activity_approval_status/1
    )
  end

  defp maybe_put(context, activity, field, value_fun) do
    if Map.has_key?(activity, field) or not is_nil(get_in(activity, ["metadata", field])) do
      Map.put(context, field, value_fun.(activity))
    else
      context
    end
  end

  defp activity_status(activity) do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.activity_status(
      activity,
      &OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.encode/1
    )
  end

  defp activity_approval_status(activity) do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.activity_approval_status(
      activity,
      &OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.encode/1
    )
  end
end
