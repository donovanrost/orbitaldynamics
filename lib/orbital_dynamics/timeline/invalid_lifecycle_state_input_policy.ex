defmodule OrbitalDynamics.Timeline.InvalidLifecycleStateInputPolicy do
  @moduledoc false

  def optional_input(nil, _sequence, _activity_to_map, _activity_input_to_map), do: nil

  def optional_input(
        %{"invalid_activity_input" => true} = activity,
        _sequence,
        activity_to_map,
        _activity_input_to_map
      ),
      do: activity_to_map.(activity)

  def optional_input(
        %{invalid_activity_input: true} = activity,
        _sequence,
        activity_to_map,
        _activity_input_to_map
      ),
      do: activity_to_map.(activity)

  def optional_input(activity, sequence, _activity_to_map, activity_input_to_map) do
    case activity_input_to_map.(activity, sequence) do
      {:ok, activity} -> activity
      {:error, row} -> row
    end
  end

  def invalid_row?(%{"invalid_activity_input" => true}), do: true
  def invalid_row?(%{invalid_activity_input: true}), do: true
  def invalid_row?(_activity), do: false

  def invalid?(planned_activity, realized_activity) do
    planned_activity
    |> invalid_rows(realized_activity)
    |> Enum.any?()
  end

  def invalid_count(planned_activity, realized_activity) do
    planned_activity
    |> invalid_rows(realized_activity)
    |> length()
    |> case do
      0 -> nil
      count -> count
    end
  end

  def invalid_reasons(planned_activity, realized_activity, sorted_uniq) do
    reasons =
      planned_activity
      |> invalid_rows(realized_activity)
      |> Enum.map(& &1["invalid_activity_input_reason"])
      |> sorted_uniq.()

    if reasons == [], do: nil, else: reasons
  end

  def state_activity_id(
        %{"invalid_activity_input" => true, "activity_id" => activity_id},
        _activity_id
      ),
      do: activity_id

  def state_activity_id(activity, activity_id), do: activity_id.(activity)

  def state_timeline_id(
        %{"invalid_activity_input" => true, "timeline_id" => timeline_id},
        _activity_timeline_id
      ),
      do: timeline_id

  def state_timeline_id(activity, activity_timeline_id),
    do: activity_timeline_id.(activity)

  def status_state_activity_id(planned_activity, realized_activity, activity_id) do
    (planned_activity && state_activity_id(planned_activity, activity_id)) ||
      (realized_activity && state_activity_id(realized_activity, activity_id))
  end

  def status_state_timeline_id(planned_activity, realized_activity, activity_timeline_id) do
    (planned_activity && state_timeline_id(planned_activity, activity_timeline_id)) ||
      (realized_activity && state_timeline_id(realized_activity, activity_timeline_id))
  end

  defp invalid_rows(planned_activity, realized_activity) do
    [planned_activity, realized_activity]
    |> Enum.filter(fn
      %{"invalid_activity_input" => true} -> true
      _activity -> false
    end)
  end
end
