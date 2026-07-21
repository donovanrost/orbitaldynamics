defmodule OrbitalDynamics.Schema.CampaignPlanActivitySnapshotContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, artifact) when is_map(artifact) do
    candidates = candidate_index(Map.get(artifact, "candidate_activities"))
    timelines = Map.get(artifact, "ranked_timelines")

    issues
    |> validate_ranked_timelines(timelines, candidates)
    |> validate_selected_activities(Map.get(artifact, "activities"), first_timeline(timelines))
  end

  defp candidate_index(candidates) when is_list(candidates) do
    Enum.reduce(candidates, %{}, fn
      %{"id" => id} = activity, acc when is_binary(id) -> Map.put_new(acc, id, activity)
      _activity, acc -> acc
    end)
  end

  defp candidate_index(_candidates), do: %{}

  defp validate_ranked_timelines(issues, timelines, candidates) when is_list(timelines) do
    timelines
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{"activities" => activities}, timeline_index}, acc when is_list(activities) ->
        validate_ranked_activities(acc, activities, timeline_index, candidates)

      {_timeline, _timeline_index}, acc ->
        acc
    end)
  end

  defp validate_ranked_timelines(issues, _timelines, _candidates), do: issues

  defp validate_ranked_activities(issues, activities, timeline_index, candidates) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{"id" => id} = activity, activity_index}, acc when is_binary(id) ->
        path = "$.ranked_timelines[#{timeline_index}].activities[#{activity_index}]"

        case Map.fetch(candidates, id) do
          :error -> [error(path, "must reference candidate activity by id") | acc]
          {:ok, ^activity} -> acc
          {:ok, _candidate} -> [error(path, "must match candidate activity snapshot") | acc]
        end

      {_activity, _activity_index}, acc ->
        acc
    end)
  end

  defp validate_selected_activities(issues, activities, %{"activities" => ranked_activities})
       when is_list(activities) and is_list(ranked_activities) do
    issues
    |> validate_selected_rows(activities, ranked_activities)
    |> validate_selected_count(activities, ranked_activities)
  end

  defp validate_selected_activities(issues, _activities, _timeline), do: issues

  defp validate_selected_rows(issues, activities, ranked_activities) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, index}, acc ->
      if activity == Enum.at(ranked_activities, index) do
        acc
      else
        [
          error(
            "$.activities[#{index}]",
            "must match first ranked timeline activity snapshot"
          )
          | acc
        ]
      end
    end)
  end

  defp validate_selected_count(issues, activities, ranked_activities) do
    if length(activities) == length(ranked_activities) do
      issues
    else
      [error("$.activities", "must match first ranked timeline activity count") | issues]
    end
  end

  defp first_timeline([%{} = timeline | _timelines]), do: timeline
  defp first_timeline(_timelines), do: nil
end
