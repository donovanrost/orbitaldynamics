defmodule OrbitalDynamics.Timeline.ActivityInputNormalization do
  @moduledoc false

  def normalize(
        {activity, sequence},
        opts,
        activity_to_map,
        activity_input_issue,
        invalid_activity_input_row,
        normalize_valid_activity
      ) do
    case to_map(
           activity,
           sequence,
           activity_to_map,
           activity_input_issue,
           invalid_activity_input_row
         ) do
      {:ok, activity} ->
        normalize_valid_activity.(activity, Keyword.put(opts, :sequence, sequence))

      {:error, row} ->
        Map.drop(row, ["id"])
    end
  end

  def to_map(
        activity,
        sequence,
        activity_to_map,
        activity_input_issue,
        invalid_activity_input_row
      ) do
    case safe_activity_to_map(activity, activity_to_map) do
      {:ok, activity} ->
        maybe_valid_activity_map(
          activity,
          sequence,
          activity_input_issue,
          invalid_activity_input_row
        )

      {:error, reason, source_activity} ->
        {:error, invalid_activity_input_row.(source_activity, sequence, reason)}
    end
  end

  defp safe_activity_to_map(activity, activity_to_map) do
    {:ok, activity_to_map.(activity)}
  rescue
    _error ->
      {:error, "invalid_activity_shape", %{"raw_input" => inspect(activity)}}
  end

  defp maybe_valid_activity_map(
         activity,
         sequence,
         activity_input_issue,
         invalid_activity_input_row
       ) do
    case activity_input_issue.(activity) do
      nil ->
        {:ok, activity}

      reason ->
        {:error, invalid_activity_input_row.(activity, sequence, reason)}
    end
  end
end
