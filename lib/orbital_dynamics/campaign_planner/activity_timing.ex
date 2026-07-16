defmodule OrbitalDynamics.CampaignPlanner.ActivityTiming do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ScalarValues, ValueEncoding}

  def within_remaining_horizon?(activity, horizon) do
    within_remaining_horizon?(activity, horizon, callbacks())
  end

  def within_remaining_horizon?(
        activity,
        %{"starts_at_s" => starts_at_s, "ends_at_s" => ends_at_s},
        callbacks
      ) do
    activity_end(activity, callbacks) > starts_at_s and
      activity_start(activity, callbacks) < ends_at_s
  end

  def remaining_horizon(prior_plan, horizon, current_epoch_s) do
    remaining_horizon(prior_plan, horizon, current_epoch_s, callbacks())
  end

  def remaining_horizon(prior_plan, nil, current_epoch_s, callbacks) do
    duration_s = planning_horizon_duration_s(prior_plan, current_epoch_s, callbacks)

    %{
      "starts_at_s" => current_epoch_s,
      "ends_at_s" => duration_s
    }
  end

  def remaining_horizon(_prior_plan, horizon, _current_epoch_s, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    numeric! = Keyword.fetch!(callbacks, :numeric!)

    horizon = stringify_keys.(horizon)

    %{
      "starts_at_s" =>
        numeric!.(Map.fetch!(horizon, "starts_at_s"), "remaining_horizon.starts_at_s"),
      "ends_at_s" => numeric!.(Map.fetch!(horizon, "ends_at_s"), "remaining_horizon.ends_at_s")
    }
  end

  def planning_horizon_duration_s(prior_plan, default) do
    planning_horizon_duration_s(prior_plan, default, callbacks())
  end

  def planning_horizon_duration_s(prior_plan, default, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    prior_plan
    |> get_in(["planning_horizon", "duration_s"])
    |> numeric_or_nil.()
    |> case do
      value when is_number(value) -> value
      _value -> default
    end
  end

  def activity_start(activity), do: activity_start(activity, callbacks())

  def shift_activity(activity, delay_s) do
    activity
    |> maybe_shift("starts_at_s", delay_s)
    |> maybe_shift("ends_at_s", delay_s)
  end

  def activity_start(activity, callbacks) do
    activity_raw_start(activity, callbacks) || 0.0
  end

  def activity_end(activity), do: activity_end(activity, callbacks())

  def activity_end(activity, callbacks) do
    activity_raw_end(activity, callbacks) || activity_start(activity, callbacks)
  end

  def activity_raw_start(activity), do: activity_raw_start(activity, callbacks())

  def activity_raw_start(activity, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    numeric_or_nil.(Map.get(activity, "starts_at_s")) ||
      numeric_or_nil.(Map.get(activity, "start_s")) ||
      numeric_or_nil.(Map.get(activity, "epoch_s"))
  end

  def activity_raw_end(activity), do: activity_raw_end(activity, callbacks())

  def activity_raw_end(activity, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    numeric_or_nil.(Map.get(activity, "ends_at_s")) ||
      numeric_or_nil.(Map.get(activity, "end_s")) ||
      numeric_or_nil.(Map.get(activity, "epoch_s"))
  end

  def overlaps?(left, right) do
    left["starts_at_s"] < right["ends_at_s"] and right["starts_at_s"] < left["ends_at_s"]
  end

  def overlap_duration(interval, intervals) do
    intervals
    |> Enum.map(fn other -> interval_overlap_duration(interval, other) end)
    |> Enum.sum()
  end

  def interval_overlap_duration({left_start, left_end}, {right_start, right_end}) do
    max(0.0, min(left_end, right_end) - max(left_start, right_start))
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      numeric!: &ScalarValues.numeric!/2,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1
    ]
  end

  defp maybe_shift(activity, key, delay_s) do
    case Map.fetch(activity, key) do
      {:ok, value} -> Map.put(activity, key, value + delay_s)
      :error -> activity
    end
  end
end
