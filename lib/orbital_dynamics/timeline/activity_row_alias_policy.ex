defmodule OrbitalDynamics.Timeline.ActivityRowAliasPolicy do
  @moduledoc false

  def normalize(activity) do
    activity
    |> put_new_present("id", Map.get(activity, "activity_id"))
    |> put_new_present("type", Map.get(activity, "activity_type"))
  end

  def put_new_present(activity, _key, value) when value in [nil, ""], do: activity

  def put_new_present(activity, key, value) do
    Map.put_new(activity, key, value)
  end
end
